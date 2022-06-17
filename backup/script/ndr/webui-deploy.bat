@echo off
color 3f
title QDR install bat
set qdr_home=%QDR_HOME%
set qdr_home_p=%QDR_HOME_P%

:: set database type
:db_type
set db_type=oracle
set /p db_type="Enter database type oracle/mysql [ default oracle ]: "
echo;
echo =======================================================
echo The database type you entered is [ %db_type% ]
echo =======================================================
echo;
if "%db_type%"=="oracle"  (
    goto oracle
) ^
else if "%db_type%"=="mysql" (
    goto mysql
) ^
else (
    echo Error! Database type %db_type% Not defined,Please enter again.
    goto db_type
)


:: =====================================================================
:: oracle databaes config       START
:: =====================================================================
:oracle
set local_ip=127.0.0.1
set /p local_ip="Enter local ip adress [ default: 127.0.0.1 ]: "
set remote_ip=127.0.0.1
set /p remote_ip="Enter remote ip address [ default: 127.0.0.1 ]: "
set db_user=sys
set /p db_user="Enter the oracle account [ default: sys ]: "
set db_password=123456
set /p db_password="Enter the oracle password [ default: 123456 ]: "
set db_instance=orcl
set /p db_instance="Enter the oracle instance [ default: orcl ]: "
set web_user=admin
set /p web_user="Enter the WebUi account [ default: admin ]: "
set web_password=123456
set /p web_password="Enter the WebUi password [ default: 123456 ]: "
echo;
echo =======================================================
echo The database is [ %db_type% ]
echo The database loacl ip address is [ %local_ip% ]
echo The database remote ip address is [ %remote_ip% ]
echo The database account is [ %db_user% ]
echo The database password is [ %db_password% ]
echo The database instance is [ %db_instance% ]
echo The WebUi account is [ %web_user% ]
echo The WebUi password is [ %web_password% ]
echo The path is [ %qdr_home% ]
echo The path_p is [ %qdr_home_p% ]
echo =======================================================
echo;
set db_config=yes
echo Please Confirm! 'yes' continue, 'no' re-reten, 'quit' exit install.
set /p db_config="Confirm! [ yes | no | quit ]: "
echo;
echo Confirm! [ %db_config% ]
if /i "%db_config%"=="yes" goto config_json
if /i "%db_config%"=="no"  goto db_type
if /i "%db_config%"=="quit"  goto end

:: Generate oracle config files
:config_json
echo;
set config_file=config.json
set config_file_path=%qdr_home%\dashboard\ndr-uifront-end\webapps\static
echo [config_debug]: Generated '%config_file%' file 
(
    echo {
    echo   "BASE_URL": "http://%local_ip%:8310"
    echo } 
) > %config_file_path%\%config_file%
echo [config_debug]: %config_file_path%\%config_file%
echo [config_debug]: '%config_file%' file Generated success!
echo;

set config_file=db.properties
set config_file_path=%qdr_home%\dashboard\ndr-uiback-end
echo [config_debug]: Generated '%config_file%' file 
(
    echo db_url_oracle=jdbc:oracle:thin:@%local_ip%:1521:%db_instance%
    echo user = %db_user%
    echo password = %db_password%
    echo instance = %db_instance%
    echo enable_dg = true
    echo dg_script_dir = %qdr_home_p%\\bin\\switch
    echo local_db_ip = %local_ip%
    echo remote_db_ip = %remote_ip%
    echo check_cycle = 480
    echo heartbeat_port = 8310
    echo heartbeat_host = %remote_ip%
    echo web_user = %web_user%
    echo web_password = %web_password%
) > %config_file_path%\%config_file%
echo [config_debug]: %config_file_path%\%config_file%
echo [config_debug]: '%config_file%' file Generated success!
echo;

set config_file=db.properties.xml
set config_file_path=%qdr_home%\dashboard\ndr-uiback-end
echo [config_debug]: Generated '%config_file%' file 
(
    echo ^<configuration^>
    echo    ^<id^>Ndr-uiback-end^</id^>
    echo    ^<name^>Ndr-uiback-end^</name^>
    echo    ^<description^>Ndr-ui Back-end server^</description^>
    echo    ^<executable^>java^</executable^>
    echo    ^<arguments^>-jar %qdr_home%\dashboard\ndr-uiback-end\db.properties.jar --spring.config.location=./db.properties --server.port=8310^</arguments^>
    echo     ^<startmode^>Automatic^</startmode^>
    echo    ^<logpath^>%qdr_home%\dashboard\ndr-uiback-end\logs^</logpath^>
    echo    ^<log mode="roll-by-time"^>
    echo     ^<pattern^>yyyyMMdd^</pattern^>
    echo    ^</log^>
    echo ^</configuration^>
) > %config_file_path%\%config_file%
echo [config_debug]: %config_file_path%\%config_file%
echo [config_debug]: '%config_file%' file Generated success!
echo;
echo;
:: =====================================================================
:: oracle databaes config       END
:: =====================================================================

goto start_service


:: =====================================================================
:: mysql databaes config       START
:: =====================================================================
:mysql
set master_standby=master
set /p master_standby="Enter master/standby adress [ default: master ]: "
set local_ip=127.0.0.1
set /p local_ip="Enter local ip adress [ default: 127.0.0.1 ]: "
set remote_ip=127.0.0.1
set /p remote_ip="Enter remote ip address [ default: 127.0.0.1 ]: "
set db_user=simon
set /p db_user="Enter the mysql account [ default: simon ]: "
set db_password=123456
set /p db_password="Enter the mysql password [ default: 123456 ]: "
set web_user=admin
set /p web_user="Enter the WebUi account [ default: admin ]: "
set web_password=123456
set /p web_password="Enter the WebUi password [ default: 123456 ]: "
echo;
echo =======================================================
echo The local is [ %master_standby% ]
echo The database is [ %db_type% ]
echo The database loacl ip address is [ %local_ip% ]
echo The database remote ip address is [ %remote_ip% ]
echo The database account is [ %db_user% ]
echo The database password is [ %db_password% ]
echo The WebUi account is [ %web_user% ]
echo The WebUi password is [ %web_password% ]
echo The path is [ %qdr_home% ]
echo The path_p is [ %qdr_home_p% ]
echo =======================================================
echo;
set db_config=yes
echo Please Confirm! 'yes' continue, 'no' re-reten, 'quit' exit install.
set /p db_config="Confirm! [ yes | no | quit ]: "
echo;
echo Confirm! [ %db_config% ]
if /i "%db_config%"=="yes" goto config_json_mysql
if /i "%db_config%"=="no"  goto db_type
if /i "%db_config%"=="quit"  goto end

:: Generate mysql config files
:config_json_mysql
echo;
set config_file=config.json
set config_file_path=%qdr_home%\dashboard\ndr-uifront-end\webapps\static
echo [config_debug]: Generated '%config_file%' file 
(
    echo {
    echo   "BASE_URL": "http://%local_ip%:8310"
    echo } 
) > %config_file_path%\%config_file%
echo [config_debug]: %config_file_path%\%config_file%
echo [config_debug]: '%config_file%' file Generated success!
echo;

if /i "%master_standby%"=="master" goto master_file
if /i "%master_standby%"=="standby" goto standby_file

:master_file
set config_file=db.properties
set config_file_path=%qdr_home%\dashboard\ndr-uiback-end
echo [config_debug]: Generated '%config_file%' file 
(
    echo db_url_mysql=jdbc:mysql://%local_ip%:3306/simon_sym?useUnicode=true^&characterEncoding=utf-8^&useSSL=false^&serverTimezone=GMT%%2B8
    echo user = %db_user%
    echo password = %db_password%
    echo api_host = %local_ip%
    echo api_port = 8340
    echo api_host_system_version = %OS%
    echo target_host = %remote_ip%
    echo target_port = 8341
    echo target_host_system_version = %OS%
    echo heartbeat_port = 8310
    echo heartbeat_host = %remote_ip%
    echo web_user = %web_user%
    echo web_password = %web_password%
) > %config_file_path%\%config_file%
echo [config_debug]: %config_file_path%\%config_file%
echo [config_debug]: '%config_file%' file Generated success!
echo;
goto db_properties_xml

:standby_file
set config_file=db.properties
set config_file_path=%qdr_home%\dashboard\ndr-uiback-end
echo [config_debug]: Generated '%config_file%' file 
(
    echo db_url_mysql=jdbc:mysql://%local_ip%:3306/simon_sym?useUnicode=true^&characterEncoding=utf-8^&useSSL=false^&serverTimezone=GMT%%2B8
    echo user = %db_user%
    echo password = %db_password%
    echo api_host = %local_ip%
    echo api_port = 8341
    echo api_host_system_version = %OS%
    echo target_host = %remote_ip%
    echo target_port = 8340
    echo target_host_system_version = %OS%
    echo heartbeat_port = 8310
    echo heartbeat_host = %remote_ip%
    echo web_user = %web_user%
    echo web_password = %web_password%
) > %config_file_path%\%config_file%
echo [config_debug]: %config_file_path%\%config_file%
echo [config_debug]: '%config_file%' file Generated success!
echo;
goto db_properties_xml


:db_properties_xml
set config_file=db.properties.xml
set config_file_path=%qdr_home%\dashboard\ndr-uiback-end
echo [config_debug]: Generated '%config_file%' file 
(
    echo ^<configuration^>
    echo    ^<id^>Ndr-uiback-end^</id^>
    echo    ^<name^>Ndr-uiback-end^</name^>
    echo    ^<description^>Ndr-ui Back-end server^</description^>
    echo    ^<executable^>java^</executable^>
    echo    ^<arguments^>-jar %qdr_home%\dashboard\ndr-uiback-end\db.properties.jar --spring.config.location=./db.properties --server.port=8310^</arguments^>
    echo     ^<startmode^>Automatic^</startmode^>
    echo    ^<logpath^>%qdr_home%\dashboard\ndr-uiback-end\logs^</logpath^>
    echo    ^<log mode="roll-by-time"^>
    echo     ^<pattern^>yyyyMMdd^</pattern^>
    echo    ^</log^>
    echo ^</configuration^>
) > %config_file_path%\%config_file%
echo [config_debug]: %config_file_path%\%config_file%
echo [config_debug]: '%config_file%' file Generated success!
echo;
echo;
:: =====================================================================
:: mysql databaes config       START
:: =====================================================================

goto start_service

::service reg
:start_service
set service_name=Ndr-uifront-end
set service_file=service.bat
set service_path=%qdr_home%\dashboard\ndr-uifront-end\bin
echo [service_debug]: registered service %service_name%
echo [service_debug]: cd %service_path%
cd %service_path%
echo [service_debug]: %service_file% install
call %service_file% install >nul 2>nul
echo [service_debug]: start %service_name%
net start %service_name% >nul 2>nul
sc config  %service_name% start=auto >nul 2>nul
echo [service_debug]: '%service_name%' service start success!
echo;

set service_name=Ndr-uiback-end
set service_file=db.properties.exe
set service_path=%qdr_home%\dashboard\ndr-uiback-end
echo [service_debug]: registered service %service_name%
echo [service_debug]: cd %service_path%
cd %service_path%
echo [service_debug]: %service_file% install
call %service_file% install >nul 2>nul
echo [service_debug]: start %service_name%
net start %service_name% >nul 2>nul
echo [service_debug]: '%service_name%' service start success!
echo;
echo [service_debug]: Deployment is complete!!!
echo;
echo Can be opened the browser: [ http://%local_ip%:8300 ]
echo;
Pause
exit


:end
echo exit 999
Pause