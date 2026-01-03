# UI Refinement Plan (v4)
**Objective:** Fine-tune alignment, spacing, and labels to achieve a polished, professional look.

## 1. Label Updates
*   **Header:** Change "SETTING" -> "SETTINGS".
*   **Profit Lock Label:** Change "Lock Settings (pts):" -> "Profit Lock Settings".
    *   **Color:** Change from `m_header_color` (Blue) to `clrGray` (same as RR/Risk labels).

## 2. Alignment & Spacing (Right Panel)
**Goal:** Consistent Right Alignment.
*   **RR Buttons:**
    *   Currently: Left-aligned relative to the section.
    *   **Fix:** Calculate `rr_total_width` and position `start_x = (right_x + half_width - pad) - rr_total_width`.
    *   **Spacing:** Ensure standard gap between "1:1", "1:1.5", "1:2".
*   **Profit Lock Inputs:**
    *   **Label Gap:** Increase space between "Profit Lock Settings" label and the input row (`right_y += 20` instead of `15`).
    *   **Input Alignment:** Right-align the entire group (Trig/Lock/Step) to match the RR buttons and Toggles.
    *   **Option Spacing:** Increase gap between Trig/Lock/Step pairs (e.g., `plGap = 10` or `15`).

## 3. Section Positioning (Vertical Layout)
**Goal:** Fix overlaps and optimize vertical space.
*   **Strategy Signal:**
    *   **Issue:** "Details not in their section area."
    *   **Fix:** Increase the Y-offset for the labels inside the `InfoBG` rectangle or move the `InfoBG` rectangle up/expand it.
*   **Active Orders (Bottom Anchor):**
    *   **Goal:** "Align at bottom of panel."
    *   **Fix:** Instead of a dynamic `current_y` calculation from the top, define `ActiveOrders_Y = m_panel_height - 130` (fixed distance from bottom).
*   **Pending Alerts:**
    *   **Goal:** Move down to match Active Orders.
    *   **Fix:** Position `PendingAlerts_Y` relative to `ActiveOrders_Y` (e.g., `ActiveOrders_Y - 80`).

## 4. Implementation Steps (DashboardPanel.mqh)

### A. Settings Section (Refined)
1.  **Header:** "SETTINGS".
2.  **RR Buttons:** Calculate positions to align the *rightmost* button edge with `right_x + half_width - pad`.
3.  **Profit Lock Label:** `clrGray`, add extra Y padding below it.
4.  **Profit Lock Inputs:**
    *   Calculate total width of the 3 pairs.
    *   Start X = `(right_x + half_width - pad) - total_width`.
    *   Increase `plGap`.

### B. Vertical Flow Adjustment
1.  **Strategy Signal:**
    *   Verify `right_y` before creating `InfoBG`.
    *   Ensure `Trend_T`, `PA_T`, `Adv_T` Y-coordinates are `right_y + offset`.
2.  **Bottom Sections (Fixed Anchor):**
    *   **Active Orders:** `y = m_panel_height - 120`.
    *   **Pending Alerts:** `y = m_panel_height - 200` (or appropriate gap above Active Orders).
    *   **Note:** This ensures that no matter how much the top sections expand, the bottom stays anchored (like a footer).

## 5. Verification
- [ ] "SETTINGS" label correct.
- [ ] RR buttons right-aligned.
- [ ] Profit Lock inputs right-aligned & spaced.
- [ ] Strategy Signal text fits inside its box.
- [ ] Active Orders anchored to bottom.
