const std = @import("std");
const win = @import("zigwin32").everything;

pub fn u8tou16(utf8: [*:0]const u8, utf16: [*:0]u16, len: usize) void {
    for (0..len - 1) |i| {
        utf16[i] = @intCast(utf8[i]);
    }
    utf16[len - 1] = @as(u16, 0);
}

pub fn u16tou8(utf16: [*:0]const u16, utf8: [*:0]u8, len: usize) void {
    for (0..len) |i| {
        utf8[i] = @intCast(utf16[i]);
    }
    utf8[len - 1] = 0;
}

// pub fn lstring(allocator: std.mem.Allocator, utf8: anytype) ![]u16 {
//     var utf16: [*]u16 = (try allocator.alloc(u16, utf8.len + 1)).ptr;
//     for (utf8, 0..) |char, i| {
//         utf16[i] = @intCast(char);
//     }
//     utf16[utf8.len] = 0;
//     return utf16[0 .. utf8.len + 1];
// }

pub fn slicestr(utf8: anytype) []u8 {
    return utf8[0 .. utf8.len + 1];
}

pub fn isFullPath(utf16: []const u16) ?u16 {
    const fw_slash: u16 = '/';
    const bw_slash: u16 = '\\';

    for (utf16) |item| {
        if (item == fw_slash) return fw_slash;
        if (item == bw_slash) return bw_slash;
    }
    return null;
}

pub fn print16(s: anytype) void {
    var i: usize = 0;
    while (s[i] != 0) : (i += 1) {
        const c: u8 = @intCast(s[i]);
        std.debug.print("{c}", .{c});
    }
    std.debug.print("\n", .{});
}

pub fn getShortName(s: [:0]u16) [:0]u16 {
    var lastSlash: usize = 0;

    for (s, 0..) |chr, i| {
        if (chr == '\\') {
            lastSlash = i;
        }
    }
    return @ptrCast(s[lastSlash + 1 .. s.len]);
}

pub fn looksLikeAscii(possible_str: []const u8) bool {
    for (possible_str) |c| {
        if (c < 20 or c > 'z' or c == '@') {
            return false;
        }
    }
    return true;
}

pub fn screwApiSets(possible_apiset: []const u16) bool {
    const pattern: *const [10:0]u8 = "api-ms-win";
    if (possible_apiset.len < 10) {
        return false;
    }

    for (possible_apiset, 0..) |wc, i| {
        if (i >= 9) {
            return true;
        }
        if (wc & 0xff00 != 0) {
            return false;
        }
        const c: u8 = @intCast(wc);
        if (c != pattern[i]) {
            return false;
        }
    }
    return false;
}

pub fn findExportRealName(fname: [*]const u8) ?[]const u8 {
    const len = std.mem.len(@as([*:0]const u8, @ptrCast(fname)));
    for (fname[0..len], 0..) |c, i| {
        if (c == '.') return fname[i + 1 .. len];
    }
    return null;
}
pub fn sectionCharacteristicsToPageProtection(chars: win.IMAGE_SECTION_CHARACTERISTICS) win.PAGE_PROTECTION_FLAGS {
    const execute = chars.MEM_EXECUTE == 1;
    const read = chars.MEM_READ == 1;
    const write = chars.MEM_WRITE == 1;

    var flags = win.PAGE_PROTECTION_FLAGS{};

    // Map RWX combinations to the appropriate PAGE_* base protection
    if (!execute and !read and !write) {
        flags.PAGE_NOACCESS = 1;
    } else if (!execute and read and !write) {
        flags.PAGE_READONLY = 1;
    } else if (!execute and read and write) {
        flags.PAGE_READWRITE = 1;
    } else if (!execute and !read and write) {
        // Write-only has no direct equivalent; Windows doesn't support it,
        // so fall back to READWRITE.
        flags.PAGE_READWRITE = 1;
    } else if (execute and !read and !write) {
        flags.PAGE_EXECUTE = 1;
    } else if (execute and read and !write) {
        flags.PAGE_EXECUTE_READ = 1;
    } else if (execute and read and write) {
        flags.PAGE_EXECUTE_READWRITE = 1;
    } else if (execute and !read and write) {
        // Execute+Write without Read is unusual; promote to EXECUTE_READWRITE.
        flags.PAGE_EXECUTE_READWRITE = 1;
    }

    // Map cache/paging modifiers
    if (chars.MEM_NOT_CACHED == 1) {
        flags.PAGE_NOCACHE = 1;
    }

    // MEM_DISCARDABLE doesn't have a direct PAGE_* equivalent but
    // maps loosely to SEC_RESERVE semantics for mapped views.
    if (chars.MEM_DISCARDABLE == 1) {
        flags.SEC_RESERVE = 1;
    }

    return flags;
}
