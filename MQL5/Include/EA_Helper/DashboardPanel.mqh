//+------------------------------------------------------------------+
//|                                                DashboardPanel.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "4.00"

#include <EA_Helper/Definitions.mqh>

struct PanelObject
{
   string name;
   int rel_x;
   int rel_y;
};

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
   
   // Dragging State
   PanelObject       m_objects[];
   bool              m_is_dragging;
   int               m_drag_offset_x;
   int               m_drag_offset_y;

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

   void RegisterObject(const string name, int x, int ry);
   void MovePanel(int x, int y);

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

   void Init(long chart_id);
   void CreatePanel();
   void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   
   void UpdatePrice(double price);
   void UpdateSessionInfo(string session_name, string countdown, bool is_gold_time);
   void UpdateWidwaZones(double d1_open);
   void UpdateStrategyInfo(string reversal_alert, bool rev_valid, string breakout_alert, bool brk_valid, string pa_sig);
   void UpdateTrendStrength(string strengthText, color strengthColor);
   void UpdateZoneStatus(int zoneStatus);  // 0=none, 1=buy1, 2=buy2, 3=sell1, 4=sell2
   void UpdateAdvisor(string message);
   void UpdateLastAutoTrade(string strategy, string direction, double price);
   void UpdateActiveOrders(int count, long &tickets[], double &prices[], double &profits[], double &lots[], int &types[], double total_profit);

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
   m_panel_height = 610;  // Increased for uniform spacing and headers
   m_blink_state = false;

   m_bg_color = C'35,35,45';      // Dark Grey Background
   m_header_color = C'0,191,255'; // Deep Sky Blue
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
   ArrayResize(m_objects, 0); // Clear object registry



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



      CreateLabel("Title", left_x + pad, 15, "DJAY Smart Assistant", C'255,223,0', 11, "Arial Bold");



      CreateLabel("LblSesTitle", left_x + pad, 35, "SESSION:", m_text_color, 9);



      CreateLabel("LblSesValue", left_x + pad + 55, 35, "--", clrGray, 9, "Arial");



      CreateLabel("LblTime", left_x + half_width - pad, 35, "M5: --:--", clrGray, 9, "Arial", "right");

   

      

         CreateLabel("LblRunTimeTitle", left_x + pad, 48, "STATUS:", m_text_color, 9);

   

      

         CreateLabel("LblRunTime", left_x + pad + 55, 48, "SIDEWAY", clrGray, 9, "Arial");

   

      

         

   

      

         CreateLabel("LblZoneStatTitle", left_x + pad, 61, "ZONE:", m_text_color, 9);

   

      

         CreateLabel("LblZoneStat", left_x + pad + 55, 61, "NEUTRAL", clrGray, 9, "Arial");



   // 2. Daily Zones Table (Panel A)

   CreateLabel("LblZ", left_x + pad, 80, "DAILY ZONES (Smart Grid)", m_header_color, 10, "Arial Bold");

   CreateRect("TableBG", left_x, 100, half_width, 200, C'5,5,15', true, C'45,45,60');



   // Table Headers

   CreateLabel("H_Z", left_x + 10, 110, "ZONE", clrGray, 8);

   CreateLabel("H_P", left_x + 85, 110, "PRICE", clrGray, 8);

   CreateLabel("H_D", left_x + 150, 110, "DIST", clrGray, 8);



   for(int i = 0; i < 10; i++)

   {

      string id = IntegerToString(i);

      int ry = 125 + (i * 18);

      CreateLabel("L_N_" + id, left_x + 10, ry, "--", clrWhite, 9);

      CreateLabel("L_P_" + id, left_x + 85, ry, "0.00", m_text_color, 9);

      CreateLabel("L_D_" + id, left_x + 150, ry, "0 pts", clrGray, 9);

   }

   // [Strategy Signal Section moved to Panel B]

   // ============================================

   // RIGHT PANEL (Panel B)

   // ============================================



   // 4. Execution Section (Panel B - Top)

   CreateLabel("LblCtrl", right_x + pad, 15, "EXECUTION", m_header_color, 10, "Arial Bold");

   CreateLabel("LblPrice", right_x + half_width - pad, 15, "0.00000", C'255,223,0', 10, "Arial Bold", "right");



   CreateLabel("LblRisk", right_x + pad, 38, "Risk %", clrGray, 9);

   CreateEdit("EditRisk", right_x + half_width - pad - 25, 35, 30, 18, "1.0");



   int btnW = (half_width - 30) / 2;

   CreateButton("BtnBuy", right_x + 10, 62, btnW, 38, "BUY", m_buy_color, clrWhite, 9);

   CreateButton("BtnSell", right_x + half_width - 10 - btnW, 62, btnW, 38, "SELL", m_sell_color, clrWhite, 9);



   // 5. Auto Strategy Options (Panel B)

   int stratY = 115;

   CreateLabel("LblStratTitle", right_x + pad, stratY, "AUTO STRATEGY", m_header_color, 10, "Arial Bold");

   CreateButton("BtnMode", right_x + half_width - 55, stratY - 5, 45, 22, "OFF", clrGray, clrWhite, 9);



   CreateRect("StratBG", right_x, 135, half_width, 65, C'5,5,15', true, C'45,45,60');



   CreateButton("BtnStratArrow", right_x + 10, 148, 15, 15, "", clrGray);

   CreateLabel("L_Arrow", right_x + 30, 148, "Arrow", clrCyan, 9, "Arial Bold");



   CreateButton("BtnStratRev", right_x + 85, 148, 15, 15, "", clrGray);

   CreateLabel("L_Rev", right_x + 105, 148, "Rev", clrCyan, 9, "Arial Bold");



   CreateButton("BtnStratBreak", right_x + 155, 148, 15, 15, "", clrGray);

   CreateLabel("L_Break", right_x + 175, 148, "Break", clrCyan, 9, "Arial Bold");



   CreateLabel("LblLastAuto", right_x + 10, 180, "Last: ---", C'80,80,80', 8);

   // 3. Strategy Signal (Moved to Panel B)
   CreateLabel("LblSig", right_x + pad, 215, "STRATEGY SIGNAL", m_header_color, 10, "Arial Bold");
   CreateRect("InfoBG", right_x, 235, half_width, 105, C'5,5,15');

   CreateLabel("Trend_T", right_x + 10, 247, "Trend:", m_header_color, 9);
   CreateLabel("Trend_V", right_x + 50, 247, "--", clrGray, 9, "Arial Bold");

   CreateLabel("PA_T", right_x + 10, 263, "PA Signal:", m_header_color, 9);
   CreateLabel("PA_V", right_x + 75, 263, "NONE", clrGray, 9);

   CreateRect("Sep1", right_x + 8, 280, half_width - 16, 1, C'60,60,70');

   CreateLabel("Adv_T", right_x + 10, 285, "Advisor:", m_accent_color, 10, "Arial Bold");
   CreateLabel("Adv_V", right_x + 10, 300, "Scanning market...", clrCyan, 9);
   CreateLabel("Adv_V2", right_x + 10, 315, "", clrCyan, 9);

   CreateLabel("Ver", right_x + half_width - pad, 330, "v4.1", clrGray, 8);

   // ============================================

   // LOWER SECTIONS (Full Width)

   // ============================================



   // 6. NEW SECTION: PENDING ALERTS

   int pendingY = 370;

   CreateLabel("LblPending", x + pad, pendingY, "PENDING ALERTS", m_header_color, 10, "Arial Bold");

   CreateButton("BtnConfirm", x + m_panel_width - 130, pendingY - 2, 120, 20, "NO SIGNAL", C'50,50,60', C'100,100,100', 8);

   

   CreateRect("PendingBG", x + 5, 390, m_panel_width - 20, 65, C'5,5,15', true, C'45,45,60');

   

   CreateButton("BtnRev", x + 15, 400, m_panel_width - 40, 20, "NO REVERSAL SETUP", clrGray, clrWhite, 8);

   CreateButton("BtnBrk", x + 15, 425, m_panel_width - 40, 20, "NO BREAKOUT SETUP", clrGray, clrWhite, 8);



   // 7. ACTIVE ORDERS Section

   int orderY = 470;

   CreateLabel("LblAct", x + pad, orderY, "ACTIVE ORDERS (0)", m_header_color, 10, "Arial Bold");

   CreateLabel("LblBalance", x + 150, orderY, "Balance: $--", clrWhite, 9, "Arial Bold");

   CreateLabel("LblTotalProfit", x + 280, orderY, "Profit: $0.00", clrGray, 9, "Arial Bold");

   CreateButton("BtnCloseAll", x + m_panel_width - 75, orderY - 2, 65, 18, "CLOSE ALL", m_sell_color, clrWhite, 8);



   CreateRect("OrderListBG", x + 5, 490, m_panel_width - 20, 115, C'5,5,15', true, C'45,45,60');

   for(int i=0; i<4; i++)

   {

      string sid = IntegerToString(i);

      int rowY = 508 + (i * 26);

      CreateLabel("ActOrder_L_"+sid, -200, rowY, "", clrCyan, 9);

      CreateLabel("ActOrder_M_"+sid, -200, rowY, "", clrWhite, 9);

      CreateLabel("ActOrder_R_"+sid, -200, rowY, "", clrWhite, 9);

            CreateButton("BtnCloseOrder_"+sid, -100, rowY - 3, 35, 18, "X", C'80,80,80', clrWhite, 9);

         }

      

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
   int best_idx[10]; double best_dist[10];
   for(int k=0; k<10; k++) { best_dist[k] = 999999; best_idx[k] = -1; }
   
   for(int i=0; i<count; i++)
   {
      double dist = MathAbs(current - levels[i]);
      for(int k=0; k<10; k++)
      {
         if(dist < best_dist[k])
         {
            for(int j=9; j>k; j--) { best_dist[j] = best_dist[j-1]; best_idx[j] = best_idx[j-1]; }
            best_dist[k] = dist; best_idx[k] = i; break;
         }
      }
   }
   
   // Sort by Price DESC
   for(int i=0; i<9; i++)
      for(int j=0; j<9-i; j++)
         if(best_idx[j] != -1 && best_idx[j+1] != -1 && levels[best_idx[j]] < levels[best_idx[j+1]])
         { int t = best_idx[j]; best_idx[j] = best_idx[j+1]; best_idx[j+1] = t; }

   for(int i=0; i<10; i++)
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
   RegisterObject(name, x, ry);
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
   RegisterObject(name, x, ry);
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
   RegisterObject(name, x, ry);
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
   RegisterObject(name, x, ry);
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
void CDashboardPanel::UpdateActiveOrders(int count, long &tickets[], double &prices[], double &profits[], double &lots[], int &types[], double total_profit)
{
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

   // Calculate button positions
   int x = m_base_x;

   // Update slots and store tickets
   for(int i = 0; i < 4; i++)
   {
      string sid = IntegerToString(i);

      if(i < count)
      {
         m_order_tickets[i] = tickets[i];
         
         string typeStr = (types[i] == 0) ? "BUY" : "SELL"; // 0=Buy
         double profitPct = (balance > 0) ? (profits[i] / balance) * 100.0 : 0;
         color pColor = (profits[i] >= 0) ? clrLime : clrOrange;

         // 1. Info Label (Cyan) - Increased spacing
         string infoText = StringFormat("#%d      %s      Lots %.2f      @%.2f", tickets[i], typeStr, lots[i], prices[i]);
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_TEXT, infoText);
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_COLOR, clrCyan);
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_XDISTANCE, x + 10);

         // 2. Profit Label ($)
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_TEXT, StringFormat("$%.2f", profits[i]));
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_COLOR, pColor);
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_XDISTANCE, x + 290);

         // 3. Percent Label (%)
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_TEXT, StringFormat("(%.2f%%)", profitPct));
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_COLOR, pColor);
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_XDISTANCE, x + 380);

         // Show close button
         int btnX = x + m_panel_width - 45;
         ObjectSetInteger(m_chart_id, m_prefix+"BtnCloseOrder_"+sid, OBJPROP_XDISTANCE, btnX);
         ObjectSetInteger(m_chart_id, m_prefix+"BtnCloseOrder_"+sid, OBJPROP_STATE, false);
      }
      else
      {
         // Clear slots and HIDE objects
         ObjectSetString(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_TEXT, "");
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_L_"+sid, OBJPROP_XDISTANCE, -200);

         ObjectSetString(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_TEXT, "");
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_M_"+sid, OBJPROP_XDISTANCE, -200);

         ObjectSetString(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_TEXT, "");
         ObjectSetInteger(m_chart_id, m_prefix+"ActOrder_R_"+sid, OBJPROP_XDISTANCE, -200);
         
         m_order_tickets[i] = 0;

         // Hide close button
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

//+------------------------------------------------------------------+
//| Register Object for Dragging                                     |
//+------------------------------------------------------------------+
void CDashboardPanel::RegisterObject(const string name, int x, int ry)
{
   int size = ArraySize(m_objects);
   ArrayResize(m_objects, size + 1);
   m_objects[size].name = m_prefix + name;
   m_objects[size].rel_x = x - m_base_x;
   m_objects[size].rel_y = Y(ry) - m_base_y;
}

//+------------------------------------------------------------------+
//| Move Panel to New Coordinates                                    |
//+------------------------------------------------------------------+
void CDashboardPanel::MovePanel(int x, int y)
{
   m_base_x = x;
   m_base_y = y;
   
   int total = ArraySize(m_objects);
   for(int i = 0; i < total; i++)
   {
      ObjectSetInteger(m_chart_id, m_objects[i].name, OBJPROP_XDISTANCE, m_base_x + m_objects[i].rel_x);
      ObjectSetInteger(m_chart_id, m_objects[i].name, OBJPROP_YDISTANCE, m_base_y + m_objects[i].rel_y);
   }
   
   ChartRedraw(m_chart_id);
}

//+------------------------------------------------------------------+
//| Handle Chart Events (Dragging)                                   |
//+------------------------------------------------------------------+
void CDashboardPanel::OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      int x = (int)lparam;
      int y = (int)dparam;
      int state = (int)StringToInteger(sparam); // Mouse state mask
      
      // Mouse Left Button Down (1)
      if(state == 1)
      {
         if(!m_is_dragging)
         {
            // Check collision with Header area (Top 40 pixels of MainBG)
            long bgX = ObjectGetInteger(m_chart_id, m_prefix+"MainBG", OBJPROP_XDISTANCE);
            long bgY = ObjectGetInteger(m_chart_id, m_prefix+"MainBG", OBJPROP_YDISTANCE);
            long bgW = ObjectGetInteger(m_chart_id, m_prefix+"MainBG", OBJPROP_XSIZE);
            long bgH = ObjectGetInteger(m_chart_id, m_prefix+"MainBG", OBJPROP_YSIZE);
            
            long chartH = ChartGetInteger(m_chart_id, CHART_HEIGHT_IN_PIXELS);
            long panelTopY = chartH - (bgY + bgH); // Screen Y of panel top
            
            // Check if mouse is within panel horizontal bounds
            if(x >= bgX && x <= bgX + bgW)
            {
               // Check vertical - Header is top 40px
               if(y >= panelTopY && y <= panelTopY + 40)
               {
                  m_is_dragging = true;
                  m_drag_offset_x = x - (int)bgX;
                  m_drag_offset_y = (int)(chartH - y - bgY);
                  
                  ChartSetInteger(m_chart_id, CHART_MOUSE_SCROLL, false);
               }
            }
         }
         else
         {
            // Dragging - Move MainBG
            long chartH = ChartGetInteger(m_chart_id, CHART_HEIGHT_IN_PIXELS);
            int newX = x - m_drag_offset_x;
            int newY = (int)(chartH - y - m_drag_offset_y);
            
            // Safety limits
            if(newX < 0) newX = 0;
            if(newY < 0) newY = 0;
            
            ObjectSetInteger(m_chart_id, m_prefix+"MainBG", OBJPROP_XDISTANCE, newX);
            ObjectSetInteger(m_chart_id, m_prefix+"MainBG", OBJPROP_YDISTANCE, newY);
            
            ChartRedraw(m_chart_id);
         }
      }
      else if(state == 0 && m_is_dragging) // Mouse Up
      {
         m_is_dragging = false;
         
         long bgX = ObjectGetInteger(m_chart_id, m_prefix+"MainBG", OBJPROP_XDISTANCE);
         long bgY = ObjectGetInteger(m_chart_id, m_prefix+"MainBG", OBJPROP_YDISTANCE);
         
         MovePanel((int)bgX, (int)bgY);
         ChartSetInteger(m_chart_id, CHART_MOUSE_SCROLL, true);
      }
   }
}