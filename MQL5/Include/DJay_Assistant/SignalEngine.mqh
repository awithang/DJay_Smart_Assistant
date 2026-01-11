//+------------------------------------------------------------------+
//|                                                   SignalEngine.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//|                       FORCE RELOAD - Updated 2025-01-11 01:50        |
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
    int    m_handle_adx;        // ADX indicator handle (Current)

    // Cached Multi-Timeframe Handles
    int    m_handle_d1_100, m_handle_d1_200;
    int    m_handle_h4_100, m_handle_h4_200;
    int    m_handle_h1_100, m_handle_h1_200;
    int    m_handle_m15_100, m_handle_m15_200;
    int    m_handle_m15_20, m_handle_m15_50; // Cached for Sniper/Trend Matrix

    // OPTIMIZATION: Persistent Handles for Heavy Indicators
    // Creating/Destroying handles in OnTick causes massive lag (2-3s freezes)
    int    m_handle_rsi_m15;    // RSI 14 on M15
    int    m_handle_rsi_m5;     // RSI 14 on M5
    int    m_handle_stoch_m15;  // Stoch (14,3,3) on M15
    int    m_handle_stoch_m5;   // Stoch (14,3,3) on M5
    int    m_handle_atr_m15;    // ATR 14 on M15
    int    m_handle_atr_m5;     // ATR 14 on M5
    int    m_handle_atr_h1;     // ATR 14 on H1 (for Slope thresholds)

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
    double GetADXValue(ENUM_TIMEFRAMES tf);

    //--- Natural Language Advisor
    string GetAdvisorMessage(bool quickScalpMode);
    bool   IsDataReady();

    //--- Sniper Update: Market Context Functions (Sprint 1)
    double GetATRValue(int period = 14, ENUM_TIMEFRAMES tf = PERIOD_M15);  // Return ATR in points
    ENUM_SLOPE_DIRECTION GetEMASlope(ENUM_TIMEFRAMES tf = PERIOD_H1, int ema_period = 20, double steep_threshold = 0.0);
    TrendMatrix GetTrendMatrix(int h4_fast_ema = 100, int h4_slow_ema = 50,
                               int h1_fast_ema = 100, int h1_slow_ema = 50,
                               int m15_fast_ema = 20, int m15_slow_ema = 50);
    ENUM_MARKET_STATE GetMarketState(double adx_trend_min = 25.0, double adx_range_max = 20.0);
    bool IsNearStructuralLevel(double price, double tolerance_points = 50.0);
    MarketContext GetMarketContext();  // Get complete market context in one call

    //--- Trade Recommendation for Manual Traders (Sprint 7)
    TradeRecommendation GetTradeRecommendation();  // Get natural language trading recommendation
    string FormatMarketState(MarketContext &ctx, ENUM_ZONE_STATUS zone, double rsi, double stoch);
    string FormatPrice(double price);
    string GetZoneText(ENUM_ZONE_STATUS zone);

    //--- Filter States for AUTO MODE STATUS (Sprint 7)
    void GetSniperFilterStates(SniperFilterStates &states);
    void GetHybridFilterStates(HybridFilterStates &states);

    //--- Sniper Update: Sprint 2 - Sniper Filter Functions
    ENUM_SIGNAL_TYPE GetSniperSignal(bool debug_mode = false,  // M15-based filtered signals
                                     double atr_multiplier = 1.0,      // Volume filter multiplier
                                     double zone_tolerance = 50.0);    // Structure proximity tolerance

    //--- Hybrid Mode: M15 Context + M5 Entry (Sprint 6)
    ENUM_SIGNAL_TYPE GetHybridSignal(bool debugMode = false,
                                     double emaMaxDist = 0.5,
                                     double minTrendScore = 2.0);
    ENUM_SIGNAL_TYPE GetActiveSignalTF(ENUM_TIMEFRAMES tf);  // Get PA signal for specific timeframe

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
    m_handle_m15_20 = INVALID_HANDLE; m_handle_m15_50 = INVALID_HANDLE;
    
    // Initialize new persistent handles
    m_handle_rsi_m15 = INVALID_HANDLE; m_handle_rsi_m5 = INVALID_HANDLE;
    m_handle_stoch_m15 = INVALID_HANDLE; m_handle_stoch_m5 = INVALID_HANDLE;
    m_handle_atr_m15 = INVALID_HANDLE; m_handle_atr_m5 = INVALID_HANDLE;
    m_handle_atr_h1 = INVALID_HANDLE;
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
    
    if(m_handle_m15_20 != INVALID_HANDLE) IndicatorRelease(m_handle_m15_20);
    if(m_handle_m15_50 != INVALID_HANDLE) IndicatorRelease(m_handle_m15_50);

    // Release Persistent Handles
    if(m_handle_rsi_m15 != INVALID_HANDLE) IndicatorRelease(m_handle_rsi_m15);
    if(m_handle_rsi_m5 != INVALID_HANDLE) IndicatorRelease(m_handle_rsi_m5);
    if(m_handle_stoch_m15 != INVALID_HANDLE) IndicatorRelease(m_handle_stoch_m15);
    if(m_handle_stoch_m5 != INVALID_HANDLE) IndicatorRelease(m_handle_stoch_m5);
    if(m_handle_atr_m15 != INVALID_HANDLE) IndicatorRelease(m_handle_atr_m15);
    if(m_handle_atr_m5 != INVALID_HANDLE) IndicatorRelease(m_handle_atr_m5);
    if(m_handle_atr_h1 != INVALID_HANDLE) IndicatorRelease(m_handle_atr_h1);

    // Release ADX indicator handle (Quick Scalp choppy market filter)
    if(m_handle_adx != INVALID_HANDLE) IndicatorRelease(m_handle_adx);
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
    
    m_handle_m15_20 = iMA(_Symbol, PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE);
    m_handle_m15_50 = iMA(_Symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);

    // Create Persistent Handles for Strategy Indicators (Optimization)
    // 1. RSI (14)
    m_handle_rsi_m15 = iRSI(_Symbol, PERIOD_M15, 14, PRICE_CLOSE);
    m_handle_rsi_m5  = iRSI(_Symbol, PERIOD_M5, 14, PRICE_CLOSE);
    
    // 2. Stochastic (14, 3, 3)
    m_handle_stoch_m15 = iStochastic(_Symbol, PERIOD_M15, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
    m_handle_stoch_m5  = iStochastic(_Symbol, PERIOD_M5, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
    
    // 3. ATR (14)
    m_handle_atr_m15 = iATR(_Symbol, PERIOD_M15, 14);
    m_handle_atr_m5  = iATR(_Symbol, PERIOD_M5, 14);
    m_handle_atr_h1  = iATR(_Symbol, PERIOD_H1, 14);

    // Create ADX indicator handle for Quick Scalp choppy market filter
    m_handle_adx = iADX(_Symbol, PERIOD_CURRENT, 14);

    if(m_handle_ema100 == INVALID_HANDLE)
        Print("Error: Failed to create EMA 100 indicator handle");
    if(m_handle_adx == INVALID_HANDLE)
        Print("Error: Failed to create ADX indicator handle");
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
   int h = timeStruct.hour - m_gmt_offset;
   int m = timeStruct.min;

   // Handle wrap-around for negative/overflow hours
   if(h < 0) h += 24;
   if(h > 23) h -= 24;

   int currentTime = h * 60 + m;  // Convert to minutes

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
   double ema50;

   // Get EMA 50 value (trend baseline - consistent across all timeframes)
   if(tf == PERIOD_CURRENT || tf == _Period)
   {
      ema50 = m_ema_100;  // Note: Using cached EMA 100 as closest available (could add EMA 50 cache)
   }
   else
   {
      // Fetch fresh value for specific timeframe
      ema50 = GetEMAValue(tf, 50, 0);
   }

   // Determine trend by PRICE POSITION relative to EMA 50
   // This gives real-time trend direction with balanced reaction speed
   double price = m_current_price;

   if(price > ema50)
      return TREND_UP;
   else if(price < ema50)
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
   else if(period == 20 && tf == PERIOD_M15) handle = m_handle_m15_20;
   else if(period == 50 && tf == PERIOD_M15) handle = m_handle_m15_50;
   
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

   // Get EMA 50 values for each timeframe (consistent trend detection)
   double d1_ema50 = GetEMAValue(PERIOD_D1, 50, 0);
   double h4_ema50 = GetEMAValue(PERIOD_H4, 50, 0);
   double h1_ema50 = GetEMAValue(PERIOD_H1, 50, 0);

   // Determine trend by PRICE POSITION relative to EMA 50
   // All timeframes use same EMA period (50) for consistency
   // Each TF calculates its own EMA 50 based on that timeframe's data
   double currentPrice = m_current_price;

   if(currentPrice > d1_ema50) { result.d1 = TREND_UP; result.score++; }
   else if(currentPrice < d1_ema50) { result.d1 = TREND_DOWN; result.score--; }

   if(currentPrice > h4_ema50) { result.h4 = TREND_UP; result.score++; }
   else if(currentPrice < h4_ema50) { result.h4 = TREND_DOWN; result.score--; }

   if(currentPrice > h1_ema50) { result.h1 = TREND_UP; result.score++; }
   else if(currentPrice < h1_ema50) { result.h1 = TREND_DOWN; result.score--; }

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
   // OPTIMIZATION: Use persistent handles instead of creating new ones
   // Only supports standard strategy periods (14) on M15/M5
   int handle = INVALID_HANDLE;
   
   if (period == 14) {
      if (tf == PERIOD_M15) handle = m_handle_rsi_m15;
      else if (tf == PERIOD_M5) handle = m_handle_rsi_m5;
   }
   
   // Fallback for non-standard params (slow, but safe)
   bool isTemp = false;
   if(handle == INVALID_HANDLE)
   {
      handle = iRSI(_Symbol, tf, period, PRICE_CLOSE);
      isTemp = true;
   }

   if(handle == INVALID_HANDLE) return -1;

   double rsiBuffer[];
   ArraySetAsSeries(rsiBuffer, true);
   int copied = CopyBuffer(handle, 0, shift, 1, rsiBuffer);
   
   if(isTemp) IndicatorRelease(handle);

   if(copied <= 0) return -1;

   return rsiBuffer[0];
}

//+------------------------------------------------------------------+
//| Get Stochastic K value for specified timeframe and shift          |
//+------------------------------------------------------------------+
double CSignalEngine::GetStochKValue(ENUM_TIMEFRAMES tf, int k_period, int d_period, int shift)
{
   // OPTIMIZATION: Use persistent handles
   int handle = INVALID_HANDLE;
   
   if (k_period == 14 && d_period == 3) {
      if (tf == PERIOD_M15) handle = m_handle_stoch_m15;
      else if (tf == PERIOD_M5) handle = m_handle_stoch_m5;
   }

   // Fallback
   bool isTemp = false;
   if(handle == INVALID_HANDLE)
   {
      handle = iStochastic(_Symbol, tf, k_period, d_period, 3, MODE_SMA, STO_LOWHIGH);
      isTemp = true;
   }

   if(handle == INVALID_HANDLE) return -1;

   double stochBuffer[];
   ArraySetAsSeries(stochBuffer, true);
   int copied = CopyBuffer(handle, 0, shift, 1, stochBuffer);
   
   if(isTemp) IndicatorRelease(handle);

   if(copied <= 0) return -1;

   return stochBuffer[0];
}

//+------------------------------------------------------------------+
//| Get ADX value for specified timeframe                             |
//| Used in Quick Scalp mode to filter choppy markets                |
//+------------------------------------------------------------------+
double CSignalEngine::GetADXValue(ENUM_TIMEFRAMES tf)
{
   if(m_handle_adx == INVALID_HANDLE)
      return 0.0;

   double adxBuffer[];
   ArraySetAsSeries(adxBuffer, true);

   int copied = CopyBuffer(m_handle_adx, 0, 0, 1, adxBuffer);
   if(copied <= 0)
      return 0.0;

   return adxBuffer[0];
}

//+====================================================================+
//| SNIPER UPDATE: Sprint 1 - Market Context Functions                 |
//+====================================================================+

//+------------------------------------------------------------------+
//| Get ATR Value (Sniper Update)                                     |
//| Calculate Average True Range for specified timeframe and period   |
//| Returns: ATR value in POINTS (not pips)                           |
//+------------------------------------------------------------------+
double CSignalEngine::GetATRValue(int period = 14, ENUM_TIMEFRAMES tf = PERIOD_M15)
{
   // OPTIMIZATION: Use persistent handles
   int handle = INVALID_HANDLE;
   
   if (period == 14) {
      if (tf == PERIOD_M15) handle = m_handle_atr_m15;
      else if (tf == PERIOD_M5) handle = m_handle_atr_m5;
      else if (tf == PERIOD_H1) handle = m_handle_atr_h1;
   }

   // Fallback
   bool isTemp = false;
   if(handle == INVALID_HANDLE)
   {
      handle = iATR(_Symbol, tf, period);
      isTemp = true;
   }

   if(handle == INVALID_HANDLE) return 0.0;

   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);

   int copied = CopyBuffer(handle, 0, 0, 1, atrBuffer);
   
   if(isTemp) IndicatorRelease(handle);

   if(copied <= 0) return 0.0;

   // Convert ATR from price to points
   return atrBuffer[0] / _Point;
}

//+------------------------------------------------------------------+
//| Get EMA Slope Direction (Sniper Update)                           |
//| Calculate the slope of EMA to determine momentum strength         |
//| Parameters:                                                       |
//|   tf - Timeframe for slope calculation                            |
//|   ema_period - EMA period to use                                  |
//|   steep_threshold - Points threshold for "steep" slope (0=auto)   |
//| Returns: SLOPE_FLAT, SLOPE_UP, SLOPE_DOWN, or SLOPE_CRASH         |
//+------------------------------------------------------------------+
ENUM_SLOPE_DIRECTION CSignalEngine::GetEMASlope(ENUM_TIMEFRAMES tf = PERIOD_H1, int ema_period = 20, double steep_threshold = 0.0)
{
   // Get current and previous EMA values
   double emaCurrent = GetEMAValue(tf, ema_period, 0);
   double emaPrev1 = GetEMAValue(tf, ema_period, 1);
   double emaPrev2 = GetEMAValue(tf, ema_period, 2);

   if(emaCurrent <= 0 || emaPrev1 <= 0 || emaPrev2 <= 0)
      return SLOPE_FLAT;

   // Calculate slope as change in EMA over 2 bars (in points)
   double slopeChange = (emaCurrent - emaPrev2) / _Point;

   // Auto-calculate steep threshold if not provided (use 2x ATR as reference)
   if(steep_threshold == 0.0)
   {
      double atr = GetATRValue(14, tf);
      steep_threshold = atr * 2.0;  // Steep = 2x ATR change over 2 bars
   }

   // Determine slope direction
   if(slopeChange > steep_threshold)
      return SLOPE_UP;       // Strong upward slope
   else if(slopeChange > steep_threshold * 0.3)
      return SLOPE_UP;       // Moderate upward slope
   else if(slopeChange < -steep_threshold)
      return SLOPE_CRASH;    // Steep downward (falling knife)
   else if(slopeChange < -steep_threshold * 0.3)
      return SLOPE_DOWN;     // Moderate downward slope
   else
      return SLOPE_FLAT;     // Flat/sideways
}

//+------------------------------------------------------------------+
//| Get Trend Matrix (Sniper Update)                                  |
//| Multi-timeframe trend analysis for H4, H1, M15                    |
//| Uses EMA 50 on all timeframes for consistent trend detection      |
//| Returns: TrendMatrix structure with alignment score               |
//+------------------------------------------------------------------+
TrendMatrix CSignalEngine::GetTrendMatrix(int h4_fast_ema = 100, int h4_slow_ema = 50,
                                          int h1_fast_ema = 100, int h1_slow_ema = 50,
                                          int m15_fast_ema = 20, int m15_slow_ema = 50)
{
   TrendMatrix result;
   result.h4 = TREND_FLAT;
   result.h1 = TREND_FLAT;
   result.m15 = TREND_FLAT;
   result.score = 0;
   result.description = "No Data";
   result.displayColor = clrGray;

   // Get EMA 50 values for all timeframes (consistent trend detection)
   double h4_ema50 = GetEMAValue(PERIOD_H4, 50, 0);
   double h1_ema50 = GetEMAValue(PERIOD_H1, 50, 0);
   double m15_ema50 = GetEMAValue(PERIOD_M15, 50, 0);

   // Get current price (for real-time trend detection)
   double currentPrice = m_current_price;  // Use cached price for consistency

   // Determine trend by PRICE POSITION relative to EMA 50
   // All timeframes use same EMA period (50) for consistency
   // Each TF calculates its own EMA 50 based on that timeframe's data
   if(currentPrice > h4_ema50) { result.h4 = TREND_UP; result.score++; }
   else if(currentPrice < h4_ema50) { result.h4 = TREND_DOWN; result.score--; }

   if(currentPrice > h1_ema50) { result.h1 = TREND_UP; result.score++; }
   else if(currentPrice < h1_ema50) { result.h1 = TREND_DOWN; result.score--; }

   if(currentPrice > m15_ema50) { result.m15 = TREND_UP; result.score++; }
   else if(currentPrice < m15_ema50) { result.m15 = TREND_DOWN; result.score--; }

   // Generate description and color based on alignment score
   int absScore = MathAbs(result.score);

   if(absScore == 3)
   {
      result.description = (result.score > 0) ? "STRONG UPTREND" : "STRONG DOWNTREND";
      result.displayColor = (result.score > 0) ? clrLime : clrRed;
   }
   else if(absScore == 2)
   {
      result.description = (result.score > 0) ? "UPTREND" : "DOWNTREND";
      result.displayColor = (result.score > 0) ? clrMediumSeaGreen : clrOrangeRed;
   }
   else if(absScore == 1)
   {
      result.description = (result.score > 0) ? "WEAK UPTREND" : "WEAK DOWNTREND";
      result.displayColor = (result.score > 0) ? clrYellowGreen : clrLightSalmon;
   }
   else
   {
      // Mixed signals - check for divergence
      if(result.h4 == TREND_UP && result.m15 == TREND_DOWN)
         result.description = "PULLBACK (Bull)";
      else if(result.h4 == TREND_DOWN && result.m15 == TREND_UP)
         result.description = "PULLBACK (Bear)";
      else
         result.description = "MIXED";
      result.displayColor = clrGray;
   }

   return result;
}

//+------------------------------------------------------------------+
//| Get Market State (Sniper Update)                                  |
//| Determine if market is TRENDING, RANGING, or CHOPPY based on ADX  |
//| Parameters:                                                       |
//|   adx_trend_min - Minimum ADX for trending market (default 25)    |
//|   adx_range_max - Maximum ADX for ranging market (default 20)     |
//| Returns: STATE_TRENDING, STATE_RANGING, or STATE_CHOPPY          |
//+------------------------------------------------------------------+
ENUM_MARKET_STATE CSignalEngine::GetMarketState(double adx_trend_min = 25.0, double adx_range_max = 20.0)
{
   double adx = GetADXValue(PERIOD_H1);  // Use H1 ADX for market state

   if(adx >= adx_trend_min)
      return STATE_TRENDING;
   else if(adx <= adx_range_max)
      return STATE_RANGING;
   else
      return STATE_CHOPPY;  // Transition zone
}

//+------------------------------------------------------------------+
//| Is Near Structural Level (Sniper Update)                          |
//| Check if price is near a known structural level (zone)            |
//| Parameters:                                                       |
//|   price - Price to check                                         |
//|   tolerance_points - Distance tolerance in points (default 50)    |
//| Returns: true if price is within tolerance of a zone             |
//+------------------------------------------------------------------+
bool CSignalEngine::IsNearStructuralLevel(double price, double tolerance_points = 50.0)
{
   // Check all zone levels
   double zones[4];
   zones[0] = GetZoneLevel(ZONE_BUY1);
   zones[1] = GetZoneLevel(ZONE_BUY2);
   zones[2] = GetZoneLevel(ZONE_SELL1);
   zones[3] = GetZoneLevel(ZONE_SELL2);

   double tolerance = tolerance_points * _Point;

   for(int i = 0; i < 4; i++)
   {
      if(MathAbs(price - zones[i]) <= tolerance)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Get Market Context (Sniper Update)                                |
//| Get complete market intelligence in a single call                 |
//| Returns: MarketContext structure with all market data            |
//+------------------------------------------------------------------+
MarketContext CSignalEngine::GetMarketContext()
{
   MarketContext ctx;

   // ATR values (volatility)
   ctx.atrM15 = GetATRValue(14, PERIOD_M15);
   ctx.atrM5 = GetATRValue(14, PERIOD_M5);

   // EMA Slope (momentum)
   ctx.slopeH1 = GetEMASlope(PERIOD_H1, 20, 0.0);

   // Calculate raw slope and distance for dashboard display
   double ema20 = GetEMAValue(PERIOD_H1, 20, 0);
   double ema20_prev = GetEMAValue(PERIOD_H1, 20, 2); // 2 bars ago for slope
   
   if (ema20 > 0 && ema20_prev > 0)
      ctx.slopeValue = (ema20 - ema20_prev) / _Point;
      
   if (ema20 > 0)
      ctx.emaDistance = (m_current_price - ema20) / _Point;

   // Trend Matrix (multi-TF alignment)
   ctx.trendMatrix = GetTrendMatrix(100, 50, 100, 50, 20, 50);  // All use EMA 50 for consistency

   // Market State (ADX-based)
   ctx.marketState = GetMarketState(25.0, 20.0);
   ctx.adxValue = GetADXValue(PERIOD_H1);

   // Structure (distance to nearest zone)
   double zones[4];
   zones[0] = GetZoneLevel(ZONE_BUY1);
   zones[1] = GetZoneLevel(ZONE_BUY2);
   zones[2] = GetZoneLevel(ZONE_SELL1);
   zones[3] = GetZoneLevel(ZONE_SELL2);

   double minDistance = DBL_MAX;
   for(int i = 0; i < 4; i++)
   {
      double dist = MathAbs(m_current_price - zones[i]) / _Point;
      if(dist < minDistance)
         minDistance = dist;
   }
   ctx.distanceToNearestZone = minDistance;  // FIX: Assign calculated distance to context

   // Calculate Space to Target (Room to Run)
   double space = 0.0;
   double minSpace = DBL_MAX;
   bool targetFound = false;

   if (ctx.trendMatrix.h1 == TREND_UP)
   {
      // Find nearest zone ABOVE price
      for(int i=0; i<4; i++) {
         if(zones[i] > m_current_price) {
            double dist = (zones[i] - m_current_price) / _Point;
            if(dist < minSpace) { minSpace = dist; targetFound = true; }
         }
      }
   }
   else if (ctx.trendMatrix.h1 == TREND_DOWN)
   {
      // Find nearest zone BELOW price
      for(int i=0; i<4; i++) {
         if(zones[i] < m_current_price) {
            double dist = (m_current_price - zones[i]) / _Point;
            if(dist < minSpace) { minSpace = dist; targetFound = true; }
         }
      }
   }
   
   if(targetFound) ctx.spaceToTarget = minSpace;
   else ctx.spaceToTarget = 0.0; // No target or Flat

   return ctx;
}

//+====================================================================+
//| TRADE RECOMMENDATION: Natural Language Trading Guidance            |
//+====================================================================+

//+------------------------------------------------------------------+
//| Get Trade Recommendation                                          |
//| Generate natural language trading recommendations for manual      |
//| traders based on current market conditions.                       |
//|                                                                   |
//| Analyzes 5 factors:                                               |
//|   1. Trend Strength (score: ±3, ±1, 0)                           |
//|   2. Market State (ADX: trending/ranging/choppy)                 |
//|   3. Zone Location (Buy1/Buy2/Middle/Sell1/Sell2)                |
//|   4. Momentum State (RSI/Stoch: OB/OS/neutral)                   |
//|   5. Price Extension (distance from EMA 20)                      |
//|                                                                   |
//| Returns: TradeRecommendation with natural language guidance      |
//+------------------------------------------------------------------+
TradeRecommendation CSignalEngine::GetTradeRecommendation()
{
   TradeRecommendation rec;
   MarketContext ctx = GetMarketContext();

   // Get additional data
   double rsi = GetRSIValue(PERIOD_M15, 14, 0);
   double stoch = GetStochKValue(PERIOD_M15, 14, 3, 0);
   ENUM_ZONE_STATUS zone = GetCurrentZoneStatus();
   double ema20 = GetEMAValue(PERIOD_M15, 20, 0);
   double currentPrice = m_current_price;
   double atr = ctx.atrM15;
   double emaDistance = (currentPrice - ema20) / _Point;

   // Scenario detection flags
   bool strongTrend = (MathAbs(ctx.trendMatrix.score) >= 3);
   bool moderateTrend = (MathAbs(ctx.trendMatrix.score) >= 1);
   bool isTrending = (ctx.adxValue > 25);
   bool isChoppy = (ctx.adxValue < 20);
   bool isOB = (rsi > 70 || stoch > 80);
   bool isOS = (rsi < 30 || stoch < 20);
   bool inBuyZone = (zone == ZONE_STATUS_IN_BUY1 || zone == ZONE_STATUS_IN_BUY2);
   bool inSellZone = (zone == ZONE_STATUS_IN_SELL1 || zone == ZONE_STATUS_IN_SELL2);
   bool atValue = (MathAbs(emaDistance) <= atr * 0.5);

   // SCENARIO 1: Strong Trend + Favorable Zone + Momentum OK = FOLLOW TREND
   if(strongTrend && isTrending && inBuyZone && !isOB && ctx.trendMatrix.score > 0)
   {
      rec.isValid = true;
      rec.recommendationCode = "BUY";
      rec.recommendationText = "BUY (Market Order)";
      rec.entryType = "BUY MARKET";
      rec.entryPrice = currentPrice;
      rec.takeProfit = currentPrice + (atr * 1.5 * _Point);
      rec.stopLoss = currentPrice - (atr * 1.0 * _Point);
      rec.reasoning = "Strong uptrend with price at value zone. Momentum supports continuation.";
      rec.recommendationColor = clrLime;
   }
   // SCENARIO 2: Strong Trend + Favorable Zone + Momentum OB = WAIT FOR PULLBACK
   else if(strongTrend && isTrending && inBuyZone && isOB && ctx.trendMatrix.score > 0)
   {
      rec.isValid = true;
      rec.recommendationCode = "WAIT_PULLBACK";
      rec.recommendationText = "WAIT FOR PULLBACK";
      rec.entryType = "BUY LIMIT";
      rec.entryPrice = ema20;  // Or current - 0.5*ATR
      rec.takeProfit = rec.entryPrice + (atr * 1.5 * _Point);
      rec.stopLoss = rec.entryPrice - (atr * 1.0 * _Point);
      rec.reasoning = "Strong uptrend but price is overbought and extended. Wait for pullback to EMA 20.";
      rec.alternatives = "Wait for RSI drop below 60 or Stoch drop below 70";
      rec.recommendationColor = C'255,165,0';  // Orange
   }
   // SCENARIO 3: Strong Trend + Unfavorable Zone = WAIT FOR PULLBACK TO BUY ZONE
   else if(strongTrend && isTrending && !inBuyZone && ctx.trendMatrix.score > 0)
   {
      rec.isValid = true;
      rec.recommendationCode = "WAIT_ZONE";
      rec.recommendationText = "WAIT FOR PULLBACK TO BUY ZONE";
      rec.entryType = "BUY LIMIT";
      rec.entryPrice = ema20 - (atr * 0.3 * _Point);
      rec.takeProfit = rec.entryPrice + (atr * 1.5 * _Point);
      rec.stopLoss = rec.entryPrice - (atr * 1.0 * _Point);
      rec.reasoning = "Strong uptrend but price is too extended. Wait for pullback to buy zone.";
      rec.alternatives = "Do NOT chase the move";
      rec.recommendationColor = C'255,255,0';  // Yellow
   }
   // SCENARIO 4: Strong Trend + Unfavorable Zone + Momentum OB = STAY OUT OR REVERSAL
   else if(strongTrend && isTrending && !inBuyZone && isOB && ctx.trendMatrix.score > 0)
   {
      rec.isValid = true;
      rec.recommendationCode = "STAY_OUT";
      rec.recommendationText = "STAY OUT (High Risk)";
      rec.entryType = "";
      rec.reasoning = "Price is severely extended and overbought in uptrend. Risk of sharp pullback is very high.";
      rec.alternatives = "Wait for pullback to BUY zone (safer)";
      rec.recommendationColor = clrRed;
   }
   // SCENARIO 5: Strong Downtrend + Favorable Zone + Momentum OK = FOLLOW DOWNTREND
   else if(strongTrend && isTrending && inSellZone && !isOS && ctx.trendMatrix.score < 0)
   {
      rec.isValid = true;
      rec.recommendationCode = "SELL";
      rec.recommendationText = "SELL (Market Order)";
      rec.entryType = "SELL MARKET";
      rec.entryPrice = currentPrice;
      rec.takeProfit = currentPrice - (atr * 1.5 * _Point);
      rec.stopLoss = currentPrice + (atr * 1.0 * _Point);
      rec.reasoning = "Strong downtrend with price at value zone. Momentum supports continuation.";
      rec.recommendationColor = clrLime;
   }
   // SCENARIO 6: No Clear Trend = RANGE TRADE OR STAY OUT
   else if(!moderateTrend)
   {
      rec.isValid = true;
      rec.recommendationCode = "NO_TREND";
      rec.recommendationText = "STAY OUT (No Trend)";
      rec.entryType = "";
      rec.reasoning = "No clear directional bias. Market is ranging.";
      rec.alternatives = "Consider range trading at zone boundaries";
      rec.recommendationColor = clrGray;
   }
   // SCENARIO 7: Choppy Market = STAY OUT
   else if(isChoppy)
   {
      rec.isValid = true;
      rec.recommendationCode = "CHOPPY";
      rec.recommendationText = "STAY OUT (Market is CHOPPY)";
      rec.entryType = "";
      rec.reasoning = "Market is CHOPPY (ADX < 20). Low volatility, high whipsaw risk.";
      rec.alternatives = "Wait for ADX > 20 before trading";
      rec.recommendationColor = clrRed;
   }
   // DEFAULT: Wait
   else
   {
      rec.isValid = true;
      rec.recommendationCode = "WAIT";
      rec.recommendationText = "WAIT";
      rec.entryType = "";
      rec.reasoning = "Market conditions unclear. Wait for clearer setup.";
      rec.recommendationColor = clrGray;
   }

   // Format text outputs
   rec.marketStateText = FormatMarketState(ctx, zone, rsi, stoch);
   rec.entryPriceText = FormatPrice(rec.entryPrice);
   rec.targetsText = StringFormat("TP: %s | SL: %s",
                                   FormatPrice(rec.takeProfit),
                                   FormatPrice(rec.stopLoss));

   return rec;
}

//+------------------------------------------------------------------+
//| Format Market State Text                                         |
//| Create a formatted string describing current market conditions  |
//+------------------------------------------------------------------+
string CSignalEngine::FormatMarketState(MarketContext &ctx, ENUM_ZONE_STATUS zone, double rsi, double stoch)
{
   string trendText = (ctx.trendMatrix.score > 0) ? "UP" :
                      (ctx.trendMatrix.score < 0) ? "DN" : "NT";
   string score = StringFormat("%+d", ctx.trendMatrix.score);
   string arrows = StringFormat("%s%s%s",
                                (ctx.trendMatrix.h4 == TREND_UP) ? "↑" : (ctx.trendMatrix.h4 == TREND_DOWN) ? "↓" : "→",
                                (ctx.trendMatrix.h1 == TREND_UP) ? "↑" : (ctx.trendMatrix.h1 == TREND_DOWN) ? "↓" : "→",
                                (ctx.trendMatrix.m15 == TREND_UP) ? "↑" : (ctx.trendMatrix.m15 == TREND_DOWN) ? "↓" : "→");

   string zoneText = GetZoneText(zone);
   string obOsText = (rsi > 70) ? "OB" : (rsi < 30) ? "OS" : "Neut";

   // Compact format: UP+3(↑↑↑) ADX:25.5 Zone:BUY1 RSI:60(Neut)
   return StringFormat("%s%s%s ADX:%.1f Zone:%s RSI:%.0f(%s)",
                      trendText, score, arrows, ctx.adxValue, zoneText, rsi, obOsText);
}

//+------------------------------------------------------------------+
//| Format Price with Proper Precision                                |
//| Convert price to string with correct decimal places              |
//+------------------------------------------------------------------+
string CSignalEngine::FormatPrice(double price)
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   return DoubleToString(price, digits);
}

//+------------------------------------------------------------------+
//| Get Zone Text                                                     |
//| Convert zone enum to readable string                             |
//+------------------------------------------------------------------+
string CSignalEngine::GetZoneText(ENUM_ZONE_STATUS zone)
{
   switch(zone)
   {
      case ZONE_STATUS_IN_BUY1: return "BUY1";
      case ZONE_STATUS_IN_BUY2: return "BUY2";
      case ZONE_STATUS_IN_SELL1: return "SELL1";
      case ZONE_STATUS_IN_SELL2: return "SELL2";
      default: return "MIDDLE";
   }
}

//+====================================================================+
//| FILTER STATES FOR AUTO MODE STATUS DISPLAY                          |
//+====================================================================+

//+------------------------------------------------------------------+
//| Get Sniper Filter States                                           |
//+------------------------------------------------------------------+
void CSignalEngine::GetSniperFilterStates(SniperFilterStates &states)
{
   MarketContext ctx = GetMarketContext();

   // FILTER 1: PA Check
   bool isHammer = IsHammer(1, PERIOD_M15);
   bool isShootingStar = IsShootingStar(1, PERIOD_M15);
   bool isEngulfing = IsEngulfing(1, PERIOD_M15);
   states.PA = (isHammer || isShootingStar || isEngulfing);

   // FILTER 2: Pullback/Location Check
   double atrM15 = ctx.atrM15;
   double ema20 = GetEMAValue(PERIOD_M15, 20, 0);
   double currentPrice = m_current_price;
   double emaDistance = (currentPrice - ema20) / _Point;

   // Use same adaptive logic as GetSniperSignal
   double adx = GetADXValue(PERIOD_H1);
   double baseMultiplier = 0.5;
   double adaptiveMultiplier = baseMultiplier;

   if(adx < 20) adaptiveMultiplier = baseMultiplier * 0.6;
   else if(adx >= 20 && adx < 25) adaptiveMultiplier = baseMultiplier;
   else if(adx >= 25 && adx < 30) adaptiveMultiplier = baseMultiplier * 2.0;
   else adaptiveMultiplier = baseMultiplier * 3.0;

   // For buy: price should be at or below EMA (allow tolerance)
   // For sell: price should be at or above EMA (allow tolerance)
   bool buyOK = (emaDistance <= atrM15 * adaptiveMultiplier);
   bool sellOK = (emaDistance >= -atrM15 * adaptiveMultiplier);
   states.LOC = (buyOK || sellOK);

   // FILTER 3: Volume Check (candle body >= ATR)
   double openM15 = iOpen(_Symbol, PERIOD_M15, 1);
   double closeM15 = iClose(_Symbol, PERIOD_M15, 1);
   double bodySize = MathAbs(closeM15 - openM15) / _Point;
   states.VOL = (bodySize >= atrM15);

   // FILTER 4: Zone Check (price touched/wicked a zone)
   ENUM_ZONE_STATUS zone = GetCurrentZoneStatus();
   states.ZONE = (zone != ZONE_STATUS_NONE);
}

//+------------------------------------------------------------------+
//| Get Hybrid Filter States                                           |
//+------------------------------------------------------------------+
void CSignalEngine::GetHybridFilterStates(HybridFilterStates &states)
{
   MarketContext ctx = GetMarketContext();

   // FILTER 1: Trend Alignment
   states.TrendScore = ctx.trendMatrix.score;
   states.Trend = (MathAbs(ctx.trendMatrix.score) >= 1);

   // FILTER 2: Market State (not choppy)
   states.ADX = (ctx.adxValue >= 20);

   // FILTER 3: Volatility Check
   states.ATR = (ctx.atrM15 > 50);

   // FILTER 4: M5 PA Signal
   ENUM_SIGNAL_TYPE m5Signal = GetActiveSignalTF(PERIOD_M5);
   states.M5 = (m5Signal == SIGNAL_PA_BUY || m5Signal == SIGNAL_PA_SELL);

   // FILTER 5: M5 direction matches trend bias
   if(m5Signal == SIGNAL_PA_BUY && ctx.trendMatrix.score > 0)
      states.M5Match = true;
   else if(m5Signal == SIGNAL_PA_SELL && ctx.trendMatrix.score < 0)
      states.M5Match = true;
   else
      states.M5Match = false;
}

//+====================================================================+
//| SNIPER UPDATE: Sprint 2 - Sniper Filter Functions                 |
//+====================================================================+

//+------------------------------------------------------------------+
//| Get Sniper Signal (Sniper Filter)                                 |
//| M15-based filtered signals with 3-filter stack for high-quality  |
//| entries. Used for auto-trading decisions.                        |
//|                                                                   |
//| Filter Stack:                                                     |
//|   1. Pullback: Price must be at value (near M15 EMA)             |
//|   2. Volume: Signal candle body > ATR(14) * multiplier           |
//|   3. Structure: Price must touch/wick a known structural level   |
//|                                                                   |
//| Returns: SIGNAL_PA_BUY, SIGNAL_PA_SELL, or SIGNAL_NONE            |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalEngine::GetSniperSignal(bool debug_mode = false,
                                               double atr_multiplier = 1.0,
                                               double zone_tolerance = 50.0)
{
   //--- Get market context data
   double atrM15 = GetATRValue(14, PERIOD_M15);
   double ema20 = GetEMAValue(PERIOD_M15, 20, 0);  // M15 EMA 20 for pullback check
   double currentPrice = m_current_price;

   //--- Check M15 Price Action signals (shift 1 = previous completed candle)
   bool isHammer = IsHammer(1, PERIOD_M15);
   bool isShootingStar = IsShootingStar(1, PERIOD_M15);
   bool isEngulfing = IsEngulfing(1, PERIOD_M15);

   //--- Determine signal direction from PA patterns
   ENUM_SIGNAL_TYPE rawSignal = SIGNAL_NONE;
   double signalOpen = iOpen(_Symbol, PERIOD_M15, 1);
   double signalClose = iClose(_Symbol, PERIOD_M15, 1);
   double signalHigh = iHigh(_Symbol, PERIOD_M15, 1);
   double signalLow = iLow(_Symbol, PERIOD_M15, 1);

   if(isHammer)
      rawSignal = SIGNAL_PA_BUY;
   else if(isShootingStar)
      rawSignal = SIGNAL_PA_SELL;
   else if(isEngulfing)
      rawSignal = (signalClose > signalOpen) ? SIGNAL_PA_BUY : SIGNAL_PA_SELL;

   //--- No raw signal found
   if(rawSignal == SIGNAL_NONE)
   {
      if(debug_mode)
         Print("[Sniper Filter] REJECTED: No M15 PA pattern detected");
      return SIGNAL_NONE;
   }

   //====================================================================
   // FILTER 1: PULLBACK CHECK (Price at Value) - ADAPTIVE
   // Buy: Price should be below or near EMA (discounted)
   // Sell: Price should be above or near EMA (extended)
   //====================================================================
   double emaDistance = (currentPrice - ema20) / _Point;  // Points from EMA

   // ADAPTIVE LOCATION FILTER: Adjust tolerance based on ADX
   double adx = GetADXValue(PERIOD_H1);
   double baseMultiplier = 0.5;  // Default base multiplier
   double adaptiveMultiplier = baseMultiplier;

   if(adx < 20) {
      adaptiveMultiplier = baseMultiplier * 0.6;  // 0.5 → 0.3 (tighter in choppy)
   } else if(adx >= 20 && adx < 25) {
      adaptiveMultiplier = baseMultiplier;  // 0.5 (standard)
   } else if(adx >= 25 && adx < 30) {
      adaptiveMultiplier = baseMultiplier * 2.0;  // 0.5 → 1.0 (trending)
   } else {
      adaptiveMultiplier = baseMultiplier * 3.0;  // 0.5 → 1.5 (strong trend)
   }

   bool pullbackOK = false;
   if(rawSignal == SIGNAL_PA_BUY)
   {
      // For buy: Price should be at or below EMA (buying the dip)
      // Allow adaptive tolerance based on market conditions
      pullbackOK = (emaDistance <= atrM15 * adaptiveMultiplier);

      if(debug_mode && !pullbackOK)
         Print(StringFormat("[Sniper Filter] REJECTED (Buy): Price %d pts ABOVE EMA (max %d pts, ADX=%.1f, mult=%.2f)",
                          (int)emaDistance, (int)(atrM15 * adaptiveMultiplier), adx, adaptiveMultiplier));
   }
   else if(rawSignal == SIGNAL_PA_SELL)
   {
      // For sell: Price should be at or above EMA (selling the rally)
      // Allow adaptive tolerance based on market conditions
      pullbackOK = (emaDistance >= -atrM15 * adaptiveMultiplier);

      if(debug_mode && !pullbackOK)
         Print(StringFormat("[Sniper Filter] REJECTED (Sell): Price %d pts BELOW EMA (max %d pts, ADX=%.1f, mult=%.2f)",
                          (int)MathAbs(emaDistance), (int)(atrM15 * adaptiveMultiplier), adx, adaptiveMultiplier));
   }

   if(debug_mode && pullbackOK)
      Print(StringFormat("[Sniper Filter] Pullback OK: %d pts (max %d pts, ADX=%.1f, mult=%.2f)",
                       (int)emaDistance, (int)(atrM15 * adaptiveMultiplier), adx, adaptiveMultiplier));

   if(!pullbackOK)
      return SIGNAL_NONE;

   //====================================================================
   // FILTER 2: VOLUME/MOMENTUM CHECK (Strong Move)
   // Signal candle body must be significant compared to ATR
   //====================================================================
   double candleBody = MathAbs(signalClose - signalOpen) / _Point;  // Body in points
   double candleRange = (signalHigh - signalLow) / _Point;          // Full range in points

   // Use the larger of body or range for momentum check
   double candleStrength = MathMax(candleBody, candleRange);
   double requiredStrength = atrM15 * atr_multiplier;

   bool volumeOK = (candleStrength >= requiredStrength);

   if(debug_mode && !volumeOK)
      Print(StringFormat("[Sniper Filter] REJECTED: Candle strength %.0f pts < ATR*%.1f (%.0f pts)",
                       candleStrength, atr_multiplier, requiredStrength));

   if(!volumeOK)
      return SIGNAL_NONE;

   //====================================================================
   // FILTER 3: STRUCTURAL ANCHOR CHECK (High-Probability Location)
   // Signal must occur near a known structural level (zone)
   // Check: signal candle's high/low touched a zone
   //====================================================================
   bool nearZone = false;

   // Check if signal candle touched any zone
   if(rawSignal == SIGNAL_PA_BUY)
   {
      // For buy: check if the LOW (wick) touched a buy zone or support
      // OR if the signal candle closed near a buy zone
      double buyZone1 = GetZoneLevel(ZONE_BUY1);
      double buyZone2 = GetZoneLevel(ZONE_BUY2);

      double tolerance = zone_tolerance * _Point;

      // Check if signal low touched a buy zone
      bool touchedBuy1 = (MathAbs(signalLow - buyZone1) <= tolerance);
      bool touchedBuy2 = (MathAbs(signalLow - buyZone2) <= tolerance);
      bool closedNearBuy1 = (MathAbs(signalClose - buyZone1) <= tolerance);
      bool closedNearBuy2 = (MathAbs(signalClose - buyZone2) <= tolerance);

      nearZone = (touchedBuy1 || touchedBuy2 || closedNearBuy1 || closedNearBuy2);
   }
   else if(rawSignal == SIGNAL_PA_SELL)
   {
      // For sell: check if the HIGH (wick) touched a sell zone or resistance
      // OR if the signal candle closed near a sell zone
      double sellZone1 = GetZoneLevel(ZONE_SELL1);
      double sellZone2 = GetZoneLevel(ZONE_SELL2);

      double tolerance = zone_tolerance * _Point;

      // Check if signal high touched a sell zone
      bool touchedSell1 = (MathAbs(signalHigh - sellZone1) <= tolerance);
      bool touchedSell2 = (MathAbs(signalHigh - sellZone2) <= tolerance);
      bool closedNearSell1 = (MathAbs(signalClose - sellZone1) <= tolerance);
      bool closedNearSell2 = (MathAbs(signalClose - sellZone2) <= tolerance);

      nearZone = (touchedSell1 || touchedSell2 || closedNearSell1 || closedNearSell2);
   }

   if(debug_mode && !nearZone)
      Print(StringFormat("[Sniper Filter] REJECTED: Signal not within %d pts of structural level",
                       (int)zone_tolerance));

   if(!nearZone)
      return SIGNAL_NONE;

   //====================================================================
   // ALL FILTERS PASSED - RETURN VALID SIGNAL
   //====================================================================
   if(debug_mode)
   {
      string signalType = (rawSignal == SIGNAL_PA_BUY) ? "BUY" : "SELL";
      Print(StringFormat("[Sniper Filter] ✓ VALID %s SIGNAL: Pullback=OK, Volume=%.0f pts, Structure=OK",
                       signalType, candleStrength));
   }

   return rawSignal;
}

//+====================================================================+
//| HYBRID MODE: Sprint 6 - M15 Context + M5 Entry                    |
//+====================================================================+

//+------------------------------------------------------------------+
//| Get Active Signal for Specific Timeframe                           |
//| Helper function to get PA signal on any timeframe                 |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalEngine::GetActiveSignalTF(ENUM_TIMEFRAMES tf)
{
   // Check for Price Action signals on specified timeframe
   if(IsHammer(1, tf))
      return SIGNAL_PA_BUY;

   if(IsShootingStar(1, tf))
      return SIGNAL_PA_SELL;

   if(IsEngulfing(1, tf))
   {
      // Determine if bullish or bearish engulfing
      double currClose = iClose(_Symbol, tf, 1);
      double currOpen = iOpen(_Symbol, tf, 1);
      if(currClose > currOpen)
         return SIGNAL_PA_BUY;
      else
         return SIGNAL_PA_SELL;
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get Hybrid Signal (M15 Context + M5 Entry)                        |
//|                                                                   |
//| Combines M15 context/permission with M5 entry timing.            |
//|                                                                   |
//| Filter Stack:                                                     |
//|   1. M15 Trend Alignment (H4+H1+M15, min 2/3 agree)              |
//|   2. M15 Market State (Skip CHOPPY)                              |
//|   3. M15 Volatility (Minimum ATR check)                           |
//|   4. M5 PA Trigger (Hammer/Engulfing/Shooting Star)               |
//|   5. Location Filter (Price near M15 EMA - pullback to value)    |
//|   6. Direction Alignment (Signal matches M15 bias)                |
//|   7. Slope Safety (No falling knife for buys, no rocket for sell)|
//|                                                                   |
//| Returns:                                                          |
//|   SIGNAL_PA_BUY  - Valid buy signal (M15 bullish + M5 trigger)    |
//|   SIGNAL_PA_SELL - Valid sell signal (M15 bearish + M5 trigger)   |
//|   SIGNAL_NONE    - No valid signal                                |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalEngine::GetHybridSignal(bool debugMode,
                                                double emaMaxDist,
                                                double minTrendScore)
{
   //───────────────────────────────────────
   // STEP 1: M15 CONTEXT CHECK (Permission)
   //───────────────────────────────────────

   // 1a. Trend Alignment (H4 + H1 + M15)
   TrendMatrix tm = GetTrendMatrix();
   int trendScore = tm.score;  // Use the calculated score, not enum values

   bool bullishContext = (trendScore >= (int)minTrendScore);   // At least 2/3 bullish
   bool bearishContext = (trendScore <= -(int)minTrendScore);  // At least 2/3 bearish

   if(!bullishContext && !bearishContext)
   {
      if(debugMode)
         Print("HYBRID: No clear trend bias (score=", trendScore, ") - WAIT");
      return SIGNAL_NONE;
   }

   // 1b. Market State (Skip CHOPPY markets)
   ENUM_MARKET_STATE state = GetMarketState();
   if(state == STATE_CHOPPY)
   {
      if(debugMode)
         Print("HYBRID: Market is CHOPPY - wait");
      return SIGNAL_NONE;
   }

   // 1c. Volatility Check (Need minimum movement)
   double atrM15 = GetATRValue(14, PERIOD_M15);
   if(atrM15 <= 0)
   {
      if(debugMode)
         Print("HYBRID: Invalid ATR value");
      return SIGNAL_NONE;
   }

   //───────────────────────────────────────
   // STEP 2: M5 ENTRY TRIGGER
   //───────────────────────────────────────

   ENUM_SIGNAL_TYPE m5Signal = GetActiveSignalTF(PERIOD_M5);

   if(m5Signal == SIGNAL_NONE)
      return SIGNAL_NONE;

   //───────────────────────────────────────
   // STEP 3: LOCATION FILTER (Pullback to Value)
   //───────────────────────────────────────

   double priceM15 = iClose(_Symbol, PERIOD_M15, 0);
   double emaM15 = GetEMAValue(PERIOD_M15, 20, 0);

   if(emaM15 <= 0)
   {
      if(debugMode)
         Print("HYBRID: Invalid EMA value");
      return SIGNAL_NONE;
   }

   // Calculate distance from M15 EMA (in points)
   double distFromEMA = MathAbs(priceM15 - emaM15) / _Point;

   // ADAPTIVE LOCATION FILTER: Adjust max distance based on ADX (market volatility)
   double adx = GetADXValue(PERIOD_H1);
   double adaptiveMultiplier = emaMaxDist;  // Default/base multiplier

   if(adx < 20) {
      // Choppy/Ranging market → Use tighter filter (safer entries)
      adaptiveMultiplier = emaMaxDist * 0.6;  // 0.5 → 0.3
   } else if(adx >= 20 && adx < 25) {
      // Transition zone → Use standard filter
      adaptiveMultiplier = emaMaxDist;  // 0.5
   } else if(adx >= 25 && adx < 30) {
      // Trending market → Relax filter (catch moves)
      adaptiveMultiplier = emaMaxDist * 2.0;  // 0.5 → 1.0
   } else {
      // Strong trend (ADX >= 30) → Much looser filter (allow extended entries)
      adaptiveMultiplier = emaMaxDist * 3.0;  // 0.5 → 1.5
   }

   double maxAllowedDist = atrM15 * adaptiveMultiplier;

   bool atValue = (distFromEMA <= maxAllowedDist);

   if(!atValue)
   {
      if(debugMode)
         Print("HYBRID: Price too far from M15 EMA (", distFromEMA, " pts, max=",
               maxAllowedDist, " pts, ADX=", adx, ", mult=", adaptiveMultiplier, ") - WAIT FOR PULLBACK");
      return SIGNAL_NONE;
   }

   if(debugMode)
      Print("HYBRID: Location OK (", distFromEMA, " pts / ", maxAllowedDist, " pts max, ADX=", adx, ", mult=", adaptiveMultiplier, ")");

   //───────────────────────────────────────
   // STEP 4: DIRECTION ALIGNMENT
   //───────────────────────────────────────

   if(m5Signal == SIGNAL_PA_BUY)
   {
      // Must have bullish M15 context
      if(!bullishContext)
      {
         if(debugMode)
            Print("HYBRID: BUY signal rejected - M15 context not bullish (score=", trendScore, ")");
         return SIGNAL_NONE;
      }

      // Additional safety: Slope crash check (falling knife protection)
      ENUM_SLOPE_DIRECTION slopeM15 = GetEMASlope(PERIOD_M15, 20);
      if(slopeM15 == SLOPE_CRASH)
      {
         if(debugMode)
            Print("HYBRID: BUY signal rejected - M15 slope is CRASH (falling knife)");
         return SIGNAL_NONE;
      }

      if(debugMode)
         Print("HYBRID: VALID BUY SIGNAL - M15 Bullish (score=", trendScore, ") + M5 Trigger @ ", priceM15);

      return SIGNAL_PA_BUY;
   }
   else if(m5Signal == SIGNAL_PA_SELL)
   {
      // Must have bearish M15 context
      if(!bearishContext)
      {
         if(debugMode)
            Print("HYBRID: SELL signal rejected - M15 context not bearish (score=", trendScore, ")");
         return SIGNAL_NONE;
      }

      // Additional safety: Slope rocket check
      ENUM_SLOPE_DIRECTION slopeM15 = GetEMASlope(PERIOD_M15, 20);
      if(slopeM15 == SLOPE_UP)
      {
         if(debugMode)
            Print("HYBRID: SELL signal rejected - M15 slope is UP (rocket)");
         return SIGNAL_NONE;
      }

      if(debugMode)
         Print("HYBRID: VALID SELL SIGNAL - M15 Bearish (score=", trendScore, ") + M5 Trigger @ ", priceM15);

      return SIGNAL_PA_SELL;
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
