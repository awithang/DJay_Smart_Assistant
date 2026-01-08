//+------------------------------------------------------------------+
//|                                         DJay_Smart_Assistant.mq5 |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"
#property description "DJAY Smart Assistant - Automated zones, signals, and one-click trading"

#include <DJay_Assistant/Definitions.mqh>
#include <DJay_Assistant/SignalEngine.mqh>
#include <DJay_Assistant/TradeManager.mqh>
#include <DJay_Assistant/DashboardPanel.mqh>
#include <DJay_Assistant/ChartZones.mqh>

//--- Input Parameters
input double Input_RiskPercent = 1.0;       // Risk % per trade
input int    Input_SL_Points = 500;         // Stop Loss distance (updated from 300)
input int    Input_Zone_Offset1 = 300;      // Zone 1 offset (points)
input int    Input_Zone_Offset2 = 1000;     // Zone 2 offset (points)
input int    Input_MagicNumber = 123456;    // Unique ID for EA trades

//--- M15/M5 Hybrid Scalp Settings (Replaces Quick Scalp)
input group "=== M15/M5 Hybrid Scalp ==="
input bool   Input_Enable_Hybrid_Mode    = false;  // Enable Hybrid Mode (M15 Context + M5 Entry)
input int    Input_Hybrid_TP_Points      = 225;    // Take Profit (points) - Target 1.5x risk
input int    Input_Hybrid_SL_Points      = 150;    // Stop Loss (points) - Tight risk
input double Input_Hybrid_EMA_MaxDist    = 0.5;    // Max EMA distance (ATR multiplier for pullback)
input bool   Input_Hybrid_UseTrendFilter = true;   // Require M15 trend alignment (strict)
input int    Input_Hybrid_MinATR         = 50;     // Minimum M15 ATR (volatility filter)
input bool   Input_Hybrid_Debug_Mode     = false;  // Enable debug logging (development)
input double Input_Hybrid_Trend_MinScore = 2.0;    // Minimum trend score (2=2/3 TFs aligned)

//--- Lot Size Calculation Mode
input ENUM_LOT_SIZE_MODE Input_Hybrid_Lot_Mode    = LOT_MODE_RISK_PERCENT;  // Lot size: Risk% or Fixed
input double             Input_Hybrid_Fixed_Lots  = 0.01;                   // Fixed lot size (when Mode=Fixed)
input double             Input_Hybrid_Risk_Percent = 1.0;                   // Risk % (when Mode=Risk%)

//--- RR Ratio Settings (NEW)
input ENUM_RR_RATIO Input_Default_RR = RR_1_TO_2;  // Default RR Ratio

//--- Trade Management Settings (Ladder Logic)
input group "=== Trade Management (Ladder Logic) ==="
input bool   Input_Use_TradeManagement = true;   // Default Profit Lock State (sets initial button ON/OFF)
input int    Input_ProfitLock_Trigger_Pts = 200; // Profit Lock Trigger (points) - e.g., 200 = 20 pips
input int    Input_ProfitLock_Amount_Pts  = 50;  // Initial Lock Amount (points) - e.g., 50 = 5 pips
input int    Input_ProfitLock_Step_Pts    = 100; // Step Size (points) - e.g., 100 = 10 pips

//--- Sniper Update Settings (Sprint 1-4)
input group "=== Sniper Update Settings ==="
input bool   Input_Enable_Sniper_Mode     = false;  // Enable Sniper Mode (M15-based filtered signals)
input bool   Input_Sniper_Debug_Mode      = false;  // Enable Debug Mode (logs signal rejection reasons)
input double Input_Sniper_ATR_Multiplier  = 1.5;    // Dynamic SL Multiplier (default 1.5x ATR)
input double Input_Sniper_Zone_Tolerance  = 50.0;   // Structure proximity tolerance (points)
input double Input_Sniper_BE_Trigger_Pts  = 200.0;  // Auto Break-Even trigger (points)
input double Input_Sniper_BE_Padding_Pts  = 10.0;   // Auto Break-Even SL padding (points)
input double Input_Sniper_Trail_Mult      = 1.0;    // Smart Trail multiplier (1.0x ATR)
input double Input_Sniper_Trail_Min_Profit = 200.0; // Minimum profit before trail activates (points)
input int    Input_Sniper_ADX_Trend_Min   = 25;     // ADX threshold for Trending market
input int    Input_Sniper_ADX_Range_Max   = 20;     // ADX threshold for Ranging market

//--- Auto Mode Options
input group "=== Auto Mode Options ==="
input bool   Input_Auto_Arrow          = true;   // Auto Trade on Any Arrow (PA/EMA)
input bool   Input_Auto_Reversal       = true;   // Auto Trade on Reversal (Zone Bounce)
input bool   Input_Auto_Breakout       = true;   // Auto Trade on Breakout (Zone Flip)

//--- Chart Zones Settings
input group "=== Chart Zones Settings ==="
input bool   Input_Show_Zones_On_Chart   = true;   // Show zones on chart
input bool   Input_Show_Pivot_Line       = true;   // Show D1 Open pivot line
input int    Input_Max_Zones_Show        = 3;      // Max zones above/below to display
input int    Input_Zone_Range_Points     = 50;     // Zone depth (±points from level)

//--- Signal Safety Settings
input group "=== Signal Safety Settings ==="
input int    Input_Signal_TTL_Seconds    = 300;    // Signal Time-To-Live in seconds (5 min)
input int    Input_Pending_Min_Buffer   = 50;     // Minimum buffer for pending orders (points)

//--- Risk Management Settings
input group "=== Risk Management Settings ==="
input double Input_Daily_Max_Loss_Percent = 5.0;   // Daily Max Loss % (0 = disabled)
input int    Input_Max_Open_Trades        = 5;     // Maximum concurrent open trades (0 = unlimited)

//--- Time Settings
input group "=== Time Settings ==="
input int    Input_GMT_Offset             = 2;     // GMT Offset (hours) for broker time adjustment

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

//--- M15/M5 Hybrid Mode State (Replaces Quick Scalp)
bool g_hybrid_mode_enabled;          // Track if Hybrid Mode is active
bool g_hybrid_context_ready;         // M15 context allows trading
ENUM_TREND_BIAS g_hybrid_bias;       // Current bias: BULLISH/BEARISH/NEUTRAL

//--- Strategy Entry State (for Manual Execution buttons)
EntryPoint g_last_rev_entry;
EntryPoint g_last_brk_entry;

//--- Captured Entry Points (preserved when button clicked)
EntryPoint g_captured_rev_entry;
bool g_has_captured_rev = false;
EntryPoint g_captured_brk_entry;
bool g_has_captured_brk = false;

//--- Recommendation State (for One-Click Execution)
ENUM_ORDER_TYPE g_rec_type = ORDER_TYPE_BUY_LIMIT; // Default placeholder
double          g_rec_price = 0.0;
double          g_rec_sl = 0.0;
double          g_rec_tp = 0.0;
bool            g_rec_active = false;

//--- Risk Management State
datetime g_daily_reset_time = 0;   // Track when daily P&L last reset
double   g_daily_start_balance = 0; // Balance at start of trading day

//--- Sniper Update State
MarketContext g_marketContext;       // Current market intelligence (Sprint 1)
bool g_sniper_mode_enabled = false;  // Track if Sniper Mode is active

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Init Strategy Bools
   g_strat_arrow = Input_Auto_Arrow;
   g_strat_rev = Input_Auto_Reversal;
   g_strat_break = Input_Auto_Breakout;

   // Init M15/M5 Hybrid Mode
   g_hybrid_mode_enabled = Input_Enable_Hybrid_Mode;
   if(g_hybrid_mode_enabled)
      Print("HYBRID MODE: ENABLED - M15 Context + M5 Entry");

   // Init Sniper Mode
   g_sniper_mode_enabled = Input_Enable_Sniper_Mode;
   if(g_sniper_mode_enabled)
      Print("SNIPER MODE: ENABLED - Using M15 3-filter signals");

   signalEngine.Init(Input_Zone_Offset1, Input_Zone_Offset2, Input_GMT_Offset);
   tradeManager.Init(Input_MagicNumber);
   dashboardPanel.Init(0, Input_RiskPercent, Input_ProfitLock_Trigger_Pts, Input_ProfitLock_Amount_Pts, Input_ProfitLock_Step_Pts);
   dashboardPanel.InitSettings(Input_Default_RR, Input_Use_TradeManagement);  // Initialize Settings with Profit Lock state
   dashboardPanel.UpdateTradingMode((int)g_tradingMode);
   dashboardPanel.UpdateStrategyButtons(g_strat_arrow, g_strat_rev, g_strat_break, g_hybrid_mode_enabled);

   // Initialize Chart Zones
   double d1Open = signalEngine.GetD1Open();
   chartZones.Init(d1Open, Input_Zone_Offset1, Input_Zone_Offset2, Input_Zone_Range_Points);
   chartZones.SetSettings(Input_Show_Zones_On_Chart, Input_Show_Pivot_Line, Input_Max_Zones_Show);

   dashboardPanel.UpdateDJayZones(d1Open, Input_Max_Zones_Show * 2);

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
   // 1. Fast Price Update (Real-time)
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // 2. Throttled Analysis (Run every 1 second)
   // This prevents blocking the UI thread with heavy calculations on every tick
   static ulong last_calc_time = 0;
   ulong now = GetMicrosecondCount();
   
   if (now - last_calc_time > 1000000) // 1 second throttle
   {
       signalEngine.RefreshData();
       
       // SNIPER UPDATE: Risk Management & Ghost Buttons
       g_marketContext = signalEngine.GetMarketContext();
       dashboardPanel.UpdateExecutionButtons(g_marketContext);
       
       last_calc_time = now;
   }

   double d1Open = signalEngine.GetD1Open();
   
   // Update zones if D1 Open changes (new day)
   static double prevD1Open = 0;
   if(d1Open != prevD1Open)
   {
      dashboardPanel.UpdateDJayZones(d1Open, Input_Max_Zones_Show * 2);
      prevD1Open = d1Open;
   }

   // Calculate Profit (Needed for UI and Logic)
   double totalProfit = tradeManager.GetPositionProfit();

   // Trade Management: Ladder Logic Profit Lock
   if(dashboardPanel.IsTrailingEnabled())
   {
      int plTrigger = dashboardPanel.GetPL_Trigger();
      int plAmount = dashboardPanel.GetPL_Amount();
      int plStep = dashboardPanel.GetPL_Step();
      tradeManager.ManagePositions(plTrigger, plAmount, plStep);
   }

   // Auto Break-Even (moves SL to entry + padding after profit threshold)
   if(g_sniper_mode_enabled)
   {
      tradeManager.AutoBreakEven(Input_Sniper_BE_Trigger_Pts, Input_Sniper_BE_Padding_Pts);

      // Smart Trail (ATR-based trailing stop)
      tradeManager.SmartTrail(g_marketContext.atrM15, Input_Sniper_Trail_Mult, Input_Sniper_Trail_Min_Profit);
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
      long orderTickets[20];
      double orderPrices[20];
      double orderProfits[20];
      double orderLots[20];
      int orderTypes[20];

      int activeCount = 0;
      int magic = Input_MagicNumber;

      for(int i=0; i<PositionsTotal() && activeCount < 20; i++)
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

         // --- 4. SNIPER MODE (M15 3-Filter Signals) ---
         if(g_sniper_mode_enabled)
         {
            // Get Sniper Signal (M15-based with 3-filter stack)
            ENUM_SIGNAL_TYPE sniperSignal = signalEngine.GetSniperSignal(
               Input_Sniper_Debug_Mode,
               1.0,  // ATR multiplier for volume filter
               Input_Sniper_Zone_Tolerance  // Structure proximity
            );

            // Create arrow and execute trade on valid Sniper signal
            if(sniperSignal == SIGNAL_PA_BUY)
            {
               // Create Sniper arrow (Lime, code 233 - different from QS)
               double prevLow = iLow(_Symbol, PERIOD_M15, 1);
               CreateSignalArrow(currentBarTime, prevLow - 50*_Point, 233, clrLime, "SNIPER_Buy");

               // AUTO MODE execution with Dynamic SL
               if(g_tradingMode == MODE_AUTO)
                  ExecuteSniperTrade(ORDER_TYPE_BUY);
            }
            else if(sniperSignal == SIGNAL_PA_SELL)
            {
               // Create Sniper arrow (Red, code 234)
               double prevHigh = iHigh(_Symbol, PERIOD_M15, 1);
               CreateSignalArrow(currentBarTime, prevHigh + 50*_Point, 234, clrRed, "SNIPER_Sell");

               // AUTO MODE execution with Dynamic SL
               if(g_tradingMode == MODE_AUTO)
                  ExecuteSniperTrade(ORDER_TYPE_SELL);
            }
         }
      }

         // --- 5. HYBRID MODE (M15 Context + M5 Entry) - DISABLED when Sniper Mode is ON ---
         if(g_hybrid_mode_enabled && !g_sniper_mode_enabled)
         {
            // Only check on new M5 bar (for efficiency)
            static datetime lastM5BarTime = 0;
            datetime currentM5BarTime = iTime(_Symbol, PERIOD_M5, 0);
            bool newM5Bar = (currentM5BarTime != lastM5BarTime);

            if(newM5Bar)
            {
               // Get Hybrid Signal (M15 context + M5 trigger)
               ENUM_SIGNAL_TYPE hybridSignal = signalEngine.GetHybridSignal(
                  Input_Hybrid_Debug_Mode,
                  Input_Hybrid_EMA_MaxDist,
                  Input_Hybrid_Trend_MinScore
               );

               // Execute trade on valid Hybrid signal
               if(hybridSignal == SIGNAL_PA_BUY)
               {
                  // Create Hybrid arrow (Lime, code 241 - different from Sniper)
                  double prevLow = iLow(_Symbol, PERIOD_M5, 1);
                  CreateSignalArrow(currentM5BarTime, prevLow - 50*_Point, 241, clrLime, "HYBRID_Buy");

                  // AUTO MODE execution
                  if(g_tradingMode == MODE_AUTO)
                     ExecuteHybridTrade(ORDER_TYPE_BUY);
               }
               else if(hybridSignal == SIGNAL_PA_SELL)
               {
                  // Create Hybrid arrow (Red, code 242)
                  double prevHigh = iHigh(_Symbol, PERIOD_M5, 1);
                  CreateSignalArrow(currentM5BarTime, prevHigh + 50*_Point, 242, clrRed, "HYBRID_Sell");

                  // AUTO MODE execution
                  if(g_tradingMode == MODE_AUTO)
                     ExecuteHybridTrade(ORDER_TYPE_SELL);
               }

               lastM5BarTime = currentM5BarTime;
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

   // PERFORMANCE OPTIMIZATION: Throttle Heavy Logic
   // Run heavy analysis only every 3 seconds to keep UI responsive
   static int heavy_tick = 0;
   heavy_tick++;
   if(heavy_tick % 3 != 0) return;

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

   // Capture valid entry points for button execution (preserve until signal invalid)
   if(g_last_rev_entry.isValid && !g_has_captured_rev) {
      g_captured_rev_entry = g_last_rev_entry;
      g_has_captured_rev = true;
      Print("DEBUG: Captured Reversal entry - ", g_captured_rev_entry.direction, " @ ", g_captured_rev_entry.price, " (", g_captured_rev_entry.zone, ")");
   }
   // Reset capture when signal becomes invalid (using isValid flag, not description string)
   if(!g_last_rev_entry.isValid && g_has_captured_rev) {
      Print("DEBUG: Resetting captured Reversal entry - signal invalid");
      g_has_captured_rev = false;
   }

   if(g_last_brk_entry.isValid && !g_has_captured_brk) {
      g_captured_brk_entry = g_last_brk_entry;
      g_has_captured_brk = true;
      Print("DEBUG: Captured Breakout entry - ", g_captured_brk_entry.direction, " @ ", g_captured_brk_entry.price, " (", g_captured_brk_entry.zone, ")");
   }
   // Reset capture when signal becomes invalid (using isValid flag, not description string)
   if(!g_last_brk_entry.isValid && g_has_captured_brk) {
      Print("DEBUG: Resetting captured Breakout entry - signal invalid");
      g_has_captured_brk = false;
   }

   // Check Signal TTL (Time-To-Live) for captured entries
   if(g_has_captured_rev && g_captured_rev_entry.timestamp > 0) {
      int timeElapsed = (int)(TimeCurrent() - g_captured_rev_entry.timestamp);
      if(timeElapsed > Input_Signal_TTL_Seconds) {
         Print("[TTL] Reversal signal expired after ", timeElapsed, " seconds (TTL=", Input_Signal_TTL_Seconds, ")");
         g_has_captured_rev = false;
      }
   }

   if(g_has_captured_brk && g_captured_brk_entry.timestamp > 0) {
      int timeElapsed = (int)(TimeCurrent() - g_captured_brk_entry.timestamp);
      if(timeElapsed > Input_Signal_TTL_Seconds) {
         Print("[TTL] Breakout signal expired after ", timeElapsed, " seconds (TTL=", Input_Signal_TTL_Seconds, ")");
         g_has_captured_brk = false;
      }
   }

   dashboardPanel.UpdateStrategyInfo(g_last_rev_entry.description, g_last_rev_entry.isValid, g_last_brk_entry.description, g_last_brk_entry.isValid, paText);

   // 3e. Zone Status
   ENUM_ZONE_STATUS zoneStatus = signalEngine.GetCurrentZoneStatus();
   dashboardPanel.UpdateZoneStatus((int)zoneStatus);

   // 3e-1. Hybrid Mode Smart State (Context-aware Visual Feedback) - Sprint 6
   if(g_hybrid_mode_enabled)
   {
      // Calculate M15 context readiness
      TrendMatrix tm = signalEngine.GetTrendMatrix();
      int trendScore = tm.h4 + tm.h1 + tm.m15;

      if(trendScore >= 2)
      {
         g_hybrid_bias = TREND_BIAS_BULLISH;
         g_hybrid_context_ready = true;
      }
      else if(trendScore <= -2)
      {
         g_hybrid_bias = TREND_BIAS_BEARISH;
         g_hybrid_context_ready = true;
      }
      else
      {
         g_hybrid_bias = TREND_BIAS_NEUTRAL;
         g_hybrid_context_ready = false;
      }

      // Update dashboard with Hybrid status (if DashboardPanel has the function)
      // Note: UpdateHybridStatus will be implemented in Phase 4 (Dashboard UI)
      // dashboardPanel.UpdateHybridStatus(g_hybrid_context_ready, g_hybrid_bias);
   }

   // 3f. Advisor Message
   string advisorMessage = signalEngine.GetAdvisorMessage(g_hybrid_mode_enabled);
   dashboardPanel.UpdateAdvisor(advisorMessage);

   // 3f-1. Advisor Details (Zone, Trend, Hybrid, RSI)
   string zoneText, trendText, qsText, rsiText;

   // Zone info with distance
   ENUM_ZONE_STATUS zone = signalEngine.GetCurrentZoneStatus();
   double zoneBuy1 = signalEngine.GetZoneLevel(ZONE_BUY1);
   double zoneSell1 = signalEngine.GetZoneLevel(ZONE_SELL1);
   double currentPrice = signalEngine.GetCurrentPrice();
   double distToBuy = MathAbs(currentPrice - zoneBuy1);
   double distToSell = MathAbs(currentPrice - zoneSell1);

   if(zone == ZONE_STATUS_NONE)
      zoneText = StringFormat("Zone: Middle (%.0f pts to Buy1)", distToBuy/_Point);
   else if(zone == ZONE_STATUS_IN_BUY1)
      zoneText = StringFormat("Zone: Buy1 (%.0f pts in)", distToBuy/_Point);
   else if(zone == ZONE_STATUS_IN_BUY2)
      zoneText = StringFormat("Zone: Buy2 (%.0f pts in)", (currentPrice - zoneBuy1)/_Point);
   else if(zone == ZONE_STATUS_IN_SELL1)
      zoneText = StringFormat("Zone: Sell1 (%.0f pts in)", distToSell/_Point);
   else if(zone == ZONE_STATUS_IN_SELL2)
      zoneText = StringFormat("Zone: Sell2 (%.0f pts in)", (zoneSell1 - currentPrice)/_Point);
   else
      zoneText = "Zone: Scanning...";

   // H1 Trend
   ENUM_TREND_DIRECTION h1Trend = signalEngine.GetTrendDirection(PERIOD_H1);
   if(h1Trend == TREND_UP)
      trendText = "H1 Trend: UP";
   else if(h1Trend == TREND_DOWN)
      trendText = "H1 Trend: DOWN";
   else
      trendText = "H1 Trend: FLAT";

   // Hybrid Mode status
   qsText = g_hybrid_mode_enabled ? "HYBRID: Active" : "HYBRID: Inactive";

   // RSI and Stochastic values (combined on same row)
   double rsiVal = signalEngine.GetRSIValue(PERIOD_M5, 14, 0);
   double stochVal = signalEngine.GetStochKValue(PERIOD_M5, 14, 3, 0);

   if(rsiVal > 0 && stochVal > 0)
      rsiText = StringFormat("RSI: %.0f | Stoch: %.1f", rsiVal, stochVal);
   else if(rsiVal > 0)
      rsiText = StringFormat("RSI: %.0f | Stoch: --", rsiVal);
   else if(stochVal > 0)
      rsiText = StringFormat("RSI: -- | Stoch: %.1f", stochVal);
   else
      rsiText = "RSI: -- | Stoch: --";

   // ADX value
   double adxVal = signalEngine.GetADXValue(PERIOD_M5);
   string adxText = (adxVal > 0) ? StringFormat("ADX(M5): %.1f", adxVal) : "ADX(M5): --";

   // Current TF PA Signal (for Quick Scalp reference)
   ENUM_SIGNAL_TYPE currentTFSignal = signalEngine.GetActiveSignal();
   string currentTFPAText = "";
   if(currentTFSignal == SIGNAL_PA_BUY)
      currentTFPAText = "PA: BUY";
   else if(currentTFSignal == SIGNAL_PA_SELL)
      currentTFPAText = "PA: SELL";
   else
      currentTFPAText = "PA: NONE";

   dashboardPanel.UpdateAdvisorDetails(zoneText, trendText, qsText, rsiText, adxText, currentTFPAText);

   //============================================================
   // SNIPER UPDATE: Sprint 3 - Dashboard 3-Column Grid Update
   //============================================================
   // Get RSI and Stochastic for the grid
   double rsiForGrid = signalEngine.GetRSIValue(PERIOD_M15, 14, 0);
   double stochForGrid = signalEngine.GetStochKValue(PERIOD_M15, 14, 3, 0);
   ENUM_SIGNAL_TYPE m15Signal = signalEngine.GetActiveSignal();

   // Update the Market Intelligence Grid with all context data
   dashboardPanel.UpdateMarketIntelligenceGrid(g_marketContext, rsiForGrid, stochForGrid, m15Signal);

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
   dashboardPanel.UpdateDJayZones(d1Open, Input_Max_Zones_Show * 2);
   currentPrice = signalEngine.GetCurrentPrice();

   // 5. Update Chart Zones
   chartZones.Update(d1Open, currentPrice);

   // Final Redraw to update all changes
   dashboardPanel.Redraw();
   
   // ulong duration = GetMicrosecondCount() - start;
   // if(duration > 10000) // Print if > 10ms
   //    Print("WARNING: OnTimer took ", duration, " us");
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
         // Check if trading is allowed BEFORE attempting execution
         if(!IsTradingAllowed())
         {
            // Trading blocked by risk management - show alert to user
            Alert("Manual BUY Blocked: Risk Management limit reached. Check Experts log for details.");
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
         }
         else
         {
            ExecuteBuyTrade();
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
         }
      }
      else if(dashboardPanel.IsSellButtonClicked(sparam))
      {
         // Check if trading is allowed BEFORE attempting execution
         if(!IsTradingAllowed())
         {
            // Trading blocked by risk management - show alert to user
            Alert("Manual SELL Blocked: Risk Management limit reached. Check Experts log for details.");
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
         }
         else
         {
            ExecuteSellTrade();
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
         }
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
      else if(dashboardPanel.IsOpenSettingsClicked(sparam))
      {
         // Open EA Properties window using F7 Hotkey simulation
         long handle = (long)ChartGetInteger(0, CHART_WINDOW_HANDLE);
         PostMessageW(handle, WM_KEYDOWN, VK_F7, 0);
         PostMessageW(handle, WM_KEYUP, VK_F7, 0);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
      }
      else if(dashboardPanel.IsStatsButtonClicked(sparam))
      {
         // TODO: Open Trade Statistics panel (not implemented yet)
         Print("Statistics button clicked - Feature coming soon!");
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
      }
      else if(dashboardPanel.IsConfirmButtonClicked(sparam))
      {
         if(g_rec_active)
         {
            // Risk Management Check
            if(!IsTradingAllowed())
            {
               ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
               return;
            }

            double risk = dashboardPanel.GetRiskPercent();
            double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double entryPrice = g_rec_price;

            // Dynamic buffer: MathMax(user_min_buffer, current_spread * 1.5)
            int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
            int minBuffer = MathMax(Input_Pending_Min_Buffer, (int)(spread * 1.5));

            // Adjust entry price based on current price with buffer
            if(g_rec_type == ORDER_TYPE_BUY_LIMIT)
            {
               // BUY_LIMIT: Must be below current price
               entryPrice = MathMin(g_rec_price, currentPrice - minBuffer * _Point);
            }
            else if(g_rec_type == ORDER_TYPE_SELL_LIMIT)
            {
               // SELL_LIMIT: Must be above current price
               entryPrice = MathMax(g_rec_price, currentPrice + minBuffer * _Point);
            }
            // For STOP orders, adjust accordingly
            else if(g_rec_type == ORDER_TYPE_BUY_STOP)
            {
               // BUY_STOP: Must be above current price
               entryPrice = MathMax(g_rec_price, currentPrice + minBuffer * _Point);
            }
            else if(g_rec_type == ORDER_TYPE_SELL_STOP)
            {
               // SELL_STOP: Must be below current price
               entryPrice = MathMin(g_rec_price, currentPrice - minBuffer * _Point);
            }

            // Recalculate SL/TP based on adjusted entry price
            double sl, tp;
            if(g_rec_type == ORDER_TYPE_BUY_LIMIT || g_rec_type == ORDER_TYPE_BUY_STOP)
            {
               sl = entryPrice - (Input_SL_Points * _Point);
               tp = entryPrice + (Input_SL_Points * 2 * _Point);
            }
            else  // SELL orders
            {
               sl = entryPrice + (Input_SL_Points * _Point);
               tp = entryPrice - (Input_SL_Points * 2 * _Point);
            }

            tradeManager.ExecutePending(g_rec_type, entryPrice, sl, tp, risk, "DJay Pending");
            Print("[TRADE_EXEC] Confirm Button: type=", g_rec_type, " current=", currentPrice, " entry=", entryPrice, " orig=", g_rec_price, " buffer=", minBuffer);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset button state
         }
      }
      // Reversal/Breakout Action Buttons
      else if(dashboardPanel.IsRevActionClicked(sparam))
      {
         // Use captured entry point (preserved from when button became active)
         // REVERSAL: Adjust entry price based on current market price with buffer
         if(g_has_captured_rev && g_captured_rev_entry.price > 0)
         {
            // Risk Management Check
            if(!IsTradingAllowed())
            {
               ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
               return;
            }

            double risk = dashboardPanel.GetRiskPercent();
            double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double entryPrice = 0;
            ENUM_ORDER_TYPE type;
            double sl, tp;

            // Dynamic buffer: MathMax(user_min_buffer, current_spread * 1.5)
            int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
            int minBuffer = MathMax(Input_Pending_Min_Buffer, (int)(spread * 1.5));

            if(g_captured_rev_entry.direction == "BUY")
            {
               // BUY_LIMIT: Place below current price
               entryPrice = MathMin(g_captured_rev_entry.price, currentPrice - minBuffer * _Point);
               type = ORDER_TYPE_BUY_LIMIT;
               sl = entryPrice - (Input_SL_Points * _Point);
               tp = entryPrice + (Input_SL_Points * 2 * _Point);
            }
            else  // SELL
            {
               // SELL_LIMIT: Place above current price
               entryPrice = MathMax(g_captured_rev_entry.price, currentPrice + minBuffer * _Point);
               type = ORDER_TYPE_SELL_LIMIT;
               sl = entryPrice + (Input_SL_Points * _Point);
               tp = entryPrice - (Input_SL_Points * 2 * _Point);
            }

            tradeManager.ExecutePending(type, entryPrice, sl, tp, risk, "DJay Rev Button");
            Print("[TRADE_EXEC] Reversal Button: ", g_captured_rev_entry.direction, " order - current=", currentPrice, " entry=", entryPrice, " zone=", g_captured_rev_entry.price, " buffer=", minBuffer);
            // Clear capture after execution
            g_has_captured_rev = false;
         }
         else
         {
            Print("Reversal Button: No valid entry point - g_has_captured_rev=", g_has_captured_rev, " price=", g_captured_rev_entry.price);
         }
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsBrkActionClicked(sparam))
      {
         // Use captured entry point (preserved from when button became active)
         // BREAKOUT uses STOP orders (entry above/below current price) with buffer
         if(g_has_captured_brk && g_captured_brk_entry.price > 0)
         {
            // Risk Management Check
            if(!IsTradingAllowed())
            {
               ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
               return;
            }

            double risk = dashboardPanel.GetRiskPercent();
            double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double entryPrice = 0;
            ENUM_ORDER_TYPE type;
            double sl, tp;

            // Dynamic buffer: MathMax(user_min_buffer, current_spread * 1.5)
            int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
            int minBuffer = MathMax(Input_Pending_Min_Buffer, (int)(spread * 1.5));

            if(g_captured_brk_entry.direction == "BUY")
            {
               // BUY_STOP: Place above current price
               entryPrice = MathMax(g_captured_brk_entry.price, currentPrice + minBuffer * _Point);
               type = ORDER_TYPE_BUY_STOP;
               sl = entryPrice - (Input_SL_Points * _Point);
               tp = entryPrice + (Input_SL_Points * 2 * _Point);
            }
            else  // SELL
            {
               // SELL_STOP: Place below current price
               entryPrice = MathMin(g_captured_brk_entry.price, currentPrice - minBuffer * _Point);
               type = ORDER_TYPE_SELL_STOP;
               sl = entryPrice + (Input_SL_Points * _Point);
               tp = entryPrice - (Input_SL_Points * 2 * _Point);
            }

            tradeManager.ExecutePending(type, entryPrice, sl, tp, risk, "DJay Brk Button");
            Print("[TRADE_EXEC] Breakout Button: ", g_captured_brk_entry.direction, " order - current=", currentPrice, " entry=", entryPrice, " zone=", g_captured_brk_entry.price, " buffer=", minBuffer);
            // Clear capture after execution
            g_has_captured_brk = false;
         }
         else
         {
            Print("Breakout Button: No valid entry point - g_has_captured_brk=", g_has_captured_brk, " price=", g_captured_brk_entry.price);
         }
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      // Strategy Toggles
      else if(dashboardPanel.IsStratArrowClicked(sparam))
      {
         g_strat_arrow = !g_strat_arrow;
         dashboardPanel.UpdateStrategyButtons(g_strat_arrow, g_strat_rev, g_strat_break, g_hybrid_mode_enabled);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsStratRevClicked(sparam))
      {
         g_strat_rev = !g_strat_rev;
         dashboardPanel.UpdateStrategyButtons(g_strat_arrow, g_strat_rev, g_strat_break, g_hybrid_mode_enabled);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsStratBreakClicked(sparam))
      {
         g_strat_break = !g_strat_break;
         dashboardPanel.UpdateStrategyButtons(g_strat_arrow, g_strat_rev, g_strat_break, g_hybrid_mode_enabled);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsStratQSClicked(sparam))
      {
         g_hybrid_mode_enabled = !g_hybrid_mode_enabled;
         dashboardPanel.UpdateStrategyButtons(g_strat_arrow, g_strat_rev, g_strat_break, g_hybrid_mode_enabled);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         Print("Hybrid Mode: ", g_hybrid_mode_enabled ? "ENABLED" : "DISABLED");
      }
      // === TEST HELPERS (Sprint 6) - Hybrid Mode Testing ===
      else if(dashboardPanel.IsTestStateClicked(sparam))
      {
         TestPrintHybridState();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsTestSignalClicked(sparam))
      {
         TestHybridSignal();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsTestFiltersClicked(sparam))
      {
         TestPrintFilters();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsTestTradeClicked(sparam))
      {
         TestTradeCalculation();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsTestLotsClicked(sparam))
      {
         TestLotSizeCalculation();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      // Settings Buttons (handled in DashboardPanel - RR, Trailing, and Profit Lock)
      else if(dashboardPanel.IsRR1Clicked(sparam) ||
              dashboardPanel.IsRR15Clicked(sparam) ||
              dashboardPanel.IsRR2Clicked(sparam) ||
              dashboardPanel.IsTrailingToggleClicked(sparam))
      {
         // Handled in DashboardPanel.OnEvent() - instant update, no full redraw needed
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         return;  // Early return - skip ChartRedraw
      }
      else if(dashboardPanel.IsCloseAllButtonClicked(sparam))
      {
         tradeManager.CloseAllSymbolPositions();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsScrollUpClicked(sparam))
      {
         // Scroll up - decrease scroll offset
         dashboardPanel.ScrollUp();
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(dashboardPanel.IsScrollDownClicked(sparam))
      {
         // Scroll down - increase scroll offset
         dashboardPanel.ScrollDown();
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
   // Risk Management Check
   if(!IsTradingAllowed())
      return;

   // SAFETY CHECK: Smart Filters (Ghost Button Logic applied to Auto-Trade)
   // Only apply if NOT Manual (Manual trades override safety) AND NOT Aggressive Mode
   if(strategy != "MANUAL" && !dashboardPanel.IsAggressiveOn())
   {
      // 1. Slope Check (Falling Knife Protection)
      if(g_marketContext.slopeH1 == SLOPE_CRASH)
      {
         Print("[AUTO_BLOCK] Buy blocked by CRASH slope protection");
         return;
      }

      // 2. Trend Filter Check
      if(dashboardPanel.IsTrendFilterOn() && g_marketContext.trendMatrix.h1 == TREND_DOWN)
      {
         Print("[AUTO_BLOCK] Buy blocked by H1 Downtrend (Trend Filter ON)");
         return;
      }
   }

   // Duplicate Prevention: Check if position with same strategy comment already exists
   if(strategy != "MANUAL" && tradeManager.HasOpenPosition(strategy))
   {
      Print("Duplicate Trade Blocked: strategy ", strategy, " already has an open position.");
      return;
   }

   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double riskPercent = dashboardPanel.GetRiskPercent();
   double rrMultiplier = dashboardPanel.GetRRMultiplier();  // NEW: Dynamic RR
   double sl = currentPrice - (Input_SL_Points * _Point);
   double tp = currentPrice + (Input_SL_Points * rrMultiplier * _Point);  // NEW: Use dynamic RR

   TradeRequest req;
   req.type = ORDER_TYPE_BUY;
   req.price = currentPrice;
   req.sl = sl;
   req.tp = tp;
   req.risk_percent = riskPercent;
   req.comment = "DJay Buy " + strategy;

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
   // Risk Management Check
   if(!IsTradingAllowed())
      return;

   // SAFETY CHECK: Smart Filters (Ghost Button Logic applied to Auto-Trade)
   // Only apply if NOT Manual (Manual trades override safety) AND NOT Aggressive Mode
   if(strategy != "MANUAL" && !dashboardPanel.IsAggressiveOn())
   {
      // 1. Slope Check (Rocket Protection)
      if(g_marketContext.slopeH1 == SLOPE_UP)
      {
         Print("[AUTO_BLOCK] Sell blocked by STRONG UP slope protection");
         return;
      }

      // 2. Trend Filter Check
      if(dashboardPanel.IsTrendFilterOn() && g_marketContext.trendMatrix.h1 == TREND_UP)
      {
         Print("[AUTO_BLOCK] Sell blocked by H1 Uptrend (Trend Filter ON)");
         return;
      }
   }

   // Duplicate Prevention: Check if position with same strategy comment already exists
   if(strategy != "MANUAL" && tradeManager.HasOpenPosition(strategy))
   {
      Print("Duplicate Trade Blocked: strategy ", strategy, " already has an open position.");
      return;
   }

   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double riskPercent = dashboardPanel.GetRiskPercent();
   double rrMultiplier = dashboardPanel.GetRRMultiplier();  // NEW: Dynamic RR
   double sl = currentPrice + (Input_SL_Points * _Point);
   double tp = currentPrice - (Input_SL_Points * rrMultiplier * _Point);  // NEW: Use dynamic RR

   TradeRequest req;
   req.type = ORDER_TYPE_SELL;
   req.price = currentPrice;
   req.sl = sl;
   req.tp = tp;
   req.risk_percent = riskPercent;
   req.comment = "DJay Sell " + strategy;

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
//| Execute Sniper Trade (Dynamic ATR-based SL/TP)                    |
//+------------------------------------------------------------------+
void ExecuteSniperTrade(ENUM_ORDER_TYPE orderType)
{
   // Risk Management Check
   if(!IsTradingAllowed())
      return;

   // SAFETY CHECK: Smart Filters (Ghost Button Logic applied to Sniper Auto-Trade)
   if(!dashboardPanel.IsAggressiveOn())
   {
      if(orderType == ORDER_TYPE_BUY)
      {
         // 1. Slope Check
         if(g_marketContext.slopeH1 == SLOPE_CRASH)
         {
            Print("[SNIPER_BLOCK] Buy blocked by CRASH slope protection");
            return;
         }
         // 2. Trend Check
         if(dashboardPanel.IsTrendFilterOn() && g_marketContext.trendMatrix.h1 == TREND_DOWN)
         {
            Print("[SNIPER_BLOCK] Buy blocked by H1 Downtrend");
            return;
         }
      }
      else // SELL
      {
         // 1. Slope Check
         if(g_marketContext.slopeH1 == SLOPE_UP)
         {
            Print("[SNIPER_BLOCK] Sell blocked by STRONG UP slope protection");
            return;
         }
         // 2. Trend Check
         if(dashboardPanel.IsTrendFilterOn() && g_marketContext.trendMatrix.h1 == TREND_UP)
         {
            Print("[SNIPER_BLOCK] Sell blocked by H1 Uptrend");
            return;
         }
      }
   }

   // Calculate entry price
   double entryPrice = (orderType == ORDER_TYPE_BUY) ?
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                        SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Use Dynamic SL based on current ATR (Sprint 4)
   bool isBuy = (orderType == ORDER_TYPE_BUY);
   double sl = tradeManager.CalculateDynamicSL(entryPrice, isBuy, g_marketContext.atrM15, Input_Sniper_ATR_Multiplier);

   // Calculate TP using RR multiplier from dashboard (1:2 default)
   double rrMultiplier = dashboardPanel.GetRRMultiplier();
   double slDistance = MathAbs(entryPrice - sl);
   double tp = isBuy ? (entryPrice + slDistance * rrMultiplier) : (entryPrice - slDistance * rrMultiplier);

   // Normalize values
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   // Execute trade
   TradeRequest req;
   req.type = orderType;
   req.price = entryPrice;
   req.sl = sl;
   req.tp = tp;
   req.risk_percent = dashboardPanel.GetRiskPercent();
   req.comment = "SNIPER_" + (string)(isBuy ? "BUY" : "SELL");

   if(tradeManager.ExecuteOrder(req))
   {
      Print("SNIPER ", (isBuy ? "BUY" : "SELL"), " executed at ", entryPrice,
            " SL=", sl, " (Dynamic ATR=", g_marketContext.atrM15, " pts)");
      dashboardPanel.UpdateLastAutoTrade("SNIPER", (isBuy ? "BUY" : "SELL"), entryPrice);
   }
   else
   {
      Print("SNIPER Order Failed");
   }
}

//+------------------------------------------------------------------+
//| Execute Hybrid Trade (M15 Context + M5 Entry)                     |
//| Sprint 6: Hybrid Mode implementation                             |
//+------------------------------------------------------------------+
void ExecuteHybridTrade(ENUM_ORDER_TYPE orderType)
{
   // Risk Management Check
   if(!IsTradingAllowed())
      return;

   // Calculate entry price
   double entryPrice = (orderType == ORDER_TYPE_BUY) ?
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                        SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Tight SL (smaller than standard strategies)
   double sl = (orderType == ORDER_TYPE_BUY) ?
               entryPrice - (Input_Hybrid_SL_Points * _Point) :
               entryPrice + (Input_Hybrid_SL_Points * _Point);

   // Quick TP (scalp target)
   double tp = (orderType == ORDER_TYPE_BUY) ?
               entryPrice + (Input_Hybrid_TP_Points * _Point) :
               entryPrice - (Input_Hybrid_TP_Points * _Point);

   //─────────────────────────────────────────────────────────────
   // LOT SIZE CALCULATION (Based on User Selection)
   //─────────────────────────────────────────────────────────────
   double lotSize = 0.0;
   double riskPercent = 0.0;

   if(Input_Hybrid_Lot_Mode == LOT_MODE_FIXED_LOTS)
   {
      // Use fixed lot size (manual)
      lotSize = Input_Hybrid_Fixed_Lots;
      riskPercent = 0.0;  // Not applicable for fixed lots
   }
   else  // LOT_MODE_RISK_PERCENT (default)
   {
      // Calculate lot size based on risk percentage
      riskPercent = Input_Hybrid_Risk_Percent;
      lotSize = tradeManager.CalculateLotSize(entryPrice, sl, riskPercent);

      if(lotSize <= 0)
      {
         Print("HYBRID: Failed to calculate lot size - trade aborted");
         return;
      }
   }

   // Build trade request
   TradeRequest req;
   req.type = orderType;
   req.price = entryPrice;
   req.sl = sl;
   req.tp = tp;
   req.risk_percent = riskPercent;
   req.lot_size = lotSize;
   req.comment = "HYBRID_" + (string)(orderType == ORDER_TYPE_BUY ? "BUY" : "SELL");

   // Execute trade with custom lot size (validation happens in ExecuteOrderWithLot)
   if(tradeManager.ExecuteOrderWithLot(req))
   {
      string lotInfo = (Input_Hybrid_Lot_Mode == LOT_MODE_FIXED_LOTS) ?
                       StringFormat("%.2f (Fixed)", lotSize) :
                       StringFormat("%.2f (%.1f%% Risk)", lotSize, riskPercent);

      Print("HYBRID ", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"),
            " executed @ ", entryPrice,
            " Lots: ", lotInfo,
            " TP: ", Input_Hybrid_TP_Points, " pts",
            " SL: ", Input_Hybrid_SL_Points, " pts",
            " Context: ", g_hybrid_bias == TREND_BIAS_BULLISH ? "BULLISH" : "BEARISH");
      dashboardPanel.UpdateLastAutoTrade("HYBRID", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"), entryPrice);
   }
   else
   {
      Print("HYBRID Order Failed");
   }
}

//+------------------------------------------------------------------+
//| TEST HELPER: Print Hybrid Mode State (Sprint 6)                   |
//| Usage: Click "STATE" button on dashboard                          |
//+------------------------------------------------------------------+
void TestPrintHybridState()
{
   TrendMatrix tm = signalEngine.GetTrendMatrix();
   MarketContext ctx = signalEngine.GetMarketContext();

   Print("========================================");
   Print("    HYBRID MODE STATE DUMP");
   Print("========================================");

   // Trend Matrix
   Print("--- TREND MATRIX ---");
   Print("H4 Trend: ",  EnumToString(tm.h4));
   Print("H1 Trend: ",  EnumToString(tm.h1));
   Print("M15 Trend: ", EnumToString(tm.m15));
   Print("Trend Score: ", tm.score, " (Range: -3 to +3)");

   // Market Context
   Print("--- MARKET CONTEXT ---");
   Print("Market State: ", EnumToString(ctx.marketState));
   Print("ADX Value: ", ctx.adxValue);
   Print("ATR M15: ", ctx.atrM15, " points");
   Print("ATR M5: ", ctx.atrM5, " points");

   // Slope Analysis
   Print("--- SLOPE ANALYSIS ---");
   Print("H1 Slope: ", EnumToString(ctx.slopeH1));
   Print("Slope Value: ", ctx.slopeValue);
   Print("EMA Distance: ", ctx.emaDistance, " points");

   // Hybrid Mode State
   Print("--- HYBRID STATE ---");
   Print("Context Ready: ", g_hybrid_context_ready ? "YES" : "NO");
   Print("Trend Bias: ", EnumToString(g_hybrid_bias));
   Print("Hybrid Mode: ", g_hybrid_mode_enabled ? "ENABLED" : "DISABLED");
   Print("Sniper Mode: ", g_sniper_mode_enabled ? "ENABLED" : "DISABLED");

   Print("========================================");
}

//+------------------------------------------------------------------+
//| TEST HELPER: Test Hybrid Signal Detection (Sprint 6)             |
//| Usage: Click "SIGNAL" button on dashboard                         |
//+------------------------------------------------------------------+
void TestHybridSignal()
{
   Print("========================================");
   Print("    TESTING HYBRID SIGNAL DETECTION");
   Print("========================================");

   ENUM_SIGNAL_TYPE signal = signalEngine.GetHybridSignal(
      true,   // Debug mode ON
      Input_Hybrid_EMA_MaxDist,
      Input_Hybrid_Trend_MinScore
   );

   Print("SIGNAL RESULT: ", EnumToString(signal));

   if(signal == SIGNAL_PA_BUY)
      Print("✅ HYBRID BUY signal detected - READY TO TRADE");
   else if(signal == SIGNAL_PA_SELL)
      Print("✅ HYBRID SELL signal detected - READY TO TRADE");
   else
      Print("❌ NO SIGNAL - See logs for rejection reason");

   Print("========================================");
}

//+------------------------------------------------------------------+
//| TEST HELPER: Print Filter Status (Sprint 6)                       |
//| Usage: Click "FILTERS" button on dashboard                        |
//+------------------------------------------------------------------+
void TestPrintFilters()
{
   TrendMatrix tm = signalEngine.GetTrendMatrix();
   MarketContext ctx = signalEngine.GetMarketContext();
   double priceM15 = iClose(_Symbol, PERIOD_M15, 0);
   double emaM15 = signalEngine.GetEMAValue(PERIOD_M15, 20, 0);
   double distFromEMA = MathAbs(priceM15 - emaM15) / _Point;
   double maxAllowedDist = ctx.atrM15 * Input_Hybrid_EMA_MaxDist;

   Print("========================================");
   Print("    HYBRID FILTER STATUS");
   Print("========================================");

   // Filter 1: Trend Alignment
   bool trendPass = (tm.score >= (int)Input_Hybrid_Trend_MinScore ||
                     tm.score <= -(int)Input_Hybrid_Trend_MinScore);
   Print("[1] TREND FILTER: ", trendPass ? "✅ PASS" : "❌ FAIL",
         " | Score: ", tm.score, " (Need ±", Input_Hybrid_Trend_MinScore, "+)");

   // Filter 2: Market State
   bool statePass = (ctx.marketState != STATE_CHOPPY);
   Print("[2] MARKET STATE: ", statePass ? "✅ PASS" : "❌ FAIL",
         " | ", EnumToString(ctx.marketState));

   // Filter 3: Volatility
   bool volPass = (ctx.atrM15 >= Input_Hybrid_MinATR);
   Print("[3] VOLATILITY: ", volPass ? "✅ PASS" : "❌ FAIL",
         " | ATR: ", ctx.atrM15, " (Min: ", Input_Hybrid_MinATR, ")");

   // Filter 4: Location (Distance from EMA)
   bool locPass = (distFromEMA <= maxAllowedDist);
   Print("[4] LOCATION: ", locPass ? "✅ PASS" : "❌ FAIL",
         " | Dist: ", (int)distFromEMA, " pts (Max: ", (int)maxAllowedDist, " pts)");

   // Filter 5: Slope Safety
   bool slopeBuyPass = (ctx.slopeH1 != SLOPE_CRASH);
   bool slopeSellPass = (ctx.slopeH1 != SLOPE_ROCKET);
   Print("[5] SLOPE SAFETY:");
   Print("    Buy Protection: ", slopeBuyPass ? "✅ PASS" : "❌ FAIL",
         " | ", EnumToString(ctx.slopeH1));
   Print("    Sell Protection: ", slopeSellPass ? "✅ PASS" : "❌ FAIL",
         " | ", EnumToString(ctx.slopeH1));

   // Overall Status
   bool allPass = trendPass && statePass && volPass && locPass;
   Print("---");
   Print("OVERALL: ", allPass ? "✅ ALL FILTERS PASS" : "❌ FILTERS BLOCKING");
   Print("========================================");
}

//+------------------------------------------------------------------+
//| TEST HELPER: Test Trade Calculation (Sprint 6)                   |
//| Usage: Click "TRADE" button on dashboard                          |
//+------------------------------------------------------------------+
void TestTradeCalculation()
{
   Print("========================================");
   Print("    TRADE CALCULATION TEST");
   Print("========================================");

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // Test BUY trade
   Print("--- BUY TRADE ---");
   Print("Entry: ", ask);
   double buySL = ask - (Input_Hybrid_SL_Points * _Point);
   double buyTP = ask + (Input_Hybrid_TP_Points * _Point);
   Print("SL: ", buySL, " (Distance: -", Input_Hybrid_SL_Points, " pts)");
   Print("TP: ", buyTP, " (Distance: +", Input_Hybrid_TP_Points, " pts)");
   Print("Risk:Reward: 1:", StringFormat("%.1f", (double)Input_Hybrid_TP_Points / Input_Hybrid_SL_Points));

   // Test SELL trade
   Print("\n--- SELL TRADE ---");
   Print("Entry: ", bid);
   double sellSL = bid + (Input_Hybrid_SL_Points * _Point);
   double sellTP = bid - (Input_Hybrid_TP_Points * _Point);
   Print("SL: ", sellSL, " (Distance: +", Input_Hybrid_SL_Points, " pts)");
   Print("TP: ", sellTP, " (Distance: -", Input_Hybrid_TP_Points, " pts)");
   Print("Risk:Reward: 1:", StringFormat("%.1f", (double)Input_Hybrid_TP_Points / Input_Hybrid_SL_Points));

   // Lot Size Info
   Print("\n--- LOT SIZE MODE ---");
   if(Input_Hybrid_Lot_Mode == LOT_MODE_FIXED_LOTS)
      Print("Mode: FIXED LOTS | Size: ", Input_Hybrid_Fixed_Lots);
   else
      Print("Mode: RISK PERCENT | Risk: ", Input_Hybrid_Risk_Percent, "%");

   Print("========================================");
}

//+------------------------------------------------------------------+
//| TEST HELPER: Test Lot Size Calculation (Sprint 6)                |
//| Usage: Click "LOT CALC" button on dashboard                      |
//+------------------------------------------------------------------+
void TestLotSizeCalculation()
{
   Print("========================================");
   Print("    LOT SIZE CALCULATION TEST");
   Print("========================================");

   double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = entry - (Input_Hybrid_SL_Points * _Point);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   // Symbol limits
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   Print("--- SYMBOL LIMITS ---");
   Print("Min Lot: ", minLot);
   Print("Max Lot: ", maxLot);
   Print("Lot Step: ", lotStep);
   Print("Current Balance: $", balance);

   // Test Risk Percent Mode
   Print("\n--- RISK PERCENT MODE ---");
   for(double risk = 0.5; risk <= 3.0; risk += 0.5)
   {
      double lots = tradeManager.CalculateLotSize(entry, sl, risk);
      Print("Risk ", risk, "%: ", StringFormat("%.2f", lots), " lots");
   }

   // Test Fixed Lot Mode
   Print("\n--- FIXED LOT MODE ---");
   Print("Configured: ", Input_Hybrid_Fixed_Lots, " lots");

   // Validate fixed lot
   double validatedLot = Input_Hybrid_Fixed_Lots;
   if(validatedLot < minLot) validatedLot = minLot;
   if(validatedLot > maxLot) validatedLot = maxLot;
   if(validatedLot > 10.0) validatedLot = 10.0; // Safety cap
   validatedLot = MathFloor(validatedLot / lotStep) * lotStep;

   Print("Validated: ", validatedLot, " lots");

   Print("========================================");
}

//+------------------------------------------------------------------+
//| Risk Management: Get current open trades count                   |
//+------------------------------------------------------------------+
int GetOpenTradesCount()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetInteger(POSITION_MAGIC) == Input_MagicNumber)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Risk Management: Calculate daily P&L as percentage of balance   |
//+------------------------------------------------------------------+
double GetDailyPnLPercent()
{
   // Check if we need to reset daily tracking (new trading day)
   datetime currentTime = TimeCurrent();
   MqlDateTime tm;
   TimeToStruct(currentTime, tm);

   // Calculate midnight time (00:00) for current day
   MqlDateTime midnight_tm = tm;
   midnight_tm.hour = 0;
   midnight_tm.min = 0;
   midnight_tm.sec = 0;
   datetime midnight = StructToTime(midnight_tm);

   // Reset tracking if it's a new day
   if(g_daily_reset_time < midnight || g_daily_reset_time == 0)
   {
      g_daily_reset_time = currentTime;
      g_daily_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      Print("[RISK_MGMT] New trading day - Start Balance: $", g_daily_start_balance);
   }

   // Calculate daily P&L
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double dailyPnL = currentBalance - g_daily_start_balance;

   // Convert to percentage
   if(g_daily_start_balance > 0)
      return (dailyPnL / g_daily_start_balance) * 100.0;
   else
      return 0.0;
}

//+------------------------------------------------------------------+
//| Risk Management: Check if trading is allowed                     |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   string blockReason = "";

   // Check max open trades
   if(Input_Max_Open_Trades > 0)
   {
      int openTrades = GetOpenTradesCount();
      if(openTrades >= Input_Max_Open_Trades)
      {
         blockReason = StringFormat("Max open trades reached (%d/%d)", openTrades, Input_Max_Open_Trades);
      }
   }

   // Check daily loss limit
   if(Input_Daily_Max_Loss_Percent > 0 && blockReason == "")
   {
      double dailyPnL = GetDailyPnLPercent();
      if(dailyPnL < -Input_Daily_Max_Loss_Percent)
      {
         blockReason = StringFormat("Daily loss limit reached (%.2f%% / -%.2f%%)", dailyPnL, Input_Daily_Max_Loss_Percent);
      }
   }

   if(blockReason != "")
   {
      Print("[RISK_BLOCK] Trade blocked - ", blockReason);
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Helper: Create signal arrow on chart                             |
//+------------------------------------------------------------------+
void CreateSignalArrow(datetime time, double price, int arrowCode, color clr, string type)
{
   string name = "DJayArrow_" + type + "_" + TimeToString(time);
   if(ObjectFind(0, name) >= 0) return; // Already exists

   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, type + " Signal");
}