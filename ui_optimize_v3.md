# UI Optimization & Performance Plan (v3)
**Objective:** Refine the Dashboard UI layout, implement editable Profit Lock settings, and resolve button responsiveness issues.

## 1. Diagnostics: Why are buttons lagging?
**Issue:** "RR option select buttons are toggle lagging... Profit lock on/off button also lagging."
**Analysis:**
1.  **Event Handling Conflict:** The current `OnChartEvent` logic likely has a "fall-through" issue where clicking a button triggers the specific handler (which is fast) but *also* falls through to a generic `ChartRedraw()` or other heavy logic at the end of the function.
2.  **Input Focus:** Clicking an object that looks like a button but is actually an `OBJ_EDIT` (or close to one) might trigger focus events that delay the click response.
3.  **Redraw Overkill:** If `ChartRedraw()` is called *twice* (once by the specific handler and once by the main loop) or called unnecessarily, it causes a visual stutter.
4.  **State Management:** If the EA writes to GlobalVariables on *every* click synchronously, file I/O lag might be perceptible.

**Solution Strategy:**
*   **Exclusive Event Handling:** Ensure that once a button click is handled, the `OnChartEvent` function returns *immediately*.
*   **Asynchronous Saving:** Consider saving settings only when the panel is destroyed or periodically, rather than on every single click (or accept the slight micro-lag for persistence but optimize the visual update first).
*   **Visual Feedback First:** Update the object color *immediately* before doing any logic/calculations.

## 2. Layout & Spacing Improvements
**Objective:** "Add more space between each section (use same padding)."
**Current Layout:** Sections are packed tight.
**New Layout Strategy:**
*   **Standard Padding:** Define `SECTION_PAD_Y = 10` (or 15).
*   **Dynamic Y Calculation:** Instead of hardcoded Y values, use a `current_y` tracker that increments by `section_height + SECTION_PAD_Y`.
*   **Bottom Expansion:** Since we have space, we can expand the "Active Orders" or "Strategy Signal" sections vertically or just add breathing room.

## 3. RR Option Display Fix
**Issue:** "RR option 1:2 display not correct."
**Fix:** Check the coordinates and width of the "1:2" button. It might be overlapping with the Risk% input or clipped.
*   *Action:* Ensure total width of 3 buttons + gaps fits within the panel half-width.

## 4. Profit Lock Input Implementation
**Request:** Replace "Conservative/Balanced/Aggressive" presets with **3 Editable Input Boxes**:
1.  **Trigger (pts)**
2.  **Lock Amount (pts)**
3.  **Step (pts)**

**UI Components:**
*   **Header:** "Profit Lock Settings (pts)"
*   **Row 1:** Label "Trigger" | EditBox "EditPLTrigger" (e.g., "200")
*   **Row 2:** Label "Lock"    | EditBox "EditPLLock"    (e.g., "50")
*   **Row 3:** Label "Step"    | EditBox "EditPLStep"    (e.g., "100")

**Data Flow:**
*   **Read:** `GetPL_Trigger()`, `GetPL_Amount()`, `GetPL_Step()` will now parse strings from these Edit objects instead of reading a preset array.
*   **Validation:** Ensure inputs are integers > 0.

## 5. Toggle Button Consistency
**Request:** "On/Off toggle buttons should be same size and same right align position."
**Targets:**
*   `BtnMode` (Auto Mode Toggle)
*   `BtnTrailToggle` (Profit Lock Toggle)
*   Any future toggles.

**Standardization:**
*   **Width:** Fixed 60px (or 70px).
*   **Height:** Fixed 20px.
*   **Alignment:** `right_x + half_width - pad`.
*   **Visuals:** Green (ON) / Gray (OFF) with White Text.

## 6. Detailed Implementation Steps

### A. DashboardPanel.mqh - Layout Refactor
1.  **Define Constants:** `PAD_Y = 15`, `ROW_H = 20`.
2.  **Refactor `CreatePanel`:**
    *   **Right Panel (Settings):**
        *   `current_y = 15`
        *   **RR Section:** Y = `current_y`. Buttons: `1:1`, `1:1.5`, `1:2`. Fix overlap.
        *   `current_y += 30`
        *   **Risk Section:** Y = `current_y`. Label + EditBox.
        *   `current_y += 30`
        *   **Profit Lock Toggle:** Y = `current_y`. Align Right.
        *   `current_y += 25`
        *   **Profit Lock Inputs:**
            *   Trigger: Label + EditBox.
            *   Lock: Label + EditBox.
            *   Step: Label + EditBox.
            *   (Layout: Grid or Vertical List? Grid saves space: `Trig: [200]  Lock: [50]  Step: [100]`)
    *   **Right Panel (Execution):**
        *   Move `BtnBuy`/`BtnSell` further down to accommodate new inputs.
    *   **Right Panel (Auto Strat):**
        *   Move down. Align `BtnMode` exactly with `BtnTrailToggle` (Right Align).

### B. DashboardPanel.mqh - Logic & Performance
1.  **Event Handler Optimization (`OnEvent`):**
    *   **RR Buttons:**
        ```cpp
        if (sparam == "BtnRR1") {
            m_current_rr = RR_1_TO_1;
            UpdateRRButtonsVisuals(); // Only changes color
            return; // EXIT IMMEDIATELY
        }
        ```
    *   **Profit Lock Toggle:**
        ```cpp
        if (sparam == "BtnTrailToggle") {
            m_trail = !m_trail;
            UpdateTrailVisuals();
            return; // EXIT IMMEDIATELY
        }
        ```
2.  **Input Parsing:**
    *   Update `GetPL_Trigger()`: `return StringToInteger(ObjectGetString(..., "EditPLTrigger", ...));`
    *   (Performance Note: Reading object properties is slightly slow. Cache values in variables and update on `CHARTEVENT_OBJECT_ENDEDIT`?)
    *   *Decision:* For inputs, reading on demand (in `OnTick` or when trade executes) is fine. For the *toggle* responsiveness, strict event isolation is key.

### C. DJay_Smart_Assistant.mq5 - Integration
1.  **Remove Presets:** Remove `Input_ProfitLock_Trigger_Pts` etc. from EA Inputs?
    *   *Strategy:* Keep them as **Defaults** for the Edit Boxes initialization.
2.  **Update Logic:**
    *   In `OnTick`:
        ```cpp
        if (dashboard.IsTrailingEnabled()) {
             int trig = dashboard.GetPL_Trigger(); // Reads EditBox
             int lock = dashboard.GetPL_Amount();  // Reads EditBox
             int step = dashboard.GetPL_Step();    // Reads EditBox
             tradeManager.ManagePositions(trig, lock, step);
        }
        ```

## 7. Verification Checklist
- [ ] **Performance:** Clicking RR buttons is instant (<50ms).
- [ ] **Performance:** Clicking Profit Lock Toggle is instant.
- [ ] **Layout:** Section spacing is uniform (15px).
- [ ] **Layout:** "1:2" button is fully visible.
- [ ] **Consistency:** Auto Mode and Profit Lock toggles share exact size/alignment.
- [ ] **Function:** Profit Lock uses values typed in the new Edit Boxes.

