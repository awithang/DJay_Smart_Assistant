//+------------------------------------------------------------------+
//|                                                    Definitions.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Market Session Enumeration                                       |
//+------------------------------------------------------------------+
enum ENUM_MARKET_SESSION
{
    SESSION_ASIA,   // Asia Session: 08:00 - 10:00
    SESSION_EUROPE, // Europe Session: 13:30 - 16:00
    SESSION_US,     // US Session: 19:30 - 22:00
    SESSION_QUIET   // Outside active trading hours
};

//+------------------------------------------------------------------+
//| Trading Mode Enumeration                                         |
//+------------------------------------------------------------------+
enum ENUM_TRADING_MODE
{
    MODE_MANUAL,    // User places trades manually
    MODE_AUTO       // EA places trades automatically
};

//+------------------------------------------------------------------+
//| Signal Type Enumeration                                         |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE
{
    SIGNAL_NONE,           // No active signal
    SIGNAL_BUY_ZONE,       // Price in Buy Zone
    SIGNAL_SELL_ZONE,      // Price in Sell Zone
    SIGNAL_PA_BUY,         // Price Action Buy Signal (Hammer/Bullish Engulfing)
    SIGNAL_PA_SELL,        // Price Action Sell Signal (Shooting Star/Bearish Engulfing)
    SIGNAL_EMA_TOUCH_BUY,  // EMA Touch Buy Signal
    SIGNAL_EMA_TOUCH_SELL  // EMA Touch Sell Signal
};

//+------------------------------------------------------------------+
//| Trend Direction Enumeration                                     |
//+------------------------------------------------------------------+
enum ENUM_TREND_DIRECTION
{
    TREND_UP,     // Uptrend
    TREND_DOWN,   // Downtrend
    TREND_FLAT    // Sideways/Flat
};

//+------------------------------------------------------------------+
//| Zone Type Enumeration                                           |
//+------------------------------------------------------------------+
enum ENUM_ZONE_TYPE
{
    ZONE_BUY1,    // First Buy Zone (D1 Open + Offset1)
    ZONE_BUY2,    // Second Buy Zone (D1 Open + Offset2)
    ZONE_SELL1,   // First Sell Zone (D1 Open - Offset1)
    ZONE_SELL2    // Second Sell Zone (D1 Open - Offset2)
};

//+------------------------------------------------------------------+
//| Constants                                                        |
//+------------------------------------------------------------------+
#define POINTS_TO_PIPS        10      // Conversion factor (10 points = 1 pip for 5-digit brokers)
#define MQL5_POINT            _Point  // Current symbol point value
#define REFRESH_SECONDS       1       // Timer refresh interval in seconds

//+------------------------------------------------------------------+
//| Trade Request Structure                                         |
//+------------------------------------------------------------------+
struct TradeRequest
{
    ENUM_ORDER_TYPE type;           // Order type (BUY/SELL)
    double            price;        // Entry price
    double            sl;           // Stop loss price
    double            tp;           // Take profit price
    double            risk_percent; // Risk percentage for lot calculation
    string            comment;      // Order comment

    // Constructor for initialization
    void TradeRequest()
    {
        type = ORDER_TYPE_BUY;
        price = 0.0;
        sl = 0.0;
        tp = 0.0;
        risk_percent = 3.0;
        comment = "";
    }
};

//+------------------------------------------------------------------+
