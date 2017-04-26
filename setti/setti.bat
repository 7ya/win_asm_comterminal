@echo off

echo        Assembling library modules.
echo.
\masm32\bin\ml /c /coff setti.asm
\masm32\bin\lib *.obj /out:setti.lib

dir setti.*

@echo off
pause