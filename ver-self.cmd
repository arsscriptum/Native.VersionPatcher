: Add version info resource with some strings and a help text resource file to verpatch.exe
: (also kind of self test)

: Run this in Release or Debug dir.
:
set _ver="1.0.10.24 [%date%]"
set _s1=/s desc "PE version patcher tool" 
set _s1=%_s1% /s copyright "(C) 1998-2012, pavel_a"
set _s1=%_s1% /pv "1.0.0.1-CodeProject" 
set _s2=/s private "%USERNAME%@%USERDOMAIN%"

: Note: 64 is resource ID of help text, hardcoded in the program
set _resfile=/rf #64 %~dp0\usage.txt

: Run a copy of verpatch on itself:

copy verpatch.exe v.exe || exit /b 1

v.exe verpatch.exe /va %_ver% %_s1% %_s2% %_resfile% 

@echo Errorlevel=%errorlevel%

@rem del v.exe
