#define _UNICODE

#include <windows.h>

#include <commdlg.h>

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    PWSTR pCmdLine, int nCmdShow) {
  OPENFILENAMEW ofn;
  WCHAR fileName[MAX_PATH] = L"";

  ZeroMemory(&ofn, sizeof(ofn));
  ofn.lStructSize = sizeof(ofn);
  ofn.lpstrFile = fileName;
  ofn.nMaxFile = MAX_PATH;
  ofn.lpstrFilter = L"All Files\0*.*\0Text Files\0*.TXT\0";
  ofn.nFilterIndex = 1;
  ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
  ofn.lpstrDefExt = L"txt";

  if (!GetOpenFileNameW(&ofn)) {
    MessageBoxW(NULL, L"No file selected.", L"Info", MB_OK);
    return 0;
  }

  HANDLE hFile = CreateFileW(fileName, GENERIC_READ, FILE_SHARE_READ, NULL,
                             OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

  if (hFile == INVALID_HANDLE_VALUE) {
    MessageBoxW(NULL, L"Could not open file.", L"Error", MB_OK | MB_ICONERROR);
    return 1;
  }

  DWORD fileSize = GetFileSize(hFile, NULL);
  if (fileSize == INVALID_FILE_SIZE) {
    CloseHandle(hFile);
    MessageBoxW(NULL, L"Could not get file size.", L"Error",
                MB_OK | MB_ICONERROR);
    return 1;
  }

  char *buffer =
      (char *)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, fileSize + 1);
  if (!buffer) {
    CloseHandle(hFile);
    return 1;
  }

  DWORD bytesRead;
  if (!ReadFile(hFile, buffer, fileSize, &bytesRead, NULL)) {
    HeapFree(GetProcessHeap(), 0, buffer);
    CloseHandle(hFile);
    MessageBoxW(NULL, L"Could not read file.", L"Error", MB_OK | MB_ICONERROR);
    return 1;
  }

  CloseHandle(hFile);

  // Convert to wide char for MessageBox
  int wideLen = MultiByteToWideChar(CP_UTF8, 0, buffer, -1, NULL, 0);
  WCHAR *wideBuffer = (WCHAR *)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY,
                                         wideLen * sizeof(WCHAR));

  MultiByteToWideChar(CP_UTF8, 0, buffer, -1, wideBuffer, wideLen);

  MessageBoxW(NULL, wideBuffer, L"File Contents", MB_OK);

  HeapFree(GetProcessHeap(), 0, wideBuffer);
  HeapFree(GetProcessHeap(), 0, buffer);

  return 0;
}
