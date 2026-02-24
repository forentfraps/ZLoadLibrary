const std = @import("std");
const UNICODE_STRING = @import("dll.zig").UNICODE_STRING;
const DllLoader = @import("dll.zig").DllLoader;

// Field order matches the C struct exactly:
//   pattern, mask, length, build_count, versions
// This matters if you ever use @extern or pass to C.
pub const WinVer = struct {
    major: u32, // BuildNumber
    minor: u32, // UBR
};

const OBJECT_ATTRIBUTES = extern struct {
    Length: u32,
    RootDirectory: ?*anyopaque,
    ObjectName: *UNICODE_STRING,
    Attributes: u32,
    SecurityDescriptor: ?*anyopaque,
    SecurityQualityOfService: ?*anyopaque,
};

const KEY_VALUE_PARTIAL_INFORMATION = extern struct {
    TitleIndex: u32,
    Type: u32,
    DataLength: u32,
    Data: [1]u8,
};

const OSVERSIONINFOW = extern struct {
    dwOSVersionInfoSize: u32,
    dwMajorVersion: u32,
    dwMinorVersion: u32,
    dwBuildNumber: u32,
    dwPlatformId: u32,
    szCSDVersion: [128]u16,
};

const OBJ_CASE_INSENSITIVE: u32 = 0x40;
const KEY_QUERY_VALUE: u32 = 0x0001;
const KeyValuePartialInformation: u32 = 2;

pub const GenericGroup = extern struct {
    pattern: [*]const u8,
    mask: [*]const u8,
    length: u32, // pattern byte count (NOT mask byte count)
    build_count: u32,
    versions: [*]const WinVer,
};

inline fn matchByte(want: u8, got: u8, mbits: [*]const u8, i: u32) bool {
    const bit: u8 = (mbits[i >> 3] >> @as(u3, @truncate(i & 7))) & 1;
    return if (bit != 0) (want == got) else true;
}

pub noinline fn findSignature(
    base: [*]const u8,
    size: usize,
    group: GenericGroup,
) ?[*]const u8 {
    const pattern = group.pattern;
    const mbits = group.mask;
    const sig_len = group.length;
    if (sig_len == 0) return null;
    if (size < sig_len) return null;

    var anchor: u32 = sig_len;
    for (0..sig_len) |i| {
        const idx: u32 = @intCast(i);
        if (((mbits[idx >> 3] >> @as(u3, @truncate(idx & 7))) & 1) != 0) {
            anchor = idx;
            break;
        }
    }

    if (anchor == sig_len) return base;

    const anchor_val = pattern[anchor];
    const last_pos = size - @as(usize, sig_len);

    var pos: usize = 0;
    while (pos <= last_pos) : (pos += 1) {
        if (base[pos + anchor] != anchor_val) continue;
        var i: u32 = 0;
        while (i < sig_len) : (i += 1) {
            if (!matchByte(pattern[i], base[pos + i], mbits, i)) break;
        }
        if (i == sig_len) return base + pos;
    }
    return null;
}

pub fn fetchSignature(
    major: u32,
    minor: u32,
    groups: []const GenericGroup,
) ?GenericGroup {
    var closest: ?GenericGroup = null;
    var distance: u32 = 99_999_999;
    //TODO this should check the image size from the PE

    for (groups) |group| {
        for (0..group.build_count) |si| {
            const v = group.versions[si];
            const d = absDiff(v.major, major) * 10_000 + absDiff(v.minor, minor);
            if (d < distance) {
                distance = d;
                closest = group;
            }
            if (v.major == major and v.minor == minor) {
                return group;
            }
        }
    }
    if (closest) |g| {
        return g;
    }
    return null;
}

inline fn absDiff(a: u32, b: u32) u32 {
    return if (a > b) a - b else b - a;
}

pub fn getWinVer(loader: *DllLoader) !WinVer {
    const ntdll = try loader.getDllByName("ntdll.dll");

    const NtOpenKey = try ntdll.getProc(
        fn (*?*anyopaque, u32, *OBJECT_ATTRIBUTES) callconv(.winapi) i32,
        "NtOpenKey",
    );
    const NtQueryValueKey = try ntdll.getProc(
        fn (?*anyopaque, *UNICODE_STRING, u32, ?*anyopaque, u32, *u32) callconv(.winapi) i32,
        "NtQueryValueKey",
    );
    const RtlGetVersion = try ntdll.getProc(
        fn (*OSVERSIONINFOW) callconv(.winapi) i32,
        "RtlGetVersion",
    );

    // Registry path
    const regpath = std.unicode.utf8ToUtf16LeStringLiteral(
        "\\Registry\\Machine\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
    );
    const regname = std.unicode.utf8ToUtf16LeStringLiteral("UBR");

    var path = UNICODE_STRING{
        .Length = @intCast(regpath.len * 2),
        .MaximumLength = @intCast((regpath.len + 1) * 2),
        .alignment = 0,
        .Buffer = @ptrCast(@constCast(regpath.ptr)),
    };
    var name = UNICODE_STRING{
        .Length = @intCast(regname.len * 2),
        .MaximumLength = @intCast((regname.len + 1) * 2),
        .alignment = 0,
        .Buffer = @ptrCast(@constCast(regname.ptr)),
    };

    var oa = OBJECT_ATTRIBUTES{
        .Length = @sizeOf(OBJECT_ATTRIBUTES),
        .RootDirectory = null,
        .ObjectName = &path,
        .Attributes = OBJ_CASE_INSENSITIVE,
        .SecurityDescriptor = null,
        .SecurityQualityOfService = null,
    };

    var hKey: ?*anyopaque = null;
    var st = NtOpenKey(&hKey, KEY_QUERY_VALUE, &oa);
    if (st < 0) return error.NtOpenKeyFailed;

    // Query required size first
    var need: u32 = 0;
    _ = NtQueryValueKey(hKey, &name, KeyValuePartialInformation, null, 0, &need);

    var buf: [1024]u8 = undefined;
    st = NtQueryValueKey(hKey, &name, KeyValuePartialInformation, &buf, need, &need);
    if (st < 0) return error.NtQueryValueKeyFailed;

    const kv: *const KEY_VALUE_PARTIAL_INFORMATION = @ptrCast(@alignCast(&buf));
    const ubr: u32 = @as(*align(1) const u32, @ptrCast(&kv.Data[0])).*;

    var osverinfo = OSVERSIONINFOW{
        .dwOSVersionInfoSize = @sizeOf(OSVERSIONINFOW),
        .dwMajorVersion = 0,
        .dwMinorVersion = 0,
        .dwBuildNumber = 0,
        .dwPlatformId = 0,
        .szCSDVersion = std.mem.zeroes([128]u16),
    };
    _ = RtlGetVersion(&osverinfo);

    var build = osverinfo.dwBuildNumber;
    if (build == 26200) build = 26100;

    return WinVer{
        .major = build,
        .minor = ubr,
    };
}
