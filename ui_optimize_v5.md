# UI Layout Strategy & Conclusion (v5)

## 1. Analysis of Current Overlap
**Issue:** "Strategy signal section detail are cover by Pending alerts section."
**Cause:** The new "Settings" section (with the expanded Profit Lock inputs) pushed the "Auto Strategy" and "Strategy Signal" sections down too far. Meanwhile, the "Pending Alerts" section is anchored to the bottom. The two have collided in the middle.

## 2. Architect's Conclusion on Button Placement
**Question:** "What do you think if we move manual Buy and Sell buttons to the top of panel?"

**Expert Recommendation: APPROVED.**
Moving the **Manual Buy/Sell** buttons to the top (Panel B, Row 1) is a superior UX choice for these reasons:
1.  **Immediacy:** Execution is the primary action; it should be instantly accessible without scanning past settings.
2.  **Visual Hierarchy:** Execution (Action) -> Strategy (Control) -> Settings (Configuration).
3.  **Space Efficiency:** The Buy/Sell buttons are compact horizontal elements. Placing them at the top pushes the "Settings" block down, but since "Settings" is dense, it sits better in the middle.

## 3. Revised Layout Plan (v5)

### Panel B (Right Side) - New Order
1.  **Top:** **Manual Buy/Sell Buttons** (Row 1).
2.  **Below:** **Auto Strategy** (Mode Toggle + Buttons).
3.  **Middle:** **Settings Section** (RR, Risk, Profit Lock).
    *   *Optimization:* Reduce vertical gaps (`gap_y`) slightly to save space.
4.  **Lower-Middle:** **Strategy Signal**.
5.  **Bottom Anchor:** **Pending Alerts** & **Active Orders** (Footer).

### Coordinate Strategy
*   `right_y` starts at 15.
*   **Buy/Sell:** Height 40px.
*   **Auto Strat:** Height ~60px.
*   **Settings:** Height ~140px.
*   **Strategy Signal:** Height ~100px.
*   **Total Content Height:** ~340px.
*   **Footer Height:** ~200px (Pending + Orders).
*   **Total Panel Height:** ~665px.
*   **Space Check:** 340 + 200 = 540px. Buffer = 125px. This layout fits comfortably without overlap.

## 4. Implementation Steps (CreatePanel)

1.  **Reset `right_y`**: Start at 15.
2.  **Section 1: Manual Execution**
    *   Place `BtnBuy` and `BtnSell` here.
    *   `right_y += 45`.
3.  **Section 2: Auto Strategy**
    *   Place `LblStratTitle`, `BtnMode`, `StratBG`, Strategy Buttons.
    *   `right_y += 75`.
4.  **Section 3: Settings**
    *   Place Header "SETTINGS".
    *   Place `SettingsBG` (RR, Risk, Profit Lock).
    *   *Refinement:* Reduce internal gaps (`row_h + 10` -> `row_h + 5`).
    *   `right_y += 165`.
5.  **Section 4: Strategy Signal**
    *   Place `LblSig`, `InfoBG`, Signal Labels.
    *   `right_y += 115`.
6.  **Section 5: Footer (Bottom Anchored)**
    *   Pending Alerts (`m_panel_height - 220`).
    *   Active Orders (`m_panel_height - 130`).

## 5. Summary
This reordering solves the overlap by compacting the top sections and logically placing the "Action" buttons first.
