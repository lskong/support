@echo off
echo,
echo ===================================================================================
echo   请勿关闭本窗口!!!
echo,
echo   正在为您自动升级备份系统，完善用户资料的自动备份。
echo   预计需要20秒左右，升级完成之后，窗口会自动退出，感谢。
echo ===================================================================================
sc query NDPAgent >nul 2>nul
if ERRORLEVEL 1060 goto END

:EXIST
sc delete NDPAgent >nul 2>nul
goto END

:END
FOR /f "tokens=2 delims= " %%a in ('wmic product list brief ^| findstr "ZTE NewStart"') do (
    SET NDPAGENTUUID=%%a
    call :removendpagent
)

"%~dp0\NDP452-KB2901907-x86-x64-AllOS-ENU.exe" /q /norestart
"%~dp0\vc_redist.x86.exe" /quiet /norestart
"%~dp0\vc_redist.x64.exe" /quiet /norestart
"%~dp0\NDP_4.3.7.msi" /quiet /norestart
sc config VSS start= auto >nul 2>nul
sc config swprv start= auto >nul 2>nul
net start VSS >nul 2>nul
net start swprv >nul 2>nul

:AddSchtasks
FOR /f "tokens=4 delims= " %%b in ('wmic product list ^| findstr "ZTE NewStart"') do SET NDPPATHb=%%b
FOR /f "tokens=5 delims= " %%c in ('wmic product list ^| findstr "ZTE NewStart"') do SET NDPPATHc=%%c
FOR /f "tokens=6 delims= " %%d in ('wmic product list ^| findstr "ZTE NewStart"') do SET NDPPATHd=%%d
FOR /f "tokens=7 delims= " %%e in ('wmic product list ^| findstr "ZTE NewStart"') do SET NDPPATHe=%%e
set NDPPATH=%NDPPATHb% %NDPPATHc% %NDPPATHd% %NDPPATHe%
schtasks /create /F /tn "\Microsoft\Windows\NDPAgent\NDPAgentServiceCheck" /ru system /tr ^"%NDPPATH%ndpagent_schtasks_exec.bat^" /sc hourly /mo 2 /st 00:00:00 >nul 2>nul

exit



:removendpagent
MsiExec.exe /qn /X%NDPAGENTUUID%>NUL 2>NUL


REM remove list
::MsiExec.exe /qn /X{79643782-71AC-471F-9FEA-846433AD550A}>NUL 2>NUL
::MsiExec.exe /qn /X{4448C0C3-C810-4FB7-BDA7-0FF1D42E8E2E}>NUL 2>NUL
::MsiExec.exe /qn /X{E92CA519-6F77-4764-81BD-E65B0BBE43FB}>NUL 2>NUL
::MsiExec.exe /qn /X{0C655058-A089-$BF3-80EB-06E9808B540C}>NUL 2>NUL
::MsiExec.exe /qn /X{48480626-E482-46FC-93E6-5C5A87094B12}>NUL 2>NUL
::MsiExec.exe /qn /X{737D09A1-B652-4F7D-A460-26A72140E688}>NUL 2>NUL
::MsiExec.exe /qn /X{B5477BB2-F034-4D09-9195-492286CEC443}>NUL 2>NUL
::MsiExec.exe /qn /X{6D0B621F-D284-46D0-9A6B-8BF3144F75C0}>NUL 2>NUL
::MsiExec.exe /qn /X{D9D10319-69BA-44BF-80CE-DB2F3FF0DB97}>NUL 2>NUL
::MsiExec.exe /qn /X{30BB0D6B-508F-4858-913E-9EF2D43E9EAF}>NUL 2>NUL
::MsiExec.exe /qn /X{5F8E67EF-1530-48D9-8755-0E255FEF826F}>NUL 2>NUL
::MsiExec.exe /qn /X{99801C2B-8B4E-45E7-A5AF-5485DB8D92F1}>NUL 2>NUL
::MsiExec.exe /qn /X{2A9DE5A7-EF1B-44B9-987B-C74A34037BEB}>NUL 2>NUL
::MsiExec.exe /qn /X{E787FA53-6962-4C6D-8D7A-7B6B366930BC}>NUL 2>NUL
::MsiExec.exe /qn /X{6FA445D5-4528-4CEF-85F5-01473BA73ACC}>NUL 2>NUL
::MsiExec.exe /qn /X{B22DE1EB-C06E-4B91-ABD8-2D64078ED44C}>NUL 2>NUL

REM remove all
::wmic product list brief |findstr NDP
::for /f "tokens=2 delims= " %a in ('wmic product list brief ^| find "NDP"') do MsiExec.exe /qn /X%a


REM OS 32/64
::wmic os get OSArchitecture
::echo %PROCESSOR_ARCHITECTURE%
