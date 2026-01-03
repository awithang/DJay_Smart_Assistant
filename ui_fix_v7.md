# UI Optimization & Lag Fix Plan (v7.2 - Final)

## 1. Layout Adjustment (Space Saving)
**Goal:** Clear the overlap between "Strategy Signal" and "Pending Alerts" by compacting the top section.
*   **Action:** Reduce **Manual Buy/Sell Button Height** from `38px` to **30px**.
*   **File:** `DashboardPanel.mqh` (inside `CreatePanel`).

## 2. Performance Fix (Eliminating Lag)
**Diagnosis:** The "lag" is caused by a conflict between the terminal's native "button pressed" animation and our code's manual color update. The terminal keeps the button "down" while our code tries to paint it "green", causing a visual stutter.

**The Fix Pattern:**
We must strictly follow this execution order in `OnEvent` for every button (RR, Trailing):

1.  **IMMEDIATE Unpress:** `ObjectSetInteger(..., OBJPROP_STATE, false);`
    *   *Why:* Instantly resets the button to its "up" state, cancelling the native animation conflict.
2.  **Logic Update:** `m_current_rr = ...;`
3.  **Visual Update:** `UpdateRRButtonsVisuals();`
    *   *Why:* Applies the new background colors to the buttons.
4.  **Force Redraw:** `ChartRedraw(m_chart_id);`
    *   *Why:* Forces the terminal to paint the new colors *now*, in this frame.
5.  **Save State:** `SaveSettings();`
    *   *Why:* Persist the change (fast, <1ms) *after* the user has seen the visual feedback.
6.  **Return:** `return;` (Exit immediately).

## 3. Implementation Checklist

### A. DashboardPanel.mqh - Layout
- [ ] Locate `CreateButton("BtnBuy", ...)` and `CreateButton("BtnSell", ...)`.
- [ ] Change height parameter from `38` to `30`.

### B. DashboardPanel.mqh - OnEvent Optimization
- [ ] Refactor `BtnRR1` block: Insert `ObjectSetInteger(..., OBJPROP_STATE, false)` at the top. Add `ChartRedraw()`.
- [ ] Refactor `BtnRR15` block: Same pattern.
- [ ] Refactor `BtnRR2` block: Same pattern.
- [ ] Refactor `BtnTrailToggle` block: Same pattern.

## 4. Verification
- [ ] **Visual:** Buy/Sell buttons are visibly shorter (30px).
- [ ] **Feel:** Clicking "Profit Lock" or "RR" buttons feels "snappy" and instant, identical to the Auto Strategy buttons.
- [ ] **Function:** Settings are still saved and restored correctly.