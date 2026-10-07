# ==============================================================================
# סנכרון וניהול טקסטים - פרויקט עפרה על הספה
# מאפשר המרה דו-כיוונית בין data.json לבין טקסטים_עפרה_על_הספה.csv (לאקסל)
# ==============================================================================

param(
    [switch]$FromCsv,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$currentDir = Get-Location
$jsonPath = Join-Path $currentDir 'data.json'
$csvPath = Join-Path $currentDir 'טקסטים_עפרה_על_הספה.csv'
$assemblePath = Join-Path $currentDir 'assemble_index.ps1'

function Show-Usage {
    Write-Host @"
======================================================
  מדריך לשימוש בכלי סנכרון הטקסטים - עפרה על הספה
======================================================

1. ייצוא מ-JSON ל-CSV (עבור אקסל):
   .\sync_texts.ps1
   (מעדכן את טקסטים_עפרה_על_הספה.csv עם כל הטקסטים העדכניים)

2. ייבוא שינויים מ-CSV (אקסל) בחזרה לאתר:
   .\sync_texts.ps1 -FromCsv
   (מעדכן את data.json ובונה מחדש את index.html)

"@
}

if ($Help) {
    Show-Usage
    exit 0
}

# -----------------------------------------------------------------------------
# פעולה 1: ייבוא שינויים מקובץ CSV (אקסל) לתוך data.json ו-index.html
# -----------------------------------------------------------------------------
if ($FromCsv) {
    if (-not (Test-Path $csvPath)) {
        Write-Error "הקובץ $csvPath לא נמצא!"
        exit 1
    }

    Write-Host "קורא נתונים מקובץ CSV (אקסל)..." -ForegroundColor Cyan
    $csvData = Import-Csv -Path $csvPath -Encoding UTF8

    # קריאת data.json הקיים כדי לשמר מאפיינים טכניים (מידות תמונה וכדומה)
    $existingRaw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
    $existingObj = ConvertFrom-Json $existingRaw
    $existingList = if ($existingObj -is [array]) { $existingObj } elseif ($existingObj.PSObject.Properties['families']) { $existingObj.families } elseif ($existingObj.PSObject.Properties['value']) { $existingObj.value } else { $existingObj }
    
    $existingMap = @{}
    foreach ($item in $existingList) {
        $existingMap[[int]$item.id] = $item
    }

    $updatedFamilies = @()
    foreach ($row in $csvData) {
        $id = [int]$row.'מספר'
        $existing = $existingMap[$id]

        $lastName = ($row.'שם משפחה' -replace '^\s+|\s+$', '')
        $firstName = ($row.'שם פרטי' -replace '^\s+|\s+$', '')
        $year = ($row.'שנת הגעה' -replace '^\s+|\s+$', '')
        $story = ($row.'סיפור המשפחה' -replace '^\s+|\s+$', '')
        $fbLink = ($row.'קישור פייסבוק' -replace '^\s+|\s+$', '')
        $image = ($row.'קובץ תמונה' -replace '^\s+|\s+$', '')

        $fullName = "$firstName $lastName".Trim()

        # בדיקת מייסדים (1975 או 1976 או תשל"ה/תשל"ו)
        $isFounder = $false
        if ($year -match '1975|1976|תשל[הו]|75|76') {
            $isFounder = $true
        }

        $hasStory = [bool]($story -and $story.Trim().Length -gt 0)
        $hasImage = [bool]($image -and $image.Trim().Length -gt 0)

        $famObj = [PSCustomObject]@{
            id = $id
            serial = [string]$id
            lastName = $lastName
            firstName = $firstName
            fullName = $fullName
            year = $year
            isFounder = $isFounder
            image = $image
            imageUrl = $image
            fbLink = $fbLink
            story = $story
            hasStory = $hasStory
            hasImage = $hasImage
            isVertical = if ($existing -and $existing.isVertical -ne $null) { [bool]$existing.isVertical } else { $true }
            width = if ($existing -and $existing.width) { [int]$existing.width } else { 1366 }
            height = if ($existing -and $existing.height) { [int]$existing.height } else { 2048 }
        }

        $updatedFamilies += $famObj
    }

    # שמירה ל-data.json ללא BOM
    $jsonFormatted = ($updatedFamilies | ConvertTo-Json -Depth 10) -replace '\\u0027', "'"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($jsonPath, $jsonFormatted, $utf8NoBom)

    Write-Host "✓ עודכן בהצלחה קובץ data.json עם $($updatedFamilies.Count) משפחות." -ForegroundColor Green

    # עדכון index.html
    if (Test-Path $assemblePath) {
        Write-Host "מרכיב מחדש את index.html..." -ForegroundColor Cyan
        & powershell -ExecutionPolicy Bypass -File $assemblePath
    }

    $storiesCount = ($updatedFamilies | Where-Object { $_.hasStory }).Count
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host " הסנכרון הושלם בהצלחה!" -ForegroundColor Green
    Write-Host " סך הכל משפחות: $($updatedFamilies.Count)" -ForegroundColor Green
    Write-Host " משפחות עם סיפור מלא: $storiesCount" -ForegroundColor Green
    Write-Host "======================================================" -ForegroundColor Green
    exit 0
}

# -----------------------------------------------------------------------------
# פעולה 2: ייצוא מ-data.json לקובץ CSV (עבור אקסל) ותיקון מבנה JSON
# -----------------------------------------------------------------------------
Write-Host "קורא את data.json..." -ForegroundColor Cyan
$jsonRaw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
$jsonObj = ConvertFrom-Json $jsonRaw
$families = if ($jsonObj -is [array]) { $jsonObj } elseif ($jsonObj.PSObject.Properties['families']) { $jsonObj.families } elseif ($jsonObj.PSObject.Properties['value']) { $jsonObj.value } else { $jsonObj }

# ניקוי וסדר למבנה data.json
$cleanList = @()
$csvRows = @()

foreach ($it in $families) {
    $id = [int]$it.id
    $lastName = [string]$it.lastName
    $firstName = [string]$it.firstName
    $fullName = if ($it.fullName) { [string]$it.fullName } else { "$firstName $lastName".Trim() }
    $year = [string]$it.year
    $story = [string]$it.story
    $fbLink = [string]$it.fbLink
    $image = if ($it.image) { [string]$it.image } else { [string]$it.imageUrl }
    
    $isFounder = if ($it.isFounder -ne $null) { [bool]$it.isFounder } else { [bool]($year -match '1975|1976|תשל[הו]|75|76') }
    $hasStory = [bool]($story -and $story.Trim().Length -gt 0)
    $hasImage = [bool]($image -and $image.Trim().Length -gt 0)

    $cleanObj = [PSCustomObject]@{
        id = $id
        serial = [string]$id
        lastName = $lastName
        firstName = $firstName
        fullName = $fullName
        year = $year
        isFounder = $isFounder
        image = $image
        imageUrl = $image
        fbLink = $fbLink
        story = $story
        hasStory = $hasStory
        hasImage = $hasImage
        isVertical = if ($it.isVertical -ne $null) { [bool]$it.isVertical } else { $true }
        width = if ($it.width) { [int]$it.width } else { 1366 }
        height = if ($it.height) { [int]$it.height } else { 2048 }
    }
    $cleanList += $cleanObj

    $csvRows += [PSCustomObject]@{
        'מספר' = $id
        'שם משפחה' = $lastName
        'שם פרטי' = $firstName
        'שנת הגעה' = $year
        'סיפור המשפחה' = $story
        'קישור פייסבוק' = $fbLink
        'קובץ תמונה' = $image
    }
}

# כתיבת data.json כמערך תקני ללא BOM
$jsonFormatted = ($cleanList | ConvertTo-Json -Depth 10) -replace '\\u0027', "'"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($jsonPath, $jsonFormatted, $utf8NoBom)
Write-Host "✓ נשמר data.json תקני ומסודר (ללא BOM, סך הכל $($cleanList.Count) משפחות)." -ForegroundColor Green

# כתיבת CSV עבור אקסל עם UTF-8 BOM
try {
    $csvRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "✓ נוצר קובץ אקסל נוח: טקסטים_עפרה_על_הספה.csv ($($csvRows.Count) שורות)." -ForegroundColor Green
} catch {
    Write-Warning "קובץ ה-CSV נעול כרגע (פתוח באקסל), דילגנו עליו. שאר הקבצים (data.json ו-index.html) עודכנו בהצלחה!"
}

# עדכון index.html
if (Test-Path $assemblePath) {
    & powershell -ExecutionPolicy Bypass -File $assemblePath
}

$storiesCount = ($cleanList | Where-Object { $_.hasStory }).Count
Write-Host "======================================================" -ForegroundColor Green
Write-Host " הקבצים מוכנים ומסונכרנים!" -ForegroundColor Green
Write-Host " 1. קובץ מרכזי לאתר: data.json" -ForegroundColor Green
Write-Host " 2. קובץ עריכה באקסל: טקסטים_עפרה_על_הספה.csv" -ForegroundColor Green
Write-Host " סך הכל משפחות: $($cleanList.Count), עם סיפור מתועד: $storiesCount" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
