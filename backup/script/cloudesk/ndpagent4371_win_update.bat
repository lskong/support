@echo off
color 3f
echo,
echo 备份系统升级中...
echo,
echo 请勿关闭，感谢支持...
echo,
echo 预计需要20秒~2分钟...


set NDPAgentServicesName="NDPAgent"
set NDPAgentReleaseName="NDPAgent4371.msi"
set NetFrameWorkName="NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
set VisualNameThreeTwo="vc_redist.x86.exe"
set VisualNameSixFour="vc_redist.x64.exe"
for /f "tokens=4-7 delims= " %%a in ('wmic product list ^| findstr "ZTE NewStart"') do set NDPAgentPath=%%a %%b %%c %%d

sc query %NDPAgentServicesName% >nul 2>nul
if ERRORLEVEL 1060 goto NotExist

:Exist
net stop %NDPAgentServicesName% >nul 2>nul
sc delete %NDPAgentServicesName% >nul 2>nul


:NotExist
for /f "tokens=2 delims= " %%a in ('wmic product list brief ^| findstr "ZTE NewStart"') do (
    set NDPAGENTUUID=%%a
    call :RemoveNDPAgent
)

:DeleteNDPLog
cd %NDPAgentPath% >nul 2>nul
del /s /q Log\*.* >nul 2>nul

:Install
ver | findstr "6.1" >nul 2>nul && goto OSReleaseWinSeven
ver | findstr "10.0" >nul 2>nul && goto OSReleaseWinTen

:OSReleaseWinSeven
wmic product get description | findstr ".NET" >nul 2>nul
if ERRORLEVEL 1 goto NetFrameWorkInstall

:NetFrameWrokRelease
for /f "tokens=4 delims= " %%a in ('wmic product get description ^| findstr ".NET"') do set NETVERSION=%%a
for /f "tokens=1,2 delims=." %%a in ('echo %NETVERSION%') do set NETVERSION=%%a%%b
if %NETVERSION% GEQ 45 goto OSReleaseWinTen

:NetFrameWorkInstall
"%~dp0\%NetFrameWorkName%" /q /norestart

:OSReleaseWinTen
::wmic product get description | findstr "14.16.27024" && goto NDPAgentInstall
set n=0
for /f %%a in ('wmic product get description ^| findstr "14.16.27024"') do set /a n+=1
if %n% GEQ 4 goto NDPAgentInstall
"%~dp0\%VisualNameThreeTwo%" /quiet /norestart
"%~dp0\%VisualNameSixFour%" /quiet /norestart

:NDPAgentInstall
"%~dp0\%NDPAgentReleaseName%" /quiet /norestart

:ServiceStart
sc config VSS start= auto >nul 2>nul
sc config swprv start= auto >nul 2>nul
net start VSS >nul 2>nul
net start swprv >nul 2>nul
net stop %NDPAgentServicesName% >nul 2>nul
net start %NDPAgentServicesName% >nul 2>nul

:AddSchtasks
schtasks /create /F /tn "\Microsoft\Windows\NDPAgent\NDPAgentServiceCheck" /ru system /tr '"%NDPAgentPath%ndpagent_schtasks_exec.bat"' /sc hourly /mo 2 /st 00:00:00 >nul 2>nul

echo,
echo 升级已完成，再次感谢...
timeout /T 5 /NOBREAK
exit



:RemoveNDPAgent
MsiExec.exe /qn /X%NDPAGENTUUID%>nul 2>nul



REM remove list
::MsiExec.exe /qn /X{79643782-71AC-471F-9FEA-846433AD550A}>nul 2>nul
::MsiExec.exe /qn /X{4448C0C3-C810-4FB7-BDA7-0FF1D42E8E2E}>nul 2>nul
::MsiExec.exe /qn /X{E92CA519-6F77-4764-81BD-E65B0BBE43FB}>nul 2>nul
::MsiExec.exe /qn /X{0C655058-A089-$BF3-80EB-06E9808B540C}>nul 2>nul
::MsiExec.exe /qn /X{48480626-E482-46FC-93E6-5C5A87094B12}>nul 2>nul
::MsiExec.exe /qn /X{737D09A1-B652-4F7D-A460-26A72140E688}>nul 2>nul
::MsiExec.exe /qn /X{B5477BB2-F034-4D09-9195-492286CEC443}>nul 2>nul
::MsiExec.exe /qn /X{6D0B621F-D284-46D0-9A6B-8BF3144F75C0}>nul 2>nul
::MsiExec.exe /qn /X{D9D10319-69BA-44BF-80CE-DB2F3FF0DB97}>nul 2>nul
::MsiExec.exe /qn /X{30BB0D6B-508F-4858-913E-9EF2D43E9EAF}>nul 2>nul
::MsiExec.exe /qn /X{5F8E67EF-1530-48D9-8755-0E255FEF826F}>nul 2>nul
::MsiExec.exe /qn /X{99801C2B-8B4E-45E7-A5AF-5485DB8D92F1}>nul 2>nul
::MsiExec.exe /qn /X{2A9DE5A7-EF1B-44B9-987B-C74A34037BEB}>nul 2>nul
::MsiExec.exe /qn /X{E787FA53-6962-4C6D-8D7A-7B6B366930BC}>nul 2>nul
::MsiExec.exe /qn /X{6FA445D5-4528-4CEF-85F5-01473BA73ACC}>nul 2>nul
::MsiExec.exe /qn /X{B22DE1EB-C06E-4B91-ABD8-2D64078ED44C}>nul 2>nul

REM remove all
::wmic product list brief | findstr "ZTE NewStart"
::for /f "tokens=2 delims= " %a in ('wmic product list brief ^| findstr "NDP"') do MsiExec.exe /qn /X%a


REM OS 32/64
::wmic os get OSArchitecture
::echo %PROCESSOR_ARCHITECTURE%
