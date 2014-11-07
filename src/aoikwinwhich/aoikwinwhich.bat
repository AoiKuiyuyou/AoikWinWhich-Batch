@echo off
setlocal EnableDelayedExpansion

::/
call :main %*
exit /B

::/ define a |strIndex| func
::# Copied from: http://stackoverflow.com/a/22928259
::--BEG
:strIndex string substring [instance]
    REM Using adaptation of strLen function found at http://www.dostips.com/DtCodeCmdLib.php#Function.strLen

    SETLOCAL ENABLEDELAYEDEXPANSION
    SETLOCAL ENABLEEXTENSIONS
    IF "%~2" EQU "" SET Index=-1 & GOTO strIndex_end
    IF "%~3" EQU "" (SET Instance=1) ELSE (SET Instance=%~3)
    SET Index=-1
    SET String=%~1

    SET "str=A%~1"
    SET "String_Length=0"
    FOR /L %%A IN (12,-1,0) DO (
        SET /a "String_Length|=1<<%%A"
        FOR %%B IN (!String_Length!) DO IF "!str:~%%B,1!"=="" SET /a "String_Length&=~1<<%%A"
    )
    SET "sub=A%~2"
    SET "Substring_Length=0"
    FOR /L %%A IN (12,-1,0) DO (
        SET /a "Substring_Length|=1<<%%A"
        FOR %%B IN (!Substring_Length!) DO IF "!sub:~%%B,1!"=="" SET /a "Substring_Length&=~1<<%%A"
    )

    IF %Substring_Length% GTR %String_Length% GOTO strIndex_end

    SET /A Searches=%String_Length%-%Substring_Length%
    IF %Instance% GTR 0 (
        FOR /L %%n IN (0,1,%Searches%) DO (
            CALL SET StringSegment=%%String:~%%n,!Substring_Length!%%

            IF "%~2" EQU "!StringSegment!" SET /A Instance-=1
            IF !Instance! EQU 0 SET Index=%%n & GOTO strIndex_end
    )) ELSE (
        FOR /L %%n IN (%Searches%,-1,0) DO (
            CALL SET StringSegment=%%String:~%%n,!Substring_Length!%%

            IF "%~2" EQU "!StringSegment!" SET /A Instance+=1
            IF !Instance! EQU 0 SET Index=%%n & GOTO strIndex_end
    ))

:strIndex_end
    EXIT /B %Index%
::--END

:items_exists
REM %~1: items' array-like variable name prefix
REM %~2: items' count
REM %~3: item to check if it exists in the items
    ::/
    setlocal

    ::/
    set items_vnp=%~1

    ::/
    set items_cnt=%~2

    ::/
    set item=%~3

    ::/
    set /A items_imax=items_cnt-1

    for /L %%m in (0,1,!items_imax!) do (
        call set "cur_item=%%!items_vnp![%%m]%%"

        if "!item!" == "!cur_item!" (
            exit /B 0
        )
    )

    exit /B 1
goto:eof

:exts_anyisendof
REM %~1: exts' array-like variable name prefix
REM %~2: exts' count
REM %~3: path to check if it ends with one of the exts
    ::/
    setlocal

    ::/
    set exts_vnp=%~1

    ::/
    set exts_cnt=%~2

    ::/
    set path=%~3

    ::/
    set /A exts_imax=exts_cnt-1

    for /L %%x in (0,1,!exts_imax!) do (
        call set "ext=%%!exts_vnp![%%x]%%"

        ::/ check if the path ends with one of the exts
        REM :: Tried using |findstr| but very slow.
        REM --BEG
        REM set regex=.*\!ext!
        REM echo.!path!|>nul findstr /I /rx "!regex!"
        REM --END

        call :strIndex "!path!" "." -1

        set ext_dot_idx=!errorlevel!

        if ext_dot_idx neq -1 (
            call set path_ext=%%path:~!ext_dot_idx!%%

            if /I "!path_ext!"=="!ext!" (
                exit /B 0
            )
        )
    )

    exit /B 1
goto:eof

::/
:find_executable
REM %~1: prog name or path
    ::/
    setlocal

    ::/
    set prog=%~1

    ::/ 6qhHTHF
    ::/ split into a list of extensions
    set i=0

    for %%e in ("%PATHEXT:;=";"%") do (
        ::/
        set _ext=%%~e

        ::/ 2gqeHHl
        REM:: remove empty
        if not "!_ext!" == "" (
            call set "ext_s[%%i%%]=!_ext!"
            set /A i=i+1
        )
    )

    set /A exts_cnt=i

    set /A ext_imax=exts_cnt-1

    ::/ 6bFwhbv
    set i=0
    ::: loop index

    set res_path_i=0
    ::: result index

    for %%x in ("" "%PATH:;=";"%") do (
        ::/ 7rO7NIN
        REM :: synthesize a path with the dir and prog
        if "%%~x" == "" (
            if "!i!" == "0" (
                set path=%prog%
            ) else (
                ::/ ignore empty dir unless it's the first
                set path=
            )
        ) else (
            set path=%%~x\%prog%
        )

        ::/
        if not "!path!" == "" (
            ::/ 6kZa5cq
            REM :: assume the path has extension, check if it is an executable
            if exist "!path!" if not exist "!path!\" (
                ::/ check if the path ends with one of the exts
                call :exts_anyisendof "ext_s" "!exts_cnt!" "!path!"
                ::: Y
                if "!errorlevel!" == "0" (
                    ::/ check if the path exists in result
                    call :items_exists "res_path_s" "!res_path_i!" "!path!"
                    ::: N
                    if not "!errorlevel!" == "0" (
                        ::/ add to res_path_s
                        call set "res_path_s[!res_path_i!]=!path!"

                        ::/
                        set /A res_path_i=res_path_i+1
                    )
                )
            )

            ::/ 2sJhhEV
            REM :: assume the path has no extension
            for /L %%k in (0,1,%ext_imax%) do (
                ::/ 6k9X6GP
                REM :: synthesize a new path with the path and the executable extension
                set ext=!ext_s[%%k]!

                set path_plus_ext=!path!!ext!

                ::/ 6kabzQg
                REM :: check if it is an executable
                if exist "!path_plus_ext!" if not exist "!path_plus_ext!\" (
                    ::/ check if the path exists in result
                    call :items_exists "res_path_s" "!res_path_i!" "!path_plus_ext!"
                    ::: N
                    if not "!errorlevel!" == "0" (
                        ::/ add to res_path_s
                        call set "res_path_s[!res_path_i!]=!path_plus_ext!"

                        ::/
                        set /A res_path_i=res_path_i+1
                    )
                )
            )
        )

        ::/
        set /A i=i+1
    )

    ::/ 5fWrcaF
    ::/ has found none, exit
    if %res_path_i% equ 0 (
        ::/ 3uswpx0
        exit /B
    )

    ::/ 9xPCWuS
    ::/ has found some, output
    set /A res_path_imax=res_path_i-1

    for /L %%n in (0,1,%res_path_imax%) do (
        echo !res_path_s[%%n]!
    )
goto:eof

:main
    ::/
    setlocal

    ::/ 9mlJlKg
    ::/ check if one cmd arg is given
    set args_len=0
    for %%x in (%*) do set /A args_len+=1

    :: N
    if not "%args_len%" == "1" (
        ::/ 7rOUXFo
        ::/ print program usage
        echo.Usage: aoikwinwhich PROG
        echo.
        echo.#/ PROG can be either name or path
        echo.aoikwinwhich notepad.exe
        echo.aoikwinwhich C:\Windows\notepad.exe
        echo.
        echo.#/ PROG can be either absolute or relative
        echo.aoikwinwhich C:\Windows\notepad.exe
        echo.aoikwinwhich Windows\notepad.exe
        echo.
        echo.#/ PROG can be either with or without extension
        echo.aoikwinwhich notepad.exe
        echo.aoikwinwhich notepad
        echo.aoikwinwhich C:\Windows\notepad.exe
        echo.aoikwinwhich C:\Windows\notepad

        ::/ 3nqHnP7
        exit /B
    )

    ::/ 9m5B08H
    ::/ get name or path of a program from cmd arg
    set prog=%~1

    ::/ 8ulvPXM
    ::/ find executables
    call :find_executable "!prog!"

    ::/ 4s1yY1b
    exit /B

goto:eof
