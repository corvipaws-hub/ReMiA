$ErrorActionPreference = "Stop"

# ===== SETTINGS =====
$repo = "corvipaws-hub/ReMiA"
$branch = "main"
$base = "https://cdn.jsdelivr.net/gh/$repo@$branch"

$title = "Re-Made in Abyss (Content-Safe Fan Edit)"
$description = "Unofficial fan edit. Sexual content involving minors removed. Intended for mature audiences only (17+). Please support the official release."
$artist = "Akihito Tsukushi (original) / fan edit"
$author = "Akihito Tsukushi"
$group = "/r/ReMiA"

# ====================

function Get-ChapterNumber($name) {
    if ($name -match '^chapter[_-]?(\d+)$') {
        return [int]$matches[1]
    }
    return $null
}

$dirs = Get-ChildItem -Directory | Where-Object { Get-ChapterNumber $_.Name } |
        Sort-Object { Get-ChapterNumber $_.Name }

$chapters = [ordered]@{}
$cover = $null
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))

foreach ($d in $dirs) {

    $num = Get-ChapterNumber $d.Name

    $images = Get-ChildItem $d.FullName -File |
              Where-Object { $_.Extension -match '\.(jpg|jpeg)$' } |
              Sort-Object Name

    if (!$images) { continue }

    $urls = @()

    foreach ($img in $images) {
        $urls += "$base/$($d.Name)/$($img.Name)"
    }

    if (!$cover) {
        $cover = $urls[0]
    }

    $chapters["$num"] = @{
        title = "Chapter $num"
        volume = "1"
        last_updated = $timestamp
        groups = @{
            $group = $urls
        }
    }
}

$index = @{
    title = $title
    description = $description
    artist = $artist
    author = $author
    cover = $cover
    chapters = $chapters
}

$index | ConvertTo-Json -Depth 50 | Set-Content "index.json" -Encoding UTF8

Write-Host "index.json generated."
Write-Host "Cover:" $cover