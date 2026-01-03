# UI Refinement Plan (v8)

## 1. Vertical Compression (Upper Half)
**Request:** "Move Auto strategy... Settings... and Strategy Signal up a bit to make more space."
**Issue:** There is extra padding below the Buy/Sell buttons (red square in `issue1.png`).
**Action:**
*   Reduce the gap after `BtnBuy`/`BtnSell` from `right_y += 50` to `right_y += 40`.
*   Reduce the gap after the new 2nd Section (was Auto, now Settings) before the 3rd Section.

## 2. Section Reordering
**Request:** "Settings section should be above auto strategy section."
**New Order (Top -> Bottom):**
1.  **Manual Execution** (Buy/Sell) - *Already at top*
2.  **Settings** (RR, Risk, Profit Lock) - *Move UP*
3.  **Auto Strategy** (Mode, Buttons) - *Move DOWN*
4.  **Strategy Signal** - *Flows after Auto*
5.  **Footer** (Pending + Active) - *Fixed at bottom*

## 3. Implementation Logic (DashboardPanel.mqh)

### Step-by-Step Layout Reconstruction:
1.  **Start:** `right_y = 15`.
2.  **Section 1: Execution**
    *   Draw Header + Buy/Sell (30px height).
    *   Advance `right_y += 40` (Tighter gap).
3.  **Section 2: Settings (Swapped)**
    *   Draw Header "SETTINGS".
    *   Draw BG + Controls.
    *   Height ~160px.
    *   Advance `right_y += 165`.
4.  **Section 3: Auto Strategy (Swapped)**
    *   Draw Header "AUTO STRATEGY".
    *   Draw BG + Controls.
    *   Height ~80px.
    *   Advance `right_y += 85`.
5.  **Section 4: Strategy Signal**
    *   Draw Header.
    *   Draw BG + Details.
    *   Advance `right_y`.
    *   **Result:** This pushes the bottom of the content UP, increasing the whitespace before the fixed footer.

## 4. Verification
- [ ] Gap below Buy/Sell reduced.
- [ ] Settings is now immediately below Buy/Sell.
- [ ] Auto Strategy is below Settings.
- [ ] More empty space between Strategy Signal and Pending Alerts.
