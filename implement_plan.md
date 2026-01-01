# Implementation Plan: Draggable Dashboard (Performance Optimized)

## Objective
Allow the main dashboard panel to be dragged and dropped to any position on the chart, specifically optimizing for zero lag and minimal CPU usage.

## Performance Strategy
**"Ghost/Lazy Dragging"**: Moving 50+ UI objects (buttons, labels, inputs) simultaneously on every mouse move event is computationally expensive and causes chart flickering.
**Solution**:
1.  **On Drag Start**: Identify the drag action.
2.  **During Drag**: Move **only** the main background panel (or a lightweight outline). This is extremely fast (1 object update).
3.  **On Drop**: Instantly snap all other UI elements (buttons, text) to the new position.

## Implementation Steps

### 1. Enable Mouse Events
*   **File**: `MQL5/Experts/EA_Helper/WidwaPa_Assistant.mq5`
*   **Action**: Add `ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);` in `OnInit`.

### 2. Update `CDashboardPanel` Class Structure
*   **File**: `MQL5/Include/EA_Helper/DashboardPanel.mqh`
*   **Data Structure**:
    -   Define a struct `PanelObject` (`string name`, `int relative_x`, `int relative_y`) to cache object offsets.
    -   Add an array `m_objects[]` to store this registry.
    -   Add state variables: `m_is_dragging`, `m_drag_offset_x`, `m_drag_offset_y`.

### 3. Modify Object Creation Helpers
*   **File**: `MQL5/Include/EA_Helper/DashboardPanel.mqh`
*   **Action**: Update `CreateRect`, `CreateLabel`, `CreateButton`, etc.
*   **Logic**: Every time an object is created, calculate its `relative_x = x - m_base_x` and `relative_y = ry - m_base_y` and add it to `m_objects[]`.
    -   *Benefit*: This pre-calculates the geometry, making the "Drop" action an O(N) linear iteration with simple addition, avoiding complex recalculations.

### 4. Implement Drag Logic
*   **File**: `MQL5/Include/EA_Helper/DashboardPanel.mqh`
*   **New Method**: `OnEvent(int id, long& lparam, double& dparam, string& sparam)`
    -   **Mouse Down**: Check if cursor is over the "Header" area. If yes, set `m_is_dragging = true` and record starting offset.
    -   **Mouse Move**:
        -   If `m_is_dragging == true`:
        -   Calculate `new_x`, `new_y`.
        -   Update **only** the `MainBG` object's position (visual feedback).
    -   **Mouse Up**:
        -   Set `m_is_dragging = false`.
        -   Call `MovePanel(new_x, new_y)`.

### 5. Implement `MovePanel` Method
*   **Logic**:
    -   Update `m_base_x`, `m_base_y`.
    -   Loop through `m_objects[]`.
    -   For each object, set `OBJPROP_XDISTANCE = m_base_x + relative_x` (and Y equivalent).
    -   Force `ChartRedraw()` once at the end.

## Verification
-   [ ] **Smoothness**: Dragging the header should feel instant (moving only the background).
-   [ ] **Precision**: On release, all buttons and labels should snap perfectly into place.
-   [ ] **Performance**: No CPU spikes or chart freeze during dragging.
