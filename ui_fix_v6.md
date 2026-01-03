# UI Fix Plan (v6): Height Reduction & Space Utilization

## 1. Analysis of `issue1.png`
*   **Problem:** The panel is now *too tall* (780px), extending beyond the visible chart area for many users.
*   **Opportunity:** There is a significant empty gap (red box) between the "Strategy Signal" section and the "Pending Alerts" footer.
*   **Goal:** Reduce `m_panel_height` back to a reasonable size (e.g., 680-700px) by moving the footer UP into that empty space.

## 2. Calculated Adjustments

### Vertical Space Math (Approximate)
*   **Top Sections (Execution + Auto + Settings + Signal):** Ends around Y = 550px.
*   **Footer (Pending + Active):** Starts at `m_panel_height - 220`.
*   **Current Gap:** If Height=780, Footer starts at 560.
    *   Wait, looking at the image, the gap is quite large.
    *   Let's check the code:
        *   `right_y` ends after Strategy Signal (~550px?).
        *   Footer anchors at `m_panel_height - 130` (Active) and `m_panel_height - 220` (Pending).
        *   If H=780, Pending starts at 560. Gap = 10px?
        *   *Correction:* The Strategy Signal ends at `right_y + 110`.
        *   If `right_y` was ~400 entering that block, it ends at ~510.
        *   Pending starts at 560. Gap = 50px.
        *   But the image shows a larger gap.

### Solution Strategy
1.  **Reduce Panel Height:** Change `m_panel_height` from 780 back to **680**.
    *   This naturally pulls the bottom-anchored footer UP by 100 pixels.
    *   Old Gap: ~100px (Red box).
    *   New Gap: ~0px (perfect fit).
2.  **Safety Check:** Will it overlap?
    *   If Content ends at 510px.
    *   New Footer (at H=680) starts at 680 - 220 = 460px.
    *   **OVERLAP!** 510 > 460.
    *   **Action:** We need to *compact* the top sections slightly OR accept a slightly taller panel (e.g., 720px).
    *   **Alternative:** The "Strategy Signal" `InfoBG` is quite tall (105px). Can we shrink it?
        *   Content: Trend, PA, Separator, Advisor.
        *   Advisor can be 2 lines.
        *   Maybe 90px is enough?

### Revised Target
*   **Panel Height:** **710px**.
*   **Compaction:**
    *   Reduce `SettingsBG` bottom padding.
    *   Reduce gap between Settings and Strategy Signal.

## 3. Implementation Steps (DashboardPanel.mqh)

1.  **Constructor:** Set `m_panel_height = 710;` (from 780).
2.  **CreatePanel:**
    *   **Settings Section:** Ensure `right_y` increments are tight.
    *   **Strategy Signal:**
        *   Move `Ver` label inside `InfoBG` or to the corner.
        *   Check `InfoBG` height.

## 4. Verification
- [ ] Panel fits better on screen.
- [ ] Red gap is gone.
- [ ] No overlap between Strategy Signal and Pending Alerts.
