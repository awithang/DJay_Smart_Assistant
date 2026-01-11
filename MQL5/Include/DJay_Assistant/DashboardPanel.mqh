//+------------------------------------------------------------------+
//|                                                DashboardPanel.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "4.00"

#include <DJay_Assistant/Definitions.mqh>

class CDashboardPanel
{
private:
   long              m_chart_id;
   int               m_corner;
   string            m_prefix;
   
   int               m_panel_width;
   int               m_panel_height;
   int               m_base_x;
   int               m_base_y;
   bool              m_blink_state;

   color             m_bg_color;       
   color             m_header_color;
   color             m_text_color;     
   color             m_label_color;
   color             m_buy_color;
   color             m_sell_color;
   color             m_supply_color;
   color             m_accent_color;

   // Store active order tickets for individual close buttons
   long              m_order_tickets[20];

   //--- Scroll State for Active Orders (NEW)
   int               m_scroll_offset;        // Current scroll position (which row is at top)
   int               m_visible_count;        // How many orders visible at once
   int               m_total_orders;         // Total active orders

   //--- Settings State (NEW)
   int               m_current_rr;           // ENUM_RR_RATIO value
   bool              m_trailing_enabled;     // Profit Lock toggle state (controls Ladder Logic)

   //--- Filter State (Smart Filters - v5.0)
   bool              m_filter_trend_enabled;
   bool              m_filter_zone_enabled;
   bool              m_filter_aggr_enabled;

   //--- Initial Parameter Values (from EA Inputs) - FIX: UI Inputs sync
   double            m_initial_risk;         // Initial Risk % from EA inputs
   int               m_initial_pl_trigger;   // Initial PL Trigger from EA inputs
   int               m_initial_pl_lock;      // Initial PL Lock Amount from EA inputs
   int               m_initial_pl_step;      // Initial PL Step from EA inputs

   //--- RR Multiplier Lookup Table (NEW)
   double            m_rr_multipliers[3];    // [1.0, 1.5, 2.0]

   //--- Hybrid Mode Status (Sprint 6) - Phase 4
   bool              m_hybrid_context_ready; // M15 context readiness
   ENUM_TREND_BIAS   m_hybrid_bias;          // Current trend bias (BULLISH/BEARISH/NEUTRAL)

   // Helper: Convert relative Y (0 at top of panel) to absolute Y (distance from anchor)
   int Y(int relative_y) { return (m_base_y + m_panel_height) - relative_y; }

   void CreateRect(const string name, int x, int ry, int w, int h, color bg, bool border=false, color border_color=clrNONE);
   void CreateLabel(const string name, int x, int ry, const string text, color clr, int font_size, const string font="Arial", string align="left");
   void CreateEdit(const string name, int x, int ry, int width, int height, const string text);
   void CreateButton(const string name, int x, int ry, int width, int height, const string text, color clr, color txt_clr=clrWhite, int font_size=8);
   void CreateHLine(const string name, double price, color clr, ENUM_LINE_STYLE style, int width, const string desc);
   void AddLevel(double &arr[], string &lbls[], double price, string label);
   
   // Property Setters (Dirty Checking)
   void SetText(string name, string text);
   void SetColor(string name, color clr);
   void SetBgColor(string name, color clr);

public:
   CDashboardPanel();
   ~CDashboardPanel() { Destroy(); }

   void Init(long chart_id, double initial_risk = 1.0, int pl_trigger = 200, int pl_lock = 50, int pl_step = 100);
   void CreatePanel();
   void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   
   void UpdatePrice(double price);
   void UpdateSessionInfo(string session_name, string countdown, bool is_gold_time);
      void              UpdateDJayZones(double d1_open, int maxZones = 6);
   void UpdateStrategyInfo(string reversal_alert, bool rev_valid, string breakout_alert, bool brk_valid, string pa_sig);
   void UpdateTrendStrength(string strengthText, color strengthColor);
   void UpdateZoneStatus(int zoneStatus);  // 0=none, 1=buy1, 2=buy2, 3=sell1, 4=sell2
   void UpdateAdvisor(string message);
   void UpdateAdvisorDetails(string zone, string trend, string qs, string rsi, string adx, string pa = "");
   void UpdateLastAutoTrade(string strategy, string direction, double price);

   //--- Sniper Update: Sprint 3 - Market Intelligence Grid Update Methods
   void UpdateMarketIntelligenceGrid(MarketContext &ctx, double rsi, double stoch, ENUM_SIGNAL_TYPE m15Signal, ENUM_SIGNAL_TYPE m5Signal = SIGNAL_NONE);
   void UpdateActiveOrders(int count, long &tickets[], double &prices[], double &profits[], double &lots[], int &types[], double total_profit);

   //--- Sprint 7: Trade Strategy Recommendation Update
   void UpdateTradeStrategy(TradeRecommendation &rec);
   string GetRecommendationIcon(string code);

   //--- Sprint 7: Auto Mode Status Update
   void UpdateAutoModeStatus(bool sniperEnabled, bool hybridEnabled,
                               SniperFilterStates &sniperStates,
                               HybridFilterStates &hybridStates);

   //--- Ghost Button Logic (v5.0)
   void UpdateExecutionButtons(MarketContext &ctx);

   // New Methods
   void UpdateTradingMode(int mode);
   void UpdateStrategyButtons(bool arrow, bool rev, bool brk, bool sniper, bool hybrid);
   void UpdateHybridStatus(bool contextReady, ENUM_TREND_BIAS bias);
   void UpdateConfirmButton(string text, bool enable);

   //--- Settings Methods (NEW)
   void InitSettings(ENUM_RR_RATIO default_rr, bool profit_lock_enabled);
   void SaveSettings();
   void UpdateSettingsVisuals();
   void UpdateRRButtonsVisuals();
   void UpdateTrailingButtonVisuals();
   double GetRRMultiplier();
   int  GetRRRatio()           { return m_current_rr; }
   bool IsTrailingEnabled()    { return m_trailing_enabled; }
   int  GetPL_Option()         { return 0; } // Deprecated
   int  GetPL_Trigger()        { return (int)StringToInteger(ObjectGetString(m_chart_id, m_prefix+"EditPL_Trigger", OBJPROP_TEXT)); }
   int  GetPL_Amount()         { return (int)StringToInteger(ObjectGetString(m_chart_id, m_prefix+"EditPL_Amount", OBJPROP_TEXT)); }
   int  GetPL_Step()           { return (int)StringToInteger(ObjectGetString(m_chart_id, m_prefix+"EditPL_Step", OBJPROP_TEXT)); }

   //--- Filter Accessors (NEW)
   bool IsTrendFilterOn() { return m_filter_trend_enabled; }
   bool IsZoneFilterOn()  { return m_filter_zone_enabled; }
   bool IsAggressiveOn()  { return m_filter_aggr_enabled; }
   void UpdateFilterVisuals();

   //--- Scroll Support for Active Orders (NEW)
   int  GetScrollOffset()      { return m_scroll_offset; }
   int  GetTotalOrders()       { return m_total_orders; }
   int  GetVisibleCount()      { return m_visible_count; }
   void ScrollUp()             { if(m_scroll_offset > 0) m_scroll_offset--; }
   void ScrollDown()           { int maxScroll = m_total_orders - m_visible_count; if(m_scroll_offset < maxScroll) m_scroll_offset++; }

   void Redraw() { ChartRedraw(m_chart_id); }

   bool IsModeButtonClicked(string sparam) { return (sparam == m_prefix+"BtnMode"); }
   bool IsOpenSettingsClicked(string sparam) { return (sparam == m_prefix+"BtnOpenSettings"); }
   bool IsStatsButtonClicked(string sparam) { return (sparam == m_prefix+"BtnStats"); }
   bool IsConfirmButtonClicked(string sparam) { return (sparam == m_prefix+"BtnConfirm"); }
   bool IsCloseAllButtonClicked(string sparam) { return (sparam == m_prefix+"BtnCloseAll"); }

   // Individual order close button handlers
   bool IsCloseOrderButtonClicked(string sparam, int &index);
   long GetOrderTicket(int index) { return (index >= 0 && index < 20) ? m_order_tickets[index] : 0; }

   bool IsStratArrowClicked(string sparam) { return (sparam == m_prefix+"BtnStratArrow"); }
   bool IsStratRevClicked(string sparam) { return (sparam == m_prefix+"BtnStratRev"); }
   bool IsStratBreakClicked(string sparam) { return (sparam == m_prefix+"BtnStratBreak"); }
   bool IsStratSniperClicked(string sparam) { return (sparam == m_prefix+"BtnStratSniper"); }
   bool IsStratHybridClicked(string sparam) { return (sparam == m_prefix+"BtnStratHybrid"); }

   bool IsRevActionClicked(string sparam) { return (sparam == m_prefix+"BtnRev"); }
   bool IsBrkActionClicked(string sparam) { return (sparam == m_prefix+"BtnBrk"); }

   //--- Settings Button Click Handlers (NEW)
   bool IsRR1Clicked(string sparam)    { return (sparam == m_prefix+"BtnRR1"); }
   bool IsRR15Clicked(string sparam)   { return (sparam == m_prefix+"BtnRR15"); }
   bool IsRR2Clicked(string sparam)    { return (sparam == m_prefix+"BtnRR2"); }
   bool IsTrailingToggleClicked(string sparam) { return (sparam == m_prefix+"BtnTrailToggle"); }

   //--- Scroll Button Click Handlers (NEW)
   bool IsScrollUpClicked(string sparam) { return (sparam == m_prefix+"BtnScrollUp"); }
   bool IsScrollDownClicked(string sparam) { return (sparam == m_prefix+"BtnScrollDown"); }

   double GetRiskPercent();              
   bool IsBuyButtonClicked(string sparam)  { return (sparam == m_prefix+"BtnBuy"); }
   bool IsSellButtonClicked(string sparam) { return (sparam == m_prefix+"BtnSell"); }
   
   void Destroy() { ObjectsDeleteAll(m_chart_id, m_prefix); ObjectsDeleteAll(m_chart_id, "EA_"); ChartRedraw(m_chart_id); }
};

CDashboardPanel::CDashboardPanel()
{
   m_chart_id = 0;
   m_corner = CORNER_LEFT_LOWER;
   m_prefix = "DJ_"; // NEW PREFIX to force UI Reset (was "EA_")
   m_base_x = 10;
   m_base_y = 10;
   m_panel_width = 650;  // Widened to 650px
   m_panel_height = 710; 
   m_blink_state = false;

   m_bg_color = C'35,35,45';      // Dark Grey Background
   m_header_color = C'0,191,255'; // Deep Sky Blue
   m_text_color = clrWhite;
   m_label_color = C'200,200,200'; // Light Grey
   m_buy_color = C'34,139,34';    // ForestGreen (Darker)
   m_sell_color = C'139,0,0';     // DarkRed (Darker)
   m_supply_color = C'255,140,0'; // Dark Orange
   m_accent_color = C'0,191,255'; // Deep Sky Blue

   // Initialize Settings State (will be overridden by InitSettings)
   m_current_rr = RR_1_TO_2;
   m_trailing_enabled = true;

   // Initialize Filter State
   m_filter_trend_enabled = true; // Default ON
   m_filter_zone_enabled = true;  // Default ON
   m_filter_aggr_enabled = false; // Default OFF

   // Initialize Scroll State for Active Orders
   m_scroll_offset = 0;
   m_visible_count = 4;
   m_total_orders = 0;

   // RR Multiplier Lookup Table
   m_rr_multipliers[0] = 1.0;   // RR_1_TO_1
   m_rr_multipliers[1] = 1.5;   // RR_1_TO_1_5
   m_rr_multipliers[2] = 2.0;   // RR_1_TO_2
}

void CDashboardPanel::Init(long chart_id, double initial_risk, int pl_trigger, int pl_lock, int pl_step)
{
   m_chart_id = chart_id;

   // Store initial parameter values from EA inputs
   m_initial_risk = initial_risk;
   m_initial_pl_trigger = pl_trigger;
   m_initial_pl_lock = pl_lock;
   m_initial_pl_step = pl_step;

   // Print("DEBUG: Dashboard Panel v5.0 Loaded. Target Width=", m_panel_width); // Verify update

   CreatePanel();
}

void CDashboardPanel::CreatePanel()
{
   Destroy();

   int x = m_base_x;
   int pad = 10;

   // NEW LAYOUT - Full width for Market Intelligence
   int full_width = m_panel_width - 10;  // Use full panel width
   int left_x = x + 5;
   int bottom_half_width = (full_width / 2) - 10;  // Split bottom sections
   int bottom_left_x = left_x;
   int bottom_right_x = left_x + bottom_half_width + 20;

   // TEMPORARY: For compatibility with old code during transition
   int half_width = bottom_half_width;  // Alias for bottom_half_width
   int right_x = bottom_right_x;       // Alias for bottom_right_x

   // ============================================
   // MAIN BACKGROUND
   // ============================================
   CreateRect("MainBG", x, 0, m_panel_width, m_panel_height, m_bg_color, true, clrWhite);

   // ============================================
   // HEADER ROW 1: DJAY Smart Assistant Title
   // ============================================
   CreateLabel("Title", left_x + (full_width / 2) - 70, 12, "DJAY Smart Assistant", C'255,223,0', 12, "Arial Bold");

   // ============================================
   // HEADER ROW 2: Region, Status, Zone, M5 Time
   // ============================================
   int header_row2_y = 35;

   // Left side: Region, Status, Zone
   CreateLabel("LblSesTitle", left_x + pad, header_row2_y, "REGION:", m_text_color, 9);
   CreateLabel("LblSesValue", left_x + pad + 60, header_row2_y, "US", clrGray, 9, "Arial");

   CreateLabel("LblRunTimeTitle", left_x + pad + 100, header_row2_y, "STATUS:", m_text_color, 9);
   CreateLabel("LblRunTime", left_x + pad + 160, header_row2_y, "SIDEWAY", clrGray, 9, "Arial");

   CreateLabel("LblZoneStatTitle", left_x + pad + 230, header_row2_y, "ZONE:", m_text_color, 9);
   CreateLabel("LblZoneStat", left_x + pad + 280, header_row2_y, "NEUTRAL", clrGray, 9, "Arial");

   // Right side: M5 Time
   CreateLabel("LblTime", left_x + full_width - pad, header_row2_y, "M5: --:--", clrOrange, 9, "Arial", "right");

   // ============================================
   // MARKET INTELLIGENCE (Full Width - Panel A + B merged)
   // ============================================
   int mi_y_start = 58;  // Start below header (35 + 18 + 5 gap)

   // Header with price and icons
   CreateLabel("LblSig", left_x + pad, mi_y_start, "MARKET INTELLIGENCE", m_header_color, 10, "Arial Bold");
   CreateLabel("LblPrice", left_x + full_width - 100, mi_y_start, "0.00000", C'255,223,0', 12, "Arial Bold", "right");
   CreateButton("BtnOpenSettings", left_x + full_width - 85, mi_y_start + 2, 20, 20, "⚙", clrGray, clrWhite, 12);
   CreateButton("BtnStats", left_x + full_width - 60, mi_y_start + 2, 20, 20, "📋", clrGray, clrWhite, 12);
   CreateRect("InfoBG", left_x, mi_y_start + 18, full_width, mi_y_start + 175, C'5,5,15', true, C'45,45,60');

   // ============================================
   // SUBSECTION 1: MARKET SNAPSHOT (For Everyone)
   // ============================================
   int snap_y_start = mi_y_start + 28;

   // 5-column layout to maximize horizontal space usage
   int snap_col1_x = left_x + 5;       // Column 1
   int snap_col2_x = left_x + 65;      // Column 2
   int snap_col3_x = left_x + 125;     // Column 3
   int snap_col4_x = left_x + 185;     // Column 4
   int snap_col5_x = left_x + 245;     // Column 5
   int snap_row1_y = snap_y_start + 5;
   int snap_row_h = 14;

   // Row 1: Context | ADX | RSI | Stoch | ATR
   CreateLabel("Ctx_Label", snap_col1_x, snap_row1_y, "Context:", clrGray, 8);
   CreateLabel("Bias_Light", snap_col1_x + 50, snap_row1_y, "●", clrGray, 10);
   CreateLabel("ADX_Label2", snap_col2_x, snap_row1_y, "ADX:", clrGray, 8);
   CreateLabel("ADX_V2", snap_col2_x + 30, snap_row1_y, "--", clrGray, 8);
   CreateLabel("RSI_T", snap_col3_x, snap_row1_y, "RSI:", clrGray, 8);
   CreateLabel("RSI_V", snap_col3_x + 30, snap_row1_y, "--", clrGray, 8);
   CreateLabel("Stoch_T", snap_col4_x, snap_row1_y, "Stoch:", clrGray, 8);
   CreateLabel("Stoch_V", snap_col4_x + 35, snap_row1_y, "--", clrGray, 8);
   CreateLabel("ATR_T", snap_col5_x, snap_row1_y, "ATR:", clrGray, 8);
   CreateLabel("ATR_V", snap_col5_x + 30, snap_row1_y, "--", clrGray, 8);

   // Row 2: M15 PA | M5 PA | EMA 20 | Slope | To Zone
   CreateLabel("PA_T2", snap_col1_x, snap_row1_y + snap_row_h, "M15 PA:", clrGray, 8);
   CreateLabel("PA_V2", snap_col1_x + 50, snap_row1_y + snap_row_h, "NONE", clrGray, 8, "Arial Bold");
   CreateLabel("M5_PA_T", snap_col2_x, snap_row1_y + snap_row_h, "M5 PA:", clrGray, 8);
   CreateLabel("M5_PA_V", snap_col2_x + 45, snap_row1_y + snap_row_h, "--", clrGray, 8, "Arial Bold");
   CreateLabel("Dist_T", snap_col3_x, snap_row1_y + snap_row_h, "EMA 20:", clrGray, 8);
   CreateLabel("Dist_V", snap_col3_x + 45, snap_row1_y + snap_row_h, "--", clrGray, 8);
   CreateLabel("Slope_T", snap_col4_x, snap_row1_y + snap_row_h, "Slope:", clrGray, 8);
   CreateLabel("Slope_V", snap_col4_x + 35, snap_row1_y + snap_row_h, "FLAT", clrGray, 8);
   CreateLabel("Struct_T", snap_col5_x, snap_row1_y + snap_row_h, "To Zone:", clrGray, 8);
   CreateLabel("Struct_V", snap_col5_x + 50, snap_row1_y + snap_row_h, "--", clrGray, 8);

   // ============================================
   // SUBSECTION 2: TRADE STRATEGY (For Manual Traders)
   // ============================================

   int strat_y_start = snap_y_start + snap_row_h * 2 + 12;  // After Market Snapshot (2 rows now)
   int strat_row_h = 18;     // Row height

   CreateLabel("Strategy_Header", left_x + pad, strat_y_start, "📊 TRADE STRATEGY", C'255,200,50', 9, "Arial Bold");

   // Row 1: Market State
   CreateLabel("Strategy_State_Label", left_x + pad + 5, strat_y_start + strat_row_h, "State:", clrGray, 8);
   CreateLabel("Strategy_State", left_x + pad + 45, strat_y_start + strat_row_h, "--", clrGray, 8);

   // Row 2: Recommendation
   CreateLabel("Strategy_Rec_Label", left_x + pad + 5, strat_y_start + strat_row_h * 2, "Rec:", clrGray, 8);
   CreateLabel("Strategy_Rec_Code", left_x + pad + 35, strat_y_start + strat_row_h * 2, "⏳", clrGray, 10);
   CreateLabel("Strategy_Rec_Text", left_x + pad + 55, strat_y_start + strat_row_h * 2, "WAIT", clrGray, 8, "Arial Bold");

   // Row 3: Reasoning
   CreateLabel("Strategy_Reasoning", left_x + pad + 5, strat_y_start + strat_row_h * 3, "Analyzing market...", clrGray, 7);

   // Row 4: Entry + Targets combined (single row)
   CreateLabel("Strategy_Entry_Row", left_x + pad + 5, strat_y_start + strat_row_h * 4, "ENTRY: -- | TP: -- | SL: --", clrGray, 8);

   // Row 5: Alternatives
   CreateLabel("Strategy_Alt_Label", left_x + pad + 5, strat_y_start + strat_row_h * 5, "", clrGray, 8);
   CreateLabel("Strategy_Alt_Text", left_x + pad + 25, strat_y_start + strat_row_h * 5, "", clrGray, 8);

   // ============================================
   // SUBSECTION 3: AUTO MODE STATUS (For Auto Traders)
   // ============================================

   int auto_y_start = strat_y_start + strat_row_h * 6 + 10;  // After Trade Strategy (6 rows now)

   CreateLabel("Auto_Header", left_x + pad, auto_y_start, "🤖 AUTO MODE STATUS", C'100,200,100', 9, "Arial Bold");

   // Sniper row (status + filters combined)
   CreateLabel("Auto_Sniper_Row", left_x + pad + 5, auto_y_start + strat_row_h, "SNIPER: ⚪ OFF  PA:[ ] LOC:[ ] VOL:[ ] ZONE:[ ]", clrGray, 7);

   // Hybrid row (status + filters combined)
   CreateLabel("Auto_Hybrid_Row", left_x + pad + 5, auto_y_start + strat_row_h * 2, "HYBRID: ⚪ OFF  Trend:[ ] ADX:[ ] M5:[ ]", clrGray, 7);

   // ============================================
   // BOTTOM SPLIT PANEL (LEFT: Settings/Filters/Auto, RIGHT: Manual Trade/Zones)
   // ============================================
   int bottom_y_start = auto_y_start + strat_row_h * 3 + 12;  // After Auto Mode Status (3 rows total)
   int row_h = 20;
   int gap = 10;

   // ============================================
   // LEFT PANEL: Settings, Smart Filters, Auto Strategy
   // ============================================
   int left_y = bottom_y_start;
   int left_x_pos = bottom_left_x;

   // ============================================
   // LEFT PANEL SECTION 1: SETTINGS
   // ============================================
   CreateLabel("LblSettings", left_x_pos + pad, left_y, "SETTINGS", m_header_color, 10, "Arial Bold");
   left_y += row_h;

   CreateRect("SettingsBG", left_x_pos, left_y, bottom_half_width, 75, C'5,5,15', true, C'45,45,60');
   left_y += 10;

   // Row 1: RR Ratio + Risk %
   int rrBtnW = 40;
   int rrGap = 2;

   CreateLabel("L_RR_Title", left_x_pos + 10, left_y + 3, "RR:", clrGray, 8);
   CreateButton("BtnRR1", left_x_pos + 35, left_y, rrBtnW, 20, "1:1", clrGray, clrWhite, 8);
   CreateButton("BtnRR15", left_x_pos + 35 + rrBtnW + rrGap, left_y, rrBtnW, 20, "1:1.5", clrGray, clrWhite, 8);
   CreateButton("BtnRR2", left_x_pos + 35 + (rrBtnW + rrGap)*2, left_y, rrBtnW, 20, "1:2", m_buy_color, clrWhite, 8);

   CreateLabel("L_Risk", left_x_pos + bottom_half_width - 70, left_y + 3, "Risk:", clrGray, 8);
   CreateEdit("EditRisk", left_x_pos + bottom_half_width - 40, left_y, 30, 20, DoubleToString(m_initial_risk, 1));

   // Row 2: PL Toggle
   left_y += 25;
   CreateLabel("L_Trail", left_x_pos + 10, left_y + 3, "PL:", clrGray, 8);
   CreateButton("BtnTrailToggle", left_x_pos + 35, left_y, 35, 20, "ON", m_buy_color, clrWhite, 8);

   // PL Inputs (horizontal layout)
   int plX = left_x_pos + 80;
   CreateLabel("L_TP_Trail", plX, left_y + 3, "T:", clrGray, 8);
   CreateEdit("EditTrailTP", plX + 15, left_y, 30, 20, IntegerToString(m_initial_pl_trigger));
   CreateLabel("L_SL_Trail", plX + 50, left_y + 3, "L:", clrGray, 8);
   CreateEdit("EditTrailSL", plX + 65, left_y, 30, 20, IntegerToString(m_initial_pl_lock));
   CreateLabel("L_Step_Trail", plX + 100, left_y + 3, "S:", clrGray, 8);
   CreateEdit("EditTrailStep", plX + 115, left_y, 30, 20, IntegerToString(m_initial_pl_step));

   left_y += 40;
   left_y += gap;

   // ============================================
   // LEFT PANEL SECTION 2: SMART FILTERS
   // ============================================
   CreateLabel("LblFilters", left_x_pos + pad, left_y, "SMART FILTERS", m_header_color, 10, "Arial Bold");
   left_y += row_h;

   CreateRect("FilterBG", left_x_pos, left_y, bottom_half_width, 60, C'5,5,15', true, C'45,45,60');
   left_y += 10;

   // Row 1: Trend Filter + Zone Filter
   CreateButton("BtnFilterTrend", left_x_pos + 10, left_y, 15, 15, "X", m_buy_color, clrWhite, 8);
   CreateLabel("L_F_Trend", left_x_pos + 30, left_y, "Trend Filter", clrWhite, 8);
   CreateButton("BtnFilterZone", left_x_pos + 150, left_y, 15, 15, "X", m_buy_color, clrWhite, 8);
   CreateLabel("L_F_Zone", left_x_pos + 170, left_y, "Zone Filter", clrWhite, 8);

   // Row 2: Aggressive
   left_y += 25;
   CreateButton("BtnFilterAggr", left_x_pos + 10, left_y, 15, 15, "", clrGray, clrWhite, 8);
   CreateLabel("L_F_Aggr", left_x_pos + 30, left_y, "Aggressive (Ignore All)", C'255,100,100', 8);

   left_y += 35;  // Reduced gap from 50 to 35

   // ============================================
   // LEFT PANEL SECTION 3: AUTO STRATEGY
   // ============================================
   CreateLabel("LblStratTitle", left_x_pos + pad, left_y + 3, "AUTO STRATEGY", m_header_color, 10, "Arial Bold");
   CreateButton("BtnMode", left_x_pos + bottom_half_width - 65, left_y + 3, 60, row_h, "OFF", clrGray, clrWhite, 9);
   left_y += row_h;

   CreateRect("StratBG", left_x_pos, left_y, bottom_half_width, 50, C'5,5,15', true, C'45,45,60');
   left_y += 10;

   // Row 1: Arrow, Rev, Break
   CreateButton("BtnStratArrow", left_x_pos + 10, left_y, 15, 15, "", clrGray);
   CreateLabel("L_Arrow", left_x_pos + 30, left_y, "Arrow", clrCyan, 9, "Arial Bold");
   CreateButton("BtnStratRev", left_x_pos + 85, left_y, 15, 15, "", clrGray);
   CreateLabel("L_Rev", left_x_pos + 105, left_y, "Rev", clrCyan, 9, "Arial Bold");
   CreateButton("BtnStratBreak", left_x_pos + 155, left_y, 15, 15, "", clrGray);
   CreateLabel("L_Break", left_x_pos + 175, left_y, "Break", clrCyan, 9, "Arial Bold");

   // Row 2: Sniper, Hybrid (replaces Quick Scalp)
   left_y += 22;
   CreateButton("BtnStratSniper", left_x_pos + 10, left_y, 15, 15, "", clrGray);
   CreateLabel("L_Sniper", left_x_pos + 30, left_y, "SNIPER", clrCyan, 9, "Arial Bold");
   CreateButton("BtnStratHybrid", left_x_pos + 120, left_y, 15, 15, "", clrGray);
   CreateLabel("L_Hybrid", left_x_pos + 140, left_y, "HYBRID", clrCyan, 9, "Arial Bold");

   // Last auto trade info
   CreateLabel("LblLastAuto", left_x_pos + 10, left_y + 20, "Last: ---", C'80,80,80', 7);

   left_y += 35;

   // ============================================
   // RIGHT PANEL: Manual Trade + Daily Zones
   // ============================================
   int right_y = bottom_y_start;
   int right_x_pos = bottom_right_x;

   // ============================================
   // RIGHT PANEL SECTION 1: MANUAL TRADE
   // ============================================
   CreateLabel("LblCtrl", right_x_pos + pad, right_y, "MANUAL TRADE", C'255,140,0', 10, "Arial Bold");
   right_y += row_h;

   int btnW = (bottom_half_width - 30) / 2;
   CreateButton("BtnBuy", right_x_pos + 10, right_y, btnW, 35, "BUY", m_buy_color, clrWhite, 9);
   CreateButton("BtnSell", right_x_pos + bottom_half_width - 10 - btnW, right_y, btnW, 35, "SELL", m_sell_color, clrWhite, 9);

   right_y += 45;
   right_y += gap;

   // ============================================
   // RIGHT PANEL SECTION 2: DAILY ZONES
   // ============================================
   CreateLabel("LblZ", right_x_pos + pad, right_y, "DAILY ZONES (Smart Grid)", m_header_color, 10, "Arial Bold");
   right_y += row_h;

   CreateRect("TableBG", right_x_pos, right_y, bottom_half_width, 130, C'5,5,15', true, C'45,45,60');

   CreateLabel("H_Z", right_x_pos + 10, right_y + 10, "ZONE", clrGray, 8);
   CreateLabel("H_P", right_x_pos + 100, right_y + 10, "PRICE", clrGray, 8);
   CreateLabel("H_D", right_x_pos + 200, right_y + 10, "DIST", clrGray, 8);

   for(int i = 0; i < 6; i++)
   {
      string id = IntegerToString(i);
      int ry = right_y + 25 + (i * 18);
      CreateLabel("L_N_" + id, right_x_pos + 10, ry, "--", clrWhite, 9);
      CreateLabel("L_P_" + id, right_x_pos + 100, ry, "0.00", m_text_color, 9);
      CreateLabel("L_D_" + id, right_x_pos + 200, ry, "0 pts", clrGray, 9);
   }

   // ============================================
   // ACTIVE ORDERS Section (Bottom Anchor)
   // ============================================
   int orderY = m_panel_height - 130;

   CreateLabel("LblAct", x + pad, orderY, "ACTIVE ORDERS (0)", m_header_color, 10, "Arial Bold");
   CreateLabel("LblBalance", x + 150, orderY, "Balance: $--", clrWhite, 9, "Arial Bold");
   CreateLabel("LblTotalProfit", x + 280, orderY, "Profit: $0.00", clrGray, 9, "Arial Bold");
   CreateButton("BtnCloseAll", x + m_panel_width - 75, orderY - 2, 65, 18, "CLOSE ALL", m_sell_color, clrWhite, 8);

   CreateRect("OrderListBG", x + 5, orderY + 20, m_panel_width - 20, 105, C'5,5,15', true, C'45,45,60');

   // Scroll buttons for Active Orders
   CreateButton("BtnScrollUp", x + m_panel_width - 30, orderY + 25, 15, 15, "▲", clrGray, clrWhite, 10);
   CreateButton("BtnScrollDown", x + m_panel_width - 30, orderY + 45, 15, 15, "▼", clrGray, clrWhite, 10);

   // Active Order Rows
   for(int i=0; i<4; i++)
   {
      string sid = IntegerToString(i);
      int rowY = (orderY + 38) + (i * 24);

      CreateLabel("ActOrder_L_"+sid, -200, rowY, "", clrCyan, 9);
      CreateLabel("ActOrder_M_"+sid, -200, rowY, "", clrWhite, 9);
      CreateLabel("ActOrder_R_"+sid, -200, rowY, "", clrWhite, 9);
      CreateButton("BtnCloseOrder_"+sid, -100, rowY - 3, 35, 18, "X", C'80,80,80', clrWhite, 9);
   }

   // PENDING ALERTS Section - REMOVED PER USER REQUEST

   ChartRedraw(m_chart_id);
}

//+------------------------------------------------------------------+
//| Update Trading Mode                                              |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateTradingMode(int mode)
{
   // mode 0 = AUTO OFF (manual only), mode 1 = AUTO ON (manual + auto)
   string text = (mode == 0) ? "OFF" : "ON";
   color bg = (mode == 0) ? clrGray : m_buy_color;   // Gray when OFF, Green when ON
   color txt = clrWhite; // Always White for better contrast

   ObjectSetString(m_chart_id, m_prefix+"BtnMode", OBJPROP_TEXT, text);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnMode", OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnMode", OBJPROP_COLOR, txt);

   // Update mode label
   ObjectSetString(m_chart_id, m_prefix+"LblMode", OBJPROP_TEXT, text);
   ObjectSetInteger(m_chart_id, m_prefix+"LblMode", OBJPROP_COLOR, bg);
}
//+------------------------------------------------------------------+
//| Update Strategy Selection Buttons (all 5)                         |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateStrategyButtons(bool arrow, bool rev, bool brk, bool sniper, bool hybrid)
{
   color bgArrow = arrow ? m_buy_color : clrGray;
   color bgRev   = rev ? m_buy_color : clrGray;
   color bgBrk   = brk ? m_buy_color : clrGray;
   color bgSniper = sniper ? m_buy_color : clrGray;
   color bgHybrid = hybrid ? m_buy_color : clrGray;

   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratArrow", OBJPROP_BGCOLOR, bgArrow);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratRev", OBJPROP_BGCOLOR, bgRev);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratBreak", OBJPROP_BGCOLOR, bgBrk);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratSniper", OBJPROP_BGCOLOR, bgSniper);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratHybrid", OBJPROP_BGCOLOR, bgHybrid);
}

//+------------------------------------------------------------------+
//| Update Hybrid Mode Status (context only, not checkbox)           |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateHybridStatus(bool contextReady, ENUM_TREND_BIAS bias)
{
   // Store Hybrid Mode context state for dashboard tracking
   m_hybrid_context_ready = contextReady;
   m_hybrid_bias = bias;
   // Note: Status dot removed - context shown in Auto Mode Status section instead
}

//+------------------------------------------------------------------+
//| Update Confirm Button (One-Click Execution)                      |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateConfirmButton(string text, bool enable)
{
   color bg;
   color txt;

   if(enable)
   {
      // Dynamic color based on order type
      if(StringFind(text, "BUY") >= 0)
         bg = m_buy_color;
      else if(StringFind(text, "SELL") >= 0)
         bg = m_sell_color;
      else
         bg = m_header_color;
         
      txt = clrWhite; // Always white text for contrast on colored buttons
   }
   else
   {
      // Disabled State - Show "NO SIGNAL" placeholder
      text = "NO SIGNAL";
      bg = C'50,50,60'; // Dark Grey (slightly lighter than BG)
      txt = C'100,100,100'; // Dim Grey Text
   }
   
   ObjectSetString(m_chart_id, m_prefix+"BtnConfirm", OBJPROP_TEXT, text);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnConfirm", OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnConfirm", OBJPROP_COLOR, txt);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnConfirm", OBJPROP_STATE, false); // Ensure unpressed
}

//+------------------------------------------------------------------+
//| Update DJay Zones (Pivot + Support/Resistance)                   |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateDJayZones(double d1_open, int maxZones)
{
   if(d1_open <= 0) return;
   double current = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pt = _Point;
   if(pt <= 0) return;

   double levels[]; string labels[];
   // OPTIMIZATION: Reduced scan range from +/-30 to +/-5 (covers +/- 5000 points)
   // This reduces loop iterations from 61 to 11, cutting CPU load by ~80%
   for(int i=-5; i<=5; i++)
   {
      double base = i * 1000;
      AddLevel(levels, labels, d1_open + (base * pt), StringFormat("D1 %+d", (int)base));
      double minor = (i >= 0) ? (base + 300) : (base - 300);
      AddLevel(levels, labels, d1_open + (minor * pt), StringFormat("D1 %+d", (int)minor));
   }

   int count = ArraySize(levels);
   int best_idx[]; double best_dist[];
   ArrayResize(best_idx, maxZones);
   ArrayResize(best_dist, maxZones);
   for(int k=0; k<maxZones; k++) { best_dist[k] = 999999; best_idx[k] = -1; }

   for(int i=0; i<count; i++)
   {
      double dist = MathAbs(current - levels[i]);
      for(int k=0; k<maxZones; k++)
      {
         if(dist < best_dist[k])
         {
            for(int j=maxZones-1; j>k; j--) { best_dist[j] = best_dist[j-1]; best_idx[j] = best_idx[j-1]; }
            best_dist[k] = dist; best_idx[k] = i; break;
         }
      }
   }

   // Sort by Price DESC
   for(int i=0; i<maxZones-1; i++)
      for(int j=0; j<maxZones-1-i; j++)
         if(best_idx[j] != -1 && best_idx[j+1] != -1 && levels[best_idx[j]] < levels[best_idx[j+1]])
         { int t = best_idx[j]; best_idx[j] = best_idx[j+1]; best_idx[j+1] = t; }

   for(int i=0; i<maxZones; i++)
   {
      int idx = best_idx[i];
      if(idx == -1) continue;
      string sid = IntegerToString(i);
      color c = (levels[idx] > current) ? m_supply_color : m_buy_color;
      if(MathAbs(levels[idx] - d1_open) < pt) c = m_header_color;

      ObjectSetString(m_chart_id, m_prefix+"L_N_"+sid, OBJPROP_TEXT, labels[idx]);
      ObjectSetInteger(m_chart_id, m_prefix+"L_N_"+sid, OBJPROP_COLOR, c);
      ObjectSetString(m_chart_id, m_prefix+"L_P_"+sid, OBJPROP_TEXT, DoubleToString(levels[idx], 2));
      ObjectSetString(m_chart_id, m_prefix+"L_D_"+sid, OBJPROP_TEXT, DoubleToString(MathAbs(current-levels[idx])/pt, 0)+" pts");
   }

   // Hide unused zone labels (6-9) since we now only show 6 zones
   for(int i=maxZones; i<10; i++)
   {
      string sid = IntegerToString(i);
      ObjectSetString(m_chart_id, m_prefix+"L_N_"+sid, OBJPROP_TEXT, "");
      ObjectSetString(m_chart_id, m_prefix+"L_P_"+sid, OBJPROP_TEXT, "");
      ObjectSetString(m_chart_id, m_prefix+"L_D_"+sid, OBJPROP_TEXT, "");
   }
}

void CDashboardPanel::UpdateSessionInfo(string session_name, string countdown, bool is_gold_time)
{
   SetText("LblSesValue", session_name);
   SetColor("LblSesValue", (session_name == "QUIET" ? clrGray : m_text_color));
   SetText("LblTime", countdown);

   if(is_gold_time) {
      SetText("LblRunTime", "RUN TIME");
      SetColor("LblRunTime", clrLime);
   } else {
      SetText("LblRunTime", "SIDEWAY");
      SetColor("LblRunTime", clrGray);
   }
}

// Helper for Smart Updates (Dirty Checking)
void CDashboardPanel::SetText(string name, string text)
{
   if(ObjectGetString(m_chart_id, m_prefix+name, OBJPROP_TEXT) != text)
      ObjectSetString(m_chart_id, m_prefix+name, OBJPROP_TEXT, text);
}

void CDashboardPanel::SetColor(string name, color clr)
{
   if(ObjectGetInteger(m_chart_id, m_prefix+name, OBJPROP_COLOR) != clr)
      ObjectSetInteger(m_chart_id, m_prefix+name, OBJPROP_COLOR, clr);
}

void CDashboardPanel::SetBgColor(string name, color clr)
{
   if(ObjectGetInteger(m_chart_id, m_prefix+name, OBJPROP_BGCOLOR) != clr)
      ObjectSetInteger(m_chart_id, m_prefix+name, OBJPROP_BGCOLOR, clr);
}

void CDashboardPanel::UpdateStrategyInfo(string reversal_alert, bool rev_valid, string breakout_alert, bool brk_valid, string pa_sig)
{
   // Update Reversal Dynamic Button
   string revText = "NO REVERSAL SETUP";
   color revBg = clrGray;
   
   if(rev_valid)
   {
      revText = reversal_alert;
      if(StringFind(reversal_alert, "BUY") >= 0) revBg = m_buy_color;
      else if(StringFind(reversal_alert, "SELL") >= 0) revBg = m_sell_color;
   }
   
   SetText("BtnRev", revText);
   SetBgColor("BtnRev", revBg);

   // Update Breakout Dynamic Button
   string brkText = "NO BREAKOUT SETUP";
   color brkBg = clrGray;
   
   if(brk_valid)
   {
      brkText = breakout_alert;
      if(StringFind(breakout_alert, "BUY") >= 0) brkBg = m_buy_color;
      else if(StringFind(breakout_alert, "SELL") >= 0) brkBg = m_sell_color;
   }

   SetText("BtnBrk", brkText);
   SetBgColor("BtnBrk", brkBg);

   // Update PA Signal
   SetText("PA_V", pa_sig);

   color pc = clrGray;
   if(StringFind(pa_sig, "BUY") >= 0)
      pc = m_buy_color;
   else if(StringFind(pa_sig, "SELL") >= 0)
      pc = m_sell_color;

   SetColor("PA_V", pc);
}

void CDashboardPanel::UpdatePrice(double price)
{
   ObjectSetString(m_chart_id, m_prefix+"LblPrice", OBJPROP_TEXT, DoubleToString(price, _Digits));
}

double CDashboardPanel::GetRiskPercent()
{
   return StringToDouble(ObjectGetString(m_chart_id, m_prefix+"EditRisk", OBJPROP_TEXT));
}

// Helpers
void CDashboardPanel::CreateRect(const string name, int x, int ry, int w, int h, color bg, bool border, color border_color)
{
   string n = m_prefix + name;
   ObjectCreate(m_chart_id, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(m_chart_id, n, OBJPROP_CORNER, m_corner);
   ObjectSetInteger(m_chart_id, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chart_id, n, OBJPROP_YDISTANCE, Y(ry));
   ObjectSetInteger(m_chart_id, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(m_chart_id, n, OBJPROP_YSIZE, h);
   ObjectSetInteger(m_chart_id, n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(m_chart_id, n, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   
   if(border)
   {
      ObjectSetInteger(m_chart_id, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chart_id, n, OBJPROP_BORDER_COLOR, border_color);
      
      // Make the Main Panel border thicker
      if(StringFind(name, "MainBG") >= 0)
         ObjectSetInteger(m_chart_id, n, OBJPROP_WIDTH, 2); 
      else
         ObjectSetInteger(m_chart_id, n, OBJPROP_WIDTH, 1);
   }
   else
   {
      ObjectSetInteger(m_chart_id, n, OBJPROP_BORDER_TYPE, BORDER_SUNKEN);
      ObjectSetInteger(m_chart_id, n, OBJPROP_WIDTH, 0);
   }
   
   ObjectSetInteger(m_chart_id, n, OBJPROP_SELECTABLE, false);
}

void CDashboardPanel::CreateLabel(const string name, int x, int ry, const string text, color clr, int font_size, const string font, string align)
{
   string n = m_prefix + name;
   ObjectCreate(m_chart_id, n, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(m_chart_id, n, OBJPROP_CORNER, m_corner);
   ObjectSetInteger(m_chart_id, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chart_id, n, OBJPROP_YDISTANCE, Y(ry));
   ObjectSetString(m_chart_id, n, OBJPROP_TEXT, text);
   ObjectSetInteger(m_chart_id, n, OBJPROP_COLOR, clr);
   ObjectSetInteger(m_chart_id, n, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(m_chart_id, n, OBJPROP_FONT, font);
   ObjectSetInteger(m_chart_id, n, OBJPROP_ANCHOR, (align=="right" ? ANCHOR_RIGHT_UPPER : ANCHOR_LEFT_UPPER));
}

void CDashboardPanel::CreateButton(const string name, int x, int ry, int width, int height, const string text, color clr, color txt_clr, int font_size)
{
   string n = m_prefix + name;
   ObjectCreate(m_chart_id, n, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(m_chart_id, n, OBJPROP_CORNER, m_corner);
   ObjectSetInteger(m_chart_id, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chart_id, n, OBJPROP_YDISTANCE, Y(ry));
   ObjectSetInteger(m_chart_id, n, OBJPROP_XSIZE, width);
   ObjectSetInteger(m_chart_id, n, OBJPROP_YSIZE, height);
   ObjectSetString(m_chart_id, n, OBJPROP_TEXT, text);
   ObjectSetInteger(m_chart_id, n, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(m_chart_id, n, OBJPROP_COLOR, txt_clr);
   ObjectSetInteger(m_chart_id, n, OBJPROP_FONTSIZE, font_size);
   ObjectSetInteger(m_chart_id, n, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(m_chart_id, n, OBJPROP_ZORDER, 10); // Ensure button is on top

   // TRUE FLAT STYLE - Removes all 3D effects for instant response
   ObjectSetInteger(m_chart_id, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chart_id, n, OBJPROP_BORDER_COLOR, clr); // Border same as bg for seamless look
   ObjectSetInteger(m_chart_id, n, OBJPROP_WIDTH, 1); // Minimal border width
}

void CDashboardPanel::CreateEdit(const string name, int x, int ry, int width, int height, const string text)
{
   string n = m_prefix + name;
   ObjectCreate(m_chart_id, n, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(m_chart_id, n, OBJPROP_CORNER, m_corner);
   ObjectSetInteger(m_chart_id, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chart_id, n, OBJPROP_YDISTANCE, Y(ry));
   ObjectSetInteger(m_chart_id, n, OBJPROP_XSIZE, width);
   ObjectSetInteger(m_chart_id, n, OBJPROP_YSIZE, height);
   ObjectSetString(m_chart_id, n, OBJPROP_TEXT, text);
   ObjectSetInteger(m_chart_id, n, OBJPROP_BGCOLOR, C'5,5,15');
   ObjectSetInteger(m_chart_id, n, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chart_id, n, OBJPROP_ALIGN, ALIGN_CENTER);
}

void CDashboardPanel::AddLevel(double &arr[], string &lbls[], double price, string label)
{
   int s = ArraySize(arr); ArrayResize(arr, s+1); ArrayResize(lbls, s+1);
   arr[s] = price; lbls[s] = label;
}

//+------------------------------------------------------------------+
//| Update Trend Strength Display                                    |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateTrendStrength(string strengthText, color strengthColor)
{
   ObjectSetString(m_chart_id, m_prefix+"Trend_V", OBJPROP_TEXT, strengthText);
   ObjectSetInteger(m_chart_id, m_prefix+"Trend_V", OBJPROP_COLOR, strengthColor);
}

//+------------------------------------------------------------------+
//| Update Zone Status Highlight                                     |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateZoneStatus(int zoneStatus)
{
   string statusText = "--";
   color statusColor = clrGray;

   switch(zoneStatus)
   {
      case 0: // ZONE_STATUS_NONE
         statusText = "NEUTRAL";
         statusColor = clrGray;
         break;
      case 1: // ZONE_STATUS_IN_BUY1
         statusText = "BUY ZONE 1";
         statusColor = m_buy_color;
         break;
      case 2: // ZONE_STATUS_IN_BUY2
         statusText = "BUY ZONE 2";
         statusColor = m_buy_color;
         break;
      case 3: // ZONE_STATUS_IN_SELL1
         statusText = "SELL ZONE 1";
         statusColor = m_supply_color;
         break;
      case 4: // ZONE_STATUS_IN_SELL2
         statusText = "SELL ZONE 2";
         statusColor = m_supply_color;
         break;
   }

   // Update the status label in the header area
   ObjectSetString(m_chart_id, m_prefix+"LblZoneStat", OBJPROP_TEXT, statusText);
   ObjectSetInteger(m_chart_id, m_prefix+"LblZoneStat", OBJPROP_COLOR, statusColor);
}

//+------------------------------------------------------------------+
//| Update Advisor Message (Text Wrapping Support)                    |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateAdvisor(string message)
{
   // Split message into two lines if needed (max ~40 chars per line)
   string line1 = "";
   string line2 = "";

   int maxLen = 40;
   int msgLen = StringLen(message);

   if(msgLen <= maxLen)
   {
      line1 = message;
   }
   else
   {
      // Find best split point (space or punctuation)
      int splitPos = maxLen;
      for(int i = maxLen; i > maxLen - 10; i--)
      {
         if(StringGetCharacter(message, i) == ' ' ||
            StringGetCharacter(message, i) == '.' ||
            StringGetCharacter(message, i) == ',')
         {
            splitPos = i + 1;
            break;
         }
      }

      line1 = StringSubstr(message, 0, splitPos);
      line2 = StringSubstr(message, splitPos);
   }

   // Update labels
   ObjectSetString(m_chart_id, m_prefix+"Adv_V", OBJPROP_TEXT, line1);
   ObjectSetString(m_chart_id, m_prefix+"Adv_V2", OBJPROP_TEXT, line2);
}

//+------------------------------------------------------------------+
//| Update Advisor Details (Zone, Trend, QS, RSI, ADX, PA)                  |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateAdvisorDetails(string zone, string trend, string qs, string rsi, string adx, string pa = "")
{
   ObjectSetString(m_chart_id, m_prefix+"Stat_Zone", OBJPROP_TEXT, zone);
   ObjectSetString(m_chart_id, m_prefix+"Stat_Trend", OBJPROP_TEXT, trend);
   ObjectSetString(m_chart_id, m_prefix+"Stat_QS", OBJPROP_TEXT, qs);
   ObjectSetString(m_chart_id, m_prefix+"Stat_RSI", OBJPROP_TEXT, rsi);
   ObjectSetString(m_chart_id, m_prefix+"Stat_ADX", OBJPROP_TEXT, adx);
   if(pa != "")
      ObjectSetString(m_chart_id, m_prefix+"Stat_PA", OBJPROP_TEXT, pa);
}

//+------------------------------------------------------------------+
//| Update Last Auto Trade Label                                      |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateLastAutoTrade(string strategy, string direction, double price)
{
   string text = "Last: " + strategy + " " + direction + " @" + DoubleToString(price, _Digits);
   ObjectSetString(m_chart_id, m_prefix+"LblLastAuto", OBJPROP_TEXT, text);

   // Set color based on direction
   color clr = clrGray;
   if(direction == "BUY")
      clr = m_buy_color;
   else if(direction == "SELL")
      clr = m_sell_color;

   ObjectSetInteger(m_chart_id, m_prefix+"LblLastAuto", OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| Settings Management Methods (NEW)                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialize Settings from Inputs                                   |
//+------------------------------------------------------------------+
void CDashboardPanel::InitSettings(ENUM_RR_RATIO default_rr, bool profit_lock_enabled)
{
   // Try to load from Global Variables (persistent state)
   if(GlobalVariableCheck(GV_RR_RATIO))
      m_current_rr = (ENUM_RR_RATIO)GlobalVariableGet(GV_RR_RATIO);
   else
      m_current_rr = default_rr;

   if(GlobalVariableCheck(GV_TRAILING_ENABLED))
      m_trailing_enabled = GlobalVariableGet(GV_TRAILING_ENABLED) > 0;
   else
      m_trailing_enabled = profit_lock_enabled;  // Initialize from Input_Use_TradeManagement

   // Create Global Variables if they don't exist
   GlobalVariableTemp(GV_RR_RATIO);
   GlobalVariableTemp(GV_TRAILING_ENABLED);

   // Save initial state
   SaveSettings();

   // Update visuals
   UpdateSettingsVisuals();
}

//+------------------------------------------------------------------+
//| Save Settings to Global Variables                                 |
//+------------------------------------------------------------------+
void CDashboardPanel::SaveSettings()
{
   GlobalVariableSet(GV_RR_RATIO, (long)m_current_rr);
   GlobalVariableSet(GV_TRAILING_ENABLED, m_trailing_enabled ? 1 : 0);
}

//+------------------------------------------------------------------+
//| Update Settings Visuals (All settings)                            |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateSettingsVisuals()
{
   UpdateRRButtonsVisuals();
   UpdateTrailingButtonVisuals();
}

//+------------------------------------------------------------------+
//| Update RR Buttons Visuals (Targeted redraw only)                  |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateRRButtonsVisuals()
{
   // Reset ALL to Gray (inactive)
   SetBgColor("BtnRR1", clrGray);
   SetBgColor("BtnRR15", clrGray);
   SetBgColor("BtnRR2", clrGray);

   // Highlight ONLY active button
   switch(m_current_rr)
   {
      case RR_1_TO_1:
         SetBgColor("BtnRR1", m_buy_color);
         break;
      case RR_1_TO_1_5:
         SetBgColor("BtnRR15", m_buy_color);
         break;
      case RR_1_TO_2:
         SetBgColor("BtnRR2", m_buy_color);
         break;
   }
}

//+------------------------------------------------------------------+
//| Update Profit Lock Button Visuals (Targeted redraw only)          |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateTrailingButtonVisuals()
{
   string text = m_trailing_enabled ? "ON" : "OFF";
   color bg = m_trailing_enabled ? m_buy_color : clrGray;

   SetText("BtnTrailToggle", text);
   SetBgColor("BtnTrailToggle", bg);
}

//+------------------------------------------------------------------+
//| Update Smart Filter Visuals (v5.0)                                |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateFilterVisuals()
{
   // Trend Filter
   string trendText = m_filter_trend_enabled ? "X" : "";
   color trendBg = m_filter_trend_enabled ? m_buy_color : clrGray;
   SetText("BtnFilterTrend", trendText);
   SetBgColor("BtnFilterTrend", trendBg);

   // Zone Filter
   string zoneText = m_filter_zone_enabled ? "X" : "";
   color zoneBg = m_filter_zone_enabled ? m_buy_color : clrGray;
   SetText("BtnFilterZone", zoneText);
   SetBgColor("BtnFilterZone", zoneBg);

   // Aggressive Mode
   string aggrText = m_filter_aggr_enabled ? "ON" : "";
   color aggrBg = m_filter_aggr_enabled ? C'255,100,100' : clrGray;
   SetText("BtnFilterAggr", aggrText);
   SetBgColor("BtnFilterAggr", aggrBg);
   
   // Logic: If Aggressive is ON, filters are visually "ignored" (but we keep their state)
   // We might want to dim the filter buttons if Aggressive is ON, but for now simple toggle is fine.
}

//+------------------------------------------------------------------+
//| Get RR Multiplier                                                 |
//+------------------------------------------------------------------+
double CDashboardPanel::GetRRMultiplier()
{
   if(m_current_rr >= 0 && m_current_rr < 3)
      return m_rr_multipliers[m_current_rr];
   return 2.0;  // Safe fallback to 1:2
}

//+------------------------------------------------------------------+
//| Update Active Orders List (with Scroll Support)                   |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateActiveOrders(int count, long &tickets[], double &prices[], double &profits[], double &lots[], int &types[], double total_profit)
{
   // Store total orders
   m_total_orders = count;

   // Update count label
   ObjectSetString(m_chart_id, m_prefix+"LblAct", OBJPROP_TEXT, StringFormat("ACTIVE ORDERS (%d)", count));

   // Update Balance
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   ObjectSetString(m_chart_id, m_prefix+"LblBalance", OBJPROP_TEXT, StringFormat("Balance: $%.2f", balance));

   // Update Total Profit
   if(count > 0)
   {
      ObjectSetString(m_chart_id, m_prefix+"LblTotalProfit", OBJPROP_TEXT, StringFormat("Profit: $%.2f", total_profit));
      color profitColor = (total_profit >= 0) ? clrLime : clrOrange;
      ObjectSetInteger(m_chart_id, m_prefix+"LblTotalProfit", OBJPROP_COLOR, profitColor);
   }
   else
   {
      ObjectSetString(m_chart_id, m_prefix+"LblTotalProfit", OBJPROP_TEXT, "Profit: $0.00");
      ObjectSetInteger(m_chart_id, m_prefix+"LblTotalProfit", OBJPROP_COLOR, clrGray);
   }

   // Show/hide scroll buttons based on order count
   if(count <= 4)
   {
      // Hide scroll buttons when <= 4 orders
      ObjectSetInteger(m_chart_id, m_prefix+"BtnScrollUp", OBJPROP_XDISTANCE, -200);
      ObjectSetInteger(m_chart_id, m_prefix+"BtnScrollDown", OBJPROP_XDISTANCE, -200);
   }
   else
   {
      // Show scroll buttons (inside OrderListBG area)
      int btnX = m_base_x + m_panel_width - 30;
      ObjectSetInteger(m_chart_id, m_prefix+"BtnScrollUp", OBJPROP_XDISTANCE, btnX);
      ObjectSetInteger(m_chart_id, m_prefix+"BtnScrollDown", OBJPROP_XDISTANCE, btnX);
   }

   // Calculate button positions
   int x = m_base_x;

   // Update visible slots (with scroll offset support)
   for(int displayIndex = 0; displayIndex < m_visible_count; displayIndex++)
   {
      string sid = IntegerToString(displayIndex);
      int actualOrderIndex = m_scroll_offset + displayIndex;

      if(actualOrderIndex < count && actualOrderIndex < 20)
      {
         // Display this order
         m_order_tickets[displayIndex] = tickets[actualOrderIndex];

         string typeStr = (types[actualOrderIndex] == 0) ? "BUY" : "SELL";
         double profitPct = (balance > 0) ? (profits[actualOrderIndex] / balance) * 100.0 : 0;
         color pColor = (profits[actualOrderIndex] >= 0) ? clrLime : clrOrange;

         // 1. Info Label (Cyan) - Ticket ID removed, button moved to left
         string infoText = StringFormat("%s      Lots %.2f      @%.2f", typeStr, lots[actualOrderIndex], prices[actualOrderIndex]);
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_TEXT, infoText);
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_COLOR, clrCyan);
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_XDISTANCE, x + 50);

         // 2. Profit Label ($)
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_TEXT, StringFormat("$%.2f", profits[actualOrderIndex]));
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_COLOR, pColor);
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_XDISTANCE, x + 300);

         // 3. Percent Label (%)
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_TEXT, StringFormat("(%.2f%%)", profitPct));
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_COLOR, pColor);
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_XDISTANCE, x + 390);

         // Show close button (moved to left)
         int btnX = x + 10;
         ObjectSetInteger(m_chart_id, m_prefix+"BtnCloseOrder_"+sid, OBJPROP_XDISTANCE, btnX);
         ObjectSetInteger(m_chart_id, m_prefix+"BtnCloseOrder_"+sid, OBJPROP_STATE, false);
      }
      else
      {
         // Clear and hide unused slots
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_TEXT, "");
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_XDISTANCE, -200);

         ObjectSetString(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_TEXT, "");
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_XDISTANCE, -200);

         ObjectSetString(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_TEXT, "");
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_XDISTANCE, -200);

         m_order_tickets[displayIndex] = 0;

         // Hide close button
         ObjectSetInteger(m_chart_id, m_prefix+"BtnCloseOrder_"+sid, OBJPROP_XDISTANCE, -100);
      }
   }
}

//+====================================================================+
//| SNIPER UPDATE: Sprint 3 - Market Intelligence Grid Update           |
//+====================================================================+

//+------------------------------------------------------------------+
//| Update Market Intelligence Grid (5-Column Layout)                  |
//| Populates the new dashboard grid with market context data           |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateMarketIntelligenceGrid(MarketContext &ctx, double rsi, double stoch, ENUM_SIGNAL_TYPE m15Signal, ENUM_SIGNAL_TYPE m5Signal)
{
   // ==========================================================
   // MARKET SNAPSHOT - 5-Column Layout
   // ==========================================================

   // 1. Bias Indicator (Context)
   color biasColor = ctx.trendMatrix.displayColor;
   SetColor("Bias_Light", biasColor);

   // 2. ADX Value
   string adxText = (ctx.adxValue > 0) ? StringFormat("%.1f", ctx.adxValue) : "--";
   SetText("ADX_V2", adxText);

   // 3. M15 PA Signal
   string paText = "NONE";
   color paColor = clrGray;
   if(m15Signal == SIGNAL_PA_BUY)
   {
      paText = "BUY";
      paColor = m_buy_color;
   }
   else if(m15Signal == SIGNAL_PA_SELL)
   {
      paText = "SELL";
      paColor = m_sell_color;
   }
   SetText("PA_V2", paText);
   SetColor("PA_V2", paColor);

   // 4. M5 PA Signal
   string m5PaText = "--";
   color m5PaColor = clrGray;
   if(m5Signal == SIGNAL_PA_BUY)
   {
      m5PaText = "BUY";
      m5PaColor = m_buy_color;
   }
   else if(m5Signal == SIGNAL_PA_SELL)
   {
      m5PaText = "SELL";
      m5PaColor = m_sell_color;
   }
   else if(m5Signal == SIGNAL_NONE)
   {
      m5PaText = "NONE";
   }
   SetText("M5_PA_V", m5PaText);
   SetColor("M5_PA_V", m5PaColor);

   // 5. RSI Value
   string rsiText = (rsi > 0) ? StringFormat("%.0f", rsi) : "--";
   color rsiColor = clrGray;
   if(rsi > 70)
      rsiColor = clrRed;
   else if(rsi < 30)
      rsiColor = clrLime;
   else if(rsi > 60)
      rsiColor = m_sell_color;
   else if(rsi < 40)
      rsiColor = m_buy_color;
   SetText("RSI_V", rsiText);
   SetColor("RSI_V", rsiColor);

   // 6. Stochastic Value
   string stochText = (stoch > 0) ? StringFormat("%.0f", stoch) : "--";
   color stochColor = clrGray;
   if(stoch > 80)
      stochColor = clrRed;
   else if(stoch < 20)
      stochColor = clrLime;
   else if(stoch > 60)
      stochColor = m_sell_color;
   else if(stoch < 40)
      stochColor = m_buy_color;
   SetText("Stoch_V", stochText);
   SetColor("Stoch_V", stochColor);

   // 7. EMA Slope
   string slopeText = "FLAT";
   color slopeColor = clrGray;
   switch(ctx.slopeH1)
   {
      case SLOPE_UP:
         slopeText = "UP";
         slopeColor = clrLime;
         break;
      case SLOPE_DOWN:
         slopeText = "DOWN";
         slopeColor = m_sell_color;
         break;
      case SLOPE_CRASH:
         slopeText = "CRASH";
         slopeColor = clrRed;
         break;
      case SLOPE_FLAT:
         slopeText = "FLAT";
         slopeColor = clrGray;
         break;
   }
   SetText("Slope_V", slopeText);
   SetColor("Slope_V", slopeColor);

   // 8. EMA Distance
   string distText = (ctx.emaDistance != 0) ? StringFormat("%.0f", ctx.emaDistance) : "0";
   color distColor = clrGray;
   if(ctx.emaDistance > 200) distColor = m_sell_color;
   else if(ctx.emaDistance < -200) distColor = m_buy_color;
   SetText("Dist_V", distText + " pts");
   SetColor("Dist_V", distColor);

   // 9. ATR Value
   string atrText = (ctx.atrM15 > 0) ? StringFormat("%.0f", ctx.atrM15) : "--";
   SetText("ATR_V", atrText + " pts");

   // 10. To Zone (Structure Distance)
   string structText = (ctx.distanceToNearestZone > 0 && ctx.distanceToNearestZone < 1000000) ?
                       StringFormat("%.0f", ctx.distanceToNearestZone) : "--";
   color structColor = ctx.nearStructuralLevel ? clrLime : clrGray;
   SetText("Struct_V", structText + " pts");
   SetColor("Struct_V", structColor);
}

//+------------------------------------------------------------------+
//| Update Trade Strategy Recommendation                               |
//| Display natural language trading recommendations for manual       |
//| traders in the cockpit.                                          |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateTradeStrategy(TradeRecommendation &rec)
{
   // Note: UI elements for Trade Strategy section will be created in CreatePanel()
   // This function updates the existing elements with new data

   // Update market state
   SetText("Strategy_State", rec.marketStateText);

   // Update recommendation code with icon
   SetText("Strategy_Rec_Code", GetRecommendationIcon(rec.recommendationCode));
   SetColor("Strategy_Rec_Code", rec.recommendationColor);

   // Update recommendation text
   SetText("Strategy_Rec_Text", rec.recommendationText);
   SetColor("Strategy_Rec_Text", rec.recommendationColor);

   // Update reasoning
   SetText("Strategy_Reasoning", rec.reasoning);

   // Update entry details - format as "ENTRY: MARKET @ 1.0850 | TP: 1.0900 | SL: 1.0800"
   if(rec.entryType != "")
   {
      string entryText = StringFormat("ENTRY: %s @ %s | %s",
                                       rec.entryType,
                                       rec.entryPriceText,
                                       rec.targetsText);
      SetText("Strategy_Entry_Row", entryText);
   }
   else
   {
      SetText("Strategy_Entry_Row", "ENTRY: -- | TP: -- | SL: --");
   }

   // Update alternatives if present
   if(rec.alternatives != "")
   {
      SetText("Strategy_Alt_Label", "Alt:");
      SetText("Strategy_Alt_Text", rec.alternatives);
   }
   else
   {
      SetText("Strategy_Alt_Label", "");
      SetText("Strategy_Alt_Text", "");
   }
}

//+------------------------------------------------------------------+
//| Get Recommendation Icon                                           |
//| Convert recommendation code to visual icon                        |
//+------------------------------------------------------------------+
string CDashboardPanel::GetRecommendationIcon(string code)
{
   if(code == "BUY" || code == "SELL") return "✅";
   if(code == "WAIT_PULLBACK" || code == "WAIT_ZONE") return "⚠️";
   if(code == "STAY_OUT" || code == "CHOPPY" || code == "NO_TREND") return "🔴";
   if(code == "WAIT") return "⏳";
   return "⏳";  // Default
}

//+------------------------------------------------------------------+
//| Update Auto Mode Status                                            |
//| Display filter states for Sniper and Hybrid auto modes            |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateAutoModeStatus(bool sniperEnabled, bool hybridEnabled,
                                           SniperFilterStates &sniperStates,
                                           HybridFilterStates &hybridStates)
{
   // Sniper row - status + filters combined
   string sniperStatus = sniperEnabled ? "🟢 ON" : "⚪ OFF";
   string sniperFilters = StringFormat("PA:[%c] LOC:[%c] VOL:[%c] ZONE:[%c]",
                                       sniperStates.PA ? '✓' : '❌',
                                       sniperStates.LOC ? '✓' : '❌',
                                       sniperStates.VOL ? '✓' : '❌',
                                       sniperStates.ZONE ? '✓' : '❌');
   string sniperRow = "SNIPER: " + sniperStatus + "  " + sniperFilters;
   SetText("Auto_Sniper_Row", sniperRow);

   // Hybrid row - status + filters combined
   string hybridStatus = hybridEnabled ? "🟢 ON" : "⚪ OFF";
   string hybridM5Icon = hybridStates.M5 ? (hybridStates.M5Match ? "✓" : "⚠") : "⏳";
   string hybridFilters = StringFormat("Trend:[%c score=%+d] ADX:[%c] M5:[%c]",
                                       hybridStates.Trend ? '✓' : '❌',
                                       hybridStates.TrendScore,
                                       hybridStates.ADX ? '✓' : '❌',
                                       hybridM5Icon);
   string hybridRow = "HYBRID: " + hybridStatus + "  " + hybridFilters;
   SetText("Auto_Hybrid_Row", hybridRow);
}

//+------------------------------------------------------------------+
//| Check if individual order close button was clicked (with Scroll)   |
//+------------------------------------------------------------------+
bool CDashboardPanel::IsCloseOrderButtonClicked(string sparam, int &index)
{
   for(int displayIndex = 0; displayIndex < m_visible_count; displayIndex++)
   {
      if(sparam == m_prefix + "BtnCloseOrder_" + IntegerToString(displayIndex))
      {
         // Return actual order index (display index + scroll offset)
         index = m_scroll_offset + displayIndex;
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Handle Chart Events (Settings Buttons)                           |
//+------------------------------------------------------------------+
void CDashboardPanel::OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // Handle Settings Button Clicks (RR and Profit Lock)
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      //--- RR Button Clicks (Radio Behavior)
      if(sparam == m_prefix + "BtnRR1" && m_current_rr != RR_1_TO_1)
      {
         // 1. IMMEDIATE Unpress (removes native press animation - FEELS SNAPPY)
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
         // 2. Logic Update
         m_current_rr = RR_1_TO_1;
         // 3. Visual Update
         UpdateRRButtonsVisuals();
         // 4. Force Redraw
         ChartRedraw(m_chart_id);
         // 5. Save State
         SaveSettings();
         // 6. Return
         return;
      }
      if(sparam == m_prefix + "BtnRR15" && m_current_rr != RR_1_TO_1_5)
      {
         // 1. IMMEDIATE Unpress
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
         // 2. Logic Update
         m_current_rr = RR_1_TO_1_5;
         // 3. Visual Update
         UpdateRRButtonsVisuals();
         // 4. Force Redraw
         ChartRedraw(m_chart_id);
         // 5. Save State
         SaveSettings();
         // 6. Return
         return;
      }
      if(sparam == m_prefix + "BtnRR2" && m_current_rr != RR_1_TO_2)
      {
         // 1. IMMEDIATE Unpress
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
         // 2. Logic Update
         m_current_rr = RR_1_TO_2;
         // 3. Visual Update
         UpdateRRButtonsVisuals();
         // 4. Force Redraw
         ChartRedraw(m_chart_id);
         // 5. Save State
         SaveSettings();
         // 6. Return
         return;
      }

      //--- Profit Lock Toggle Click
      if(sparam == m_prefix + "BtnTrailToggle")
      {
         // 1. IMMEDIATE Unpress
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
         // 2. Logic Update
         m_trailing_enabled = !m_trailing_enabled;
         // 3. Visual Update
         UpdateTrailingButtonVisuals();
         // 4. Force Redraw
         ChartRedraw(m_chart_id);
         // 5. Save State
         SaveSettings();
         // 6. Return
         return;
      }

      //--- SMART FILTERS Toggle Clicks (v5.0)
      if(sparam == m_prefix + "BtnFilterTrend")
      {
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
         m_filter_trend_enabled = !m_filter_trend_enabled;
         UpdateFilterVisuals();
         ChartRedraw(m_chart_id);
         return;
      }
      if(sparam == m_prefix + "BtnFilterZone")
      {
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
         m_filter_zone_enabled = !m_filter_zone_enabled;
         UpdateFilterVisuals();
         ChartRedraw(m_chart_id);
         return;
      }
      if(sparam == m_prefix + "BtnFilterAggr")
      {
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
         m_filter_aggr_enabled = !m_filter_aggr_enabled;
         // If Aggressive ON -> Filters ignored (visually dimmed)
         UpdateFilterVisuals();
         ChartRedraw(m_chart_id);
         return;
      }

      //--- AUTO STRATEGY Toggle Clicks (moved here for instant response like Settings buttons)
      // NOTE: We can't toggle state here because the global variables are in the main file
      // So we just reset the button state instantly here and return early
      // The actual state toggle happens in main handler (which is fast because it just updates bools)
      if(sparam == m_prefix + "BtnStratArrow" ||
         sparam == m_prefix + "BtnStratRev" ||
         sparam == m_prefix + "BtnStratBreak" ||
         sparam == m_prefix + "BtnStratSniper" ||
         sparam == m_prefix + "BtnStratHybrid")
      {
         // IMMEDIATE button state reset for instant visual feedback
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
         return;  // Return immediately - main handler will toggle state and redraw
      }

      // Note: Profit Lock inputs (Trigger/Lock/Step Edits) are handled natively by MT5
   }
}

//+------------------------------------------------------------------+
//| Update Execution Buttons (Ghost Button Logic)                     |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateExecutionButtons(MarketContext &ctx)
{
   bool safeToBuy = true;
   bool safeToSell = true;

   // 1. Check Aggressive Override (If ON, everything is safe)
   if (!m_filter_aggr_enabled)
   {
      // 2. Check Slope (Falling Knife Protection)
      if (ctx.slopeH1 == SLOPE_CRASH) safeToBuy = false;
      if (ctx.slopeH1 == SLOPE_UP)    safeToSell = false;

      // 3. Check Trend Filter
      if (m_filter_trend_enabled)
      {
         // If H1 is DOWN, Don't Buy (unless it's a deep pullback, but for safety we block)
         if (ctx.trendMatrix.h1 == TREND_DOWN) safeToBuy = false;
         
         // If H1 is UP, Don't Sell
         if (ctx.trendMatrix.h1 == TREND_UP)   safeToSell = false;
      }
      
      // 4. Check Zone Filter (Middle Zone Protection)
      // If Zone Filter is ON, we generally discourage trading in the middle, 
      // but blocking Manual execution might be too strict. 
      // Let's keep Ghost Buttons focused on MOMENTUM/TREND safety.
   }

   // Visual Update
   color buyColor = safeToBuy ? m_buy_color : C'60,60,60'; // Dimmed Dark Gray
   color sellColor = safeToSell ? m_sell_color : C'60,60,60';
   
   color buyText = safeToBuy ? clrWhite : C'150,150,150';
   color sellText = safeToSell ? clrWhite : C'150,150,150';

   SetBgColor("BtnBuy", buyColor);
   SetColor("BtnBuy", buyText);
   
   SetBgColor("BtnSell", sellColor);
   SetColor("BtnSell", sellText);
   
   // We do NOT disable the button functionality (IsBuyButtonClicked checks are still valid).
   // This is a "Nudge", not a hard lock. User can still click if they really want to.
}