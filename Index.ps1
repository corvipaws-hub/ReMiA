$ErrorActionPreference = "Stop"

# ===== SETTINGS =====
$repo   = "corvipaws-hub/ReMiA"
$branch = "main"
$base   = "https://cdn.jsdelivr.net/gh/$repo@$branch"  # faster than raw.githubusercontent

$title = "Re-Made in Abyss (Content-Safe Fan Edit)"
$description = "Unofficial fan edit. Intended for mature audiences only (17+). Please support the official release.

Manga edit of Made in Abyss where sexual content related to underaged characters has been drawn over, and text modified. Edits are subtle and kept to a minimum. Nothing plot relevant is changed, edits are made for child nudity and perceive fetishistic content (e.g. urine, exhibitionism, bondage). 

Note: This edit does not remove gore, or substantially plot relevant sexual content."
$artist = "Akihito Tsukushi (original) / fan edit"
$author = "Akihito Tsukushi"
$group  = "/r/ReMiA"
$outFile = "index.json"
# ====================

function Get-ChapterNumber($name) {
    if ($name -match '^chapter[_-]?(\d+)$') { return [int]$matches[1] }
    return $null
}

# Chapter number -> Chapter title (Wikipedia volume list)
# Source: https://en.wikipedia.org/wiki/List_of_Made_in_Abyss_volumes
$ChapterTitles = @{
  1='Orth: The City of the Great Pit'; 2='The Abode of Trees and Fossils'; 3="Riko's Room: Former Torture Chamber"; 4='Belchero Orphanage'
  5='Resurrection Festival'; 6='Premonition'; 7='Eve of Departure'; 8='Here We Go!'
  9="The Depths' First Layer: The Edge of the Abyss"; 10="The Depths' Second Layer: The Forest of Temptation"; 11='Incinerator'; 12="Lowest Area of the Depths' Second Layer: The Inverted Forest"
  13='Seeker Camp'; 14='The Curse-Repelling Vessel'; 15='The Unmovable Sovereign'; 16='A Vile Mentoring Method'
  17='Survival Training'; 18="The Depths' Third Layer: The Great Fault"; 19='Poison and the Curse'; 20='Nanachi'
  21="Reg's Memories"; 22='The True Nature of the Curse'; 23='A Dreadful Experiment'; 24='Liberation of the Soul'
  25='A Return From Darkness'; 26='A Fresh Start'; 27='The Forbidden Field of Flowers'; 28='The Entrance to the Sixth Layer'
  29='A Fateful Reunion'; 30='Unforeseen Peril'; 31='Despair and Hope'; 32='The End of a Fierce Fight'
  33='The True Nature of the Mask'; 34='Counterattack'; 35='Clouded Memory'; 36='Miniature Garden of Dawn'
  37='Flower of Dawn'; 38='The Challengers'
  39='Capital of the Unreturned'; 40='Hollow Husk of Life'; 41='The Balancing of Values'; 42='Princess of the Hollows'
  43='Approaching Crisis'; 44="Hollows' Restaurant"; 45='Captive'; 46='The Luring'; 47='The Secret of the Village'
  48='The Compass Pointed to the Darkness'; 49='The Golden City'; 50='The Cradle of Desire'; 51='The Form the Wish Takes'
  52="Faputa's Promise"; 53='Prelude of Disintegration'; 54='All That You Gather'; 55='Faputa and Reg'
  56='A Gift'; 57='Value'; 58='Towards the Path of Flame'; 59='A Warm Darkness'; 60='Gold'
  61='You Can Go Anywhere'; 62='The Place of Song'; 63='The Curse Fleet'
  64='Juusou'; 65='In the Midst'; 66='Bottom Layer'
  67='Whereabouts of the Soul'; 68='Maelstrom Danger Zone - Part 1'; 69='Maelstrom Danger Zone - Part 2'
  70='Little Brother'; 71='Shooter'
}

# Chapter number -> Volume number (Wikipedia tankōbon grouping)
# v1: 1-8; v2: 9-16; v3: 17-24; v4: 25-32; v5: 33-38; v6: 39-42; v7: 43-47;
# v8: 48-51; v9: 52-55; v10: 56-60; v11: 61-63; v12: 64-66; v13: 67-69; v14: 70-71
function Get-VolumeNumber([int]$ch) {
    if ($ch -ge 1  -and $ch -le 8 ) { return "1"  }
    if ($ch -ge 9  -and $ch -le 16) { return "2"  }
    if ($ch -ge 17 -and $ch -le 24) { return "3"  }
    if ($ch -ge 25 -and $ch -le 32) { return "4"  }
    if ($ch -ge 33 -and $ch -le 38) { return "5"  }
    if ($ch -ge 39 -and $ch -le 42) { return "6"  }
    if ($ch -ge 43 -and $ch -le 47) { return "7"  }
    if ($ch -ge 48 -and $ch -le 51) { return "8"  }
    if ($ch -ge 52 -and $ch -le 55) { return "9"  }
    if ($ch -ge 56 -and $ch -le 60) { return "10" }
    if ($ch -ge 61 -and $ch -le 63) { return "11" }
    if ($ch -ge 64 -and $ch -le 66) { return "12" }
    if ($ch -ge 67 -and $ch -le 69) { return "13" }
    if ($ch -ge 70 -and $ch -le 71) { return "14" }
    return ""
}

$dirs = Get-ChildItem -Directory |
        ForEach-Object { $n = Get-ChapterNumber $_.Name; if ($null -ne $n) { [pscustomobject]@{ Num=$n; Name=$_.Name; Full=$_.FullName } } } |
        Sort-Object Num

$chapters = [ordered]@{}
$cover = $null
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))

foreach ($d in $dirs) {
    $num = [int]$d.Num

    $images = Get-ChildItem -LiteralPath $d.Full -File |
              Where-Object { $_.Extension -match '^\.(jpg|jpeg)$' } |
              Sort-Object Name
    if (-not $images) { continue }

    $urls = @()
    foreach ($img in $images) {
        $urls += "$base/$($d.Name)/$($img.Name)"
    }

    if (-not $cover) { $cover = $urls[0] }

    $name = $ChapterTitles[$num]
    $prettyTitle = if ($name) { "Chapter $num - $name" } else { "Chapter $num" }
    $vol = Get-VolumeNumber $num

    $chapters["$num"] = [ordered]@{
        title = $prettyTitle
        volume = $vol
        last_updated = $timestamp
        groups = [ordered]@{
            $group = $urls
        }
    }
}

$index = [ordered]@{
    title = $title
    description = $description
    artist = $artist
    author = $author
    cover = $cover
    chapters = $chapters
}

$index | ConvertTo-Json -Depth 60 | Set-Content -LiteralPath $outFile -Encoding UTF8
Write-Host "Wrote $outFile"
Write-Host "Cover: $cover"