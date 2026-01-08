# Implementation Plan: UI Feature Restoration (The Cockpit Upgrade)

**Date:** 2026-01-07
**Objective:** Align the actual dashboard code with the approved `ui_mockup.md`. Restore missing features (Smart Filters, Ghost Buttons, Matrix details) by optimizing screen real estate.

**Target:** A 650px wide "Cockpit" that gives full control and safety feedback.

---

## Phase 1: Left Panel Refinement (The Matrix Completion)
*Goal: Ensure the "Decision Grid" matches the mockup exactly.*

### 1.1 Update Grid Rows
*   **Current:** Missing specific "Action" and "Spread" fields.
*   **New Layout (Left Panel):**
    *   **Header:** Add "Status: RUN TIME | Vol: HIGH" (Safety Alert).
    *   **Row 1 (Bias):** Keep Traffic Light. Add explicit "Bias: BULLISH" text.
    *   **Row 2-4 (Trend):** Keep H4/H1/M15 Arrows.
    *   **Row 5 (Action):** **NEW.** Display "Action: WAIT" (Red) or "Action: READY" (Green) based on M15 alignment.
    *   **Row 6 (Space):** **NEW.** Display "Space: +400 pts" (Distance to next resistance).

---

## Phase 2: Right Panel Overhaul (Smart Filters)
*Goal: Make room for "Filter Switches" by condensing the Settings area.*

### 2.1 Compact Settings (Space Saving)
*   **RR Ratio:** Move to a compact single line `[1:1] [1:1.5] [1:2]`.
*   **Risk %:** Small input box next to RR.
*   **Profit Lock:** Single small toggle button `[PL: ON]`. Hidden details (Trigger/Step) unless clicked (or moved to a separate "Settings" popup logic).
*   *Result:* Saves ~100px of vertical height.

### 2.2 Implement Smart Filters (The Missing Features)
*   **New Section:** "SMART FILTERS" (Below Execution, Above Auto Strategy).
*   **Toggles:**
    *   `[x] Trend Filter`: If ON, blocks counter-trend trades.
    *   `[x] Zone Filter`: If ON, blocks trades in "Middle Zone".
    *   `[ ] Aggressive`: If ON, ignores filters.

---

## Phase 3: Visual Logic (Ghost Buttons & Safety)
*Goal: Visual feedback when trading is unsafe.*

### 3.1 Ghost Button Logic
*   **Function:** `UpdateExecutionButtons(bool safeToBuy, bool safeToSell)`
*   **Logic:**
    *   If `Slope == CRASH` or `Trend Filter == ON && Trend == DOWN`:
        *   **BUY Button:** Turn Color to `clrGray`. Disable click.
    *   If `Slope == RALLY` or `Trend Filter == ON && Trend == UP`:
        *   **SELL Button:** Turn Color to `clrGray`. Disable click.

### 3.2 Visual Safety Indicators
*   **Panel Flash:** Add a border color change (Red) when `ATR > Limit` (High Volatility).

---

## Phase 4: Auto Strategy & Status
*Goal: Clean up the bottom section.*

### 4.1 Auto Strategy Section
*   **Design:** Match Mockup.
*   **Status Dot:** Add the colored dot (🟢/🔴) next to "Quick Scalp" to show if filters are passing.

---

## Phase 5: High-Performance Engineering (Optimization)
*Goal: Reduce CPU usage to near-zero.*

### 5.1 Event-Driven Architecture
*   **Remove Heavy Logic from OnTimer:** Stop calculating ATR/Trends every second.
*   **OnNewCandle (M15):** Recalculate Trend Matrix, ATR, Market State. (Runs once every 15 mins).
*   **OnTick:** Only update Price and check Signal Triggers.
*   **OnChartEvent:** Update UI only when buttons are clicked.

### 5.2 Smart Redraw
*   **Dirty Flag Pattern:**
    *   `if (!g_ui_dirty) return;`
    *   Only call `dashboardPanel.Update()` when data *actually* changes.
*   **Text Caching:**
    *   Check `ObjectGetString` before `ObjectSetString`. If text is same, do NOT call Set (MetaTrader object calls are expensive).

---

## Execution Steps (For Tomorrow)
1.  **Refactor `CreatePanel`:** Move "Right Panel" elements to create the "Filter Gap".
2.  **Add Objects:** Create the Checkbox/Toggle buttons for Filters.
3.  **Update Logic:** Connect `OnTick` to `UpdateExecutionButtons` to trigger the Ghost effect.
4.  **Optimize:** Implement "Dirty Flags" and remove redundant calculations from OnTimer.
5.  **Verify:** Check against `ui_mockup.md`.