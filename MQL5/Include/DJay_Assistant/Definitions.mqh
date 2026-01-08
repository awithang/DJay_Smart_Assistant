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
//| Trend Bias Enumeration (Hybrid Mode)                              |
//+------------------------------------------------------------------+
enum ENUM_TREND_BIAS
{
    TREND_BIAS_BULLISH,
    TREND_BIAS_BEARISH,
    TREND_BIAS_NEUTRAL
};

//+------------------------------------------------------------------+
//| Lot Size Calculation Mode (Hybrid Mode)                           |
//+------------------------------------------------------------------+
enum ENUM_LOT_SIZE_MODE
{
    LOT_MODE_RISK_PERCENT,     // Calculate lots based on risk % of account
    LOT_MODE_FIXED_LOTS        // Use fixed lot size (manual)
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
//| Risk:Reward Ratio Enumeration                                     |
//+------------------------------------------------------------------+
enum ENUM_RR_RATIO
{
    RR_1_TO_1,      // Reward = 1.0x Risk
    RR_1_TO_1_5,    // Reward = 1.5x Risk
    RR_1_TO_2       // Reward = 2.0x Risk (Default)
};

//+------------------------------------------------------------------+
//| Global Variable Names for State Persistence                       |
//+------------------------------------------------------------------+
#define GV_RR_RATIO         "DJay_RR_Ratio"
#define GV_TRAILING_ENABLED "DJay_Trailing_Enabled"

//+------------------------------------------------------------------+
//| Constants                                                        |
//+------------------------------------------------------------------+
#define POINTS_TO_PIPS        10      // Conversion factor (10 points = 1 pip for 5-digit brokers)
#define MQL5_POINT            _Point  // Current symbol point value
#define REFRESH_SECONDS       1       // Timer refresh interval in seconds

//--- Windows API Commands
#define WM_COMMAND            0x0111
#define WM_KEYDOWN            0x0100
#define WM_KEYUP              0x0101
#define VK_F7                 0x76

#import "user32.dll"
int PostMessageW(long hWnd, uint Msg, uint wParam, long lParam);
#import

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

    // Hybrid Mode: Direct lot size specification (optional)
    // If lot_size > 0, use this instead of calculating from risk_percent
    double            lot_size;     // Direct lot size (for fixed lot mode)

    // NOTE: MQL5 structs don't reliably support constructors
    // Always initialize manually before use:
    // TradeRequest req;
    // req.type = ORDER_TYPE_BUY;
    // req.price = 0; req.sl = 0; req.tp = 0;
    // req.risk_percent = 1.0;
    // req.comment = "";
    // req.lot_size = 0.0;  // 0 means use risk calculation

    // Constructor for initialization
    TradeRequest()
    {
        type = ORDER_TYPE_BUY;
        price = 0.0;
        sl = 0.0;
        tp = 0.0;
        risk_percent = 3.0;
        comment = "";
        lot_size = 0.0;  // Default: use risk calculation
    }
};

//+------------------------------------------------------------------+
//| Market State Enumeration (Sniper Update)                          |
//+------------------------------------------------------------------+
enum ENUM_MARKET_STATE
{
    STATE_TRENDING,    // Trending market (ADX > threshold)
    STATE_RANGING,     // Ranging market (ADX < threshold)
    STATE_CHOPPY       // Choppy/transition zone
};

//+------------------------------------------------------------------+
//| Momentum Bias Enumeration (Sniper Update)                         |
//+------------------------------------------------------------------+
enum ENUM_MOMENTUM_BIAS
{
    MOMENTUM_STRONG_UP,    // Strong upward momentum
    MOMENTUM_STRONG_DOWN,  // Strong downward momentum
    MOMENTUM_NEUTRAL       // Neutral/sideways momentum
};

//+------------------------------------------------------------------+
//| Slope Direction Enumeration (Sniper Update)                       |
//+------------------------------------------------------------------+
enum ENUM_SLOPE_DIRECTION
{
    SLOPE_FLAT,       // Flat slope (no significant direction)
    SLOPE_UP,         // Moderate upward slope
    SLOPE_DOWN,       // Moderate downward slope
    SLOPE_CRASH       // Steep downward slope (falling knife)
};

//+------------------------------------------------------------------+
//| Trend Matrix Structure (Sniper Update)                            |
//| Multi-timeframe trend alignment for H4, H1, M15                    |
//+------------------------------------------------------------------+
struct TrendMatrix
{
    ENUM_TREND_DIRECTION h4;      // H4 trend (strategic bias)
    ENUM_TREND_DIRECTION h1;      // H1 trend (tactical trend)
    ENUM_TREND_DIRECTION m15;     // M15 trend (entry setup)
    int score;                    // Alignment score (-3 to +3)
    string description;           // Human-readable description
    color displayColor;           // Color for dashboard display

    // Constructor
    void TrendMatrix()
    {
        h4 = TREND_FLAT;
        h1 = TREND_FLAT;
        m15 = TREND_FLAT;
        score = 0;
        description = "No Data";
        displayColor = clrGray;
    }
};

//+------------------------------------------------------------------+
//| Market Context Structure (Sniper Update)                          |
//| Complete market intelligence for decision support                 |
//+------------------------------------------------------------------+
struct MarketContext
{
    // Volatility
    double atrM15;                  // ATR(14) value on M15 in points
    double atrM5;                   // ATR(14) value on M5 in points

    // Momentum
    ENUM_SLOPE_DIRECTION slopeH1;   // H1 EMA slope direction
    double slopeValue;              // Raw slope value (for debugging)
    double emaDistance;             // Distance from Price to H1 EMA 20 (points)

    // Trend Alignment
    TrendMatrix trendMatrix;        // Multi-TF trend analysis

    // Market State
    ENUM_MARKET_STATE marketState;  // TRENDING, RANGING, or CHOPPY
    double adxValue;                // Raw ADX value

    // Structure
    double distanceToNearestZone;   // Distance to nearest structural level (points)
    double spaceToTarget;           // Distance to next logical target (points)
    bool nearStructuralLevel;       // True if price near zone

    // Constructor
    void MarketContext()
    {
        atrM15 = 0.0;
        atrM5 = 0.0;
        slopeH1 = SLOPE_FLAT;
        slopeValue = 0.0;
        emaDistance = 0.0;
        marketState = STATE_CHOPPY;
        adxValue = 0.0;
        distanceToNearestZone = 0.0;
        spaceToTarget = 0.0;
        nearStructuralLevel = false;
    }
};

//+------------------------------------------------------------------+
