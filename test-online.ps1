$ErrorActionPreference = 'Stop'
$f = 'C:\Users\Administrator\Documents\Default Project\Github\AutoCID-Online.ps1'
$errs = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$errs)
if ($errs.Count -eq 0) { Write-Output 'SYNTAX-OK' }
else { $errs | ForEach-Object { Write-Output $_.Message }; throw 'syntax loi' }

# Test chuc nang voi zip local (khong chay exe)
$r = & $f -ZipPath 'C:\Users\Administrator\Documents\Default Project\AutoCID_Full_MoiNhat.zip' -Dir 'C:\Users\Administrator\AppData\Local\Temp\opencode\autocid-test' -NoRun -Keep
Write-Output ('RET=' + $r)
Get-ChildItem 'C:\Users\Administrator\AppData\Local\Temp\opencode\autocid-test\EXE' | Select-Object Name, Length
