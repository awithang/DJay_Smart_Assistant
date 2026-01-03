# WidwaPa EA Installation & Sync Guide

This project includes a PowerShell script to automatically detect your MetaTrader 5 installation and copy the Expert Advisor and Include files to the correct MQL5 folders.

## How to Run the Installer

### Option 1: Using PowerShell (Recommended)
1. Open a terminal or command prompt in the project root directory.
2. Run the following command:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File scripts/install_ea.ps1
   ```
3. The script will:
   - Auto-detect your MT5 Data Folder.
   - Create the necessary `EA_Helper` directories if they don't exist.
   - Copy all `.mq5` and `.mqh` files.
   - Ask if you want to open MetaEditor.

### Option 2: Using the Batch File
If you prefer a simple double-click:
1. Navigate to the `scripts/` folder.
2. Double-click `install_ea.bat`.

---

## Manual Compilation (After Sync)
Once the files are copied, you must compile the EA in MetaTrader 5:
1. Open **MetaTrader 5**.
2. Press `F4` to open **MetaEditor**.
3. In the Navigator (left side), go to `Experts` -> `EA_Helper`.
4. Double-click `WidwaPa_Assistant.mq5`.
5. Press `F7` to **Compile**.
6. Check the "Errors" tab at the bottom to ensure it says `0 errors, 0 warnings`.

## Troubleshooting
If the script cannot find your MT5 folder automatically, you can provide the path manually:
```powershell
.\scripts\install_ea.ps1 -Mt5Path "C:\Your\Custom\Path\Terminal\MQL5"
```
