@echo off
title Text-to-Speech Web Studio
echo ========================================================
echo  Starting Text-to-Speech Web Studio...
echo ========================================================
cd /d "%~dp0"
timeout /t 2 /nobreak >nul
start http://localhost:5050
"C:\flutter\bin\cache\dart-sdk\bin\dart.exe" run tts_server.dart
pause
