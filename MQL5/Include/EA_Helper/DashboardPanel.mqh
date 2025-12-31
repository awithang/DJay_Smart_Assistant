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

   // Helper: Convert relative Y (0 at top of panel) to absolute Y (distance from anchor)
   int Y(int relative_y) { return (m_base_y + m_panel_height) - relative_y; }

   void CreateRect(const string name, int x, int ry, int w, int h, color bg, bool border=false, color border_color=clrNONE);
   void CreateLabel(const string name, int x, int ry, const string text, color clr, int font_size, const string font="Arial", string align="left");
   void CreateEdit(const string name, int x, int ry, int width, int height, const string text);
   void CreateButton(const string name, int x, int ry, int width, int height, const string text, color clr, color txt_clr=clrWhite);
   void CreateHLine(const string name, double price, color clr, ENUM_LINE_STYLE style, int width, const string desc);
   void AddLevel(double &arr[], string &lbls[], double price, string label);

public:
   CDashboardPanel();
   ~CDashboardPanel() { Destroy(); }

   void Init(long chart_id);
   void CreatePanel();
   
   void UpdateAccountInfo();
   void UpdatePrice(double price);
   void UpdateSessionInfo(string session_name, string countdown, bool is_gold_time);
   void UpdateWidwaZones(double d1_open);
   void UpdateStrategyInfo(string ema_m15, string ema_h1, string pa_sig, string risk_rec);
   void UpdateTrendStrength(string strengthText, color strengthColor);
   void UpdateZoneStatus(int zoneStatus);  // 0=none, 1=buy1, 2=buy2, 3=sell1, 4=sell2
   void UpdateAdvisor(string message);
   void UpdateLastAutoTrade(string strategy, string direction, double price);

   // New Methods
   void UpdateTradingMode(int mode);
   void UpdateStrategyButtons(bool arrow, bool rev, bool brk);
   void UpdateConfirmButton(string text, bool enable);
   
   bool IsModeButtonClicked(string sparam) { return (sparam == m_prefix+"BtnMode"); }
   bool IsConfirmButtonClicked(string sparam) { return (sparam == m_prefix+"BtnConfirm"); }
   
   bool IsStratArrowClicked(string sparam) { return (sparam == m_prefix+"BtnStratArrow"); }
   bool IsStratRevClicked(string sparam) { return (sparam == m_prefix+"BtnStratRev"); }
   bool IsStratBreakClicked(string sparam) { return (sparam == m_prefix+"BtnStratBreak"); }

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
   m_panel_height = 520;
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
   CreateLabel("Title", left_x + pad, 15, "DJAY Smart Assistant", m_header_color, 10, "Arial Bold");
   CreateLabel("Balance", left_x + pad + 130, 15, "$--", clrWhite, 10, "Arial Bold");

   // 2. Market Status (Left Panel)
   CreateLabel("LblSes", left_x + pad, 35, "SESSION: --", m_text_color, 8);
   CreateLabel("LblTime", left_x + pad, 50, "M5: --:--", clrGray, 8);
   CreateLabel("LblStat", left_x + pad + 130, 42, "SIDEWAY", clrGray, 9, "Arial Bold");

   // 3. Daily Zones Table (Left Panel)
   CreateLabel("LblZ", left_x + pad, 75, "DAILY ZONES (Smart Grid)", m_accent_color, 9, "Arial Bold");
   CreateRect("TableBG", left_x, 90, half_width, 110, C'5,5,15', true, C'45,45,60');

   // Table Headers
   CreateLabel("H_Z", left_x + 10, 100, "ZONE", clrGray, 7);
   CreateLabel("H_P", left_x + 85, 100, "PRICE", clrGray, 7);
   CreateLabel("H_D", left_x + 150, 100, "DIST", clrGray, 7);

   // Table Rows (5 rows)
   for(int i = 0; i < 5; i++)
   {
      string id = IntegerToString(i);
      int ry = 115 + (i * 18);
      CreateLabel("L_N_" + id, left_x + 10, ry, "--", clrWhite, 8);
      CreateLabel("L_P_" + id, left_x + 85, ry, "0.00", m_text_color, 8);
      CreateLabel("L_D_" + id, left_x + 150, ry, "0 pts", clrGray, 8);
   }

   // 4. Strategy Signal (Left Panel - Bottom)
   CreateLabel("LblSig", left_x + pad, 215, "STRATEGY SIGNAL", m_text_color, 9, "Arial Bold");
   CreateRect("InfoBG", left_x, 230, half_width, 140, C'5,5,15');

   CreateLabel("Trend_T", left_x + 10, 240, "Trend:", clrGold, 8);
   CreateLabel("Trend_V", left_x + 50, 240, "--", clrGray, 8, "Arial Bold");

   // EMA Distance Labels (M15 and H1)
   CreateLabel("EMA_M15", left_x + 10, 255, "M15: --/--", m_label_color, 8);
   CreateLabel("EMA_H1", left_x + 10, 270, "H1: --/--", m_label_color, 8);

   // Advisor: Natural language recommendation
   CreateLabel("Adv_T", left_x + 10, 285, "Advisor:", m_accent_color, 9, "Arial Bold");
   CreateLabel("Adv_V", left_x + 10, 300, "Scanning market...", clrCyan, 8);
   CreateLabel("Adv_V2", left_x + 10, 315, "", clrCyan, 8);

   CreateLabel("PA_T", left_x + 10, 335, "PA Signal:", clrGold, 8);
   CreateLabel("PA_V", left_x + 75, 335, "NONE", clrGray, 8);

   CreateLabel("Risk_T", left_x + 10, 355, "Rec. SL/TP:", clrGold, 8);
   CreateLabel("Risk_V", left_x + 75, 355, "-- / --", clrWhite, 8);

   CreateLabel("Ver", left_x + half_width - pad, 360, "v4.0", clrGray, 7);

   // ============================================
   // RIGHT PANEL (50%)
   // ============================================

   // 5. Execution Section (Right Panel - Top)
   CreateLabel("LblCtrl", right_x + pad, 15, "EXECUTION", m_text_color, 9, "Arial Bold");
   CreateLabel("LblPrice", right_x + half_width - pad, 15, "0.00000", m_header_color, 9, "Arial Bold", "right");
   
   CreateLabel("LblRisk", right_x + pad, 35, "Risk %", clrGray, 8);
   CreateEdit("EditRisk", right_x + half_width - pad - 25, 32, 30, 18, "1.0");

   CreateButton("BtnBuy", right_x + pad, 60, (half_width - 30) / 2, 35, "BUY", m_buy_color);
   CreateButton("BtnSell", right_x + pad + (half_width - 30) / 2 + 10, 60, (half_width - 30) / 2, 35, "SELL", m_sell_color);

   // Confirm Button (Pending recommendation)
   CreateButton("BtnConfirm", right_x + pad, 105, half_width - 20, 30, "NO SIGNAL", C'50,50,60', C'100,100,100');

   // 6. Auto Strategy Options (Right Panel - Below Confirm)
   int stratY = 150;
   CreateLabel("LblStratTitle", right_x + pad, stratY, "AUTO STRATEGY", m_text_color, 9, "Arial Bold");
   
   // Auto Mode Toggle (Next to title)
   CreateButton("BtnMode", right_x + half_width - 55, stratY - 5, 45, 22, "OFF", clrGray, clrWhite);

   // Section Box
   CreateRect("StratBG", right_x, stratY + 25, half_width, 85, C'5,5,15', true, C'45,45,60');
   
   int chkW = 60;
   CreateButton("BtnStratArrow", right_x + 10, stratY + 35, 15, 15, "", clrGray);
   CreateLabel("L_Arrow", right_x + 30, stratY + 35, "Arrow", clrCyan, 8, "Arial Bold");
   
   CreateButton("BtnStratRev", right_x + 80, stratY + 35, 15, 15, "", clrGray);
   CreateLabel("L_Rev", right_x + 100, stratY + 35, "Rev", clrCyan, 8, "Arial Bold");
   
   CreateButton("BtnStratBreak", right_x + 150, stratY + 35, 15, 15, "", clrGray);
   CreateLabel("L_Break", right_x + 170, stratY + 35, "Break", clrCyan, 8, "Arial Bold");

   // Last Trade Label
   CreateLabel("LblLastTrade", right_x + 10, stratY + 65, "Last: ---", C'80,80,80', 7);

   // 7. Active Orders Section
   int orderY = 250;
   CreateLabel("LblAct", right_x + pad, orderY, "ACTIVE ORDERS (0)", clrLime, 9, "Arial Bold");
   CreateButton("BtnCloseAll", right_x + half_width - 75, orderY - 2, 65, 18, "CLOSE ALL", m_sell_color, clrWhite);
   
   // Empty list placeholder or area
   CreateRect("OrderListBG", right_x, orderY + 20, half_width, 100, C'5,5,15');

   UpdateAccountInfo();
   ChartRedraw(m_chart_id);
}

//+------------------------------------------------------------------+
//| Update Trading Mode                                              |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateTradingMode(int mode)
{
   // mode 0 = AUTO OFF (manual only), mode 1 = AUTO ON (manual + auto)
   string text = (mode == 0) ? "AUTO: OFF" : "AUTO: ON";
   color bg = (mode == 0) ? clrGray : m_buy_color;   // Gray when OFF, Green when ON
   color txt = clrWhite; // Always White for better contrast
   
   ObjectSetString(m_chart_id, m_prefix+"BtnMode", OBJPROP_TEXT, text);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnMode", OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(m_chart_id, m_prefix+"BtnMode", OBJPROP_COLOR, txt);
   Print("DEBUG: UpdateTradingMode called with mode=", mode, " -> ", text);
   ChartRedraw(m_chart_id);
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
   
   ChartRedraw(m_chart_id);
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
   ChartRedraw(m_chart_id);
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
      ObjectSetString(m_chart_id, m_prefix+"LblStat", OBJPROP_TEXT, "RUN TIME");
      ObjectSetInteger(m_chart_id, m_prefix+"LblStat", OBJPROP_COLOR, clrLime);
   } else {
      ObjectSetString(m_chart_id, m_prefix+"LblStat", OBJPROP_TEXT, "SIDEWAY");
      ObjectSetInteger(m_chart_id, m_prefix+"LblStat", OBJPROP_COLOR, clrGray);
   }
}

void CDashboardPanel::UpdateStrategyInfo(string ema_m15, string ema_h1, string pa_sig, string risk_rec)
{
   string nameM15 = m_prefix+"EMA_M15";
   if(ObjectFind(m_chart_id, nameM15) < 0) {
      Print("ERROR: Object ", nameM15, " not found!");
      // Attempt to force recreate if missing? No, just log for now.
   }
   
   // Toggle blink state
   m_blink_state = !m_blink_state;
   
   // Correctly update the labels with the calculated strategy info
   ObjectSetString(m_chart_id, nameM15, OBJPROP_TEXT, "M15 (100/200): " + ema_m15);
   ObjectSetString(m_chart_id, m_prefix+"EMA_H1", OBJPROP_TEXT, "H1 (100/200): " + ema_h1);
   
   ObjectSetString(m_chart_id, m_prefix+"PA_V", OBJPROP_TEXT, pa_sig);
   
   color pc = clrGray;
   if(StringFind(pa_sig, "BUY") >= 0)
      pc = m_blink_state ? clrLime : m_bg_color; // Blink Green
   else if(StringFind(pa_sig, "SELL") >= 0)
      pc = m_blink_state ? clrRed : m_bg_color; // Blink Red
      
   ObjectSetInteger(m_chart_id, m_prefix+"PA_V", OBJPROP_COLOR, pc);
   
   ObjectSetString(m_chart_id, m_prefix+"Risk_V", OBJPROP_TEXT, risk_rec);
   
   ChartRedraw(m_chart_id); // Force redraw
}

void CDashboardPanel::UpdateAccountInfo()
{
   ObjectSetString(m_chart_id, m_prefix+"Balance", OBJPROP_TEXT, StringFormat("$%.2f", AccountInfoDouble(ACCOUNT_BALANCE)));
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

void CDashboardPanel::CreateButton(const string name, int x, int ry, int width, int height, const string text, color clr, color txt_clr)
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
   ObjectSetInteger(m_chart_id, n, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(m_chart_id, n, OBJPROP_ZORDER, 10); // Ensure button is on top
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
   ChartRedraw(m_chart_id);
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
   ObjectSetString(m_chart_id, m_prefix+"LblStat", OBJPROP_TEXT, statusText);
   ObjectSetInteger(m_chart_id, m_prefix+"LblStat", OBJPROP_COLOR, statusColor);
   ChartRedraw(m_chart_id);
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

   ChartRedraw(m_chart_id);
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
   ChartRedraw(m_chart_id);
}