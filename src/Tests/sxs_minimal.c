
#include <stdio.h>
#include <windows.h>

#include <commctrl.h>
#include <commdlg.h>

int main() {

  INITCOMMONCONTROLSEX icc = {sizeof(INITCOMMONCONTROLSEX), ICC_WIN95_CLASSES};
  printf("RESULT: %x\n", InitCommonControlsEx(&icc));
  return 0;
}
