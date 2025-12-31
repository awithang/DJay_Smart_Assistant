//+------------------------------------------------------------------+
//|                                                DashboardPanel.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "4.00"

#include <EA_Helper/Definitions.mqh>

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
   long              m_order_tickets[4];

   // Helper: Convert relative Y (0 at top of panel) to absolute Y (distance from anchor)
   int Y(int relative_y) { return (m_base_y + m_panel_height) - relative_y; }

   void CreateRect(const string name, int x, int ry, int w, int h, color bg, bool border=false, color border_color=clrNONE);
   void CreateLabel(const string name, int x, int ry, const string text, color clr, int font_size, const string font="Arial", string align="left");
   void CreateEdit(const string name, int x, int ry, int width, int height, const string text);
   void CreateButton(const string name, int x, int ry, int width, int height, const string text, color clr, color txt_clr=clrWhite, int font_size=8);
   void CreateHLine(const string name, double price, color clr, ENUM_LINE_STYLE style, int width, const string desc);
   void AddLevel(double &arr[], string &lbls[], double price, string label);

public:
   CDashboardPanel();
   ~CDashboardPanel() { Destroy(); }

   void Init(long chart_id);
   void CreatePanel();
   
   void UpdatePrice(double price);
   void UpdateSessionInfo(string session_name, string countdown, bool is_gold_time);
   void UpdateWidwaZones(double d1_open);
   void UpdateStrategyInfo(string reversal_alert, string breakout_alert, string pa_sig);
   void UpdateTrendStrength(string strengthText, color strengthColor);
   void UpdateZoneStatus(int zoneStatus);  // 0=none, 1=buy1, 2=buy2, 3=sell1, 4=sell2
   void UpdateAdvisor(string message);
   void UpdateLastAutoTrade(string strategy, string direction, double price);
   void UpdateActiveOrders(int count, long &tickets[], string &order_details[], int &order_types[], double total_profit);

   // New Methods
   void UpdateTradingMode(int mode);
   void UpdateStrategyButtons(bool arrow, bool rev, bool brk);
   void UpdateConfirmButton(string text, bool enable);
   
   void Redraw() { ChartRedraw(m_chart_id); }

   bool IsModeButtonClicked(string sparam) { return (sparam == m_prefix+"BtnMode"); }
   bool IsConfirmButtonClicked(string sparam) { return (sparam == m_prefix+"BtnConfirm"); }
   bool IsCloseAllButtonClicked(string sparam) { return (sparam == m_prefix+"BtnCloseAll"); }

   // Individual order close button handlers
   bool IsCloseOrderButtonClicked(string sparam, int &index);
   long GetOrderTicket(int index) { return (index >= 0 && index < 4) ? m_order_tickets[index] : 0; }

   bool IsStratArrowClicked(string sparam) { return (sparam == m_prefix+"BtnStratArrow"); }
   bool IsStratRevClicked(string sparam) { return (sparam == m_prefix+"BtnStratRev"); }
   bool IsStratBreakClicked(string sparam) { return (sparam == m_prefix+"BtnStratBreak"); }

   bool IsRevActionClicked(string sparam) { return (sparam == m_prefix+"BtnRev"); }
   bool IsBrkActionClicked(string sparam) { return (sparam == m_prefix+"BtnBrk"); }

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
   m_panel_height = 540;  // Increased height for full-width Active Orders section
   m_blink_state = false;

   m_bg_color = C'35,35,45';      // Dark Grey Background
   m_header_color = C'255,223,0'; // Bright Gold
   m_text_color = clrWhite;
   m_label_color = C'200,200,200'; // Light Grey
   m_buy_color = C'34,139,34';    // ForestGreen (Darker)
   m_sell_color = C'139,0,0';     // DarkRed (Darker)
   m_supply_color = C'255,140,0'; // Dark Orange
   m_accent_color = C'0,191,255'; // Deep Sky Blue
}

void CDashboardPanel::Init(long chart_id)
{
   m_chart_id = chart_id;
   CreatePanel();
}

void CDashboardPanel::CreatePanel()
{
   Destroy();

   int x = m_base_x;
   int pad = 10;
   int half_width = (m_panel_width - 30) / 2;  // 50/50 split with padding
   int left_x = x + 5;
   int right_x = x + 5 + half_width + 10;

   // ============================================
   // MAIN BACKGROUND - Single unified panel
   // ============================================
   CreateRect("MainBG", x, 0, m_panel_width, m_panel_height, m_bg_color, true, clrWhite);

   // ============================================
   // LEFT PANEL (50%)
   // ============================================

   // 1. Header Section (Left Panel)
   // Title with left padding
   CreateLabel("Title", left_x + pad, 15, "DJAY Smart Assistant", m_header_color, 11, "Arial Bold");
   
   // Balance moved to bottom section

   // 2. Market Status (Left Panel)
   CreateLabel("LblSes", left_x + pad, 35, "SESSION: --", m_text_color, 9);
   CreateLabel("LblTime", left_x + pad + 100, 35, "M5: --:--", clrGray, 9); 
   
   CreateLabel("LblRunTime", left_x + pad, 48, "SIDEWAY", clrGray, 9, "Arial Bold");
   CreateLabel("LblZoneStat", left_x + pad, 61, "NEUTRAL", clrGray, 9, "Arial Bold");

   // 3. Daily Zones Table (Left Panel)
   CreateLabel("LblZ", left_x + pad, 75, "DAILY ZONES (Smart Grid)", m_accent_color, 10, "Arial Bold");
   CreateRect("TableBG", left_x, 90, half_width, 110, C'5,5,15', true, C'45,45,60');

   // Table Headers
   CreateLabel("H_Z", left_x + 10, 100, "ZONE", clrGray, 8);
   CreateLabel("H_P", left_x + 85, 100, "PRICE", clrGray, 8);
   CreateLabel("H_D", left_x + 150, 100, "DIST", clrGray, 8);

   // Table Rows (5 rows)
   for(int i = 0; i < 5; i++)
   {
      string id = IntegerToString(i);
      int ry = 115 + (i * 18);
      CreateLabel("L_N_" + id, left_x + 10, ry, "--", clrWhite, 9);
      CreateLabel("L_P_" + id, left_x + 85, ry, "0.00", m_text_color, 9);
      CreateLabel("L_D_" + id, left_x + 150, ry, "0 pts", clrGray, 9);
   }

   // 4. Strategy Signal (Left Panel - Bottom)
   CreateLabel("LblSig", left_x + pad, 215, "STRATEGY SIGNAL", m_text_color, 10, "Arial Bold");
   CreateRect("InfoBG", left_x, 230, half_width, 140, C'5,5,15');

   CreateLabel("Trend_T", left_x + 10, 242, "Trend:", clrGold, 9);
   CreateLabel("Trend_V", left_x + 50, 242, "--", clrGray, 9, "Arial Bold");

   // PA Signal (moved under Trend)
   CreateLabel("PA_T", left_x + 10, 258, "PA Signal:", clrGold, 9);
   CreateLabel("PA_V", left_x + 75, 258, "NONE", clrGray, 9);

   // Reversal Alert (replaces EMA M15)
   CreateLabel("Rev_T", left_x + 10, 274, "Reversal Alert:", clrGold, 9);
   CreateLabel("Rev_V", left_x + 95, 274, "--", clrGray, 9);
   CreateButton("BtnRev", left_x + half_width - 45, 272, 35, 16, "SET", clrGray, clrWhite, 8);

   // Breakout Alert (replaces EMA H1)
   CreateLabel("Break_T", left_x + 10, 290, "Breakout Alert:", clrGold, 9);
   CreateLabel("Break_V", left_x + 95, 290, "--", clrGray, 9);
   CreateButton("BtnBrk", left_x + half_width - 45, 288, 35, 16, "SET", clrGray, clrWhite, 8);

   // Separator line before Advisor
   CreateRect("Sep1", left_x + 8, 302, half_width - 16, 1, C'60,60,70');

   // Advisor: Natural language recommendation
   CreateLabel("Adv_T", left_x + 10, 312, "Advisor:", m_accent_color, 10, "Arial Bold");
   CreateLabel("Adv_V", left_x + 10, 327, "Scanning market...", clrCyan, 9);
   CreateLabel("Adv_V2", left_x + 10, 342, "", clrCyan, 9);

   // REMOVED Risk_T and Risk_V labels

   CreateLabel("Ver", left_x + half_width - pad, 363, "v4.0", clrGray, 8);

   // ============================================
   // RIGHT PANEL (50%)
   // ============================================

   // 5. Execution Section (Right Panel - Top)
   CreateLabel("LblCtrl", right_x + pad, 15, "EXECUTION", m_text_color, 10, "Arial Bold");
   CreateLabel("LblPrice", right_x + half_width - pad, 15, "0.00000", m_header_color, 10, "Arial Bold", "right");

   CreateLabel("LblRisk", right_x + pad, 38, "Risk %", clrGray, 9);
   CreateEdit("EditRisk", right_x + half_width - pad - 25, 35, 30, 18, "1.0");

   CreateButton("BtnBuy", right_x + pad, 62, (half_width - 30) / 2, 38, "BUY", m_buy_color, clrWhite, 9);
   CreateButton("BtnSell", right_x + pad + (half_width - 30) / 2 + 10, 62, (half_width - 30) / 2, 38, "SELL", m_sell_color, clrWhite, 9);

   // Confirm Button (Pending recommendation)
   CreateButton("BtnConfirm", right_x + pad, 110, half_width - 20, 28, "NO SIGNAL", C'50,50,60', C'100,100,100', 9);

   // 6. Auto Strategy Options (Right Panel - Below Confirm)
   int stratY = 152;
   CreateLabel("LblStratTitle", right_x + pad, stratY, "AUTO STRATEGY", m_text_color, 10, "Arial Bold");

   // Auto Mode Toggle (Next to title)
   CreateButton("BtnMode", right_x + half_width - 55, stratY - 5, 45, 22, "OFF", clrGray, clrWhite, 9);

   // Section Box
   CreateRect("StratBG", right_x, stratY + 25, half_width, 90, C'5,5,15', true, C'45,45,60');

   CreateButton("BtnStratArrow", right_x + 10, stratY + 38, 15, 15, "", clrGray);
   CreateLabel("L_Arrow", right_x + 30, stratY + 38, "Arrow", clrCyan, 9, "Arial Bold");

   CreateButton("BtnStratRev", right_x + 80, stratY + 38, 15, 15, "", clrGray);
   CreateLabel("L_Rev", right_x + 100, stratY + 38, "Rev", clrCyan, 9, "Arial Bold");

   CreateButton("BtnStratBreak", right_x + 150, stratY + 38, 15, 15, "", clrGray);
   CreateLabel("L_Break", right_x + 170, stratY + 38, "Break", clrCyan, 9, "Arial Bold");

   // Last Trade Label
   CreateLabel("LblLastAuto", right_x + 10, stratY + 70, "Last: ---", C'80,80,80', 8);

   // 7. Active Orders Section (moved to bottom, full width)
   // Position below all other content, covers both left and right panels
   int orderY = 385;  // Bottom of panel, full width
   CreateLabel("LblAct", x + pad, orderY, "ACTIVE ORDERS (0)", clrLime, 10, "Arial Bold");
   
   // New Balance and Profit Labels
   CreateLabel("LblBalance", x + 150, orderY, "Balance: $--", clrWhite, 9, "Arial Bold");
   CreateLabel("LblTotalProfit", x + 280, orderY, "Profit: $0.00", clrGray, 9, "Arial Bold");
   
   CreateButton("BtnCloseAll", x + m_panel_width - 70, orderY - 2, 60, 18, "CLOSE ALL", m_sell_color, clrWhite, 8);

   // Full-width order list with individual close buttons
   CreateRect("OrderListBG", x, orderY + 20, m_panel_width - 20, 115, C'5,5,15', true, C'45,45,60');
   for(int i=0; i<4; i++)
   {
      string sid = IntegerToString(i);
      int rowY = orderY + 38 + (i * 26);
      // Order info label (increased text size to 9)
      CreateLabel("ActOrder_"+sid, x + 10, rowY, "", clrWhite, 10);
      // Individual close button for each order (small X button)
      CreateButton("BtnCloseOrder_"+sid, x + m_panel_width - 45, rowY - 3, 35, 18, "X", C'80,80,80', clrWhite, 9);
   }

   UpdateAccountInfo();
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
void CDashboardPanel::UpdateStrategyButtons(bool arrow, bool rev, bool brk)
{
   color bgArrow = arrow ? m_buy_color : clrGray;
   color bgRev   = rev ? m_buy_color : clrGray;
   color bgBrk   = brk ? m_buy_color : clrGray;
   
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratArrow", OBJPROP_BGCOLOR, bgArrow);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratRev", OBJPROP_BGCOLOR, bgRev);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnStratBreak", OBJPROP_BGCOLOR, bgBrk);
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

void CDashboardPanel::UpdateWidwaZones(double d1_open)
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
   int best_idx[5]; double best_dist[5];
   for(int k=0; k<5; k++) { best_dist[k] = 999999; best_idx[k] = -1; }
   
   for(int i=0; i<count; i++)
   {
      double dist = MathAbs(current - levels[i]);
      for(int k=0; k<5; k++)
      {
         if(dist < best_dist[k])
         {
            for(int j=4; j>k; j--) { best_dist[j] = best_dist[j-1]; best_idx[j] = best_idx[j-1]; }
            best_dist[k] = dist; best_idx[k] = i; break;
         }
      }
   }
   
   // Sort by Price DESC
   for(int i=0; i<4; i++)
      for(int j=0; j<4-i; j++)
         if(best_idx[j] != -1 && best_idx[j+1] != -1 && levels[best_idx[j]] < levels[best_idx[j+1]])
         { int t = best_idx[j]; best_idx[j] = best_idx[j+1]; best_idx[j+1] = t; }

   for(int i=0; i<5; i++)
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
}

void CDashboardPanel::UpdateSessionInfo(string session_name, string countdown, bool is_gold_time)
{
   ObjectSetString(m_chart_id, m_prefix+"LblSes", OBJPROP_TEXT, "SESSION: " + session_name);
   ObjectSetString(m_chart_id, m_prefix+"LblTime", OBJPROP_TEXT, countdown);
   if(is_gold_time) {
      ObjectSetString(m_chart_id, m_prefix+"LblRunTime", OBJPROP_TEXT, "RUN TIME");
      ObjectSetInteger(m_chart_id, m_prefix+"LblRunTime", OBJPROP_COLOR, clrLime);
   } else {
      ObjectSetString(m_chart_id, m_prefix+"LblRunTime", OBJPROP_TEXT, "SIDEWAY");
      ObjectSetInteger(m_chart_id, m_prefix+"LblRunTime", OBJPROP_COLOR, clrGray);
   }
}

void CDashboardPanel::UpdateStrategyInfo(string reversal_alert, string breakout_alert, string pa_sig)
{
   // Update Reversal Alert & Button
   ObjectSetString(m_chart_id, m_prefix+"Rev_V", OBJPROP_TEXT, reversal_alert);
   if(StringFind(reversal_alert, "BUY") >= 0) {
      ObjectSetInteger(m_chart_id, m_prefix+"BtnRev", OBJPROP_BGCOLOR, m_buy_color);
      ObjectSetString(m_chart_id, m_prefix+"BtnRev", OBJPROP_TEXT, "BUY");
   } else if(StringFind(reversal_alert, "SELL") >= 0) {
      ObjectSetInteger(m_chart_id, m_prefix+"BtnRev", OBJPROP_BGCOLOR, m_sell_color);
      ObjectSetString(m_chart_id, m_prefix+"BtnRev", OBJPROP_TEXT, "SELL");
   } else {
      ObjectSetInteger(m_chart_id, m_prefix+"BtnRev", OBJPROP_BGCOLOR, clrGray);
      ObjectSetString(m_chart_id, m_prefix+"BtnRev", OBJPROP_TEXT, "SET");
   }

   // Update Breakout Alert & Button
   ObjectSetString(m_chart_id, m_prefix+"Break_V", OBJPROP_TEXT, breakout_alert);
   if(StringFind(breakout_alert, "BUY") >= 0) {
      ObjectSetInteger(m_chart_id, m_prefix+"BtnBrk", OBJPROP_BGCOLOR, m_buy_color);
      ObjectSetString(m_chart_id, m_prefix+"BtnBrk", OBJPROP_TEXT, "BUY");
   } else if(StringFind(breakout_alert, "SELL") >= 0) {
      ObjectSetInteger(m_chart_id, m_prefix+"BtnBrk", OBJPROP_BGCOLOR, m_sell_color);
      ObjectSetString(m_chart_id, m_prefix+"BtnBrk", OBJPROP_TEXT, "SELL");
   } else {
      ObjectSetInteger(m_chart_id, m_prefix+"BtnBrk", OBJPROP_BGCOLOR, clrGray);
      ObjectSetString(m_chart_id, m_prefix+"BtnBrk", OBJPROP_TEXT, "SET");
   }

   // Update PA Signal
   ObjectSetString(m_chart_id, m_prefix+"PA_V", OBJPROP_TEXT, pa_sig);

   color pc = clrGray;
   if(StringFind(pa_sig, "BUY") >= 0)
      pc = m_buy_color;
   else if(StringFind(pa_sig, "SELL") >= 0)
      pc = m_sell_color;

   ObjectSetInteger(m_chart_id, m_prefix+"PA_V", OBJPROP_COLOR, pc);
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
//| Update Active Orders List                                        |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateActiveOrders(int count, long &tickets[], string &order_details[], int &order_types[], double total_profit)
{
   // Update count label
   ObjectSetString(m_chart_id, m_prefix+"LblAct", OBJPROP_TEXT, StringFormat("ACTIVE ORDERS (%d)", count));

   // Update Balance
   ObjectSetString(m_chart_id, m_prefix+"LblBalance", OBJPROP_TEXT, StringFormat("Balance: $%.2f", AccountInfoDouble(ACCOUNT_BALANCE)));

   // Update Total Profit
   if(count > 0)
   {
      ObjectSetString(m_chart_id, m_prefix+"LblTotalProfit", OBJPROP_TEXT, StringFormat("Profit: $%.2f", total_profit));
      color profitColor = (total_profit >= 0) ? clrLime : m_sell_color;
      ObjectSetInteger(m_chart_id, m_prefix+"LblTotalProfit", OBJPROP_COLOR, profitColor);
   }
   else
   {
      ObjectSetString(m_chart_id, m_prefix+"LblTotalProfit", OBJPROP_TEXT, "Profit: $0.00");
      ObjectSetInteger(m_chart_id, m_prefix+"LblTotalProfit", OBJPROP_COLOR, clrGray);
   }

   // Calculate button positions (same as in CreatePanel)
   int x = m_base_x;
   int orderY = 385;

   // Update slots and store tickets
   for(int i = 0; i < 4; i++)
   {
      string sid = IntegerToString(i);

      if(i < count)
      {
         // Active order - show details with color theme
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_"+sid, OBJPROP_TEXT, order_details[i]);
         m_order_tickets[i] = tickets[i];

         // Apply color theme based on order type
         // POSITION_TYPE_BUY = 0, POSITION_TYPE_SELL = 1
         color orderColor = (order_types[i] == 0) ? clrLime : m_sell_color; // Green for BUY, Red for SELL
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_"+sid, OBJPROP_COLOR, orderColor);

         // Show individual close button by restoring its original position
         int btnX = x + m_panel_width - 45;
         ObjectSetInteger(m_chart_id, m_prefix+"BtnCloseOrder_"+sid, OBJPROP_XDISTANCE, btnX);
         ObjectSetInteger(m_chart_id, m_prefix+"BtnCloseOrder_"+sid, OBJPROP_STATE, false);
      }
      else
      {
         // Empty slot - clear details, hide close button, reset ticket
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_"+sid, OBJPROP_TEXT, "");
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_"+sid, OBJPROP_COLOR, clrGray); // Reset color to gray
         m_order_tickets[i] = 0;

         // Hide individual close button by moving it off-screen
         ObjectSetInteger(m_chart_id, m_prefix+"BtnCloseOrder_"+sid, OBJPROP_XDISTANCE, -100);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if individual order close button was clicked               |
//+------------------------------------------------------------------+
bool CDashboardPanel::IsCloseOrderButtonClicked(string sparam, int &index)
{
   for(int i = 0; i < 4; i++)
   {
      if(sparam == m_prefix + "BtnCloseOrder_" + IntegerToString(i))
      {
         index = i;
         return true;
      }
   }
   return false;
}