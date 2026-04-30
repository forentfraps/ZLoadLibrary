clang file_dialog.c -o file_dialog.exe -municode -lcomdlg32 -luser32

llvm-rc /fo sxs_minimal.res sxs_minimal.rc
clang sxs_minimal.c sxs_minimal.res -o sxs_minimal.exe -municode -lcomdlg32 -luser32 -lcomctl32

clang urlmon_imports.c -o urlmon_imports.exe

clang urlmon_zones.c -o urlmon_zones.exe -lole32

clang winhttp_test.c -o winhttp_test.exe
