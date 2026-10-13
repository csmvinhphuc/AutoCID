@echo off
rem AutoCID Online Launcher cho CMD - nhap doi Admin tu dong
rem Cach dung: AutoCID-Online.bat [-Exe AutoCID/Obf/MaHoa] [-Version v1.0.0] [-NoRun]
set URL=https://raw.githubusercontent.com/csmvinhphuc/AutoCID/main/AutoCID-Online.ps1
if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm '%URL%' | iex"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([ScriptBlock]::Create((irm '%URL%'))) %*"
)
