# Implementation Plan: UI Optimization & Layout Restructuring

## Objective
1.  **Fix UI Responsiveness**: Resolve "unclickable" button issues and optimize EA performance.
2.  **Restructure Dashboard**: Move the "Strategy Signal" section to Panel B (Right Side) for better logical grouping.

## Part 1: Performance & Responsiveness (Critical)

### Root Cause Analysis
-   **Unclickable Buttons**: Visual "Active" state (Green/Red) does not match logical `isValid` state. Users click a green button, but the code rejects it because the internal signal isn't ready.
-   **UI Lag**: `OnTimer` blindly updates all objects every second, flooding the terminal with redundant commands.

### Implementation Steps
1.  **Sync Visuals with Logic**:
    -   Update `DashboardPanel::UpdateStrategyInfo` to accept `isValid` flags.
    -   **Rule**: Button only turns Green/Red if `isValid == true`. Otherwise, it stays Gray (Active Wait) or Hidden.
2.  **"Dirty Checking" (Smart Updates)**:
    -   Refactor all `Update...` methods in `DashboardPanel.mqh`.
    -   Read current property value (`ObjectGetString`/`Integer`) before writing.
    -   **Only write if different**. This reduces API calls by ~90%.
3.  **Event Handling**:
    -   Add "Action Blocked" debug prints in `OnChartEvent` if a user clicks an apparently active button that fails.
    -   Ensure immediate `OBJPROP_STATE` reset after clicks.

## Part 2: Layout Restructuring (UI Move)

### Objective
Move "Strategy Signal" section from **Panel A (Left)** to **Panel B (Right)**, positioning it between "Auto Strategy" and "Pending Alerts".

### Execution Details
1.  **Target Coordinates**:
    -   **Previous Location**: Left Panel, Y=230.
    -   **New Location**: Right Panel, below "Auto Strategy" (approx Y=215).
    -   **Vertical Space**: Available space in Right Panel is Y=200 to Y=370. The section height is ~115px, fitting perfectly.

2.  **Code Migration (`DashboardPanel::CreatePanel`)**:
    -   **Move Code Block**: Cut the "3. Strategy Signal" block.
    -   **Insert**: Paste it after the "5. Auto Strategy Options" block.
    -   **Update Variables**: Change `left_x` to `right_x` for all moved elements (`LblSig`, `InfoBG`, `Trend_T`, `PA_T`, `Adv_T`, `Ver`, etc.).
    -   **Recalculate Y-Offsets**:
        -   Header (`LblSig`): **Y = 215**
        -   Background (`InfoBG`): **Y = 235**
        -   Inner Elements: Maintain relative spacing from new background top.

3.  **Panel A (Left) Cleanup**:
    -   The move leaves a large void in Panel A (Left).
    -   **Action**: Extend the "Daily Zones Table" (Smart Grid) to show more zones (e.g., increase from 5 to 10 zones) to utilize the newly available vertical space effectively.

## Verification Checklist
-   [ ] **Responsiveness**: Buttons react instantly.
-   [ ] **Clickability**: Buttons only active when trade is valid.
-   [ ] **Layout**: "Strategy Signal" sits neatly in Right Panel without overlapping "Pending Alerts".
-   [ ] **Left Panel**: Empty space is utilized (extended grid).
-   [ ] **Performance**: `OnTimer` execution is < 1ms on average.