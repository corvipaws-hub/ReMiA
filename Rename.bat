@echo off
setlocal EnableExtensions

REM ================= SETTINGS =================
REM DRYRUN=1 preview, DRYRUN=0 actually rename
set "DRYRUN=0"

REM Minimum digits to pad to (3 => 001, 012, 120)
set "PADLEN=3"
REM ============================================

echo.
echo ===== Cubari Chapter Image Renamer (robust) =====
echo Root: "%CD%"
echo DRYRUN=%DRYRUN%  (1=preview, 0=rename)
echo PADLEN=%PADLEN%
echo.

set "PS1=%TEMP%\cubari_rename_%RANDOM%_%RANDOM%.ps1"

REM ---- write PowerShell script to a temp file ----
> "%PS1%" echo $ErrorActionPreference = 'Stop'
>>"%PS1%" echo $dry    = [int]$env:DRYRUN
>>"%PS1%" echo $padLen = [int]$env:PADLEN
>>"%PS1%" echo $root   = Get-Location
>>"%PS1%" echo
>>"%PS1%" echo Get-ChildItem -LiteralPath $root -Directory -Filter 'Chapter*' ^| ForEach-Object ^{
>>"%PS1%" echo ^  $chapterDir = $_.FullName
>>"%PS1%" echo ^  Write-Host ("--- Processing: " + $chapterDir)
>>"%PS1%" echo
>>"%PS1%" echo ^  Get-ChildItem -LiteralPath $chapterDir -File ^| Where-Object ^{
>>"%PS1%" echo ^    $_.Extension -match '^\.(jpg^|jpeg)$'
>>"%PS1%" echo ^  } ^| ForEach-Object ^{
>>"%PS1%" echo ^    $old    = $_.Name
>>"%PS1%" echo ^    $ext    = $_.Extension
>>"%PS1%" echo ^    $base   = $_.BaseName
>>"%PS1%" echo ^    $digits = ($base -replace '\D','')
>>"%PS1%" echo
>>"%PS1%" echo ^    if ([string]::IsNullOrWhiteSpace($digits)) ^{
>>"%PS1%" echo ^      Write-Host ("  [skip - no digits] " + $old)
>>"%PS1%" echo ^      return
>>"%PS1%" echo ^    }
>>"%PS1%" echo
>>"%PS1%" echo ^    if ($digits.Length -lt $padLen) ^{
>>"%PS1%" echo ^      $digits = $digits.PadLeft($padLen,'0')
>>"%PS1%" echo ^    }
>>"%PS1%" echo
>>"%PS1%" echo ^    $new = $digits + $ext
>>"%PS1%" echo
>>"%PS1%" echo ^    if ($old -ieq $new) ^{
>>"%PS1%" echo ^      Write-Host ("  [ok] " + $old)
>>"%PS1%" echo ^      return
>>"%PS1%" echo ^    }
>>"%PS1%" echo
>>"%PS1%" echo ^    $newPath = Join-Path $chapterDir $new
>>"%PS1%" echo ^    if (Test-Path -LiteralPath $newPath) ^{
>>"%PS1%" echo ^      Write-Host ("  [WARNING - target exists, skipping] " + $old + " -> " + $new)
>>"%PS1%" echo ^      return
>>"%PS1%" echo ^    }
>>"%PS1%" echo
>>"%PS1%" echo ^    Write-Host ("  " + $old + " -> " + $new)
>>"%PS1%" echo ^    if ($dry -eq 0) ^{
>>"%PS1%" echo ^      Move-Item -LiteralPath $_.FullName -Destination $newPath
>>"%PS1%" echo ^    }
>>"%PS1%" echo ^  }
>>"%PS1%" echo
>>"%PS1%" echo ^  Write-Host ""
>>"%PS1%" echo ^}
>>"%PS1%" echo
>>"%PS1%" echo Write-Host "Done."

REM ---- run it ----
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "ERR=%ERRORLEVEL%"

REM ---- cleanup ----
del "%PS1%" >nul 2>&1

echo.
if not "%ERR%"=="0" (
  echo [ERROR] Script failed with exit code %ERR%
) else (
  echo Finished successfully.
)
pause
exit /b %ERR%