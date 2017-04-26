@echo off

echo        Assembling library modules.
echo.
\masm32\bin\ml /c /coff lang.asm
\masm32\bin\lib *.obj /out:lang.lib

dir lang.*

@echo off
pause