const std = @import("std");
const win = @import("std").os.windows;
const clr = @import("clr.zig");
const sneaky_memory = @import("memory.zig");
const logger = @import("../Logger/logger.zig");
const winc = @import("Windows.h.zig");
const print = std.debug.print;

//https://www.geoffchappell.com/studies/windows/win32/apisetschema/index.htm
const ApiSetNamespaceHeader = struct {
    version: u32, // If less than 6 -> ignore, lost cause
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
    nameSize: u32,
    valueSize: u32,
    valueEntriesOffset: u32,
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
    nameLength: u32,
    valueOffset: u32,
    valueLength: u32,
};

pub fn hyphenLen(string: []u16) usize {
    const hyphen: u16 = @intCast('-');
    var index: usize = 0;
    for (string, 0..) |c, i| {
        if (c == hyphen) {
            index = i;
        }
    }
    return index;
}

pub fn checkApiSet(dllname: []u16) bool {
    if (dllname.len < 4) {
        return false;
    }
    var prefix: u64 = @as(*align(2) u64, @ptrCast(dllname.ptr)).*;
    prefix &= 0xffffffdfffdfffdf;
    //Converts to lowercase first 3 letters, ignoring the hyphen
    const api_prefix = 0x002D004900500041;
    const ext_prefix = 0x002D005400580045;
    if (prefix == api_prefix or prefix == ext_prefix) {
        return true;
    }
    return false;
}

pub fn winHash(multiplier: u32, string: []u16) u32 {
    var hash: u32 = 0;
    for (string) |c| {
        hash = hash *% multiplier + @as(u32, @intCast(c));
    }
    return hash;
}

pub fn ApiSetResolve(apiset_name: []u16) ?[]u16 {
    if (!checkApiSet(apiset_name)) {
        return null;
    }
    const ApiSetMap: *ApiSetNamespaceHeader = asm volatile (
        \\mov %gs:0x60, %rax
        \\add $0x68, %rax
        \\mov (%rax), %rax 
        : [ApiSetMap] "={rax}" (-> *ApiSetNamespaceHeader),
        :
        : "memory"
    );

    const hashMultiplier = ApiSetMap.hashMultiplier;
    var foundEntry: ?*ApiSetNamespaceEntry = null;
    const apisetLen = hyphenLen(apiset_name);
    const target_hash = winHash(hashMultiplier, apiset_name[0..apisetLen]);
    var low: usize = 0;
    var high: usize = @intCast(ApiSetMap.count);
    var middle: usize = 0;
    const hashEntryArray: [*]ApiSetHashEntry = @ptrFromInt(@intFromPtr(ApiSetMap) + @as(usize, @intCast(ApiSetMap.offsetArrayHashEntries)));
    const valueEntryArray: [*]ApiSetNamespaceEntry = @ptrFromInt(@intFromPtr(ApiSetMap) + @as(usize, @intCast(ApiSetMap.offsetArrayNamespaceEntries)));
    while (high >= low) {
        middle = (high + low) >> 1;
        const hashEntry = hashEntryArray[middle];
        const hashValue = hashEntry.hash;
        if (target_hash < hashValue) {
            high = middle - 1;
        } else if (target_hash > hashValue) {
            low = middle + 1;
        } else {
            foundEntry = @ptrCast(&valueEntryArray[@as(usize, @intCast(hashEntry.index))]);
            break;
        }
    }
    var validValueEntry: *ApiSetNamespaceEntry = undefined;
    if (foundEntry) |fe| {
        validValueEntry = fe;
    } else {
        return null;
    }

    if (validValueEntry.hostCount != 1) {
        std.debug.print("NOT ONE HOSTCOUNT BUT: {d}\n", .{validValueEntry.hostCount});
    }

    const valueEntriesArray: [*]ApiSetValueEntry = @ptrFromInt(@intFromPtr(ApiSetMap) + @as(usize, @intCast(validValueEntry.valueEntriesOffset)));
    const dllName: [*]u16 = @ptrFromInt(@intFromPtr(ApiSetMap) + @as(usize, @intCast(valueEntriesArray[0].valueOffset)));
    const dllNameSlice: []u16 = dllName[0..(valueEntriesArray[0].valueLength / 2)];

    return dllNameSlice;
}
