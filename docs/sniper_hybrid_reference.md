# Sniper & Hybrid Mode Reference Guide

> **Document Purpose**: Reference for Sniper and Hybrid mode logic, differences, and configuration.
> **Last Updated**: 2025-01-10
> **Status**: Active Development

---

## Table of Contents

1. [Quick Summary](#quick-summary)
2. [Bug Fixes](#bug-fixes)
3. [Sniper Mode](#sniper-mode)
4. [Hybrid Mode](#hybrid-mode)
5. [Mode Comparison](#mode-comparison)
6. [Configuration Guide](#configuration-guide)
7. [Debugging Tips](#debugging-tips)

---

## Quick Summary

| Mode | Timeframe | Style | Trade Frequency | Best For |
|------|-----------|-------|-----------------|----------|
| **Sniper** | M15 | Pattern-based | Low (every 15min) | Reversals at zones |
| **Hybrid** | M15+M5 | Trend-following | Medium (every 5min) | Trend continuation |

---

## Bug Fixes

### ✅ Fixed: Hybrid Trend Score Bug (2025-01-10)

**Problem**: Trend score requirement was impossible to reach.

```
Before: Input_Hybrid_Trend_MinScore = 2.0
After:  Input_Hybrid_Trend_MinScore = 1.0
```

**Why it was wrong**: With 3 timeframes (H4, H1, M15), the trend score can only be:
- `+3` = All bullish
- `+1` = 2 bullish, 1 bearish
- `-1` = 1 bullish, 2 bearish
- `-3` = All bearish

**The score can NEVER be ±2!** It's always odd.

**Impact**: With `minScore = 2.0`, Hybrid would only trigger when ALL 3 TFs aligned (score = ±3), which almost never happens.

**File**: `MQL5/Experts/DJay_Assistant/DJay_Smart_Assistant.mq5:33`

---

### ✅ Fixed: Stale Indicator Data Bug (2025-01-10)

**Problem**: Cockpit showed `Trend Matrix: ↑↑↑ (score +3)` but Experts log said `"No clear trend bias (score=0)"`

**Root Cause**: Hybrid and Sniper calculated trend matrices using **stale indicator data**. The cockpit was updated every 1 second with fresh data, but Hybrid/Sniper used old cached indicator values.

**Fix**: Added `RefreshData()` call before both signal calculations:

```cpp
// Before Sniper signal (line 380)
signalEngine.RefreshData();

// Before Hybrid signal (line 431)
signalEngine.RefreshData();
```

**Impact**: Now both modes use fresh indicator data matching the cockpit display.

**Files**:
- `MQL5/Experts/DJay_Assistant/DJay_Smart_Assistant.mq5:380`
- `MQL5/Experts/DJay_Assistant/DJay_Smart_Assistant.mq5:431`

---

### ✅ Added: M5 PA Display in Market Intelligence (2025-01-10)

**Feature**: Added M5 PA signal display to the cockpit Market Intelligence section.

**What's Added**:
- M5 PA label and value in MOMENTUM column (below M15 PA)
- Hybrid Status indicator in RISK column showing READY/WAIT/MISMATCH states

**Purpose**: Traders can now see when Hybrid mode has a trigger ready (M5 PA + M15 trend alignment).

**Files**:
- `MQL5/Include/DJay_Assistant/DashboardPanel.mqh:302-307`
- `MQL5/Include/DJay_Assistant/DashboardPanel.mqh:326-327`
- `MQL5/Include/DJay_Assistant/DashboardPanel.mqh:1737-1968`

---

### ✅ Fixed: Removed Debug Messages (2025-01-10)

**Changes**:
- Commented out "DEBUG: Dashboard Panel v5.0 Loaded" message
- Commented out "TREND DEBUG (EMA 50)" periodic debug output
- Commented out order execution prints ("Buy order executed", "Sell order executed", etc.)
- Removed Test Tools section from dashboard

**Files**:
- `MQL5/Include/DJay_Assistant/DashboardPanel.mqh:233`
- `MQL5/Include/DJay_Assistant/SignalEngine.mqh:1417-1425`
- `MQL5/Include/DJay_Assistant/TradeManager.mqh:411,457,506`

---

## Sniper Mode

### How It Works

Sniper mode uses a **3-filter stack** on M15 timeframes:

```
┌─────────────────────────────────────────────────┐
│  SNIPER MODE FILTERS                            │
├─────────────────────────────────────────────────┤
│  1️⃣  PATTERN: M15 PA (Hammer/Star/Engulfing)  │
│  2️⃣  PULLBACK: Price within ATR×0.5 of M15 EMA │
│  3️⃣  VOLUME: Candle body ≥ ATR × 1.0           │
│  4️⃣  STRUCTURE: Signal touched a zone         │
└─────────────────────────────────────────────────┘
```

### Key Characteristics

| Aspect | Detail |
|--------|--------|
| **Trend Check** | ❌ NONE - works in any trend |
| **Entry Trigger** | M15 new bar with PA pattern |
| **Trade Frequency** | Every ~15 minutes (when conditions met) |
| **Style** | Counter-trend OR trend-following |
| **Risk** | Dynamic SL based on ATR |

### Input Parameters

```cpp
// Sniper Settings
Input_Enable_Sniper_Mode     = false   // Enable Sniper Mode
Input_Sniper_Debug_Mode      = false   // Debug logging
Input_Sniper_ATR_Multiplier  = 1.5     // Dynamic SL multiplier
Input_Sniper_Zone_Tolerance  = 50.0    // Structure proximity (points)
Input_Sniper_BE_Trigger_Pts  = 200.0   // Break-even trigger (points)
Input_Sniper_BE_Padding_Pts  = 10.0    // Break-even SL padding
Input_Sniper_Trail_Mult      = 1.0     // Smart Trail multiplier
Input_Sniper_Trail_Min_Profit = 200.0  // Min profit before trail
Input_Sniper_ADX_Trend_Min   = 25      // ADX threshold for trending
Input_Sniper_ADX_Range_Max   = 20      // ADX threshold for ranging
```

---

## Hybrid Mode

### How It Works

Hybrid mode uses **M15 context + M5 entry trigger**:

```
┌─────────────────────────────────────────────────┐
│  HYBRID MODE FILTERS                            │
├─────────────────────────────────────────────────┤
│  STEP 1: M15 CONTEXT (Permission Layer)         │
│  ├── Trend: H4+H1+M15 score ≥ 1 (2/3 aligned)  │
│  ├── Market: Not choppy (ADX check)             │
│  ├── Volatility: Valid ATR > 0                  │
│  └── Bias: Bullish or Bearish                   │
│                                                 │
│  STEP 2: M5 ENTRY (Trigger Layer)               │
│  ├── Pattern: M5 PA (Hammer/Star/Engulfing)    │
│  ├── Location: Within ATR×0.5 of M15 EMA       │
│  ├── Direction: M5 signal matches M15 bias     │
│  └── Slope Safety: No crash (BUY) or rocket    │
└─────────────────────────────────────────────────┘
```

### Why It Can Trigger Multiple Times

```
M15 BAR START (New trend bias set: BULLISH)
    │
    ├── M5 Bar #1 (5 min later)
    │   └── ✅ Can trigger if M5 has BUY signal
    │
    ├── M5 Bar #2 (10 min later)
    │   └── ✅ Can trigger if M5 has BUY signal
    │
    └── M5 Bar #3 (15 min later)
        └── ✅ Can trigger if M5 has BUY signal

NEW M15 BAR (Bias re-evaluated)
```

**Hybrid can fire up to 3 times per M15 period!**

### Input Parameters

```cpp
// Hybrid Settings
Input_Enable_Hybrid_Mode    = false   // Enable Hybrid Mode
Input_Hybrid_TP_Points      = 225     // Take Profit (points)
Input_Hybrid_SL_Points      = 150     // Stop Loss (points)
Input_Hybrid_EMA_MaxDist    = 0.5     // Max EMA distance (ATR mult)
Input_Hybrid_UseTrendFilter = true    // Require M15 trend alignment
Input_Hybrid_MinATR         = 50      // Minimum M15 ATR
Input_Hybrid_Debug_Mode     = false   // Debug logging ⚠️ ENABLE FOR TESTING
Input_Hybrid_Trend_MinScore = 1.0     // Min trend score (FIXED from 2.0)
Input_Hybrid_Lot_Mode       = LOT_MODE_RISK_PERCENT
Input_Hybrid_Risk_Percent   = 1.0     // Risk % per trade
```

---

## Mode Comparison

### Decision Matrix

| Scenario | Use Sniper | Use Hybrid |
|----------|-----------|------------|
| Trending market | ✅ Good | ✅✅ Best |
| Ranging market | ✅✅ Best | ❌ Poor |
| Strong reversal | ✅✅ Best | ❌ Won't trigger |
| Uncertain trend | ✅ Good | ⚠️ Needs alignment |
| High volatility | ✅ Good | ✅ Good |
| Low volatility | ❌ Few signals | ❌ Won't trigger |

### Filter Count Comparison

| Mode | Filters | Strictness |
|------|---------|------------|
| **Sniper** | 4 | Medium |
| **Hybrid** | 6+ | High |

### When Each Mode Triggers

```
                    ┌─────────────────────────────────────┐
                    │         MARKET CONDITIONS           │
                    └─────────────────────────────────────┘
                                       │
           ┌───────────────────────────┼───────────────────────────┐
           │                           │                           │
           ▼                           ▼                           ▼
    ┌─────────────┐            ┌─────────────┐            ┌─────────────┐
    │  CHOPPY     │            │  TRENDING   │            │  REVERSAL   │
    │  (ADX < 20) │            │  (ADX > 25) │            │  at ZONE    │
    └─────────────┘            └─────────────┘            └─────────────┘
           │                           │                           │
           ▼                           ▼                           ▼
    ┌─────────────┐            ┌─────────────┐            ┌─────────────┐
    │  Hybrid:    │            │  Hybrid:    │            │  Sniper:    │
    │  ❌ BLOCKED │            │  ✅ ACTIVE  │            │  ✅ ACTIVE  │
    │  Sniper:    │            │  Sniper:    │            │  Hybrid:    │
    │  ✅ ACTIVE  │            │  ✅ ACTIVE  │            │  ❌ BLOCKED │
    └─────────────┘            └─────────────┘            └─────────────┘
```

---

## Configuration Guide

### Recommended Settings by Market Type

#### Ranging Market (ADX < 20)
```cpp
// Use Sniper only
Input_Enable_Sniper_Mode  = true
Input_Enable_Hybrid_Mode  = false
```

#### Trending Market (ADX > 25)
```cpp
// Enable both for maximum signals
Input_Enable_Sniper_Mode  = true
Input_Enable_Hybrid_Mode  = true
```

#### Testing/Debugging
```cpp
// Enable debug modes
Input_Sniper_Debug_Mode   = true
Input_Hybrid_Debug_Mode   = true  // ⚠️ Check Experts log for rejection reasons
```

### EMA Filter Tuning

| Setting | Effect | Use When |
|---------|--------|----------|
| `0.3` | Very tight | Conservative/picky entries |
| `0.5` | Standard | Default (current) |
| `1.0` | Moderate | More trade opportunities |
| `1.5` | Loose | Aggressive trend following |

**Recommendation**: Start with `0.5` and increase if not getting enough signals.

---

## Debugging Tips

### Enable Debug Mode

**In MetaTrader:**
1. Press F7 (or right-click chart → Properties)
2. Go to **Inputs** tab
3. Set `Input_Hybrid_Debug_Mode = true`
4. Click OK

### Check Experts Log for These Messages

```
✅ VALID SIGNALS:
"HYBRID: VALID BUY SIGNAL - M15 Bullish (score=2) + M5 Trigger @ 1.0850"
"SNIPER BUY executed at 1.0850"

❌ REJECTIONS:
"HYBRID: No clear trend bias (score=0) - WAIT"
"HYBRID: Market is CHOPPY - wait"
"HYBRID: Price too far from M15 EMA (250 pts, max=75 pts) - WAIT FOR PULLBACK"
"HYBRID: BUY signal rejected - M15 slope is CRASH (falling knife)"
"[Sniper Filter] REJECTED: Price 150 pts ABOVE EMA (not at value)"
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| **Cockpit trend differs from Experts log** | Stale indicator data in Hybrid/Sniper | ✅ FIXED - RefreshData() now called before signals |
| **No Hybrid signals for days** | Trend score was 2.0 (impossible) | ✅ FIXED - Now 1.0 |
| **No Hybrid signals** | Price too far from EMA | Increase `Input_Hybrid_EMA_MaxDist` to 1.0 |
| **No Hybrid signals** | Market is choppy | Wait for trending market or use Sniper |
| **Sniper triggers but Hybrid doesn't** | M5 PA not forming | Normal - Sniper uses M15, Hybrid needs M5 |
| **Both modes not triggering** | Check if Auto Mode is ON | Set `Input_Auto_Arrow = true` or test manually |
| **Debug messages cluttering Experts log** | Too many debug prints | ✅ FIXED - Most debug messages removed |

### Coordination Logic

```
┌─────────────────────────────────────────────────────┐
│  SNIPER + HYBRID COORDINATION                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  M15 NEW BAR → Sets trend bias                      │
│       │                                             │
│       ├── If Sniper enabled ─────────────────┐     │
│       │     └── Checks M15 PA pattern         │     │
│       │     └── If valid → SNIPER TRADE      │     │
│       │                                       │     │
│       └── If Hybrid enabled ─────────────┐   │     │
│             └── Uses trend bias         │   │     │
│             └── Waits for M5 bar         │   │     │
│             └── If M5 PA matches bias    │   │     │
│                 └── HYBRID TRADE        │   │     │
│                                          │   │     │
│  RULE: Sniper takes priority per M15     │   │     │
│  cycle. If Sniper executes, Hybrid       │   │     │
│  waits for next M15 cycle.               │   │     │
│                                          │   │     │
└──────────────────────────────────────────┼───┼─────┘
                                           │   │
                                    Both can │   │
                                    coexist  │   │
                                    in the   │   │
                                    same M15 │   │
                                    cycle    │   │
                                             │
```

---

## Testing Checklist

After fixing the trend score bug, test the following:

- [ ] Recompile EA (F7 in MetaEditor)
- [ ] Enable Hybrid Mode in Inputs
- [ ] Enable Hybrid Debug Mode
- [ ] Watch for "HYBRID: VALID" messages in Experts log
- [ ] Verify M15 PA shows in cockpit
- [ ] Verify trades execute when conditions are met
- [ ] Check if Hybrid triggers on M5 bars (not just M15)

---

## Code References

| File | Lines | Description |
|------|-------|-------------|
| `DJay_Smart_Assistant.mq5` | 26-33 | Hybrid input parameters |
| `DJay_Smart_Assistant.mq5` | 51-61 | Sniper input parameters |
| `DJay_Smart_Assistant.mq5` | 421-464 | Hybrid execution logic |
| `DJay_Smart_Assistant.mq5`` | 377-413 | Sniper execution logic |
| `SignalEngine.mqh` | 1604-1753 | `GetSniperSignal()` function |
| `SignalEngine.mqh` | 1805-1936 | `GetHybridSignal()` function |
| `DashboardPanel.mqh` | 1737-1820 | Market Intelligence Grid update |

---

## Notes

- **Hybrid mode was implemented in Sprint 6**
- **Trend score bug fixed on 2025-01-10** (2.0 → 1.0)
- **Stale indicator data bug fixed on 2025-01-10** (RefreshData() added before signals)
- **M5 PA display added to Market Intelligence on 2025-01-10**
- **Debug messages removed from codebase on 2025-01-10**
- **Test tools removed from dashboard on 2025-01-10**

---

## Market Intelligence Dashboard Layout

The Market Intelligence grid displays real-time market data for both Sniper and Hybrid modes:

```
┌─────────────┬─────────────┬─────────────┐
│  CONTEXT    │  MOMENTUM   │    RISK     │
├─────────────┼─────────────┼─────────────┤
│ ● BULLISH   │ M15: NONE   │ ATR: 100    │
│ H4: ↑       │ M5:  BUY    │ EMA: 50 pts │
│ H1: ↑       │ RSI: 48.9   │ HYBRID: READY│
│ M15: ↑      │ Stoch: 44.4 │ To Zone: 25 │
│ ACTION: READY│ Slope: UP   │ ADX: 28.5   │
└─────────────┴─────────────┴─────────────┘
```

### Hybrid Status States

| Status | Color | Meaning |
|--------|-------|---------|
| **READY** | 🟢 Lime | Trend aligned + M5 PA matches bias - Ready to trade! |
| **WAIT M5** | 🟡 Yellow | Trend aligned but waiting for M5 trigger |
| **MISMATCH** | 🟠 Orange | M5 PA signal opposite to trend bias |
| **NO TREND** | 🔴 Red | No clear trend (score = 0) |
| **OFF** | ⚫ Gray | Default/Disabled |

---

*Generated for EA Helper Project*
