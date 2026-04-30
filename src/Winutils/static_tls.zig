const std = @import("std");
const sigscan = @import("sigscan.zig");
const dll_mapper = @import("dll.zig");
const win = @import("zigwin32").everything;

const c_sig = @import("sig_headers/handle_tls_sig.zig");

const log = &dll_mapper.log;

const PAGE_READWRITE: u32 = 0x04;

fn getCurrentExeLdrEntry() *dll_mapper.LDR_DATA_TABLE_ENTRY {
    const peb: *dll_mapper.PEB = asm volatile ("mov %gs:0x60, %rax"
        : [peb] "={rax}" (-> *dll_mapper.PEB),
        :
        : .{ .memory = true });
    const first: *win.LIST_ENTRY = peb.Ldr.InLoadOrderModuleList.Flink.?;
    return @fieldParentPtr("InLoadOrderLinks", first);
}

fn validateTlsDirectory(target_dll: *dll_mapper.Dll) bool {
    const nt = dll_mapper.DllLoader.ResolveNtHeaders(target_dll.BaseAddr) catch {
        log.crit16("[tls] ResolveNtHeaders failed for ", .{}, target_dll.Path.short.view());
        return false;
    };
    const tls_dd = nt.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_TLS)];
    if (tls_dd.Size == 0) return true; // no TLS, nothing to validate

    const image_base = @intFromPtr(target_dll.BaseAddr);
    const image_end = image_base + nt.OptionalHeader.SizeOfImage;

    const tls_dir_addr = image_base + tls_dd.VirtualAddress;
    if (tls_dir_addr < image_base or tls_dir_addr + 40 > image_end) {
        log.crit("[tls] TLS directory RVA 0x{x} out of image range for base=0x{x}", .{
            tls_dd.VirtualAddress, image_base,
        });
        return false;
    }
    const tls_dir: *align(1) const win.IMAGE_TLS_DIRECTORY64 = @ptrFromInt(tls_dir_addr);

    const aoi: usize = @intCast(tls_dir.AddressOfIndex);
    const aocb: usize = @intCast(tls_dir.AddressOfCallBacks);
    const start: usize = @intCast(tls_dir.StartAddressOfRawData);
    const end: usize = @intCast(tls_dir.EndAddressOfRawData);

    log.info16("[tls] inspect TLS for ", .{}, target_dll.Path.short.view());
    log.info(
        "[tls]   base=0x{x} size=0x{x} TLS dir RVA=0x{x}",
        .{ image_base, nt.OptionalHeader.SizeOfImage, tls_dd.VirtualAddress },
    );
    log.info("[tls]   AddressOfIndex     = 0x{x}", .{aoi});
    log.info("[tls]   AddressOfCallBacks = 0x{x}", .{aocb});
    log.info("[tls]   RawData range       = [0x{x} .. 0x{x}]", .{ start, end });

    if (aoi < image_base or aoi + 4 > image_end) {
        log.crit(
            "[tls] REJECT: AddressOfIndex=0x{x} is OUTSIDE image [0x{x} .. 0x{x}] " ++
                "- relocation likely missed; skipping LdrpHandleTlsData to avoid AV",
            .{ aoi, image_base, image_end },
        );
        asm volatile ("int3");
        return false;
    }

    if (aocb != 0 and (aocb < image_base or aocb + 8 > image_end)) {
        log.crit(
            "[tls] REJECT: AddressOfCallBacks=0x{x} is OUTSIDE image [0x{x} .. 0x{x}]",
            .{ aocb, image_base, image_end },
        );
        return false;
    }
    if (end < start) {
        log.crit("[tls] REJECT: EndAddressOfRawData=0x{x} < StartAddressOfRawData=0x{x}", .{ end, start });
        asm volatile ("int3");
        return false;
    }
    if (start != 0 and (start < image_base or end > image_end)) {
        log.crit(
            "[tls] REJECT: RawData range [0x{x} .. 0x{x}] is OUTSIDE image [0x{x} .. 0x{x}]",
            .{ start, end, image_base, image_end },
        );

        asm volatile ("int3");
        return false;
    }
    return true;
}

pub fn ldrpHandleTlsData(loader: *dll_mapper.DllLoader, target_dll: *dll_mapper.Dll) !void {
    if (!validateTlsDirectory(target_dll)) return;

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

    const status = LdrpHandleTlsData(entry);
    if (status != 0) {
        log.crit("[tls] LdrpHandleTlsData returned status=0x{x} (non-zero)", .{status});
    }
}
