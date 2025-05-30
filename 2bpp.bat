@echo off & setlocal enableDelayedExpansion

rem benchmark 1
set t1=%time%

rem Script must be run by drag & drop  FOLDER  onto script.
if "%~1" equ "" (
	echo PATH required...
	echo Drag ^& Drop   FOLDER   into %~nx0 to try again.
	pause & exit
)

call :init

rem automatically name the sprite by the name of the PATH
set "name=%~1"
set "name=!name:%cd%=!"
set "name=!name: =!"
set "name=!name:~1!"

rem temp change directory
pushd %~1

rem color palette / edit colors here, color[0] will be made transparent
set /a "color[0]=0","color[1]=7","color[2]=15","color[3]=8"
rem if palette file exists, use that color palette
if exist palette.txt (
	for /f "tokens=*" %%i in (palette.txt) do (
		set /a "colors+=1"
		for /f "tokens=1-3 delims=;" %%1 in ("%%~i") do (
			set /a "color[!colors!]=(%%~1 * 6 / 256) * 36 + (%%~2 * 6 / 256) * 6 + (%%~3 * 6 / 256) + 16"
		)
	)
	set "colors="
)

rem collect the hex from the .chr files and create our .txt, but if it already exists,
rem we can skip this part, and load directly from sprite.txt
if not exist sprite.txt (

	rem convert .chr files to hex, and output to .txt
	echo Loading hex values...
	for /f "tokens=*" %%a in ('dir /b "%~1"') do (
		set "file=%%~a"
		if /i "!file:~-4!" equ ".chr" (
			
			certutil -encodehex !file! !file:~0,-4!.hex >nul
			
			<"!file:~0,-4!.hex" ( for /l %%i in (1,1,18) do set /p "line[%%i]=" )
			
			del /f /q "!file:~0,-4!.hex" >nul

			for %%i in (1 2 17 18) do (
				set "line[%%i]=!line[%%i]:~5,48!"
				set "line[%%i]=!line[%%i]:  = !"
			)
			echo "!line[1]! !line[2]! !line[17]! !line[18]!">>%name%.txt
		)
	)
	for /l %%i in (1,1,18) do set "line[%%i]="
	
	echo Loading Sprite...
	set "spriteFrames=-1"
	rem each iteration is 4 sprites, and then stitched together to make one full sprite. In total 6 sprites are made from the total of 24
	for /f "tokens=*" %%i in (%name%.txt) do (
	
		set /a "spriteFrames+=1"
	
		set "current=%%~i"
		
		rem 193 = max length for 4 sprites
		for /l %%j in (0,24,193) do ( rem for each %%i, create 8 lists = 4 sprites
			set /a "c=%%j / 24 + 1"
			set "list!c!=!current:~%%j,23!"
		)

		for %%k in (%name%.frame!spriteFrames!) do (
			
			rem make and stitch the 4 sprites together
			%_2bpp% "!list1!"."!list2!"
			set "%%~k=%\e%7!tile!%\e%8%\e%[8C"
			
			%_2bpp% "!list3!"."!list4!"
			set "%%~k=!%%~k!%\e%7!tile!%\e%8%\e%[8B%\e%[8D"
			
			%_2bpp% "!list5!"."!list6!"
			set "%%~k=!%%~k!%\e%7!tile!%\e%8%\e%[8C"
			
			%_2bpp% "!list7!"."!list8!"
			set "%%~k=!%%~k!!tile!%\e%[m"
		
			rem add transparency
			for /l %%i in (8,-1,1) do (
				for %%j in ("!spaceBuffer:~0,%%i!") do (
					set "%%~k=!%%~k:%\e%[48;5;%color[0]%m%%~j=%\e%[%%~iC!"

				)
			)
			
			
		)
	)
	
	rem capture raw output as useable variables
	echo Saving data to variables...
	for /l %%i in (0,1,!spriteFrames!) do (
		echo set "%name%.frame%%i=!%name%.frame%%i!">>sprite.txt
	)
	

 ) else (
	rem if the sprite.txt already exist, just load this instead.
	for /f "tokens=*" %%i in (sprite.txt) do (
		set /a "spriteFrames+=1"
		%%~i
		for /f "tokens=1 delims=." %%a in ("%%~i") do (
			set "name=%%~a"
			set "name=!name:~5!"
		)
	)
	set /a "spriteFrames-=1"
)

rem pop back to home directory
popd

rem benchmark 2
set t2=%time%
for /F "tokens=1-8 delims=:.," %%a in ("%t1: =0%:%t2: =0%") do set /a "td=(((1%%e-1%%a)*60)+1%%f-1%%b)*6000+1%%g%%h-1%%c%%d, td+=(td>>31) & 8640000"

rem ### Main Loop ###################################################################

%@getTimeCS:?=t1%
%while% ( %@getTimeCS:?=t2%, "deltatime=t2-t1"

	if !deltatime! gtr 5 (
		set /a "t1=t2", "frames=(frames + 1) %% (spriteFrames + 1)"
		
		for %%f in (!frames!) do echo %\e%[2J%\e%[7;7H!%name%.frame%%f!%\e%[HLoad time: !td!cs ; ID: %%f
		
	)
)

rem #################################################################################

:init
mode 28,28
rem hide cursor
<nul set /p "=%\e%[?25l"
rem necessary for transparency later
set "spaceBuffer=                "



rem newLine for macros
(set \n=^^^
%= This creates an escaped Line Feed - DO NOT ALTER =%
)

for /f %%a in ('echo prompt $E^| cmd') do set "\e=%%a" %= \e =%

set @getTimeCS=for /f "tokens=1-4 delims=:.," %%a in ("^!time: =0^!") do set /a "?=(((1%%a*60)+1%%b)*60+1%%c)*100+1%%d"

set "while=for /l %%i in (1 1 16)do if defined do.while"
set "while=set do.while=1&!while! !while! !while! !while! !while! "
set "endWhile=set "do.while=""

rem %_2bpp% "list1"."list2" where list1 & list2 contain 8x 2-digit hex values
set _2bpp=for %%# in (1 2) do if %%#==2 ( for /f "tokens=1,2 delims=." %%1 in ("^!args^!") do (%\n%
	set "list[0]=%%~1" ^& set "list[1]=%%~2" ^& set "tile="%\n%
	set "list[0]=^!list[0]:~2,-1^!"%\n%
	for /l %%i in (0,3,21) do (%\n%
		set "lastc="%\n%
		for /f "tokens=1,2" %%x in ("^!list[0]:~%%i,2^! ^!list[1]:~%%i,2^!") do (%\n%
			for /l %%b in (7,-1,0) do (%\n%
				set /a "_a=((0x%%~x >> %%b) & 1)", "_b=((0x%%~y >> %%b) & 1)"%\n%
				set /a "c=(_b + _a * 2)"%\n%
				if "^!lastc^!" neq "^!c^!" (%\n%
					for %%c in (^^!c^^!) do set "tile=^!tile^!%\e%[48;5;^!color[%%c]^!m "%\n%
				) else (%\n%
					set "tile=^!tile^! "%\n%
				)%\n%
				set "lastc=^!c^!"%\n%
			)%\n%
		)%\n%
		set "tile=^!tile^!%\e%[8D%\e%[B"%\n%
	)%\n%
)) else set args=
goto :eof
