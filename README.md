# Verpatch - a tool to patch win32 version resources on .exe or .dll files,

Version: 1.0.10 (02-Sep-2012)

Verpatch is a command line tool for adding and editing the version information
of Windows executable files (applications, DLLs, kernel drivers)
without rebuilding the executable.

It can also add or replace Win32 (native) resources, and do some other
modifications of executable files.

Verpatch sets ERRORLEVEL 0 on success, otherwise errorlevel is non-zero.
Verpatch modifies files in place, so please make copies of precious files.


Command line syntax
===================

verpatch filename [version] [/options]

Where
 - filename : any Windows PE file (exe, dll, sys, ocx...) that can have version resource
 - version : one to four decimal numbers, separated by dots, ex.: 1.2.3.4
   Additional text can follow the numbers; see examples below. Ex.: "1.2.3.4 extra text"

Common Options:

/va - creates a version resource. Use when the file has no version resource at all,
     or existing version resource should be replaced.
     If this option not specified, verpatch will read version resourse from the file.
/s name "value" - add a version resource string attribute
     The name can be either a full attribute name or alias; see below.
/sc "comment" - add or replace Comments string (shortcut for /s Comments "comment")
/pv <version>   - specify Product version
    where <version> arg has same form as the file version (1.2.3.4 or "1.2.3.4 text")
/high - when less than 4 version numbers, these are higher numbers.


Other options:

/fn - preserves Original filename, Internal name in the existing version resource of the file.
/langid <number> - language id for new version resource.
     Use with /va. Default is Language Neutral.
     <number> is combination of primary and sublanguage IDs. ENU is 1033 or 0x409.
/vo - outputs the version info in RC format to stdout.
     This can be used with /xi to dump a version resource without modification.
     Output of /vo can be pasted to a .rc file and compiled with rc.
/xi- test mode. does all operations in memory but does not modify the file
/xlb - test mode. Re-parses the version resource after modification.
/rpdb - removes path to the .pdb file in debug information; leaves only file name.
/rf #id file - add or replace a raw binary resource from file (see below)
/noed - do not check for extra data appended to exe file
/vft2 num - specify driver subtype (VFT2_xxx value, see winver.h)
     The application type (VFT_xxx) is retained from the existing version resource of the file,
     or filled automatically, based on the filename extension (.exe->app, .sys->driver, anything else->dll)

