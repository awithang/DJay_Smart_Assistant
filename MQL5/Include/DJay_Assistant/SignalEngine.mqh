//+------------------------------------------------------------------+
//|                                                   SignalEngine.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"

#include <DJay_Assistant/Definitions.mqh>

//+------------------------------------------------------------------+
//| Combined PA Signal Structure (H1 primary, M5 entry)               |
//+------------------------------------------------------------------+
struct CombinedSignal
{
    ENUM_SIGNAL_TYPE h1Signal;      // H1 PA signal (trend direction)
    ENUM_SIGNAL_TYPE m5Signal;      // M5 PA signal (entry timing)
    string description;             // Combined description
};

//+------------------------------------------------------------------+
//| Trend Alignment Structure (D1, H4, H1)                            |
//+------------------------------------------------------------------+
struct TrendAlignment
{
    ENUM_TREND_DIRECTION d1;
    ENUM_TREND_DIRECTION h4;
    ENUM_TREND_DIRECTION h1;
    int score;                      // -3 to +3 (all agree)
    string strengthText;            // "Strong Uptrend", "Weak Downtrend", etc.
    color strengthColor;            // Color for display
};

//+------------------------------------------------------------------+
//| EMA Distance Structure                                            |
//+------------------------------------------------------------------+
struct EMADistance
{
    double m15_ema100;    // Distance in points from EMA 100 on M15
    double m15_ema200;    // Distance in points from EMA 200 on M15
    double h1_ema100;     // Distance in points from EMA 100 on H1
    double h1_ema200;     // Distance in points from EMA 200 on H1
};

//+------------------------------------------------------------------+
//| Entry Point Structure (for Reversal/Breakout)                      |
//+------------------------------------------------------------------+
struct EntryPoint
{
    bool   isValid;       // Whether entry point is valid
    double price;         // Entry price level
    string direction;     // "BUY" or "SELL"
    string zone;          // Zone name (e.g., "Buy1", "Sell2")
    string description;   // Human-readable description
    datetime timestamp;   // When this entry was captured (for TTL expiry)
};

//+------------------------------------------------------------------+
//| Zone Status Enumeration                                           |
//+------------------------------------------------------------------+
enum ENUM_ZONE_STATUS
{
    ZONE_STATUS_NONE,
    ZONE_STATUS_IN_BUY1,
    ZONE_STATUS_IN_BUY2,
    ZONE_STATUS_IN_SELL1,
    ZONE_STATUS_IN_SELL2
};

//+------------------------------------------------------------------+
//| Signal Engine Class - Market Analysis                           |
//+------------------------------------------------------------------+
class CSignalEngine
{
private:
    double m_d1_open;           // Daily (D1) open price
    double m_ema_100;           // EMA 100 value
    double m_ema_200;           // EMA 200 value
    double m_ema_720;           // EMA 720 value
    double m_current_price;     // Current bid price

    int    m_zone_offset1;      // Zone offset 1 (in points)
    int    m_zone_offset2;      // Zone offset 2 (in points)
    int    m_gmt_offset;        // GMT Offset (hours) for session time adjustment

    // Indicator handles (created once, reused)
    int    m_handle_ema100;     // EMA 100 indicator handle (Current)
    int    m_handle_ema200;     // EMA 200 indicator handle (Current)
    int    m_handle_ema720;     // EMA 720 indicator handle (Current)

    // Cached Multi-Timeframe Handles
    int    m_handle_d1_100, m_handle_d1_200;
    int    m_handle_h4_100, m_handle_h4_200;
    int    m_handle_h1_100, m_handle_h1_200;
    int    m_handle_m15_100, m_handle_m15_200;

    // Helper method for copying indicator buffer values
    double CopyBufferValue(int handle, int buffer_num);

public:
    //--- Constructor/Destructor
    CSignalEngine();
    ~CSignalEngine();

    //--- Initialization
    void Init(int zone_offset1, int zone_offset2, int gmt_offset);

    //--- Data Refresh (Called on New Bar or Timer)
    void RefreshData();

    //--- Zone Logic
    double GetZoneLevel(ENUM_ZONE_TYPE zone_type);
    bool   IsInZone(double price, ENUM_ZONE_TYPE zone_type);
    ENUM_ZONE_STATUS GetCurrentZoneStatus();

    //--- Price Action Pattern Detection (multi-timeframe)
    bool IsHammer(int shift, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
    bool IsShootingStar(int shift, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
    bool IsEngulfing(int shift, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
    CombinedSignal GetCombinedPASignal();
    ENUM_SIGNAL_TYPE GetActiveSignal();  // For current timeframe (chart arrows)

    //--- Trend & Session Analysis
    ENUM_MARKET_SESSION  GetCurrentSession();
    ENUM_TREND_DIRECTION GetTrendDirection(ENUM_TIMEFRAMES tf);
    TrendAlignment GetTrendAlignment();

    //--- EMA Distance Calculation
    EMADistance GetEMADistance();

    //--- EMA Touch Detection
    bool CheckEMATouch(ENUM_TIMEFRAMES tf, int ema_period);

    //--- Helper to get EMA value
    double GetEMAValue(ENUM_TIMEFRAMES tf, int period, int shift);

    //--- Quick Scalp: RSI/Stochastic helper methods
    double GetRSIValue(ENUM_TIMEFRAMES tf, int period, int shift);
    double GetStochKValue(ENUM_TIMEFRAMES tf, int k_period, int d_period, int shift);

    //--- Natural Language Advisor
    string GetAdvisorMessage(bool quickScalpMode);
    bool   IsDataReady();
    
    //--- Strategy Helpers
    bool   IsReversalSetup();
    bool   IsBreakoutSetup();

    //--- Entry Point Detection (for UI display)
    EntryPoint GetReversalEntryPoint();   // Get reversal entry price
    EntryPoint GetBreakoutEntryPoint();   // Get breakout entry price

    //--- Pending Order Recommendation
    bool GetRecommendedPending(ENUM_ORDER_TYPE &outType, double &outPrice, double &outSL, double &outTP, int sl_points);

    //--- Getters for Zone Levels
    double GetD1Open()       { return m_d1_open; }
    double GetCurrentPrice() { return m_current_price; }
    int    GetZoneOffset1()  { return m_zone_offset1; }
    int    GetZoneOffset2()  { return m_zone_offset2; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalEngine::CSignalEngine()
{
    m_d1_open = 0.0;
    m_ema_100 = 0.0;
    m_ema_200 = 0.0;
    m_ema_720 = 0.0;
    m_current_price = 0.0;
    m_zone_offset1 = 300;
    m_zone_offset2 = 1000;
    m_handle_ema100 = INVALID_HANDLE;
    m_handle_ema200 = INVALID_HANDLE;
    m_handle_ema720 = INVALID_HANDLE;
    
    m_handle_d1_100 = INVALID_HANDLE; m_handle_d1_200 = INVALID_HANDLE;
    m_handle_h4_100 = INVALID_HANDLE; m_handle_h4_200 = INVALID_HANDLE;
    m_handle_h1_100 = INVALID_HANDLE; m_handle_h1_200 = INVALID_HANDLE;
    m_handle_m15_100 = INVALID_HANDLE; m_handle_m15_200 = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalEngine::~CSignalEngine()
{
    // Release indicator handles
    if(m_handle_ema100 != INVALID_HANDLE)
        IndicatorRelease(m_handle_ema100);
    if(m_handle_ema200 != INVALID_HANDLE)
        IndicatorRelease(m_handle_ema200);
    if(m_handle_ema720 != INVALID_HANDLE)
        IndicatorRelease(m_handle_ema720);
        
    if(m_handle_d1_100 != INVALID_HANDLE) IndicatorRelease(m_handle_d1_100);
    if(m_handle_d1_200 != INVALID_HANDLE) IndicatorRelease(m_handle_d1_200);
    
    if(m_handle_h4_100 != INVALID_HANDLE) IndicatorRelease(m_handle_h4_100);
    if(m_handle_h4_200 != INVALID_HANDLE) IndicatorRelease(m_handle_h4_200);
    
    if(m_handle_h1_100 != INVALID_HANDLE) IndicatorRelease(m_handle_h1_100);
    if(m_handle_h1_200 != INVALID_HANDLE) IndicatorRelease(m_handle_h1_200);
    
    if(m_handle_m15_100 != INVALID_HANDLE) IndicatorRelease(m_handle_m15_100);
    if(m_handle_m15_200 != INVALID_HANDLE) IndicatorRelease(m_handle_m15_200);
}

//+------------------------------------------------------------------+
//| Initialize with zone offsets and GMT offset                      |
//+------------------------------------------------------------------+
void CSignalEngine::Init(int zone_offset1, int zone_offset2, int gmt_offset)
{
    m_zone_offset1 = zone_offset1;
    m_zone_offset2 = zone_offset2;
    m_gmt_offset = gmt_offset;  // Store GMT offset for session time adjustment

    // Create indicator handles once (reused for lifetime of EA)
    m_handle_ema100 = iMA(_Symbol, PERIOD_CURRENT, 100, 0, MODE_EMA, PRICE_CLOSE);
    m_handle_ema200 = iMA(_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
    m_handle_ema720 = iMA(_Symbol, PERIOD_CURRENT, 720, 0, MODE_EMA, PRICE_CLOSE);

    // Create Multi-Timeframe Handles
    m_handle_d1_100 = iMA(_Symbol, PERIOD_D1, 100, 0, MODE_EMA, PRICE_CLOSE);
    m_handle_d1_200 = iMA(_Symbol, PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    m_handle_h4_100 = iMA(_Symbol, PERIOD_H4, 100, 0, MODE_EMA, PRICE_CLOSE);
    m_handle_h4_200 = iMA(_Symbol, PERIOD_H4, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    m_handle_h1_100 = iMA(_Symbol, PERIOD_H1, 100, 0, MODE_EMA, PRICE_CLOSE);
    m_handle_h1_200 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    m_handle_m15_100 = iMA(_Symbol, PERIOD_M15, 100, 0, MODE_EMA, PRICE_CLOSE);
    m_handle_m15_200 = iMA(_Symbol, PERIOD_M15, 200, 0, MODE_EMA, PRICE_CLOSE);

    if(m_handle_ema100 == INVALID_HANDLE)
        Print("Error: Failed to create EMA 100 indicator handle");
    if(m_handle_ema200 == INVALID_HANDLE)
        Print("Error: Failed to create EMA 200 indicator handle");
    if(m_handle_ema720 == INVALID_HANDLE)
        Print("Error: Failed to create EMA 720 indicator handle");

    RefreshData();
}

//+------------------------------------------------------------------+
//| Refresh market data                                              |
//+------------------------------------------------------------------+
void CSignalEngine::RefreshData()
{
   // Get D1 (Daily) open price from iOpen function
   // Index 0 = current daily bar, Index 1 = previous completed day
   m_d1_open = iOpen(_Symbol, PERIOD_D1, 0);

   // Update current bid price
   m_current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Update EMA values using pre-created indicator handles
   // Handles are created once in Init() and reused here
   if(m_handle_ema100 != INVALID_HANDLE)
      m_ema_100 = CopyBufferValue(m_handle_ema100, 0);
   if(m_handle_ema200 != INVALID_HANDLE)
      m_ema_200 = CopyBufferValue(m_handle_ema200, 0);
   if(m_handle_ema720 != INVALID_HANDLE)
      m_ema_720 = CopyBufferValue(m_handle_ema720, 0);
}

//+------------------------------------------------------------------+
//| Helper: Copy buffer value from indicator handle                   |
//+------------------------------------------------------------------+
double CSignalEngine::CopyBufferValue(int handle, int buffer_num)
{
   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(handle, buffer_num, 0, 1, buffer) > 0) {
      return buffer[0];
   }
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get zone level based on type                                     |
//+------------------------------------------------------------------+
double CSignalEngine::GetZoneLevel(ENUM_ZONE_TYPE zone_type)
{
   double point = _Point;
   double level = 0.0;

   switch(zone_type)
   {
      case ZONE_BUY1:   // Buy Zone 1: D1 Open + Offset1
         level = m_d1_open + (m_zone_offset1 * point);
         break;
      case ZONE_BUY2:   // Buy Zone 2: D1 Open + Offset2
         level = m_d1_open + (m_zone_offset2 * point);
         break;
      case ZONE_SELL1:  // Sell Zone 1: D1 Open - Offset1
         level = m_d1_open - (m_zone_offset1 * point);
         break;
      case ZONE_SELL2:  // Sell Zone 2: D1 Open - Offset2
         level = m_d1_open - (m_zone_offset2 * point);
         break;
   }

   return NormalizeDouble(level, _Digits);
}

//+------------------------------------------------------------------+
//| Check if price is in zone                                        |
//+------------------------------------------------------------------+
bool CSignalEngine::IsInZone(double price, ENUM_ZONE_TYPE zone_type)
{
   double zoneLevel = GetZoneLevel(zone_type);
   double tolerance = _Point * 10;  // 10 points tolerance for zone detection

   // Check if price is at or near the zone level
   if(MathAbs(price - zoneLevel) <= tolerance)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Detect Hammer pattern                                            |
//+------------------------------------------------------------------+
bool CSignalEngine::IsHammer(int shift, ENUM_TIMEFRAMES tf)
{
   // Get candle data at specified shift and timeframe
   double open = iOpen(_Symbol, tf, shift);
   double close = iClose(_Symbol, tf, shift);
   double high = iHigh(_Symbol, tf, shift);
   double low = iLow(_Symbol, tf, shift);

   // Calculate body and shadows
   double body = MathAbs(close - open);
   double upperShadow = high - MathMax(open, close);
   double lowerShadow = MathMin(open, close) - low;
   double totalRange = high - low;

   // Avoid division by zero
   if(totalRange == 0) return false;

   // Hammer criteria:
   // 1. Small body (body <= 30% of total range)
   // 2. Long lower shadow (lower shadow >= 2x body)
   // 3. Little or no upper shadow (upper shadow <= 30% of total range)
   // 4. Lower shadow is significant (>= 50% of total range)

   bool smallBody = (body <= totalRange * 0.3);
   bool longLowerShadow = (lowerShadow >= body * 2.0);
   bool littleUpperShadow = (upperShadow <= totalRange * 0.3);
   bool significantLowerShadow = (lowerShadow >= totalRange * 0.5);

   return (smallBody && longLowerShadow && littleUpperShadow && significantLowerShadow);
}

//+------------------------------------------------------------------+
//| Detect Shooting Star pattern                                     |
//+------------------------------------------------------------------+
bool CSignalEngine::IsShootingStar(int shift, ENUM_TIMEFRAMES tf)
{
   // Get candle data at specified shift and timeframe
   double open = iOpen(_Symbol, tf, shift);
   double close = iClose(_Symbol, tf, shift);
   double high = iHigh(_Symbol, tf, shift);
   double low = iLow(_Symbol, tf, shift);

   // Calculate body and shadows
   double body = MathAbs(close - open);
   double upperShadow = high - MathMax(open, close);
   double lowerShadow = MathMin(open, close) - low;
   double totalRange = high - low;

   // Avoid division by zero
   if(totalRange == 0) return false;

   // Shooting Star criteria:
   // 1. Small body (body <= 30% of total range)
   // 2. Long upper shadow (upper shadow >= 2x body)
   // 3. Little or no lower shadow (lower shadow <= 30% of total range)
   // 4. Upper shadow is significant (>= 50% of total range)

   bool smallBody = (body <= totalRange * 0.3);
   bool longUpperShadow = (upperShadow >= body * 2.0);
   bool littleLowerShadow = (lowerShadow <= totalRange * 0.3);
   bool significantUpperShadow = (upperShadow >= totalRange * 0.5);

   return (smallBody && longUpperShadow && littleLowerShadow && significantUpperShadow);
}

//+------------------------------------------------------------------+
//| Detect Engulfing pattern                                         |
//+------------------------------------------------------------------+
bool CSignalEngine::IsEngulfing(int shift, ENUM_TIMEFRAMES tf)
{
   // Get data for current candle (shift) and previous candle (shift+1)
   double currOpen = iOpen(_Symbol, tf, shift);
   double currClose = iClose(_Symbol, tf, shift);
   double prevOpen = iOpen(_Symbol, tf, shift + 1);
   double prevClose = iClose(_Symbol, tf, shift + 1);

   // Current candle body
   double currBody = MathAbs(currClose - currOpen);
   double prevBody = MathAbs(prevClose - prevOpen);

   // Check if previous candle had a body (avoid zero division)
   if(prevBody == 0) return false;

   // Bullish Engulfing: Previous candle bearish, current candle bullish
   // and current body engulfs previous body
   bool prevBearish = (prevClose < prevOpen);
   bool currBullish = (currClose > currOpen);
   bool bullEngulf = (currBullish && prevBearish &&
                      (currOpen <= prevClose) && (currClose >= prevOpen));

   // Bearish Engulfing: Previous candle bullish, current candle bearish
   // and current body engulfs previous body
   bool prevBullish = (prevClose > prevOpen);
   bool currBearish = (currClose < currOpen);
   bool bearEngulf = (currBearish && prevBullish &&
                      (currOpen >= prevClose) && (currClose <= prevOpen));

   // Return true if either bullish or bearish engulfing pattern is detected
   return (bullEngulf || bearEngulf);
}

//+------------------------------------------------------------------+
//| Get current market session (with GMT offset adjustment)          |
//+------------------------------------------------------------------+
ENUM_MARKET_SESSION CSignalEngine::GetCurrentSession()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);

   // Apply GMT offset to get adjusted hour
   int hour = timeStruct.hour - m_gmt_offset;
   int minute = timeStruct.min;  // MQL5 uses 'min' not 'minute'

   // Handle wrap-around for negative/overflow hours
   if(hour < 0) hour += 24;
   if(hour > 23) hour -= 24;

   int currentTime = hour * 60 + minute;  // Convert to minutes

   // Asia Session: 08:00 - 10:00 (480 - 600 minutes)
   if(currentTime >= 480 && currentTime < 600)
      return SESSION_ASIA;

   // Europe Session: 13:30 - 16:00 (810 - 960 minutes)
   if(currentTime >= 810 && currentTime < 960)
      return SESSION_EUROPE;

   // US Session: 19:30 - 22:00 (1170 - 1320 minutes)
   if(currentTime >= 1170 && currentTime < 1320)
      return SESSION_US;

   return SESSION_QUIET;
}

//+------------------------------------------------------------------+
//| Get trend direction for timeframe                                |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CSignalEngine::GetTrendDirection(ENUM_TIMEFRAMES tf)
{
   double ema100, ema200;

   // Use cached values if requesting current chart period (optimization)
   if(tf == PERIOD_CURRENT || tf == _Period)
   {
      ema100 = m_ema_100;
      ema200 = m_ema_200;
   }
   else
   {
      // Fetch fresh values for specific timeframe
      ema100 = GetEMAValue(tf, 100, 0);
      ema200 = GetEMAValue(tf, 200, 0);
   }

   if(ema100 > ema200)
      return TREND_UP;
   else if(ema100 < ema200)
      return TREND_DOWN;

   return TREND_FLAT;
}

//+------------------------------------------------------------------+
//| Check EMA touch detection                                        |
//+------------------------------------------------------------------+
bool CSignalEngine::CheckEMATouch(ENUM_TIMEFRAMES tf, int ema_period)
{
   // Get current candle data (shift 1 = previous completed candle)
   double high1 = iHigh(_Symbol, tf, 1);
   double low1 = iLow(_Symbol, tf, 1);
   double close1 = iClose(_Symbol, tf, 1);

   double high2 = iHigh(_Symbol, tf, 2);
   double low2 = iLow(_Symbol, tf, 2);
   double close2 = iClose(_Symbol, tf, 2);

   // Get EMA value for shift 1 and 2
   // Try to find cached handle first
   int emaHandle = INVALID_HANDLE;
   bool isCached = false;
   
   if(ema_period == 100)
   {
      if(tf == PERIOD_H1) { emaHandle = m_handle_h1_100; isCached = true; }
      else if(tf == PERIOD_CURRENT) { emaHandle = m_handle_ema100; isCached = true; }
   }
   else if(ema_period == 200)
   {
      if(tf == PERIOD_H1) { emaHandle = m_handle_h1_200; isCached = true; }
      else if(tf == PERIOD_CURRENT) { emaHandle = m_handle_ema200; isCached = true; }
   }
   
   // Create temporary handle if not cached
   if(emaHandle == INVALID_HANDLE)
   {
      emaHandle = iMA(_Symbol, tf, ema_period, 0, MODE_EMA, PRICE_CLOSE);
   }

   if(emaHandle == INVALID_HANDLE) return false;

   double emaBuffer[];
   ArraySetAsSeries(emaBuffer, true);
   if(CopyBuffer(emaHandle, 0, 0, 3, emaBuffer) < 3) {
      if(!isCached) IndicatorRelease(emaHandle);
      return false;
   }
   
   if(!isCached) IndicatorRelease(emaHandle);

   double ema1 = emaBuffer[1];  // EMA for candle 1
   double ema2 = emaBuffer[2];  // EMA for candle 2

   // First Touch: Previous candle was away from EMA, current candle touched EMA
   // Bullish Touch: Low touched EMA and closed above
   bool bullTouch = (low2 > ema2) && (low1 <= ema1) && (close1 > ema1);

   // Bearish Touch: High touched EMA and closed below
   bool bearTouch = (high2 < ema2) && (high1 >= ema1) && (close1 < ema1);

   return (bullTouch || bearTouch);
}

//+------------------------------------------------------------------+
//| Get EMA Value for specific TF                                    |
//+------------------------------------------------------------------+
double CSignalEngine::GetEMAValue(ENUM_TIMEFRAMES tf, int period, int shift)
{
   int handle = INVALID_HANDLE;
   
   // Select cached handle
   if(period == 100)
   {
      if(tf == PERIOD_D1) handle = m_handle_d1_100;
      else if(tf == PERIOD_H4) handle = m_handle_h4_100;
      else if(tf == PERIOD_H1) handle = m_handle_h1_100;
      else if(tf == PERIOD_M15) handle = m_handle_m15_100;
      else if(tf == PERIOD_CURRENT) handle = m_handle_ema100;
   }
   else if(period == 200)
   {
      if(tf == PERIOD_D1) handle = m_handle_d1_200;
      else if(tf == PERIOD_H4) handle = m_handle_h4_200;
      else if(tf == PERIOD_H1) handle = m_handle_h1_200;
      else if(tf == PERIOD_M15) handle = m_handle_m15_200;
      else if(tf == PERIOD_CURRENT) handle = m_handle_ema200;
   }
   
   // Fallback for non-cached params (e.g. 720 or other TFs if added later)
   if(handle == INVALID_HANDLE)
   {
       handle = iMA(_Symbol, tf, period, 0, MODE_EMA, PRICE_CLOSE);
       if(handle == INVALID_HANDLE) return 0.0;
       
       double buf[];
       ArraySetAsSeries(buf, true);
       double result = 0.0;
       if(CopyBuffer(handle, 0, shift, 1, buf) > 0) result = buf[0];
       IndicatorRelease(handle);
       return result;
   }

   // Use cached handle
   double buf[];
   ArraySetAsSeries(buf, true);
   double result = 0.0;

   if(CopyBuffer(handle, 0, shift, 1, buf) > 0)
      result = buf[0];

   return result;
}

//+------------------------------------------------------------------+
//| Get Active Signal (current timeframe for chart arrows)           |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalEngine::GetActiveSignal()
{
   // Check for Price Action signals on current timeframe (for chart arrows)
   if(IsHammer(1, PERIOD_CURRENT))
      return SIGNAL_PA_BUY;

   if(IsShootingStar(1, PERIOD_CURRENT))
      return SIGNAL_PA_SELL;

   if(IsEngulfing(1, PERIOD_CURRENT))
   {
      // Determine if bullish or bearish engulfing
      double currClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      double currOpen = iOpen(_Symbol, PERIOD_CURRENT, 1);
      if(currClose > currOpen)
         return SIGNAL_PA_BUY;
      else
         return SIGNAL_PA_SELL;
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get Combined PA Signal (H1 primary, M5 entry)                    |
//+------------------------------------------------------------------+
CombinedSignal CSignalEngine::GetCombinedPASignal()
{
   CombinedSignal result;
   result.h1Signal = SIGNAL_NONE;
   result.m5Signal = SIGNAL_NONE;
   result.description = "NONE";

   // Check H1 for trend direction
   if(IsHammer(1, PERIOD_H1))
      result.h1Signal = SIGNAL_PA_BUY;
   else if(IsShootingStar(1, PERIOD_H1))
      result.h1Signal = SIGNAL_PA_SELL;
   else if(IsEngulfing(1, PERIOD_H1))
   {
      double currClose = iClose(_Symbol, PERIOD_H1, 1);
      double currOpen = iOpen(_Symbol, PERIOD_H1, 1);
      result.h1Signal = (currClose > currOpen) ? SIGNAL_PA_BUY : SIGNAL_PA_SELL;
   }

   // Check M5 for entry timing
   if(IsHammer(1, PERIOD_M5))
      result.m5Signal = SIGNAL_PA_BUY;
   else if(IsShootingStar(1, PERIOD_M5))
      result.m5Signal = SIGNAL_PA_SELL;
   else if(IsEngulfing(1, PERIOD_M5))
   {
      double currClose = iClose(_Symbol, PERIOD_M5, 1);
      double currOpen = iOpen(_Symbol, PERIOD_M5, 1);
      result.m5Signal = (currClose > currOpen) ? SIGNAL_PA_BUY : SIGNAL_PA_SELL;
   }

   // Generate combined description
   if(result.h1Signal == SIGNAL_NONE && result.m5Signal == SIGNAL_NONE)
      result.description = "NONE";
   else if(result.h1Signal != SIGNAL_NONE && result.m5Signal == SIGNAL_NONE)
      result.description = (result.h1Signal == SIGNAL_PA_BUY) ? "H1 BULLISH" : "H1 BEARISH";
   else if(result.h1Signal == SIGNAL_NONE && result.m5Signal != SIGNAL_NONE)
      result.description = (result.m5Signal == SIGNAL_PA_BUY) ? "M5 ENTRY BUY" : "M5 ENTRY SELL";
   else if(result.h1Signal == SIGNAL_PA_BUY && result.m5Signal == SIGNAL_PA_BUY)
      result.description = "H1 BULL + M5 ENTRY";
   else if(result.h1Signal == SIGNAL_PA_SELL && result.m5Signal == SIGNAL_PA_SELL)
      result.description = "H1 BEAR + M5 ENTRY";
   else
      result.description = "MIXED SIGNALS";

   return result;
}

//+------------------------------------------------------------------+
//| Get Trend Alignment (D1, H4, H1)                                 |
//+------------------------------------------------------------------+
TrendAlignment CSignalEngine::GetTrendAlignment()
{
   TrendAlignment result;
   result.d1 = TREND_FLAT;
   result.h4 = TREND_FLAT;
   result.h1 = TREND_FLAT;
   result.score = 0;
   result.strengthText = "No Clear Trend";
   result.strengthColor = clrGray;

   // Get EMA values for each timeframe
   double d1_ema100 = GetEMAValue(PERIOD_D1, 100, 0);
   double d1_ema200 = GetEMAValue(PERIOD_D1, 200, 0);
   double h4_ema100 = GetEMAValue(PERIOD_H4, 100, 0);
   double h4_ema200 = GetEMAValue(PERIOD_H4, 200, 0);
   double h1_ema100 = GetEMAValue(PERIOD_H1, 100, 0);
   double h1_ema200 = GetEMAValue(PERIOD_H1, 200, 0);

   // Determine trend for each timeframe
   if(d1_ema100 > d1_ema200) { result.d1 = TREND_UP; result.score++; }
   else if(d1_ema100 < d1_ema200) { result.d1 = TREND_DOWN; result.score--; }

   if(h4_ema100 > h4_ema200) { result.h4 = TREND_UP; result.score++; }
   else if(h4_ema100 < h4_ema200) { result.h4 = TREND_DOWN; result.score--; }

   if(h1_ema100 > h1_ema200) { result.h1 = TREND_UP; result.score++; }
   else if(h1_ema100 < h1_ema200) { result.h1 = TREND_DOWN; result.score--; }

   // Generate strength text and color based on score
   int absScore = MathAbs(result.score);
   if(absScore == 3)
   {
      result.strengthText = (result.score > 0) ? "STRONG UPTREND" : "STRONG DOWNTREND";
      result.strengthColor = (result.score > 0) ? clrLime : clrRed;
   }
   else if(absScore == 2)
   {
      result.strengthText = (result.score > 0) ? "UPTREND" : "DOWNTREND";
      result.strengthColor = (result.score > 0) ? clrMediumSeaGreen : clrOrangeRed;
   }
   else if(absScore == 1)
   {
      result.strengthText = (result.score > 0) ? "WEAK UPTREND" : "WEAK DOWNTREND";
      result.strengthColor = (result.score > 0) ? clrYellowGreen : clrLightSalmon;
   }
   else
   {
      result.strengthText = "SIDEWAYS";
      result.strengthColor = clrGray;
   }

   return result;
}

//+------------------------------------------------------------------+
//| Get EMA Distance (M15 and H1)                                    |
//+------------------------------------------------------------------+
EMADistance CSignalEngine::GetEMADistance()
{
   EMADistance result;
   result.m15_ema100 = 0;
   result.m15_ema200 = 0;
   result.h1_ema100 = 0;
   result.h1_ema200 = 0;

   // Get EMA values
   double m15_ema100 = GetEMAValue(PERIOD_M15, 100, 0);
   double m15_ema200 = GetEMAValue(PERIOD_M15, 200, 0);
   double h1_ema100 = GetEMAValue(PERIOD_H1, 100, 0);
   double h1_ema200 = GetEMAValue(PERIOD_H1, 200, 0);

   // Calculate distance in points
   if(m15_ema100 > 0)
      result.m15_ema100 = (m_current_price - m15_ema100) / _Point;
   if(m15_ema200 > 0)
      result.m15_ema200 = (m_current_price - m15_ema200) / _Point;
   if(h1_ema100 > 0)
      result.h1_ema100 = (m_current_price - h1_ema100) / _Point;
   if(h1_ema200 > 0)
      result.h1_ema200 = (m_current_price - h1_ema200) / _Point;

   return result;
}

//+------------------------------------------------------------------+
//| Get Current Zone Status                                          |
//+------------------------------------------------------------------+
ENUM_ZONE_STATUS CSignalEngine::GetCurrentZoneStatus()
{
   double zoneBuy1 = GetZoneLevel(ZONE_BUY1);
   double zoneBuy2 = GetZoneLevel(ZONE_BUY2);
   double zoneSell1 = GetZoneLevel(ZONE_SELL1);
   double zoneSell2 = GetZoneLevel(ZONE_SELL2);

   double tolerance = m_zone_offset1 * _Point; // Use offset1 as tolerance

   // Check if price is in any zone (prioritize closer zones)
   if(MathAbs(m_current_price - zoneBuy2) <= tolerance)
      return ZONE_STATUS_IN_BUY2;
   if(MathAbs(m_current_price - zoneBuy1) <= tolerance)
      return ZONE_STATUS_IN_BUY1;
   if(MathAbs(m_current_price - zoneSell2) <= tolerance)
      return ZONE_STATUS_IN_SELL2;
   if(MathAbs(m_current_price - zoneSell1) <= tolerance)
      return ZONE_STATUS_IN_SELL1;

   return ZONE_STATUS_NONE;
}

//+------------------------------------------------------------------+
//| Check if all necessary data is loaded and synchronized           |
//+------------------------------------------------------------------+
bool CSignalEngine::IsDataReady()
{
   // 1. Check if terminal is connected
   if(!TerminalInfoInteger(TERMINAL_CONNECTED)) return false;

   // 2. Check if main indicator handles are calculated
   if(m_handle_ema100 != INVALID_HANDLE && BarsCalculated(m_handle_ema100) < 1) return false;
   if(m_handle_ema200 != INVALID_HANDLE && BarsCalculated(m_handle_ema200) < 1) return false;

   // 3. Check history synchronization for multi-timeframe analysis
   ENUM_TIMEFRAMES tfs[] = {PERIOD_D1, PERIOD_H4, PERIOD_H1};
   for(int i=0; i<ArraySize(tfs); i++)
   {
      if(!SeriesInfoInteger(_Symbol, tfs[i], SERIES_SYNCHRONIZED)) return false;
      
      // Ensure there's at least some history available
      if(iBars(_Symbol, tfs[i]) < 200) return false; 
   }

   return true;
}

//+------------------------------------------------------------------+
//| Get Advisor Message (Natural Language Trade Recommendation)       |
//+------------------------------------------------------------------+
string CSignalEngine::GetAdvisorMessage(bool quickScalpMode)
{
   // Get trend, zone, and signal
   ENUM_TREND_DIRECTION trend = GetTrendDirection(PERIOD_H1);
   ENUM_ZONE_STATUS zone = GetCurrentZoneStatus();
   CombinedSignal combinedSig = GetCombinedPASignal();
   ENUM_SIGNAL_TYPE signal = SIGNAL_NONE;
   if(combinedSig.h1Signal == SIGNAL_PA_BUY || combinedSig.m5Signal == SIGNAL_PA_BUY)
      signal = SIGNAL_PA_BUY;
   else if(combinedSig.h1Signal == SIGNAL_PA_SELL || combinedSig.m5Signal == SIGNAL_PA_SELL)
      signal = SIGNAL_PA_SELL;

   // Zone helpers
   bool isBuyZone = (zone == ZONE_STATUS_IN_BUY1 || zone == ZONE_STATUS_IN_BUY2);
   bool isSellZone = (zone == ZONE_STATUS_IN_SELL1 || zone == ZONE_STATUS_IN_SELL2);

   // ========== MIDDLE ZONE LOGIC (Quick Scalp Guidance) ==========
   if(zone == ZONE_STATUS_NONE)
   {
      if(trend == TREND_UP)
      {
         if(!quickScalpMode)
            return "Trend UP. Enable Quick Scalp for middle zone opportunities.";
         else
            return "Trend UP. Quick Scalp active - watching for RSI/Stochastic signals.";
      }
      else if(trend == TREND_DOWN)
      {
         if(!quickScalpMode)
            return "Trend DOWN. Enable Quick Scalp for middle zone opportunities.";
         else
            return "Trend DOWN. Quick Scalp active - watching for RSI/Stochastic signals.";
      }
      else // FLAT or SIDEWAY
      {
         return "Choppy. Quick Scalp available when trend develops.";
      }
   }

   // ========== BUY ZONE LOGIC ==========
   if(isBuyZone)
   {
      // Quick Scalp warning
      if(quickScalpMode)
         return "At Buy1 zone. Disable Quick Scalp - use Zone Trading instead.";

      // Existing zone messages (preserved)
      if(trend == TREND_UP)
      {
         if(signal == SIGNAL_PA_BUY)
            return "PERFECT BUY: Uptrend + Support + Signal!";
         return "Uptrend pullback to support. Watch for BUY signal.";
      }
      if(trend == TREND_DOWN)
      {
         double supPrice = (zone == ZONE_STATUS_IN_BUY2) ? GetZoneLevel(ZONE_BUY2) : GetZoneLevel(ZONE_BUY1);
         if(signal == SIGNAL_PA_BUY)
            return StringFormat("Counter-trend Buy at support @%.2f. Scalp with caution.", supPrice);
         return StringFormat("Strong Downtrend hitting support @%.2f. Wait for breakdown or bounce.", supPrice);
      }
      // FLAT trend in Buy zone
      if(signal == SIGNAL_PA_BUY)
         return "Range bounce. Buying at support.";
      return "At support in range. Watch for buy signal.";
   }

   // ========== SELL ZONE LOGIC ==========
   if(isSellZone)
   {
      // Quick Scalp warning
      if(quickScalpMode)
         return "At Sell1 zone. Disable Quick Scalp - use Zone Trading instead.";

      // Existing zone messages (preserved)
      if(trend == TREND_UP)
      {
         double resPrice = (zone == ZONE_STATUS_IN_SELL2) ? GetZoneLevel(ZONE_SELL2) : GetZoneLevel(ZONE_SELL1);
         if(signal == SIGNAL_PA_SELL)
            return StringFormat("Counter-trend Sell at resistance @%.2f. Scalp with caution.", resPrice);
         return StringFormat("Strong Uptrend hitting resistance @%.2f. Wait for breakout or pullback.", resPrice);
      }
      if(trend == TREND_DOWN)
      {
         if(signal == SIGNAL_PA_SELL)
            return "PERFECT SELL: Downtrend + Resistance + Signal!";
         return "Downtrend rally to resistance. Watch for SELL signal.";
      }
      // FLAT trend in Sell zone
      if(signal == SIGNAL_PA_SELL)
         return "Range rejection. Selling at resistance.";
      return "At resistance in range. Watch for sell signal.";
   }

   return "Analyzing market...";
}

//+------------------------------------------------------------------+
//| Get Recommended Pending Order (Zone + PA Logic - Real-Time)       |
//+------------------------------------------------------------------+
bool CSignalEngine::GetRecommendedPending(ENUM_ORDER_TYPE &outType, double &outPrice, double &outSL, double &outTP, int sl_points)
{
   // Get current zone and signal (REAL-TIME)
   ENUM_ZONE_STATUS zone = GetCurrentZoneStatus();
   ENUM_SIGNAL_TYPE signal = GetActiveSignal();

   double pt = _Point;
   double zoneLevel = 0;

   // Buy Limit: In Buy Zone + PA Buy Signal (Reversal at Support)
   if((zone == ZONE_STATUS_IN_BUY1 || zone == ZONE_STATUS_IN_BUY2) && signal == SIGNAL_PA_BUY)
   {
      // Get the appropriate zone level
      zoneLevel = (zone == ZONE_STATUS_IN_BUY2) ? GetZoneLevel(ZONE_BUY2) : GetZoneLevel(ZONE_BUY1);

      outType = ORDER_TYPE_BUY_LIMIT;
      outPrice = zoneLevel;  // Entry at zone level (support)
      outSL = outPrice - (sl_points * pt);
      outTP = outPrice + (sl_points * 2 * pt);
      return true;
   }

   // Sell Limit: In Sell Zone + PA Sell Signal (Reversal at Resistance)
   if((zone == ZONE_STATUS_IN_SELL1 || zone == ZONE_STATUS_IN_SELL2) && signal == SIGNAL_PA_SELL)
   {
      // Get the appropriate zone level
      zoneLevel = (zone == ZONE_STATUS_IN_SELL2) ? GetZoneLevel(ZONE_SELL2) : GetZoneLevel(ZONE_SELL1);

      outType = ORDER_TYPE_SELL_LIMIT;
      outPrice = zoneLevel;  // Entry at zone level (resistance)
      outSL = outPrice + (sl_points * pt);
      outTP = outPrice - (sl_points * 2 * pt);
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check for Reversal Setup (PA Signal matches Zone)                |
//+------------------------------------------------------------------+
bool CSignalEngine::IsReversalSetup()
{
   ENUM_ZONE_STATUS zone = GetCurrentZoneStatus();
   ENUM_SIGNAL_TYPE sig = GetActiveSignal();
   
   // Buy Zone + Buy Signal
   if((zone == ZONE_STATUS_IN_BUY1 || zone == ZONE_STATUS_IN_BUY2) && sig == SIGNAL_PA_BUY)
      return true;
      
   // Sell Zone + Sell Signal
   if((zone == ZONE_STATUS_IN_SELL1 || zone == ZONE_STATUS_IN_SELL2) && sig == SIGNAL_PA_SELL)
      return true;
      
   return false;
}

//+------------------------------------------------------------------+
//| Check for Breakout Setup (PA Signal opposes Zone)                |
//+------------------------------------------------------------------+
bool CSignalEngine::IsBreakoutSetup()
{
   ENUM_ZONE_STATUS zone = GetCurrentZoneStatus();
   ENUM_SIGNAL_TYPE sig = GetActiveSignal();
   
   // Buy Zone + Sell Signal (Breaking Support)
   if((zone == ZONE_STATUS_IN_BUY1 || zone == ZONE_STATUS_IN_BUY2) && sig == SIGNAL_PA_SELL)
      return true;
      
   // Sell Zone + Buy Signal (Breaking Resistance)
   if((zone == ZONE_STATUS_IN_SELL1 || zone == ZONE_STATUS_IN_SELL2) && sig == SIGNAL_PA_BUY)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Get Reversal Entry Point (Zone Bounce)                            |
//+------------------------------------------------------------------+
EntryPoint CSignalEngine::GetReversalEntryPoint()
{
   EntryPoint result;
   result.isValid = false;
   result.price = 0.0;
   result.direction = "--";
   result.zone = "--";
   result.description = "--";
   result.timestamp = 0;

   // Check if reversal setup exists
   if(!IsReversalSetup())
      return result;

   ENUM_ZONE_STATUS zone = GetCurrentZoneStatus();
   double zoneLevel = 0.0;
   string zoneName = "";

   // Determine zone level and name
   switch(zone)
   {
      case ZONE_STATUS_IN_BUY1:
         zoneLevel = GetZoneLevel(ZONE_BUY1);
         zoneName = "Buy1";
         break;
      case ZONE_STATUS_IN_BUY2:
         zoneLevel = GetZoneLevel(ZONE_BUY2);
         zoneName = "Buy2";
         break;
      case ZONE_STATUS_IN_SELL1:
         zoneLevel = GetZoneLevel(ZONE_SELL1);
         zoneName = "Sell1";
         break;
      case ZONE_STATUS_IN_SELL2:
         zoneLevel = GetZoneLevel(ZONE_SELL2);
         zoneName = "Sell2";
         break;
      default:
         return result;
   }

   // For reversal: Enter AT the zone level (bounce from support/resistance)
   ENUM_SIGNAL_TYPE sig = GetActiveSignal();

   if((zone == ZONE_STATUS_IN_BUY1 || zone == ZONE_STATUS_IN_BUY2) && sig == SIGNAL_PA_BUY)
   {
      result.isValid = true;
      result.price = zoneLevel;
      result.direction = "BUY";
      result.zone = zoneName;
      result.description = StringFormat("BUY @ %.2f (Bounce %s)", zoneLevel, zoneName);
      result.timestamp = TimeCurrent();  // Capture timestamp for TTL
   }
   else if((zone == ZONE_STATUS_IN_SELL1 || zone == ZONE_STATUS_IN_SELL2) && sig == SIGNAL_PA_SELL)
   {
      result.isValid = true;
      result.price = zoneLevel;
      result.direction = "SELL";
      result.zone = zoneName;
      result.description = StringFormat("SELL @ %.2f (Reject %s)", zoneLevel, zoneName);
      result.timestamp = TimeCurrent();  // Capture timestamp for TTL
   }

   return result;
}

//+------------------------------------------------------------------+
//| Get Breakout Entry Point (Zone Flip)                              |
//+------------------------------------------------------------------+
EntryPoint CSignalEngine::GetBreakoutEntryPoint()
{
   EntryPoint result;
   result.isValid = false;
   result.price = 0.0;
   result.direction = "--";
   result.zone = "--";
   result.description = "--";
   result.timestamp = 0;

   // Check if breakout setup exists
   if(!IsBreakoutSetup())
      return result;

   ENUM_ZONE_STATUS zone = GetCurrentZoneStatus();
   double zoneLevel = 0.0;
   string zoneName = "";
   ENUM_SIGNAL_TYPE sig = GetActiveSignal();

   // Determine zone level and name
   switch(zone)
   {
      case ZONE_STATUS_IN_BUY1:
         zoneLevel = GetZoneLevel(ZONE_BUY1);
         zoneName = "Buy1";
         break;
      case ZONE_STATUS_IN_BUY2:
         zoneLevel = GetZoneLevel(ZONE_BUY2);
         zoneName = "Buy2";
         break;
      case ZONE_STATUS_IN_SELL1:
         zoneLevel = GetZoneLevel(ZONE_SELL1);
         zoneName = "Sell1";
         break;
      case ZONE_STATUS_IN_SELL2:
         zoneLevel = GetZoneLevel(ZONE_SELL2);
         zoneName = "Sell2";
         break;
      default:
         return result;
   }

   double breakOffset = m_zone_offset1 * _Point * 0.5; // Entry beyond zone (half offset)

   // For breakout: Enter BEYOND the zone level (break through support/resistance)
   if((zone == ZONE_STATUS_IN_BUY1 || zone == ZONE_STATUS_IN_BUY2) && sig == SIGNAL_PA_SELL)
   {
      // Breaking support below Buy Zone - Enter SELL below zone
      result.isValid = true;
      result.price = zoneLevel - breakOffset;
      result.direction = "SELL";
      result.zone = zoneName;
      result.description = StringFormat("SELL @ %.2f (Break %s)", result.price, zoneName);
      result.timestamp = TimeCurrent();  // Capture timestamp for TTL
   }
   else if((zone == ZONE_STATUS_IN_SELL1 || zone == ZONE_STATUS_IN_SELL2) && sig == SIGNAL_PA_BUY)
   {
      // Breaking resistance above Sell Zone - Enter BUY above zone
      result.isValid = true;
      result.price = zoneLevel + breakOffset;
      result.direction = "BUY";
      result.zone = zoneName;
      result.description = StringFormat("BUY @ %.2f (Break %s)", result.price, zoneName);
      result.timestamp = TimeCurrent();  // Capture timestamp for TTL
   }

   return result;
}

//+------------------------------------------------------------------+
//| Get RSI value for specified timeframe and shift (Quick Scalp)     |
//+------------------------------------------------------------------+
double CSignalEngine::GetRSIValue(ENUM_TIMEFRAMES tf, int period, int shift)
{
   int handle = iRSI(_Symbol, tf, period, PRICE_CLOSE);
   if(handle == INVALID_HANDLE)
   {
      return -1;  // Error indicator
   }

   double rsiBuffer[];
   ArraySetAsSeries(rsiBuffer, true);
   int copied = CopyBuffer(handle, 0, shift, 1, rsiBuffer);
   IndicatorRelease(handle);

   if(copied <= 0)
      return -1;

   return rsiBuffer[0];
}

//+------------------------------------------------------------------+
//| Get Stochastic K value for specified timeframe and shift          |
//+------------------------------------------------------------------+
double CSignalEngine::GetStochKValue(ENUM_TIMEFRAMES tf, int k_period, int d_period, int shift)
{
   int handle = iStochastic(_Symbol, tf, k_period, d_period, 3, MODE_SMA, STO_LOWHIGH);
   if(handle == INVALID_HANDLE)
   {
      return -1;  // Error indicator
   }

   double stochBuffer[];
   ArraySetAsSeries(stochBuffer, true);
   int copied = CopyBuffer(handle, 0, shift, 1, stochBuffer);
   IndicatorRelease(handle);

   if(copied <= 0)
      return -1;

   return stochBuffer[0];
}

//+------------------------------------------------------------------+
