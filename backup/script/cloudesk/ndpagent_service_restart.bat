@echo off
rem set env
set SERVICENAME=NDPAgent
net stop %SERVICENAME%
net start %SERVICENAME%


