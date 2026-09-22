sc stop AIOSWGTunnel$AIOSVPN
sc delete AIOSWGTunnel$AIOSVPN
taskkill /IM "AIOSVPN-service.exe" /F
taskkill /IM "AIOSVPN.exe" /F
exit /b 0
