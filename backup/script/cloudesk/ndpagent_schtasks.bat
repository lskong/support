@echo off
::CheckService
schtasks /create /tn "\Microsoft\Windows\NDPAgent\NDPAgentServiceCheck" /ru system /tr "C:\Program Files (x86)\ZTE NewStart\NDP\ndpagent_schtasks_exec.bat" /sc hourly /mo 2 /st 00:00:00
::CheckApp
::schtasks /create /tn "\Microsoft\Windows\NDPAgent\NDPAgentAppCheck" /ru system /tr "C:\Program Files (x86)\ZTE NewStart\NDP\ndpagent_schtasks_install.bat" /sc weekly /mo 1  /st 0:0:0