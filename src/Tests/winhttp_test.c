#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>
#include <winhttp.h>

typedef HINTERNET(WINAPI *PFN_WinHttpOpen)(LPCWSTR, DWORD, LPCWSTR, LPCWSTR, DWORD);
typedef HINTERNET(WINAPI *PFN_WinHttpConnect)(HINTERNET, LPCWSTR, INTERNET_PORT, DWORD);
typedef HINTERNET(WINAPI *PFN_WinHttpOpenRequest)(HINTERNET, LPCWSTR, LPCWSTR, LPCWSTR, LPCWSTR, LPCWSTR *, DWORD);
typedef BOOL(WINAPI *PFN_WinHttpSendRequest)(HINTERNET, LPCWSTR, DWORD, LPVOID, DWORD, DWORD, DWORD_PTR);
typedef BOOL(WINAPI *PFN_WinHttpReceiveResponse)(HINTERNET, LPVOID);
typedef BOOL(WINAPI *PFN_WinHttpQueryHeaders)(HINTERNET, DWORD, LPCWSTR, LPVOID, LPDWORD, LPDWORD);
typedef BOOL(WINAPI *PFN_WinHttpReadData)(HINTERNET, LPVOID, DWORD, LPDWORD);
typedef BOOL(WINAPI *PFN_WinHttpCloseHandle)(HINTERNET);
typedef BOOL(WINAPI *PFN_WinHttpCrackUrl)(LPCWSTR, DWORD, DWORD, LPURL_COMPONENTS);

static int try_call(const char *label, int ok) {
  printf("  %-32s %s\n", label, ok ? "OK" : "FAIL");
  return ok;
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
  const wchar_t *url_w = L"http://example.com/";
  wchar_t url_buf[2048];
  if (argc > 1) {
    int n = MultiByteToWideChar(CP_UTF8, 0, argv[1], -1, url_buf,
                                (int)(sizeof(url_buf) / sizeof(url_buf[0])));
    if (n > 0) {
      url_w = url_buf;
    }
  }
  printf("URL: %S\n", url_w);

  printf("\n=== Loading winhttp.dll ===\n");
  HMODULE wh = LoadLibraryA("winhttp.dll");
  if (!wh) {
    printf("LoadLibrary(winhttp.dll) failed: %lu\n", GetLastError());
    return 1;
  }
  printf("winhttp base = %p\n", (void *)wh);

  PFN_WinHttpOpen pOpen = (PFN_WinHttpOpen)must_get_proc(wh, "WinHttpOpen");
  PFN_WinHttpConnect pConnect = (PFN_WinHttpConnect)must_get_proc(wh, "WinHttpConnect");
  PFN_WinHttpOpenRequest pOpenReq = (PFN_WinHttpOpenRequest)must_get_proc(wh, "WinHttpOpenRequest");
  PFN_WinHttpSendRequest pSend = (PFN_WinHttpSendRequest)must_get_proc(wh, "WinHttpSendRequest");
  PFN_WinHttpReceiveResponse pRecv = (PFN_WinHttpReceiveResponse)must_get_proc(wh, "WinHttpReceiveResponse");
  PFN_WinHttpQueryHeaders pQueryH = (PFN_WinHttpQueryHeaders)must_get_proc(wh, "WinHttpQueryHeaders");
  PFN_WinHttpReadData pRead = (PFN_WinHttpReadData)must_get_proc(wh, "WinHttpReadData");
  PFN_WinHttpCloseHandle pClose = (PFN_WinHttpCloseHandle)must_get_proc(wh, "WinHttpCloseHandle");
  PFN_WinHttpCrackUrl pCrack = (PFN_WinHttpCrackUrl)must_get_proc(wh, "WinHttpCrackUrl");

  printf("  WinHttpOpen            = %p\n", (void *)pOpen);
  printf("  WinHttpConnect         = %p\n", (void *)pConnect);
  printf("  WinHttpOpenRequest     = %p\n", (void *)pOpenReq);
  printf("  WinHttpSendRequest     = %p\n", (void *)pSend);
  printf("  WinHttpReceiveResponse = %p\n", (void *)pRecv);
  printf("  WinHttpQueryHeaders    = %p\n", (void *)pQueryH);
  printf("  WinHttpReadData        = %p\n", (void *)pRead);
  printf("  WinHttpCloseHandle     = %p\n", (void *)pClose);
  printf("  WinHttpCrackUrl        = %p\n", (void *)pCrack);

  printf("\n=== Cracking URL ===\n");
  wchar_t host[256] = {0};
  wchar_t path[1024] = {0};
  URL_COMPONENTSW uc;
  ZeroMemory(&uc, sizeof(uc));
  uc.dwStructSize = sizeof(uc);
  uc.lpszHostName = host;
  uc.dwHostNameLength = (DWORD)(sizeof(host) / sizeof(host[0]));
  uc.lpszUrlPath = path;
  uc.dwUrlPathLength = (DWORD)(sizeof(path) / sizeof(path[0]));
  if (!try_call("WinHttpCrackUrl", pCrack(url_w, 0, 0, &uc))) {
    printf("WinHttpCrackUrl GLE=%lu\n", GetLastError());
    return 1;
  }
  printf("  scheme = %s   host = %S   port = %u   path = %S\n",
         (uc.nScheme == INTERNET_SCHEME_HTTPS) ? "https" : "http", host,
         (unsigned)uc.nPort, path[0] ? path : L"/");

  printf("\n=== HTTP request ===\n");

  HINTERNET hSession = pOpen(L"winhttp_test/1.0", WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                             WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
  try_call("WinHttpOpen", hSession != NULL);
  if (!hSession) {
    printf("WinHttpOpen GLE=%lu\n", GetLastError());
    return 1;
  }

  HINTERNET hConn = pConnect(hSession, host, uc.nPort, 0);
  try_call("WinHttpConnect", hConn != NULL);
  if (!hConn) {
    printf("WinHttpConnect GLE=%lu\n", GetLastError());
    pClose(hSession);
    return 1;
  }

  DWORD req_flags = (uc.nScheme == INTERNET_SCHEME_HTTPS) ? WINHTTP_FLAG_SECURE : 0;
  HINTERNET hReq = pOpenReq(hConn, L"GET", path[0] ? path : L"/", NULL,
                            WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, req_flags);
  try_call("WinHttpOpenRequest", hReq != NULL);
  if (!hReq) {
    printf("WinHttpOpenRequest GLE=%lu\n", GetLastError());
    pClose(hConn);
    pClose(hSession);
    return 1;
  }

  BOOL sent = pSend(hReq, WINHTTP_NO_ADDITIONAL_HEADERS, 0,
                    WINHTTP_NO_REQUEST_DATA, 0, 0, 0);
  try_call("WinHttpSendRequest", sent);
  if (!sent) {
    printf("WinHttpSendRequest GLE=%lu\n", GetLastError());
    pClose(hReq);
    pClose(hConn);
    pClose(hSession);
    return 1;
  }

  BOOL recv = pRecv(hReq, NULL);
  try_call("WinHttpReceiveResponse", recv);
  if (!recv) {
    printf("WinHttpReceiveResponse GLE=%lu\n", GetLastError());
    pClose(hReq);
    pClose(hConn);
    pClose(hSession);
    return 1;
  }

  DWORD status = 0;
  DWORD status_len = sizeof(status);
  BOOL got_status = pQueryH(hReq, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                            WINHTTP_HEADER_NAME_BY_INDEX, &status, &status_len,
                            WINHTTP_NO_HEADER_INDEX);
  try_call("WinHttpQueryHeaders(STATUS)", got_status);
  if (got_status) {
    printf("  HTTP status = %lu\n", status);
  }

  printf("\n=== Body (first 256 bytes) ===\n");
  char buf[4096];
  DWORD total = 0;
  for (;;) {
    DWORD got = 0;
    if (!pRead(hReq, buf, sizeof(buf), &got)) {
      printf("WinHttpReadData GLE=%lu\n", GetLastError());
      break;
    }
    if (got == 0) {
      break;
    }
    if (total < 256) {
      DWORD show = (total + got > 256) ? (256 - total) : got;
      fwrite(buf, 1, show, stdout);
    }
    total += got;
    if (total > (1u << 20)) {
      printf("\n[truncated after 1 MiB]\n");
      break;
    }
  }
  printf("\n  total body bytes = %lu\n", total);

  pClose(hReq);
  pClose(hConn);
  pClose(hSession);

  printf("\nDone.\n");
  fflush(stdout);
  return 0;
}
