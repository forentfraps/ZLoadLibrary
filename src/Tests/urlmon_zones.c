#include <objbase.h>
#include <stdint.h>
#include <stdio.h>
#include <windows.h>

typedef HRESULT(WINAPI *PFN_CoInternetCreateSecurityManager)(void *, void **, DWORD);
typedef HRESULT(WINAPI *PFN_CoInternetCreateZoneManager)(void *, void **, DWORD);
typedef HRESULT(WINAPI *PFN_CoInternetParseUrl)(LPCWSTR, DWORD, DWORD, LPWSTR, DWORD, DWORD *, DWORD);

#define PARSE_CANONICALIZE 0x1
#define PARSE_FRIENDLY 0x2

static int try_call(const char *label, HRESULT hr) {
  if (FAILED(hr)) {
    printf("  %-44s FAIL hr=0x%08lX\n", label, hr);
    return 0;
  }
  printf("  %-44s OK   hr=0x%08lX\n", label, hr);
  return 1;
}

static void *must_get_proc(HMODULE m, const char *name) {
  FARPROC fp = GetProcAddress(m, name);
  if (!fp) {
    printf("GetProcAddress(%s) failed: %lu\n", name, GetLastError());
    ExitProcess(2);
  }
  return (void *)fp;
}

int main(int argc, char **argv) {
  int do_com = 1;
  for (int i = 1; i < argc; ++i) {
    if (lstrcmpA(argv[i], "--no-com") == 0)
      do_com = 0;
  }

  if (do_com) {
    HRESULT hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    printf("CoInitializeEx -> 0x%08lX\n", hr);
    if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
      return 1;
    }
  } else {
    printf("(skipping CoInitializeEx; --no-com)\n");
  }

  printf("\n=== Loading urlmon.dll ===\n");
  HMODULE urlmon = LoadLibraryA("urlmon.dll");
  if (!urlmon) {
    printf("LoadLibrary(urlmon.dll) failed: %lu\n", GetLastError());
    return 1;
  }
  printf("urlmon base = %p\n", (void *)urlmon);

  PFN_CoInternetCreateSecurityManager pCreateSM =
      (PFN_CoInternetCreateSecurityManager)must_get_proc(urlmon, "CoInternetCreateSecurityManager");
  PFN_CoInternetCreateZoneManager pCreateZM =
      (PFN_CoInternetCreateZoneManager)must_get_proc(urlmon, "CoInternetCreateZoneManager");
  PFN_CoInternetParseUrl pParseUrl =
      (PFN_CoInternetParseUrl)must_get_proc(urlmon, "CoInternetParseUrl");

  printf("  CoInternetCreateSecurityManager = %p\n", (void *)pCreateSM);
  printf("  CoInternetCreateZoneManager     = %p\n", (void *)pCreateZM);
  printf("  CoInternetParseUrl              = %p\n", (void *)pParseUrl);

  printf("\n=== Calls that funnel into ZonesInit ===\n");

  {
    void *sm = NULL;
    HRESULT hr = pCreateSM(NULL, &sm, 0);
    try_call("CoInternetCreateSecurityManager", hr);
    if (sm) {
      IUnknown *u = (IUnknown *)sm;
      u->lpVtbl->Release(u);
    }
  }

  {
    void *zm = NULL;
    HRESULT hr = pCreateZM(NULL, &zm, 0);
    try_call("CoInternetCreateZoneManager", hr);
    if (zm) {
      IUnknown *u = (IUnknown *)zm;
      u->lpVtbl->Release(u);
    }
  }

  {
    WCHAR out[1024];
    DWORD got = 0;
    HRESULT hr = pParseUrl(L"https://example.com/foo/../bar", PARSE_CANONICALIZE, 0, out,
                           (DWORD)(sizeof(out) / sizeof(out[0])), &got, 0);
    try_call("CoInternetParseUrl(PARSE_CANONICALIZE)", hr);
    if (SUCCEEDED(hr)) {
      printf("    canonicalised: \"%S\" (%lu wchars)\n", out, got);
    }
  }

  {
    void *sm = NULL;
    HRESULT hr = pCreateSM(NULL, &sm, 0);
    try_call("CoInternetCreateSecurityManager (2nd)", hr);
    if (sm) {
      IUnknown *u = (IUnknown *)sm;
      u->lpVtbl->Release(u);
    }
  }

  if (do_com)
    CoUninitialize();
  printf("\nDone.\n");
  fflush(stdout);
  return 0;
}
