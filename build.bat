@echo off
setlocal EnableExtensions
title LinuxSpherso ISO builder
rem ===========================================================================
rem  Build the LinuxSpherso ISO on Windows 10/11.
rem  Uses WSL2 (Windows Subsystem for Linux) with Debian to run build.sh.
rem
rem    build.bat            full build
rem    build.bat noproton   skip the GE-Proton download (~500 MB smaller)
rem
rem  Needs: ~30 GB free on C:, internet, virtualization enabled in BIOS.
rem  Output: LinuxSpherso-amd64.hybrid.iso next to this file.
rem ===========================================================================

cd /d "%~dp0"
set "DISTRO=Debian"
rem Make "wsl -l" print plain text instead of UTF-16
set "WSL_UTF8=1"
set "GEPROTON=1"
if /i "%~1"=="noproton" set "GEPROTON=0"

echo.
echo   ===  LinuxSpherso ISO builder  ===
echo.

rem --- 1. WSL present? -------------------------------------------------------
where wsl.exe >nul 2>&1
if errorlevel 1 (
  echo [!] WSL is not available on this PC.
  echo     Open PowerShell as Administrator and run:   wsl --install
  echo     Restart your PC, then run build.bat again.
  goto :fail
)

rem --- 2. Debian installed in WSL? ------------------------------------------
rem  wsl -l prints UTF-16, so search it with "find" which handles that.
wsl.exe -l -q 2>nul | find /i "%DISTRO%" >nul
if errorlevel 1 (
  echo [*] Installing Debian for WSL. A Debian window will open:
  echo     create a username and password there, then close it
  echo     and run build.bat again.
  wsl.exe --install -d %DISTRO%
  goto :fail
)

rem --- 3. Must be WSL2 (WSL1 cannot mount filesystems) -----------------------
wsl.exe -d %DISTRO% -u root -- sh -c "grep -qi microsoft-standard /proc/version || grep -qi wsl2 /proc/version" >nul 2>&1
if errorlevel 1 (
  echo [*] Converting Debian to WSL2, this can take a few minutes...
  wsl.exe --set-version %DISTRO% 2
  if errorlevel 1 (
    echo [!] Could not switch to WSL2. Enable "Virtual Machine Platform" in
    echo     Windows Features and virtualization in your BIOS, then retry.
    goto :fail
  )
)

rem --- 4. Build inside WSL ---------------------------------------------------
rem  Build in your normal WSL user's home so Explorer can open the folder.
set "WSLUSER="
for /f "delims=" %%u in ('wsl.exe -d %DISTRO% -- whoami 2^>nul') do set "WSLUSER=%%u"
if "%WSLUSER%"=="" set "WSLUSER=root"
echo [*] Building LinuxSpherso inside WSL. This takes 30-90 minutes
echo     and downloads about 4 GB. Leave this window open.
echo.
wsl.exe -d %DISTRO% -u root --cd "%~dp0." -- env WITH_GE_PROTON=%GEPROTON% WSL_USER=%WSLUSER% bash -c "tr -d '\r' < tools/wsl-build.sh | bash"
if errorlevel 1 (
  echo.
  echo [!] The build failed. Open the log in File Explorer:
  if /i "%WSLUSER%"=="root" (echo     \\wsl.localhost\%DISTRO%\root\LinuxSpherso-build\build.log) else (echo     \\wsl.localhost\%DISTRO%\home\%WSLUSER%\LinuxSpherso-build\build.log)
  goto :fail
)

if not exist "LinuxSpherso-amd64.hybrid.iso" (
  echo [!] The build finished but no ISO was copied back.
  goto :fail
)

echo.
echo [OK] ISO ready:  %~dp0LinuxSpherso-amd64.hybrid.iso
echo      Flash it to a USB stick with Rufus or balenaEtcher
echo      (use DD mode in Rufus), or boot it in VirtualBox/VMware.
echo.
pause
exit /b 0

:fail
echo.
pause
exit /b 1
