#!/bin/bash
# ==========================================
# WidwaPa EA Installer - Shell Script
# For Git Bash / WSL / Linux
# ==========================================

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${CYAN}========================================="
echo -e "${CYAN}WidwaPa EA Installer${RESET}"
echo -e "${CYAN}=========================================${RESET}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source paths
SOURCE_EXPERTS="$PROJECT_ROOT/MQL5/Experts/EA_Helper"
SOURCE_INCLUDE="$PROJECT_ROOT/MQL5/Include/EA_Helper"

echo -e "${CYAN}Project Root: $PROJECT_ROOT${RESET}"
echo ""

# Detect MT5 folder (Windows paths for WSL/Git Bash)
echo -e "${CYAN}Detecting MetaTrader 5 installation...${RESET}"

# Try common Windows MT5 paths via WSL
if [[ -n "$WSL_DISTRO_NAME" ]] || grep -qi microsoft /proc/version; then
    # Running in WSL
    APPDATA=$(/mnt/c/Windows/System32/cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')
    LOCALAPPDATA=$(/mnt/c/Windows/System32/cmd.exe /c "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r')

    # Convert Windows path to WSL path
    APPDATA=$(wslpath "$APPDATA" 2>/dev/null || echo "$APPDATA")
    LOCALAPPDATA=$(wslpath "$LOCALAPPDATA" 2>/dev/null || echo "$LOCALAPPDATA")
fi

# Search for MT5 folder
MT5_PATH=""
for search_path in \
    "$APPDATA/MetaQuotes/Terminat"*/MQL5" \
    "$LOCALAPPDATA/MetaQuotes/Terminat"*/MQL5" \
    "/mnt/c/Program Files/MetaTrader 5/MQL5" \
    "/mnt/c/Program Files (x86)/MetaTrader 5/MQL5"
do
    # Expand wildcards
    for match in $search_path; do
        if [[ -d "$match" ]]; then
            MT5_PATH="$match"
            break 2
        fi
    done
done

if [[ -z "$MT5_PATH" ]]; then
    echo -e "${YELLOW}Could not auto-detect MT5 folder.${RESET}"
    echo -e "${YELLOW}Please enter MT5 MQL5 path:${RESET}"
    echo ""
    echo -n "MT5 MQL5 Path: "
    read -r MT5_PATH

    # Convert to WSL path if Windows path given
    if [[ "$MT5_PATH" =~ ^[A-Za-z]: ]]; then
        MT5_PATH=$(wslpath "$MT5_PATH" 2>/dev/null || echo "$MT5_PATH")
    fi

    if [[ ! -d "$MT5_PATH" ]]; then
        echo -e "${RED}Error: Path does not exist: $MT5_PATH${RESET}"
        exit 1
    fi
else
    echo -e "${GREEN}Found MT5 folder: $MT5_PATH${RESET}"
fi

# Destination paths
DEST_EXPERTS="$MT5_PATH/Experts/EA_Helper"
DEST_INCLUDE="$MT5_PATH/Include/EA_Helper"

# Create directories
echo ""
echo -e "${CYAN}Creating target directories...${RESET}"
mkdir -p "$DEST_EXPERTS"
mkdir -p "$DEST_INCLUDE"

# Copy Expert files
echo ""
echo -e "${CYAN}Copying Expert Advisor files...${RESET}"
cp -v "$SOURCE_EXPERTS"/*.mq5 "$DEST_EXPERTS/"

# Copy Include files
echo ""
echo -e "${CYAN}Copying Include files...${RESET}"
cp -v "$SOURCE_INCLUDE"/*.mqh "$DEST_INCLUDE/"

# Summary
echo ""
echo -e "${GREEN}========================================="
echo -e "${GREEN}Installation Complete!${RESET}"
echo -e "${GREEN}=========================================${RESET}"
echo ""
echo -e "${CYAN}Files copied to:${RESET}"
echo "  Experts:  $DEST_EXPERTS"
echo "  Include:  $DEST_INCLUDE"
echo ""
echo -e "${CYAN}Next Steps:${RESET}"
echo "  1. Open MetaTrader 5"
echo "  2. Press F4 (MetaEditor)"
echo "  3. Navigate to Experts → EA_Helper → WidwaPa_Assistant.mq5"
echo "  4. Press F7 to Compile"
echo "  5. Press Ctrl+R to open Strategy Tester"
echo "  6. Select WidwaPa_Assistant, XAUUSD, H1 timeframe"
echo "  7. Check 'Visual Mode' and click Start"
echo ""

# Offer to open MetaEditor
read -p "Open MetaEditor now? (Y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    MT5_ROOT="$(dirname "$MT5_PATH")"
    if [[ -f "$MT5_ROOT/metaeditor64.exe" ]]; then
        powershell.exe -Command "Start-Process '$(wslpath -w '$MT5_ROOT')\\metaeditor64.exe'" 2>/dev/null
        echo -e "${GREEN}MetaEditor opened!${RESET}"
    elif [[ -f "$MT5_ROOT/metaeditor.exe" ]]; then
        powershell.exe -Command "Start-Process '$(wslpath -w '$MT5_ROOT')\\metaeditor.exe'" 2>/dev/null
        echo -e "${GREEN}MetaEditor opened!${RESET}"
    else
        echo -e "${YELLOW}Could not find MetaEditor executable${RESET}"
    fi
fi
