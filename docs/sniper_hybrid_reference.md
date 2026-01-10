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

### ✅ Fixed: Trend Score Calculation Bug (CRITICAL - 2025-01-10)

**Problem**: Cockpit showed `Trend Matrix: ↑↑↑` but Hybrid said `"No clear trend bias (score=0)"`

**Root Cause**: Hybrid calculated trend score by summing **enum values** instead of using the **calculated score**.

```cpp
// WRONG - Adding enum values (TREND_UP = 0 as first enum value)
int trendScore = tm.h4 + tm.h1 + tm.m15;  // 0 + 0 + 0 = 0

// CORRECT - Using calculated score
int trendScore = tm.score;  // 3 (when all 3 TFs are UP)
```

**Why it failed**: The `ENUM_TREND_DIRECTION` enum has:
- `TREND_UP = 0` (first enum value)
- `TREND_DOWN = 1`
- `TREND_FLAT = 2`

When all 3 timeframes were UP, adding enum values gave `0+0+0=0` instead of the correct score of `3`.

**Impact**: Hybrid was **completely broken** - could never detect trend alignment regardless of market conditions.

**File**: `MQL5/Include/DJay_Assistant/SignalEngine.mqh:1815`

---

### ✅ Fixed: Hybrid Trend Score Requirement (2025-01-10)

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

**Problem**: Cockpit and Hybrid were using different indicator data at different times.

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

Sniper mode uses a **4-filter stack** on M15 timeframes (Updated with Adaptive Filter):

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
"HYBRID: VALID BUY SIGNAL - M15 Bullish (score=3) + M5 Trigger @ 1.0850"
"HYBRID: VALID BUY SIGNAL - M15 Bullish (score=1) + M5 Trigger @ 1.0850"
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

## Cockpit Redesign Proposal (2025-01-10)

### Problem Statement

Current cockpit mixes manual trading indicators with auto-mode status, causing:
1. **Clutter**: Manual traders see auto-mode info they don't need
2. **Confusion**: Auto traders can't see why modes are blocked
3. **Inefficiency**: No clear separation of concerns

### Proposed Solution: Split into 2 Sections

```
┌─────────────────────────────────────────────────────────────────┐
│  MARKET INTELLIGENCE                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  MARKET SNAPSHOT (For Everyone - Manual + Auto)          │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  CONTEXT:  ● BULLISH (↑↑↑)  ADX: 28.5 (Trending)        │  │
│  │  M15 PA:   BUY              M5 PA:    BUY                │  │
│  │  RSI:      55 (Neutral)     Stoch:    48 (Neutral)       │  │
│  │  Slope:    UP               EMA 20:   +150 pts           │  │
│  │  ATR:      180 pts          To Zone:  25 pts             │  │
│  │  Action:   HYBRID READY                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  AUTO MODE STATUS (Auto Traders Only)                    │  │
│  ├───────────────────┬──────────────────────────────────────┤  │
│  │  SNIPER           │  ⚪ OFF                               │  │
│  │                   │  ┌─────────────────────────────────┐  │  │
│  │                   │  │  PA: [✓]  LOC: [✓]  VOL: [✓]   │  │  │
│  │                   │  │  ZONE: [?]  Status: OFF         │  │  │
│  │                   │  └─────────────────────────────────┘  │  │
│  ├───────────────────┼──────────────────────────────────────┤  │
│  │  HYBRID           │  🟢 ON                                │  │
│  │                   │  ┌─────────────────────────────────┐  │  │
│  │                   │  │  Trend: [✓ score=3]  ADX: [✓]  │  │  │
│  │                   │  │  M5: [✓ BUY]  Status: READY    │  │  │
│  │                   │  └─────────────────────────────────┘  │  │
│  └───────────────────┴──────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Section 1: MARKET SNAPSHOT (Top)

Essential trading information for **both manual and auto traders**:

| Indicator | Purpose |
|-----------|---------|
| **CONTEXT + ADX** | Overall trend direction + market state (trending/ranging) |
| **M15 PA + M5 PA** | Price action signals (Sniper uses M15, Hybrid uses M5) |
| **RSI + Stoch** | Timing entries, spotting OB/OS conditions (manual traders) |
| **Slope** | Momentum direction (Hybrid safety check) |
| **EMA 20 Distance** | Pullback/extension detection (both modes use M15 EMA 20 internally) |
| **ATR** | Volatility measurement (position sizing, SL/TP) |
| **To Zone** | Distance to support/resistance (Sniper filter) |
| **Action** | Summary: READY/WAIT based on conditions |

**Why keep RSI/Stoch?** Manual traders use them for timing entries. Auto modes don't use them, but they're valuable for human decision-making.

### Section 2: AUTO MODE STATUS (Bottom)

Shows which auto modes are enabled and their **filter states**:

```
┌──────────┬─────────────────────────────────────────────────────────┐
│  MODE    │  STATUS                                                  │
├──────────┼─────────────────────────────────────────────────────────┤
│  SNIPER  │  ⚪ OFF / 🟢 ON                                         │
│          │  ┌─────────────────────────────────────────────────┐    │
│          │  │  Filter States:                                  │    │
│          │  │  PA: [✓ PASS] or [❌ NO PATTERN]                 │    │
│          │  │  LOC: [✓ PASS] or [❌ TOO FAR (711 pts)]         │    │
│          │  │  VOL: [✓ PASS] or [❌ LOW VOLUME]                │    │
│          │  │  ZONE: [✓ TOUCHED] or [❌ NOT IN ZONE]           │    │
│          │  │  Status: READY / BLOCKED (reason)                │    │
│          │  └─────────────────────────────────────────────────┘    │
├──────────┼─────────────────────────────────────────────────────────┤
│  HYBRID  │  ⚪ OFF / 🟢 ON                                         │
│          │  ┌─────────────────────────────────────────────────┐    │
│          │  │  Filter States:                                  │    │
│          │  │  Trend: [✓ score=3] or [❌ NO TREND (score=0)]  │    │
│          │  │  ADX: [✓ NOT CHOPPY] or [❌ CHOPPY (ADX 15)]    │    │
│          │  │  ATR: [✓ VALID] or [❌ TOO LOW]                  │    │
│          │  │  M5: [✓ BUY] or [⏳ WAIT M5] or [❌ MISMATCH]   │    │
│          │  │  Status: READY / WAIT M5 / MISMATCH / OFF       │    │
│          │  └─────────────────────────────────────────────────┘    │
└──────────┴─────────────────────────────────────────────────────────┘
```

### Benefits

| Benefit | Manual Traders | Auto Traders |
|---------|----------------|--------------|
| **Cleaner UI** | Only see market data, no auto clutter | See exactly what's blocking trades |
| **Better Debugging** | N/A | Instantly see which filter failed |
| **Faster Decisions** | Clear market snapshot | Know when modes will trigger |
| **Less Confusion** | No irrelevant auto mode status | Clear filter states per mode |

### Key Notes

1. **"Quick Scalp" is the OLD name** - The correct name is **HYBRID mode** (M15 context + M5 entry trigger)

2. **Trend score is always odd** - With 3 timeframes, score can only be:
   - `+3` = All bullish
   - `+1` = 2 bullish, 1 bearish
   - `-1` = 1 bullish, 2 bearish
   - `-3` = All bearish
   - **Score is NEVER ±2**

3. **EMA 50 vs EMA 20**:
   - **EMA 50** = Trend direction (bullish/bearish based on price position)
   - **EMA 20** = Pullback filter (is price close enough to enter?)

4. **Manual trading indicators to keep**: RSI, Stoch, EMA Distance, Slope - these help manual traders time entries even though auto modes don't use them

---

## Trade Strategy Recommendation System

### Purpose

Translate all technical indicators into **natural language trading advice** that manual traders can understand and act upon immediately.

---

### Section 3: TRADE STRATEGY (Middle - For Manual Traders)

```
┌─────────────────────────────────────────────────────────────────┐
│  📊 TRADE STRATEGY                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  MARKET STATE                                                   │
│  ├─ Trend: Strong UPTREND (↑↑↑)  ADX: 32.5 (Trending)          │
│  ├─ Location: BUY2 Zone (+180 pts from EMA 20)                 │
│  └─ Momentum: RSI 72 (OB)  Stoch 78 (OB)  Slope: UP            │
│                                                                 │
│  ⚠️  RECOMMENDATION: WAIT FOR PULLBACK                         │
│                                                                 │
│  Price is overbought despite strong uptrend. Chasing here is   │
│  risky. Best entry: Wait for pullback to EMA 20 or RSI < 60.   │
│                                                                 │
│  📌 SUGGESTED ENTRY:                                            │
│     → BUY LIMIT at [EMA 20 value] or [current - 0.5×ATR]        │
│     → Alternative: Wait for RSI drop below 60                  │
│                                                                 │
│  🎯 TARGETS: TP [+ATR×1.5] | SL [-ATR×1.0] from entry          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### Recommendation Logic Matrix

The system analyzes **5 key factors** to generate recommendations:

| Factor | Condition | Weight |
|--------|-----------|--------|
| **Trend Strength** | Strong (score ±3), Moderate (score ±1), None (score 0) | High |
| **Market State** | Trending (ADX > 25), Ranging (ADX 20-25), Choppy (ADX < 20) | High |
| **Zone Location** | Favorable zone, Middle zone, Unfavorable zone | Medium |
| **Momentum State** | OB/OS (RSI > 70 or < 30), Neutral | Medium |
| **Price Extension** | Extended (> 0.5×ATR from EMA), At value (near EMA) | Medium |

---

### Scenario-Based Recommendations

#### Scenario 1: Strong Trend + Favorable Zone + Momentum OK = **FOLLOW TREND**

```
MARKET STATE:
├─ Trend: Strong UPTREND (↑↑↑)  ADX: 32
├─ Location: BUY2 Zone (+50 pts from EMA 20)
└─ Momentum: RSI 58  Stoch 55  Slope: UP

✅ RECOMMENDATION: BUY (Market Order)
Strong trend with price at value. Momentum supports continuation.

📌 SUGGESTED ENTRY:
   → BUY MARKET at current price
   → Or BUY LIMIT at [EMA 20 value] for safer entry

🎯 TARGETS: TP [+ATR×1.5] | SL [-ATR×1.0]
```

---

#### Scenario 2: Strong Trend + Favorable Zone + Momentum OB = **WAIT FOR PULLBACK**

```
MARKET STATE:
├─ Trend: Strong UPTREND (↑↑↑)  ADX: 35
├─ Location: BUY2 Zone (+120 pts from EMA 20)
└─ Momentum: RSI 76 (OB)  Stoch 82 (OB)  Slope: UP

⚠️ RECOMMENDATION: WAIT FOR PULLBACK
Strong trend but price is extended and overbought. Chasing is risky.

📌 SUGGESTED ENTRY:
   → BUY LIMIT at [current - 0.5×ATR] or [EMA 20 value]
   → Wait for RSI drop below 60 or Stoch drop below 70
   → Best entry: When price touches EMA 20

🎯 TARGETS: TP [+ATR×1.5] | SL [-ATR×1.0]
```

---

#### Scenario 3: Strong Trend + Unfavorable Zone = **WAIT FOR PULLBACK**

```
MARKET STATE:
├─ Trend: Strong UPTREND (↑↑↑)  ADX: 28
├─ Location: SELL2 Zone (+350 pts from EMA 20)
└─ Momentum: RSI 65  Stoch 62  Slope: UP

⏳ RECOMMENDATION: WAIT FOR PULLBACK TO BUY ZONE
Strong uptrend but price is too extended. Wait for pullback to buy zone.

📌 SUGGESTED ENTRY:
   → WAIT for pullback to BUY2 or BUY1 zone
   → BUY LIMIT at [EMA 20 - 0.3×ATR]
   → Do NOT chase the move

🎯 TARGETS: TP [+ATR×1.5] | SL [-ATR×1.0] from future entry
```

---

#### Scenario 4: Strong Trend + Unfavorable Zone + Momentum OB = **STAY OUT OR REVERSAL**

```
MARKET STATE:
├─ Trend: Strong UPTREND (↑↑↑)  ADX: 38
├─ Location: SELL2 Zone (+450 pts from EMA 20)
└─ Momentum: RSI 78 (OB)  Stoch 85 (OB)  Slope: UP

🔴 RECOMMENDATION: STAY OUT (High Risk)
Price is severely extended and overbought in uptrend.
Risk of sharp pullback is very high. NOT a good entry point.

📌 ALTERNATIVES:
   → WAIT for pullback to BUY zone (safer)
   → Experienced only: Consider SELL STOP below recent swing low
     (Counter-trend reversal play, high risk)

🎯 If Reversal: TP [+ATR×1.0] | SL [+ATR×0.5]
```

---

#### Scenario 5: Strong Downtrend + Favorable Zone + Momentum OK = **FOLLOW DOWNTREND**

```
MARKET STATE:
├─ Trend: Strong DOWNTREND (↓↓↓)  ADX: 30
├─ Location: SELL2 Zone (-60 pts from EMA 20)
└─ Momentum: RSI 42  Stoch 38  Slope: DOWN

✅ RECOMMENDATION: SELL (Market Order)
Strong downtrend with price at value. Momentum supports continuation.

📌 SUGGESTED ENTRY:
   → SELL MARKET at current price
   → Or SELL LIMIT at [EMA 20 value] for safer entry

🎯 TARGETS: TP [-ATR×1.5] | SL [+ATR×1.0]
```

---

#### Scenario 6: No Clear Trend = **RANGE TRADE OR STAY OUT**

```
MARKET STATE:
├─ Trend: NEUTRAL (→→→)  Score: 0
├─ Location: MIDDLE Zone (+15 pts from EMA 20)
└─ Momentum: RSI 52  Stoch 48  Slope: FLAT

⏸️ RECOMMENDATION: STAY OUT (No Trend)
No clear directional bias. Market is ranging.

📌 ALTERNATIVES (Range Trading Only):
   → Buy at BUY1 zone with TP at middle
   → Sell at SELL1 zone with TP at middle
   → Use tight stops (0.5×ATR)

🎯 Range Trade: TP [+ATR×0.8] | SL [-ATR×0.5]
```

---

#### Scenario 7: Choppy Market = **STAY OUT**

```
MARKET STATE:
├─ Trend: MIXED (↑↑↓)  Score: +1
├─ Location: MIDDLE Zone
└─ ADX: 18 (CHOPPY)

🔴 RECOMMENDATION: STAY OUT (Market is CHOPPY)
Low volatility means no meaningful moves. High whipsaw risk.

📌 ACTION: Do NOT trade. Wait for ADX > 20.
```

---

#### Scenario 8: Price Action Signal Present = **CONSIDER PA ENTRY**

```
MARKET STATE:
├─ Trend: Moderate UPTREND (↑↑→)  Score: +1
├─ Location: BUY2 Zone (+80 pts from EMA 20)
├─ Momentum: RSI 62  Stoch 58
└─ 🎯 M15 PA: HAMMER (Bullish) at SUPPORT

✅ RECOMMENDATION: BUY (PA Signal)
Price action pattern supports entry. Hammer at support is bullish.

📌 SUGGESTED ENTRY:
   → BUY STOP at [High of Hammer candle + 5 pts]
   → Or BUY LIMIT at [Hammer low - 5 pts]

🎯 TARGETS: TP [+ATR×1.5] | SL [-ATR×1.0] below hammer low
```

---

### Recommendation Codes (Quick Reference)

| Code | Meaning | Action |
|------|---------|--------|
| **✅ BUY** | Follow uptrend, good entry | Buy market or limit |
| **✅ SELL** | Follow downtrend, good entry | Sell market or limit |
| **⚠️ WAIT FOR PULLBACK** | Good trend but extended | Wait for price to return to EMA/value |
| **⏳ WAIT FOR ZONE** | Good trend but wrong location | Wait for price to reach favorable zone |
| **🔴 STAY OUT** | Bad conditions (choppy/OB+extended) | Do not trade |
| **⏸️ NO TREND** | Range-bound market | Range trade or stay out |
| **🎯 PA SIGNAL** | Price action pattern present | Trade the PA signal |

---

### Price Calculation Examples

The system calculates specific entry prices based on current values:

```
Example 1: BUY LIMIT Calculation
├─ Current Price: 1.0850
├─ ATR (M15): 180 points (0.00180)
├─ EMA 20: 1.0835
└─ Recommendation: BUY LIMIT at EMA 20
   → Entry: 1.0835
   → TP: 1.0835 + 180 = 1.0853
   → SL: 1.0835 - 180 = 1.0817

Example 2: SELL LIMIT Calculation
├─ Current Price: 1.0920
├─ ATR (M15): 200 points
├─ EMA 20: 1.0900
└─ Recommendation: Wait for pullback to SELL zone
   → Entry: 1.0900 (EMA 20)
   → TP: 1.0900 - 200 = 1.0880
   → SL: 1.0900 + 200 = 1.0920
```

---

### Natural Language Templates

The system uses these templates based on the detected scenario:

```
Template 1 - Follow Trend (Favorable):
"Strong [DIRECTION] trend with price at value zone.
Momentum supports continuation. Good entry point."

Template 2 - Wait for Pullback:
"Strong [DIRECTION] trend but price is extended.
Best entry: Wait for pullback to EMA 20 or [EMA 20 ± offset]."

Template 3 - Wait for Zone:
"Strong [DIRECTION] trend but price is in [UNFAVORABLE ZONE].
Wait for pullback to [FAVORABLE ZONE]. Do NOT chase."

Template 4 - Stay Out (Extended + OB):
"Price is [EXTENDED] and [OVERBOUGHT/OVERSOLD] in [DIRECTION] trend.
Chasing is very risky. Stay out or wait for deep pullback."

Template 5 - No Trend:
"No clear directional bias. Market is ranging.
Consider range trading at zone boundaries or stay out."

Template 6 - Choppy:
"Market is CHOPPY (ADX < 20). Low volatility, high whipsaw risk.
Stay out until trend develops (ADX > 25)."

Template 7 - PA Signal:
"[PATTERN NAME] detected at [SUPPORT/RESISTANCE].
Price action confirms entry. Good risk/reward setup."
```

---

### Implementation Priority

| Component | Priority | Notes |
|-----------|----------|-------|
| Basic recommendation logic | **P0** | Core scenarios (trend + zone + momentum) |
| Price calculations (entry/TP/SL) | **P0** | Actual values based on ATR |
| Zone detection | **P1** | Need zone indicator from zones.mqh |
| PA signal integration | **P1** | Include M15/M5 PA in recommendation |
| Natural language output | **P1** | Human-readable messages |
| Cockpit display section | **P2** | UI update to show recommendation |

---

## Cockpit Parameter Blocking Analysis

### 🔒 Parameters That Block Sniper/Hybrid

#### Mode Enablement Blockers
```
┌─────────────────────────────────────┐
│ AUTO MODE = [OFF]                   │  🔴 BLOCKS all auto trades
│ SNIPER MODE = [OFF]                  │  🔴 BLOCKS Sniper
│ HYBRID MODE = [ON]                   │  ✅ Hybrid enabled
└─────────────────────────────────────┘
```

#### Execution Filter Blockers
```
┌─────────────────────────────────────┐
│ AGGRESSIVE = [OFF]                  │  🔴 Safety filters ACTIVE
│                                        │
│ TREND FILTER = [ON] with [X]         │  🔴 Blocks counter-trend
│                                        │
│ ZONE FILTER = [ON] with [X]         │  🔴 Blocks trades in Middle zone
└─────────────────────────────────────┘
```

#### Market Condition Blockers
```
┌─────────────────────────────────────┐
│ M15 PA = NONE                        │  🔴 Sniper blocked (no pattern)
│ M5 PA = NONE                         │  🔴 Hybrid blocked (no trigger)
│ HYBRID STATUS = WAIT M5              │  ⏳ Hybrid waiting for M5 PA
│ ADX < 20                              │  🔴 Market is CHOPPY (Hybrid only)
└─────────────────────────────────────┘
```

### Example Analysis (sc1.png)

When both modes are blocked but have signals:

```
Scenario: Trending Market (ADX 39.6)
├── M15 PA = BUY ✅
├── M5 PA = BUY ✅
├── HYBRID = READY ✅
└── But both BLOCKED by Location Filter

Expert Log:
❌ SNIPER: "Price 711 pts ABOVE EMA (not at value)"
❌ HYBRID: "Price too far from M15 EMA (711 pts, max=276 pts)"

Root Cause: Fixed location filter (0.5× ATR) too strict for trending markets

Solution: Adaptive location filter adjusts to 1.5× ATR for strong trends
```

---

## Parameter Usage by Mode

### Which Cockpit Parameters Each Mode Uses

| Cockpit Parameter | Sniper | Hybrid | Notes |
|-------------------|--------|--------|-------|
| **Trend Matrix (H4↑H1↑M15↑)** | ❌ No | ✅ **YES** | Hybrid ONLY (trend context) |
| **M15 PA** | ✅ **YES** | ❌ No | Direct trigger |
| **M5 PA** | ❌ No | ✅ **YES** | Hybrid ONLY (trigger) |
| **RSI (M15)** | ❌ No | ❌ No | Display only, not used |
| **Stoch (M15)** | ❌ No | ❌ No | Display only, not used |
| **Slope H1** | ❌ No | ⚠️ **YES** | Hybrid slope safety check |
| **ATR (M15)** | ✅ **YES** | ✅ **YES** | Both use for calculations |
| **EMA Distance (H1)** | ❌ No | ❌ No | Display only (not used!) |
| **To Zone** | ✅ **YES** | ❌ No | Sniper ONLY (structure filter) |
| **ADX (H1)** | ❌ No | ✅ **YES** | Hybrid market state check |
| **HYBRID Status** | ❌ No | ✅ **YES** | Hybrid internal state |

### Important Notes

1. **EMA Distance in Cockpit ≠ What Modes Use**
   - Cockpit shows: H1 EMA 20 distance
   - Both modes use: M15 EMA 20 distance (calculated fresh)
   - Modes recalculate values for accuracy

2. **Trend Context - Hybrid Only**
   - Hybrid: Uses Trend Matrix for permission
   - Sniper: Works in any trend (no trend check)

3. **Zone Filter - Sniper Only**
   - Sniper: Uses for structure validation
   - Hybrid: Does not use zone filter

---

## Adaptive Location Filter

### What It Does

Automatically adjusts the location/pullback filter based on market volatility (ADX):

```
┌─────────────────────────────────────────────────┐
│  ADX READING → FILTER ADJUSTMENT                │
├─────────────────────────────────────────────────┤
│  ADX < 20 (Choppy)  → 0.3× ATR (~165 pts)      │
│  ADX 20-25 (Range)  → 0.5× ATR (~276 pts)      │
│  ADX 25-30 (Trending) → 1.0× ATR (~552 pts)     │
│  ADX > 30 (Strong) → 1.5× ATR (~828 pts)       │
└─────────────────────────────────────────────────┘
```

### Why It Was Added

**Problem**: Sniper and Hybrid blocked for 2+ days because:
- Trending market (ADX 39.6)
- Price stayed extended (711 pts above EMA)
- Fixed filter (276 pts max) blocked all trades
- Only Arrow signal (less accurate) was trading

**Solution**: Adaptive filter automatically loosens in trends, tightens in choppy markets.

### Impact on Accuracy vs Trade Frequency

| Metric | Tight Filter (0.5×) | Adaptive (0.3-1.5×) |
|--------|---------------------|---------------------|
| **Win Rate** | ~65% | ~55% (lower) |
| **Trade Frequency** | Very Low | 3-5x Higher |
| **Profit per Trade** | Higher | Lower |
| **Total Profit** | Low | **Higher ✅** |
| **Missed Moves** | Many | Few |

### Why It Still Works

In strong trends, the **trend itself provides the edge**, not the entry location. Waiting for pullback in strong trends means missing most of the move.

---

## Coordination Logic

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

*Generated for EA Helper Project*
