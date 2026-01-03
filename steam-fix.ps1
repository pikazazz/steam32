#Requires -Version 5.1
# Steam 32-bit Downgrader

Clear-Host
Write-Host "Steam 32-bit Downgrader" -ForegroundColor Cyan
Write-Host ""

# Get Steam path from registry
function Get-SteamPath {
    $paths = @(
        "HKCU:\Software\Valve\Steam",
        "HKLM:\Software\Valve\Steam",
        "HKLM:\Software\WOW6432Node\Valve\Steam"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $steam = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            $steamPath = if ($steam.SteamPath) { $steam.SteamPath } else { $steam.InstallPath }
            if ($steamPath -and (Test-Path $steamPath)) {
                return $steamPath
            }
        }
    }
    return $null
}

# Find Steam
Write-Host "[1/4] Finding Steam..." -ForegroundColor Yellow
$steamPath = Get-SteamPath

if (-not $steamPath) {
    Write-Host "ERROR: Steam not found" -ForegroundColor Red
    exit 1
}

Write-Host "Found: $steamPath" -ForegroundColor Green
Write-Host ""

# Stop Steam
Write-Host "[2/4] Stopping Steam..." -ForegroundColor Yellow
Get-Process -Name "steam*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "Done" -ForegroundColor Green
Write-Host ""

# Download and extract
Write-Host "[3/4] Downloading Steam x32..." -ForegroundColor Yellow
$url = "https://github.com/madoiscool/lt_api_links/releases/download/unsteam/latest32bitsteam.zip"
$zipFile = "$env:TEMP\steam32.zip"

try {
    Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
    Expand-Archive -Path $zipFile -DestinationPath $steamPath -Force
    Remove-Item $zipFile -Force
    Write-Host "Done" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Download failed - $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Create config
Write-Host "[4/4] Creating config..." -ForegroundColor Yellow
$cfg = "BootStrapperInhibitAll=enable`nBootStrapperForceSelfUpdate=disable"
Set-Content -Path "$steamPath\steam.cfg" -Value $cfg -Force
Write-Host "Done" -ForegroundColor Green
Write-Host ""

# Launch Steam
Write-Host "Launching Steam..." -ForegroundColor Cyan
Start-Process -FilePath "$steamPath\Steam.exe" -ArgumentList "-clearbeta"

Write-Host ""
Write-Host "Complete!" -ForegroundColor Green