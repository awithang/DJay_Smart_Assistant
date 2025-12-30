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

   color             m_bg_color;       
   color             m_header_color;
   color             m_text_color;     
   color             m_label_color;
   color             m_buy_color;
   color             m_sell_color;
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
   void UpdateSessionInfo(string session_name, string countdown, bool is_gold_time);
   void UpdateWidwaZones(double d1_open);
   void UpdateStrategyInfo(string ema_m15, string ema_h1, string pa_sig, string risk_rec);
   void UpdateTrendStrength(string strengthText, color strengthColor);
   void UpdateZoneStatus(int zoneStatus);  // 0=none, 1=buy1, 2=buy2, 3=sell1, 4=sell2

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

   m_bg_color = C'26,26,46';      // Dark navy background
   m_header_color = C'255,215,0'; // Gold
   m_text_color = clrWhite;
   m_label_color = C'180,180,180';
   m_buy_color = C'46,204,113';
   m_sell_color = C'231,76,60';
   m_accent_color = C'52,152,219';
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
   CreateRect("MainBG", x, 0, m_panel_width, m_panel_height, m_bg_color, true, C'60,60,80');

   // ============================================
   // LEFT PANEL (50%)
   // ============================================

   // 1. Header Section (Left Panel)
   CreateLabel("Title", left_x + pad, 15, "DJAY Smart Assistant", m_header_color, 10, "Arial Bold");
   CreateLabel("Balance", left_x + half_width - pad, 15, "$--", m_text_color, 9, "Arial Bold", "right");

   // 2. Market Status (Left Panel)
   CreateLabel("LblSes", left_x + pad, 35, "SESSION: --", m_text_color, 8);
   CreateLabel("LblTime", left_x + pad, 50, "M5: --:--", clrGray, 8);
   CreateLabel("LblStat", left_x + half_width - pad, 42, "SIDEWAY", clrGray, 9, "Arial Bold", "right");

   // 3. Daily Zones Table (Left Panel)
   CreateLabel("LblZ", left_x + pad, 75, "DAILY ZONES (Smart Grid)", C'100,149,237', 9, "Arial Bold");
   CreateRect("TableBG", left_x, 90, half_width, 110, C'20,20,35', true, C'60,60,80');

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
   CreateRect("InfoBG", left_x, 230, half_width, 140, C'20,20,35');

   CreateLabel("Trend_T", left_x + 10, 240, "Trend:", clrGold, 8);
   CreateLabel("Trend_V", left_x + 50, 240, "--", clrGray, 8, "Arial Bold");

   CreateLabel("EMA_T", left_x + 10, 255, "EMA Distance:", clrGold, 8);
   CreateLabel("EMA_M15", left_x + 10, 270, "M15 (100/200): --", clrWhite, 8);
   CreateLabel("EMA_H1", left_x + 10, 285, "H1 (100/200): --", clrWhite, 8);

   CreateLabel("PA_T", left_x + 10, 305, "PA Signal:", clrGold, 8);
   CreateLabel("PA_V", left_x + 75, 305, "NONE", clrGray, 8);

   CreateLabel("Risk_T", left_x + 10, 325, "Rec. SL/TP:", clrGold, 8);
   CreateLabel("Risk_V", left_x + 75, 325, "-- / --", clrWhite, 8);

   CreateLabel("Ver", left_x + half_width - pad, 360, "v4.0", clrGray, 7);

   // ============================================
   // RIGHT PANEL (50%)
   // ============================================

   // 5. Execution Section (Right Panel - Top)
   CreateLabel("LblCtrl", right_x + pad, 15, "EXECUTION", m_text_color, 9, "Arial Bold");
   CreateLabel("LblRisk", right_x + pad, 35, "Risk %", clrGray, 8);
   CreateEdit("EditRisk", right_x + half_width - pad - 25, 32, 30, 18, "1.0");

   CreateButton("BtnBuy", right_x + pad, 60, (half_width - 30) / 2, 35, "BUY", m_buy_color);
   CreateButton("BtnSell", right_x + pad + (half_width - 30) / 2 + 10, 60, (half_width - 30) / 2, 35, "SELL", m_sell_color);

   // Note: Space below Execution section reserved for future features

   UpdateAccountInfo();
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
      color c = (levels[idx] > current) ? m_sell_color : m_buy_color;
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
   
   // Correctly update the labels with the calculated strategy info
   ObjectSetString(m_chart_id, nameM15, OBJPROP_TEXT, "M15 (100/200): " + ema_m15);
   ObjectSetString(m_chart_id, m_prefix+"EMA_H1", OBJPROP_TEXT, "H1 (100/200): " + ema_h1);
   
   ObjectSetString(m_chart_id, m_prefix+"PA_V", OBJPROP_TEXT, pa_sig);
   color pc = (StringFind(pa_sig, "BUY")>=0) ? clrLime : (StringFind(pa_sig, "SELL")>=0 ? clrRed : clrGray);
   ObjectSetInteger(m_chart_id, m_prefix+"PA_V", OBJPROP_COLOR, pc);
   
   ObjectSetString(m_chart_id, m_prefix+"Risk_V", OBJPROP_TEXT, risk_rec);
   
   ChartRedraw(m_chart_id); // Force redraw
}

void CDashboardPanel::UpdateAccountInfo()
{
   ObjectSetString(m_chart_id, m_prefix+"Balance", OBJPROP_TEXT, StringFormat("$%.2f", AccountInfoDouble(ACCOUNT_BALANCE)));
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
   ObjectSetInteger(m_chart_id, n, OBJPROP_BORDER_TYPE, border ? BORDER_FLAT : BORDER_SUNKEN);
   if(border) ObjectSetInteger(m_chart_id, n, OBJPROP_BORDER_COLOR, border_color);
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
         statusColor = m_sell_color;
         break;
      case 4: // ZONE_STATUS_IN_SELL2
         statusText = "SELL ZONE 2";
         statusColor = m_sell_color;
         break;
   }

   // Update the status label in the header area
   ObjectSetString(m_chart_id, m_prefix+"LblStat", OBJPROP_TEXT, statusText);
   ObjectSetInteger(m_chart_id, m_prefix+"LblStat", OBJPROP_COLOR, statusColor);
   ChartRedraw(m_chart_id);
}