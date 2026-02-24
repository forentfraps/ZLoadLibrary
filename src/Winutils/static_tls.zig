const std = @import("std");
const sigscan = @import("sigscan.zig");
const dll_mapper = @import("dll.zig");
const win = @import("zigwin32").everything;
const c_sig = @cImport({
    @cInclude("handle_tls_sig.h");
});

const PAGE_READWRITE: u32 = 0x04;

fn getCurrentExeLdrEntry() *dll_mapper.LDR_DATA_TABLE_ENTRY {
    const peb: *dll_mapper.PEB = asm volatile ("mov %gs:0x60, %rax"
        : [peb] "={rax}" (-> *dll_mapper.PEB),
        :
        : .{ .memory = true });
    const first: *win.LIST_ENTRY = peb.Ldr.InLoadOrderModuleList.Flink.?;
    return @fieldParentPtr("InLoadOrderLinks", first);
}

pub fn ldrpHandleTlsData(loader: *dll_mapper.DllLoader, target_dll: *dll_mapper.Dll) !void {
    const wv = loader.WinVer;
    const ntdll = try loader.getDllByName("ntdll.dll");

    const sig = sigscan.fetchSignature(
        wv.major,
        wv.minor,
        @ptrCast(c_sig.WSIG_NTDLL_LDRPHANDLETLSDATA_X64_GROUPS[0..c_sig.WSIG_NTDLL_LDRPHANDLETLSDATA_X64_GROUP_COUNT]),
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

    const LdrpHandleTlsDataFn = *const fn (
        *dll_mapper.LDR_DATA_TABLE_ENTRY,
    ) callconv(.winapi) u32;
    const LdrpHandleTlsData: LdrpHandleTlsDataFn = @ptrCast(fn_ptr);

    // Build a temporary LDR entry for the DLL being loaded
    const entry = try loader.CreateLdrDataTableEntryFromImageBase(target_dll);
    defer loader.Allocator.destroy(entry);

    if (LdrpHandleTlsData(entry) != 0) {
        asm volatile ("int3");
    }
}
