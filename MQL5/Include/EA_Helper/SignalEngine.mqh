//+------------------------------------------------------------------+
//|                                                   SignalEngine.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"
#property strict

#include <EA_Helper/Definitions.mqh>

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

    // Helper method for copying indicator buffer values
    double CopyBufferValue(int handle, int buffer_num);

public:
    //--- Constructor/Destructor
    CSignalEngine();
    ~CSignalEngine();

    //--- Initialization
    void Init(int zone_offset1, int zone_offset2);

    //--- Data Refresh (Called on New Bar or Timer)
    void RefreshData();

    //--- Zone Logic
    double GetZoneLevel(ENUM_ZONE_TYPE zone_type);
    bool   IsInZone(double price, ENUM_ZONE_TYPE zone_type);

    //--- Price Action Pattern Detection
    bool IsHammer(int shift);
    bool IsShootingStar(int shift);
    bool IsEngulfing(int shift);

    //--- Trend & Session Analysis
    ENUM_MARKET_SESSION  GetCurrentSession();
    ENUM_TREND_DIRECTION GetTrendDirection(ENUM_TIMEFRAMES tf);
    ENUM_SIGNAL_TYPE     GetActiveSignal();

    //--- EMA Touch Detection
    bool CheckEMATouch(ENUM_TIMEFRAMES tf, int ema_period);

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
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalEngine::~CSignalEngine()
{
}

//+------------------------------------------------------------------+
//| Initialize with zone offsets                                     |
//+------------------------------------------------------------------+
void CSignalEngine::Init(int zone_offset1, int zone_offset2)
{
    m_zone_offset1 = zone_offset1;
    m_zone_offset2 = zone_offset2;
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

   // Calculate EMA values for the current timeframe
   int emaHandle100 = iMA(_Symbol, PERIOD_CURRENT, 100, 0, MODE_EMA, PRICE_CLOSE);
   int emaHandle200 = iMA(_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
   int emaHandle720 = iMA(_Symbol, PERIOD_CURRENT, 720, 0, MODE_EMA, PRICE_CLOSE);

   if(emaHandle100 != INVALID_HANDLE) {
      m_ema_100 = CopyBufferValue(emaHandle100, 0);
      IndicatorRelease(emaHandle100);
   }
   if(emaHandle200 != INVALID_HANDLE) {
      m_ema_200 = CopyBufferValue(emaHandle200, 0);
      IndicatorRelease(emaHandle200);
   }
   if(emaHandle720 != INVALID_HANDLE) {
      m_ema_720 = CopyBufferValue(emaHandle720, 0);
      IndicatorRelease(emaHandle720);
   }
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
bool CSignalEngine::IsHammer(int shift)
{
   // Get candle data at specified shift (shift 1 = previous completed candle)
   double open = iOpen(_Symbol, PERIOD_CURRENT, shift);
   double close = iClose(_Symbol, PERIOD_CURRENT, shift);
   double high = iHigh(_Symbol, PERIOD_CURRENT, shift);
   double low = iLow(_Symbol, PERIOD_CURRENT, shift);

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
bool CSignalEngine::IsShootingStar(int shift)
{
   // Get candle data at specified shift
   double open = iOpen(_Symbol, PERIOD_CURRENT, shift);
   double close = iClose(_Symbol, PERIOD_CURRENT, shift);
   double high = iHigh(_Symbol, PERIOD_CURRENT, shift);
   double low = iLow(_Symbol, PERIOD_CURRENT, shift);

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
bool CSignalEngine::IsEngulfing(int shift)
{
   // Get data for current candle (shift) and previous candle (shift+1)
   double currOpen = iOpen(_Symbol, PERIOD_CURRENT, shift);
   double currClose = iClose(_Symbol, PERIOD_CURRENT, shift);
   double prevOpen = iOpen(_Symbol, PERIOD_CURRENT, shift + 1);
   double prevClose = iClose(_Symbol, PERIOD_CURRENT, shift + 1);

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
//| Get current market session                                       |
//+------------------------------------------------------------------+
ENUM_MARKET_SESSION CSignalEngine::GetCurrentSession()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);

   int hour = timeStruct.hour;
   int minute = timeStruct.minute;
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
   // Simple trend detection using EMA crossover
   // If EMA 100 > EMA 200 = Uptrend, EMA 100 < EMA 200 = Downtrend

   if(m_ema_100 > m_ema_200)
      return TREND_UP;
   else if(m_ema_100 < m_ema_200)
      return TREND_DOWN;

   return TREND_FLAT;
}

//+------------------------------------------------------------------+
//| Get active signal type                                           |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalEngine::GetActiveSignal()
{
   // Check for Price Action signals on shift 1 (previous completed candle)
   if(IsHammer(1))
      return SIGNAL_PA_BUY;

   if(IsShootingStar(1))
      return SIGNAL_PA_SELL;

   if(IsEngulfing(1))
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
   int emaHandle = iMA(_Symbol, tf, ema_period, 0, MODE_EMA, PRICE_CLOSE);
   if(emaHandle == INVALID_HANDLE) return false;

   double emaBuffer[];
   ArraySetAsSeries(emaBuffer, true);
   if(CopyBuffer(emaHandle, 0, 0, 3, emaBuffer) < 3) {
      IndicatorRelease(emaHandle);
      return false;
   }
   IndicatorRelease(emaHandle);

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
