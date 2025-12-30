//+------------------------------------------------------------------+
//|                                                      ChartZones.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"

#include <EA_Helper/Definitions.mqh>

//+------------------------------------------------------------------+
//| Zone Data Structure                                               |
//+------------------------------------------------------------------+
struct ZoneData
{
    double      price;          // Zone center price
    double      top;            // Zone top (price + range)
    double      bottom;         // Zone bottom (price - range)
    string      name;           // Zone label (e.g., "D1 +300")
    bool        isBuy;          // true = Buy Zone, false = Sell Zone
    bool        isMajor;        // true = Major zone (±1000), false = Minor (±300)
    int         touchCount;     // Number of times price touched this zone
    string      objPrefix;      // Object prefix for this zone
};

//+------------------------------------------------------------------+
//| Chart Zones Class - Visual Zone Display                           |
//+------------------------------------------------------------------+
class CChartZones
{
private:
    long              m_chart_id;
    string            m_prefix;           // "DJAY_Zone_"

    // Colors (matching DashboardPanel)
    color             m_buy_color;        // Green: C'46,204,113'
    color             m_sell_color;       // Red: C'231,76,60'
    color             m_pivot_color;      // Gold: C'255,215,0'

    // Zone data
    double            m_d1_open;
    double            m_current_price;
    int               m_zone_offset_minor;// 300 points
    int               m_zone_offset_major;// 1000 points
    int               m_zone_range;       // Zone depth (±points)

    // Settings
    bool              m_show_zones;
    bool              m_show_pivot;
    int               m_max_zones_show;

    // Zone array
    ZoneData          m_zones[];
    int               m_zone_count;

    // Previous close for touch detection
    double            m_prev_close;

    // Helper methods
    void CalculateZones();
    void CreateAllZones();
    void CreatePivotLine();
    void CreateZoneRectangle(ZoneData &zone);
    void CreateZoneLabel(ZoneData &zone);
    void UpdateZoneTouches();

    // Helper: Get visible chart time range
    void GetChartTimeRange(datetime &timeStart, datetime &timeEnd);

public:
    CChartZones();
    ~CChartZones() { Destroy(); }

    void Init(double d1_open, int zone_offset_minor, int zone_offset_major, int zone_range);
    void SetSettings(bool show_zones, bool show_pivot, int max_zones);
    void Update(double d1_open, double current_price);
    void Destroy();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CChartZones::CChartZones()
{
    m_chart_id = 0;
    m_prefix = "DJAY_Zone_";

    m_buy_color = C'46,204,113';
    m_sell_color = C'231,76,60';
    m_pivot_color = C'255,215,0';

    m_d1_open = 0.0;
    m_current_price = 0.0;
    m_zone_offset_minor = 300;
    m_zone_offset_major = 1000;
    m_zone_range = 50;

    m_show_zones = true;
    m_show_pivot = true;
    m_max_zones_show = 10;

    m_zone_count = 0;
    m_prev_close = 0.0;

    ArrayResize(m_zones, 0);
}

//+------------------------------------------------------------------+
//| Initialize with parameters                                       |
//+------------------------------------------------------------------+
void CChartZones::Init(double d1_open, int zone_offset_minor, int zone_offset_major, int zone_range)
{
    m_chart_id = ChartID();
    m_d1_open = d1_open;
    m_zone_offset_minor = zone_offset_minor;
    m_zone_offset_major = zone_offset_major;
    m_zone_range = zone_range;
    m_current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    m_prev_close = m_current_price;

    CalculateZones();
    CreateAllZones();
}

//+------------------------------------------------------------------+
//| Set display settings                                              |
//+------------------------------------------------------------------+
void CChartZones::SetSettings(bool show_zones, bool show_pivot, int max_zones)
{
    m_show_zones = show_zones;
    m_show_pivot = show_pivot;
    m_max_zones_show = max_zones;
}

//+------------------------------------------------------------------+
//| Calculate zone levels                                            |
//+------------------------------------------------------------------+
void CChartZones::CalculateZones()
{
    ArrayResize(m_zones, 0);
    m_zone_count = 0;

    if(m_d1_open <= 0) return;

    double point = _Point;

    // Generate zones above and below D1 Open
    // We'll create zones at: ±300, ±1000, ±2000, ±3000, etc. up to max_zones

    int zonesAbove = 0;
    int zonesBelow = 0;

    // Create zones in pairs (above and below)
    for(int i = 1; i <= 20; i++)  // Generate up to 20 levels (10 above, 10 below)
    {
        if(zonesAbove >= m_max_zones_show && zonesBelow >= m_max_zones_show)
            break;

        // Check offsets: 300, 1000, 2000, 3000, 4000, 5000...
        // Predefine array with maximum size needed
        int offsets[6];
        int offsetCount = 0;

        // Always add minor and major
        offsets[offsetCount++] = m_zone_offset_minor;
        offsets[offsetCount++] = m_zone_offset_major;

        // For higher levels, add intermediate steps
        if(i > 1)
        {
            offsets[offsetCount++] = i * 1000;  // 2000, 3000, 4000...
            offsets[offsetCount++] = i * 1000 + m_zone_offset_minor;  // 2300, 3300...
            offsets[offsetCount++] = i * 1000 - m_zone_offset_minor;  // 1700, 2700...
        }

        for(int j = 0; j < offsetCount; j++)
        {
            int offset = offsets[j];
            double levelAbove = m_d1_open + (offset * point);
            double levelBelow = m_d1_open - (offset * point);

            // Zone above (Sell Zone)
            if(zonesAbove < m_max_zones_show && levelAbove > m_current_price)
            {
                ZoneData zone;
                zone.price = levelAbove;
                zone.top = levelAbove + (m_zone_range * point);
                zone.bottom = levelBelow - (m_zone_range * point);
                zone.name = StringFormat("D1 +%d", offset);
                zone.isBuy = false;
                zone.isMajor = (offset >= m_zone_offset_major);
                zone.touchCount = 0;
                zone.objPrefix = m_prefix + "Sell_" + IntegerToString(offset);

                int size = ArraySize(m_zones);
                ArrayResize(m_zones, size + 1);
                m_zones[size] = zone;
                m_zone_count++;
                zonesAbove++;
            }

            // Zone below (Buy Zone)
            if(zonesBelow < m_max_zones_show && levelBelow < m_current_price)
            {
                ZoneData zone;
                zone.price = levelBelow;
                zone.top = levelBelow + (m_zone_range * point);
                zone.bottom = levelBelow - (m_zone_range * point);
                zone.name = StringFormat("D1 -%d", offset);
                zone.isBuy = true;
                zone.isMajor = (offset >= m_zone_offset_major);
                zone.touchCount = 0;
                zone.objPrefix = m_prefix + "Buy_" + IntegerToString(offset);

                int size = ArraySize(m_zones);
                ArrayResize(m_zones, size + 1);
                m_zones[size] = zone;
                m_zone_count++;
                zonesBelow++;
            }
        }
    }

    // Sort zones by price (descending)
    for(int i = 0; i < m_zone_count - 1; i++)
    {
        for(int j = 0; j < m_zone_count - i - 1; j++)
        {
            if(m_zones[j].price < m_zones[j + 1].price)
            {
                ZoneData temp = m_zones[j];
                m_zones[j] = m_zones[j + 1];
                m_zones[j + 1] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Create all zone objects                                          |
//+------------------------------------------------------------------+
void CChartZones::CreateAllZones()
{
    if(!m_show_zones) return;

    // Create pivot line
    if(m_show_pivot)
        CreatePivotLine();

    // Create zone rectangles and labels
    for(int i = 0; i < m_zone_count; i++)
    {
        CreateZoneRectangle(m_zones[i]);
        CreateZoneLabel(m_zones[i]);
    }

    ChartRedraw(m_chart_id);
}

//+------------------------------------------------------------------+
//| Create D1 Open pivot line                                        |
//+------------------------------------------------------------------+
void CChartZones::CreatePivotLine()
{
    string name = m_prefix + "Pivot_D1Open";

    ObjectCreate(m_chart_id, name, OBJ_HLINE, 0, 0, m_d1_open);
    ObjectSetInteger(m_chart_id, name, OBJPROP_COLOR, m_pivot_color);
    ObjectSetInteger(m_chart_id, name, OBJPROP_STYLE, STYLE_DASH);
    ObjectSetInteger(m_chart_id, name, OBJPROP_WIDTH, 2);
    ObjectSetInteger(m_chart_id, name, OBJPROP_BACK, true);
    ObjectSetInteger(m_chart_id, name, OBJPROP_SELECTABLE, false);

    // Create label
    string labelName = m_prefix + "Label_Pivot";
    ObjectCreate(m_chart_id, labelName, OBJ_TEXT, 0, 0, 0);
    ObjectSetString(m_chart_id, labelName, OBJPROP_TEXT, "D1 Open");
    ObjectSetInteger(m_chart_id, labelName, OBJPROP_COLOR, m_pivot_color);
    ObjectSetDouble(m_chart_id, labelName, OBJPROP_PRICE, m_d1_open);
    ObjectSetInteger(m_chart_id, labelName, OBJPROP_FONTSIZE, 8);

    // Position label at right edge of chart
    datetime timeEnd = 0;
    GetChartTimeRange(timeEnd, timeEnd);
    ObjectSetInteger(m_chart_id, labelName, OBJPROP_TIME, timeEnd);
    ObjectSetInteger(m_chart_id, labelName, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
}

//+------------------------------------------------------------------+
//| Create zone rectangle                                            |
//+------------------------------------------------------------------+
void CChartZones::CreateZoneRectangle(ZoneData &zone)
{
    string rectName = zone.objPrefix + "_Rect";

    datetime timeStart = 0, timeEnd = 0;
    GetChartTimeRange(timeStart, timeEnd);

    // Create rectangle covering the visible chart area
    ObjectCreate(m_chart_id, rectName, OBJ_RECTANGLE, 0, timeStart, zone.top, timeEnd, zone.bottom);

    // Set color based on zone type and strength
    color zoneColor = zone.isBuy ? m_buy_color : m_sell_color;

    ObjectSetInteger(m_chart_id, rectName, OBJPROP_COLOR, zoneColor);
    ObjectSetInteger(m_chart_id, rectName, OBJPROP_FILL, zoneColor);

    // Opacity based on zone strength (Major = more opaque)
    // We use the alpha channel - note: MQL5 uses color with alpha for transparency
    // Normal state: 30-40% opacity
    // We achieve this by setting OBJPROP_BACK to true and using semi-transparent effect
    // Actually, OBJ_RECTANGLE doesn't support alpha directly, we use different approach

    // For semi-transparent effect, we use OBJPROP_BACK and OBJPROP_BORDER_TYPE
    ObjectSetInteger(m_chart_id, rectName, OBJPROP_BACK, true);
    ObjectSetInteger(m_chart_id, rectName, OBJPROP_BORDER_TYPE, BORDER_FLAT);

    // Width: Major zones thicker
    int width = zone.isMajor ? 2 : 1;
    ObjectSetInteger(m_chart_id, rectName, OBJPROP_WIDTH, width);

    ObjectSetInteger(m_chart_id, rectName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Create zone label                                                |
//+------------------------------------------------------------------+
void CChartZones::CreateZoneLabel(ZoneData &zone)
{
    string labelName = zone.objPrefix + "_Label";

    datetime timeEnd = 0;
    GetChartTimeRange(timeEnd, timeEnd);

    ObjectCreate(m_chart_id, labelName, OBJ_TEXT, 0, timeEnd, zone.price);
    ObjectSetString(m_chart_id, labelName, OBJPROP_TEXT, zone.name);
    ObjectSetInteger(m_chart_id, labelName, OBJPROP_COLOR, zone.isBuy ? m_buy_color : m_sell_color);
    ObjectSetDouble(m_chart_id, labelName, OBJPROP_PRICE, zone.price);
    ObjectSetInteger(m_chart_id, labelName, OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(m_chart_id, labelName, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
}

//+------------------------------------------------------------------+
//| Update zones (called on new data or new D1 bar)                  |
//+------------------------------------------------------------------+
void CChartZones::Update(double d1_open, double current_price)
{
    // Check if D1 Open changed (new day) - recreate all zones
    bool d1Changed = (MathAbs(d1_open - m_d1_open) > _Point);

    m_current_price = current_price;

    // Update touch counter
    UpdateZoneTouches();

    if(d1Changed)
    {
        m_d1_open = d1_open;
        Destroy();
        CalculateZones();
        CreateAllZones();
    }
}

//+------------------------------------------------------------------+
//| Update zone touch counters                                       |
//+------------------------------------------------------------------+
void CChartZones::UpdateZoneTouches()
{
    double currentClose = m_current_price;

    for(int i = 0; i < m_zone_count; i++)
    {
        ZoneData zone = m_zones[i];

        // Check if candle closed within this zone (touch detected)
        bool wasOutside = (m_prev_close > zone.top || m_prev_close < zone.bottom);
        bool isInside = (currentClose >= zone.bottom && currentClose <= zone.top);

        if(wasOutside && isInside)
        {
            m_zones[i].touchCount++;

            // Update label with touch count
            string labelName = m_zones[i].objPrefix + "_Label";
            string touchText = StringFormat("%s [%dx]", m_zones[i].name, m_zones[i].touchCount);
            ObjectSetString(m_chart_id, labelName, OBJPROP_TEXT, touchText);
        }
    }

    m_prev_close = currentClose;
}

//+------------------------------------------------------------------+
//| Get chart time range                                             |
//+------------------------------------------------------------------+
void CChartZones::GetChartTimeRange(datetime &timeStart, datetime &timeEnd)
{
    // Get first and last visible bar
    int firstVisible = (int)ChartGetInteger(m_chart_id, CHART_FIRST_VISIBLE_BAR);
    int visibleBars = (int)ChartGetInteger(m_chart_id, CHART_VISIBLE_BARS);
    int lastVisible = firstVisible - visibleBars + 1;

    if(lastVisible < 0) lastVisible = 0;

    timeStart = iTime(_Symbol, PERIOD_CURRENT, firstVisible);
    timeEnd = iTime(_Symbol, PERIOD_CURRENT, lastVisible);

    // Extend range a bit for labels
    timeEnd += PeriodSeconds(PERIOD_CURRENT) * 10;
}

//+------------------------------------------------------------------+
//| Destroy all zone objects                                         |
//+------------------------------------------------------------------+
void CChartZones::Destroy()
{
    ObjectsDeleteAll(m_chart_id, m_prefix);
    ChartRedraw(m_chart_id);
}
