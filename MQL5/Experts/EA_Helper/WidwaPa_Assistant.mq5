//+------------------------------------------------------------------+
//|                                                   WidwaPa_Assistant.mq5 |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"
#property description "DJAY Smart Assistant - Automated zones, signals, and one-click trading"

#include <EA_Helper/Definitions.mqh>
#include <EA_Helper/SignalEngine.mqh>
#include <EA_Helper/TradeManager.mqh>
#include <EA_Helper/DashboardPanel.mqh>
#include <EA_Helper/ChartZones.mqh>

//--- Input Parameters
input double Input_RiskPercent = 1.0;       // Risk % per trade
input int    Input_SL_Points = 300;         // Stop Loss distance
input int    Input_Zone_Offset1 = 300;      // Zone 1 offset (points)
input int    Input_Zone_Offset2 = 1000;     // Zone 2 offset (points)
input int    Input_MagicNumber = 123456;    // Unique ID for EA trades

//--- Smart Trailing Settings
input group "=== Smart Trailing Settings ==="
input bool   Input_Use_Smart_Trail     = true;   // Enable Smart Profit Lock
input double Input_Trail_Trigger_Pct   = 50.0;   // Trigger % of TP Distance (e.g. 50%)
input double Input_Trail_Lock_Pct      = 30.0;   // Lock % of TP Distance (e.g. 30%)

//--- Auto Mode Options
input group "=== Auto Mode Options ==="
input bool   Input_Auto_Arrow          = true;   // Auto Trade on Any Arrow (PA/EMA)
input bool   Input_Auto_Reversal       = true;   // Auto Trade on Reversal (Zone Bounce)
input bool   Input_Auto_Breakout       = false;  // Auto Trade on Breakout (Zone Flip)

//--- Chart Zones Settings
input group "=== Chart Zones Settings ==="
input bool   Input_Show_Zones_On_Chart   = true;   // Show zones on chart
input bool   Input_Show_Pivot_Line       = true;   // Show D1 Open pivot line
input int    Input_Max_Zones_Show        = 10;     // Max zones above/below to display
input int    Input_Zone_Range_Points     = 50;     // Zone depth (±points from level)

//--- Global Objects
CSignalEngine   signalEngine;
CTradeManager   tradeManager;
CDashboardPanel dashboardPanel;
CChartZones     chartZones;

//--- Trading Mode State
ENUM_TRADING_MODE g_tradingMode = MODE_MANUAL;
bool g_strat_arrow;
bool g_strat_rev;
bool g_strat_break;

//--- Strategy Entry State (for Manual Execution buttons)
EntryPoint g_last_rev_entry;
EntryPoint g_last_brk_entry;

//--- Recommendation State (for One-Click Execution)
ENUM_ORDER_TYPE g_rec_type = ORDER_TYPE_BUY_LIMIT; // Default placeholder
double          g_rec_price = 0.0;
double          g_rec_sl = 0.0;
double          g_rec_tp = 0.0;
bool            g_rec_active = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Init Strategy Bools
   g_strat_arrow = Input_Auto_Arrow;
   g_strat_rev = Input_Auto_Reversal;
   g_strat_break = Input_Auto_Breakout;

   signalEngine.Init(Input_Zone_Offset1, Input_Zone_Offset2);
   tradeManager.Init(Input_MagicNumber);
   dashboardPanel.Init(0);
   dashboardPanel.UpdateTradingMode((int)g_tradingMode);
   dashboardPanel.UpdateStrategyButtons(g_strat_arrow, g_strat_rev, g_strat_break);

   // Initialize Chart Zones
   double d1Open = signalEngine.GetD1Open();
   chartZones.Init(d1Open, Input_Zone_Offset1, Input_Zone_Offset2, Input_Zone_Range_Points);
   chartZones.SetSettings(Input_Show_Zones_On_Chart, Input_Show_Pivot_Line, Input_Max_Zones_Show);

   dashboardPanel.UpdateWidwaZones(d1Open);

   EventSetTimer(1);
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true); // Enable Mouse Events for Dragging

   Print("DJAY Smart Assistant initialized successfully.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   dashboardPanel.Destroy();
   chartZones.Destroy();  // Cleanup chart zone objects
   Print("DJAY Smart Assistant deinitialized. Reason: ", reason);
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
      // dashboardPanel.UpdateAccountInfo(); // Removed
      prevProfit = totalProfit;
   }

   // Smart Trailing Logic (Profit Lock)
   if(Input_Use_Smart_Trail)
   {
      tradeManager.SmartProfitLock(Input_Trail_Trigger_Pct, Input_Trail_Lock_Pct);
   }

   // --- Real-time Dashboard Updates (Safe Implementation) ---
   dashboardPanel.UpdatePrice(currentPrice);

   // Only update order list if profit changes or count changes to avoid UI lag
   static double lastTotalProfit = -9999;
   static int lastPositionsCount = -1;
   // totalProfit already calculated above
   int currentPositionsCount = PositionsTotal();

   if(MathAbs(totalProfit - lastTotalProfit) > 0.01 || currentPositionsCount != lastPositionsCount)
   {
      long orderTickets[4];
      double orderPrices[4];
      double orderProfits[4];
      double orderLots[4];
      int orderTypes[4];
      
      int activeCount = 0;
      int magic = Input_MagicNumber;

      for(int i=0; i<PositionsTotal() && activeCount < 4; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic)
            {
               orderTickets[activeCount] = (long)ticket;
               orderPrices[activeCount]  = PositionGetDouble(POSITION_PRICE_OPEN);
               orderProfits[activeCount] = PositionGetDouble(POSITION_PROFIT);
               orderLots[activeCount]    = PositionGetDouble(POSITION_VOLUME);
               orderTypes[activeCount]   = (int)PositionGetInteger(POSITION_TYPE);
               
               activeCount++;
            }
         }
      }
      dashboardPanel.UpdateActiveOrders(activeCount, orderTickets, orderPrices, orderProfits, orderLots, orderTypes, totalProfit);
      lastTotalProfit = totalProfit;
      lastPositionsCount = currentPositionsCount;
   }

   // Check for PA signals (only on new bar)
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   bool newBar = (currentBarTime != lastBarTime);
   if(newBar)
   {
      // --- 1. Price Action Signals ---
      ENUM_SIGNAL_TYPE paSignal = signalEngine.GetActiveSignal();
      
      // Get High/Low of previous bar for arrow placement
      double prevHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
      double prevLow = iLow(_Symbol, PERIOD_CURRENT, 1);
      
      if(paSignal == SIGNAL_PA_BUY)
      {
         CreateSignalArrow(currentBarTime, prevLow - 50*_Point, 233, clrBlue, "PA_Buy");
         // AUTO MODE (Legacy Arrow logic)
         if(g_tradingMode == MODE_AUTO && g_strat_arrow)
            ExecuteBuyTrade("ARROW");
      }
      else if(paSignal == SIGNAL_PA_SELL)
      {
         CreateSignalArrow(currentBarTime, prevHigh + 50*_Point, 234, clrOrange, "PA_Sell");
         // AUTO MODE (Legacy Arrow logic)
         if(g_tradingMode == MODE_AUTO && g_strat_arrow)
            ExecuteSellTrade("ARROW");
      }

      // --- 2. EMA Touch Signals ---
      // Check H1 EMA Touch
      bool emaTouch100 = signalEngine.CheckEMATouch(PERIOD_H1, 100);
      bool emaTouch200 = signalEngine.CheckEMATouch(PERIOD_H1, 200);
      bool emaSignalBuy = false;
      bool emaSignalSell = false;

      if(emaTouch100 || emaTouch200)
      {
         double currentH1Price = iClose(_Symbol, PERIOD_H1, 1);
         double emaVal = 0;
         int period = emaTouch100 ? 100 : 200;
         emaVal = signalEngine.GetEMAValue(PERIOD_H1, period, 1);

         if(currentH1Price > emaVal)
         {
             CreateSignalArrow(currentBarTime, iLow(_Symbol, PERIOD_H1, 1) - 50*_Point, 233, clrBlue, "EMA_Touch_Buy");
             emaSignalBuy = true;
         }
         else
         {
             CreateSignalArrow(currentBarTime, iHigh(_Symbol, PERIOD_H1, 1) + 50*_Point, 234, clrOrange, "EMA_Touch_Sell");
             emaSignalSell = true;
         }
      }
      
      // --- AUTO TRADING EXECUTION (Selective) ---
      if(g_tradingMode == MODE_AUTO)
      {
         // 1. Arrow Strategy (EMA specifically)
         if(g_strat_arrow)
         {
            if(emaSignalBuy) ExecuteBuyTrade("EMA");
            if(emaSignalSell) ExecuteSellTrade("EMA");
         }
         
         // 2. Reversal Strategy (Zone Bounce)
         if(g_strat_rev && signalEngine.IsReversalSetup())
         {
            if(paSignal == SIGNAL_PA_BUY) ExecuteBuyTrade("REV");
            if(paSignal == SIGNAL_PA_SELL) ExecuteSellTrade("REV");
         }
         
         // 3. Breakout Strategy (Zone Flip)
         if(g_strat_break && signalEngine.IsBreakoutSetup())
         {
            if(paSignal == SIGNAL_PA_BUY) ExecuteBuyTrade("BREAK");
            if(paSignal == SIGNAL_PA_SELL) ExecuteSellTrade("BREAK");
         }
      }

      lastBarTime = currentBarTime;
   }
}

//+------------------------------------------------------------------+
//| Timer function (1 second interval)                               |
//+------------------------------------------------------------------+
void OnTimer()
{
   ulong start = GetMicrosecondCount();

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

   // 3. Update Strategy Signals using SignalEngine methods
   signalEngine.RefreshData();

   if(!signalEngine.IsDataReady())
   {
      dashboardPanel.UpdateAdvisor("Synchronizing market data... Please wait.");
      dashboardPanel.UpdateTrendStrength("LOADING...", clrGray);
      dashboardPanel.UpdateConfirmButton("", false);
      return;
   }

   // 3a. Trend Alignment (D1/H4/H1)
   TrendAlignment trend = signalEngine.GetTrendAlignment();
   dashboardPanel.UpdateTrendStrength(trend.strengthText, trend.strengthColor);

   // 3b. Combined PA Signal (H1 primary, M5 entry)
   CombinedSignal paSignal = signalEngine.GetCombinedPASignal();
   string paText = paSignal.description;

   // Update strategy panel (new signature: reversal_alert, rev_valid, breakout_alert, brk_valid, pa_signal)
   g_last_rev_entry = signalEngine.GetReversalEntryPoint();
   g_last_brk_entry = signalEngine.GetBreakoutEntryPoint();

   dashboardPanel.UpdateStrategyInfo(g_last_rev_entry.description, g_last_rev_entry.isValid, g_last_brk_entry.description, g_last_brk_entry.isValid, paText);

   // 3e. Zone Status
   ENUM_ZONE_STATUS zoneStatus = signalEngine.GetCurrentZoneStatus();
   dashboardPanel.UpdateZoneStatus((int)zoneStatus);

   // 3f. Advisor Message
   string advisorMessage = signalEngine.GetAdvisorMessage();
   dashboardPanel.UpdateAdvisor(advisorMessage);

   // 3g. Check for Pending Order Recommendation
   ENUM_ORDER_TYPE recType;
   double recPrice, recSL, recTP;
   if(signalEngine.GetRecommendedPending(recType, recPrice, recSL, recTP, Input_SL_Points))
   {
      g_rec_active = true;
      g_rec_type = recType;
      g_rec_price = recPrice;
      g_rec_sl = recSL;
      g_rec_tp = recTP;
      
      string typeStr = (recType == ORDER_TYPE_BUY_LIMIT) ? "BUY LIMIT" : "SELL LIMIT";
      string btnLabel = StringFormat("%s @ %s", typeStr, DoubleToString(recPrice, _Digits));
      dashboardPanel.UpdateConfirmButton(btnLabel, true);
   }
   else
   {
      g_rec_active = false;
      dashboardPanel.UpdateConfirmButton("", false);
   }

   // 4. Panel Updates
   // dashboardPanel.UpdateAccountInfo(); // Removed

   // Price and Orders are now updated in OnTick for real-time responsiveness

   double d1Open = signalEngine.GetD1Open();
   dashboardPanel.UpdateWidwaZones(d1Open);
   double currentPrice = signalEngine.GetCurrentPrice();

   // 5. Update Chart Zones
   chartZones.Update(d1Open, currentPrice);

   // Final Redraw to update all changes
   dashboardPanel.Redraw();
   
   ulong duration = GetMicrosecondCount() - start;
   if(duration > 10000) // Print if > 10ms
      Print("WARNING: OnTimer took ", duration, " us");
}

//+------------------------------------------------------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // Forward event to dashboard for handling (e.g. Dragging)
   dashboardPanel.OnEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(dashboardPanel.IsBuyButtonClicked(sparam)) 
      {
         ExecuteBuyTrade();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
      }
      else if(dashboardPanel.IsSellButtonClicked(sparam)) 
      {
         ExecuteSellTrade();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
      }
      else if(dashboardPanel.IsModeButtonClicked(sparam))
      {
         // Toggle AUTO mode (ON/OFF) - Manual always available
         Print("DEBUG: Auto button clicked! Before toggle: g_tradingMode=", (int)g_tradingMode, " (0=OFF, 1=ON)");
         g_tradingMode = (g_tradingMode == MODE_MANUAL) ? MODE_AUTO : MODE_MANUAL;
         dashboardPanel.UpdateTradingMode((int)g_tradingMode);
         string modeStr = (g_tradingMode == MODE_AUTO) ? "AUTO ON (Manual + Auto trading)" : "AUTO OFF (Manual only)";
         Print("Trading Mode: ", modeStr);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
      }
      else if(dashboardPanel.IsConfirmButtonClicked(sparam))
      {
         if(g_rec_active)
         {
            double risk = dashboardPanel.GetRiskPercent();
            tradeManager.ExecutePending(g_rec_type, g_rec_price, g_rec_sl, g_rec_tp, risk, "WidwaPa Pending");
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
         }
      }
      // Reversal/Breakout Action Buttons
      else if(dashboardPanel.IsRevActionClicked(sparam))
      {
         if(g_last_rev_entry.isValid)
         {
            double risk = dashboardPanel.GetRiskPercent();
            ENUM_ORDER_TYPE type = (g_last_rev_entry.direction == "BUY") ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
            double sl = (type == ORDER_TYPE_BUY_LIMIT) ? g_last_rev_entry.price - (Input_SL_Points * _Point) : g_last_rev_entry.price + (Input_SL_Points * _Point);
            double tp = (type == ORDER_TYPE_BUY_LIMIT) ? g_last_rev_entry.price + (Input_SL_Points * 2 * _Point) : g_last_rev_entry.price - (Input_SL_Points * 2 * _Point);
            
            tradeManager.ExecutePending(type, g_last_rev_entry.price, sl, tp, risk, "WidwaPa Rev Button");
         }
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsBrkActionClicked(sparam))
      {
         if(g_last_brk_entry.isValid)
         {
            double risk = dashboardPanel.GetRiskPercent();
            ENUM_ORDER_TYPE type = (g_last_brk_entry.direction == "BUY") ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
            double sl = (type == ORDER_TYPE_BUY_LIMIT) ? g_last_brk_entry.price - (Input_SL_Points * _Point) : g_last_brk_entry.price + (Input_SL_Points * _Point);
            double tp = (type == ORDER_TYPE_BUY_LIMIT) ? g_last_brk_entry.price + (Input_SL_Points * 2 * _Point) : g_last_brk_entry.price - (Input_SL_Points * 2 * _Point);
            
            tradeManager.ExecutePending(type, g_last_brk_entry.price, sl, tp, risk, "WidwaPa Brk Button");
         }
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      // Strategy Toggles
      else if(dashboardPanel.IsStratArrowClicked(sparam))
      {
         g_strat_arrow = !g_strat_arrow;
         dashboardPanel.UpdateStrategyButtons(g_strat_arrow, g_strat_rev, g_strat_break);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsStratRevClicked(sparam))
      {
         g_strat_rev = !g_strat_rev;
         dashboardPanel.UpdateStrategyButtons(g_strat_arrow, g_strat_rev, g_strat_break);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsStratBreakClicked(sparam))
      {
         g_strat_break = !g_strat_break;
         dashboardPanel.UpdateStrategyButtons(g_strat_arrow, g_strat_rev, g_strat_break);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsCloseAllButtonClicked(sparam))
      {
         tradeManager.CloseAllSymbolPositions();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      // Individual order close buttons
      else
      {
         int orderIndex = -1;
         if(dashboardPanel.IsCloseOrderButtonClicked(sparam, orderIndex))
         {
            long ticket = dashboardPanel.GetOrderTicket(orderIndex);
            if(ticket > 0)
            {
               if(tradeManager.ClosePositionByTicket(ticket))
               {
                  Print("Closed order #", ticket);
               }
               else
               {
                  Print("Failed to close order #", ticket);
               }
            }
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         }
      }
      ChartRedraw(0);
   }
}

//+------------------------------------------------------------------+
//| Execute Buy Trade                                                 |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(string strategy="MANUAL")
{
   // Duplicate Prevention: Check if position with same strategy comment already exists
   if(strategy != "MANUAL" && tradeManager.HasOpenPosition(strategy))
   {
      Print("Duplicate Trade Blocked: strategy ", strategy, " already has an open position.");
      return;
   }

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
   req.comment = "WidwaPa Buy " + strategy;

   if(tradeManager.ExecuteOrder(req))
   {
      Print("Buy trade executed at ", currentPrice);
      // dashboardPanel.UpdateAccountInfo(); // Removed
      dashboardPanel.UpdateLastAutoTrade(strategy, "BUY", currentPrice);
   }
   else
   {
      Print("Failed to execute Buy trade");
   }
}

//+------------------------------------------------------------------+
//| Execute Sell Trade                                                |
//+------------------------------------------------------------------+
void ExecuteSellTrade(string strategy="MANUAL")
{
   // Duplicate Prevention: Check if position with same strategy comment already exists
   if(strategy != "MANUAL" && tradeManager.HasOpenPosition(strategy))
   {
      Print("Duplicate Trade Blocked: strategy ", strategy, " already has an open position.");
      return;
   }

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
   req.comment = "WidwaPa Sell " + strategy;

   if(tradeManager.ExecuteOrder(req))
   {
      Print("Sell trade executed at ", currentPrice);
      // dashboardPanel.UpdateAccountInfo(); // Removed
      dashboardPanel.UpdateLastAutoTrade(strategy, "SELL", currentPrice);
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