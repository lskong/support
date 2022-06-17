rem \NDR\bin\switch.bat
rem ---------------------------------------------------------------------------
rem Transfer Parameters Description
rem ---------------------------------------------------------------------------
rem %1 Type of statement to be executed after receiving judgment
rem    If it is siwtchover.
rem         "type==siwtchover"
rem    If it is failover.
rem         "type==failover"
rem %2 Oracle database user,Value derived from "db.properties".
rem %3 Oracle database password,Value derived from "db.properties".
rem %4 Oracle database primary ip address. Value derived from "Judging by jar".
rem %5 Oracle database standby ip address. Value derived from "Judging by jar".
rem %6 Oracle database instance, Value derived from "db.properties".
rem %7 Path to this script,Value derived from "db.properties".
rem ---------------------------------------------------------------------------

@echo off
rem Transfer Parameters
set C_USER="%2"
set C_PASSWORD="%3"
set C_HOST_P="%4"
set C_HOST_S="%5"
set C_INSTANCE="%6"
set C_PATH="%7"

rem print log
set C_LOG=\log\switch.log

rem Judgment Parameters %1
if "%1"=="siwtchover"  (
    goto siwtchover
) ^
else if "%1"=="failover" (
    goto failover
) ^
else (
    goto end
)


rem siwtchover
:::siwtchover
::echo %0 %date% %time% >>%C_PATH%%C_LOG%
::sqlplus %C_USER%/%C_PASSWORD%@%C_HOST_P%/%C_INSTANCE% as sysdba @%C_PATH%\primary_to_standby.ora >>%C_PATH%%C_LOG%
::goto end

rem siwtchover
:siwtchover
:: primary to standby
sqlplus %C_USER%/%C_PASSWORD%@%C_HOST_P%/%C_INSTANCE% as sysdba @%C_PATH%\primary_to_standby_force.ora >>%C_PATH%%C_LOG%
echo primary to standby is finish! %date% %time% >>%C_PATH%%C_LOG%
:: standbyto primary
goto standby_to_primary

rem standby to primary
:::standby_to_primary
::echo %0 %date% %time% >>%C_PATH%%C_LOG%
::sqlplus %C_USER%/%C_PASSWORD%@%C_HOST_S%/%C_INSTANCE% as sysdba @%C_PATH%\standby_to_primary.ora >>%C_PATH%%C_LOG%
::goto start_archive_log_apply

rem standby to primary
:standby_to_primary
sqlplus %C_USER%/%C_PASSWORD%@%C_HOST_S%/%C_INSTANCE% as sysdba @%C_PATH%\standby_to_primary_force.ora >>%C_PATH%%C_LOG%
echo standby to primary is finish %date% %time% >>%C_PATH%%C_LOG%
goto start_archive_log_apply

rem start archive log apply
:start_archive_log_apply
sqlplus %C_USER%/%C_PASSWORD%@%C_HOST_P%/%C_INSTANCE% as sysdba @%C_PATH%\start_archive_log_apply.ora >>%C_PATH%%C_LOG%
goto end

rem failover
:failover
sqlplus %C_USER%/%C_PASSWORD%@%C_HOST_S%/%C_INSTANCE% as sysdba @%C_PATH%\standby_failover.ora >>%C_PATH%%C_LOG%
goto end

:end
echo Switch end %date% %time% >>%C_PATH%%C_LOG%