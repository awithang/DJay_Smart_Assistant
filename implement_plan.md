# Architecture & Implementation Plan: UI Optimization & Feature Enhancement

## 1. Objective
Refine the Dashboard UI to improve usability and logical grouping, and enhance the Advisor logic to provide more specific, actionable market analysis.
**Key Changes:**
1.  **Advisor Logic (New)**: Upgrade "Advisor" to identify specific candle patterns (e.g., "H1 Bullish Engulfing") and suggest explicit entry points.
2.  **Daily Zones Scrolling**: Add scroll functionality (max 10 rows visible) to the Daily Zones table.
3.  **Layout Restructuring**: Move "Strategy Signal" to Left Panel (Panel A).
4.  **Active Orders**: Optimize row layout (Close button on left).

## 2. Technical Constraints & Performance
*   **Zero-Latency Response**: Interactive elements must remain lightweight (`BORDER_FLAT`).
*   **Efficient Redraws**:
    *   **Daily Zones**: Scrolling triggers targeted updates only.
    *   **Advisor**: Text generation uses existing cached indicators and efficient string formatting.
*   **String Length**: Advisor messages must remain concise to fit within the 2-line limit (approx 40 chars per line) of the UI.

## 3. Detailed Specifications

### 3.1 Advisor Logic Enhancement (Feature Request)
**Goal**: Provide specific technical details (Candle Patterns) and concrete Entry Suggestions in the Advisor text.

*   **New Methods (`SignalEngine.mqh`)**:
    *   `string GetPatternName(ENUM_TIMEFRAMES tf)`:
        *   Checks `IsEngulfing`, `IsHammer`, `IsShootingStar` on the given TF.
        *   Returns: "Bullish Engulfing", "Bearish Engulfing", "Hammer", "Shooting Star", or "".
*   **Updated Method (`GetAdvisorMessage`)**:
    *   **Logic**:
        1.  Get Trend (existing).
        2.  Get Pattern Name for H1 (and optionally M5).
        3.  Check for valid Entry Point using `GetReversalEntryPoint()` or `GetBreakoutEntryPoint()`.
    *   **Output Format (Draft)**:
        *   *If Entry Found*: "H1 [Pattern]. Suggest: [Direction] @ [Price]"
        *   *If No Entry*: "Trend [Dir]. H1 [Pattern]. Wait for signal."
    *   **Example 1**: "H1 Bullish Engulfing. Suggest: BUY @ 2150.00"
    *   **Example 2**: "Strong Uptrend. No clear pattern. Wait."

### 3.2 Daily Zones Scrolling
**Goal**: Enable scrolling for the Daily Zones table (max 10 rows visible).

*   **New State Members**: `m_zone_scroll_offset`, `m_zone_total_levels`, and cache arrays.
*   **UI**: Add `BtnZoneScrollUp` / `BtnZoneScrollDown` (15x15) inside `TableBG`.
*   **Logic**: `UpdateDJayZones` caches ~20 levels; render loop displays 10 based on offset.

### 3.3 Layout Restructuring
**Goal**: Move Strategy Signal from Panel B to Panel A (Top-Middle).

*   **Left Panel Flow**: Header -> **Strategy Signal** -> Daily Zones.
*   **Vertical Shift**: "Daily Zones" moves down ~140px.

### 3.4 Active Orders Row Layout
*   **Layout**: `[Close Button (X)] [Type + Lots + Price] ...` (Ticket ID removed).

## 4. Implementation Steps (For Coding Agent)

1.  **Step 1: Signal Engine Upgrade**:
    *   Implement `GetPatternName(tf)` in `CSignalEngine`.
    *   Refactor `GetAdvisorMessage` to construct the detailed string.
    *   *Note*: Ensure string length is checked to prevent truncation artifacts.
2.  **Step 2: Dashboard Class Updates**:
    *   Add zone scroll members (`m_zone_scroll_offset` etc.) and button handlers.
3.  **Step 3: UI Layout Refactoring**:
    *   Move Strategy Signal block to Left Panel.
    *   Shift Daily Zones down.
    *   Add Zone Scroll Buttons.
4.  **Step 4: Active Orders & Styling**:
    *   Update Order Row layout.
    *   Apply Orange color to M5 Timer.

## 5. Verification
*   **Advisor**:
    *   Check various market conditions (Trend vs Flat).
    *   Verify message displays specific pattern names (e.g., "Bullish Engulfing") when they occur.
    *   Verify Entry Suggestion appears when `GetReversalEntryPoint` is valid.
*   **Layout**: Verify Strategy Signal fits cleanly above Zones.
*   **Scrolling**: Verify Daily Zones scroll correctly.
