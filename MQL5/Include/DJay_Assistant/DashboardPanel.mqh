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

   //--- Initial Parameter Values (from EA Inputs) - FIX: UI Inputs sync
   double            m_initial_risk;         // Initial Risk % from EA inputs
   int               m_initial_pl_trigger;   // Initial PL Trigger from EA inputs
   int               m_initial_pl_lock;      // Initial PL Lock Amount from EA inputs
   int               m_initial_pl_step;      // Initial PL Step from EA inputs

   //--- RR Multiplier Lookup Table (NEW)
   double            m_rr_multipliers[3];    // [1.0, 1.5, 2.0]

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
   void UpdateActiveOrders(int count, long &tickets[], double &prices[], double &profits[], double &lots[], int &types[], double total_profit);

   // New Methods
   void UpdateTradingMode(int mode);
   void UpdateStrategyButtons(bool arrow, bool rev, bool brk, bool qs);
   void UpdateQuickScalpButton(bool isActive);
   void UpdateQuickScalpSmartState(bool isEnabled, ENUM_ZONE_STATUS zone, double adx, double adxThreshold);
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
   bool IsStratQSClicked(string sparam) { return (sparam == m_prefix+"BtnStratQS"); }

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
   
   void Destroy() { ObjectsDeleteAll(m_chart_id, "EA_"); ChartRedraw(m_chart_id); }
};

CDashboardPanel::CDashboardPanel()
{
   m_chart_id = 0;
   m_corner = CORNER_LEFT_LOWER;
   m_prefix = "EA_"; // Simple prefix to catch everything
   m_base_x = 10;
   m_base_y = 10;
   m_panel_width = 500;  // Wider for two-panel layout (50/50 split)
   m_panel_height = 710;  // Reduced from 780 to remove gap (v6)
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

   CreatePanel();
}

void CDashboardPanel::CreatePanel()
{
   Destroy();

   int x = m_base_x;

   int pad = 10;

   int half_width = 235;  

   int left_x = x + 5;

   int right_x = x + 5 + half_width + 10; 



   // ============================================

   // MAIN BACKGROUND

   // ============================================

   CreateRect("MainBG", x, 0, m_panel_width, m_panel_height, m_bg_color, true, clrWhite);



   // ============================================

   // LEFT PANEL (Panel A)

   // ============================================



      // 1. Header Section (Market Status)



      // Center the title label in left panel (half_width = 235, text width ~130px)
      CreateLabel("Title", left_x + (half_width / 2) - 65, 15, "DJAY Smart Assistant", C'255,223,0', 11, "Arial Bold");



      CreateLabel("LblSesTitle", left_x + pad, 35, "SESSION:", m_text_color, 9);



      CreateLabel("LblSesValue", left_x + pad + 60, 35, "--", clrGray, 9, "Arial");



      CreateLabel("LblTime", left_x + half_width - pad, 35, "M5: --:--", clrOrange, 9, "Arial", "right");

   

      

         CreateLabel("LblRunTimeTitle", left_x + pad, 48, "STATUS:", m_text_color, 9);

   

      

         CreateLabel("LblRunTime", left_x + pad + 60, 48, "SIDEWAY", clrGray, 9, "Arial");

   

      

         

   

      

         CreateLabel("LblZoneStatTitle", left_x + pad, 61, "ZONE:", m_text_color, 9);

   

      

         CreateLabel("LblZoneStat", left_x + pad + 60, 61, "NEUTRAL", clrGray, 9, "Arial");



   // 3. Daily Zones Table (Panel A)
   // Shifted down to accommodate expanded Strategy Signal section

   CreateLabel("LblZ", left_x + pad, 320, "DAILY ZONES (Smart Grid)", m_header_color, 10, "Arial Bold");

   CreateRect("TableBG", left_x, 340, half_width, 140, C'5,5,15', true, C'45,45,60');



   // Table Headers

   CreateLabel("H_Z", left_x + 10, 350, "ZONE", clrGray, 8);

   CreateLabel("H_P", left_x + 85, 350, "PRICE", clrGray, 8);

   CreateLabel("H_D", left_x + 150, 350, "DIST", clrGray, 8);



   for(int i = 0; i < 6; i++)

   {

      string id = IntegerToString(i);

      int ry = 365 + (i * 18);

      CreateLabel("L_N_" + id, left_x + 10, ry, "--", clrWhite, 9);

      CreateLabel("L_P_" + id, left_x + 85, ry, "0.00", m_text_color, 9);

      CreateLabel("L_D_" + id, left_x + 150, ry, "0 pts", clrGray, 9);

   }


   // 2. Strategy Signal Section (Panel A)
   // Moved from Panel B to improve layout balance
   // Expanded Advisor section with more details (zones reduced to 3, saving space)

   CreateLabel("LblSig", left_x + pad, 80, "STRATEGY SIGNAL", m_header_color, 10, "Arial Bold");

   CreateRect("InfoBG", left_x, 100, half_width, 210, C'5,5,15');



   int sig_y = 112;

   CreateLabel("Trend_T", left_x + 10, sig_y, "Trend:", m_header_color, 9);

   CreateLabel("Trend_V", left_x + 50, sig_y, "--", clrGray, 9, "Arial Bold");



   sig_y += 16;

   CreateLabel("PA_T", left_x + 10, sig_y, "PA Signal:", m_header_color, 9);

   CreateLabel("PA_V", left_x + 75, sig_y, "NONE", clrGray, 9);



   sig_y += 17;

   CreateRect("Sep1", left_x + 8, sig_y, half_width - 16, 1, C'60,60,70');



   sig_y += 8;

   CreateLabel("Adv_T", left_x + 10, sig_y, "Advisor:", m_accent_color, 10, "Arial Bold");

   sig_y += 16;

   CreateLabel("Adv_V", left_x + 10, sig_y, "Scanning market...", clrCyan, 9);

   sig_y += 14;

   CreateLabel("Adv_V2", left_x + 10, sig_y, "", clrCyan, 9);

   sig_y += 18;

   // Detailed status labels (formatted like Advisor, but orange)
   CreateLabel("Stat_T", left_x + 10, sig_y, "Quick Scalp Status:", m_accent_color, 10, "Arial Bold");

   sig_y += 16;

   CreateLabel("Stat_Zone", left_x + 10, sig_y, "", C'255,165,0', 9);

   sig_y += 14;

   CreateLabel("Stat_Trend", left_x + 10, sig_y, "", C'255,165,0', 9);

   sig_y += 14;

   CreateLabel("Stat_QS", left_x + 10, sig_y, "", C'255,165,0', 9);

   sig_y += 14;

   CreateLabel("Stat_RSI", left_x + 10, sig_y, "", C'255,165,0', 9);

   sig_y += 14;

   CreateLabel("Stat_ADX", left_x + 10, sig_y, "", C'100,200,255', 9);

   sig_y += 14;

   CreateLabel("Stat_PA", left_x + 10, sig_y, "", C'150,255,150', 9);

   sig_y += 20;

   CreateLabel("Ver", left_x + half_width - pad, sig_y, "v5.0", clrGray, 8);


   // ============================================

   // RIGHT PANEL (Panel B)

   // ============================================



            // ============================================



            // RIGHT PANEL (Panel B) - REORDERED V5



            // ============================================



         



            int right_y = 15;



            int row_h = 20;



            int gap_y = 10; // Reduced gap



         



                        // 4. Manual Execution (TOP PRIORITY)



         



                        CreateLabel("LblCtrl", right_x + pad, right_y, "EXECUTION", m_header_color, 10, "Arial Bold");



         



                        CreateLabel("LblPrice", right_x + half_width - pad, right_y, "0.00000", C'255,223,0', 10, "Arial Bold", "right");



         



                        



         



                        right_y += 20;



         



                        int btnW = (half_width - 30) / 2;



         



                        CreateButton("BtnBuy", right_x + 10, right_y, btnW, 30, "BUY", m_buy_color, clrWhite, 9);



         



                        CreateButton("BtnSell", right_x + half_width - 10 - btnW, right_y, btnW, 30, "SELL", m_sell_color, clrWhite, 9);



         



                     



         



                        // GAP REDUCTION: Reduced from 50 to 40 to tighten top section



         



                        right_y += 40;



         



            



         



                                                // 5. Settings Section (SWAPPED - NOW 2ND)



         



            



         



                                                CreateLabel("LblSettings", right_x + pad, right_y, "SETTINGS", m_header_color, 10, "Arial Bold");



         



            



         



                                                // Changed to "Open Properties" with wider button



         



            



         



                                                // Settings icon (gear) - left position
                                                CreateButton("BtnOpenSettings", right_x + half_width - 50, right_y, 20, 20, "⚙", clrGray, clrWhite, 12);

                                                // Statistics icon (clipboard) - to the right of Settings
                                                CreateButton("BtnStats", right_x + half_width - 25, right_y, 20, 20, "📋", clrGray, clrWhite, 12);



         



            



         



                                                



         



            



         



                                                right_y += 20; 



         



            



         



                                                // Compact Height: 150px



         



                        CreateRect("SettingsBG", right_x, right_y, half_width, 150, C'5,5,15', true, C'45,45,60');



         



            



         



                        // Row 1: RR Radio Buttons



         



                        right_y += 8;



         



                        CreateLabel("L_RR_Title", right_x + pad, right_y + 3, "RR:", clrGray, 9);



         



                        



         



                        int rrBtnW = 45;



         



                        int rrGap = 5;



         



                        int rrTotalW = (rrBtnW * 3) + (rrGap * 2);



         



                        int rrStartX = (right_x + half_width - pad) - rrTotalW; 



         



                        



         



                        CreateButton("BtnRR1", rrStartX, right_y, rrBtnW, row_h, "1:1", clrGray, clrWhite, 8);



         



                        CreateButton("BtnRR15", rrStartX + rrBtnW + rrGap, right_y, rrBtnW, row_h, "1:1.5", clrGray, clrWhite, 8);



         



                        CreateButton("BtnRR2", rrStartX + (rrBtnW + rrGap) * 2, right_y, rrBtnW, row_h, "1:2", m_buy_color, clrWhite, 8); 



         



            



         



                        // Row 2: Risk %



         



                        right_y += row_h + 8; // Compact gap



         



                        CreateLabel("LblRisk", right_x + pad, right_y + 3, "Risk %", clrGray, 9);



         



                        CreateEdit("EditRisk", right_x + half_width - pad - 40, right_y, 40, row_h, DoubleToString(m_initial_risk, 1));



         



            



         



                        // Row 3: Profit Lock Toggle



         



                        right_y += row_h + 8; // Compact gap



         



                        CreateLabel("L_Trail", right_x + pad, right_y + 3, "Profit Lock", clrGray, 9);



         



                        CreateButton("BtnTrailToggle", right_x + half_width - 65, right_y, 60, row_h, "ON", m_buy_color, clrWhite, 9);



         



            



         



                        // Row 4: Profit Lock Label



         



                        right_y += row_h + 8; 



         



                        CreateLabel("L_PL_Title", right_x + pad, right_y, "Profit Lock Settings", clrGray, 9); 



         



                        



         



                        // Row 5: Profit Lock Inputs



         



                        right_y += 20; 



         



                        



         



                        int plEditW = 35;



         



                        int plGap = 15; 



         



                        int plTotalW = 213; 



         



                        int plX = (right_x + half_width - pad) - plTotalW; 



         



                        



         



                        // Trigger



         



                        CreateLabel("L_PL_Trig", plX, right_y + 3, "Trig", clrGray, 8);



         



                        CreateEdit("EditPL_Trigger", plX + 25, right_y, plEditW, row_h, IntegerToString(m_initial_pl_trigger));



         



                        



         



                        // Lock



         



                        plX += 25 + plEditW + plGap;



         



                        CreateLabel("L_PL_Lock", plX, right_y + 3, "Lock", clrGray, 8);



         



                        CreateEdit("EditPL_Amount", plX + 28, right_y, plEditW, row_h, IntegerToString(m_initial_pl_lock));



         



                        



         



                        // Step



         



                        plX += 28 + plEditW + plGap;



         



                        CreateLabel("L_PL_Step", plX, right_y + 3, "Step", clrGray, 8);



         



                        CreateEdit("EditPL_Step", plX + 25, right_y, plEditW, row_h, IntegerToString(m_initial_pl_step));



         



            



         



                        // 6. Auto Strategy Options (SWAPPED - NOW 3RD)



         



                        right_y += 45; // Gap after Settings



         



                        CreateLabel("LblStratTitle", right_x + pad, right_y + 3, "AUTO STRATEGY", m_header_color, 10, "Arial Bold");



         



                        CreateButton("BtnMode", right_x + half_width - 65, right_y, 60, row_h, "OFF", clrGray, clrWhite, 9);



         



            



         



                        right_y += 25;



         



                        CreateRect("StratBG", right_x, right_y, half_width, 65, C'5,5,15', true, C'45,45,60');



         



            



         



                        right_y += 13;

                        // Auto Strategy checkboxes (single row)
                        CreateButton("BtnStratArrow", right_x + 10, right_y, 15, 15, "", clrGray);
                        CreateLabel("L_Arrow", right_x + 30, right_y, "Arrow", clrCyan, 9, "Arial Bold");

                        CreateButton("BtnStratRev", right_x + 85, right_y, 15, 15, "", clrGray);
                        CreateLabel("L_Rev", right_x + 105, right_y, "Rev", clrCyan, 9, "Arial Bold");

                        CreateButton("BtnStratBreak", right_x + 155, right_y, 15, 15, "", clrGray);
                        CreateLabel("L_Break", right_x + 175, right_y, "Break", clrCyan, 9, "Arial Bold");

                        // Quick Scalp section (separate)
                        right_y += 25;
                        CreateLabel("L_QS_Label", right_x + 10, right_y, "QUICK SCALP:", m_header_color, 9, "Arial Bold");
                        CreateButton("BtnStratQS", right_x + 100, right_y, 60, 20, "OFF", C'50,50,60', C'100,100,100', 8);




         



            



         



                        CreateLabel("LblLastAuto", right_x + 10, right_y + 32, "Last: ---", C'80,80,80', 8);



         



            



         



            // ============================================
            // Strategy Signal section moved to Panel A
            // ============================================



         



                        // right_y += 60; // REMOVED: Strategy Signal moved to Panel A



         



                        // CreateLabel LblSig REMOVED - now in Panel A



         



                        // CreateRect InfoBG REMOVED



            



            // int sig_y REMOVED 



            // CreateLabel Trend_T REMOVED



            // CreateLabel Trend_V REMOVED



         



            // sig_y increment REMOVED



            // CreateLabel PA_T REMOVED



            // CreateLabel PA_V REMOVED



         



            // sig_y increment REMOVED



            // CreateRect Sep1 REMOVED



         



            // sig_y increment REMOVED



            // CreateLabel Adv_T REMOVED



            // CreateLabel Adv_V REMOVED



            // CreateLabel Adv_V2 REMOVED



         



            // CreateLabel Ver REMOVED



         



            // ============================================



            // LOWER SECTIONS (Fixed Footer - Unchanged)



            // ============================================



            



            // Ensure Footer starts strictly below the content we just drew



            // Current right_y ends around 15+45+50+75+65+150+45+100 ~ 545px.



            // Footer starts at m_panel_height - 220 = 445.



            // Wait, 545 > 445. Overlap Risk! 



            // If panel H is 665, Footer starts at 445 (Pending) and 535 (Orders).



            // Strategy Signal ends at 545. 



            // We need to move Pending Alerts DOWN or shrink spacing.



            



            // Let's PUSH the Footer down (anchored to bottom).



            // The strategy signal ends around 550px.



            // We have 665px total. 



            // Footer needs ~200px. 550+200 = 750px.



            // WE NEED TO INCREASE PANEL HEIGHT.



            



            // NOTE: The user requested "plenty of space". 



            // I will set Panel Height to 780 in Constructor to accommodate this new vertical stack.



            



            // 7. ACTIVE ORDERS Section (Bottom Anchor)



            int orderY = m_panel_height - 130; 



      



         CreateLabel("LblAct", x + pad, orderY, "ACTIVE ORDERS (0)", m_header_color, 10, "Arial Bold");



         CreateLabel("LblBalance", x + 150, orderY, "Balance: $--", clrWhite, 9, "Arial Bold");



         CreateLabel("LblTotalProfit", x + 280, orderY, "Profit: $0.00", clrGray, 9, "Arial Bold");



         CreateButton("BtnCloseAll", x + m_panel_width - 75, orderY - 2, 65, 18, "CLOSE ALL", m_sell_color, clrWhite, 8);



      



         CreateRect("OrderListBG", x + 5, orderY + 20, m_panel_width - 20, 105, C'5,5,15', true, C'45,45,60');

         // Scroll buttons for Active Orders (hidden when <= 4 orders)
         // Created AFTER OrderListBG to appear on top (z-index)
         // Positioned inside OrderListBG area (right side, within the dark background)
         CreateButton("BtnScrollUp", x + m_panel_width - 30, orderY + 25, 15, 15, "▲", clrGray, clrWhite, 10);
         CreateButton("BtnScrollDown", x + m_panel_width - 30, orderY + 45, 15, 15, "▼", clrGray, clrWhite, 10);



      



         for(int i=0; i<4; i++)



         {



            string sid = IntegerToString(i);



            int rowY = (orderY + 38) + (i * 24); // Tighter list rows



      



            CreateLabel("ActOrder_L_"+sid, -200, rowY, "", clrCyan, 9);



            CreateLabel("ActOrder_M_"+sid, -200, rowY, "", clrWhite, 9);



            CreateLabel("ActOrder_R_"+sid, -200, rowY, "", clrWhite, 9);



            CreateButton("BtnCloseOrder_"+sid, -100, rowY - 3, 35, 18, "X", C'80,80,80', clrWhite, 9);



         }



      



         // 6. PENDING ALERTS Section (Anchored above Active Orders)



         // Active Orders Top is 'orderY'. We want Pending Alerts above it.



         // Pending Section Height ~ 80px (Header + Rect).



         // Gap = 20px.



         // pendingY = orderY - 80 - 20 = orderY - 100.



         int pendingY = orderY - 90;



      



         CreateLabel("LblPending", x + pad, pendingY, "PENDING ALERTS", m_header_color, 10, "Arial Bold");



         CreateButton("BtnConfirm", x + m_panel_width - 130, pendingY - 2, 120, 20, "NO SIGNAL", C'50,50,60', C'100,100,100', 8);



         



         CreateRect("PendingBG", x + 5, pendingY + 20, m_panel_width - 20, 60, C'5,5,15', true, C'45,45,60');



         



   CreateButton("BtnRev", x + 15, pendingY + 30, m_panel_width - 40, 20, "NO REVERSAL SETUP", clrGray, clrWhite, 8);
   CreateButton("BtnBrk", x + 15, pendingY + 55, m_panel_width - 40, 20, "NO BREAKOUT SETUP", clrGray, clrWhite, 8);

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
   Print("DEBUG: UpdateTradingMode called with mode=", mode, " -> ", text);
}

//+------------------------------------------------------------------+
//| Update Strategy Selection Buttons                                |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateStrategyButtons(bool arrow, bool rev, bool brk, bool qs)
{
   color bgArrow = arrow ? m_buy_color : clrGray;
   color bgRev   = rev ? m_buy_color : clrGray;
   color bgBrk   = brk ? m_buy_color : clrGray;

   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratArrow", OBJPROP_BGCOLOR, bgArrow);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratRev", OBJPROP_BGCOLOR, bgRev);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratBreak", OBJPROP_BGCOLOR, bgBrk);

   // Update Quick Scalp button separately
   UpdateQuickScalpButton(qs);
}

//+------------------------------------------------------------------+
//| Update Quick Scalp Button                                         |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateQuickScalpButton(bool isActive)
{
   string text = isActive ? "ON" : "OFF";
   color bg = isActive ? m_buy_color : C'50,50,60';
   color txt = isActive ? clrWhite : C'100,100,100';

   ObjectSetString(m_chart_id, m_prefix+"BtnStratQS", OBJPROP_TEXT, text);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratQS", OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratQS", OBJPROP_COLOR, txt);
}

//+------------------------------------------------------------------+
//| Update Quick Scalp Smart State (Auto-Switch Visual Feedback)      |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateQuickScalpSmartState(bool isEnabled, ENUM_ZONE_STATUS zone, double adx, double adxThreshold)
{
   string btnText;
   color btnColor;
   color bgColor;

   if(!isEnabled)
   {
      // State 1: DISABLED (Gray)
      btnText = "OFF";
      btnColor = clrGray;
      bgColor = C'50,50,60';
   }
   else if(zone == ZONE_STATUS_NONE)
   {
      // Middle zone - check ADX for trading quality
      if(adx >= adxThreshold)
      {
         // State 2: READY (Green) - Middle zone + ADX OK
         btnText = "READY";
         btnColor = clrLime;
         bgColor = C'40,80,40';
      }
      else
      {
         // State 3: LOW ADX (Orange) - Middle zone but choppy
         btnText = "LOW ADX";
         btnColor = clrOrange;
         bgColor = C'80,60,20';
      }
   }
   else
   {
      // State 4: IN ZONE (Yellow) - Not in middle zone
      btnText = "WAIT";
      btnColor = clrYellow;
      bgColor = C'80,80,40';
   }

   // Update button
   ObjectSetString(m_chart_id, m_prefix+"BtnStratQS", OBJPROP_TEXT, btnText);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratQS", OBJPROP_COLOR, btnColor);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratQS", OBJPROP_BGCOLOR, bgColor);
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
   for(int i=-30; i<=30; i++)
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

      // Note: Profit Lock inputs (Trigger/Lock/Step Edits) are handled natively by MT5
   }
}