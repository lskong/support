@echo off
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"
setlocal enabledelayedexpansion

@echo off
rem set env
set SERVICENAME=NDPAgent
set SERVICEVER=4.3.7
set OTHERPORT=8200
set NDPAGENTPATH=C:\Program Files (x86)\ZTE NewStart\release

rem check serive install
:checkservice
sc query NDPAgent >nul
if ERRORLEVEL 1060  call :installservice

rem check port
:chekcport
netstat -an|findstr %OTHERPORT% >nul
if ERRORLEVEL 1 call :startservice


rem open ping rules
:openping
set INPUT_RULE_NAME="Ping"
netsh advfirewall firewall show rule name=%INPUT_RULE_NAME% >nul
if not ERRORLEVEL 1 (
    echo Sorry, rule %INPUT_RULE_NAME% already exists!
) else (
    netsh advfirewall firewall add rule name=%INPUT_RULE_NAME% dir=in protocol=icmpv4 action=allow
    echo rule %INPUT_RULE_NAME% Created successfully!
)

rem open custom rules
FOR %%c in (%OTHERPORT%) do (
    SET PORT=%%c
    call :addrule
)

:end
echo exit 666
exit

rem install service
:installservice
"%NDPAGENTPATH%\NDP_%SERVICEVER%.msi"
sc config VSS start= auto
sc config swprv start= auto 
net start VSS
net start swprv
goto chekcport

rem start service
:startservice
sc query  %SERVICENAME% | find "RUNNING" || net start %SERVICENAME%
goto openping

rem input rule
:addrule
set INPUTPORT=%PORT%
set INPUT_RULE_NAME="%INPUTPORT%_input"
netsh advfirewall firewall show rule name=%INPUT_RULE_NAME% >nul
if not ERRORLEVEL 1 (
    echo Sorry, rule %INPUT_RULE_NAME% already exists.
) else (
    netsh advfirewall firewall add rule name=%INPUT_RULE_NAME% dir=in action=allow protocol=TCP localport=%INPUTPORT%
    echo rule %INPUT_RULE_NAME% Created successfully.
)
set OUTPORT=%PORT%
set OUT_RULE_NAME="%OUTPORT%_output"
netsh advfirewall firewall show rule name=%OUT_RULE_NAME% >nul
if not ERRORLEVEL 1 (
    echo Sorry, rule %OUT_RULE_NAME% already exists.
) else (
    netsh advfirewall firewall add rule name=%OUT_RULE_NAME% dir=out action=allow protocol=TCP localport=%OUTPORT%
    echo rule %OUT_RULE_NAME% Created successfully.
)
goto end


:::installtelnetclient
::dism /Online /Enable-Feature /FeatureName:TelnetClient
::::dism /Online /Disable-Feature /FeatureName:TelnetClient
::goto end