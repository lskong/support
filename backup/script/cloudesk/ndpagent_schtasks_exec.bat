@echo off
set ServiceName="NDPAgent"

:CheckService
net start |findstr /I %ServiceName%
if ERRORLEVEL 1 goto StartService

:exit
exit

:StartService
net start %ServiceName% >nul 2>nul