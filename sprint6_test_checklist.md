# Sprint 6 Hybrid Mode - Test Verification Checklist

**Commit:** 116d2ef - feat: Sprint 6 Phase 1-4 - M15/M5 Hybrid Mode implementation
**Date:** 2026-01-08
**Tester:** _________________
**Result:** ⬜ Pass / ❌ Fail / ⚠️ Partial

---

## Pre-Test Setup

### Environment Check
- [ ] MetaTrader 5 terminal running
- [ ] Demo account loaded (recommended for testing)
- [ ] XAUUSD (Gold) chart open with M15 and M5 data available
- [ ] EA compiled successfully (no errors)
- [ ] EA attached to chart
- [ ] Inputs configured:
  - `Input_Enable_Hybrid_Mode = true`
  - `Input_Enable_Sniper_Mode = false` (to test Hybrid alone)
  - `Input_Auto_Arrow = true` (for AUTO mode testing)

---

## Unit Tests (Code Logic Verification)

### UT-001: GetHybridSignal - Bullish M15 + Bullish M5
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Wait for M15 trend alignment (H4+H1+M15 score ≥ 2, all BULLISH)
2. Wait for M5 Hammer or Bullish Engulfing pattern
3. Check Expert logs for "HYBRID" signal

**Expected Result:**
- Log shows: `HYBRID_BUY signal detected`
- `GetHybridSignal()` returns `SIGNAL_PA_BUY`
- No rejection in logs (no "CONTEXT NOT READY", no "CHOPPY MARKET", etc.)

**Actual Result:** _________________

---

### UT-002: GetHybridSignal - Bearish M15 + Bearish M5
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Wait for M15 trend alignment (H4+H1+M15 score ≤ -2, all BEARISH)
2. Wait for M5 Shooting Star or Bearish Engulfing pattern
3. Check Expert logs for "HYBRID" signal

**Expected Result:**
- Log shows: `HYBRID_SELL signal detected`
- `GetHybridSignal()` returns `SIGNAL_PA_SELL`

**Actual Result:** _________________

---

### UT-003: GetHybridSignal - Flat M15 Context
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Find market with M15 trend score between -1 and +1 (mixed signals)
2. Wait for valid M5 PA pattern
3. Check Expert logs

**Expected Result:**
- Log shows: `CONTEXT NOT READY: Trend score X`
- `GetHybridSignal()` returns `SIGNAL_NONE`
- No trade executed

**Actual Result:** _________________

---

### UT-004: GetHybridSignal - Choppy Market Filter
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Find market with ADX < 20 (ranging/choppy)
2. Wait for valid M5 PA pattern
3. Check Expert logs

**Expected Result:**
- Log shows: `CHOPPY MARKET: Skipped`
- `GetHybridSignal()` returns `SIGNAL_NONE`

**Actual Result:** _________________

---

### UT-005: GetHybridSignal - Location Filter (Price Far from EMA)
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Find market where price is > 0.5 * ATR away from M15 EMA 20
2. Wait for valid M5 PA pattern
3. Check Expert logs

**Expected Result:**
- Log shows: `LOCATION FILTER: Price too far from EMA`
- `GetHybridSignal()` returns `SIGNAL_NONE`

**Actual Result:** _________________

---

### UT-006: GetHybridSignal - Falling Knife Protection
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Find market with SLOPE_CRASH (steep downtrend)
2. Wait for M5 Hammer (buy signal)
3. Check Expert logs

**Expected Result:**
- Log shows: `FALLING KNIFE: Slope protection`
- `GetHybridSignal()` returns `SIGNAL_NONE` (buy blocked)

**Actual Result:** _________________

---

### UT-007: ExecuteHybridTrade - SL/TP Calculation
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Enable Hybrid Mode + AUTO
2. Wait for valid HYBRID signal
3. Check trade parameters in Terminal > Trade tab

**Expected Result:**
- SL = Entry Price ± `Input_Hybrid_SL_Points` (default: 150 points)
- TP = Entry Price ∓ `Input_Hybrid_TP_Points` (default: 100 points)
- Comment = "HYBRID_BUY" or "HYBRID_SELL"

**Actual Result:**
- SL: _________________
- TP: _________________

---

### UT-008: ExecuteHybridTrade - Risk Percent Lot Mode
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Set `Input_Hybrid_Lot_Mode = LOT_MODE_RISK_PERCENT`
2. Set `Input_Hybrid_Risk_Percent = 1.0`
3. Wait for valid signal and trade execution
4. Check lot size in Terminal

**Expected Result:**
- Lot size calculated from account balance and risk %
- Log shows: `Lots: X.XX (1.0% Risk)`

**Actual Result:**
- Lot Size: _________________

---

### UT-009: ExecuteHybridTrade - Fixed Lot Mode
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Set `Input_Hybrid_Lot_Mode = LOT_MODE_FIXED_LOTS`
2. Set `Input_Hybrid_Fixed_Lots = 0.05`
3. Wait for valid signal and trade execution
4. Check lot size in Terminal

**Expected Result:**
- Lot size = exactly 0.05 lots
- Log shows: `Lots: 0.05 (Fixed)`

**Actual Result:**
- Lot Size: _________________

---

### UT-010: ExecuteOrderWithLot - Direct Lot Specification
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Set `Input_Hybrid_Lot_Mode = LOT_MODE_FIXED_LOTS`
2. Set `Input_Hybrid_Fixed_Lots = 0.05`
3. Execute trade (manual or auto)
4. Verify lot size

**Expected Result:**
- Trade executed with exactly 0.05 lots
- No adjustment/capping in logs

**Actual Result:** _________________

---

### UT-011: ExecuteOrderWithLot - Minimum Lot Validation
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Set `Input_Hybrid_Fixed_Lots = 0.001` (below minimum for Gold)
2. Try to execute trade
3. Check logs

**Expected Result:**
- Log shows: `Lot size adjusted to minimum: 0.01`
- Trade executed with minimum lot size

**Actual Result:** _________________

---

### UT-012: ExecuteOrderWithLot - Maximum Lot Cap
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Set `Input_Hybrid_Fixed_Lots = 50.0` (above safety cap)
2. Try to execute trade
3. Check logs

**Expected Result:**
- Log shows: `CRITICAL: Lot size capped at absolute safety maximum`
- Trade executed with max 10.0 lots

**Actual Result:** _________________

---

## Integration Tests

### IT-001: Hybrid Mode + Auto Trading
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Enable: `Input_Enable_Hybrid_Mode = true`
2. Enable: `Input_Auto_Arrow = true`
3. Wait for valid signal
4. Observe execution

**Expected Result:**
- Signal generated
- Trade executed automatically (no manual click)
- Arrow appears on chart: "HYBRID_Buy" or "HYBRID_Sell"

**Actual Result:** _________________

---

### IT-002: Hybrid Mode + Sniper Mode Priority
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Enable: `Input_Enable_Hybrid_Mode = true`
2. Enable: `Input_Enable_Sniper_Mode = true`
3. Check logs and behavior

**Expected Result:**
- Sniper Mode takes priority (Hybrid disabled)
- Log shows: `[Hybrid disabled - Sniper Mode is ON]`
- Only Sniper signals generated

**Actual Result:** _________________

---

### IT-003: Dashboard Button Toggle
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Click "HYBRID" button on dashboard
2. Verify state change
3. Click again to toggle off

**Expected Result:**
- Button toggles ON/OFF
- `g_hybrid_mode_enabled` variable updates
- Log shows: `HYBRID MODE: ENABLED` or `DISABLED`

**Actual Result:** _________________

---

### IT-004: Status Indicator Updates
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Enable Hybrid Mode
2. Wait for M15 trend alignment (score ≥ 2 or ≤ -2)
3. Check status (if dashboard has indicator)

**Expected Result:**
- Status shows "READY" when M15 context aligned
- Status shows "WAIT" when M15 context not ready
- Log prints: `HYBRID Status Update: Ready=YES/NO Bias=BULLISH/BEARISH/NEUTRAL`

**Actual Result:** _________________

---

### IT-005: Arrow Creation on Signal
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Enable Hybrid Mode + Debug Mode
2. Wait for valid signal
3. Check chart for arrow

**Expected Result:**
- Green arrow (code 241) below candle for BUY signals
- Red arrow (code 242) above candle for SELL signals
- Arrow label: "HYBRID_Buy" or "HYBRID_Sell"

**Actual Result:** _________________

---

### IT-006: Trade Execution in Auto Mode
**Status:** ⬜ Pass / ❌ Fail

**Test Steps:**
1. Enable Hybrid + Auto
2. Set appropriate risk parameters
3. Wait for valid signal
4. Check Terminal > Trade tab

**Expected Result:**
- Position opens with correct SL/TP
- Magic number matches `Input_MagicNumber`
- Comment includes "HYBRID_"

**Actual Result:** _________________

---

## Scenario Tests (Real Market Conditions)

### SC-001: M15 Bullish + M5 Hammer
**Status:** ⬜ Pass / ❌ Fail

**Market Setup:**
- H4: UPTREND
- H1: UPTREND
- M15: UPTREND (score ≥ +2)
- M5: Hammer pattern appears

**Expected Result:**
- ✅ HYBRID_BUY signal generated
- ✅ Trade executed (if AUTO ON)
- ✅ Log shows context: "BULLISH"

**Actual Result:** _________________

---

### SC-002: M15 Bearish + M5 Engulfing
**Status:** ⬜ Pass / ❌ Fail

**Market Setup:**
- H4: DOWNTREND
- H1: DOWNTREND
- M15: DOWNTREND (score ≤ -2)
- M5: Bearish Engulfing appears

**Expected Result:**
- ✅ HYBRID_SELL signal generated
- ✅ Trade executed (if AUTO ON)
- ✅ Log shows context: "BEARISH"

**Actual Result:** _________________

---

### SC-003: M15 Flat + M5 Hammer (No Signal)
**Status:** ⬜ Pass / ❌ Fail

**Market Setup:**
- H4: UPTREND
- H1: FLAT
- M15: FLAT (score = 0 or ±1)
- M5: Hammer pattern appears

**Expected Result:**
- ❌ NO signal generated
- ✅ Log shows: "CONTEXT NOT READY"
- ✅ No trade executed

**Actual Result:** _________________

---

### SC-004: Price Extended from EMA (No Signal)
**Status:** ⬜ Pass / ❌ Fail

**Market Setup:**
- M15: BULLISH (aligned)
- Price > 0.5 * ATR away from M15 EMA 20 (extended)
- M5: Hammer pattern appears

**Expected Result:**
- ❌ NO signal generated
- ✅ Log shows: "LOCATION FILTER: Price too far from EMA"
- ✅ No trade executed

**Actual Result:** _________________

---

### SC-005: Crash Slope Protection (No Buy)
**Status:** ⬜ Pass / ❌ Fail

**Market Setup:**
- M15: SLOPE_CRASH (steep downtrend)
- M5: Hammer pattern appears

**Expected Result:**
- ❌ NO BUY signal generated
- ✅ Log shows: "FALLING KNIFE: Slope protection"
- ✅ No trade executed

**Actual Result:** _________________

---

### SC-006: Choppy Market Filter
**Status:** ⬜ Pass / ❌ Fail

**Market Setup:**
- M15: ADX < 20 (choppy/ranging)
- M5: Any PA pattern appears

**Expected Result:**
- ❌ NO signal generated
- ✅ Log shows: "CHOPPY MARKET: Skipped"
- ✅ No trade executed

**Actual Result:** _________________

---

## Performance Tests

### PT-001: Signal Frequency
**Target:** 3-5 signals per day
**Test Period:** 5 days
**Status:** ⬜ Pass / ❌ Fail

| Day | Signals | Notes |
|-----|---------|-------|
| 1 | ___ | |
| 2 | ___ | |
| 3 | ___ | |
| 4 | ___ | |
| 5 | ___ | |
| **Total** | **___** | |

**Result:** ___ signals/day (Pass if 3-5 range)

---

### PT-002: Win Rate
**Target:** >50%
**Sample Size:** 20 trades
**Status:** ⬜ Pass / ❌ Fail

| Trade | Result | P/L (pts) |
|-------|--------|-----------|
| 1 | ✅/❌ | ___ |
| 2 | ✅/❌ | ___ |
| 3 | ✅/❌ | ___ |
| ... | ... | ... |
| 20 | ✅/❌ | ___ |
| **Total** | **___/20** | **___%** |

**Result:** ___% win rate (Pass if >50%)

---

### PT-003: CPU Usage
**Target:** <5% increase from baseline
**Status:** ⬜ Pass / ❌ Fail

**Baseline CPU (EA off):** ___%
**CPU with Hybrid Mode ON:** ___%
**Increase:** ___%

**Result:** ⬜ Pass (<5%) / ❌ Fail (≥5%)

---

### PT-004: Memory Leaks
**Target:** No memory growth over time
**Status:** ⬜ Pass / ❌ Fail

**Test Method:**
1. Run EA for 24 hours
2. Check Task Manager > metaeditor64.exe > Memory
3. Record memory at start and end

**Start Memory:** ___ MB
**End Memory:** ___ MB
**Growth:** ___ MB

**Result:** ⬜ Pass (<100MB growth) / ❌ Fail (≥100MB)

---

## Test Summary

### Unit Tests
- **Passed:** ___ / 12
- **Failed:** ___ / 12
- **Pass Rate:** ___%

### Integration Tests
- **Passed:** ___ / 6
- **Failed:** ___ / 6
- **Pass Rate:** ___%

### Scenario Tests
- **Passed:** ___ / 6
- **Failed:** ___ / 6
- **Pass Rate:** ___%

### Performance Tests
- **Passed:** ___ / 4
- **Failed:** ___ / 4
- **Pass Rate:** ___%

### Overall Status
- **Total Tests:** 28
- **Passed:** ___
- **Failed:** ___
- **Overall Pass Rate:** ___%

**Recommendation:**
- ⬜ **PASS** - Deploy to live account
- ❌ **FAIL** - Fix critical bugs before deployment
- ⚠️ **CONDITIONAL** - Deploy with monitoring (document known issues)

---

## Bugs Found

| ID | Description | Severity | Status |
|----|-------------|----------|--------|
| BUG-001 | | ⬜ Critical / ⬜ Major / ⬜ Minor | ⬜ Open / ⬜ Fixed |
| BUG-002 | | ⬜ Critical / ⬜ Major / ⬜ Minor | ⬜ Open / ⬜ Fixed |

---

## Notes & Observations

```
[Add any notes, unexpected behaviors, or suggestions for improvement here]
```

---

**Test Completed By:** _________________
**Date:** _________________
**Signature:** _________________
