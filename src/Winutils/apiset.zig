const std = @import("std");
const win = @import("zigwin32").everything;
const clr = @import("clr.zig");
const sneaky_memory = @import("memory.zig");
const dll = @import("dll.zig");
const SysLogger = @import("sys_logger").SysLogger;
var log: SysLogger = undefined;
const print = std.debug.print;

// --- your structs kept as-is ---
const ApiSetNamespaceHeader = struct {
    version: u32,
    size: u32,
    flags: u32,
    count: u32,
    offsetArrayNamespaceEntries: u32,
    offsetArrayHashEntries: u32,
    hashMultiplier: u32,
};

const ApiSetHashEntry = struct {
    hash: u32,
    index: u32,
};

const ApiSetNamespaceEntry = struct {
    flags: u32,
    nameOffset: u32,
    nameSize: u32, // BYTES
    valueSize: u32, // BYTES (region size)
    valueEntriesOffset: u32, // offset to ApiSetValueEntry[]
    hostCount: u32,
};

const ApiSetValueArray = struct {
    flags: u32,
    count: u32,
    array: [*]ApiSetValueEntry,
};

const ApiSetValueEntry = struct {
    flags: u32,
    nameOffset: u32,
    nameLength: u32, // BYTES
    valueOffset: u32, // UTF-16 host name
    valueLength: u32, // BYTES
};

// ---------------- helpers ----------------

inline fn up16(w: u16) u16 {
    return if (w >= 'a' and w <= 'z') w - 32 else w;
}

fn endsWithDll(s: []const u16) bool {
    return s.len >= 4 and s[s.len - 4] == '.' and up16(s[s.len - 3]) == 'D' and up16(s[s.len - 2]) == 'L' and up16(s[s.len - 1]) == 'L';
}
fn stripDllExt(s: []const u16) []const u16 {
    return if (endsWithDll(s)) s[0 .. s.len - 4] else s;
}

fn lastHyphenIndex(s: []const u16) ?usize {
    var last: ?usize = null;
    for (s, 0..) |c, i| if (c == '-') {
        last = i;
    };
    return last;
}

pub fn hyphenLen(string: []u16) usize {
    return lastHyphenIndex(string) orelse string.len;
}

fn isDigits16(s: []const u16) bool {
    if (s.len == 0) return false;
    for (s) |ch| if (ch < '0' or ch > '9') return false;
    return true;
}

// Build “rev->-0” candidate (no alloc; returns slice into stack buf)
fn makeRevNumCandidate(base: []const u16, out: []u16, num: u8) []const u16 {
    if (lastHyphenIndex(base)) |idx| {
        const tail = if (idx + 1 <= base.len) base[idx + 1 ..] else &[_]u16{};
        if (isDigits16(tail) and idx + 2 <= out.len) {
            @memcpy(out[0 .. idx + 1], base[0 .. idx + 1]);
            out[idx + 1] = num;
            return out[0 .. idx + 2];
        }
    }
    return &[_]u16{};
}

// Take “contract root” (drop last “-<rev>” entirely)
fn makeContractRoot(base: []const u16) []const u16 {
    if (lastHyphenIndex(base)) |idx| {
        const tail = if (idx + 1 <= base.len) base[idx + 1 ..] else &[_]u16{};
        if (isDigits16(tail)) return base[0..idx];
    }
    return &[_]u16{};
}

// Your original hash (kept)
pub fn winHash(multiplier: u32, string: []u16) u32 {
    var hash: u32 = 0;
    for (string) |c| {
        hash = hash *% multiplier + @as(u32, @intCast(c));
    }
    return hash;
}

// Read UTF-16 slice at offset/length (BYTES) relative to header base
fn slice16At(base: *const anyopaque, byte_off: u32, byte_len: u32) []const u16 {
    if (byte_len == 0) return &[_]u16{};
    const p: [*]const u16 = @ptrFromInt(@intFromPtr(base) + byte_off);
    return p[0 .. byte_len / 2];
}

// -------------- quick prefix check (yours, but safer) --------------
pub fn checkApiSet(dllname: []const u16) bool {
    if (dllname.len < 11) return false; //
    // Case-insensitive check for "API-" or "EXT-"
    const p1 = "API-"[0..];
    const p2 = "EXT-"[0..];

    if (dllname.len >= p1.len) {
        var ok = true;
        for (p1, 0..) |ch, i| if (up16(dllname[i]) != ch) {
            ok = false;
            break;
        };
        if (ok) return true;
    }
    if (dllname.len >= p2.len) {
        var ok = true;
        for (p2, 0..) |ch, i| if (up16(dllname[i]) != ch) {
            ok = false;
            break;
        };
        if (ok) return true;
    }
    return false;
}

// ---------------- adapted resolver (minimal change) ----------------

pub fn ApiSetResolve(apiset_name_in: []const u16, blacklist: []const []const u16) ?[]u16 {
    log = dll.log;
    if (!checkApiSet(apiset_name_in)) return null;

    const ApiSetMap: *ApiSetNamespaceHeader = asm volatile (
        \\mov %gs:0x60, %rax
        \\add $0x68, %rax
        \\mov (%rax), %rax
        : [ApiSetMap] "={rax}" (-> *ApiSetNamespaceHeader),
        :
        : "memory");

    if (ApiSetMap.version < 6 or ApiSetMap.count == 0) {
        log.crit16("BAD API VERSION OR NO MAPS", .{}, apiset_name_in);
        return null;
    }

    const base_ptr = @intFromPtr(ApiSetMap);
    const count: usize = @intCast(ApiSetMap.count);

    const hashEntryArray: [*]const ApiSetHashEntry =
        @ptrFromInt(base_ptr + @as(usize, ApiSetMap.offsetArrayHashEntries));
    const nsEntryArray: [*]const ApiSetNamespaceEntry =
        @ptrFromInt(base_ptr + @as(usize, ApiSetMap.offsetArrayNamespaceEntries));

    const eqFold16 = struct {
        fn eqFold16(a: []const u16, b: []const u16) bool {
            if (a.len != b.len) return false;
            var i: usize = 0;
            while (i < a.len) : (i += 1) {
                var ca = a[i];
                var cb = b[i];
                if (ca >= 'A' and ca <= 'Z') ca += 32;
                if (cb >= 'A' and cb <= 'Z') cb += 32;
                if (ca != cb) return false;
            }
            return true;
        }
    }.eqFold16;

    // Case-insensitive ASCII match between a []u16 and a []u8 blacklist entry
    const matchBlacklistEntry = struct {
        fn match(a_in: []const u16, b_in: []const u16) bool {
            var a = a_in;
            var b = b_in;

            // strip trailing .dll (case-insensitive) from both sides
            const stripDll = struct {
                fn strip(s: []const u16) []const u16 {
                    if (s.len < 4) return s;
                    const t = s[s.len - 4 ..];
                    if (t[0] == '.' and
                        (t[1] | 0x20) == 'd' and
                        (t[2] | 0x20) == 'l' and
                        (t[3] | 0x20) == 'l') return s[0 .. s.len - 4];
                    return s;
                }
            }.strip;

            a = stripDll(a);
            b = stripDll(b);

            if (a.len != b.len) return false;
            var i: usize = 0;
            while (i < a.len) : (i += 1) {
                const ca = if (a[i] >= 'A' and a[i] <= 'Z') a[i] + 32 else a[i];
                const cb = if (b[i] >= 'A' and b[i] <= 'Z') b[i] + 32 else b[i];
                if (ca != cb) return false;
            }
            return true;
        }
    }.match;

    const hashFold16 = struct {
        fn hashFold16(mult: u32, s: []const u16) u32 {
            var h: u32 = 0;
            var i: usize = 0;
            while (i < s.len) : (i += 1) {
                var c = s[i];
                if (c >= 'A' and c <= 'Z') c += 32;
                h = h *% mult + @as(u32, @intCast(c));
            }
            return h;
        }
    }.hashFold16;

    const full = stripDllExt(apiset_name_in);
    const key_end = hyphenLen(@constCast(full));
    const key = full[0..key_end];
    const target_hash = hashFold16(ApiSetMap.hashMultiplier, key);

    var lo: usize = 0;
    var hi: usize = count;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        const h = hashEntryArray[mid].hash;
        if (h < target_hash) lo = mid + 1 else hi = mid;
    }
    if (lo == count or hashEntryArray[lo].hash != target_hash) {
        log.crit16("Did not find an entry ", .{}, apiset_name_in);
        return null;
    }

    var found: ?*const ApiSetNamespaceEntry = null;
    var idx = lo;
    while (idx < count and hashEntryArray[idx].hash == target_hash) : (idx += 1) {
        const he = hashEntryArray[idx];
        const ns_index: usize = @intCast(he.index);
        if (ns_index >= count) continue;

        const e = &nsEntryArray[ns_index];
        const name_ptr: [*]const u16 = @ptrFromInt(base_ptr + @as(usize, e.nameOffset));
        const name_len: usize = @intCast(e.nameSize / 2);
        const map_full = name_ptr[0..name_len];
        const map_key_end = hyphenLen(@constCast(map_full));
        const map_key = map_full[0..map_key_end];

        if (eqFold16(map_key, key)) {
            found = e;
            break;
        }
    }

    const e = found orelse {
        log.crit16("Did not find an entry ", .{}, apiset_name_in);
        return null;
    };

    if (e.hostCount == 0) {
        log.crit16("HOST COUNT 0", .{}, apiset_name_in);
        return null;
    }

    const valueEntriesArray: [*]const ApiSetValueEntry =
        @ptrFromInt(base_ptr + @as(usize, e.valueEntriesOffset));

    // Walk all host entries, skip any that are in the blacklist.
    // Entry[0] is the default/fallback; higher indices are caller-specific overrides.
    // We prefer the highest-indexed non-blacklisted entry (most specific), falling
    // back toward entry[0] if everything else is blacklisted.
    var best: ?[]u16 = null;
    var i: usize = 0;
    while (i < e.hostCount) : (i += 1) {
        const v = valueEntriesArray[i];
        if (v.valueLength == 0) continue; // empty = redirect-to-self sentinel, skip

        const host_name: []u16 = blk: {
            const ptr: [*]u16 = @ptrFromInt(base_ptr + @as(usize, v.valueOffset));
            break :blk ptr[0..(@as(usize, v.valueLength) / 2)];
        };

        // Check against every blacklisted name
        var blacklisted = false;
        for (blacklist) |bl| {
            if (matchBlacklistEntry(host_name, bl)) {
                // log.info("ApiSetResolve: skipping blacklisted host (entry {d})\n", .{i});
                blacklisted = true;
                break;
            }
        }

        if (!blacklisted) best = host_name;
        // Keep iterating: a later non-blacklisted entry is more specific
    }

    if (best) |result| return result;

    // All hosts were blacklisted — caller should treat this as "no resolution"
    log.crit16("ApiSetResolve: all hosts blacklisted for ", .{}, apiset_name_in);
    return null;
}
