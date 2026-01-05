# Architecture & Implementation Plan: UI Optimization - DJAY Smart Assistant

## 1. Objective
Refine the Dashboard UI to improve usability, visual hierarchy, and logical grouping of information.
**Key Changes:**
1.  **Layout Restructuring**: Move "Strategy Signal" to Left Panel (Panel A).
2.  **Daily Zones Scrolling**: Add scroll functionality (max 10 rows visible) to the Daily Zones table to handle more levels without taking up extra space.
3.  **Active Orders**: Optimize row layout (Close button on left).
4.  **Visual Tweaks**: Adjust spacing and highlight key timers.

## 2. Technical Constraints & Performance
*   **Zero-Latency Response**: Interactive elements must remain lightweight (`BORDER_FLAT`).
*   **Efficient Redraws**:
    *   **Daily Zones**: Scrolling should trigger a targeted update of just the zone labels, not a full panel redraw.
    *   **Data Handling**: Use an array to store all calculated zones, then render a "window" of 10 zones based on a scroll offset index.

## 3. Detailed Specifications

### 3.1 Daily Zones Scrolling (New Feature)
**Goal**: Enable scrolling for the Daily Zones table using the same visual style as Active Orders.

*   **New State Members**:
    *   `int m_zone_scroll_offset`: Current index of top visible zone row.
    *   `int m_zone_total_levels`: Total number of calculated zones (e.g., 20 or 60).
    *   `struct ZoneLevel { double price; string label; string type; };` (or parallel arrays) to store full list.
*   **UI Components (`CreatePanel`)**:
    *   **Scroll Buttons**:
        *   `BtnZoneScrollUp`: Positioned inside `TableBG` (top-right corner).
        *   `BtnZoneScrollDown`: Positioned inside `TableBG` (bottom-right corner).
        *   **Style**: 15x15 size, flat border, "▲"/"▼" symbols.
*   **Rendering Logic (`UpdateDJayZones`)**:
    *   Calculate ALL levels (e.g., +/- 30 zones).
    *   Sort and filter to find relevant levels (the existing logic keeps the "best 10").
    *   **CHANGE**: Instead of keeping just "best 10", keep "best 20" (or more) sorted by price, store them in class member arrays.
    *   **Display Loop**: Loop from `0` to `9` (10 rows).
        *   Access index `m_zone_scroll_offset + i`.
        *   Update labels `L_N_x`, `L_P_x`, `L_D_x`.
*   **Event Handling (`OnEvent`)**:
    *   `IsZoneScrollUpClicked`: Decrement offset.
    *   `IsZoneScrollDownClicked`: Increment offset.
    *   Call `UpdateDJayZones(0)` (or a dedicated redraw helper) to refresh text.

### 3.2 Layout Restructuring
**Goal**: Move Strategy Signal from Panel B to Panel A (Top-Middle).

*   **Left Panel Flow**: Header -> **Strategy Signal** -> Daily Zones.
*   **Vertical Shift**: The "Daily Zones" section (and its new scroll buttons) must move down by approx **140px** to make room for Strategy Signal.

### 3.3 Active Orders Row Layout
*   **Close Button**: Move to left (`base_x + 10`).
*   **Info Label**: Shift right. Remove Ticket ID.

### 3.4 Spacing & Styling
*   **Top Left Header**: Increase X-offset for values by **+5px**.
*   **M5 Timer**: Change color to Orange (`C'255,140,0'`).

## 4. Implementation Steps (For Coding Agent)

1.  **Class Updates (`DashboardPanel.mqh`)**:
    *   Add `m_zone_scroll_offset` (init to 0).
    *   Add private arrays to cache zone data: `m_zone_prices[]`, `m_zone_labels[]`, `m_zone_types[]`.
    *   Add event handlers for zone scroll buttons.
2.  **Refactor `CreatePanel`**:
    *   **Move Strategy Signal**: Cut from Right, Paste to Left (above Zones). Adjust Y-coords.
    *   **Shift Daily Zones**: Add ~140px to Y-coords.
    *   **Add Zone Scroll Buttons**: Create `BtnZoneScrollUp` and `BtnZoneScrollDown` within the shifted `TableBG` area.
3.  **Update `UpdateDJayZones`**:
    *   Modify logic to store **all** relevant nearest zones (e.g., top 20) into the new cache arrays instead of just writing to the first 10 labels.
    *   Implement a "Render" loop that reads from cache based on `m_zone_scroll_offset`.
4.  **Update `UpdateActiveOrders`**:
    *   Reposition Close Button (Left) and Text (Right).
5.  **Apply Styling**:
    *   Spacing + Orange M5 Timer.

## 5. Verification
*   **Daily Zones**:
    *   Verify scrolling works (values change, order is preserved).
    *   Verify layout is correctly positioned below Strategy Signal.
*   **Strategy Signal**: Verify it sits neatly between Header and Zones.
    *   **Advisor Message**: Ensure `GetAdvisorMessage` output (Trend/Zone/Signal analysis) is still correctly displayed in the moved `Adv_T/V/V2` labels.
*   **Active Orders**: Verify Left-Close button layout.