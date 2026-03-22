$source = Join-Path $PSScriptRoot "CharacterExporter"
$destination = Join-Path [Environment]::GetFolderPath("MyDocuments") "Elder Scrolls Online\live\AddOns\CharacterExporter"

Write-Host "Aggiornamento addon CharacterExporter..."

If (!(Test-Path $destination)) {
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
}

Copy-Item -Path "$source\*" -Destination $destination -Recurse -Force

Write-Host "Addon installato/aggiornato con successo in:" -ForegroundColor White
Write-Host $destination -ForegroundColor Cyan
