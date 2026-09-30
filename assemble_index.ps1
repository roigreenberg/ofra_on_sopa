$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$templatePath = Join-Path (Get-Location) 'template.html'
$dataPath = Join-Path (Get-Location) 'data.json'
$outputPath = Join-Path (Get-Location) 'index.html'

$template = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
$data = [System.IO.File]::ReadAllText($dataPath, [System.Text.Encoding]::UTF8)

$replacement = "const EMBEDDED_BACKUP_DATA = " + $data.Trim() + ";"
$output = $template.Replace("/* __EMBEDDED_BACKUP_DATA__ */", $replacement)

[System.IO.File]::WriteAllText($outputPath, $output, [System.Text.Encoding]::UTF8)

Write-Host "Assembled index.html successfully! Size: $([System.IO.FileInfo]::new($outputPath).Length) bytes."
