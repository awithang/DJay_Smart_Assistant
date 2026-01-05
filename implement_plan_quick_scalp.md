# Implementation Plan: Quick Scalp Mode for DJAY Smart Assistant

## 1. Objective

Add a "Quick Scalp" trading mode that enables day trading entries in the middle zone (between D1 Buy/Sell zones) with strict RSI/Stochastic filters. This complements the existing Zone Trading (Reversal/Breakout) system and provides more trading opportunities for active day traders.

**Key Goals:**
- Generate more trade opportunities during middle-zone periods
- Maintain trade quality with strict momentum filters (RSI + Stochastic)
- Respect H1 trend direction (no counter-trend scalping)
- Quick profit targets (20-50 pips) with tight stops
- Distinct visual indicators separate from zone trading arrows

---

## 2. Technical Constraints & Performance

*   **Zero-Latency Response**: Quick Scalp button must use `BORDER_FLAT` style for instant feedback
*   **Efficient Calculations**: RSI/Stochastic values already cached by SignalEngine, minimal overhead
*   **No Tick Performance Impact**: Signal checks only on new M5 bar (every 5 minutes)
*   **Clean State Management**: Toggle button with clear ON/OFF states, visible on dashboard

---

## 3. Detailed Specifications

### 3.1 Quick Scalp Logic

**Trigger Conditions (ALL must be TRUE):**

| Condition | BUY | SELL |
|-----------|-----|------|
| **Zone** | Middle zone (ZONE_STATUS_NONE) | Middle zone (ZONE_STATUS_NONE) |
| **PA Signal** | Hammer or Bullish Engulfing on M5 | Shooting Star or Bearish Engulfing on M5 |
| **H1 Trend** | NOT DOWN (can be UP or FLAT) | NOT UP (can be DOWN or FLAT) |
| **RSI (14)** | < 40 (approaching oversold) | > 60 (approaching overbought) |
| **Stochastic K** | < 20 (in oversold territory) | > 80 (in overbought territory) |

**Entry & Exit:**
- **Entry Price**: Current M5 close price at signal
- **Take Profit**: +35 pips from entry
- **Stop Loss**: -20 pips from entry
- **Risk:Reward**: 1:1.75

---

### 3.2 User Interface Changes

#### A. New Input Parameters

```cpp
input bool   Input_QuickScalp_Mode       = false;  // Enable Quick Scalp mode (default: OFF)
input int    Input_QS_RSI_Buy_Level      = 40;     // RSI < this for BUY signals
input int    Input_QS_RSI_Sell_Level     = 60;     // RSI > this for SELL signals
input int    Input_QS_Stoch_Buy_Level    = 20;     // Stochastic K < this for BUY
input int    Input_QS_Stoch_Sell_Level   = 80;     // Stochastic K > this for SELL
input int    Input_QS_TP_Points          = 35;     // Take Profit in pips
input int    Input_QS_SL_Points          = 20;     // Stop Loss in pips
```

#### B. New Dashboard Button

**Location:** Right Panel, under "AUTO STRATEGY" section

**Specification:**
- **Name**: `BtnQuickScalp`
- **Label**: "QUICK SCALP" (OFF) or "QUICK SCALP" (ON)
- **Size**: width=110, height=20
- **Position**: Below existing strategy buttons, above STRATEGY SIGNAL section
- **Colors**:
  - OFF: `C'50,50,60'` (Dark Gray) with `C'100,100,100'` text (Dim Gray)
  - ON: `clrLime` (Lime Green) with `clrWhite` text

**Y-Position:** After Auto Strategy button, approximately `right_y += 25` from existing code

#### C. Arrow Visual Differentiation

| Arrow Type | Arrow Code | Color | Label Prefix | Placement |
|------------|------------|-------|--------------|-----------|
| **Zone BUY** | 233 | Blue (clrBlue or C'34,139,34') | `"ZONE_"` | At Buy1/Buy2 zones |
| **Zone SELL** | 234 | Orange (clrOrange or C'255,140,0') | `"ZONE_"` | At Sell1/Sell2 zones |
| **Quick Scalp BUY** | 241 | Lime (clrLime or C'50,205,50') | `"QS_"` | In middle zone only |
| **Quick Scalp SELL** | 242 | Red (clrRed or C'220,20,60') | `"QS_"` | In middle zone only |

**Note:** Arrow codes 241/242 are thinner versions of 233/234

---

### 3.3 Global State Management

**New Global Variable:**
```cpp
bool g_quick_scalp_mode;  // Tracks Quick Scalp toggle state
```

**Initialization (in `OnInit`):**
```cpp
g_quick_scalp_mode = Input_QuickScalp_Mode;
```

**Button Event Handler (add to `OnChartEvent`):**
```cpp
else if(dashboardPanel.IsQuickScalpClicked(sparam))
{
   g_quick_scalp_mode = !g_quick_scalp_mode;
   dashboardPanel.UpdateQuickScalpButton(g_quick_scalp_mode);
}
```

---

## 4. Implementation Steps

### 4.1 SignalEngine.mqh Enhancements

**Add new helper methods:**

```cpp
// Get RSI value for specified timeframe and shift
double GetRSIValue(ENUM_TIMEFRAMES timeframe, int period, int shift);

// Get Stochastic K value for specified timeframe and shift
double GetStochKValue(ENUM_TIMEFRAMES timeframe, int k_period, int d_period, int shift);
```

**Implementation:**
- Use `iRSI()` and `iStochastic()` built-in functions
- Return single value (buffer[0])
- Handle errors gracefully (return -1 on failure)

---

### 4.2 DashboardPanel.mqh Changes

#### A. Add Button Creation (in `CreatePanel`)

**Location:** Right Panel, after Auto Strategy button section (approximately line 998)

```cpp
// Quick Scalp Button
CreateLabel("L_QS", right_x + pad, right_y, "QUICK SCALP", m_header_color, 10, "Arial Bold");
CreateButton("BtnQuickScalp", right_x + half_width - 110, right_y, 110, 20, "QUICK SCALP", C'50,50,60', C'100,100,100', 8);
```

#### B. Add Visual Update Method

```cpp
void CDashboardPanel::UpdateQuickScalpButton(bool isActive)
{
   string text = "QUICK SCALP";
   color bg = isActive ? clrLime : C'50,50,60';
   color txt = isActive ? clrWhite : C'100,100,100';

   ObjectSetString(m_chart_id, m_prefix+"BtnQuickScalp", OBJPROP_TEXT, text);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnQuickScalp", OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnQuickScalp", OBJPROP_COLOR, txt);
}
```

#### C. Add Click Handler Method

```cpp
bool IsQuickScalpClicked(string sparam)
{
   return (sparam == m_prefix+"BtnQuickScalp");
}
```

#### D. Modify `UpdateStrategyButtons` to include Quick Scalp

Update signature and implementation to manage the new button state.

---

### 4.3 Main EA (DJay_Smart_Assistant.mq5) Changes

#### A. Initialize Quick Scalp State

**In `OnInit`:**
```cpp
g_quick_scalp_mode = Input_QuickScalp_Mode;
dashboardPanel.UpdateQuickScalpButton(g_quick_scalp_mode);
```

#### B. Add Quick Scalp Logic to `OnNewBar`

**Location:** In the new bar detection section, after existing EMA/Zone trading logic (approximately line 270)

**Implementation:**

```cpp
// --- 4. Quick Scalp Mode (Middle Zone Trading) ---
if(g_quick_scalp_mode && newBar)
{
   // Only trade in middle zone
   ENUM_ZONE_STATUS zone = signalEngine.GetCurrentZoneStatus();

   if(zone == ZONE_STATUS_NONE)
   {
      // Get signals
      ENUM_SIGNAL_TYPE paSignal = signalEngine.GetActiveSignal();
      ENUM_TREND_DIRECTION h1Trend = signalEngine.GetTrendDirection(PERIOD_H1);

      // Get filter values
      double rsiVal = signalEngine.GetRSIValue(PERIOD_M5, 14, 0);
      double stochK = signalEngine.GetStochKValue(PERIOD_M5, 14, 3, 0);

      // BUY SIGNAL CHECK
      if(paSignal == SIGNAL_PA_BUY
         && h1Trend != TREND_DOWN
         && rsiVal > 0 && rsiVal < Input_QS_RSI_Buy_Level
         && stochK > 0 && stochK < Input_QS_Stoch_Buy_Level)
      {
         // Create Quick Scalp arrow (Lime, code 241)
         double prevLow = iLow(_Symbol, PERIOD_M5, 1);
         CreateSignalArrow(currentBarTime, prevLow - 50*_Point, 241, clrLime, "QS_Buy");

         // AUTO MODE execution
         if(g_tradingMode == MODE_AUTO)
            ExecuteQuickScalpTrade(ORDER_TYPE_BUY, Input_QS_TP_Points, Input_QS_SL_Points);
      }

      // SELL SIGNAL CHECK
      else if(paSignal == SIGNAL_PA_SELL
         && h1Trend != TREND_UP
         && rsiVal > 0 && rsiVal > Input_QS_RSI_Sell_Level
         && stochK > 0 && stochK > Input_QS_Stoch_Sell_Level)
      {
         // Create Quick Scalp arrow (Red, code 242)
         double prevHigh = iHigh(_Symbol, PERIOD_M5, 1);
         CreateSignalArrow(currentBarTime, prevHigh + 50*_Point, 242, clrRed, "QS_Sell");

         // AUTO MODE execution
         if(g_tradingMode == MODE_AUTO)
            ExecuteQuickScalpTrade(ORDER_TYPE_SELL, Input_QS_TP_Points, Input_QS_SL_Points);
      }
   }
}
```

#### C. Add Quick Scalp Trade Execution Function

```cpp
void ExecuteQuickScalpTrade(ENUM_ORDER_TYPE orderType, int tp_points, int sl_points)
{
   // Calculate entry price
   double entryPrice = (orderType == ORDER_TYPE_BUY) ?
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                        SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Calculate TP/SL
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tp = (orderType == ORDER_TYPE_BUY) ? entryPrice + tp_points*point : entryPrice - tp_points*point;
   double sl = (orderType == ORDER_TYPE_BUY) ? entryPrice - sl_points*point : entryPrice + sl_points*point;

   // Execute trade
   MqlTradeRequest request;
   MqlTradeResult result;

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = NormalizeDouble(Input_Risk_Percent / 100.0 * AccountInfoDouble(ACCOUNT_BALANCE) / 100.0, 2);
   request.type = orderType;
   request.price = entryPrice;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = 123456;
   request.comment = "QS_" + (string)((orderType == ORDER_TYPE_BUY) ? "BUY" : "SELL");

   if(!OrderSend(request, result))
      Print("Quick Scalp Order Failed: ", result.comment);
}
```

#### D. Update Button Event Handler

**Add to `OnChartEvent`:**
```cpp
else if(dashboardPanel.IsQuickScalpClicked(sparam))
{
   g_quick_scalp_mode = !g_quick_scalp_mode;
   dashboardPanel.UpdateQuickScalpButton(g_quick_scalp_mode);
   Print("Quick Scalp Mode: ", g_quick_scalp_mode ? "ENABLED" : "DISABLED");
}
```

---

## 5. Code Changes Summary

### Files Modified:

| File | Changes | Lines Added |
|------|---------|--------------|
| `DJay_Smart_Assistant.mq5` | Add Quick Scalp logic, button handler, trade execution | ~80 lines |
| `DashboardPanel.mqh` | Add button creation, update method, click handler | ~50 lines |
| `SignalEngine.mqh` | Add GetRSIValue(), GetStochKValue() methods | ~30 lines |

### New Code Sections:

1. **SignalEngine.mqh**: 2 new helper functions
2. **DashboardPanel.mqh**: 3 new methods, 1 UI element
3. **DJay_Smart_Assistant.mq5**: Quick Scalp logic block, trade execution function

---

## 6. Verification Steps

### 6.1 UI Verification

**Button Visibility:**
- [ ] Quick Scalp button appears below Auto Strategy section
- [ ] Button shows correct text "QUICK SCALP"
- [ ] OFF state: Dark gray background, dim gray text
- [ ] ON state: Lime green background, white text
- [ ] Button toggles correctly when clicked

### 6.2 Arrow Verification

**Zone Arrows (existing):**
- [ ] Blue arrows (233) still appear at Buy1/Buy2 zones
- [ ] Orange arrows (234) still appear at Sell1/Sell2 zones
- [ ] Label format: `"ZONE_Buy"`, `"ZONE_Sell"`

**Quick Scalp Arrows (new):**
- [ ] Lime arrows (241) appear ONLY in middle zone when ON
- [ ] Red arrows (242) appear ONLY in middle zone when ON
- [ ] Label format: `"QS_Buy"`, `"QS_Sell"`
- [ ] NO Quick Scalp arrows when button is OFF
- [ ] NO Quick Scalp arrows when in Buy/Sell zones

### 6.3 Logic Verification

**BUY Signal Filters (all must pass):**
- [ ] Middle zone (not in Buy/Sell zone)
- [ ] Hammer or Bullish Engulfing detected
- [ ] H1 trend is NOT DOWN
- [ ] RSI < 40
- [ ] Stochastic K < 20

**SELL Signal Filters (all must pass):**
- [ ] Middle zone (not in Buy/Sell zone)
- [ ] Shooting Star or Bearish Engulfing detected
- [ ] H1 trend is NOT UP
- [ ] RSI > 60
- [ ] Stochastic K > 80

### 6.4 Trade Execution Verification

**Manual Testing:**
- [ ] Click Quick Scalp button ON
- [ ] Wait for M5 signal in middle zone
- [ ] Verify Lime/Red arrow appears
- [ ] Check TP/SL calculation (35/20 pips)
- [ ] Verify trade executes in AUTO mode

**Test Cases:**
- [ ] Quick Scalp OFF → no QS arrows should appear
- [ ] Quick Scalp ON + in Buy zone → no QS arrows (only zone arrows)
- [ ] Quick Scalp ON + middle zone + PA signal + WRONG RSI → no arrow
- [ ] Quick Scalp ON + middle zone + all filters met → arrow appears

### 6.5 Performance Verification

- [ ] OnTimer completes in < 10ms (no performance degradation)
- [ ] RSI/Stochastic calculations don't cause lag
- [ ] Button toggle is instant (BORDER_FLAT style)
- [ ] Memory usage stable (no leaks)

---

## 7. Edge Cases & Error Handling

### 7.1 RSI/Stochastic Unavailable

**Scenario:** Indicator data not ready (MT5 startup, weekend)

**Handling:**
```cpp
double rsiVal = signalEngine.GetRSIValue(...);
if(rsiVal < 0) return;  // Skip this bar, wait for valid data
```

### 7.2 Quick Scalp Toggle During Position

**Scenario:** User toggles button while a Quick Scalp trade is active

**Behavior:**
- New trades respect the toggle state
- Existing position unaffected (manage separately)
- Clear visual indication of current mode

### 7.3 Counter-Trend H1 Situation

**Scenario:** H1 is DOWN, Quick Scalp looks for BUY

**Filter:**
```cpp
if(h1Trend == TREND_DOWN && paSignal == SIGNAL_PA_BUY)
   // SKIP - Don't buy against H1 downtrend
```

### 7.4 Zone Transition (Middle → Zone)

**Scenario:** Price moves from middle to Buy1 zone while Quick Scalp is ON

**Behavior:**
- Quick Scalp mode remains ON
- But QS arrows stop appearing (in zone now)
- Zone arrows take priority
- User must manually toggle OFF if desired

---

## 8. Configuration Settings (Default Values)

```cpp
// Quick Scalp Settings
input bool   Input_QuickScalp_Mode       = false;  // Enable Quick Scalp mode (default: OFF)
input int    Input_QS_RSI_Buy_Level      = 40;     // RSI < this for BUY signals
input int    Input_QS_RSI_Sell_Level     = 60;     // RSI > this for SELL signals
input int    Input_QS_Stoch_Buy_Level    = 20;     // Stochastic K < this for BUY
input int    Input_QS_Stoch_Sell_Level   = 80;     // Stochastic K > this for SELL
input int    Input_QS_TP_Points          = 35;     // Take Profit in pips
input int    Input_QS_SL_Points          = 20;     // Stop Loss in pips
```

**Rationale for Defaults:**
- **Mode OFF**: Conservative start, user opt-in
- **RSI 40/60**: Moderate levels, not too strict
- **Stoch 20/80**: Clear oversold/overbought territory
- **TP/SL 35/20**: Balance between capture and protection

---

## 9. Success Criteria

The implementation is successful when:

1. ✅ Quick Scalp button appears and toggles correctly
2. ✅ Lime/Red arrows appear in middle zone when enabled
3. ✅ No Quick Scalp arrows when in Buy/Sell zones
4. ✅ All 5 filters are applied (PA, Zone, Trend, RSI, Stoch)
5. ✅ H1 trend is respected (no counter-trend trades)
6. ✅ TP/SL is 35/20 pips as configured
7. ✅ Compiles with 0 errors, 0 warnings
8. ✅ No performance degradation in OnTimer
9. ✅ Existing Zone trading arrows unaffected
10. ✅ Auto-trading executes Quick Scalp trades correctly

---

## 10. Future Enhancements (Out of Scope)

- Trailing stop for Quick Scalp positions
- Partial close at +20 pips, move SL to breakeven
- Quick Scalp performance statistics (win rate, profit factor)
- Multi-timeframe confirmation (M15 alignment)
- News event filter (avoid scalping during high impact)
- Adjustable RSI/Stochastic periods via inputs

---

**Document Version:** 1.0
**Date:** 2025-01-05
**Author:** Claude Code Implementation Agent
**Status:** Ready for Architect Review
