@echo off
if not exist rsrc.rc goto over1
\MASM32\BIN\Rc.exe /v rsrc.rc
\MASM32\BIN\Cvtres.exe /machine:ix86 rsrc.res
:over1
if exist %1.obj del COMTerminal.obj
if exist %1.exe del COMTerminal.exe
\MASM32\BIN\Ml.exe /c /coff COMTerminal.asm
if errorlevel 1 goto errasm
if not exist rsrc.obj goto nores
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS COMTerminal.obj rsrc.obj
if errorlevel 1 goto errlink
dir COMTerminal.*
goto TheEnd
:nores
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS COMTerminal.obj
if errorlevel 1 goto errlink
dir COMTerminal.*
goto TheEnd
:errlink
echo _
echo Link error
goto errexit
:errasm
echo _
echo Assembly Error
goto errexit
:TheEnd
COMTerminal.exe
goto eeexit
:errexit
pause
:eeexit
