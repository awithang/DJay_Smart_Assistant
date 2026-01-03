# Open Settings Implementation Plan

**Objective:** Add a button to the dashboard that opens the Expert Advisor's input parameters window (Properties).

## 1. UI Implementation
**File:** `MQL5/Include/DJay_Assistant/DashboardPanel.mqh`
*   **Location:** Inside `CreatePanel`, next to the "SETTINGS" header.
*   **Object Name:** `BtnOpenSettings`
*   **Alignment:** Right-aligned (`right_x + half_width - 65`), matching the toggle buttons.
*   **Visuals:** Gray background, White text, Label: "INPUTS" or "Open".

## 2. Technical Logic (WinAPI)
Since MQL5 does not provide a native function to open the Expert Properties dialog, we will use the Windows API to send a command message to the terminal window.

**File:** `MQL5/Include/DJay_Assistant/Definitions.mqh`
*   Add `#import "user32.dll"` to declare the `PostMessageW` function.
*   Define the command constant: `#define WM_COMMAND 0x0111`.
*   Define the MT5 Expert Properties ID: `#define MT5_CMD_EXPERT_PROPERTIES 33048`.

## 3. Integration
**File:** `MQL5/Experts/DJay_Assistant/DJay_Smart_Assistant.mq5`
*   **Handler:** Add a check in `OnChartEvent` for `IsOpenSettingsClicked`.
*   **Action:**
    ```cpp
    long handle = (long)ChartGetInteger(0, CHART_WINDOW_HANDLE);
    PostMessageW(handle, WM_COMMAND, MT5_CMD_EXPERT_PROPERTIES, 0);
    ```

## 4. Verification
*   **Button:** Appears at the top right of the Settings section.
*   **Response:** Clicking the button instantly opens the standard EA Input Parameters window.
*   **DLLs:** Note that "Allow DLL imports" must be enabled in the EA settings for this specific button to function.
