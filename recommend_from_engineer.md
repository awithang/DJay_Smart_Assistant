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
  - Added `datetime timestamp` field to `EntryPoint` struct
  - OnTimer check: `if(TimeCurrent() - captured_entry.timestamp > Input_Signal_TTL_Seconds)`
  - Logs with `[TTL]` prefix showing elapsed time
- [x] **Dynamic Buffer:** Update execution logic to use `MathMax(Input_Buffer, Spread * 1.5)`. ✅ (commit `da9c554`)
  - Applied to all three buttons: Confirm, Reversal, Breakout
  - Formula: `int minBuffer = MathMax(Input_Pending_Min_Buffer, (int)(spread * 1.5));`
- [x] **Audit Log:** Ensure all executions are logged with `Print` and distinct prefixes (e.g., `[TRADE_EXEC]`). ✅ (commit `da9c554`)
  - Added `[TRADE_EXEC]` prefix to all button execution logs
  - Includes buffer size for debugging

### Phase 2: Risk Management & Time Sync (Completed)
- [x] **Risk Inputs:** Add `Input_Daily_Max_Loss_Percent` and `Input_Max_Open_Trades`. ✅ (commit `7735270`)
- [x] **Daily Loss Logic:** Implement check in `OnTick` or before order execution to block trades if daily loss limit is reached. ✅ (commit `7735270`)
  - `GetOpenTradesCount()`: Count open positions by magic number
  - `GetDailyPnLPercent()`: Calculate daily P&L with auto-reset at midnight
  - `IsTradingAllowed()`: Central check for all risk management rules
  - Applied to all execution functions and button handlers
- [x] **GMT Offset:** Add `Input_GMT_Offset` parameter to adjust session times (Asia/London/NY) for different brokers. ✅ (commit `7735270`)

### Phase 3: Testing & Verification (Pending)

#### Test 3.1: Signal TTL (Time-To-Live) Testing
**Purpose:** Verify captured signals expire after the TTL period

**Test Steps:**
1. Set `Input_Signal_TTL_Seconds = 10` (reduce from 300 for quick testing)
2. Wait for a Reversal or Breakout signal to appear (button becomes active)
3. Wait for 11+ seconds without clicking the button
4. Check Experts log for `[TTL]` message
5. Verify button becomes grayed out/inactive

**Expected Results:**
- Log shows: `[TTL] Reversal signal expired after XX seconds (TTL=10)`
- Captured entry is reset
- Button state reflects signal invalid

**Restore:** Set `Input_Signal_TTL_Seconds = 300` after testing

---

#### Test 3.2: Dynamic Pending Order Buffer Testing
**Purpose:** Verify buffer adapts to current spread

**Test Steps (XAUUSD - High Spread):**
1. Attach EA to XAUUSD (Gold) chart
2. Wait for pending signal (Confirm/Reversal/Breakout button active)
3. Click the button to execute order
4. Check Experts log for `[TRADE_EXEC]` message
5. Note the `buffer=` value in the log

**Expected Results:**
- On XAUUSD (spread ~30-50 points): buffer should be >= 45 points (spread * 1.5)
- Log example: `[TRADE_EXEC] Reversal Button: ... buffer=75`
- No Error 10015 (Invalid Price) from broker

**Test Steps (EURGBP - Low Spread):**
1. Attach EA to EURGBP chart
2. Wait for pending signal
3. Execute order and check log

**Expected Results:**
- On EURGBP (spread ~5-10 points): buffer should be 50 points (Input_Pending_Min_Buffer)
- Log example: `[TRADE_EXEC] ... buffer=50`

---

#### Test 3.3: Risk Management - Daily Loss Limit
**Purpose:** Verify trading stops when daily loss limit is reached

**Test Steps:**
1. Set `Input_Daily_Max_Loss_Percent = 0.1` (0.1% for testing)
2. Set `Input_Max_Open_Trades = 0` (disable for this test)
3. Execute some trades to create losses (or wait for natural losses)
4. When daily P&L drops below -0.1%, try to execute any trade (button or auto)
5. Check Experts log for `[RISK_BLOCK]` message

**Expected Results:**
- Log shows: `[RISK_BLOCK] Trade blocked - Daily loss limit reached (-0.15% / -0.10%)`
- Order is NOT sent to broker
- Button click does nothing (or auto trade is skipped)

**Restore:** Set `Input_Daily_Max_Loss_Percent = 5.0` after testing

---

#### Test 3.4: Risk Management - Max Open Trades Limit
**Purpose:** Verify trading stops when max concurrent trades reached

**Test Steps:**
1. Set `Input_Max_Open_Trades = 2`
2. Set `Input_Daily_Max_Loss_Percent = 0` (disable for this test)
3. Manually open 2 positions (or let EA open them)
4. Try to execute a 3rd trade via any button
5. Check Experts log for `[RISK_BLOCK]` message

**Expected Results:**
- Log shows: `[RISK_BLOCK] Trade blocked - Max open trades reached (2/2)`
- 3rd order is NOT sent to broker
- Existing positions continue normally

**Restore:** Set `Input_Max_Open_Trades = 5` after testing

---

#### Test 3.5: Risk Management - Midnight Reset
**Purpose:** Verify daily P&L tracking resets at midnight

**Test Steps:**
1. Note the current time and balance
2. Check Experts log for `[RISK_MGMT] New trading day` message
3. Wait for midnight (broker time) OR manually adjust MT5 time for testing
4. After midnight reset, execute a trade
5. Verify daily P&L starts from 0% based on new start balance

**Expected Results:**
- Log shows: `[RISK_MGMT] New trading day - Start Balance: $XXXXX.XX`
- Daily P&L calculation uses the new start balance
- Previous day's losses do not affect new day's limit

**Note:** For testing without waiting for midnight, temporarily change broker time or use demo account with adjustable time.

---

#### Test 3.6: GMT Offset Configuration
**Purpose:** Verify correct GMT Offset value for session calculations

**Test Steps:**
1. Open MetaTrader 5 Market Watch
2. Note the current server time displayed
3. Compare to GMT/UTC at https://time.is/UTC
4. Calculate: `GMT_Offset = Broker_Time - GMT_Time`
5. Set `Input_GMT_Offset` to this value
6. Restart EA to apply changes

**Example:**
- Broker shows 14:00, GMT shows 12:00 → Offset = +2
- Broker shows 10:00, GMT shows 12:00 → Offset = -2

**Expected Results:**
- Session times (Asia/London/NY) display correctly on dashboard
- Signals respect the correct session hours

---

#### Testing Checklist Summary
- [ ] TTL Testing (10-second expiry verification)
- [ ] Dynamic Buffer Testing (XAUUSD high spread)
- [ ] Dynamic Buffer Testing (EURGBP low spread)
- [ ] Daily Loss Limit Testing (0.1% threshold)
- [ ] Max Open Trades Testing (limit = 2)
- [ ] Midnight Reset Testing
- [ ] GMT Offset Configuration
