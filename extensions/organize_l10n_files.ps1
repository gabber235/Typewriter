# PowerShell script to organize localization files
# Move all l10n JSON files from src/main/ to src/main/resources/translations/

$baseDir = "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions"

$extensions = @{
    "VaultExtension" = "vault"
    "EntityExtension" = "entity"
    "BasicExtension" = "basic"
    "CitizensExtension" = "citizens"
    "QuestExtension" = "quest"
    "WorldGuardExtension" = "worldguard"
    "SuperiorSkyblockExtension" = "superiorskyblock"
    "RoadNetworkExtension" = "roadnetwork"
    "RPGRegionsExtension" = "rpgregions"
    "MythicMobsExtension" = "mythicmobs"
    "_DocsExtension" = "docs"
}

foreach ($ext in $extensions.Keys) {
    $ns = $extensions[$ext]
    $extDir = Join-Path $baseDir $ext
    $transDir = Join-Path $extDir "src\main\resources\translations"
    
    # Create directory if it doesn't exist
    if (-not (Test-Path $transDir)) {
        New-Item -ItemType Directory -Path $transDir -Force | Out-Null
        Write-Host "Created directory: $transDir"
    }
    
    # Move English file
    $enFile = Join-Path $extDir "src\main\${ns}_l10n_en.json"
    if (Test-Path $enFile) {
        Move-Item -Path $enFile -Destination (Join-Path $transDir "${ns}_l10n_en.json") -Force
        Write-Host "Moved: ${ns}_l10n_en.json"
    }
    
    # Move Russian file
    $ruFile = Join-Path $extDir "src\main\${ns}_l10n_ru.json"
    if (Test-Path $ruFile) {
        Move-Item -Path $ruFile -Destination (Join-Path $transDir "${ns}_l10n_ru.json") -Force
        Write-Host "Moved: ${ns}_l10n_ru.json"
    }
}

# Move root-level files if they exist
$rootEnFile = Join-Path $baseDir "vault_l10n_en.json"
if (Test-Path $rootEnFile) {
    $vaultTransDir = Join-Path $baseDir "VaultExtension\src\main\resources\translations"
    Move-Item -Path $rootEnFile -Destination (Join-Path $vaultTransDir "vault_l10n_en.json") -Force
    Write-Host "Moved: vault_l10n_en.json (from root)"
}

$rootRuFile = Join-Path $baseDir "vault_l10n_ru.json"
if (Test-Path $rootRuFile) {
    $vaultTransDir = Join-Path $baseDir "VaultExtension\src\main\resources\translations"
    Move-Item -Path $rootRuFile -Destination (Join-Path $vaultTransDir "vault_l10n_ru.json") -Force
    Write-Host "Moved: vault_l10n_ru.json (from root)"
}

Write-Host "`n✓ All localization files organized!"
