# Data Model & Class Structure

**Input**: Feature Specification, Research Decisions

## Core Entities (Classes/Structs)

### 1. `SignalEngine` (The Brain)
Responsible for all market analysis.

```cpp
enum ENUM_MARKET_SESSION {
    SESSION_ASIA,   // 08:00 - 10:00
    SESSION_EUROPE, // 13:30 - 16:00
    SESSION_US,     // 19:30 - 22:00
    SESSION_QUIET   // Outside active hours
};

enum ENUM_SIGNAL_TYPE {
    SIGNAL_NONE,
    SIGNAL_BUY_ZONE,
    SIGNAL_SELL_ZONE,
    SIGNAL_PA_BUY,
    SIGNAL_PA_SELL,
    SIGNAL_EMA_TOUCH_BUY,
    SIGNAL_EMA_TOUCH_SELL
};

class CSignalEngine {
private:
    double m_d1_open;
    double m_ema_100, m_ema_200, m_ema_720;
    
public:
    void RefreshData(); // Called on New Bar or Timer
    
    // Zone Logic
    double GetZoneLevel(int offset_points);
    bool IsInZone(double price, int zone_type);
    
    // PA Logic
    bool IsHammer(int shift);
    bool IsShootingStar(int shift);
    bool IsEngulfing(int shift);
    
    // Trend & Session
    ENUM_MARKET_SESSION GetCurrentSession();
    int GetTrendDirection(ENUM_TIMEFRAMES tf); // 1=Up, -1=Down, 0=Flat
};
```

### 2. `TradeManager` (The Executioner)
Handles risk math and order sending.

```cpp
struct TradeRequest {
    ENUM_ORDER_TYPE type;
    double price;
    double sl;
    double tp;
    double risk_percent;
};

class CTradeManager {
public:
    // Risk Calculation
    double CalculateLotSize(double entry_price, double sl_price, double risk_percent);
    
    // Execution
    bool ExecuteOrder(TradeRequest &req);
    void CloseAllOrders();
    void TrailingStop();
};
```

### 3. `DashboardPanel` (The Face)
Manages UI objects.

```cpp
class CDashboardPanel {
private:
    CButton m_btn_buy, m_btn_sell;
    CEdit   m_input_risk;
    CLabel  m_lbl_session, m_lbl_signal;
    // ... other UI elements
    
public:
    void Init(long chart_id);
    void UpdateValues(double price, double profit, string signal_text);
    void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
};
```

## Data Flow

1. **OnTick()**:
   - `TradeManager` checks open positions (Trailing SL, Profit).
   - `DashboardPanel` updates Price/Profit labels.

2. **OnTimer()** (1 second):
   - `SignalEngine` checks TimeCurrent for Session updates.
   - `SignalEngine` checks D1/H1/H4 for Trend updates.
   - If `SignalEngine` detects NEW Signal -> `DashboardPanel` highlights Signal Box.

3. **OnChartEvent()**:
   - User clicks "CONFIRM ORDER" -> `DashboardPanel` gathers inputs -> `TradeManager` calculates Lot -> Sends Order.

## Configuration (Inputs)

- `Input_RiskPercent`: Default 3.0
- `Input_SL_Points`: Default 300
- `Input_Zone_Offset1`: Default 300
- `Input_Zone_Offset2`: Default 1000
- `Input_MagicNumber`: Default 123456
