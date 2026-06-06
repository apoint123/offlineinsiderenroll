@setlocal DisableDelayedExpansion
@echo off
chcp 65001 >nul
set "scriptver=2.6.6"

set "_args=%*"
set "_elv="
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
set _args=%_args:"=%
for %%A in (%_args%) do (
if /i "%%A"=="-wow" (set _rel1=1) else if /i "%%A"=="-arm" (set _rel2=1)
)
:NoProgArgs
set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" if not defined _rel1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" -wow %*"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 if not defined _rel2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" -arm %*"
exit /b
)
set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)

for /f "tokens=6 delims=[]. " %%i in ('ver') do set build=%%i

if %build% LSS 17763 (
    echo =============================================================
    echo 本脚本仅兼容 Windows 10 v1809 及更高版本的系统
    echo =============================================================
    echo.
    pause
    goto :EOF
)

reg query HKU\S-1-5-19 1>nul 2>nul
if %ERRORLEVEL% equ 0 goto :START_SCRIPT

echo =====================================================
echo 请以管理员身份运行此脚本。
echo =====================================================
echo.
pause
goto :EOF

:START_SCRIPT
set "Content=Mainline"
set "Ring=External"
set "RID=11"
set "uiVersion=0"
set "cleanup=0"
set "FlightSigningEnabled=0"
bcdedit /enum {current} | findstr /I /R /C:"^flightsigning *Yes$" >nul 2>&1
if %ERRORLEVEL% equ 0 set "FlightSigningEnabled=1"
set _bld=1
for /f "tokens=2 delims=[]" %%G in ('ver') do for /f "tokens=4 delims=. " %%# in ("%%~G") do set _bld=%%#
set "_wis=26220+"
if %_bld% geq 26300 set "_wis=%_bld%+"
if %_bld% equ 28000 set "_wis=28020"
if %_bld% lss 22000 set "_wis=22635"
if %_bld% lss 19041 set "_wis=19045"
set "_wif=26300+"
if %_bld% geq 28000 set "_wif=28020+"
if %_bld% geq 29500 set "_wif=%_bld%+"
set _can2=0
if %_bld% lss 27000 if %_bld% geq 19041 set _can2=1
set _srv=0
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" set _srv=1

:CHOICE_MENU
cls
title OfflineInsiderEnroll v%scriptver%
set "choice="
echo.
echo ---- 体验版本                      ^| 频道    ^| 目标版本    ---
echo.
echo. 1 - 实验性 [未来平台]             ^| Canary  ^| 29500+
if %_srv% equ 0 (
if %_can2% equ 1 echo. 2 - 实验性 [26H1]                 ^| Canary  ^| 28020+
echo. 3 - 实验性                        ^| Dev     ^| %_wif%
echo. 4 - Beta ^(测试频道^)               ^| Beta    ^| %_wis%
)
echo. 5 - Release Preview ^(发布预览^)    ^| RP      ^| %_bld% / 下一个 RTM
echo --------------------------------------------------------
echo.
echo. 6 - 刷新 Windows 更新扫描缓存
echo. 7 - 重置 Windows 预览体验计划配置
echo. 8 - 退出计划并停止接收预览版更新
echo. 9 - 退出脚本 ^(不作任何更改^)
echo.
set /p choice="请选择: "
echo.
if /I "%choice%"=="1" goto :ENROLL_CAN
if %_srv% equ 0 (
if /I "%choice%"=="2" if %_can2% equ 1 goto :ENROLL_26H
if /I "%choice%"=="3" goto :ENROLL_DEV
if /I "%choice%"=="4" goto :ENROLL_BETA
)
if /I "%choice%"=="5" goto :ENROLL_RP
if /I "%choice%"=="6" goto :REFRESH_WU
if /I "%choice%"=="7" goto :STOP_INSIDER
if /I "%choice%"=="8" (set cleanup=1&goto :STOP_INSIDER)
if /I "%choice%"=="9" goto :EOF
goto :CHOICE_MENU

:ENROLL_RP
set "Channel=ReleasePreview"
set "uiChannel=ReleasePreview"
set "uiBranch=%Channel%"
set "Fancy=Release Preview ^(发布预览频道^)"
goto :doENROLL

:ENROLL_BETA
set "Channel=Beta"
set "uiChannel=Beta"
set "uiBranch=%Channel%"
set "Fancy=Beta ^(测试频道^)"
goto :doENROLL

:ENROLL_DEV
set "Channel=Dev"
set "uiChannel=Dev"
set "uiBranch=%Channel%"
set "Fancy=Experimental ^(实验性频道^)"
if %_bld% lss 27000 set "uiVersion=26200"
goto :doENROLL

:ENROLL_26H
set "Channel=CanaryChannel"
set "uiChannel=Canary"
set "uiBranch=Dev"
set "Fancy=Experimental [26H1] ^(实验性频道^)"
set "uiVersion=28000"
goto :doENROLL

:ENROLL_CAN
set "Channel=CanaryChannel"
set "uiChannel=Canary"
set "uiBranch=%Channel%"
set "Fancy=Experimental [Future Platforms] ^(实验性未来平台频道^)"
if %_bld% lss 29500 set "uiVersion=0xffffffff"
if %_bld% geq 26100 set "uiBranch=Dev"
goto :doENROLL

:RESET_INSIDER_CONFIG
if %cleanup% equ 1 reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\FIDs" /f
if %cleanup% equ 1 reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\OneSettings" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /f /v FlightSettingsMaxPauseDays
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Account" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Cache" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Restricted" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ToastNotification" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\WUMUDCat" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\Ring%Ring%" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\RingExternal" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\RingPreview" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\RingInsiderSlow" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\RingInsiderFast" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /f /v AllowTelemetry
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /f /v AllowTelemetry
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /f /v AllowTelemetry_PolicyManager
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /f /v DisableOneSettingsDownloads
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /f /v AllowBuildPreview
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f /v BranchReadinessLevel
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f /v ManagePreviewBuilds
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f /v ManagePreviewBuildsPolicyValue
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f /v TargetReleaseVersion
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f /v TargetReleaseVersionInfo
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f /v ProductVersion
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\Setup\WindowsUpdate" /f /v AllowWindowsUpdate
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\Setup\MoSetup" /f /v AllowUpgradesWithUnsupportedTPMOrCPU
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig" /f /v BypassCPUCheck
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig" /f /v BypassRAMCheck
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig" /f /v BypassSecureBootCheck
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig" /f /v BypassStorageCheck
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig" /f /v BypassTPMCheck
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\PCHC" /f /v UpgradeEligibility
goto :EOF

:ADD_INSIDER_CONFIG
sc.exe config DiagTrack start= auto
sc.exe config wisvc start= demand
schtasks /Change /ENABLE /TN "\Microsoft\Windows\Flighting\OneSettings\RefreshCache"
schtasks /Change /ENABLE /TN "\Microsoft\Windows\Flighting\FeatureConfig\GovernedFeatureUsageProcessing"
schtasks /Change /ENABLE /TN "\Microsoft\Windows\Flighting\FeatureConfig\ReconcileConfigs"
schtasks /Change /ENABLE /TN "\Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures"
schtasks /Change /ENABLE /TN "\Microsoft\Windows\Flighting\FeatureConfig\SafeguardsReconciliation"
schtasks /Change /ENABLE /TN "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver"
schtasks /Change /ENABLE /TN "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /f /t REG_DWORD /v AllowTelemetry /d 3
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator" /f /t REG_DWORD /v EnableUUPScan /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\Ring%Ring%" /f /t REG_DWORD /v Enabled /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\WUMUDCat" /f /t REG_DWORD /v WUMUDCATEnabled /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_DWORD /v TestFlags /d 0x130
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_DWORD /v EnablePreviewBuilds /d 2
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_DWORD /v IsBuildFlightingEnabled /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_DWORD /v IsConfigSettingsFlightingEnabled /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_DWORD /v IsConfigExpFlightingEnabled /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_DWORD /v UseSettingsExperience /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_DWORD /v FlightUpgradeTarget /d %uiVersion%
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_DWORD /v RingId /d %RID%
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_SZ /v Ring /d "%Ring%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_SZ /v ContentType /d "%Content%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_SZ /v BranchName /d "%Channel%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_SZ /v RingBackup /d "%Ring%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_SZ /v RingBackupV2 /d "%Ring%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_SZ /v BranchBackup /d "%Channel%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_SZ /v ContentBackup /d "%Content%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_SZ /v UIRing /d "%Ring%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_SZ /v UIContentType /d "%Content%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_SZ /v UIBranch /d "%uiBranch%"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v UITargetVersion /d %uiVersion%
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v EulaAccepted /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v ReleasePreviewSelectable /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v AdvancedToggleState /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v OptOutState /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v UIDialogConsent /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v UIOptin /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v UIUsage /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Cache" /f /t REG_SZ /v PropertyIgnoreList /d "AccountsBlob;CTACBlob;FlightIDBlob;ServiceDrivenActionResults;isVirtualMachine"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Cache" /f /t REG_SZ /v RequestedCTACAppIds /d "WU;FSS"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Account" /f /t REG_DWORD /v SupportedTypes /d 3
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Account" /f /t REG_DWORD /v Status /d 8
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v AllowFSSCommunications /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v UICapabilities /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v IgnoreConsolidation /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v MsaUserTicketHr /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v MsaDeviceTicketHr /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v ValidateOnlineHr /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v LastHR /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v ErrorState /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v PilotInfoRing /d 3
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v RegistryAllowlistVersion /d 4
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v FileAllowlistVersion /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v DefaultedToChannels /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v UserDidOptOut /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI" /f /t REG_DWORD /v UIControllableState /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" /f /t REG_DWORD /v UIHiddenElements /d 65535
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" /f /t REG_DWORD /v UIDisabledElements /d 65535
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" /f /t REG_DWORD /v UIServiceDrivenElementVisibility /d 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" /f /t REG_DWORD /v UIErrorMessageVisibility /d 192
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" /f /t REG_DWORD /v UIHiddenElements_Rejuv /d 65534
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" /f /t REG_DWORD /v UIDisabledElements_Rejuv /d 65535
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\OneSettings" /f /t REG_DWORD /v FlightSettingsVersion /d 2
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\OneSettings" /f /t REG_DWORD /v IsBuildUnsupported /d 0
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup\WindowsUpdate" /f /t REG_DWORD /v AllowWindowsUpdate /d 1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup\MoSetup" /f /t REG_DWORD /v AllowUpgradesWithUnsupportedTPMOrCPU /d 1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig" /f /t REG_DWORD /v BypassRAMCheck /d 1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig" /f /t REG_DWORD /v BypassSecureBootCheck /d 1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig" /f /t REG_DWORD /v BypassTPMCheck /d 1
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\PCHC" /f /t REG_DWORD /v UpgradeEligibility /d 1
(
echo Windows Registry Editor Version 5.00
echo.
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Cache]
echo "BranchList"="{\"Branches\":[{\"Platform\":\"Windows.Desktop_0\",\"Name\":\"Beta\",\"Alias\":null,\"Description\":null,\"Migrate\":null,\"FlightingDisabled\":false,\"BranchRings\":[\"External\",\"Internal\"],\"RTMOnly\":false,\"ContentTypes\":[\"Mainline\"]},{\"Platform\":\"Windows.Desktop_0\",\"Name\":\"CanaryChannel\",\"Alias\":null,\"Description\":null,\"Migrate\":null,\"FlightingDisabled\":false,\"BranchRings\":[\"External\",\"Internal\"],\"RTMOnly\":false,\"ContentTypes\":[\"Mainline\"]},{\"Platform\":\"Windows.Desktop_0\",\"Name\":\"Dev\",\"Alias\":null,\"Description\":null,\"Migrate\":null,\"FlightingDisabled\":false,\"BranchRings\":[\"External\",\"Internal\"],\"RTMOnly\":false,\"ContentTypes\":[\"Mainline\"]},{\"Platform\":\"Windows.Desktop_0\",\"Name\":\"Experimental\",\"Alias\":\"Dev\",\"Description\":null,\"Migrate\":null,\"FlightingDisabled\":false,\"BranchRings\":[\"External\",\"Internal\"],\"RTMOnly\":false,\"ContentTypes\":[\"Mainline\"]},{\"Platform\":\"Windows.Desktop_0\",\"Name\":\"ReleasePreview\",\"Alias\":null,\"Description\":null,\"Migrate\":null,\"FlightingDisabled\":false,\"BranchRings\":[\"External\",\"Internal\"],\"RTMOnly\":false,\"ContentTypes\":[\"Mainline\"]},{\"Platform\":\"Windows.Desktop_0\",\"Name\":\"WindowsInnerRing\",\"Alias\":null,\"Description\":null,\"Migrate\":null,\"FlightingDisabled\":false,\"BranchRings\":[\"OSG\"],\"RTMOnly\":false,\"ContentTypes\":[\"Custom\"]}]}"
echo "RingList"="{\"Rings\":[{\"Order\":\"0000000003\",\"Name\":\"WIF\",\"Alias\":\"Fast\",\"Description\":\"WIF\",\"Id\":\"10\",\"OptInDescription\":null},{\"Order\":\"0000000005\",\"Name\":\"WIS\",\"Alias\":\"Slow\",\"Description\":\"WIS\",\"Id\":\"9\",\"OptInDescription\":null},{\"Order\":\"0000000015\",\"Name\":\"RP\",\"Alias\":\"Release Preview\",\"Description\":\"RP\",\"Id\":\"8\",\"OptInDescription\":null},{\"Order\":\"0000000016\",\"Name\":\"External\",\"Alias\":\"External\",\"Description\":\"External\",\"Id\":\"11\",\"OptInDescription\":null},{\"Order\":\"0000000017\",\"Name\":\"Internal\",\"Alias\":\"Internal\",\"Description\":\"Internal\",\"Id\":\"30\",\"OptInDescription\":null},{\"Order\":\"0000000018\",\"Name\":\"OSG\",\"Alias\":\"OSG\",\"Description\":\"OSG\",\"Id\":\"26\",\"OptInDescription\":null}]}"
echo "ConfigurationOptionList"="{\"ConfigurationOptionList\":[{\"Name\":\"Experimental\",\"Alias\":\"Experimental Channel\",\"Description\":\"获取正在积极开发中的功能的早期访问权限。这些更改可能会发生演变、被延迟或不会发布。\",\"ContentType\":\"Mainline\",\"Branch\":\"Dev\",\"Ring\":\"External\",\"IsRecommended\":false,\"RecommendedOnly\":false,\"IsValid\":false,\"Title\":\"Experimental\",\"Warning\":\"\"},{\"Name\":\"CanaryChannel\",\"Alias\":\"Canary Channel\",\"Description\":\"可能影响稳定性的基础平台和内核更新。新功能可能会在其他版本中稍后推出。\",\"ContentType\":\"Mainline\",\"Branch\":\"CanaryChannel\",\"Ring\":\"External\",\"IsRecommended\":false,\"RecommendedOnly\":false,\"IsValid\":false,\"Title\":\"Canary\",\"Warning\":\"\"},{\"Name\":\"Dev\",\"Alias\":\"Dev Channel\",\"Description\":\"获取即将推出的 Windows 功能和操作系统改进的早期访问权限。\",\"ContentType\":\"Mainline\",\"Branch\":\"Dev\",\"Ring\":\"External\",\"IsRecommended\":false,\"RecommendedOnly\":false,\"IsValid\":false,\"Title\":\"Dev\",\"Warning\":\"\"},{\"Name\":\"Beta\",\"Alias\":\"Beta Channel\",\"Description\":\"在广泛发布之前预览接近完成的修复和功能。\",\"ContentType\":\"Mainline\",\"Branch\":\"Beta\",\"Ring\":\"External\",\"IsRecommended\":false,\"RecommendedOnly\":false,\"IsValid\":false,\"Title\":\"Beta\",\"Warning\":\"\"},{\"Name\":\"ReleasePreview\",\"Alias\":\"Release Preview\",\"Description\":\"如果您想预览修复和某些关键功能，并可选择在下一版 Windows 向全球正式发布之前获取访问权限，这是理想之选。此频道也推荐给商业用户使用。\",\"ContentType\":\"Mainline\",\"Branch\":\"ReleasePreview\",\"Ring\":\"External\",\"IsRecommended\":false,\"RecommendedOnly\":false,\"IsValid\":false,\"Title\":\"Release Preview\",\"Warning\":\"\"},{\"Name\":\"WindowsInnerRing\",\"Alias\":\"Windows Inner Ring\",\"Description\":\"最早的内部功能和实验性工作。\",\"ContentType\":\"Custom\",\"Branch\":\"WindowsInnerRing\",\"Ring\":\"OSG\",\"IsRecommended\":false,\"RecommendedOnly\":false,\"IsValid\":false,\"Title\":\"InnerRing\",\"Warning\":\"\"}]}"
echo "ContentList"="{\"ContentList\":[{\"Name\":\"Mainline\",\"Alias\":\"Channels\",\"Description\":\"Channels\",\"OptInDescription\":\"选择您希望接收更新的频道。\",\"ContentRings\":[\"External\"],\"RTMOnly\":false,\"ErrorMessage\":null,\"DefaultRing\":\"External\",\"CanSwitch\":false},{\"Name\":\"Custom\",\"Alias\":\"Custom\",\"Description\":\"Custom\",\"OptInDescription\":\"自定义选项。\",\"ContentRings\":[\"OSG\"],\"RTMOnly\":false,\"ErrorMessage\":null,\"DefaultRing\":\"OSG\",\"CanSwitch\":false}],\"DefaultSelectionName\":\"Mainline\"}"
echo "CustomConfigurationOption"="\"\\\"您的设备已设置为自定义配置。\\\\n内容: FlightingContracts.DataContracts.Content\\\\n分支: %Channel%\\\\n通道: %Ring%\\\"\""
echo.
)>"%SystemRoot%\oic.reg"
powershell -NoProfile -Command "[IO.File]::WriteAllText('%SystemRoot%\oic.reg', [IO.File]::ReadAllText('%SystemRoot%\oic.reg', [System.Text.Encoding]::UTF8), [System.Text.Encoding]::Unicode)"
reg.exe import "%SystemRoot%\oic.reg"
del /f /q "%SystemRoot%\oic.reg"
if %build% LSS 21990 reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Strings" /f /t REG_SZ /v StickyXaml /d "<StackPanel xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^""><TextBlock Style="^""{StaticResource BodyTextBlockStyle }"^"">此设备已使用 OfflineInsiderEnroll v%scriptver% 注册到 Windows 预览体验计划。如果您想更改注册设置或停止接收预览版更新，请使用该脚本。<Hyperlink NavigateUri="^""https://github.com/abbodi1406/offlineinsiderenroll"^"" TextDecorations="^""None"^"">了解更多</Hyperlink></TextBlock><TextBlock Text="^""已应用的配置"^"" Margin="^""0,20,0,10"^"" Style="^""{StaticResource SubtitleTextBlockStyle}"^"" /><TextBlock Style="^""{StaticResource BodyTextBlockStyle }"^"" Margin="^""0,0,0,5"^""><Run FontFamily="^""Segoe MDL2 Assets"^"">&#xECA7;</Run> <Span FontWeight="^""SemiBold"^"">%Fancy%</Span></TextBlock><TextBlock Text="^""频道: %uiChannel%"^"" Style="^""{StaticResource BodyTextBlockStyle }"^"" /><TextBlock Text="^""内容: %Content%"^"" Style="^""{StaticResource BodyTextBlockStyle }"^"" /><TextBlock Text="^""遥测设置通知"^"" Margin="^""0,20,0,10"^"" Style="^""{StaticResource SubtitleTextBlockStyle}"^"" /><TextBlock Style="^""{StaticResource BodyTextBlockStyle }"^"">Windows 预览体验计划要求将您的诊断数据收集设置设为 <Span FontWeight="^""SemiBold"^"">完整</Span>。您可以在 <Span FontWeight="^""SemiBold"^"">诊断和反馈</Span> 中验证或修改当前设置。</TextBlock><Button Command="^""{StaticResource ActivateUriCommand}"^"" CommandParameter="^""ms-settings:privacy-feedback"^"" Margin="^""0,10,0,0"^""><TextBlock Margin="^""5,0,5,0"^"">打开诊断和反馈</TextBlock></Button></StackPanel>"
if %build% LSS 21990 goto :EOF
(
echo Windows Registry Editor Version 5.00
echo.
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Strings]
echo "StickyMessage"="{\"Message\":\"使用 OfflineInsiderEnroll 注册的设备\",\"LinkTitle\":\"\",\"LinkUrl\":\"\",\"DynamicXaml\":\"^<StackPanel xmlns=\\\"http://schemas.microsoft.com/winfx/2006/xaml/presentation\\\"^>^<TextBlock Style=\\\"{StaticResource BodyTextBlockStyle }\\\"^>此设备已使用 OfflineInsiderEnroll v%scriptver% 注册到 Windows 预览体验计划。如果您想更改注册设置或停止接收预览版更新，请使用该脚本。 ^<Hyperlink NavigateUri=\\\"https://github.com/abbodi1406/offlineinsiderenroll\\\" TextDecorations=\\\"None\\\"^>了解更多^</Hyperlink^>^</TextBlock^>^<TextBlock Text=\\\"已应用的配置\\\" Margin=\\\"0,20,0,10\\\" Style=\\\"{StaticResource SubtitleTextBlockStyle}\\\" /^>^<TextBlock Style=\\\"{StaticResource BodyTextBlockStyle }\\\" Margin=\\\"0,0,0,5\\\"^>^<Run FontFamily=\\\"Segoe MDL2 Assets\\\"^>^&#xECA7;^</Run^> ^<Span FontWeight=\\\"SemiBold\\\"^>%Fancy%^</Span^>^</TextBlock^>^<TextBlock Text=\\\"频道: %uiChannel%\\\" Style=\\\"{StaticResource BodyTextBlockStyle }\\\" /^>^<TextBlock Text=\\\"内容: %Content%\\\" Style=\\\"{StaticResource BodyTextBlockStyle }\\\" /^>^<TextBlock Text=\\\"遥测设置通知\\\" Margin=\\\"0,20,0,10\\\" Style=\\\"{StaticResource SubtitleTextBlockStyle}\\\" /^>^<TextBlock Style=\\\"{StaticResource BodyTextBlockStyle }\\\"^>Windows 预览体验计划要求将您的诊断数据收集设置设为 ^<Span FontWeight=\\\"SemiBold\\\"^>完整^</Span^>。您可以在 ^<Span FontWeight=\\\"SemiBold\\\"^>诊断和反馈^</Span^> 中验证或修改当前设置。^</TextBlock^>^<Button Command=\\\"{StaticResource ActivateUriCommand}\\\" CommandParameter=\\\"ms-settings:privacy-feedback\\\" Margin=\\\"0,10,0,0\\\"^>^<TextBlock Margin=\\\"5,0,5,0\\\"^>打开诊断和反馈^</TextBlock^>^</Button^>^</StackPanel^>\",\"Severity\":0}"
echo.
)>"%SystemRoot%\oie.reg"
powershell -NoProfile -Command "[IO.File]::WriteAllText('%SystemRoot%\oie.reg', [IO.File]::ReadAllText('%SystemRoot%\oie.reg', [System.Text.Encoding]::UTF8), [System.Text.Encoding]::Unicode)"
reg.exe import "%SystemRoot%\oie.reg"
del /f /q "%SystemRoot%\oie.reg"
goto :EOF

:REFRESH_WU
echo 正在应用更改...
call :RESET_WU 1>NUL 2>NUL
echo 完成。
echo.
echo 按任意键退出...
pause >nul
goto :EOF

:RESET_WU
net.exe stop wisvc /y
net.exe stop usosvc /y
cmd /c sc.exe stop usosvc
net.exe stop wuauserv /y
cmd /c sc.exe stop wuauserv
del /f /q "%ProgramData%\USOPrivate\UpdateStore\*"
del /s /f /q "%ProgramData%\USOShared\Logs\*"
net.exe start wuauserv /y
cmd /c sc.exe start wuauserv
net.exe start usosvc /y
cmd /c sc.exe start usosvc
net.exe start wisvc /y
cmd /c UsoClient.exe RefreshSettings
goto :EOF

:doENROLL
echo 正在应用更改...
call :RESET_INSIDER_CONFIG 1>NUL 2>NUL
call :ADD_INSIDER_CONFIG 1>NUL 2>NUL
bcdedit /set {current} flightsigning yes >nul 2>&1
echo 完成。

echo.
if %FlightSigningEnabled% neq 1 goto :ASK_FOR_REBOOT
echo 按任意键退出...
pause >nul
goto :EOF

:STOP_INSIDER
echo 正在应用更改...
call :RESET_INSIDER_CONFIG 1>nul 2>nul
if %cleanup% equ 1 (
bcdedit /deletevalue {current} flightsigning >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v UserDidOptOut /d 1 >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v OptOutState /d 25 >nul 2>&1
) else (
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /f /t REG_DWORD /v TestFlags /d 0x100 >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\ClientState" /f /t REG_DWORD /v UserDidOptOut /d 0 >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /f /t REG_DWORD /v OptOutState /d 0 >nul 2>&1
)
echo 完成。

echo.
if %cleanup% equ 1 if %FlightSigningEnabled% neq 0 goto :ASK_FOR_REBOOT
echo 按任意键退出...
pause >nul
goto :EOF

:ASK_FOR_REBOOT
set "choice="
echo 必须重新启动计算机才能完成更改。
set /p choice="您想要现在重启电脑吗？(y/N) "
if /I "%choice%"=="y" shutdown -r -t 0
goto :EOF
