@echo off
echo.
echo --------------------------------------------------------
echo       SENOMY.MUZ DEPLOYMENT ENVIRONMENT LOADING
echo --------------------------------------------------------
echo.

:: Add a little suspense
ping 127.0.0.1 -n 4 >nul

:: Let PE settle
wpeinit
cd /d %~dp0

setlocal EnableDelayedExpansion
set setupFound=false

:: BIOS Configuration Phase
echo ========================== >> bioslog.txt
echo Starting BIOS configuration at %date% %time% >> bioslog.txt

echo Setting BIOS password... >> bioslog.txt
cctk.exe --setuppwd=Hercules >> bioslog.txt 2>&1

echo Disabling HTTPS Boot... >> bioslog.txt
cctk.exe --httpsboot=disable --valsetuppwd=Hercules >> bioslog.txt 2>&1

echo Setting SATA to AHCI... >> bioslog.txt
cctk.exe --sata=ahci --valsetuppwd=Hercules >> bioslog.txt 2>&1

echo BIOS config completed at %time% >> bioslog.txt
echo ========================== >> bioslog.txt

:: Add a little suspense
ping 127.0.0.1 -n 4 >nul

:: Find Windows setup.exe
for %%i in (D E F G H I J) do (
    if exist %%i:\setup.exe (
        echo Found setup.exe in %%i:\ at %time% >> bioslog.txt
        %%i:\setup.exe /unattend:%%i:\autounattend.xml >> bioslog.txt 2>&1
        set setupFound=true
        goto:eof
    )
)

:: If no setup found
if "!setupFound!"=="false" (
    echo [ERROR] setup.exe not found at %time% >> bioslog.txt
    echo Could not locate setup.exe on any attached volume.
)

:: Attempt to backup BIOS log
set logSaved=false
for %%i in (D E F G) do (
    if exist %%i:\ (
        copy X:\DellBIOS\bioslog.txt %%i:\bioslog_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%.txt >nul
        set logSaved=true
        goto :donecopy
    )
)

:donecopy
if "!logSaved!"=="false" (
    echo [WARN] Could not save BIOS log to USB drive. >> bioslog.txt
)

goto:eof
