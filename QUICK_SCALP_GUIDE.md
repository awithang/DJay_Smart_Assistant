# Quick Scalp Mode - Complete Guide

## Table of Contents
1. [Overview](#overview)
2. [How Quick Scalp Works](#how-quick-scalp-works)
3. [Entry Conditions](#entry-conditions)
4. [Parameters Reference](#parameters-reference)
5. [Button States](#button-states)
6. [Parameter Examples by Condition](#parameter-examples-by-condition)
7. [Optimization Tips](#optimization-tips)

---

## Overview

**Quick Scalp** is a fast-trading mode designed for scalping in the **middle zone** (neutral area between buy/sell zones). It uses price action patterns combined with momentum filters to capture quick profits.

### Key Characteristics
- **Zone**: Only trades in MIDDLE zone (neutral area)
- **Speed**: Quick entries with fixed TP/SL
- **Risk**: Controlled 1:1.75 R:R ratio (default: TP=35, SL=20)
- **Filters**: PA + Trend + ADX + Momentum (RSI/Stochastic)

### Visual Signals
- **Lime Arrow (code 241)**: Quick Scalp BUY signal
- **Red Arrow (code 242)**: Quick Scalp SELL signal

---

## How Quick Scalp Works

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    QUICK SCALP LOGIC                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Check if in MIDDLE ZONE (neutral area)                  │
│     └─ If NOT in middle → SKIP (show "WAIT")               │
│                                                             │
│  2. Check ADX (market volatility)                           │
│     └─ If ADX < threshold → SKIP (show "LOW ADX")          │
│                                                             │
│  3. Wait for Price Action (PA) Signal                       │
│     ├─ Hammer or Bullish Engulfing → BUY                   │
│     └─ Shooting Star or Bearish Engulfing → SELL           │
│                                                             │
│  4. Check Trend Filter (H1)                                 │
│     ├─ BUY: H1 must NOT be DOWN                            │
│     └─ SELL: H1 must NOT be UP                             │
│                                                             │
│  5. Check Momentum Filter (OR logic)                        │
│     ├─ BUY: RSI < 40 OR Stoch K < 20                       │
│     └─ SELL: RSI > 60 OR Stoch K > 80                      │
│                                                             │
│  6. All conditions met? → EXECUTE TRADE                     │
│     └─ Fixed TP/SL based on parameters                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Entry Conditions

### BUY Signal (All Must Be TRUE)

| Condition | Description | Source |
|-----------|-------------|--------|
| **Zone = MIDDLE** | Price must be in neutral zone (not in buy/sell zones) | M5 Chart |
| **ADX ≥ Threshold** | Market must have enough volatility (default: ≥20) | M5 Chart |
| **PA = BUY** | Hammer or Bullish Engulfing pattern detected | Current TF |
| **H1 Trend ≠ DOWN** | H1 trend can be UP or FLAT (not DOWN) | H1 Chart |
| **Momentum OK** | RSI < 40 **OR** Stoch K < 20 | M5 Chart |

### SELL Signal (All Must Be TRUE)

| Condition | Description | Source |
|-----------|-------------|--------|
| **Zone = MIDDLE** | Price must be in neutral zone | M5 Chart |
| **ADX ≥ Threshold** | Market must have enough volatility | M5 Chart |
| **PA = SELL** | Shooting Star or Bearish Engulfing pattern | Current TF |
| **H1 Trend ≠ UP** | H1 trend can be DOWN or FLAT (not UP) | H1 Chart |
| **Momentum OK** | RSI > 60 **OR** Stoch K > 80 | M5 Chart |

---

## Parameters Reference

### Main Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `Input_QuickScalp_Mode` | `true` | true/false | Master switch for Quick Scalp mode |
| `Input_QS_RSI_Buy_Level` | `40` | 20-40 | RSI must be BELOW this for BUY signals |
| `Input_QS_RSI_Sell_Level` | `60` | 60-80 | RSI must be ABOVE this for SELL signals |
| `Input_QS_Stoch_Buy_Level` | `20` | 10-30 | Stochastic K must be BELOW this for BUY |
| `Input_QS_Stoch_Sell_Level` | `80` | 70-90 | Stochastic K must be ABOVE this for SELL |
| `Input_QS_ADX_Minimum` | `20` | 15-35 | Minimum ADX value to trade (filters choppy markets) |
| `Input_QS_TP_Points` | `35` | 20-100 | Take Profit distance in points (3.5 pips) |
| `Input_QS_SL_Points` | `20` | 15-50 | Stop Loss distance in points (2.0 pips) |

### Parameter Details

#### `Input_QS_RSI_Buy_Level` / `Input_QS_RSI_Sell_Level`
- **Purpose**: RSI filter for momentum confirmation
- **Lower values** = Fewer signals, higher quality (more oversold/overbought required)
- **Higher values** = More signals, lower quality
- **Note**: Uses **OR logic** with Stochastic (only ONE needs to be true)

#### `Input_QS_Stoch_Buy_Level` / `Input_QS_Stoch_Sell_Level`
- **Purpose**: Stochastic filter for momentum confirmation
- **Works with**: RSI in OR configuration
- **Example**: If RSI=45 (not oversold) but Stoch K=15 (oversold) → BUY signal valid

#### `Input_QS_ADX_Minimum`
- **Purpose**: Filter out choppy/low-volatility markets
- **ADVISOR Status**: Shows "LOW ADX" when below threshold
- **Too low** (15): Trades in choppy conditions → more false signals
- **Too high** (30): Misses good opportunities → fewer trades

#### `Input_QS_TP_Points` / `Input_QS_SL_Points`
- **Purpose**: Fixed exit points for all Quick Scalp trades
- **Default Ratio**: 35:20 = 1.75:1 R:R
- **Calculation**: Points / 10 = Pips (e.g., 35 points = 3.5 pips)
- **Note**: These are FIXED values, not dynamically calculated

---

## Button States

The Quick Scalp button shows the current trading condition:

| Button Text | Color | Meaning | Action |
|-------------|-------|---------|--------|
| **OFF** | Gray | Quick Scalp disabled | Click to enable |
| **READY** | Green | Middle zone + ADX OK + Waiting for PA | Ready to trade |
| **LOW ADX** | Orange | Middle zone + ADX too low | Market too choppy |
| **WAIT** | Yellow | Price in zone (Buy/Sell) | Quick Scalp paused |

### State Transition Diagram

```
                    [ENABLE QS]
                         ↓
                      ┌─────┐
                      │ OFF │ (Disabled)
                      └─────┘
                         │ [Click to enable]
                         ↓
                    [Check Zone]
                    │           │
              [In Zone]     [Middle Zone]
                    │           │
                    ↓           ↓
                 ┌──────┐  [Check ADX]
                 │ WAIT │       │
                 └──────┘   ┌───┴────┐
                     │    │         │
                     │  [ADX OK] [ADX LOW]
                     │    │         │
                     └────→┘    ┌──┴──┐
                               │     │
                               ↓     ↓
                           ┌─────┐ ┌─────────┐
                           │READY│ │LOW ADX  │
                           └─────┘ └─────────┘
```

---

## Parameter Examples by Condition

### Conservative Settings (Fewer Signals, Higher Quality)

```mql5
// Use for: M1, M5 (high noise timeframes)
Input_QS_RSI_Buy_Level      = 35;    // More oversold required
Input_QS_RSI_Sell_Level     = 65;    // More overbought required
Input_QS_Stoch_Buy_Level    = 15;    // Strict oversold
Input_QS_Stoch_Sell_Level   = 85;    // Strict overbought
Input_QS_ADX_Minimum        = 25;    // Skip choppy markets
Input_QS_TP_Points          = 40;    // Higher TP
Input_QS_SL_Points          = 20;    // Same SL (2:1 R:R)
```

**Result**: ~2-5 signals per day, higher win rate

---

### Balanced Settings (Default - Recommended)

```mql5
// Use for: M5, M15 (balanced timeframes)
Input_QS_RSI_Buy_Level      = 40;    // Default
Input_QS_RSI_Sell_Level     = 60;    // Default
Input_QS_Stoch_Buy_Level    = 20;    // Default
Input_QS_Stoch_Sell_Level   = 80;    // Default
Input_QS_ADX_Minimum        = 20;    // Default
Input_QS_TP_Points          = 35;    // Default (3.5 pips)
Input_QS_SL_Points          = 20;    // Default (2.0 pips)
```

**Result**: ~5-10 signals per day, balanced risk/reward

---

### Aggressive Settings (More Signals, Lower Quality)

```mql5
// Use for: M15, H1 (lower noise timeframes)
Input_QS_RSI_Buy_Level      = 45;    // Less oversold required
Input_QS_RSI_Sell_Level     = 55;    // Less overbought required
Input_QS_Stoch_Buy_Level    = 25;    // Relaxed oversold
Input_QS_Stoch_Sell_Level   = 75;    // Relaxed overbought
Input_QS_ADX_Minimum        = 15;    // Trade in lower volatility
Input_QS_TP_Points          = 30;    // Lower TP (quick exits)
Input_QS_SL_Points          = 20;    // Same SL (1.5:1 R:R)
```

**Result**: ~10-20 signals per day, lower win rate, more activity

---

### M1 Scalper Settings (Very Fast, High Risk)

```mql5
// Use for: M1 ONLY (expert traders only)
Input_QS_RSI_Buy_Level      = 35;    // Strict filter
Input_QS_RSI_Sell_Level     = 65;    // Strict filter
Input_QS_Stoch_Buy_Level    = 15;    // Strict filter
Input_QS_Stoch_Sell_Level   = 85;    // Strict filter
Input_QS_ADX_Minimum        = 22;    // Skip very choppy
Input_QS_TP_Points          = 25;    // Very quick TP (2.5 pips)
Input_QS_SL_Points          = 15;    // Tight SL (1.5 pips)
```

**Result**: ~20-50 signals per day, requires monitoring, high spread sensitivity

---

## Optimization Tips

### 1. Timeframe Selection

| Timeframe | Recommended Settings | Notes |
|-----------|---------------------|-------|
| **M1** | Conservative + Tight TP/SL | High noise, strict filters needed |
| **M5** | Balanced (default) | Best for Quick Scalp |
| **M15** | Aggressive | Lower noise, more signals |
| **H1** | Not recommended | Too slow for scalping |

### 2. ADX Tuning

- **Low Volatility Pairs (EUR/USD)**: Use ADX 18-22
- **High Volatility Pairs (GBP/JPY)**: Use ADX 22-28
- **Asian Session**: Increase ADX to 25+ (very quiet)
- **London/NY Overlap**: ADX 20 is fine (high volatility)

### 3. TP/SL Ratio

**Conservative** (High win rate, lower profit):
```
TP = 30, SL = 20  (1.5:1)
TP = 35, SL = 20  (1.75:1) ← Default
```

**Balanced**:
```
TP = 40, SL = 20  (2:1)
TP = 50, SL = 25  (2:1)
```

**Aggressive** (Lower win rate, higher profit per trade):
```
TP = 50, SL = 20  (2.5:1)
TP = 60, SL = 20  (3:1)
```

### 4. RSI/Stochastic Combination

The **OR logic** means you can be flexible:

**More Signals** (wider net):
```mql5
RSI Buy < 40 OR Stoch < 25  // Either condition OK
```

**Fewer Signals** (both must agree):
```mql5
RSI Buy < 35 AND Stoch < 20  // Stricter (requires code change)
```

### 5. Spread Consideration

| Spread | Min TP Points | Recommendation |
|--------|---------------|----------------|
| < 0.5 pips | 25+ | Good for scalping |
| 0.5-1 pip | 30+ | Acceptable |
| 1-2 pips | 40+ | Increase TP |
| > 2 pips | 50+ | Avoid Quick Scalp |

**Formula**: `Min TP = (Spread in pips × 10) + 20 points`

Example: 1 pip spread → (1 × 10) + 20 = **30 points minimum TP**

### 6. Testing Recommendations

1. **Demo First**: Always test new settings on demo account
2. **One Change at a Time**: Only modify one parameter per test
3. **Track Metrics**:
   - Win rate (%)
   - Average profit/loss per trade
   - Maximum drawdown
   - Signals per day

4. **Test Period**: At least 2 weeks of data

---

## Troubleshooting

### Problem: No signals appearing

**Check:**
1. Is Quick Scalp button showing "READY"?
2. Is ADX above threshold? (Check "LOW ADX" status)
3. Are you in MIDDLE zone? (Check "WAIT" status)
4. Are RSI/Stoch levels too strict?

**Solution**: Lower RSI/Stoch levels or reduce ADX threshold

---

### Problem: Too many losing trades

**Check:**
1. What's your spread? (High spread kills scalping)
2. Is TP too small for spread?
3. Are filters too loose? (RSI 45/55, ADX 15)
4. What timeframe are you on? (M1 is very noisy)

**Solution**: Tighten filters, increase TP, switch to M5/M15

---

### Problem: Missing good trades

**Check:**
1. Are filters too strict? (RSI 30/70, ADX 30)
2. Is H1 trend filter blocking trades?
3. Are you in right zone? (Quick Scalp only works in MIDDLE zone)

**Solution**: Relax RSI/Stoch levels, reduce ADX threshold

---

## Summary

**Quick Scalp is ideal for:**
- Traders who can monitor the market
- M5-M15 timeframes (not M1 unless experienced)
- Low spread pairs (EUR/USD, USD/JPY)
- Volatile sessions (London/NY overlap)

**Quick Scalp is NOT for:**
- Set-and-forget trading
- High spread pairs (exotics, crosses)
- Low volatility periods (Asian session for some pairs)
- Traders who can't handle quick losses

---

**Remember**: Quick Scalp uses FIXED TP/SL. Always ensure your TP is large enough to cover spread + commission, or you will lose money even on winning trades!

*Last Updated: 2025-01-07*
*Version: 5.0*
