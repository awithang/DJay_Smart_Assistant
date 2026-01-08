# Sprint 6 Test Buttons - User Guide

## Overview

Five (5) test buttons have been added to the dashboard for Hybrid Mode testing. These buttons allow you to quickly inspect the EA's internal state, verify signal detection logic, and test trade calculations without waiting for natural market conditions.

---

## Button Locations

The test buttons are located in the **TEST TOOLS** section on the dashboard, below the QUICK SCALP section.

```
┌─────────────────────────────────────┐
│  QUICK SCALP:    ● OFF              │
├─────────────────────────────────────┤
│  TEST TOOLS:                        │
│  ┌──────────┐  ┌──────────┐         │
│  │  STATE   │  │ SIGNAL   │         │
│  └──────────┘  └──────────┘         │
│  ┌──────────┐  ┌──────────┐         │
│  │ FILTERS  │  │  TRADE   │         │
│  └──────────┘  └──────────┘         │
│  ┌──────────────────────────┐       │
│  │       LOT CALC           │       │
│  └──────────────────────────┘       │
└─────────────────────────────────────┘
```

---

## Button Functions

### 1. STATE Button
**Purpose:** Display complete Hybrid Mode internal state

**Output to Experts Log:**
```
========================================
    HYBRID MODE STATE DUMP
========================================
--- TREND MATRIX ---
H4 Trend:  TREND_UP
H1 Trend:  TREND_UP
M15 Trend: TREND_UP
Trend Score: 3 (Range: -3 to +3)

--- MARKET CONTEXT ---
Market State: STATE_TRENDING
ADX Value: 35.5
ATR M15: 850.0 points
ATR M5: 420.0 points

--- SLOPE ANALYSIS ---
H1 Slope: SLOPE_UP
Slope Value: 0.0035
EMA Distance: 45.0 points

--- HYBRID STATE ---
Context Ready: YES
Trend Bias: TREND_BIAS_BULLISH
Hybrid Mode: ENABLED
Sniper Mode: DISABLED
========================================
```

**Use When:**
- Checking if M15 trend alignment is sufficient
- Verifying market state (TRENDING vs CHOPPY)
- Checking if context is ready for trading
- Debugging why signals aren't appearing

---

### 2. SIGNAL Button
**Purpose:** Force immediate signal detection test

**Output to Experts Log:**
```
========================================
    TESTING HYBRID SIGNAL DETECTION
========================================
[M15 Context] Trend Score: 3 (≥2) → BULLISH
[M15 State] Market: TRENDING → OK
[M15 ATR] 850.0 pts ≥ 50 → OK
[M5 PA] Signal: SIGNAL_PA_BUY (Hammer)
[Location] Price: 4440.50, EMA: 4442.00, Dist: 15 pts ≤ 425 → OK
[Direction] Signal: BUY, Bias: BULLISH → MATCH
[Slope] H1: SLOPE_UP (not crash) → OK

✅ ALL FILTERS PASSED

SIGNAL RESULT: SIGNAL_PA_BUY
✅ HYBRID BUY signal detected - READY TO TRADE
========================================
```

**Use When:**
- Testing if current market conditions would generate a signal
- Verifying all 7 filters are working correctly
- Debugging why a signal was or wasn't generated
- Quick signal check without waiting for new M5 bar

---

### 3. FILTERS Button
**Purpose:** Show individual filter pass/fail status

**Output to Experts Log:**
```
========================================
    HYBRID FILTER STATUS
========================================
[1] TREND FILTER: ✅ PASS | Score: 3 (Need ±2+)
[2] MARKET STATE: ✅ PASS | STATE_TRENDING
[3] VOLATILITY: ✅ PASS | ATR: 850.0 (Min: 50)
[4] LOCATION: ✅ PASS | Dist: 15 pts (Max: 425 pts)
[5] SLOPE SAFETY:
    Buy Protection: ✅ PASS | SLOPE_UP
    Sell Protection: ✅ PASS | SLOPE_UP
---
OVERALL: ✅ ALL FILTERS PASS
========================================
```

**Use When:**
- Identifying which filter is blocking signals
- Quick filter status check
- Verifying filter parameters are configured correctly
- Debugging specific filter logic

---

### 4. TRADE Button
**Purpose:** Display SL/TP and trade parameter calculations

**Output to Experts Log:**
```
========================================
    TRADE CALCULATION TEST
========================================
--- BUY TRADE ---
Entry: 4442.50
SL: 4441.00 (Distance: -150 pts)
TP: 4443.50 (Distance: +100 pts)
Risk:Reward: 1:0.7

--- SELL TRADE ---
Entry: 4442.00
SL: 4443.50 (Distance: +150 pts)
TP: 4441.00 (Distance: -100 pts)
Risk:Reward: 1:0.7

--- LOT SIZE MODE ---
Mode: RISK PERCENT | Risk: 1.0%
========================================
```

**Use When:**
- Verifying SL/TP distances are correct
- Checking Risk:Reward ratio
- Confirming lot size mode (Risk% vs Fixed)
- Validating trade parameter calculations

---

### 5. LOT CALC Button
**Purpose:** Display lot size calculations and symbol limits

**Output to Experts Log:**
```
========================================
    LOT SIZE CALCULATION TEST
========================================
--- SYMBOL LIMITS ---
Min Lot: 0.01
Max Lot: 50.0
Lot Step: 0.01
Current Balance: $59566.0

--- RISK PERCENT MODE ---
Risk 0.5%: 0.40 lots
Risk 1.0%: 0.79 lots
Risk 1.5%: 1.19 lots
Risk 2.0%: 1.59 lots
Risk 2.5%: 1.99 lots
Risk 3.0%: 2.38 lots

--- FIXED LOT MODE ---
Configured: 0.05 lots
Validated: 0.05 lots
========================================
```

**Use When:**
- Verifying lot size calculations for different risk levels
- Checking symbol trading limits
- Testing fixed lot vs risk percent modes
- Validating lot size validation logic

---

## How to Use

### Step 1: Enable Expert Logs
1. In MetaTrader 5, go to **Tools > Options > Experts**
2. Check **Enable Expert Logs**
3. Click **OK**

### Step 2: Attach EA to Chart
1. Open XAUUSD (Gold) chart
2. Drag `DJay_Smart_Assistant` onto chart
3. Set inputs:
   - `Input_Enable_Hybrid_Mode = true`
   - Click **OK**

### Step 3: Open Experts Log
1. Go to **Tools > Experts > Logs**
2. Keep this window visible to see test output

### Step 4: Click Test Buttons
1. Click any test button on the dashboard
2. View output in Experts Log
3. Repeat for other buttons as needed

---

## Testing Scenarios

### Scenario 1: Verify Trend Alignment
**Goal:** Check if M15 trend is aligned for Hybrid Mode

1. Click **STATE** button
2. Check "Trend Score" in output
3. If score ≥ 2 or ≤ -2: Context READY
4. If score between -1 and +1: Context NOT READY

**Example Output:**
```
Trend Score: 3 (Range: -3 to +3)  ✅ READY
Trend Score: 0 (Range: -3 to +3)  ❌ NOT READY
```

---

### Scenario 2: Debug Why No Signal
**Goal:** Identify which filter is blocking signals

1. Click **SIGNAL** button
2. Read the filter-by-filter output
3. Identify which filter shows ❌ FAIL
4. Click **FILTERS** button for detailed status

**Example Output:**
```
[4] LOCATION: ❌ FAIL | Dist: 500 pts (Max: 425 pts)
```
→ Price is too far from EMA, no signal generated

---

### Scenario 3: Verify Trade Parameters
**Goal:** Confirm SL/TP distances are correct

1. Click **TRADE** button
2. Check SL/TP distances
3. Verify Risk:Reward ratio
4. Confirm lot size mode

**Example Output:**
```
SL: 4441.00 (Distance: -150 pts)  ✅ Correct
TP: 4443.50 (Distance: +100 pts)  ✅ Correct
Risk:Reward: 1:0.7  ✅ Correct
```

---

### Scenario 4: Test Lot Calculations
**Goal:** Verify lot size for different risk levels

1. Click **LOT CALC** button
2. Check risk percent calculations
3. Verify against symbol limits
4. Test fixed lot mode (if applicable)

**Example Output:**
```
Risk 1.0%: 0.79 lots  ✅ Within limits
Risk 2.0%: 1.59 lots  ✅ Within limits
Risk 3.0%: 2.38 lots  ✅ Within limits
```

---

## Tips & Best Practices

1. **Start with STATE** - Get an overview of the current market state first
2. **Use FILTERS for debugging** - Quickly identify which filter is blocking
3. **SIGNAL for quick checks** - Test if current conditions would generate a signal
4. **TRADE before live trading** - Verify SL/TP calculations match expectations
5. **LOT CALC for risk management** - Confirm lot sizes are within your risk tolerance

---

## Common Output Interpretations

### Trend Score
| Score | Interpretation | Action |
|-------|----------------|--------|
| +3 | Strong Bullish (all 3 TFs UP) | Context READY for BUY |
| +2 | Bullish (2/3 TFs UP) | Context READY for BUY |
| +1 | Weak Bullish | Wait for stronger alignment |
| 0 | Neutral | No context - DO NOT TRADE |
| -1 | Weak Bearish | Wait for stronger alignment |
| -2 | Bearish (2/3 TFs DOWN) | Context READY for SELL |
| -3 | Strong Bearish (all 3 TFs DOWN) | Context READY for SELL |

### Market State
| State | Interpretation | Action |
|-------|----------------|--------|
| STATE_TRENDING | ADX > 25, clear trend | ✅ Trade signals valid |
| STATE_RANGING | ADX < 20, no trend | ⚠️ Reduced signal quality |
| STATE_CHOPPY | Transition zone | ❌ NO SIGNALS (filter blocks) |

### Slope Direction
| Slope | Buy Signal | Sell Signal |
|-------|-----------|-------------|
| SLOPE_FLAT | ✅ Allowed | ✅ Allowed |
| SLOPE_UP | ✅ Allowed | ⚠️ Blocked (rocket) |
| SLOPE_DOWN | ⚠️ Blocked (crash) | ✅ Allowed |
| SLOPE_CRASH | ❌ BLOCKED | ✅ Allowed |
| SLOPE_ROCKET | ✅ Allowed | ❌ BLOCKED |

---

## Troubleshooting

**Q: I click the button but nothing happens**
A: Check that Experts log is open (Tools > Experts > Logs)

**Q: Output is truncated**
A: Click the "Maximize" button on Experts log window

**Q: All filters show FAIL**
A: Market conditions may not be suitable. Check if:
- Trend score is between -1 and +1 (no clear trend)
- ADX < 20 (choppy market)
- Price extended from EMA (>0.5 * ATR)

**Q: SIGNAL button shows NO SIGNAL but I think it should**
A:
1. Click FILTERS button to identify which filter blocked
2. Check if Sniper Mode is enabled (takes priority)
3. Verify Hybrid Mode is enabled
4. Check if waiting for new M5 bar (signals only update on new bar)

---

## Technical Details

### Implementation Files
- **DashboardPanel.mqh** - Button layout and click handlers
- **DJay_Smart_Assistant.mq5** - Test helper functions

### Test Functions
- `TestPrintHybridState()` - STATE button handler
- `TestHybridSignal()` - SIGNAL button handler
- `TestPrintFilters()` - FILTERS button handler
- `TestTradeCalculation()` - TRADE button handler
- `TestLotSizeCalculation()` - LOT CALC button handler

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-08 | Initial implementation - 5 test buttons added |

---

**Document:** test_buttons_guide.md
**Sprint:** 6 - Hybrid Mode
**Author:** Claude Code
**Last Updated:** 2026-01-08
