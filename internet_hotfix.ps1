# ========================================
# Script Block Internet untuk Semua EXE
# ========================================
# Requires Administrator Privileges

#Requires -RunAsAdministrator

# Set console colors
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# Function untuk print dengan warna
function Write-ColorLog {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    switch ($Type) {
        "SUCCESS" { 
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "[SUCCESS] " -NoNewline -ForegroundColor Green
            Write-Host $Message -ForegroundColor White
        }
        "ERROR" { 
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "[ERROR] " -NoNewline -ForegroundColor Red
            Write-Host $Message -ForegroundColor White
        }
        "WARNING" { 
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "[WARNING] " -NoNewline -ForegroundColor Yellow
            Write-Host $Message -ForegroundColor White
        }
        "INFO" { 
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "[INFO] " -NoNewline -ForegroundColor Cyan
            Write-Host $Message -ForegroundColor White
        }
        "HEADER" {
            Write-Host ""
            Write-Host "================================================" -ForegroundColor Magenta
            Write-Host "  $Message" -ForegroundColor Magenta
            Write-Host "================================================" -ForegroundColor Magenta
            Write-Host ""
        }
    }
}

# Header
Write-ColorLog -Message "BLOCK INTERNET - EXE SCANNER" -Type "HEADER"

# Cek Administrator
Write-ColorLog -Message "Checking administrator privileges..." -Type "INFO"
try {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-ColorLog -Message "Script must be run as Administrator!" -Type "ERROR"
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-ColorLog -Message "Administrator privileges confirmed" -Type "SUCCESS"
} catch {
    Write-ColorLog -Message "Failed to check admin privileges: $($_.Exception.Message)" -Type "ERROR"
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "  Enter the folder path OR file path" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Examples:" -ForegroundColor Gray
Write-Host "  Folder: C:\Program Files\MyGame" -ForegroundColor Gray
Write-Host "  Folder: D:\Steam\steamapps\common\GameName" -ForegroundColor Gray
Write-Host "  File  : C:\Games\Game.exe" -ForegroundColor Gray
Write-Host ""

# Input folder/file path
do {
    $inputPath = Read-Host "Path"
    
    # Remove quotes if present
    $inputPath = $inputPath.Trim('"').Trim("'")
    
    if ([string]::IsNullOrWhiteSpace($inputPath)) {
        Write-ColorLog -Message "Path cannot be empty!" -Type "ERROR"
        continue
    }
    
    # Check if it's a file
    if (Test-Path -Path $inputPath -PathType Leaf) {
        # It's a file
        if ($inputPath -notlike "*.exe") {
            Write-ColorLog -Message "File is not an .exe file!" -Type "ERROR"
            Write-Host ""
            $retry = Read-Host "Try again? (Y/N)"
            if ($retry -ne "Y" -and $retry -ne "y") {
                Write-ColorLog -Message "Operation cancelled by user" -Type "WARNING"
                Read-Host "Press Enter to exit"
                exit 0
            }
            continue
        }
        $isFile = $true
        $targetPath = $inputPath
        break
    }
    # Check if it's a folder
    elseif (Test-Path -Path $inputPath -PathType Container) {
        $isFile = $false
        $targetPath = $inputPath
        break
    }
    else {
        Write-ColorLog -Message "Path not found: $inputPath" -Type "ERROR"
        Write-Host ""
        $retry = Read-Host "Try again? (Y/N)"
        if ($retry -ne "Y" -and $retry -ne "y") {
            Write-ColorLog -Message "Operation cancelled by user" -Type "WARNING"
            Read-Host "Press Enter to exit"
            exit 0
        }
        continue
    }
} while ($true)

Write-Host ""

# Handle file or folder
if ($isFile) {
    Write-ColorLog -Message "File mode: Processing single file" -Type "INFO"
    Write-ColorLog -Message "File: $targetPath" -Type "INFO"
    Write-Host ""
    
    $exeFiles = @(Get-Item -Path $targetPath)
    
} else {
    Write-ColorLog -Message "Folder mode: Scanning for .exe files" -Type "INFO"
    Write-ColorLog -Message "Folder: $targetPath" -Type "INFO"
    Write-ColorLog -Message "Searching for all .exe files (including subfolders)..." -Type "INFO"
    Write-Host ""
    
    # Scan untuk semua file .exe
    try {
        $exeFiles = Get-ChildItem -Path $targetPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        
        if ($exeFiles.Count -eq 0) {
            Write-ColorLog -Message "No .exe files found in the specified folder" -Type "WARNING"
            Write-Host ""
            Read-Host "Press Enter to exit"
            exit 0
        }
        
    } catch {
        Write-ColorLog -Message "Error scanning folder: $($_.Exception.Message)" -Type "ERROR"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-ColorLog -Message "Found $($exeFiles.Count) executable file(s)" -Type "SUCCESS"
Write-Host ""

# Tampilkan daftar file yang ditemukan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Files to be blocked:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$index = 1
foreach ($exe in $exeFiles) {
    Write-Host "  [$index] " -NoNewline -ForegroundColor Yellow
    Write-Host "$($exe.Name)" -NoNewline -ForegroundColor White
    Write-Host " ($([math]::Round($exe.Length / 1MB, 2)) MB)" -ForegroundColor Gray
    Write-Host "      $($exe.DirectoryName)" -ForegroundColor DarkGray
    $index++
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Konfirmasi
Write-Host "Do you want to BLOCK internet access for all these files? (Y/N): " -NoNewline -ForegroundColor Yellow
$confirmation = Read-Host

if ($confirmation -ne "Y" -and $confirmation -ne "y") {
    Write-ColorLog -Message "Operation cancelled by user" -Type "WARNING"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 0
}

Write-Host ""
Write-ColorLog -Message "Starting blocking process..." -Type "INFO"
Write-Host ""

# Counter untuk statistik
$successCount = 0
$failCount = 0
$skippedCount = 0

# Process setiap file
foreach ($exe in $exeFiles) {
    $exePath = $exe.FullName
    $exeName = $exe.Name
    $ruleName = "Block Internet - $exeName"
    
    Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    Write-ColorLog -Message "Processing: $exeName" -Type "INFO"
    
    try {
        # Hapus rule lama jika ada
        $existingRuleOut = Get-NetFirewallRule -DisplayName "$ruleName - Outbound" -ErrorAction SilentlyContinue
        $existingRuleIn = Get-NetFirewallRule -DisplayName "$ruleName - Inbound" -ErrorAction SilentlyContinue
        
        if ($existingRuleOut -or $existingRuleIn) {
            Write-ColorLog -Message "Removing existing rules..." -Type "INFO"
            if ($existingRuleOut) { Remove-NetFirewallRule -DisplayName "$ruleName - Outbound" -ErrorAction SilentlyContinue }
            if ($existingRuleIn) { Remove-NetFirewallRule -DisplayName "$ruleName - Inbound" -ErrorAction SilentlyContinue }
        }
        
        # Buat rule OUTBOUND (blokir koneksi keluar)
        Write-ColorLog -Message "Creating outbound rule..." -Type "INFO"
        New-NetFirewallRule -DisplayName "$ruleName - Outbound" `
                           -Direction Outbound `
                           -Program $exePath `
                           -Action Block `
                           -Profile Any `
                           -Enabled True `
                           -Description "Block internet access for $exeName" `
                           -ErrorAction Stop | Out-Null
        
        # Buat rule INBOUND (blokir koneksi masuk)
        Write-ColorLog -Message "Creating inbound rule..." -Type "INFO"
        New-NetFirewallRule -DisplayName "$ruleName - Inbound" `
                           -Direction Inbound `
                           -Program $exePath `
                           -Action Block `
                           -Profile Any `
                           -Enabled True `
                           -Description "Block internet access for $exeName" `
                           -ErrorAction Stop | Out-Null
        
        Write-ColorLog -Message "Successfully blocked: $exeName" -Type "SUCCESS"
        $successCount++
        
    } catch {
        Write-ColorLog -Message "Failed to block $exeName - $($_.Exception.Message)" -Type "ERROR"
        $failCount++
    }
}

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor Magenta
Write-Host "  BLOCKING PROCESS COMPLETED" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "  Total files processed: " -NoNewline -ForegroundColor White
Write-Host "$($exeFiles.Count)" -ForegroundColor Cyan

Write-Host "  Successfully blocked: " -NoNewline -ForegroundColor White
Write-Host "$successCount" -ForegroundColor Green

if ($failCount -gt 0) {
    Write-Host "  Failed to block: " -NoNewline -ForegroundColor White
    Write-Host "$failCount" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""

Write-ColorLog -Message "All executable files in the folder have been blocked from internet access" -Type "SUCCESS"
Write-Host ""
Write-Host "To unblock, use the companion script 'Unblock-Internet.ps1'" -ForegroundColor Gray
Write-Host "or manually remove rules from Windows Firewall settings" -ForegroundColor Gray
Write-Host ""

Write-Host ""
Read-Host "Press Enter to exit"
