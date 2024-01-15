@echo off & setlocal enableDelayedExpansion

set t1=%time%

if "%~1" equ "" echo PATH required... & echo Drag ^& Drop   FOLDER   into %~nx0 to try again. & pause & exit

call :init

set "name=%~1" & set "name=!name:%cd%=!" & set "name=!name: =!" & set "name=!name:~1!"

pushd %~1

if exist palette.txt (
	for /f "tokens=*" %%i in (palette.txt) do (
		set /a "colors+=1"
		for /f "tokens=1-3 delims=;" %%1 in ("%%~i") do (
			set /a "color[!colors!]=(%%~1 * 6 / 256) * 36 + (%%~2 * 6 / 256) * 6 + (%%~3 * 6 / 256) + 16"
		)
	)
	set "colors="
)

if not exist sprite.txt (

	if exist %name%.txt del /f /q %name%.txt >nul

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
	for /f "tokens=*" %%i in (%name%.txt) do (
	
		set /a "spriteFrames+=1"
	
		set "current=%%~i"
		
		for /l %%j in (0,24,193) do ( 
			set /a "c=%%j / 24 + 1"
			set "list!c!=!current:~%%j,23!"
		)

		for %%k in (%name%.frame!spriteFrames!) do (

			%_2bpp% "!list1!"."!list2!"
			set "%%~k=[y;xH!tile![8A[8C"
			
			%_2bpp% "!list3!"."!list4!"
			set "%%~k=!%%~k!!tile![8D"
			
			%_2bpp% "!list5!"."!list6!"
			set "%%~k=!%%~k!!tile![8C[8A"
			
			%_2bpp% "!list7!"."!list8!"
			set "%%~k=!%%~k!!tile![0m"
		
			for /l %%i in (8,-1,1) do (
				for %%j in ("!spaceBuffer:~0,%%i!") do (
					set "%%~k=!%%~k:[48;5;%color[0]%m%%~j=[%%~iC!"
				)
			)
		)
	)
	
	if not exist sprite.txt (
		echo Saving data to variables...
		for /l %%i in (0,1,!spriteFrames!) do (
			echo set "%name%.frame%%i=!%name%.frame%%i!">>sprite.txt
		)
	)

) else (

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

popd

set t2=%time%
for /F "tokens=1-8 delims=:.," %%a in ("%t1: =0%:%t2: =0%") do set /a "td=(((1%%e-1%%a)*60)+1%%f-1%%b)*6000+1%%g%%h-1%%c%%d, td+=(td>>31) & 8640000"


:main
	set /a "frames+=1", "id=frames %% (spriteFrames + 1)"
	
	echo [2J!%name%.frame%ID%:y;x=7;7![HLoad time: !td!cs ; ID: !id!
	
	for /l %%i in (1,%rotationSpeed%,1000000) do rem
goto :main


:init
mode 28,28
<nul set /p "=[?25l"
set "spaceBuffer=                "

set /a "color[0]=0","color[1]=7","color[2]=15","color[3]=8",   "rotationSpeed=10"

(set \n=^^^
%= This creates an escaped Line Feed - DO NOT ALTER =%
)

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
					for %%c in (^^!c^^!) do set "tile=^!tile^![48;5;^!color[%%c]^!m "%\n%
				) else (%\n%
					set "tile=^!tile^! "%\n%
				)%\n%
				set "lastc=^!c^!"%\n%
			)%\n%
		)%\n%
		set "tile=^!tile^![8D[B"%\n%
	)%\n%
)) else set args=
goto :eof