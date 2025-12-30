//+------------------------------------------------------------------+
//|                                                   WidwaPa_Assistant.mq5 |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"
#property description "WidwaPa Trade Assistant - Automated zones, signals, and one-click trading"

#include <EA_Helper/Definitions.mqh>
#include <EA_Helper/SignalEngine.mqh>
#include <EA_Helper/TradeManager.mqh>
#include <EA_Helper/DashboardPanel.mqh>

//--- Input Parameters
input double Input_RiskPercent = 3.0;       // Risk % per trade
input int    Input_SL_Points = 300;         // Stop Loss distance
input int    Input_Zone_Offset1 = 300;      // Zone 1 offset (points)
input int    Input_Zone_Offset2 = 1000;     // Zone 2 offset (points)
input int    Input_MagicNumber = 123456;    // Unique ID for EA trades

//--- Global Objects
CSignalEngine   signalEngine;
CTradeManager   tradeManager;
CDashboardPanel dashboardPanel;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   signalEngine.Init(Input_Zone_Offset1, Input_Zone_Offset2);
   tradeManager.Init(Input_MagicNumber);
   dashboardPanel.Init(0);

   EventSetTimer(1);

   double d1Open = signalEngine.GetD1Open();
   dashboardPanel.UpdateWidwaZones(d1Open);

   Print("WidwaPa Assistant initialized successfully.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   dashboardPanel.Destroy();
   Print("WidwaPa Assistant deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   signalEngine.RefreshData();

   double currentPrice = signalEngine.GetCurrentPrice();
   double d1Open = signalEngine.GetD1Open();

   // Update zones if D1 Open changes (new day)
   static double prevD1Open = 0;
   if(d1Open != prevD1Open)
   {
      dashboardPanel.UpdateWidwaZones(d1Open);
      prevD1Open = d1Open;
   }

   // Update account info on profit change
   static double prevProfit = 0;
   double totalProfit = tradeManager.GetPositionProfit();
   if(MathAbs(totalProfit - prevProfit) > 0.01 || PositionsTotal() > 0)
   {
      dashboardPanel.UpdateAccountInfo();
      prevProfit = totalProfit;
   }

   tradeManager.TrailingStop(Input_SL_Points);

   // Check for PA signals (only on new bar)
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   bool newBar = (currentBarTime != lastBarTime);
   if(newBar)
   {
      // --- 1. Price Action Signals ---
      ENUM_SIGNAL_TYPE paSignal = signalEngine.GetActiveSignal();
      string newSignalText = "";
      
      // Get High/Low of previous bar for arrow placement
      double prevHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
      double prevLow = iLow(_Symbol, PERIOD_CURRENT, 1);
      
      if(paSignal == SIGNAL_PA_BUY)
      {
         CreateSignalArrow(currentBarTime, prevLow - 50*_Point, 233, clrLime, "PA_Buy");
      }
      else if(paSignal == SIGNAL_PA_SELL)
      {
         CreateSignalArrow(currentBarTime, prevHigh + 50*_Point, 234, clrRed, "PA_Sell");
      }
      
      // --- 2. EMA Touch Signals ---
      // Check H1 EMA Touch
      bool emaTouch100 = signalEngine.CheckEMATouch(PERIOD_H1, 100);
      bool emaTouch200 = signalEngine.CheckEMATouch(PERIOD_H1, 200);
      
      if(emaTouch100 || emaTouch200)
      {
         double currentH1Price = iClose(_Symbol, PERIOD_H1, 1); 
         
         double emaVal = 0;
         // Note: We use GetEMAValue logic manually here or assume we can get it from engine?
         // For one-off checks, manual or helper is fine. Let's use the helper!
         int period = emaTouch100 ? 100 : 200;
         emaVal = signalEngine.GetEMAValue(PERIOD_H1, period, 1);
         
         if(currentH1Price > emaVal)
             CreateSignalArrow(currentBarTime, iLow(_Symbol, PERIOD_H1, 1) - 50*_Point, 233, clrLime, "EMA_Touch_Buy");
         else
             CreateSignalArrow(currentBarTime, iHigh(_Symbol, PERIOD_H1, 1) + 50*_Point, 234, clrRed, "EMA_Touch_Sell");
      }

      lastBarTime = currentBarTime;
   }
}

//+------------------------------------------------------------------+
//| Timer function (1 second interval)                               |
//+------------------------------------------------------------------+
void OnTimer()
{
   // 1. Session & Run Time Logic
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour;
   int min = dt.min;

   bool isRunTime = false;
   if(hour >= 8 && hour < 10) isRunTime = true; // Asia Run
   else if((hour == 13 && min >= 30) || (hour >= 14 && hour < 16)) isRunTime = true; // EU Run
   else if((hour == 19 && min >= 30) || (hour >= 20 && hour < 22)) isRunTime = true; // US Run

   ENUM_MARKET_SESSION session = signalEngine.GetCurrentSession();
   string sessionName = "QUIET";
   if(session == SESSION_ASIA) sessionName = "ASIA";
   else if(session == SESSION_EUROPE) sessionName = "EUROPE";
   else if(session == SESSION_US) sessionName = "US";

   // 2. Countdown Timer (M5 Candle)
   long timeCur = (long)TimeCurrent();
   long timeLeft = 300 - (timeCur % 300);
   string timeStr = StringFormat("M5: %02d:%02d", timeLeft/60, timeLeft%60);

   dashboardPanel.UpdateSessionInfo(sessionName, timeStr, isRunTime);

   // 3. NEW: Update Strategy Signals using SignalEngine methods
   signalEngine.RefreshData();

   // 3a. Trend Alignment (D1/H4/H1)
   TrendAlignment trend = signalEngine.GetTrendAlignment();
   dashboardPanel.UpdateTrendStrength(trend.strengthText, trend.strengthColor);

   // 3b. Combined PA Signal (H1 primary, M5 entry)
   CombinedSignal paSignal = signalEngine.GetCombinedPASignal();
   string paText = paSignal.description;

   // 3c. EMA Distance (M15 and H1)
   EMADistance emaDist = signalEngine.GetEMADistance();
   string emaM15Text = StringFormat("%.0f / %.0f", emaDist.m15_ema100, emaDist.m15_ema200);
   string emaH1Text = StringFormat("%.0f / %.0f", emaDist.h1_ema100, emaDist.h1_ema200);

   // 3d. Risk Recommendation
   string riskRec = StringFormat("%d / %d pts", Input_SL_Points, Input_SL_Points * 2);

   // Update strategy panel
   dashboardPanel.UpdateStrategyInfo(emaM15Text, emaH1Text, paText, riskRec);

   // 3e. Zone Status
   ENUM_ZONE_STATUS zoneStatus = signalEngine.GetCurrentZoneStatus();
   dashboardPanel.UpdateZoneStatus((int)zoneStatus);

   // 4. Panel Updates
   dashboardPanel.UpdateAccountInfo();

   double d1Open = signalEngine.GetD1Open();
   dashboardPanel.UpdateWidwaZones(d1Open);
}

//+------------------------------------------------------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(dashboardPanel.IsBuyButtonClicked(sparam)) ExecuteBuyTrade();
      else if(dashboardPanel.IsSellButtonClicked(sparam)) ExecuteSellTrade();
   }
}

//+------------------------------------------------------------------+
//| Execute Buy Trade                                                 |
//+------------------------------------------------------------------+
void ExecuteBuyTrade()
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double riskPercent = dashboardPanel.GetRiskPercent();
   double sl = currentPrice - (Input_SL_Points * _Point);
   double tp = currentPrice + (Input_SL_Points * 2 * _Point);

   TradeRequest req;
   req.type = ORDER_TYPE_BUY;
   req.price = currentPrice;
   req.sl = sl;
   req.tp = tp;
   req.risk_percent = riskPercent;
   req.comment = "WidwaPa Buy";

   if(tradeManager.ExecuteOrder(req))
   {
      Print("Buy trade executed at ", currentPrice);
      dashboardPanel.UpdateAccountInfo();
   }
   else
   {
      Print("Failed to execute Buy trade");
   }
}

//+------------------------------------------------------------------+
//| Execute Sell Trade                                                |
//+------------------------------------------------------------------+
void ExecuteSellTrade()
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double riskPercent = dashboardPanel.GetRiskPercent();
   double sl = currentPrice + (Input_SL_Points * _Point);
   double tp = currentPrice - (Input_SL_Points * 2 * _Point);

   TradeRequest req;
   req.type = ORDER_TYPE_SELL;
   req.price = currentPrice;
   req.sl = sl;
   req.tp = tp;
   req.risk_percent = riskPercent;
   req.comment = "WidwaPa Sell";

   if(tradeManager.ExecuteOrder(req))
   {
      Print("Sell trade executed at ", currentPrice);
      dashboardPanel.UpdateAccountInfo();
   }
   else
   {
      Print("Failed to execute Sell trade");
   }
}

//+------------------------------------------------------------------+
//| Helper: Create signal arrow on chart                             |
//+------------------------------------------------------------------+
void CreateSignalArrow(datetime time, double price, int arrowCode, color clr, string type)
{
   string name = "WidwaArrow_" + type + "_" + TimeToString(time);
   if(ObjectFind(0, name) >= 0) return; // Already exists

   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, type + " Signal");
}
