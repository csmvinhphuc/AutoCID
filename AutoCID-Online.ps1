#Requires -Version 3.0
<#
.SYNOPSIS
  AutoCID Online Launcher - chay truc tiep tu GitHub bang 1 dong lenh:
    irm https://raw.githubusercontent.com/USER/AutoCID/main/AutoCID-Online.ps1 | iex
 uot;HUONG DAN: sua 3 gia tri $Repo, $Asset, $ScriptUrl o cau hinh ben duoi
  cho khop repo GitHub cua ban, roi upload file nay len repo.
#>
param(
  [ValidateSet('AutoCID', 'Obf', 'MaHoa')]
  [string]$Exe = 'AutoCID',
  [string]$Version = 'latest',   # 'latest' hoac tag cu the, vd: 'v1.0.0'
  [string]$ZipPath = '',         # dung file zip co san (de test offline)
  [string]$Dir = '',             # thu muc giai nen (mac dinh %TEMP%\AutoCID)
  [switch]$NoRun,                # chi tai + giai nen, khong chay exe
  [switch]$Keep                   # giu lai file zip sau khi xong
)

# ================= CAU HINH - SUA 3 DONG NAY =================
$Repo      = 'csmvinhphuc/AutoCID'
$Asset     = 'AutoCID_Full_MoiNhat.zip'
$ScriptUrl = 'https://raw.githubusercontent.com/csmvinhphuc/AutoCID/main/AutoCID-Online.ps1'
# =============================================================

$ExeMap = @{
  'AutoCID' = 'EXE\AutoCID.exe'
  'Obf'     = 'EXE\AutoCID_Obf.exe'
  'MaHoa'   = 'EXE\AutoCID_MaHoa_Obf.exe'
}

function Test-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
}

try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

# --- Tu nang quyen Admin (tool bat buoc Admin de goi slmgr) ---
if (!(Test-Admin) -and !$NoRun) {
  Write-Host 'Can quyen Administrator, dang tu mo lai...' -ForegroundColor Yellow
  $tmp = Join-Path $env:TEMP 'AutoCID-Online.ps1'
  Invoke-WebRequest -Uri $ScriptUrl -OutFile $tmp -UseBasicParsing
  $arg = '-NoProfile -ExecutionPolicy Bypass -File "' + $tmp + '" -Exe ' + $Exe + ' -Version ' + $Version
  if ($Dir) { $arg += ' -Dir "' + $Dir + '"' }
  if ($Keep) { $arg += ' -Keep' }
  Start-Process powershell -ArgumentList $arg -Verb RunAs
  return
}

if (!$Dir) { $Dir = Join-Path $env:TEMP 'AutoCID' }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$zip = Join-Path $Dir $Asset

# --- Lay file zip ---
if ($ZipPath -and (Test-Path $ZipPath)) {
  Write-Host ('Dung file co san: ' + $ZipPath)
  Copy-Item $ZipPath $zip -Force
} else {
  if ($Version -eq 'latest') {
    $url = 'https://github.com/' + $Repo + '/releases/latest/download/' + $Asset
  } else {
    $url = 'https://github.com/' + $Repo + '/releases/download/' + $Version + '/' + $Asset
  }
  Write-Host ('Dang tai: ' + $url)
  try {
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  } catch {
    Write-Host 'Link truc tiep loi, thu qua GitHub API...' -ForegroundColor Yellow
    if ($Version -eq 'latest') { $api = 'https://api.github.com/repos/' + $Repo + '/releases/latest' }
    else { $api = 'https://api.github.com/repos/' + $Repo + '/releases/tags/' + $Version }
    $rel = Invoke-RestMethod -Uri $api -TimeoutSec 30
    $a = @($rel.assets | Where-Object { $_.name -eq $Asset })
    if ($a.Count -eq 0) {
      Write-Host 'Khong thay asset dinh kem, thu link trong mo ta release...' -ForegroundColor Yellow
      $m = [regex]::Match([string]$rel.body, 'https://github\.com/user-attachments/files/[^\s\)\]]+')
      if (!$m.Success) { throw ('Khong thay asset ' + $Asset + ' trong release. Hay dinh kem file vao release (khung Attach binaries).') }
      Invoke-WebRequest -Uri $m.Value -OutFile $zip -UseBasicParsing
    } else {
      Invoke-WebRequest -Uri $a[0].browser_download_url -OutFile $zip -UseBasicParsing
    }
  }
  Write-Host ('Da tai xong (' + ((Get-Item $zip).Length / 1MB).ToString('0.0') + ' MB)')
}
if (!(Test-Path $zip)) { throw 'Tai that bai: khong co file zip. Hay chac chan repo da Publish Release (khong phai Draft) va asset dung ten.' }

# --- Giai nen ---
Write-Host ('Dang giai nen vao: ' + $Dir)
try { Add-Type -AssemblyName System.IO.Compression.FileSystem } catch { }
Expand-Archive -Path $zip -DestinationPath $Dir -Force
if (!$Keep -and !$ZipPath) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }

# --- Chay tool ---
$exePath = Join-Path $Dir $ExeMap[$Exe]
if (!(Test-Path $exePath)) { throw ('Khong thay ' + $exePath + '. Asset zip co dung cau truc EXE/... ?') }
if ($NoRun) { Write-Host ('Xong (NoRun). File chay o: ' + $exePath); return $exePath }
Write-Host ('Dang chay: ' + $exePath) -ForegroundColor Green
Start-Process $exePath
