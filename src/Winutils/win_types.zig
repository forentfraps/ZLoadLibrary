const win = @import("zigwin32").everything;

// ===== Memory / file constants =====

pub const GENERIC_WRITE: u32 = 0x40000000;
pub const GENERIC_READ: u32 = 0x80000000;
pub const FILE_SHARE_READ: u32 = 0x00000001;
pub const FILE_SHARE_WRITE: u32 = 0x00000002;
pub const OPEN_EXISTING: u32 = 3;
pub const FILE_ATTRIBUTE_NORMAL: u32 = 0x00000080;
pub const MEM_RESERVE: u32 = 0x00002000;
pub const MEM_COMMIT: u32 = 0x00001000;
pub const PAGE_NOACCESS: u32 = 0x01;
pub const PAGE_READONLY: u32 = 0x02;
pub const PAGE_READWRITE: u32 = 0x04;
pub const PAGE_WRITECOPY: u32 = 0x08;
pub const PAGE_EXECUTE: u32 = 0x10;
pub const PAGE_EXECUTE_READ: u32 = 0x20;
pub const PAGE_EXECUTE_READWRITE: u32 = 0x40;
pub const PAGE_EXECUTE_WRITECOPY: u32 = 0x80;
pub const PAGE_GUARD: u32 = 0x100;
pub const PAGE_NOCACHE: u32 = 0x200;
pub const PAGE_WRITECOMBINE: u32 = 0x400;

// ===== GetModuleHandleEx flags =====

pub const GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS: u32 = 0x00000004;
pub const GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT: u32 = 0x00000001;
pub const GET_MODULE_HANDLE_EX_FLAG_PIN: u32 = 0x00000001;

// ===== Error set =====

pub const DllError = error{
    Size,
    VirtualAllocNull,
    HashmapSucks,
    FuncResolutionFailed,
    ForwarderParse,
    LoadFailed,
};

// ===== Windows structures =====

pub const UNICODE_STRING = extern struct {
    Length: u16,
    MaximumLength: u16,
    alignment: u32,
    Buffer: ?[*:0]u16,
};

pub const LDR_DATA_TABLE_ENTRY = extern struct {
    InLoadOrderLinks: win.LIST_ENTRY,
    InMemoryOrderLinks: win.LIST_ENTRY,
    InInitializationOrderLinks: win.LIST_ENTRY,
    DllBase: ?*anyopaque,
    EntryPoint: ?*anyopaque,
    SizeOfImage: u32,
    fullDllName: UNICODE_STRING,
    BaseDllName: UNICODE_STRING,
    Flags: u32,
    LoadCount: u16,
    TlsIndex: u16,
    HashLinks: win.LIST_ENTRY,
    TimeDateStamp: u32,
};

pub const LDR_DATA_TABLE_ENTRY_FULL = extern struct {
    InLoadOrderLinks: win.LIST_ENTRY,
    InMemoryOrderLinks: win.LIST_ENTRY,
    InInitializationOrderLinks: win.LIST_ENTRY,
    DllBase: ?*anyopaque,
    EntryPoint: ?*anyopaque,
    SizeOfImage: u32,
    FullDllName: UNICODE_STRING,
    BaseDllName: UNICODE_STRING,
    Flags: u32,
    LoadCount: u16,
    TlsIndex: u16,
    HashLinks: win.LIST_ENTRY,
    TimeDateStamp: u32,
};

pub const PEB_LDR_DATA = extern struct {
    lenght: u32,
    initialized: u32,
    SsHandle: win.HANDLE,
    InLoadOrderModuleList: win.LIST_ENTRY,
    InMemoryOrderModuleList: win.LIST_ENTRY,
    InInitializationOrderModuleList: win.LIST_ENTRY,
    EntryInProgress: *anyopaque,
    ShutdownInProgress: win.BOOLEAN,
    ShutdownThreadId: win.HANDLE,
};

pub const PEB = extern struct {
    Reserved1: [2]u8,
    BeingDebugged: u8,
    Reserved2: [1]u8,
    Reserved3: [2]*anyopaque,
    Ldr: *PEB_LDR_DATA,
    Reserved4: [3]*anyopaque,
    Reserved5: [2]usize,
    Reserved6: *anyopaque,
    Reserved7: usize,
    Reserved8: [4]usize,
    Reserved9: [4]usize,
    Reserved10: [1]usize,
    PostProcessInitRoutine: *const usize,
    Reserved11: [1]usize,
    Reserved12: [1]usize,
    SessionId: u32,
};

pub const IMAGE_DELAYLOAD_DESCRIPTOR = extern struct {
    Attributes: u32,
    DllNameRVA: u32,
    ModuleHandleRVA: u32,
    ImportAddressTableRVA: u32,
    ImportNameTableRVA: u32,
    BoundImportAddressTableRVA: u32,
    UnloadInformationTableRVA: u32,
    TimeDateStamp: u32,
};

pub const BASE_RELOCATION_BLOCK = struct {
    PageAddress: u32,
    BlockSize: u32,
};

pub const BASE_RELOCATION_ENTRY = packed struct {
    Offset: u12,
    Type: u4,
};

pub const RTL_INVERTED_FUNCTION_TABLE_ENTRY = extern struct {
    ImageBase: ?*anyopaque,
    ImageSize: u32,
    ExceptionDirectory: ?*anyopaque,
    ExceptionDirectorySize: u32,
};

pub const RTL_INVERTED_FUNCTION_TABLE = extern struct {
    Count: u32,
    MaxCount: u32,
    Epoch: u32,
    Overflow: u32,
    Entries: ?[*]RTL_INVERTED_FUNCTION_TABLE_ENTRY,
};

pub const DLLEntry = fn (dll: win.HINSTANCE, reason: u32, reserved: ?*@import("std").os.windows.LPVOID) callconv(.winapi) bool;
