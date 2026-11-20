@echo off
title Build TextSpeech Windows App
echo ========================================================
echo  Building TextSpeech Windows Desktop Release (.exe)...
echo ========================================================
cd /d "%~dp0"

call "C:\flutter\bin\flutter.bat" build windows --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo  Build Successful!
    echo  Output folder:
    echo  %~dp0build\windows\x64\runner\Release\
    echo.
    echo  Executable:
    echo  %~dp0build\windows\x64\runner\Release\text_speech_app.exe
    echo ========================================================
) else (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
)
pause
