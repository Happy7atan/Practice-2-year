@echo off
setlocal enabledelayedexpansion
title Автоматическая установка ПО для аудиторий кафедры ИТ и ЭО

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ОШИБКА] Запустите скрипт от имени Администратора!
    pause
    exit /b 1
)
echo [1/7] Проверка и установка Chocolatey

where choco >nul 2>&1
if %errorLevel% neq 0 (
    echo Chocolatey не найден. Начинаем установку...
    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

    set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

    where choco >nul 2>&1
    if !errorLevel! neq 0 (
        echo [ОШИБКА] Не удалось установить Chocolatey. Проверьте подключение к интернету.
        pause
        exit /b 2
    )
    echo Chocolatey успешно установлен.
) else (
    echo Chocolatey уже установлен:
    choco --version
)

echo [2/7] Установка браузеров, утилит и архиваторов

choco install googlechrome firefox yandex-browser 7zip flameshot sumatrapdf far qalculate -y
choco install vscode -y
choco install git github-desktop -y

echo [3/7] Установка сред разработки и научного ПО

choco install docker-desktop pycharm-community -y
choco install anaconda3 -y
choco install maxima knime gimp zettlr miktex texstudio -y

echo [4/7] Установка языков программирования

choco install python rust julia -y
choco install msys2 -y

echo [5/7] Установка приложений через winget 

echo Установка Arc Browser...
winget install --id TheBrowserCompany.Arc --silent --accept-source-agreements --accept-package-agreements
if !errorLevel! NEQ 0 (
    echo [!] Arc Browser не установлен. Установите вручную из Microsoft Store.
)

echo.

echo [6/7] Установка расширений VS Code

timeout /t 10 /nobreak >nul

code --install-extension ms-python.python
code --install-extension ms-vscode.cpptools
code --install-extension ms-azuretools.vscode-docker
code --install-extension eamodio.gitlens
code --install-extension ritwickdey.LiveServer
code --install-extension ecmel.vscode-html-css
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension julialang.language-julia
code --install-extension rust-lang.rust-analyzer
code --install-extension ms-vscode-remote.remote-wsl

echo [7/7] Настройка WSL 2

if /I "%~1"=="/continue" goto :wsl_install_distros

dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

if !errorLevel! EQU 3010 set "REBOOT_NEEDED=1"
if !errorLevel! EQU 0 set "REBOOT_NEEDED=0"

if "!REBOOT_NEEDED!"=="1" (
    echo Требуется перезагрузка. После входа скрипт продолжит автоматически.
    schtasks /create /tn "WSL_Install_Continue" /tr "\"%~f0\" /continue" /sc onlogon /rl highest /f >nul

    if !errorLevel! NEQ 0 (
        echo [!] Не удалось создать задачу автопродолжения.
        echo     Запустите скрипт вручную с параметром /continue.
    )

    choice /M "Перезагрузить сейчас"
    if !errorLevel! EQU 1 shutdown /r /t 5
    exit /b
)

goto :wsl_install_distros

:wsl_install_distros
wsl --update
wsl --install -d Ubuntu-22.04
wsl --install -d Ubuntu-24.04
wsl --set-default-version 2

schtasks /query /tn "WSL_Install_Continue" >nul 2>&1
if !errorLevel! EQU 0 schtasks /delete /tn "WSL_Install_Continue" /f >nul 2>&1

echo.
echo Установка завершена.
echo Проверьте WSL: wsl --list --verbose
echo Telemost и Sber Jazz установите вручную.
start "" "https://telemost.yandex.ru"
start "" "https://developers.sber.ru/portal/products/jazz-by-sber"
pause
