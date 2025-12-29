//+------------------------------------------------------------------+
//|                                                DashboardPanel.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"
#property strict

#include <EA_Helper/Definitions.mqh>
#include <ChartObjects/ChartObjectsTxtControls.mqh>
#include <ChartObjects/ChartObjectsControls.mqh>

//+------------------------------------------------------------------+
//| Dashboard Panel Class - UI Management                            |
//+------------------------------------------------------------------+
class CDashboardPanel
{
private:
   long              m_chart_id;       // Chart ID
   int               m_corner;         // Panel corner position
   color             m_bg_color;       // Background color
   color             m_text_color;     // Text color
   color             m_signal_color;   // Signal color

   // UI Elements
   CChartObjectLabel m_lbl_title;      // Title label
   CChartObjectLabel m_lbl_session;    // Session label
   CChartObjectLabel m_lbl_signal;     // Signal label
   CChartObjectLabel m_lbl_price;      // Current price label
   CChartObjectLabel m_lbl_profit;     // Profit label

   CChartObjectEdit  m_edit_risk;      // Risk percentage input
   CChartObjectButton m_btn_buy;       // Buy button
   CChartObjectButton m_btn_sell;      // Sell button

   // Zone lines
   CChartObjectHLine m_hline_buy1;     // Buy Zone 1 line
   CChartObjectHLine m_hline_buy2;     // Buy Zone 2 line
   CChartObjectHLine m_hline_sell1;    // Sell Zone 1 line
   CChartObjectHLine m_hline_sell2;    // Sell Zone 2 line

public:
   //--- Constructor/Destructor
   CDashboardPanel();
   ~CDashboardPanel();

   //--- Initialization
   void Init(long chart_id);
   void CreatePanel();
   void CreateZoneLines();
   void SetColors(color bg, color txt, color signal);

   //--- Value Updates
   void UpdateSession(ENUM_MARKET_SESSION session);
   void UpdateSignal(ENUM_SIGNAL_TYPE signal, string signal_text);
   void UpdatePrice(double bid, double ask);
   void UpdateProfit(double profit);
   void UpdateValues(double price, double profit, string signal_text);

   //--- Zone Drawing
   void DrawZones(double buy1, double buy2, double sell1, double sell2);
   void UpdateZones(double d1_open, int offset1, int offset2);

   //--- Event Handling
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);

   //--- Interactive UI Methods
   double GetRiskPercent();              // Get risk percentage from edit box
   bool IsBuyButtonClicked(string sparam);  // Check if buy button was clicked
   bool IsSellButtonClicked(string sparam); // Check if sell button was clicked
   void SetRiskPercent(double risk);     // Set risk percentage value

   //--- Cleanup
   void Destroy();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDashboardPanel::CDashboardPanel()
{
   m_chart_id = 0;
   m_corner = CORNER_LEFT_UPPER;
   m_bg_color = clrNONE;
   m_text_color = clrWhite;
   m_signal_color = clrLime;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDashboardPanel::~CDashboardPanel()
{
   Destroy();
}

//+------------------------------------------------------------------+
//| Initialize panel with chart ID                                   |
//+------------------------------------------------------------------+
void CDashboardPanel::Init(long chart_id)
{
   m_chart_id = chart_id;
   CreatePanel();
}

//+------------------------------------------------------------------+
//| Create panel UI elements                                        |
//+------------------------------------------------------------------+
void CDashboardPanel::CreatePanel()
{
   // Create Title Label
   m_lbl_title.Create(0, "EA_Helper_Title", 0, 20, 20);
   m_lbl_title.Description("WidwaPa Assistant");
   m_lbl_title.Color(clrGold);
   m_lbl_title.FontSize(14);
   m_lbl_title.Font("Arial Bold");

   // Create Session Label
   m_lbl_session.Create(0, "EA_Helper_Session", 0, 20, 45);
   m_lbl_session.Description("Session: --");
   m_lbl_session.Color(m_text_color);
   m_lbl_session.FontSize(10);

   // Create Signal Label
   m_lbl_signal.Create(0, "EA_Helper_Signal", 0, 20, 65);
   m_lbl_signal.Description("Signal: WAITING...");
   m_lbl_signal.Color(clrGray);
   m_lbl_signal.FontSize(10);

   // Create Price Label
   m_lbl_price.Create(0, "EA_Helper_Price", 0, 20, 85);
   m_lbl_price.Description("Price: --");
   m_lbl_price.Color(m_text_color);
   m_lbl_price.FontSize(10);

   // Create Profit Label
   m_lbl_profit.Create(0, "EA_Helper_Profit", 0, 20, 105);
   m_lbl_profit.Description("Profit: $0.00");
   m_lbl_profit.Color(m_text_color);
   m_lbl_profit.FontSize(10);

   // Create Risk Edit Box
   m_edit_risk.Create(0, "EA_Helper_EditRisk", 0, 20, 130, 60, 20);
   m_edit_risk.Description("3.0");  // Default 3% risk
   m_edit_risk.Color(clrWhite);
   m_edit_risk.BackColor(clrNavy);
   m_edit_risk.FontSize(10);
   m_edit_risk.Tooltip("Risk % (1-10): Lot size auto-calculated based on this");

   // Create Buy/Sell buttons
   m_btn_buy.Create(0, "EA_Helper_BtnBuy", 0, 90, 130, 80, 25);
   m_btn_buy.Description("BUY");
   m_btn_buy.Color(clrForestGreen);
   m_btn_buy.FontSize(10);
   m_btn_buy.Locked(false);  // Enable button
   m_btn_buy.Tooltip("Execute BUY order with auto-calculated lot size");

   m_btn_sell.Create(0, "EA_Helper_BtnSell", 0, 180, 130, 80, 25);
   m_btn_sell.Description("SELL");
   m_btn_sell.Color(clrCrimson);
   m_btn_sell.FontSize(10);
   m_btn_sell.Locked(false);  // Enable button
   m_btn_sell.Tooltip("Execute SELL order with auto-calculated lot size");

   // Create Zone Horizontal Lines
   CreateZoneLines();
}

//+------------------------------------------------------------------+
//| Create zone horizontal lines                                     |
//+------------------------------------------------------------------+
void CDashboardPanel::CreateZoneLines()
{
   // Buy Zone 1 (Green, Solid)
   m_hline_buy1.Create(0, "EA_Helper_ZoneBuy1", 0, 0, clrLime);
   m_hline_buy1.Style(STYLE_SOLID);
   m_hline_buy1.Width(2);
   m_hline_buy1.Selectable(true);
   m_hline_buy1.Description("Buy Zone 1");

   // Buy Zone 2 (Green, Dashed)
   m_hline_buy2.Create(0, "EA_Helper_ZoneBuy2", 0, 0, clrLime);
   m_hline_buy2.Style(STYLE_DASH);
   m_hline_buy2.Width(1);
   m_hline_buy2.Selectable(true);
   m_hline_buy2.Description("Buy Zone 2");

   // Sell Zone 1 (Red, Solid)
   m_hline_sell1.Create(0, "EA_Helper_ZoneSell1", 0, 0, clrRed);
   m_hline_sell1.Style(STYLE_SOLID);
   m_hline_sell1.Width(2);
   m_hline_sell1.Selectable(true);
   m_hline_sell1.Description("Sell Zone 1");

   // Sell Zone 2 (Red, Dashed)
   m_hline_sell2.Create(0, "EA_Helper_ZoneSell2", 0, 0, clrRed);
   m_hline_sell2.Style(STYLE_DASH);
   m_hline_sell2.Width(1);
   m_hline_sell2.Selectable(true);
   m_hline_sell2.Description("Sell Zone 2");
}

//+------------------------------------------------------------------+
//| Set panel colors                                                 |
//+------------------------------------------------------------------+
void CDashboardPanel::SetColors(color bg, color txt, color signal)
{
   m_bg_color = bg;
   m_text_color = txt;
   m_signal_color = signal;
}

//+------------------------------------------------------------------+
//| Update session display                                           |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateSession(ENUM_MARKET_SESSION session)
{
   string sessionText = "";
   color sessionColor = clrGray;

   switch(session)
   {
      case SESSION_ASIA:
         sessionText = "ASIA";
         sessionColor = clrYellow;
         break;
      case SESSION_EUROPE:
         sessionText = "EUROPE";
         sessionColor = clrOrange;
         break;
      case SESSION_US:
         sessionText = "US";
         sessionColor = clrDodgerBlue;
         break;
      case SESSION_QUIET:
         sessionText = "QUIET";
         sessionColor = clrGray;
         break;
   }

   // Get current time and format it
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   string timeStr = StringFormat("%02d:%02d:%02d", timeStruct.hour, timeStruct.min, timeStruct.sec);

   // Display session and time together
   m_lbl_session.Description("[" + timeStr + "] " + sessionText);
   m_lbl_session.Color(sessionColor);
}

//+------------------------------------------------------------------+
//| Update signal display                                            |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateSignal(ENUM_SIGNAL_TYPE signal, string signal_text)
{
   m_lbl_signal.Description("Signal: " + signal_text);

   // Update signal color based on type
   switch(signal)
   {
      case SIGNAL_BUY_ZONE:
      case SIGNAL_PA_BUY:
      case SIGNAL_EMA_TOUCH_BUY:
         m_lbl_signal.Color(clrLime);
         break;
      case SIGNAL_SELL_ZONE:
      case SIGNAL_PA_SELL:
      case SIGNAL_EMA_TOUCH_SELL:
         m_lbl_signal.Color(clrRed);
         break;
      default:
         m_lbl_signal.Color(clrGray);
         break;
   }
}

//+------------------------------------------------------------------+
//| Update price display                                             |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdatePrice(double bid, double ask)
{
   string priceText = StringFormat("Price: %.5f", bid);
   m_lbl_price.Description(priceText);
}

//+------------------------------------------------------------------+
//| Update profit display                                            |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateProfit(double profit)
{
   string profitText = StringFormat("Profit: $%.2f", profit);
   m_lbl_profit.Description(profitText);

   // Update color based on profit/loss
   if(profit > 0)
      m_lbl_profit.Color(clrLime);
   else if(profit < 0)
      m_lbl_profit.Color(clrRed);
   else
      m_lbl_profit.Color(m_text_color);
}

//+------------------------------------------------------------------+
//| Update multiple values at once                                   |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateValues(double price, double profit, string signal_text)
{
   UpdatePrice(price, price);
   UpdateProfit(profit);
}

//+------------------------------------------------------------------+
//| Draw zone lines on chart                                         |
//+------------------------------------------------------------------+
void CDashboardPanel::DrawZones(double buy1, double buy2, double sell1, double sell2)
{
   // Update Buy Zone 1
   m_hline_buy1.Price(NormalizeDouble(buy1, _Digits));
   m_hline_buy1.Description(StringFormat("Buy Zone 1: %.5f", buy1));

   // Update Buy Zone 2
   m_hline_buy2.Price(NormalizeDouble(buy2, _Digits));
   m_hline_buy2.Description(StringFormat("Buy Zone 2: %.5f", buy2));

   // Update Sell Zone 1
   m_hline_sell1.Price(NormalizeDouble(sell1, _Digits));
   m_hline_sell1.Description(StringFormat("Sell Zone 1: %.5f", sell1));

   // Update Sell Zone 2
   m_hline_sell2.Price(NormalizeDouble(sell2, _Digits));
   m_hline_sell2.Description(StringFormat("Sell Zone 2: %.5f", sell2));
}

//+------------------------------------------------------------------+
//| Update zone lines based on D1 open and offsets                   |
//+------------------------------------------------------------------+
void CDashboardPanel::UpdateZones(double d1_open, int offset1, int offset2)
{
   double point = _Point;

   // Calculate zone levels
   double buy1 = d1_open + (offset1 * point);
   double buy2 = d1_open + (offset2 * point);
   double sell1 = d1_open - (offset1 * point);
   double sell2 = d1_open - (offset2 * point);

   // Draw the zones
   DrawZones(buy1, buy2, sell1, sell2);
}

//+------------------------------------------------------------------+
//| Handle chart events (button clicks)                              |
//+------------------------------------------------------------------+
void CDashboardPanel::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // Event is handled by the main EA OnChartEvent
   // This method is a placeholder for future UI event handling within the panel
}

//+------------------------------------------------------------------+
//| Get risk percentage from edit box                                |
//+------------------------------------------------------------------+
double CDashboardPanel::GetRiskPercent()
{
   string riskText = m_edit_risk.Description();
   double risk = StringToDouble(riskText);

   // Validate risk value (1% to 10%)
   if(risk < 1.0) risk = 1.0;
   if(risk > 10.0) risk = 10.0;

   return risk;
}

//+------------------------------------------------------------------+
//| Check if buy button was clicked                                  |
//+------------------------------------------------------------------+
bool CDashboardPanel::IsBuyButtonClicked(string sparam)
{
   return (sparam == "EA_Helper_BtnBuy");
}

//+------------------------------------------------------------------+
//| Check if sell button was clicked                                 |
//+------------------------------------------------------------------+
bool CDashboardPanel::IsSellButtonClicked(string sparam)
{
   return (sparam == "EA_Helper_BtnSell");
}

//+------------------------------------------------------------------+
//| Set risk percentage value                                        |
//+------------------------------------------------------------------+
void CDashboardPanel::SetRiskPercent(double risk)
{
   // Validate and set risk value
   if(risk < 1.0) risk = 1.0;
   if(risk > 10.0) risk = 10.0;

   m_edit_risk.Description(DoubleToString(risk, 1));
}

//+------------------------------------------------------------------+
//| Destroy panel and cleanup resources                              |
//+------------------------------------------------------------------+
void CDashboardPanel::Destroy()
{
   // Delete UI labels
   m_lbl_title.Delete();
   m_lbl_session.Delete();
   m_lbl_signal.Delete();
   m_lbl_price.Delete();
   m_lbl_profit.Delete();

   // Delete buttons
   m_btn_buy.Delete();
   m_btn_sell.Delete();

   // Delete zone lines
   m_hline_buy1.Delete();
   m_hline_buy2.Delete();
   m_hline_sell1.Delete();
   m_hline_sell2.Delete();
}

//+------------------------------------------------------------------+
