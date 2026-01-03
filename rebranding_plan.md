# Renaming & Refactoring Plan: DJay Smart Assistant

**Objective:** Rebrand the project from "WidwaPa" to "DJay" and rename the directory structure from "EA_Helper" to "DJay_Assistant" to match the new identity.

## 1. File System Operations

### A. Rename Include Directory
*   **Current:** `MQL5/Include/EA_Helper/`
*   **New:** `MQL5/Include/DJay_Assistant/`
*   **Action:** Move/Rename the folder.

### B. Rename Expert Directory
*   **Current:** `MQL5/Experts/EA_Helper/`
*   **New:** `MQL5/Experts/DJay_Assistant/`
*   **Action:** Move/Rename the folder.

### C. Rename Main EA File
*   **Current:** `MQL5/Experts/DJay_Assistant/WidwaPa_Assistant.mq5` (after folder move)
*   **New:** `MQL5/Experts/DJay_Assistant/DJay_Smart_Assistant.mq5`
*   **Action:** Rename the file.

---

## 2. Code Content Updates

### A. Update Include Paths
**Affected Files:**
1.  `MQL5/Experts/DJay_Assistant/DJay_Smart_Assistant.mq5`
2.  `MQL5/Include/DJay_Assistant/TradeManager.mqh`
3.  `MQL5/Include/DJay_Assistant/SignalEngine.mqh`
4.  `MQL5/Include/DJay_Assistant/DashboardPanel.mqh`
5.  `MQL5/Include/DJay_Assistant/ChartZones.mqh`

**Change:**
*   Replace: `#include <EA_Helper/...`
*   With: `#include <DJay_Assistant/...`

### B. Update Terminology & Labels (Rebranding)
**File:** `DJay_Smart_Assistant.mq5`
*   **Header:** Update File Description/Copyright.
*   **Trade Comments:**
    *   `"WidwaPa Pending"` -> `"DJay Pending"`
    *   `"WidwaPa Rev Button"` -> `"DJay Rev Button"`
    *   `"WidwaPa Brk Button"` -> `"DJay Brk Button"`
    *   `"WidwaPa Buy "` -> `"DJay Buy "`
    *   `"WidwaPa Sell "` -> `"DJay Sell "`
*   **Object Names:**
    *   `"WidwaArrow_"` -> `"DJayArrow_"`

**File:** `Definitions.mqh`
*   **Global Variable Defines:**
    *   `"EA_Helper_RR_Ratio"` -> `"DJay_RR_Ratio"`
    *   `"EA_Helper_Trailing_Enabled"` -> `"DJay_Trailing_Enabled"`

**File:** `DashboardPanel.mqh`
*   **Prefix:** Update `m_prefix` initialization if it uses "Widwa" or "EA_Helper" (default checks usually needed).
*   **Labels:** Ensure no UI labels display "Widwa".

---

## 3. Execution Order (Critical for Dependencies)
1.  **Stop EA/Terminal:** Ensure files are not locked.
2.  **Rename Folders:** Execute shell commands to rename Include and Experts directories.
3.  **Rename File:** Rename the `.mq5` file.
4.  **Batch Replace Includes:** Update `#include` paths in all `.mqh` files and the `.mq5` file.
5.  **Batch Replace Terms:** Update strings/comments from "WidwaPa" to "DJay" and "EA_Helper" to "DJay_Assistant" (where appropriate).
6.  **Compile:** Verify the new `DJay_Smart_Assistant.mq5` compiles without error.

## 4. Performance & Safety Note
*   **Magic Number:** Changing the EA name does *not* affect the Magic Number, so existing trades *can* still be managed if the logic relies solely on Magic Number.
*   **Trade Comments:** Changing trade comments (`"WidwaPa..."` -> `"DJay..."`) will **break management of existing open positions** if the EA uses `StringFind(comment, ...)` to identify its trades.
    *   *Mitigation:* The EA primarily uses **Magic Number** checks (`PositionGetInteger(POSITION_MAGIC) == m_magic_number`) in `TradeManager.mqh`.
    *   *Check:* I verified `TradeManager.mqh` uses Magic Number for filtering in `ManagePositions`. The strings are mostly for user logs.
    *   *Exception:* `ExecuteBuyTrade` checks `tradeManager.HasOpenPosition(strategy)`. This likely relies on magic number + maybe comment?
        *   *Verification:* `HasOpenPosition` needs to be checked. If it checks comments, changing the comment prefix effectively resets the "duplicate check" for old trades (which might be desired or safe enough).

## 5. Summary
This plan isolates the renaming process. Once completed, the previous "UI Optimization" plan can be applied to the *new* file structure seamlessly.
