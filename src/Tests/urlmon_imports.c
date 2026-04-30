#include <stdint.h>
#include <stdio.h>
#include <windows.h>

typedef struct _IMG_DELAYLOAD_DESCRIPTOR_LOCAL {
  union {
    DWORD AllAttributes;
    struct {
      DWORD RvaBased : 1;
      DWORD ReservedAttributes : 31;
    };
  } Attributes;
  DWORD DllNameRVA;
  DWORD ModuleHandleRVA;
  DWORD ImportAddressTableRVA;
  DWORD ImportNameTableRVA;
  DWORD BoundImportAddressTableRVA;
  DWORD UnloadInformationTableRVA;
  DWORD TimeDateStamp;
} IMG_DELAYLOAD_DESCRIPTOR_LOCAL;

static void describe_owning_module(uintptr_t addr) {
  HMODULE mod = NULL;
  if (!GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                              GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                          (LPCSTR)addr, &mod)) {
    printf(" [owner=<unknown>]");
    return;
  }
  char path[MAX_PATH];
  DWORD n = GetModuleFileNameA(mod, path, sizeof(path));
  if (n == 0) {
    printf(" [owner=hMod=0x%p path=<err %lu>]", mod, GetLastError());
    return;
  }
  const char *base = path;
  for (const char *p = path; *p; ++p) {
    if (*p == '\\' || *p == '/')
      base = p + 1;
  }
  printf(" [owner=%s base=0x%p +0x%llx]", base, (void *)mod,
         (unsigned long long)(addr - (uintptr_t)mod));
}

static const IMAGE_NT_HEADERS *nt_of(HMODULE mod) {
  const IMAGE_DOS_HEADER *dos = (const IMAGE_DOS_HEADER *)mod;
  if (dos->e_magic != IMAGE_DOS_SIGNATURE)
    return NULL;
  const IMAGE_NT_HEADERS *nt =
      (const IMAGE_NT_HEADERS *)((const BYTE *)mod + dos->e_lfanew);
  if (nt->Signature != IMAGE_NT_SIGNATURE)
    return NULL;
  return nt;
}

static int address_in_image(uintptr_t addr, HMODULE mod) {
  const IMAGE_NT_HEADERS *nt = nt_of(mod);
  if (!nt)
    return 0;
  uintptr_t base = (uintptr_t)mod;
  return addr >= base && addr < base + nt->OptionalHeader.SizeOfImage;
}

static void walk_imports(HMODULE mod) {
  const IMAGE_NT_HEADERS *nt = nt_of(mod);
  if (!nt) {
    printf("  bad NT headers\n");
    return;
  }
  const IMAGE_DATA_DIRECTORY *dd =
      &nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
  if (dd->Size == 0) {
    printf("  no import directory\n");
    return;
  }
  const BYTE *base = (const BYTE *)mod;
  const IMAGE_IMPORT_DESCRIPTOR *desc =
      (const IMAGE_IMPORT_DESCRIPTOR *)(base + dd->VirtualAddress);

  int dll_idx = 0;
  for (; desc->Name; ++desc, ++dll_idx) {
    const char *dll = (const char *)(base + desc->Name);
    DWORD int_rva =
        desc->OriginalFirstThunk ? desc->OriginalFirstThunk : desc->FirstThunk;
    DWORD iat_rva = desc->FirstThunk;
    printf("\n[%d] %s  INT=0x%lx  IAT=0x%lx  TimeDate=0x%lx  Forward=0x%lx\n",
           dll_idx, dll, (unsigned long)int_rva, (unsigned long)iat_rva,
           (unsigned long)desc->TimeDateStamp,
           (unsigned long)desc->ForwarderChain);

    const IMAGE_THUNK_DATA64 *int_thunk =
        (const IMAGE_THUNK_DATA64 *)(base + int_rva);
    const IMAGE_THUNK_DATA64 *iat_thunk =
        (const IMAGE_THUNK_DATA64 *)(base + iat_rva);

    int n = 0;
    for (; int_thunk->u1.AddressOfData; ++int_thunk, ++iat_thunk, ++n) {
      uint64_t int_data = int_thunk->u1.AddressOfData;
      uint64_t bound = iat_thunk->u1.Function;
      int is_ordinal = (int_data & IMAGE_ORDINAL_FLAG64) != 0;

      if (is_ordinal) {
        WORD ord = (WORD)(int_data & 0xFFFF);
        printf("  [%4d] ORD #%u  iat=0x%llx  bound=0x%llx", n, ord,
               (unsigned long long)(uintptr_t)iat_thunk,
               (unsigned long long)bound);
      } else {
        const IMAGE_IMPORT_BY_NAME *ibn =
            (const IMAGE_IMPORT_BY_NAME *)(base + int_data);
        printf("  [%4d] %s  hint=%u  iat=0x%llx  bound=0x%llx", n, ibn->Name,
               ibn->Hint, (unsigned long long)(uintptr_t)iat_thunk,
               (unsigned long long)bound);
      }

      if (bound == 0) {
        printf("  *** UNBOUND ***");
      } else if ((uintptr_t)bound < 0x10000) {
        printf("  *** SUSPICIOUSLY-LOW (likely garbage) ***");
      } else {
        describe_owning_module((uintptr_t)bound);
      }
      printf("\n");
    }
    printf("  -- %d entries\n", n);
  }
}

static void walk_delay_imports(HMODULE mod) {
  const IMAGE_NT_HEADERS *nt = nt_of(mod);
  if (!nt)
    return;
  const IMAGE_DATA_DIRECTORY *dd =
      &nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT];
  if (dd->Size == 0) {
    printf("\n(no delay-import directory)\n");
    return;
  }
  printf("\n=== Delay imports ===\n");
  const BYTE *base = (const BYTE *)mod;
  const IMG_DELAYLOAD_DESCRIPTOR_LOCAL *d =
      (const IMG_DELAYLOAD_DESCRIPTOR_LOCAL *)(base + dd->VirtualAddress);

  int dll_idx = 0;
  for (; d->DllNameRVA; ++d, ++dll_idx) {
    const char *dll = (const char *)(base + d->DllNameRVA);
    printf("\n[delay %d] %s  attr=0x%lx  INT=0x%lx  IAT=0x%lx  Bound=0x%lx\n",
           dll_idx, dll, (unsigned long)d->Attributes.AllAttributes,
           (unsigned long)d->ImportNameTableRVA,
           (unsigned long)d->ImportAddressTableRVA,
           (unsigned long)d->BoundImportAddressTableRVA);

    if (d->ImportNameTableRVA == 0 || d->ImportAddressTableRVA == 0) {
      printf("  (skip - no INT/IAT)\n");
      continue;
    }
    const IMAGE_THUNK_DATA64 *int_thunk =
        (const IMAGE_THUNK_DATA64 *)(base + d->ImportNameTableRVA);
    const IMAGE_THUNK_DATA64 *iat_thunk =
        (const IMAGE_THUNK_DATA64 *)(base + d->ImportAddressTableRVA);

    int n = 0;
    for (; int_thunk->u1.AddressOfData; ++int_thunk, ++iat_thunk, ++n) {
      uint64_t int_data = int_thunk->u1.AddressOfData;
      uint64_t bound = iat_thunk->u1.Function;
      int is_ordinal = (int_data & IMAGE_ORDINAL_FLAG64) != 0;
      if (is_ordinal) {
        WORD ord = (WORD)(int_data & 0xFFFF);
        printf("  [%4d] ORD #%u  iat=0x%llx  current=0x%llx (un-resolved "
               "expected for delay)\n",
               n, ord, (unsigned long long)(uintptr_t)iat_thunk,
               (unsigned long long)bound);
      } else {
        const IMAGE_IMPORT_BY_NAME *ibn =
            (const IMAGE_IMPORT_BY_NAME *)(base + int_data);
        printf("  [%4d] %s  hint=%u  iat=0x%llx  current=0x%llx\n", n,
               ibn->Name, ibn->Hint, (unsigned long long)(uintptr_t)iat_thunk,
               (unsigned long long)bound);
      }
    }
    printf("  -- %d delay entries\n", n);
  }
}

static void crosscheck_via_get_proc_address(HMODULE mod) {
  const IMAGE_NT_HEADERS *nt = nt_of(mod);
  if (!nt)
    return;
  const IMAGE_DATA_DIRECTORY *dd =
      &nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
  if (dd->Size == 0)
    return;
  const BYTE *base = (const BYTE *)mod;
  const IMAGE_IMPORT_DESCRIPTOR *desc =
      (const IMAGE_IMPORT_DESCRIPTOR *)(base + dd->VirtualAddress);

  printf("\n=== GetProcAddress cross-check ===\n");
  int diffs = 0, checked = 0;
  for (; desc->Name; ++desc) {
    const char *dll_name = (const char *)(base + desc->Name);
    HMODULE dep = GetModuleHandleA(dll_name);
    if (!dep) {
      printf("  (skip dep %s - not loaded)\n", dll_name);
      continue;
    }
    DWORD int_rva =
        desc->OriginalFirstThunk ? desc->OriginalFirstThunk : desc->FirstThunk;
    const IMAGE_THUNK_DATA64 *int_thunk =
        (const IMAGE_THUNK_DATA64 *)(base + int_rva);
    const IMAGE_THUNK_DATA64 *iat_thunk =
        (const IMAGE_THUNK_DATA64 *)(base + desc->FirstThunk);
    for (; int_thunk->u1.AddressOfData; ++int_thunk, ++iat_thunk) {
      uint64_t int_data = int_thunk->u1.AddressOfData;
      uint64_t bound = iat_thunk->u1.Function;
      uint64_t lookup = 0;
      if ((int_data & IMAGE_ORDINAL_FLAG64) != 0) {
        WORD ord = (WORD)(int_data & 0xFFFF);
        lookup =
            (uint64_t)(uintptr_t)GetProcAddress(dep, (LPCSTR)(uintptr_t)ord);
      } else {
        const IMAGE_IMPORT_BY_NAME *ibn =
            (const IMAGE_IMPORT_BY_NAME *)(base + int_data);
        lookup = (uint64_t)(uintptr_t)GetProcAddress(dep, ibn->Name);
      }
      ++checked;
      if (lookup != bound) {
        ++diffs;
        if ((int_data & IMAGE_ORDINAL_FLAG64) != 0) {
          printf("  DIFF %s!#%u  bound=0x%llx  GPA=0x%llx\n", dll_name,
                 (WORD)(int_data & 0xFFFF), (unsigned long long)bound,
                 (unsigned long long)lookup);
        } else {
          const IMAGE_IMPORT_BY_NAME *ibn =
              (const IMAGE_IMPORT_BY_NAME *)(base + int_data);
          printf("  DIFF %s!%s  bound=0x%llx  GPA=0x%llx\n", dll_name,
                 ibn->Name, (unsigned long long)bound,
                 (unsigned long long)lookup);
        }
      }
    }
  }
  printf("  checked=%d diffs=%d\n", checked, diffs);
}

int main(int argc, char **argv) {
  const char *dll_name = (argc >= 2) ? argv[1] : "urlmon.dll";

  printf("=== Loading %s via OS LoadLibrary ===\n", dll_name);
  HMODULE mod = LoadLibraryA(dll_name);
  if (!mod) {
    printf("LoadLibrary failed: %lu\n", GetLastError());
    return 1;
  }
  char path[MAX_PATH];
  GetModuleFileNameA(mod, path, sizeof(path));
  const IMAGE_NT_HEADERS *nt = nt_of(mod);
  printf("  base=0x%p  size=0x%lx  path=%s\n", (void *)mod,
         nt ? (unsigned long)nt->OptionalHeader.SizeOfImage : 0, path);

  printf("\n=== Static imports ===\n");
  walk_imports(mod);

  walk_delay_imports(mod);

  crosscheck_via_get_proc_address(mod);

  printf("\nDone.\n");
  fflush(stdout);
  return 0;
}
