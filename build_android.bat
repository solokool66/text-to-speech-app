@echo off
title Build TextSpeech Android App
echo ========================================================
echo  Building TextSpeech Android APK Release (.apk)...
echo ========================================================
cd /d "%~dp0"

call "C:\flutter\bin\flutter.bat" build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo  Build Successful!
    echo  Output APK location:
    echo  %~dp0build\app\outputs\flutter-apk\app-release.apk
    echo ========================================================
    
    REM Optional: Copy APK to Desktop for convenience
    set /p COPY_DESKTOP="Copy app-release.apk to Desktop? (Y/N, default Y): "
    if /i not "%COPY_DESKTOP%"=="N" (
        copy "%~dp0build\app\outputs\flutter-apk\app-release.apk" "%USERPROFILE%\Desktop\TextSpeech.apk" >nul
        echo Copied to: %USERPROFILE%\Desktop\TextSpeech.apk
    )
) else (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
)
pause
