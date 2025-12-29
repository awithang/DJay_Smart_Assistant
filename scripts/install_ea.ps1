#!/usr/bin/env pwsh
<#
.SYNOPSIS
    WidwaPa EA Installer - Copy EA files to MetaTrader 5

.DESCRIPTION
    Automatically copies WidwaPa Assistant Expert Advisor files to
    MetaTrader 5 MQL5 folder for compilation and testing.

.NOTES
    Author: EA Helper Project
    Version: 1.0
#>

#Requires -Version 5.1

param(
    [string]$Mt5Path = "",
    [switch]$VerboseOutput = $false
)

# Color output helpers
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green @args }
function Write-Info { Write-ColorOutput Cyan @args }
function Write-Warning { Write-ColorOutput Yellow @args }
function Write-Error { Write-ColorOutput Red @args }

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Source paths
$SourceExperts = Join-Path $ProjectRoot "MQL5\Experts\EA_Helper"
$SourceInclude = Join-Path $ProjectRoot "MQL5\Include\EA_Helper"

Write-Info "========================================="
Write-Info "WidwaPa EA Installer"
Write-Info "========================================="
Write-Output ""

# Detect MT5 data folder
if ([string]::IsNullOrEmpty($Mt5Path)) {
    Write-Info "Detecting MetaTrader 5 installation..."

    # Common MT5 data folder locations
    $AppData = [Environment]::GetFolderPath("ApplicationData")
    $PossiblePaths = @(
        Join-Path $AppData "MetaQuotes\Terminal\*\MQL5",
        "$env:LOCALAPPDATA\MetaQuotes\Terminal\*\MQL5",
        "C:\Program Files\MetaTrader 5\MQL5",
        "${env:ProgramFiles(x86)}\MetaTrader 5\MQL5",
        "C:\Program Files*\*MetaTrader*\MQL5"
    )

    $Mt5Path = $null
    foreach ($Pattern in $PossiblePaths) {
        $Matches = Resolve-Path $Pattern -ErrorAction SilentlyContinue
        if ($Matches) {
            $Mt5Path = $Matches[0].Path
            break
        }
    }

    if (-not $Mt5Path) {
        Write-Error "Could not auto-detect MT5 folder."
        Write-Warning "Please specify MT5 path manually:"
        Write-Output "  .\scripts\install_ea.ps1 -Mt5Path `"C:\Path\To\MT5\MQL5`"`n"
        exit 1
    }

    Write-Success "Found MT5 folder: $Mt5Path"
} else {
    Write-Info "Using specified MT5 path: $Mt5Path"
}

# Validate MT5 path
if (-not (Test-Path $Mt5Path)) {
    Write-Error "MT5 path does not exist: $Mt5Path"
    exit 1
}

# Destination paths
$DestExperts = Join-Path $Mt5Path "Experts\EA_Helper"
$DestInclude = Join-Path $Mt5Path "Include\EA_Helper"

# Create directories if they don't exist
Write-Output ""
Write-Info "Creating target directories..."
New-Item -ItemType Directory -Force -Path $DestExperts | Out-Null
New-Item -ItemType Directory -Force -Path $DestInclude | Out-Null

# Copy Expert files
Write-Output ""
Write-Info "Copying Expert Advisor files..."
$ExpertFiles = Get-ChildItem -Path $SourceExperts -Filter "*.mq5"
foreach ($File in $ExpertFiles) {
    $DestFile = Join-Path $DestExperts $File.Name
    Copy-Item -Path $File.FullName -Destination $DestFile -Force
    Write-Output "  $($File.Name) → EA_Helper\"
}

# Copy Include files
Write-Output ""
Write-Info "Copying Include files..."
$IncludeFiles = Get-ChildItem -Path $SourceInclude -Filter "*.mqh"
foreach ($File in $IncludeFiles) {
    $DestFile = Join-Path $DestInclude $File.Name
    Copy-Item -Path $File.FullName -Destination $DestFile -Force
    Write-Output "  $($File.Name) → Include\EA_Helper\"
}

# Summary
Write-Output ""
Write-Success "========================================="
Write-Success "Installation Complete!"
Write-Success "========================================="
Write-Output ""
Write-Info "Files copied to:"
Write-Output "  Experts:  $DestExperts"
Write-Output "  Include:  $DestInclude"
Write-Output ""
Write-Info "Next Steps:"
Write-Output "  1. Open MetaTrader 5"
Write-Output "  2. Press F4 (MetaEditor)"
Write-Output "  3. Navigate to Experts → EA_Helper → WidwaPa_Assistant.mq5"
Write-Output "  4. Press F7 to Compile"
Write-Output "  5. Press Ctrl+R to open Strategy Tester"
Write-Output "  6. Select WidwaPa_Assistant, XAUUSD, H1 timeframe"
Write-Output "  7. Check 'Visual Mode' and click Start"
Write-Output ""

# Offer to open MetaEditor
$Response = Read-Host "Open MetaEditor now? (Y/N)"
if ($Response -eq "Y" -or $Response -eq "y") {
    $MetaEditorExe = Join-Path (Split-Path -Parent $Mt5Path) "metaeditor64.exe"
    if (Test-Path $MetaEditorExe) {
        Start-Process $MetaEditorExe
        Write-Success "MetaEditor opened!"
    } else {
        Write-Warning "Could not find MetaEditor executable"
    }
}
