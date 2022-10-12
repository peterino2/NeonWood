zig build -fstage1 -Drelease-safe -Dtarget=x86_64-windows
rmdir /S /Q /i zig-out\bin\content
xcopy /s /y /i content zig-out\bin\content
xcopy /y glfw3.dll zig-out\bin\
