# Bug Report: UI Inputs Not Syncing with EA Inputs

**Date:** January 7, 2026
**Status:** CONFIRMED

## 1. Issue Description
When the user changes Input parameters (e.g., Risk %, Profit Lock Settings) in the EA properties window, the Dashboard Panel does not reflect these changes. It reverts to default values (e.g., Risk 1.0%, Trigger 200).

## 2. Root Cause Analysis
The Dashboard Panel's initialization logic hardcodes the default values for the UI Edit fields, completely ignoring the values provided in the EA's Input parameters.

**File:** `MQL5/Include/DJay_Assistant/DashboardPanel.mqh`
**Method:** `CreatePanel()`

**Offending Code (Hardcoded Defaults):**
```cpp
CreateEdit("EditRisk", ..., "1.0"); // Hardcoded "1.0"
CreateEdit("EditPL_Trigger", ..., "200"); // Hardcoded "200"
CreateEdit("EditPL_Amount", ..., "50"); // Hardcoded "50"
CreateEdit("EditPL_Step", ..., "100"); // Hardcoded "100"
```

## 3. Required Fixes

### 3.1 Update DashboardPanel Class
**Action:** Modify `Init` and `CreatePanel` to accept dynamic values.
- Update `Init` signature to accept: `double initial_risk`, `int pl_trigger`, `int pl_lock`, `int pl_step`.
- Store these values in private member variables.
- Use these variables in `CreatePanel` instead of hardcoded strings.

### 3.2 Update Expert Advisor Initialization
**Action:** Pass the Input parameters to the Panel during initialization.
**File:** `DJay_Smart_Assistant.mq5` -> `OnInit()`
**Change:**
```cpp
// Pass user inputs to panel
dashboardPanel.Init(0, Input_RiskPercent, Input_ProfitLock_Trigger_Pts, Input_ProfitLock_Amount_Pts, Input_ProfitLock_Step_Pts);
```

## 4. Conclusion
This fix will ensure that whatever values the user sets in the Input tab (e.g., Risk 2.0%) will be correctly populated in the Dashboard Panel upon startup.
