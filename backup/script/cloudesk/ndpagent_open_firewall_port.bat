@echo off
rem set env
set OTHERPORT=8200

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