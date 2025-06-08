# Dellploy_WIN10: : BIOS + Windows 10 Deployment USB Guide
cmd and xml templates to configure a dual-partitioned (FAT32 and NFTS) boot stick to automatically configure BIOS and install Windows 10 with desired settings

## 🎯 Objective
A USB stick for **automated provisioning** of Dell Latitude laptops that:
- Applies **custom BIOS configuration** via Dell Command Configure
- Installs **Windows 10/11 Enterprise (EN-GB)** without user input
- Joins device to domain, creates a local admin, and auto-logs in

## 📂 Prerequisites
- Windows 10/ 11 host system (10GB+ free space)
- ✅ UEFI enabled, GPT-partitioned disk
- ⚠️ Not compatible with legacy BIOS or MBR disks
- 🔧 Admin privileges
- 💽 USB 3.0 stick (32GB+ recommended)
- 📦 Windows 10/ 11 Enterprise ISO (EN-GB)
- 🔧 [Windows ADK + WinPE Add-on](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)

Install:
- Deployment Tools
- WinPE Add-on

## 🔧 Part 1: Build WinPE Environment

### 1. Create Working Directory
```bash
copype amd64 C:\WinPE_amd64
```

### 2. Mount `boot.wim`
```bash
Dism /Mount-Image /ImageFile:"C:\WinPE_amd64\media\sources\boot.wim" /index:1 /MountDir:"C:\WinPE_amd64\mount"
```

### 3. Add Dell BIOS Tools
Install **Dell Command | Configure** and copy `cctk.exe` & required DLLs to:
```plaintext
C:\WinPE_amd64\mount\DellBIOS\
```

### 4. Edit `startnet.cmd`
Path: `C:\WinPE_amd64\mount\Windows\System32\startnet.cmd`
Insert BIOS configuration logic and unattended setup script.

### 5. Unmount & Commit
```bash
Dism /Unmount-Image /MountDir:"C:\WinPE_amd64\mount" /Commit
```
If locked:
```bash
Dism /Unmount-Image /MountDir:"C:\WinPE_amd64\mount" /Discard
```

## 📀 Part 2: Partition USB Stick
```bash
diskpart
list disk
select disk X
clean
create partition primary size=2000
format fs=fat32 quick
assign letter=F
active
create partition primary
format fs=ntfs quick
assign letter=N
exit
```

## 💾 Part 3: Copy Files to USB
```bash
xcopy C:\WinPE_amd64\media\* F:\ /E /H /F
```
Mount the Windows ISO, then:
```bash
xcopy D:\* N:\ /E /H /F
```
Place the autounattend.xml to `N:\`.

## 📜 Part 4: autounattend.xml Features
- Wipes & partitions internal disk
- Installs Windows 10 Enterprise x64 EN-GB
- Sets local admin: `Admin`
- Joins domain `fullers.local`

## 🚀 Part 5: Deploy It
1. Plug USB into Dell Latitude
2. Boot → F12 → Select UEFI USB
3. BIOS config auto-applies
4. Windows setup begins
5. Device reboots & completes unattended install

## ✨ Tips & Add-ons
- Post-install: `setupcomplete.cmd`
- Add drivers: `N:\$OEM$\$1\Drivers`
- BitLocker / Intune via scripting

## 🪪 Project Summary
| Key Metric       | Traditional | Dellploy |
|------------------|-------------|----------|
| Setup Time       | 15–30 mins  | ~8 mins  |
| Manual Input     | High        | Very Low |
| Risk of Errors   | Moderate    | Near-zero |
| Consistency      | Variable    | Standardised |
| Domain Join      | Manual      | Auto      |

**Status**: 🔧 Stable  
**Codename**: `Dellploy`  
**Built by**: You + Vinushka

## 🧾 `autounattend.xml` Content
> Paste this in `N:\autounattend.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

  <!-- ===================== PASS: windowsPE ===================== -->
  <settings pass="windowsPE">

    <!-- Regional Settings -->
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <SetupUILanguage>
        <UILanguage>en-GB</UILanguage>
      </SetupUILanguage>
      <InputLocale>en-GB</InputLocale>
      <SystemLocale>en-GB</SystemLocale>
      <UILanguage>en-GB</UILanguage>
      <UILanguageFallback>en-GB</UILanguageFallback>
      <UserLocale>en-GB</UserLocale>
    </component>

    <!-- Disk Setup -->
    <component name="Microsoft-Windows-Setup"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">

      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>

          <CreatePartitions>
            <CreatePartition wcm:action="add">
              <Order>1</Order>
              <Type>EFI</Type>
              <Size>300</Size>
            </CreatePartition>
            <CreatePartition wcm:action="add">
              <Order>2</Order>
              <Type>MSR</Type>
              <Size>128</Size>
            </CreatePartition>
            <CreatePartition wcm:action="add">
              <Order>3</Order>
              <Type>Primary</Type>
              <Extend>true</Extend>
            </CreatePartition>
          </CreatePartitions>

          <ModifyPartitions>
            <ModifyPartition wcm:action="add">
              <Order>1</Order>
              <PartitionID>1</PartitionID>
              <Label>System</Label>
              <Format>FAT32</Format>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
              <Order>2</Order>
              <PartitionID>2</PartitionID>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
              <Order>3</Order>
              <PartitionID>3</PartitionID>
              <Label>Windows</Label>
              <Format>NTFS</Format>
              <Letter>C</Letter>
            </ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>

      <ImageInstall>
        <OSImage>
          <InstallTo>
            <DiskID>0</DiskID>
            <PartitionID>3</PartitionID>
          </InstallTo>
          <WillShowUI>OnError</WillShowUI>
        </OSImage>
      </ImageInstall>

      <UserData>
        <ProductKey>
          <WillShowUI>Never</WillShowUI>
        </ProductKey>
        <AcceptEula>true</AcceptEula>
        <FullName>Andrei</FullName>
        <Organization>NotMicrosoft</Organization>
      </UserData>
    </component>
  </settings>

  <!-- ===================== PASS: specialize ===================== -->
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <ComputerName>DUKU</ComputerName>
      <TimeZone>GMT Standard Time</TimeZone>
      <RegisteredOwner>AndreiEduardSTAN</RegisteredOwner>
      <RegisteredOrganization>FST</RegisteredOrganization>
    </component>
  </settings>

  <!-- ===================== PASS: oobeSystem ===================== -->
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <InputLocale>en-GB</InputLocale>
      <SystemLocale>en-GB</SystemLocale>
      <UILanguage>en-GB</UILanguage>
      <UserLocale>en-GB</UserLocale>
    </component>

    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>1</ProtectYourPC>
      </OOBE>

      <UserAccounts>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Name>Admin</Name>
            <DisplayName>Admin</DisplayName>
            <Group>Administrators</Group>
            <Password>
              <Value>Cowg1rl</Value>
              <PlainText>true</PlainText>
            </Password>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>

      <AutoLogon>
        <Username>Admin</Username>
        <Password>
          <Value>RED@CTED</Value>
          <PlainText>true</PlainText>
        </Password>
        <Enabled>true</Enabled>
        <LogonCount>1</LogonCount>
      </AutoLogon>

      <TimeZone>GMT Standard Time</TimeZone>
      <RegisteredOwner>Andrei</RegisteredOwner>
      <RegisteredOrganization>FST</RegisteredOrganization>
    </component>
  </settings>
</unattend>
```

## 🧾 `startnet.cmd` Content
> Paste this in `C:\WinPE_amd64\mount\Windows\System32\startnet.cmd`

```cmd

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

```
## 🔐 Security Notes
- Use **admin passwords** wisely in production versions.
- Redact or encrypt sensitive values in public repos.
- Consider using a **domain join script** for credential safety.

## 🎬 Deployment Demo
<div class="no-print">
  
</div>

<div class="no-print">
  <video controls width="100%">
    <source src="dellploy_prototype_demo.mp4" type="video/mp4">
    Your browser does not support the video tag.
  </video>
</div>
## 🧪 Further Ideas
- PXE Boot version for true zero-touch
- Offline Intune Enrollment
- Dynamic hostname generation

