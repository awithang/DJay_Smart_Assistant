# Engineering & Architectural Recommendations: DJay Smart Assistant

This document outlines critical architectural recommendations regarding **Time Management**, **Signal Validity**, and **Execution Reliability** for the DJay Smart Assistant EA.

## 1. Signal Expiry & "Stale Data" Prevention (High Priority)
With the recent implementation of "Captured Entry Points," there is a risk that a user might execute a signal that was generated several minutes ago. In fast-moving markets, a price captured 5 minutes ago may no longer represent a valid strategy context.

*   **Observation:** Currently, a signal is captured and held until it is either executed or the `SignalEngine` flags it as invalid.
*   **Risk:** "Stale Signal Execution." If the market moves significantly and returns, the old captured price might be executed when it's no longer advantageous.
*   **Recommendation:** Implement a **Signal TTL (Time-To-Live)**.
    *   Add a `datetime timestamp` to the `EntryPoint` structure.
    *   In `OnTimer`, if `(TimeCurrent() - captured_entry.timestamp) > Signal_Expiry_Seconds`, auto-reset the capture.
    *   Suggested default: **300 seconds (5 minutes)** for M5/M15 scalping.

## 2. Dynamic Pending Order Buffer Logic (High Priority)
The 50-point buffer implemented to prevent 10015 errors is a good start, but needs refinement for different asset classes.

*   **Observation:** A fixed 50-point (5 pip) buffer may be too tight for XAUUSD or too loose for EURGBP.
*   **Recommendation:** Implement a **Hybrid Dynamic Buffer**.
    *   `double dynamicBuffer = MathMax(Input_Min_Buffer_Points * _Point, SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * 1.5 * _Point);`
    *   This ensures the buffer is never smaller than the spread (plus a safety margin) but respects a user-defined minimum.

## 3. Risk Management Integration (High Priority)
*   **Critical Gap:** No daily loss limits or position size limits.
*   **Recommendation:** Add basic safety inputs.
    *   `Input_Max_Open_Trades` (already partially covered by `Max_Orders`)
    *   `Input_Daily_Max_Loss_Percent` (Stop trading if daily loss exceeds X%)

## 4. Defer Until Later (Low Priority)
*   **Broker Time Synchronization:** While important for multi-broker support, we will stick to `Input_GMT_Offset` manually for now.
*   **OnTimer Optimization:** Premature optimization. Current performance is acceptable.
*   **Order Execution Retry:** Complex state management. Defer to v2.0.

## 5. Summary Checklist for Implementation

### Phase 1: Stability & Bug Fixes (Completed)
- [x] **Fix Critical Bug:** Correct the reset string mismatch (`description == "NO REVERSAL SETUP"` vs `!isValid`). ✅ (commit `c071495`)
- [x] **Signal TTL:** Add `timestamp` to `EntryPoint` and implement 5-minute expiry in `OnTimer`. ✅ (commit `da9c554`)
- [x] **Dynamic Buffer:** Update execution logic to use `MathMax(Input_Buffer, Spread * 1.5)`. ✅ (commit `da9c554`)
- [x] **Audit Log:** Ensure all executions are logged with `Print` and distinct prefixes (e.g., `[TRADE_EXEC]`). ✅ (commit `da9c554`)

### Phase 2: Risk Management & Time Sync (Completed)
- [x] **Risk Inputs:** Add `Input_Daily_Max_Loss_Percent` and `Input_Max_Open_Trades`. ✅ (commit `7735270`)
- [x] **Daily Loss Logic:** Implement check in `OnTick` or before order execution to block trades if daily loss limit is reached. ✅ (commit `7735270`)
  - `GetOpenTradesCount()`: Count open positions by magic number
  - `GetDailyPnLPercent()`: Calculate daily P&L with auto-reset at midnight
  - `IsTradingAllowed()`: Central check for all risk management rules
  - Applied to all execution functions and button handlers
- [x] **GMT Offset Wiring:** ✅ (commit `7c96bf9`)
  - Added `m_gmt_offset` member to CSignalEngine class
  - Updated `Init()` to accept and store GMT offset parameter
  - Updated `GetCurrentSession()` to apply offset to time calculation
    - Formula: `adjusted_hour = server_hour - gmt_offset`
    - Handles wrap-around for negative/overflow hours
  - Updated main EA to pass `Input_GMT_Offset` to `signalEngine.Init()`

### Phase 3: Testing & Verification (Pending)
- [ ] **Test 3.3: Risk Management:** Verify `[RISK_BLOCK]` when daily loss or max trades reached.
- [ ] **Test 3.4: GMT Offset:** Verify dashboard sessions align with UTC after applying offset.
