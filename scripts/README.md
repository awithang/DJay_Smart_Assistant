# WidwaPa EA Installer Scripts

Helper scripts to automatically copy WidwaPa Assistant EA files to MetaTrader 5.

## Available Installers

### Windows (Recommended)
```powershell
# PowerShell
.\scripts\install_ea.ps1

# Command Prompt / Batch
.\scripts\install_ea.bat
```

### Git Bash / WSL
```bash
# Make executable first
chmod +x scripts/install_ea.sh

# Run installer
./scripts/install_ea.sh
```

## What These Scripts Do

1. **Auto-detect** your MetaTrader 5 installation folder
2. **Create** the required `EA_Helper` folders
3. **Copy** all EA files to the correct locations:
   - Experts → `MQL5/Experts/EA_Helper/`
   - Include → `MQL5/Include/EA_Helper/`

## Features

- ✅ Automatic MT5 folder detection
- ✅ Creates directories if needed
- ✅ Preserves existing files (use -Force to overwrite)
- ✅ Color-coded output
- ✅ Option to open MetaEditor after installation

## Manual Installation (If Scripts Fail)

1. Find your MT5 data folder:
   - Open MT5 → File → Open Data Folder
   - Navigate to `MQL5\`

2. Create folders:
   ```
   MQL5\
   ├── Experts\
   │   └── EA_Helper\
   └── Include\
       └── EA_Helper\
   ```

3. Copy files:
   ```
   From: MQL5\Experts\EA_Helper\*.mq5
   To:   <MT5>\MQL5\Experts\EA_Helper\

   From: MQL5\Include\EA_Helper\*.mqh
   To:   <MT5>\MQL5\Include\EA_Helper\
   ```

## After Installation

1. **Compile the EA:**
   - Open MetaTrader 5
   - Press **F4** (MetaEditor)
   - File → Open → `Experts/EA_Helper/WidwaPa_Assistant.mq5`
   - Press **F7** (Compile)
   - Check for errors

2. **Test in Strategy Tester:**
   - Press **Ctrl+R** (Strategy Tester)
   - Expert: `WidwaPa_Assistant`
   - Symbol: `XAUUSD`
   - Model: `Every tick` or `Open prices`
   - Timeframe: `H1`
   - Check: ✅ **Visual mode**
   - Click **Start**

## Troubleshooting

### Script won't run
**PowerShell:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Batch:** Right-click → Run as Administrator

### "Cannot find MT5 folder"
Specify path manually:
```powershell
.\scripts\install_ea.ps1 -Mt5Path "C:\Users\YourName\AppData\MetaQuotes\Terminal\...\MQL5"
```

### "Access Denied"
Run as Administrator or check folder permissions.

## File Structure After Installation

```
<MQL5_Data_Folder>\
├── Experts\
│   └── EA_Helper\
│       └── WidwaPa_Assistant.mq5        ← Main EA (compile this)
└── Include\
    └── EA_Helper\
        ├── Definitions.mqh              ← Enums & constants
        ├── SignalEngine.mqh             ← Signal detection
        ├── TradeManager.mqh             ← Trade execution
        └── DashboardPanel.mqh           ← UI Panel
```

## Compilation Checklist

- [ ] MetaEditor opens without errors
- [ ] `WidwaPa_Assistant.mq5` is loaded
- [ ] Press **F7** → `0 error(s), 0 warning(s)`
- [ ] EA appears in Navigator → Expert Advisors
- [ ] Ready for Strategy Tester testing

## Testing Parameters (Recommended)

| Setting | Value |
|---------|-------|
| Expert | WidwaPa_Assistant |
| Symbol | XAUUSD (Gold) |
| Timeframe | H1 |
| Model | Every tick |
| Date | Last 3 months |
| Visual Mode | ✅ Enabled |
| Speed | Maximum (fastest) |

---

**Issues?** Check the main project README or review the EA source code comments.
