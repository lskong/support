@echo off
color 3f
echo,
echo ���ڳ�ʼ������ϵͳ...
echo,

set NDPAgentServicesName="NDPAgent"
set NDPAgentReleaseName="NDPAgent4371.msi"


:InstallNDPAgent
"%~dp0\%NDPAgentReleaseName%" /quiet /norestart

:StartServices
sc config VSS start= auto >nul 2>nul
sc config swprv start= auto >nul 2>nul
net start VSS >nul 2>nul
net start swprv >nul 2>nul

:AddSchtasks
for /f "tokens=4-7 delims= " %%a in ('wmic product list ^| findstr "ZTE NewStart"') do set NDPAgentPath=%%a %%b %%c %%d
schtasks /create /F /tn "\Microsoft\Windows\NDPAgent\NDPAgentServiceCheck" /ru system /tr '"%NDPAgentPath%ndpagent_schtasks_exec.bat"' /sc hourly /mo 2 /st 00:00:00 >nul 2>nul

echo,
echo ����ϵͳ��ʼ�������.
echo,

echo,
echo ���ڽ���5����Զ��˳�.
echo,

timeout /t 5 /nobreak > NUL 2>nul
exit