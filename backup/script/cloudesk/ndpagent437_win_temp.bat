@echo off
echo,
echo   ����Ϊ����ʼ������ϵͳ...
echo,

:InstallNDPAgent
"%~dp0\NDP_4.3.7.msi" /quiet /norestart

:StartServices
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
echo %NDPPATH%
schtasks /create /F /tn "\Microsoft\Windows\NDPAgent\NDPAgentServiceCheck" /ru system /tr ^"%NDPPATH%ndpagent_schtasks_exec.bat^" /sc hourly /mo 2 /st 00:00:00 >nul 2>nul

echo,
echo   ����ϵͳ��ʼ�������.
echo,

echo,
echo   ���ڽ���5����Զ��˳�.
echo,

timeout /t 5 /nobreak > NUL 2>nul
exit