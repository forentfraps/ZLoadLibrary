#include <Winsock2.h>

#include <Windows.h>
#include <stdio.h>

typedef int (*pWSAStartup)(DWORD, WSADATA *);
extern void pebGrabba (void);

int main() {

  pebGrabba();
  void *addr = LoadLibraryA("Ws2_32.dll");

  WSADATA wsaData;
  pWSAStartup wstp = (pWSAStartup)GetProcAddress(addr, "WSAStartup");

  printf("Rerturn val %d\n", wstp(MAKEWORD(2, 2), &wsaData));
  return 0;
}
