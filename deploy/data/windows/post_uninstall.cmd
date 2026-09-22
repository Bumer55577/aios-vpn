set AiosPath=%~dp0
echo %AiosPath%

rem Define directories for logs
set "ORG_DIR=%AppData%\AIOS.VPN"
set "USER_APP_DIR=%ORG_DIR%\AIOSVPN"
set "USER_LOG_DIR=%USER_APP_DIR%\log"
set "SYS_APP_DIR=%ProgramData%\AIOSVPN"
set "SYS_LOG_DIR=%SYS_APP_DIR%\log"
set "SYS_LOG_FILE=%SYS_LOG_DIR%\AIOSVPN-service.log"

timeout /t 1
sc stop AIOSVPN-service
sc delete AIOSVPN-service
sc stop AIOSWGTunnel$AIOSVPN
sc delete AIOSWGTunnel$AIOSVPN
taskkill /IM "AIOSVPN-service.exe" /F
taskkill /IM "AIOSVPN.exe" /F

rem Delete the service log file under ProgramData
if exist "%SYS_LOG_FILE%" del /F /Q "%SYS_LOG_FILE%"
if exist "%SYS_LOG_DIR%" rmdir /S /Q "%SYS_LOG_DIR%"
rem Try to remove application dir if empty
rd "%SYS_APP_DIR%" 2>nul

rem Delete client logs under current user's AppData\Roaming (Organization\Application)
if exist "%USER_LOG_DIR%" rmdir /S /Q "%USER_LOG_DIR%"
rem Try to remove app and org directories if empty
rd "%USER_APP_DIR%" 2>nul
rd "%ORG_DIR%" 2>nul

exit /b 0
