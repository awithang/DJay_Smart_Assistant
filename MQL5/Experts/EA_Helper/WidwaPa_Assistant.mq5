//+------------------------------------------------------------------+
//|                                                   WidwaPa_Assistant.mq5 |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
/*
 * WidwaPa Trade Assistant - Expert Advisor
 * --------------------------------------------
 *
 * This EA assists traders following the "Widwa Pa" strategy by:
 *
 * 1. AUTOMATIC ZONE CALCULATION
 *    - Calculates daily Buy/Sell zones based on D1 open price
 *    - Displays zones as colored lines on the chart (Green=Buy, Red=Sell)
 *    - Zone 1: D1 Open +/- 300 points (primary)
 *    - Zone 2: D1 Open +/- 1000 points (secondary)
 *
 * 2. PRICE ACTION SIGNAL DETECTION
 *    - Hammer: Bullish reversal signal
 *    - Shooting Star: Bearish reversal signal
 *    - Engulfing: Strong trend reversal signal
 *
 * 3. EMA TOUCH SIGNALS
 *    - Detects first touch of EMA 100, 200, or 720
 *    - Bullish touch: Price bounces off EMA from above
 *    - Bearish touch: Price rejects EMA from below
 *
 * 4. ONE-CLICK TRADING
 *    - Click BUY or SELL buttons to execute trades instantly
 *    - Auto-calculates lot size based on risk percentage
 *    - Automatic stop loss and take profit (1:2 risk-reward)
 *
 * 5. MARKET SESSION CLOCK
 *    - Asia: 08:00-10:00 (Yellow)
 *    - Europe: 13:30-16:00 (Orange)
 *    - US: 19:30-22:00 (Blue)
 *    - Quiet: Outside active hours (Gray)
 *
 * USAGE:
 * ------
 * 1. Attach EA to XAUUSD (Gold) chart
 * 2. Set Risk Percentage in edit box (1-10% recommended)
 * 3. Watch for signals on the dashboard
 * 4. Click BUY or SELL when signal appears
 * 5. Monitor profit in real-time on panel
 *
 * RISK MANAGEMENT:
 * ---------------
 * - Default risk: 3% per trade
 * - Maximum risk: 10% (capped for safety)
 * - Stop Loss: Configurable (default 300 points)
 * - Take Profit: 2x Stop Loss distance
 * - Trailing Stop: Activates once in profit
 *
 * DISCLAIMER:
 * This EA is a trading assistant tool. Always use proper risk management
 * and test on demo accounts before live trading. Past performance does not
 * guarantee future results.
 */
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"
#property strict
#property description "WidwaPa Trade Assistant - Automated zones, signals, and one-click trading"

#include <EA_Helper/Definitions.mqh>
#include <EA_Helper/SignalEngine.mqh>
#include <EA_Helper/TradeManager.mqh>
#include <EA_Helper/DashboardPanel.mqh>

//--- Input Parameters (Configurable via EA Inputs)
input double Input_RiskPercent = 3.0;       // Risk % per trade (1-10% recommended)
input int    Input_SL_Points = 300;         // Stop Loss distance in points
input int    Input_Zone_Offset1 = 300;      // Zone 1 offset from D1 Open (points)
input int    Input_Zone_Offset2 = 1000;     // Zone 2 offset from D1 Open (points)
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
   // Initialize SignalEngine with zone offsets from input parameters
   signalEngine.Init(Input_Zone_Offset1, Input_Zone_Offset2);

   // Initialize TradeManager with magic number
   tradeManager.Init(Input_MagicNumber);

   // Initialize DashboardPanel with current chart ID
   dashboardPanel.Init(0);

   // Set up timer for 1-second interval
   EventSetTimer(1);

   // Initial zone drawing
   double d1Open = signalEngine.GetD1Open();
   dashboardPanel.UpdateZones(d1Open, Input_Zone_Offset1, Input_Zone_Offset2);

   Print("WidwaPa Assistant initialized successfully.");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Kill timer
   EventKillTimer();

   // Clean up DashboardPanel resources
   dashboardPanel.Destroy();

   Print("WidwaPa Assistant deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Refresh market data in SignalEngine
   signalEngine.RefreshData();

   // Get current price and D1 open
   double currentPrice = signalEngine.GetCurrentPrice();
   double d1Open = signalEngine.GetD1Open();

   // Cache variables for optimization (only update when changed)
   static double prevPrice = 0;
   static double prevProfit = 0;
   static ENUM_SIGNAL_TYPE prevSignal = SIGNAL_NONE;
   static string prevSignalText = "";

   // Update price only if changed significantly (more than 1 point)
   if(MathAbs(currentPrice - prevPrice) > _Point)
   {
      dashboardPanel.UpdatePrice(currentPrice, currentPrice);
      prevPrice = currentPrice;
   }

   // Update profit only if changed by more than $1
   double totalProfit = tradeManager.GetPositionProfit();
   if(MathAbs(totalProfit - prevProfit) > 1.0)
   {
      dashboardPanel.UpdateProfit(totalProfit);
      prevProfit = totalProfit;
   }

   // Apply trailing stop to open positions
   tradeManager.TrailingStop(Input_SL_Points);

   // Update zones on new day (D1 open changed)
   static double prevD1Open = 0;
   if(d1Open != prevD1Open)
   {
      dashboardPanel.UpdateZones(d1Open, Input_Zone_Offset1, Input_Zone_Offset2);
      prevD1Open = d1Open;
   }

   // Check for PA signals (only on new bar)
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   bool newBar = (currentBarTime != lastBarTime);
   if(newBar)
   {
      ENUM_SIGNAL_TYPE paSignal = signalEngine.GetActiveSignal();
      string newSignalText = "";
      if(paSignal == SIGNAL_PA_BUY)
         newSignalText = "HAMMER/ENGULFING BUY";
      else if(paSignal == SIGNAL_PA_SELL)
         newSignalText = "SHOOTING STAR/ENGULFING SELL";

      if(paSignal != SIGNAL_NONE && newSignalText != prevSignalText)
      {
         dashboardPanel.UpdateSignal(paSignal, newSignalText);
         prevSignal = paSignal;
         prevSignalText = newSignalText;
      }
      lastBarTime = currentBarTime;
   }

   // Check for zone entry signals (only if no PA signal and on new bar or price moved significantly)
   if(prevSignal == SIGNAL_NONE)
   {
      ENUM_SIGNAL_TYPE zoneSignal = SIGNAL_NONE;
      string zoneSignalText = "Waiting...";

      if(signalEngine.IsInZone(currentPrice, ZONE_BUY1) ||
         signalEngine.IsInZone(currentPrice, ZONE_BUY2))
      {
         zoneSignal = SIGNAL_BUY_ZONE;
         zoneSignalText = "In Buy Zone";
      }
      else if(signalEngine.IsInZone(currentPrice, ZONE_SELL1) ||
              signalEngine.IsInZone(currentPrice, ZONE_SELL2))
      {
         zoneSignal = SIGNAL_SELL_ZONE;
         zoneSignalText = "In Sell Zone";
      }

      // Only update if signal changed
      if(zoneSignal != prevSignal || zoneSignalText != prevSignalText)
      {
         dashboardPanel.UpdateSignal(zoneSignal, zoneSignalText);
         prevSignal = zoneSignal;
         prevSignalText = zoneSignalText;
      }
   }
}

//+------------------------------------------------------------------+
//| Timer function (1 second interval)                               |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Update session display
   ENUM_MARKET_SESSION session = signalEngine.GetCurrentSession();
   dashboardPanel.UpdateSession(session);

   // Check for EMA touch signals (H1 timeframe)
   bool emaTouch100 = signalEngine.CheckEMATouch(PERIOD_H1, 100);
   bool emaTouch200 = signalEngine.CheckEMATouch(PERIOD_H1, 200);

   if(emaTouch100)
   {
      // Determine bullish or bearish touch based on price position
      double currentPrice = signalEngine.GetCurrentPrice();
      if(currentPrice > iMA(_Symbol, PERIOD_H1, 100, 0, MODE_EMA, PRICE_CLOSE, 1))
      {
         dashboardPanel.UpdateSignal(SIGNAL_EMA_TOUCH_BUY, "EMA 100 Bullish Touch");
      }
      else
      {
         dashboardPanel.UpdateSignal(SIGNAL_EMA_TOUCH_SELL, "EMA 100 Bearish Touch");
      }
   }
   else if(emaTouch200)
   {
      double currentPrice = signalEngine.GetCurrentPrice();
      if(currentPrice > iMA(_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE, 1))
      {
         dashboardPanel.UpdateSignal(SIGNAL_EMA_TOUCH_BUY, "EMA 200 Bullish Touch");
      }
      else
      {
         dashboardPanel.UpdateSignal(SIGNAL_EMA_TOUCH_SELL, "EMA 200 Bearish Touch");
      }
   }
}

//+------------------------------------------------------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // Check if event is a chart object click
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Check if Buy button was clicked
      if(dashboardPanel.IsBuyButtonClicked(sparam))
      {
         ExecuteBuyTrade();
      }
      // Check if Sell button was clicked
      else if(dashboardPanel.IsSellButtonClicked(sparam))
      {
         ExecuteSellTrade();
      }
   }
}

//+------------------------------------------------------------------+
//| Execute Buy Trade                                                 |
//+------------------------------------------------------------------+
void ExecuteBuyTrade()
{
   // Get current price and risk percentage
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double riskPercent = dashboardPanel.GetRiskPercent();

   // Calculate stop loss and take profit
   double sl = currentPrice - (Input_SL_Points * _Point);
   double tp = currentPrice + (Input_SL_Points * 2 * _Point);  // 1:2 risk-reward

   // Create trade request
   TradeRequest req;
   req.type = ORDER_TYPE_BUY;
   req.price = currentPrice;
   req.sl = sl;
   req.tp = tp;
   req.risk_percent = riskPercent;
   req.comment = "WidwaPa Buy";

   // Execute the order
   if(tradeManager.ExecuteOrder(req))
   {
      Print("Buy trade executed successfully at ", currentPrice);
      dashboardPanel.UpdateSignal(SIGNAL_PA_BUY, "BUY ORDER PLACED");
   }
   else
   {
      Print("Failed to execute Buy trade");
      dashboardPanel.UpdateSignal(SIGNAL_NONE, "ORDER FAILED");
   }
}

//+------------------------------------------------------------------+
//| Execute Sell Trade                                                |
//+------------------------------------------------------------------+
void ExecuteSellTrade()
{
   // Get current price and risk percentage
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double riskPercent = dashboardPanel.GetRiskPercent();

   // Calculate stop loss and take profit
   double sl = currentPrice + (Input_SL_Points * _Point);
   double tp = currentPrice - (Input_SL_Points * 2 * _Point);  // 1:2 risk-reward

   // Create trade request
   TradeRequest req;
   req.type = ORDER_TYPE_SELL;
   req.price = currentPrice;
   req.sl = sl;
   req.tp = tp;
   req.risk_percent = riskPercent;
   req.comment = "WidwaPa Sell";

   // Execute the order
   if(tradeManager.ExecuteOrder(req))
   {
      Print("Sell trade executed successfully at ", currentPrice);
      dashboardPanel.UpdateSignal(SIGNAL_PA_SELL, "SELL ORDER PLACED");
   }
   else
   {
      Print("Failed to execute Sell trade");
      dashboardPanel.UpdateSignal(SIGNAL_NONE, "ORDER FAILED");
   }
}

//+------------------------------------------------------------------+
