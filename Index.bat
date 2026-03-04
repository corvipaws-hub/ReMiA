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
echo ===== Generate Cubari index.json (folder groups) =====
echo Root: "%CD%"
echo Output: "%OUT%"
echo.

set "PS1=%TEMP%\cubari_index_%RANDOM%_%RANDOM%.ps1"

REM ---- Write PowerShell script safely ----
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
>>"%PS1%" echo function Get-ChapterNumber([string]$folder^) ^{
>>"%PS1%" echo ^  # match chapter_001, Chapter_12, chapter-003 etc.
>>"%PS1%" echo ^  $m = [regex]::Match($folder, '(?i)^chapter[_-]?(\d+)$'^)
>>"%PS1%" echo ^  if ($m.Success^) { return [int]$m.Groups[1].Value }
>>"%PS1%" echo ^  return $null
>>"%PS1%" echo ^}
>>"%PS1%" echo
>>"%PS1%" echo $chapters = @(^)
>>"%PS1%" echo Get-ChildItem -LiteralPath $root -Directory ^| ForEach-Object ^{
>>"%PS1%" echo ^  $n = Get-ChapterNumber $_.Name
>>"%PS1%" echo ^  if ($null -eq $n^) { return }
>>"%PS1%" echo ^  # only include if folder contains at least one jpg/jpeg
>>"%PS1%" echo ^  $has = Get-ChildItem -LiteralPath $_.FullName -File ^| Where-Object { $_.Extension -match '^\.(jpg^|jpeg)$' } ^| Select-Object -First 1
>>"%PS1%" echo ^  if (-not $has^) { return }
>>"%PS1%" echo ^  $chapters += [pscustomobject]@{ Num = $n; Folder = $_.Name }
>>"%PS1%" echo ^}
>>"%PS1%" echo
>>"%PS1%" echo $chapters = $chapters ^| Sort-Object Num
>>"%PS1%" echo
>>"%PS1%" echo $chapObj = [ordered]@{}
>>"%PS1%" echo foreach ($c in $chapters^) ^{
>>"%PS1%" echo ^  $chapObj[[string]$c.Num] = [ordered]@{
>>"%PS1%" echo ^    title  = ('Chapter ' + $c.Num^)
>>"%PS1%" echo ^    groups = [ordered]@{ $group = @($c.Folder) }
>>"%PS1%" echo ^  }
>>"%PS1%" echo ^  Write-Host ('Added Chapter ' + $c.Num + ' -> ' + $c.Folder^)
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
>>"%PS1%" echo $json = $index ^| ConvertTo-Json -Depth 10
>>"%PS1%" echo Set-Content -LiteralPath $out -Value $json -Encoding UTF8
>>"%PS1%" echo Write-Host ('Wrote ' + $out^)

REM ---- Run PowerShell ----
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "ERR=%ERRORLEVEL%"

REM ---- Cleanup ----
del "%PS1%" >nul 2>&1

echo.
if not "%ERR%"=="0" (
  echo [ERROR] Failed with exit code %ERR%
) else (
  echo Finished successfully.
)
pause
exit /b %ERR%