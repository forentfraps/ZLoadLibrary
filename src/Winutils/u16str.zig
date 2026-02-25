const std = @import("std");

// ===== ASCII helpers =====

pub fn asciiUpper(b: u8) u8 {
    return if (b >= 'a' and b <= 'z') b - 32 else b;
}

pub fn asciiUpper16(w: u16) u16 {
    return if (w >= 'a' and w <= 'z') w - 32 else w;
}

pub fn toUpperOwned(alloc: std.mem.Allocator, s: []const u8) ![]u8 {
    var out = try alloc.alloc(u8, s.len);
    for (s, 0..) |b, i| out[i] = asciiUpper(b);
    return out;
}

pub fn toUpperTemp(buf: []u8, s: []const u8) []u8 {
    const n = @min(buf.len, s.len);
    var i: usize = 0;
    while (i < n) : (i += 1) buf[i] = asciiUpper(s[i]);
    return buf[0..n];
}

// ===== Forwarder / thunk helpers =====

pub fn looksLikeForwarderString(p: [*]const u8) bool {
    var i: usize = 0;
    var has_dot = false;
    while (i < 64) : (i += 1) {
        const c = p[i];
        if (c == 0) break;
        if (c == '.') has_dot = true;
        if (c < 0x20 or c > 0x7E) return false;
    }
    return has_dot;
}

pub fn isOrdinalLookup64(imp: u64) bool {
    return (imp & (1 << 63)) != 0;
}

pub fn ordinalOf64(imp: u64) u16 {
    return @intCast(imp & 0xFFFF);
}

// ===== OwnedZ16 =====

pub const OwnedZ16 = struct {
    alloc: std.mem.Allocator,
    raw: []u16,   // exact allocation INCLUDING sentinel
    z: [:0]u16,   // view with len excluding sentinel

    const Self = @This();

    pub fn deinit(self: *Self) void {
        if (self.raw.len != 0) self.alloc.free(self.raw);
    }

    fn up16(c: u16) u16 {
        return if (c >= 'a' and c <= 'z') c - 32 else c;
    }

    fn ensureNoDoulbeSentinel(self: *Self) void {
        if (self.raw.len == 0) return;
        if (self.raw[self.raw.len - 1] != 0) {
            self.raw[self.raw.len - 1] = 0;
        }
        var payload: usize = self.raw.len - 1;
        while (payload > 0 and self.raw[payload - 1] == 0) : (payload -= 1) {}
        self.raw[payload] = 0;
        self.raw = self.raw[0 .. payload + 1];
        self.z = @ptrCast(self.raw[0..payload]);
    }

    pub fn toUpperAsciiInPlace(self: *Self) void {
        var i: usize = 0;
        while (i < self.z.len) : (i += 1) {
            const c = self.z[i];
            if (c >= 'a' and c <= 'z') self.z[i] = c - 32;
        }
    }

    pub fn fromU8(alloc: std.mem.Allocator, s_in: []const u8) !Self {
        var n: usize = s_in.len;
        if (n > 0 and s_in[n - 1] == 0) n -= 1;
        var z = try alloc.allocSentinel(u16, n, 0);
        var i: usize = 0;
        while (i < n) : (i += 1) z[i] = @intCast(s_in[i]);
        return .{ .alloc = alloc, .raw = z[0 .. n + 1], .z = z };
    }

    pub fn fromU8z(alloc: std.mem.Allocator, zsrc: [*:0]const u8) !Self {
        const n = std.mem.len(zsrc);
        var z = try alloc.allocSentinel(u16, n, 0);
        var i: usize = 0;
        while (i < n) : (i += 1) z[i] = @intCast(zsrc[i]);
        return .{ .alloc = alloc, .raw = z[0 .. n + 1], .z = z };
    }

    pub fn fromU16(alloc: std.mem.Allocator, s: []const u16) !Self {
        var n = s.len;
        if (n > 0 and s[n - 1] == 0) n -= 1;
        var z = try alloc.allocSentinel(u16, n, 0);
        @memcpy(z[0..n], s[0..n]);
        return Self{ .alloc = alloc, .raw = z[0 .. n + 1], .z = z };
    }

    pub fn replaceWithZ16(self: *Self, nz: [:0]const u16) !void {
        var z = try self.alloc.allocSentinel(u16, nz.len, 0);
        @memcpy(z[0..nz.len], nz);
        if (self.raw.len != 0) self.alloc.free(self.raw);
        self.raw = z[0 .. nz.len + 1];
        self.z = z;
        self.ensureNoDoulbeSentinel();
    }

    pub fn view(self: *const Self) [:0]const u16 {
        return self.z;
    }

    pub fn viewMut(self: *Self) [:0]u16 {
        return self.z;
    }

    pub fn endsWithDll(self: *const Self) bool {
        const s = self.raw;
        if (s.len < 5) return false;
        return up16(s[s.len - 5]) == '.' and
            up16(s[s.len - 4]) == 'D' and
            up16(s[s.len - 3]) == 'L' and
            up16(s[s.len - 2]) == 'L';
    }

    pub fn canonicalUpperDllUsing(self: *Self, buf: []u16) !void {
        const core_len: usize = if (self.endsWithDll()) self.raw.len - 5 else self.raw.len - 1;
        if (buf.len < core_len + 5) return error.BufferTooSmall;
        var i: usize = 0;
        while (i < core_len) : (i += 1) buf[i] = up16(self.raw[i]);
        buf[i + 0] = '.';
        buf[i + 1] = 'D';
        buf[i + 2] = 'L';
        buf[i + 3] = 'L';
        buf[i + 4] = 0;
        const nz: [:0]u16 = @ptrCast(buf[0 .. core_len + 4]);
        try self.replaceWithZ16(nz);
    }

    pub fn canonicalUpperDll(self: *Self) !void {
        var tmp: [260]u16 = undefined;
        try self.canonicalUpperDllUsing(tmp[0..]);
    }

    pub fn fromAsciiUpper(alloc: std.mem.Allocator, s: []const u8) !Self {
        var z = try alloc.allocSentinel(u16, s.len, 0);
        var i: usize = 0;
        while (i < s.len) : (i += 1) {
            z[i] = up16(s[i]);
        }
        return .{ .alloc = alloc, .raw = z[0 .. s.len + 1], .z = z };
    }
};

// ===== HashMap contexts =====

pub const U16KeyCtx = struct {
    const Self = @This();
    pub fn hash(_: Self, key: []const u16) u64 {
        var h = std.hash.Wyhash.init(0);
        h.update(std.mem.sliceAsBytes(key));
        return h.final();
    }
    pub fn eql(_: Self, a: []const u16, b: []const u16) bool {
        return std.mem.eql(u16, a, b);
    }
};

pub const MappingContext = struct {
    const Self = @This();
    pub fn hash(_: Self, key: []u16) u64 {
        const len = key.len;
        const u8ptr: [*]const u8 = @ptrCast(key.ptr);
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(u8ptr[0 .. len * 2]);
        return hasher.final();
    }
    pub fn eql(_: Self, a: []u16, b: []u16) bool {
        return std.mem.eql(u16, a, b);
    }
};
