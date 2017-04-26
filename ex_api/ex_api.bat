@echo off

echo        Assembling library modules.
echo.
\masm32\bin\ml /c /coff ex_api.asm
\masm32\bin\lib *.obj /out:ex_api.lib

dir ex_api.*

@echo off
pause