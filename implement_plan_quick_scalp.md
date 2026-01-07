# Implementation Plan: Quick Scalp Logic Optimization (v2.0)

**Objective:** Fix the "Zero Trades" issue by relaxing filters (OR Logic) and improve safety by adding a Dead Zone filter (ADX). Also, implement "Smart Auto-Switch" to remove user error.

## 1. Modify `SignalEngine.mqh`

### Step 1.1: Add ADX Indicator
*   **Action:** Add `m_handle_adx` to the class private members.
*   **Action:** Initialize `iADX(_Symbol, PERIOD_M5, 14)` in `Init()`.
*   **Action:** Create `GetADXValue(ENUM_TIMEFRAMES tf)` method to return the current ADX level.
*   **Action:** Ensure handle release in `~CSignalEngine()`.

### Step 1.2: Update `GetAdvisorMessage`
*   **Action:** Update the advisor text logic to reflect the new state.
    *   If `ADX < 20`: Return "Market is Choppy (ADX Low). Quick Scalp Paused."
    *   If `Smart Mode` active: Return "Scanning for Momentum Pullback..."

## 2. Modify `DJay_Smart_Assistant.mq5`

### Step 2.1: Implement "OR Logic" Filter
*   **Location:** `OnTick()` inside the `if(g_quick_scalp_mode)` block.
*   **Current Logic:** `RSI < 40 && Stoch < 20`
*   **New Logic:** `(RSI < 40 || Stoch < 20)`
    *   *Note:* Keep the PA Signal and Trend Alignment as mandatory AND conditions.

### Step 2.2: Implement ADX Filter
*   **Location:** `OnTick()` inside the `if(g_quick_scalp_mode)` block.
*   **New Logic:**
    ```cpp
    double adx = signalEngine.GetADXValue(PERIOD_M5);
    if (adx < 20) return; // Skip trading
    ```

### Step 2.3: Implement "Smart Auto-Switch"
*   **Action:** Change `g_quick_scalp_mode` from a simple bool toggle to a "Permission" flag.
*   **Logic in `OnTimer`:**
    *   Check Context: `bool contextValid = (zone == NEUTRAL && trend != FLAT);`
    *   Update Button Color:
        *   **Gray:** Permission OFF (User disabled).
        *   **Orange:** Permission ON but Context Invalid (Scanning/Waiting).
        *   **Green:** Permission ON + Context Valid (Active).

## 3. Verification Plan

### Test 3.1: ADX Filter Test
*   **Method:** Run Strategy Tester on a choppy day.
*   **Expected:** `Print` log should show "QS Skipped: Low ADX".

### Test 3.2: Execution Frequency
*   **Method:** Run Strategy Tester for 1 week of data.
*   **Expected:** Should see at least 3-5 trades (Buy/Sell) instead of 0.

### Test 3.3: Visual Button State
*   **Method:** In visual mode, toggle the QS button.
*   **Expected:** Button should switch between "DISABLED" (Gray) and "AUTO" (Orange/Green depending on trend).
