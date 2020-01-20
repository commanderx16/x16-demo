@ECHO off
WHERE /q acme.exe
IF ERRORLEVEL 1 (
	ECHO Requires ACME is installed in path location
	ECHO Download from https://sourceforge.net/projects/acme-crossass/
	EXIT /B
) ELSE (
	ECHO Building PetDraw X16
	acme -f cbm -o petdrawx16.prg petdrawx16.asm
)