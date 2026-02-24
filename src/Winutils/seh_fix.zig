const std = @import("std");
const sigscan = @import("sigscan.zig");
const dll_mapper = @import("dll.zig");
const win = @import("zigwin32").everything;
const c_sig = @cImport({
    @cInclude("sehfix.h");
});

pub fn rtlInsertInvertedFunctionTable(loader: *dll_mapper.DllLoader, target_dll: *dll_mapper.Dll) !void {
    const wv = loader.WinVer;
    const ntdll = try loader.getDllByName("ntdll.dll");

    const sig = sigscan.fetchSignature(
        wv.major,
        wv.minor,
        @ptrCast(c_sig.WSIG_NTDLL_RTLINSERTINVERTEDFUNCTIONTABLE_X64_GROUPS[0..c_sig.WSIG_NTDLL_RTLINSERTINVERTEDFUNCTIONTABLE_X64_GROUP_COUNT]),
    ) orelse return error.SignatureNotFound;

    const ntdll_nt = try dll_mapper.DllLoader.ResolveNtHeaders(ntdll.BaseAddr);
    const ntdll_size = ntdll_nt.OptionalHeader.SizeOfImage;

    const fn_ptr = sigscan.findSignature(
        ntdll.BaseAddr,
        ntdll_size,
        sig,
    ) orelse {
        @breakpoint();
        return error.SignatureScanFailed;
    };

    const RtlInsertInvertedFunctionTableFn = *const fn (
        [*]u8, // DllBase
        u32, // SizeOfImage
    ) callconv(.winapi) void;
    const RtlInsertInvertedFunctionTable: RtlInsertInvertedFunctionTableFn = @ptrCast(fn_ptr);

    const entry = try loader.CreateLdrDataTableEntryFromImageBase(target_dll);
    defer loader.Allocator.destroy(entry);

    const nt = try dll_mapper.DllLoader.ResolveNtHeaders(target_dll.BaseAddr);
    RtlInsertInvertedFunctionTable(target_dll.BaseAddr, nt.OptionalHeader.SizeOfImage);
}
