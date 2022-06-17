REM +------------------------------------------------------------------
REM | VALIDATE COMMAND-LINE PARAMETERS                                 
REM +------------------------------------------------------------------

if (%1)==() goto USAGE
if (%2)==() goto USAGE
if (%3)==() goto USAGE

REM +-------------------------------------------------------------------
REM | VALIDATE ENVIRONMENT VARIABLES                                    
REM +-------------------------------------------------------------------
set ORACLE_SID=%1%
set SambaDir=%2%
set password=%3%

if not exist %BACKUP_PATH%\%ORACLE_SID% {
    md %BACKUP_PATH%\%ORACLE_SID%
}

REM +--------------------------------------------------------------------
REM | DECLARE ALL GLOBAL VARIABLES.                                      
REM +--------------------------------------------------------------------

set CMDFILE=%BACKUP_PATH%\%ORACLE_SID%\rman.rcv
set ERRORFILE=%BACKUP_PATH%\NDPBackupError.log

REM +--------------------------------------------------------------------
REM | REMOVE OLD LOG AND RMAN COMMAND FILES.                             
REM +--------------------------------------------------------------------

del /q %CMDFILE%

REM +--------------------------------------------------------------------
REM | WRITE RMAN COMMAND SCRIPT.                                         
REM +--------------------------------------------------------------------

echo run { > %CMDFILE%
echo CONFIGURE CONTROLFILE AUTOBACKUP ON; >> %CMDFILE%
echo ALLOCATE CHANNEL ch1 TYPE SBT PARMS >> %CMDFILE%
echo 'ENV=(BACKUP_DIR=%SambaDir%)'; >> %CMDFILE%
echo SQL "ALTER SYSTEM ARCHIVE LOG CURRENT"; >> %CMDFILE%
echo BACKUP ARCHIVELOG ALL FORMAT "log_%%d_%%s_%%p_%%u_%%T.arch"; >> %CMDFILE%
echo RELEASE CHANNEL ch1; >> %CMDFILE%
echo } >> %CMDFILE%
echo exit; >> %CMDFILE%



REM +---------------------------------------------------------------------
REM | PERFORM RMAN BACKUP.                                                
REM +---------------------------------------------------------------------

rman target sys/Passw0rd nocatalog cmdfile=%CMDFILE% 


REM +---------------------------------------------------------------------
REM | SCAN THE RMAN LOGFILE FOR ERRORS.                                   
REM +---------------------------------------------------------------------

IF %ERRORLEVEL% NEQ 0 (
echo BACKUP ORACLE FAILED > %ERRORFILE%
)

REM +---------------------------------------------------------------------
REM | END THIS SCRIPT.                                                    
REM +---------------------------------------------------------------------

goto END

REM +----------------------------------------------------------------------
REM |                    ***   END OF SCRIPT   ***                        
REM +----------------------------------------------------------------------

REM +----------------------------------------------------------------------
REM | LABEL DECLARATION SECTION.                                           
REM +----------------------------------------------------------------------

:USAGE
echo Usage:  oracle_incrbackup.bat oracle_sid samba_dir password
goto END

:ENV_VARIABLES
echo ERROR:  You must set the following environment variables before
echo         running this script:
echo             ORALOG       = Directory used to write logfile to
echo             ORATMP       = Directory used to write temporary files to
goto END

:END
@echo on