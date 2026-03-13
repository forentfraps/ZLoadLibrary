const std = @import("std");
const win = @import("zigwin32").everything;
const types = @import("win_types.zig");
const str = @import("u16str.zig");

const UNICODE_STRING = types.UNICODE_STRING;
const LDR_DATA_TABLE_ENTRY = types.LDR_DATA_TABLE_ENTRY;
const LDR_DATA_TABLE_ENTRY_FULL = types.LDR_DATA_TABLE_ENTRY_FULL;
const PEB = types.PEB;
const RTL_INVERTED_FUNCTION_TABLE = types.RTL_INVERTED_FUNCTION_TABLE;
const RTL_INVERTED_FUNCTION_TABLE_ENTRY = types.RTL_INVERTED_FUNCTION_TABLE_ENTRY;

// ===== getNtdllBase =====

pub fn getNtdllBase() ?[*]u8 {
    const peb: *PEB = asm volatile ("mov %gs:0x60, %rax"
        : [peb] "={rax}" (-> *PEB),
        :
        : .{ .memory = true });
    const head: *win.LIST_ENTRY = &peb.Ldr.InMemoryOrderModuleList;
    var curr: *win.LIST_ENTRY = head.Flink.?;
    var safety: usize = 0;
    while (safety < 2048) : (safety += 1) {
        const e: *LDR_DATA_TABLE_ENTRY =
            @fieldParentPtr("InMemoryOrderLinks", curr);
        if (e.BaseDllName.Buffer) |b| {
            const len = e.BaseDllName.Length / 2;
            const z = b[0..len];
            var is_ntdll = false;
            if (len >= 8) {
                var tmp: [16]u16 = undefined;
                var i: usize = 0;
                while (i < len and i < tmp.len - 1) : (i += 1)
                    tmp[i] = if (z[i] >= 'a' and z[i] <= 'z') z[i] - 32 else z[i];
                tmp[i] = 0;
                const up: [:0]u16 = @ptrCast(tmp[0..i]);
                is_ntdll = std.mem.eql(
                    u16,
                    up,
                    @as([:0]const u16, std.unicode.utf8ToUtf16LeStringLiteral("NTDLL.DLL")),
                );
            }
            if (is_ntdll) return @ptrCast(e.DllBase);
        }
        curr = curr.Flink.?;
        if (curr == head) break;
    }
    return null;
}

pub inline fn ldrBucketIndex(hash: u64) usize {
    return @intCast(hash & 0x1F);
}

// ===== Section finder =====

pub fn findSection(
    base: [*]u8,
    nt: *const win.IMAGE_NT_HEADERS64,
    name_z: []const u8,
) ?struct { p: [*]u8, size: usize } {
    var sec: [*]const win.IMAGE_SECTION_HEADER = @ptrFromInt(
        @intFromPtr(nt) + @sizeOf(win.IMAGE_NT_HEADERS64),
    );
    var i: usize = 0;
    while (i < nt.FileHeader.NumberOfSections) : (i += 1) {
        const nm = sec[i].Name[0..8];
        var j: usize = 0;
        while (j < 8 and nm[j] != 0) : (j += 1) {}
        if (std.mem.eql(u8, nm[0..j], name_z)) {
            return .{
                .p = @ptrCast(base[sec[i].VirtualAddress..]),
                .size = sec[i].Misc.VirtualSize,
            };
        }
    }
    return null;
}

// ===== insertTailList =====

pub inline fn insertTailList(head: *win.LIST_ENTRY, node: *win.LIST_ENTRY) void {
    const blink = head.Blink;
    node.Flink = head;
    node.Blink = blink;
    blink.Flink = node;
    head.Blink = node;
}

// ===== findLdrpHashTableBase =====
