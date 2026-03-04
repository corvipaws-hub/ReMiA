@echo off
setlocal EnableExtensions

REM ================= SETTINGS =================
set "OUT=index.json"
set "GROUP_NAME=Alt"

set "TITLE=Re-Made in Abyss (Content-Safe Fan Edit)"
set "DESCRIPTION=Unofficial fan edit. Sexual content involving minors removed. Intended for mature audiences only (17+). Please support the official release."
set "ARTIST=Akihito Tsukushi (original) / fan edit"
set "AUTHOR=Akihito Tsukushi"
REM ===========================================

echo.
echo ===== Create Cubari index.json (explicit page list) =====
echo Root: "%CD%"
echo Output: "%OUT%"
echo.

REM --- SAFETY: remove accidental stray file named just ' ---
if exist "'" del /q "'" >nul 2>&1

set "PS1=%TEMP%\cubari_index_%RANDOM%_%RANDOM%.ps1"

REM ---- Write PS1 safely (escape pipes as ^| so CMD doesn't break) ----
> "%PS1%"  echo $ErrorActionPreference = 'Stop'
>>"%PS1%" echo $root  = Get-Location
>>"%PS1%" echo $out   = Join-Path $root $env:OUT
>>"%PS1%" echo $group = $env:GROUP_NAME
>>"%PS1%" echo
>>"%PS1%" echo $title       = $env:TITLE
>>"%PS1%" echo $description = $env:DESCRIPTION
>>"%PS1%" echo $artist      = $env:ARTIST
>>"%PS1%" echo $author      = $env:AUTHOR
>>"%PS1%" echo
>>"%PS1%" echo function Get-FirstNumber([string]$s^) ^{
>>"%PS1%" echo ^  $m = [regex]::Match($s, '\d+'^)
>>"%PS1%" echo ^  if ($m.Success^) { return [int]$m.Value } else { return $null }
>>"%PS1%" echo ^}
>>"%PS1%" echo
>>"%PS1%" echo $chapterFolders = Get-ChildItem -LiteralPath $root -Directory ^| Where-Object { $_.Name -match '^(?i)chapter' }
>>"%PS1%" echo
>>"%PS1%" echo $chapters = @(^)
>>"%PS1%" echo foreach ($d in $chapterFolders^) ^{
>>"%PS1%" echo ^  $num = Get-FirstNumber $d.Name
>>"%PS1%" echo ^  if ($null -eq $num^) { Write-Host ('[skip - no chapter number] ' + $d.Name^); continue }
>>"%PS1%" echo ^  $chapters += [pscustomobject]@{ Num = $num; Folder = $d.Name; Full = $d.FullName }
>>"%PS1%" echo ^}
>>"%PS1%" echo $chapters = $chapters ^| Sort-Object Num
>>"%PS1%" echo
>>"%PS1%" echo $chapObj = [ordered]@{}
>>"%PS1%" echo foreach ($c in $chapters^) ^{
>>"%PS1%" echo ^  $imgs = Get-ChildItem -LiteralPath $c.Full -File ^| Where-Object { $_.Extension -match '^\.(jpg^|jpeg)$' }
>>"%PS1%" echo ^  if (-not $imgs^) { Write-Host ('[skip - no images] ' + $c.Folder^); continue }
>>"%PS1%" echo ^  $imgs = $imgs ^| Sort-Object @{ Expression = { (Get-FirstNumber $_.BaseName^) }; Ascending = $true }, Name
>>"%PS1%" echo ^  $paths = @(^)
>>"%PS1%" echo ^  foreach ($im in $imgs^) ^{
>>"%PS1%" echo ^    $paths += (($c.Folder + '/' + $im.Name^) -replace '\\','/'^)
>>"%PS1%" echo ^  }
>>"%PS1%" echo ^  $chapObj[[string]$c.Num] = [ordered]@{
>>"%PS1%" echo ^    title  = ('Chapter_' + $c.Num^)
>>"%PS1%" echo ^    groups = [ordered]@{ $group = $paths }
>>"%PS1%" echo ^  }
>>"%PS1%" echo ^  Write-Host ('Added Chapter ' + $c.Num + ' (' + $paths.Count + ' pages^) -> ' + $c.Folder^)
>>"%PS1%" echo ^}
>>"%PS1%" echo
>>"%PS1%" echo $index = [ordered]@{
>>"%PS1%" echo ^  title       = $title
>>"%PS1%" echo ^  description = $description
>>"%PS1%" echo ^  artist      = $artist
>>"%PS1%" echo ^  author      = $author
>>"%PS1%" echo ^  chapters    = $chapObj
>>"%PS1%" echo }
>>"%PS1%" echo
>>"%PS1%" echo $json = $index ^| ConvertTo-Json -Depth 30
>>"%PS1%" echo Set-Content -LiteralPath $out -Value $json -Encoding UTF8
>>"%PS1%" echo Write-Host ('Wrote ' + $out^)

REM ---- Run the PS1 ----
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "ERR=%ERRORLEVEL%"

REM ---- Cleanup temp script ----
del "%PS1%" >nul 2>&1

REM --- SAFETY AGAIN: remove accidental stray file named just ' ---
if exist "'" del /q "'" >nul 2>&1

echo.
if not "%ERR%"=="0" (
  echo [ERROR] index.json generation failed with exit code %ERR%
) else (
  echo Finished successfully.
)
pause
exit /b %ERR%