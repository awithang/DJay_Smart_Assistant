# WidwaPa Trade Assistant - Panel Reference Guide

**Version**: 4.0
**Last Updated**: 2025-12-30

---

## Panel Layout Overview

```
┌─────────────────────────────────────────┐
│ WIDWA PA ASSISTANT           $1,234.56 │  ← Title + Account Balance
├─────────────────────────────────────────┤
│ SESSION: ASIA    M5: 04:32    BUY ZONE 1│  ← Session, Countdown, Zone Status
├─────────────────────────────────────────┤
│ DAILY ZONES (Smart Grid)               │
│ ┌─────────────────────────────────────┐ │
│ │ ZONE      PRICE         DIST        │ │
│ │ D1 +3000  2800.50      200 pts     │ │  ← Top 5 nearest levels
│ │ D1 +1000  2700.30      50 pts      │ │
│ │ D1 +300   2650.10      0 pts       │ │  ← Current price area
│ │ D1 -300   2600.00      50 pts      │ │
│ │ D1 -1000  2500.00      150 pts     │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ EXECUTION              Risk %    [3.0] │
│ ┌────────────┐  ┌────────────┐        │
│ │    BUY     │  │   SELL     │        │  ← One-click trading buttons
│ └────────────┘  └────────────┘        │
├─────────────────────────────────────────┤
│ STRATEGY SIGNAL                        │
│ ┌─────────────────────────────────────┐ │
│ │ Trend:        STRONG UPTREND        │ │  ← D1+H4+H1 alignment (color-coded)
│ │ EMA Distance:                       │ │
│ │ M15 (100/200):  150 / 300          │ │  ← Distance from M15 EMAs
│ │ H1 (100/200):   -50 / 200          │ │  ← Distance from H1 EMAs
│ │ PA Signal:     H1 BULL + M5 ENTRY  │ │  ← Combined H1+M5 PA pattern
│ │ Rec. SL/TP:    300 / 600 pts       │ │  ← Risk recommendation
│ └─────────────────────────────────────┘ │
│                                        │
│                                   v4.0 │
└─────────────────────────────────────────┘
```

---

## Section Details

### 1. Header Section

| Element | Description | Update Frequency |
|---------|-------------|------------------|
| **Title** | "WIDWA PA ASSISTANT" | Static |
| **Balance** | Current account balance in USD | Every tick |

---

### 2. Market Status Section

| Element | Description | Possible Values |
|---------|-------------|-----------------|
| **Session** | Current market session | `ASIA`, `EUROPE`, `US`, `QUIET` |
| **Countdown** | Time until next M5 candle closes | `M5: MM:SS` format |
| **Status** | Trading zone status | See Zone Status below |

**Session Times (GMT+7)**:
| Session | Time Range |
|---------|------------|
| Asia | 08:00 - 10:00 |
| Europe | 13:30 - 16:00 |
| US | 19:30 - 22:00 |
| Quiet | All other times |

---

### 3. Daily Zones Table

| Column | Description |
|--------|-------------|
| **ZONE** | Level identifier (e.g., `D1 +300`, `D1 -1000`) |
| **PRICE** | Exact price level for that zone |
| **DIST** | Distance in points from current bid price |

**Zone Colors**:
- **Green** | Price is below this level (Buy Zone)
- **Red** | Price is above this level (Sell Zone)
- **Gold** | D1 Open price (reference)

**Zone Calculations**:
```
Buy Zone 1  = D1 Open + 300 points
Buy Zone 2  = D1 Open + 1000 points
Sell Zone 1 = D1 Open - 300 points
Sell Zone 2 = D1 Open - 1000 points
```

---

### 4. Execution Section

| Element | Description |
|--------|-------------|
| **Risk %** | Editable input for risk per trade (default: 3.0%) |
| **BUY Button** | Execute buy order with calculated lot size |
| **SELL Button** | Execute sell order with calculated lot size |

**Lot Size Formula**:
```
Lot = (Balance × Risk%) / (SL_Points × PointValue)
```

---

### 5. Strategy Signal Section

#### 5.1 Trend Strength

| Value | Description | Color |
|-------|-------------|-------|
| `STRONG UPTREND` | All 3 TFs bullish (D1, H4, H1) | Lime |
| `UPTREND` | 2 of 3 TFs bullish | Medium Sea Green |
| `WEAK UPTREND` | 1 of 3 TFs bullish | Yellow Green |
| `SIDEWAYS` | Mixed or no clear trend | Gray |
| `WEAK DOWNTREND` | 1 of 3 TFs bearish | Light Salmon |
| `DOWNTREND` | 2 of 3 TFs bearish | Orange Red |
| `STRONG DOWNTREND` | All 3 TFs bearish | Red |

**Trend Calculation**: Based on EMA 100 vs EMA 200 crossover on D1, H4, and H1

---

#### 5.2 EMA Distance

| Format | Example | Meaning |
|--------|---------|---------|
| `M15 (100/200): 150 / 300` | First value: distance from EMA 100 | Second value: distance from EMA 200 |
| `H1 (100/200): -50 / 200` | Positive = price above EMA | Negative = price below EMA |

**Units**: Points (not pips)

---

#### 5.3 PA Signal (Price Action)

| Signal | Meaning | Timeframe |
|--------|---------|-----------|
| `NONE` | No PA pattern detected | - |
| `H1 BULLISH` | Hammer/Bullish Engulfing on H1 | H1 (trend direction) |
| `H1 BEARISH` | Shooting Star/Bearish Engulfing on H1 | H1 (trend direction) |
| `M5 ENTRY BUY` | Hammer/Bullish Engulfing on M5 | M5 (entry timing) |
| `M5 ENTRY SELL` | Shooting Star/Bearish Engulfing on M5 | M5 (entry timing) |
| `H1 BULL + M5 ENTRY` | Both H1 and M5 show buy signals | Strongest confirmation |
| `H1 BEAR + M5 ENTRY` | Both H1 and M5 show sell signals | Strongest confirmation |
| `MIXED SIGNALS` | H1 and M5 show conflicting signals | Wait for clarity |

**PA Patterns Detected**:
- Hammer (bullish reversal)
- Shooting Star (bearish reversal)
- Bullish Engulfing (bullish continuation)
- Bearish Engulfing (bearish continuation)

---

#### 5.4 Recommended SL/TP

| Session | SL | TP | Ratio |
|---------|-----|-----|-------|
| Asia / Europe | 300 pts | 600 pts | 1:2 |
| US | 500 pts | 1000 pts | 1:2 |

**Note**: Values update based on input parameters and current session

---

### 6. Zone Status (in Status Area)

| Status | Meaning | Color |
|--------|---------|-------|
| `NEUTRAL` | Price not in any trade zone | Gray |
| `BUY ZONE 1` | Price near D1 Open + 300 | Green |
| `BUY ZONE 2` | Price near D1 Open + 1000 | Green |
| `SELL ZONE 1` | Price near D1 Open - 300 | Red |
| `SELL ZONE 2` | Price near D1 Open - 1000 | Red |

**Zone Tolerance**: ±300 points from zone level

---

## Update Frequencies

| Data Type | Update Interval |
|-----------|-----------------|
| Balance | Every tick |
| Session/Countdown | Every 1 second (timer) |
| Zone Status | Every 1 second (timer) |
| Daily Zones | Every 1 second (timer) |
| Trend Strength | Every 1 second (timer) |
| EMA Distance | Every 1 second (timer) |
| PA Signal | Every 1 second (timer) |
| Chart Arrows | On new bar (current TF) |

---

## Input Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `Input_RiskPercent` | 3.0 | Risk percentage per trade |
| `Input_SL_Points` | 300 | Stop Loss distance in points |
| `Input_Zone_Offset1` | 300 | First zone offset (points) |
| `Input_Zone_Offset2` | 1000 | Second zone offset (points) |
| `Input_MagicNumber` | 123456 | EA identifier for trades |

---

## File Structure

```
MQL5/
├── Experts/EA_Helper/
│   └── WidwaPa_Assistant.mq5          # Main EA
└── Include/EA_Helper/
    ├── Definitions.mqh                # Enums, structs, constants
    ├── SignalEngine.mqh               # Signal detection logic
    ├── TradeManager.mqh               # Order execution & risk
    └── DashboardPanel.mqh             # UI panel rendering
```

---

## Quick Reference: Color Scheme

| Element | Color | RGB |
|---------|-------|-----|
| Header/Title | Gold | 255, 215, 0 |
| Buy Signals | Green | 46, 204, 113 |
| Sell Signals | Red | 231, 76, 60 |
| Neutral/Gray | Gray | Variable |
| Background | Dark Blue | 20, 20, 35 |
| Panel Border | Accent Blue | 52, 152, 219 |

---

## Trading Workflow

1. **Check Session**: Only trade during Asia, Europe, or US hours
2. **Verify Zone**: Wait for price to enter a Buy or Sell zone
3. **Confirm Trend**: Look for trend alignment (2+ timeframes agree)
4. **Watch PA Signal**: Wait for H1 pattern, then M5 entry confirmation
5. **Set Risk**: Adjust Risk % if needed
6. **Execute**: Click BUY or SELL button when all conditions align

**Ideal Entry**: `H1 BULL + M5 ENTRY` in `BUY ZONE` with `UPTREND` or stronger

---

*Generated for EA Helper Project*
