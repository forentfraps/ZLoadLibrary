const std = @import("std");
const win = @import("std").os.windows;
const clr = @import("clr.zig");
const sneaky_memory = @import("memory.zig");
const logger = @import("../Logger/logger.zig");
const winc = @import("Windows.h.zig");
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

// FIX: return full length if there’s no hyphen
pub fn hyphenLen(string: []u16) usize {
    return lastHyphenIndex(string) orelse string.len;
}

fn isDigits16(s: []const u16) bool {
    if (s.len == 0) return false;
    for (s) |ch| if (ch < '0' or ch > '9') return false;
    return true;
}

// Build “rev->-0” candidate (no alloc; returns slice into stack buf)
fn makeRevZeroCandidate(base: []const u16, out: []u16) []const u16 {
    if (lastHyphenIndex(base)) |idx| {
        const tail = if (idx + 1 <= base.len) base[idx + 1 ..] else &[_]u16{};
        if (isDigits16(tail) and idx + 2 <= out.len) {
            @memcpy(out[0 .. idx + 1], base[0 .. idx + 1]);
            out[idx + 1] = '0';
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
pub fn checkApiSet(dllname: []u16) bool {
    if (dllname.len < 11) return false; // "api-ms-win-" length
    // Case-insensitive check for "API-MS-WIN-" or "EXT-MS-WIN-"
    const p1 = "API-MS-WIN-"[0..];
    const p2 = "EXT-MS-WIN-"[0..];

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

pub fn ApiSetResolve(apiset_name_in: []u16) ?[]u16 {
    if (!checkApiSet(apiset_name_in)) return null;

    // PEB->ApiSetMap (x64)
    const ApiSetMap: *ApiSetNamespaceHeader = asm volatile (
        \\mov %gs:0x60, %rax
        \\add $0x68, %rax
        \\mov (%rax), %rax
        : [ApiSetMap] "={rax}" (-> *ApiSetNamespaceHeader),
        :
        : "memory"
    );

    if (ApiSetMap.version < 6 or ApiSetMap.count == 0)
        return null;

    // Arrays
    const hashEntryArray: [*]const ApiSetHashEntry =
        @ptrFromInt(@intFromPtr(ApiSetMap) + ApiSetMap.offsetArrayHashEntries);
    const nsEntryArray: [*]const ApiSetNamespaceEntry =
        @ptrFromInt(@intFromPtr(ApiSetMap) + ApiSetMap.offsetArrayNamespaceEntries);

    // Normalize input: strip ".dll"
    const base = stripDllExt(apiset_name_in);

    // Build candidates
    var rev0_buf: [260]u16 = undefined;
    const cand_exact = base;
    const cand_rev0 = makeRevZeroCandidate(base, &rev0_buf);
    const cand_root = makeContractRoot(base);

    const candidates = [_][]const u16{ cand_exact, cand_rev0, cand_root };

    // Try each candidate: hash only up to its last hyphen (your scheme)
    var foundEntry: ?*const ApiSetNamespaceEntry = null;

    candidate_loop: for (candidates) |cand| {
        if (cand.len == 0) continue;

        const prefix_end = hyphenLen(@constCast(cand)); // FIX: now returns len if no '-'
        const key = cand[0..prefix_end];

        const target_hash = winHash(ApiSetMap.hashMultiplier, @constCast(key));

        var low: usize = 0;
        var high: usize = @intCast(ApiSetMap.count - 1); // FIX: count-1, not count

        while (low <= high) {
            const middle = (low + high) >> 1;
            const he = hashEntryArray[middle];

            if (target_hash < he.hash) {
                if (middle == 0) break;
                high = middle - 1;
            } else if (target_hash > he.hash) {
                low = middle + 1;
            } else {
                // Hash match → assume index into namespace array (as in your code)
                foundEntry = &nsEntryArray[@as(usize, @intCast(he.index))];
                break;
            }
        }

        if (foundEntry != null) break :candidate_loop;
    }

    const e = foundEntry orelse return null;

    // host array
    if (e.hostCount == 0) return null;

    const valueEntriesArray: [*]const ApiSetValueEntry =
        @ptrFromInt(@intFromPtr(ApiSetMap) + e.valueEntriesOffset);

    // Pick first host (works for typical default host)
    const v0 = valueEntriesArray[0];

    // Return []u16 pointing into the ApiSet map
    const dllName: [*]u16 =
        @ptrFromInt(@intFromPtr(ApiSetMap) + v0.valueOffset);
    return dllName[0..(v0.valueLength / 2)];
}
