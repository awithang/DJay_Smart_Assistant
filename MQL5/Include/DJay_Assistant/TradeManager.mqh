//+------------------------------------------------------------------+
//|                                                  TradeManager.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"

#include <DJay_Assistant/Definitions.mqh>
#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| Trade Manager Class - Risk & Order Execution                    |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
   CTrade        m_trade;           // Standard MQL5 trade object
   int           m_magic_number;    // Magic number for identification
   double        m_point;           // Symbol point value

   //--- Sniper Update: Sprint 4 - Risk Management State
   bool          m_break_even_triggered[100]; // Track BE status by index (max 100 positions)

public:
   //--- Constructor/Destructor
   CTradeManager();
   ~CTradeManager();

   //--- Initialization
   void Init(int magic_number);

   //--- Risk Calculation
   double CalculateLotSize(double entry_price, double sl_price, double risk_percent);

   //--- Sniper Update: Sprint 4 - Risk Management Automation
   double CalculateDynamicSL(double entry_price, bool is_buy, double atr_points, double atr_multiplier = 1.5);
   void   AutoBreakEven(double break_even_profit_pts = 200.0, double sl_padding_pts = 10.0);
   void   SmartTrail(double atr_points, double trail_multiplier = 1.0, double min_profit_pts = 200.0);

   //--- Order Execution
   bool ExecuteOrder(TradeRequest &req);
   bool ExecuteOrderWithLot(TradeRequest &req);  // Hybrid Mode: Direct lot size support
   bool ExecuteBuy(double price, double sl, double tp, double lot, string comment);
   bool ExecuteSell(double price, double sl, double tp, double lot, string comment);
   bool ExecutePending(ENUM_ORDER_TYPE type, double price, double sl, double tp, double risk_percent, string comment);

   //--- Position Management
   void CloseAllOrders();
   void ClosePositionsBySymbol(ENUM_POSITION_TYPE pos_type);
   void CloseAllSymbolPositions();
   bool ClosePositionByTicket(long ticket);  // Close individual position by ticket
   void ManagePositions(double lock_trigger_pts, double lock_amount_pts, double step_pts);

   //--- Utility Functions
   double GetPositionProfit();
   int    GetOpenPositionsCount();
   bool   HasOpenPosition(string comment_filter);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager()
{
   m_magic_number = 123456;
   m_point = _Point;

   // Initialize break-even tracking array
   ArrayInitialize(m_break_even_triggered, false);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager()
{
}

//+------------------------------------------------------------------+
//| Initialize with magic number                                     |
//+------------------------------------------------------------------+
void CTradeManager::Init(int magic_number)
{
   m_magic_number = magic_number;
   m_trade.SetExpertMagicNumber(m_magic_number);
   m_trade.SetDeviationInPoints(10); // Allow 10 points slippage
   m_trade.SetAsyncMode(true);       // OPTIMIZATION: Async mode for instant UI response
   m_point = _Point;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CTradeManager::CalculateLotSize(double entry_price, double sl_price, double risk_percent)
{
   // Validate inputs with detailed error messages
   if(entry_price == 0)
   {
      Print("Error: Invalid entry price (zero)");
      return 0.0;
   }

   if(sl_price == 0)
   {
      Print("Error: Invalid stop loss price (zero)");
      return 0.0;
   }

   if(risk_percent <= 0)
   {
      Print("Error: Risk percent must be greater than 0%");
      return 0.0;
   }

   if(risk_percent > 10.0)
   {
      Print("Warning: Risk percent capped at 10% (input was ", risk_percent, "%)");
      risk_percent = 10.0;
   }

   // Get account info
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(accountBalance <= 0)
   {
      Print("Error: Invalid account balance");
      return 0.0;
   }

   // Calculate the price difference (stop loss distance)
   double priceDiff = MathAbs(entry_price - sl_price);
   if(priceDiff == 0)
   {
      Print("Error: Entry price and stop loss are the same");
      return 0.0;
   }

   // Validate stop loss distance (minimum 10 points)
   if(priceDiff < _Point * 10)
   {
      Print("Error: Stop loss too close (minimum 10 points)");
      return 0.0;
   }

   // Get symbol info using standard MQL5 constants
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   // Check for failure and print detailed error if data is missing
   if(contractSize == 0 || tickSize == 0 || tickValue == 0)
   {
      // Attempt to refresh symbol info
      SymbolInfoDouble(_Symbol, SYMBOL_BID); // Trigger refresh
      
      // Retry
      contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      
      if(contractSize == 0 || tickSize == 0 || tickValue == 0)
      {
         Print("CRITICAL ERROR: Failed to get Symbol Info for ", _Symbol);
         Print("GetLastError: ", GetLastError());
         Print("ContractSize: ", contractSize, " TickSize: ", tickSize, " TickValue: ", tickValue);
         return 0.0;
      }
   }

   // Calculate risk amount in account currency
   double riskAmount = accountBalance * (risk_percent / 100.0);

   // Calculate the value of one full point movement
   // TickValue is the value of 1 TickSize for 1 Lot.
   // PointValue = (TickValue / TickSize) * _Point => Value of 1 Point for 1 Lot.
   double pointValue = (tickValue / tickSize) * _Point;

   // PointValue sanity check (P1 fix) - Validate for unusual symbols
   if(pointValue < 0.01 || pointValue > 100.0)
   {
      Print("WARNING: Unusual pointValue calculated: ", pointValue,
            ". This may indicate incorrect symbol data or unsupported instrument.");
      Print("DEBUG: TickValue=", tickValue, " TickSize=", tickSize,
            " Point=", _Point, " Symbol=", _Symbol);
      // For safety, use conservative estimate
      pointValue = 1.0;
      Print("SAFETY: Using conservative pointValue = 1.0");
   }

   // Calculate lot size: RiskAmount / (StopLossPoints * PointValue)
   // We DO NOT divide by contractSize because TickValue is already per Lot.
   double slPoints = priceDiff / _Point;
   double lotSize = riskAmount / (slPoints * pointValue);

   // Normalize to symbol's lot step
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   // Validate lot parameters
   if(minLot <= 0 || maxLot <= 0 || lotStep <= 0)
   {
      Print("Error: Invalid lot parameters (min: ", minLot, ", max: ", maxLot, ", step: ", lotStep, ")");
      return 0.0;
   }

   // Round to lot step
   lotSize = MathFloor(lotSize / lotStep) * lotStep;

   // Ensure lot size is within valid range
   if(lotSize < minLot)
   {
      Print("Warning: Lot size adjusted to minimum (", minLot, ")");
      lotSize = minLot;
   }

   if(lotSize > maxLot)
   {
      Print("Warning: Lot size adjusted to maximum (", maxLot, ")");
      lotSize = maxLot;
   }

   // ABSOLUTE SAFETY CAP - Never allow more than 10 lots (P0 fix)
   const double ABSOLUTE_MAX_LOT = 10.0;
   if(lotSize > ABSOLUTE_MAX_LOT)
   {
      Print("CRITICAL: Lot size capped at absolute safety maximum (", ABSOLUTE_MAX_LOT, ") for account safety");
      lotSize = ABSOLUTE_MAX_LOT;
   }

   double finalLot = NormalizeDouble(lotSize, 2);
   Print("Calculated lot size: ", finalLot, " (Balance: $", accountBalance,
         ", Risk: ", risk_percent, "%, SL Distance: ", priceDiff / _Point, " points)");

   return finalLot;
}

//+------------------------------------------------------------------+
//| Execute order from request structure                             |
//+------------------------------------------------------------------+
bool CTradeManager::ExecuteOrder(TradeRequest &req)
{
   // Calculate lot size based on risk
   double lotSize = CalculateLotSize(req.price, req.sl, req.risk_percent);
   if(lotSize <= 0)
   {
      Print("Error: Invalid lot size calculated for order.");
      return false;
   }

   // Free margin validation (P0 fix) - Don't use more than 80% of free margin
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double requiredMargin = lotSize * SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_LONG);

   if(requiredMargin > freeMargin * 0.8)
   {
      Print("ERROR: Lot size requires too much margin. Required: $", requiredMargin,
            " Available: $", freeMargin, " Lot size reduced for safety.");
      // Reduce lot size to fit within 80% margin limit
      lotSize = (freeMargin * 0.8) / SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_LONG);
      // Round to lot step
      double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      lotSize = MathFloor(lotSize / lotStep) * lotStep;
      // Ensure minimum lot
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      if(lotSize < minLot)
         lotSize = minLot;
      Print("Adjusted lot size to: ", lotSize, " lots for margin safety");
   }

   // Execute based on order type
   if(req.type == ORDER_TYPE_BUY)
   {
      return ExecuteBuy(req.price, req.sl, req.tp, lotSize, req.comment);
   }
   else if(req.type == ORDER_TYPE_SELL)
   {
      return ExecuteSell(req.price, req.sl, req.tp, lotSize, req.comment);
   }

   Print("Error: Invalid order type.");
   return false;
}

//+------------------------------------------------------------------+
//| Execute Order with Direct Lot Size Specification                 |
//|                                                                   |
//| This function allows specifying lot size directly instead of   |
//| calculating from risk percentage. Used for fixed lot mode.      |
//|                                                                   |
//| Parameters:                                                       |
//|   req - TradeRequest with lot_size field set (>0)                |
//|                                                                   |
//| Returns:                                                          |
//|   true if order executed successfully                             |
//|   false if failed                                                 |
//+------------------------------------------------------------------+
bool CTradeManager::ExecuteOrderWithLot(TradeRequest &req)
{
   // Validate lot size
   if(req.lot_size <= 0)
   {
      Print("ExecuteOrderWithLot: Invalid lot size (", req.lot_size, ")");
      return false;
   }

   // Validate and normalize lot size
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(minLot <= 0 || maxLot <= 0 || lotStep <= 0)
   {
      Print("Error: Invalid lot parameters (min: ", minLot, ", max: ", maxLot, ", step: ", lotStep, ")");
      return false;
   }

   double lotSize = req.lot_size;

   // Adjust to min/max if needed
   if(lotSize < minLot)
   {
      Print("Warning: Lot size adjusted to minimum (", minLot, ")");
      lotSize = minLot;
   }
   if(lotSize > maxLot)
   {
      Print("Warning: Lot size adjusted to maximum (", maxLot, ")");
      lotSize = maxLot;
   }

   // Round to lot step
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = NormalizeDouble(lotSize, 2);

   // ABSOLUTE SAFETY CAP - Never allow more than 10 lots
   const double ABSOLUTE_MAX_LOT = 10.0;
   if(lotSize > ABSOLUTE_MAX_LOT)
   {
      Print("CRITICAL: Lot size capped at absolute safety maximum (", ABSOLUTE_MAX_LOT, ") for account safety");
      lotSize = ABSOLUTE_MAX_LOT;
   }

   // Free margin validation (P0 fix) - Don't use more than 80% of free margin
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double requiredMargin = lotSize * SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_LONG);

   if(requiredMargin > freeMargin * 0.8)
   {
      Print("ERROR: Lot size requires too much margin. Required: $", requiredMargin,
            " Available: $", freeMargin, " Lot size reduced for safety.");
      // Reduce lot size to fit within 80% margin limit
      lotSize = (freeMargin * 0.8) / SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_LONG);
      // Round to lot step
      lotSize = MathFloor(lotSize / lotStep) * lotStep;
      // Ensure minimum lot
      if(lotSize < minLot)
         lotSize = minLot;
      Print("Adjusted lot size to: ", lotSize, " lots for margin safety");
   }

   // Normalize prices
   double price = NormalizeDouble(req.price, _Digits);
   double sl = NormalizeDouble(req.sl, _Digits);
   double tp = NormalizeDouble(req.tp, _Digits);
   double lot = NormalizeDouble(lotSize, 2);

   // Execute based on order type
   if(req.type == ORDER_TYPE_BUY)
   {
      return ExecuteBuy(price, sl, tp, lot, req.comment);
   }
   else if(req.type == ORDER_TYPE_SELL)
   {
      return ExecuteSell(price, sl, tp, lot, req.comment);
   }

   Print("ExecuteOrderWithLot: Invalid order type");
   return false;
}

//+------------------------------------------------------------------+
//| Execute Buy Order                                                |
//+------------------------------------------------------------------+
bool CTradeManager::ExecuteBuy(double price, double sl, double tp, double lot, string comment)
{
   // Validate inputs
   if(lot <= 0)
   {
      Print("Error: Invalid lot size for Buy order.");
      return false;
   }

   // Normalize values
   price = NormalizeDouble(price, _Digits);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   lot = NormalizeDouble(lot, 2);

   // For Market Execution, prefer sending 0.0 as price to avoid "Invalid Price" errors
   // if the price has moved slightly since the request was made.
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   if(MathAbs(price - currentAsk) < 5 * _Point || price == 0)
      price = 0.0; // Market Order

   // Execute buy order
   if(m_trade.Buy(lot, _Symbol, price, sl, tp, comment))
   {
      Print("Buy order executed: Lot=", lot, " Price=", price, " SL=", sl, " TP=", tp);
      return true;
   }
   else
   {
      int retcode = (int)m_trade.ResultRetcode();
      string retcodeDesc = m_trade.ResultRetcodeDescription();
      long stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      
      Print("CRITICAL ERROR: Buy Order Failed!");
      Print("Return Code: ", retcode, " (", retcodeDesc, ")");
      Print("Request Args: Price=", price, " SL=", sl, " TP=", tp, " Lot=", lot);
      Print("Symbol Info: Ask=", SymbolInfoDouble(_Symbol, SYMBOL_ASK), 
            " Bid=", SymbolInfoDouble(_Symbol, SYMBOL_BID), 
            " StopsLevel=", stopsLevel);
            
      return false;
   }
}

//+------------------------------------------------------------------+
//| Execute Sell Order                                               |
//+------------------------------------------------------------------+
bool CTradeManager::ExecuteSell(double price, double sl, double tp, double lot, string comment)
{
   // Validate inputs
   if(lot <= 0)
   {
      Print("Error: Invalid lot size for Sell order.");
      return false;
   }

   // Normalize values
   price = NormalizeDouble(price, _Digits);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   lot = NormalizeDouble(lot, 2);

   // For Market Execution, prefer sending 0.0 as price
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(MathAbs(price - currentBid) < 5 * _Point || price == 0)
      price = 0.0; // Market Order

   // Execute sell order
   if(m_trade.Sell(lot, _Symbol, price, sl, tp, comment))
   {
      Print("Sell order executed: Lot=", lot, " Price=", price, " SL=", sl, " TP=", tp);
      return true;
   }
   else
   {
      int retcode = (int)m_trade.ResultRetcode();
      string retcodeDesc = m_trade.ResultRetcodeDescription();
      long stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      
      Print("CRITICAL ERROR: Sell Order Failed!");
      Print("Return Code: ", retcode, " (", retcodeDesc, ")");
      Print("Request Args: Price=", price, " SL=", sl, " TP=", tp, " Lot=", lot);
      Print("Symbol Info: Ask=", SymbolInfoDouble(_Symbol, SYMBOL_ASK), 
            " Bid=", SymbolInfoDouble(_Symbol, SYMBOL_BID), 
            " StopsLevel=", stopsLevel);
            
      return false;
   }
}

//+------------------------------------------------------------------+
//| Execute Pending Order                                            |
//+------------------------------------------------------------------+
bool CTradeManager::ExecutePending(ENUM_ORDER_TYPE type, double price, double sl, double tp, double risk_percent, string comment)
{
   // Validate inputs
   if(price <= 0 || sl <= 0 || tp <= 0)
   {
      Print("Error: Invalid price parameters for Pending Order.");
      return false;
   }

   // Calculate lot size based on risk
   double lot = CalculateLotSize(price, sl, risk_percent);
   if(lot <= 0)
   {
      Print("Error: Invalid lot size calculated for Pending Order.");
      return false;
   }

   // Normalize values
   price = NormalizeDouble(price, _Digits);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   lot = NormalizeDouble(lot, 2);

   // Execute pending order
   if(m_trade.OrderOpen(_Symbol, type, lot, price, price, sl, tp, ORDER_TIME_GTC, 0, comment))
   {
      Print("Pending order placed: Type=", EnumToString(type), " Lot=", lot, " Price=", price, " SL=", sl, " TP=", tp);
      return true;
   }
   else
   {
      int retcode = (int)m_trade.ResultRetcode();
      string retcodeDesc = m_trade.ResultRetcodeDescription();
      
      Print("CRITICAL ERROR: Pending Order Failed!");
      Print("Return Code: ", retcode, " (", retcodeDesc, ")");
      Print("Request Args: Type=", EnumToString(type), " Price=", price, " SL=", sl, " TP=", tp, " Lot=", lot);
            
      return false;
   }
}

//+------------------------------------------------------------------+
//| Close all pending orders                                         |
//+------------------------------------------------------------------+
void CTradeManager::CloseAllOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(OrderGetTicket(i)))
      {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol &&
            OrderGetInteger(ORDER_MAGIC) == m_magic_number)
         {
            m_trade.OrderDelete(OrderGetTicket(i));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close positions by type                                          |
//+------------------------------------------------------------------+
void CTradeManager::ClosePositionsBySymbol(ENUM_POSITION_TYPE pos_type)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == m_magic_number &&
            (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == pos_type)
         {
            m_trade.PositionClose(PositionGetTicket(i));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close all positions for current symbol and magic number          |
//+------------------------------------------------------------------+
void CTradeManager::CloseAllSymbolPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == m_magic_number)
         {
            m_trade.PositionClose(PositionGetTicket(i));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close individual position by ticket                              |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePositionByTicket(long ticket)
{
   if(ticket <= 0)
   {
      Print("Error: Invalid ticket number");
      return false;
   }

   if(PositionSelectByTicket(ticket))
   {
      // Verify it's our position
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == m_magic_number)
      {
         if(m_trade.PositionClose(ticket))
         {
            Print("Position #", ticket, " closed successfully");
            return true;
         }
         else
         {
            Print("Failed to close position #", ticket);
            return false;
         }
      }
      else
      {
         Print("Error: Position #", ticket, " does not belong to this EA");
         return false;
      }
   }
   else
   {
      Print("Error: Position #", ticket, " not found");
      return false;
   }
}

//+------------------------------------------------------------------+
//| Manage Positions - Ladder Logic (Stepped Profit Lock)           |
//+------------------------------------------------------------------+
//| Implements a "Ladder" or "Stepped" Profit Lock system.          |
//| Instead of a standard trailing stop, this locks in specific     |
//| profit levels based on milestones.                              |
//|                                                                  |
//| Parameters:                                                      |
//|   lock_trigger_pts - Profit trigger in points (e.g., 200 = 20 pips)|
//|   lock_amount_pts  - Initial lock amount in points (e.g., 50 = 5 pips)|
//|   step_pts         - Step size in points (e.g., 100 = 10 pips)   |
//|                                                                  |
//| Logic:                                                           |
//|   1. When profit >= trigger: Lock SL at OpenPrice + lock_amount  |
//|   2. For each additional step beyond trigger: Move SL up by step |
//|      Formula: NewSL = BaseLockSL + (StepsClimbed * step_pts)    |
//|   3. This maintains a constant buffer from the trigger level    |
//+------------------------------------------------------------------+
void CTradeManager::ManagePositions(double lock_trigger_pts, double lock_amount_pts, double step_pts)
{
   // Validate inputs
   if(lock_trigger_pts <= 0 || lock_amount_pts <= 0 || step_pts <= 0)
      return;

   // Convert points to price values
   double lockTrigger = lock_trigger_pts * _Point;
   double lockAmount = lock_amount_pts * _Point;
   double stepSize = step_pts * _Point;

   // Iterate through all positions (single pass for performance)
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         // Filter: Only process positions for our symbol and magic number
         if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
            PositionGetInteger(POSITION_MAGIC) != m_magic_number)
            continue;

         ulong ticket = PositionGetTicket(i);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL = PositionGetDouble(POSITION_SL);
         double currentTP = PositionGetDouble(POSITION_TP);
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         // Get current price based on position type
         double currentPrice = SymbolInfoDouble(_Symbol,
            (posType == POSITION_TYPE_BUY) ? SYMBOL_BID : SYMBOL_ASK);

         // Calculate current profit in price units (positive = in profit)
         double currentProfit = 0.0;
         if(posType == POSITION_TYPE_BUY)
            currentProfit = currentPrice - openPrice;  // BUY: Profit when price > open
         else
            currentProfit = openPrice - currentPrice;  // SELL: Profit when price < open

         //============================================================
         // LADDER LOGIC: Only activate if we've reached the trigger
         //============================================================
         if(currentProfit >= lockTrigger)
         {
            double newTargetSL = 0.0;

            if(posType == POSITION_TYPE_BUY)
            {
               //=========================================================
               // BUY LADDER LOGIC
               //=========================================================
               // 1. Calculate Base Lock SL (Foundation)
               double baseLockSL = openPrice + lockAmount;

               // 2. Calculate how many "Steps" we have climbed BEYOND the trigger
               double profitBeyondTrigger = currentProfit - lockTrigger;
               int stepsClimbed = (int)MathFloor(profitBeyondTrigger / stepSize);

               // 3. Calculate New Target SL: BaseSL + (Steps * StepDistance)
               double stepGain = stepsClimbed * stepSize;
               newTargetSL = baseLockSL + stepGain;

               // 4. Apply if better than current SL (or no SL exists)
               if(newTargetSL > currentSL || currentSL == 0)
               {
                  newTargetSL = NormalizeDouble(newTargetSL, _Digits);
                  if(m_trade.PositionModify(ticket, newTargetSL, currentTP))
                  {
                     // Optional: Debug logging
                     // Print("Ladder BUY #", ticket, " Step ", stepsClimbed, " SL: ", currentSL, " -> ", newTargetSL);
                  }
               }
            }
            else // POSITION_TYPE_SELL
            {
               //=========================================================
               // SELL LADDER LOGIC (Inverted)
               //=========================================================
               // 1. Calculate Base Lock SL (Foundation) - moves DOWN
               double baseLockSL = openPrice - lockAmount;

               // 2. Calculate how many "Steps" we have climbed BEYOND the trigger
               double profitBeyondTrigger = currentProfit - lockTrigger;
               int stepsClimbed = (int)MathFloor(profitBeyondTrigger / stepSize);

               // 3. Calculate New Target SL: BaseSL - (Steps * StepDistance)
               //    For SELL, SL moves DOWN as profit increases
               double stepGain = stepsClimbed * stepSize;
               newTargetSL = baseLockSL - stepGain;

               // 4. Apply if better than current SL (or no SL exists)
               //    For SELL, "better" means LOWER price
               if(newTargetSL < currentSL || currentSL == 0)
               {
                  newTargetSL = NormalizeDouble(newTargetSL, _Digits);
                  if(m_trade.PositionModify(ticket, newTargetSL, currentTP))
                  {
                     // Optional: Debug logging
                     // Print("Ladder SELL #", ticket, " Step ", stepsClimbed, " SL: ", currentSL, " -> ", newTargetSL);
                  }
               }
            }
         }
      }
   }
}


//+------------------------------------------------------------------+
//| Get total profit from all open positions                         |
//+------------------------------------------------------------------+
double CTradeManager::GetPositionProfit()
{
   double totalProfit = 0.0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == m_magic_number)
         {
            totalProfit += PositionGetDouble(POSITION_PROFIT);
         }
      }
   }

   return totalProfit;
}

//+------------------------------------------------------------------+
//| Get count of open positions                                      |
//+------------------------------------------------------------------+
int CTradeManager::GetOpenPositionsCount()
{
   int count = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == m_magic_number)
         {
            count++;
         }
      }
   }

   return count;
}

//+------------------------------------------------------------------+
//| Check if open position exists with specific comment substring    |
//+------------------------------------------------------------------+
bool CTradeManager::HasOpenPosition(string comment_filter)
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == m_magic_number)
         {
            string comment = PositionGetString(POSITION_COMMENT);
            if(StringFind(comment, comment_filter) >= 0)
               return true;
         }
      }
   }
   return false;
}

//+====================================================================+
//| SNIPER UPDATE: Sprint 4 - Risk Management Automation                |
//+====================================================================+

//+------------------------------------------------------------------+
//| Calculate Dynamic Stop Loss (ATR-Based)                            |
//| Calculates SL based on market volatility (ATR)                     |
//|                                                                   |
//| Parameters:                                                       |
//|   entry_price - Entry price of the trade                           |
//|   is_buy - true for BUY, false for SELL                            |
//|   atr_points - ATR value in points                                 |
//|   atr_multiplier - Multiplier for SL (default 1.5x ATR)            |
//|                                                                   |
//| Returns: SL price                                                 |
//+------------------------------------------------------------------+
double CTradeManager::CalculateDynamicSL(double entry_price, bool is_buy, double atr_points, double atr_multiplier = 1.5)
{
   // Validate inputs
   if(entry_price <= 0)
   {
      Print("CalculateDynamicSL: Invalid entry price");
      return 0;
   }

   if(atr_points <= 0)
   {
      Print("CalculateDynamicSL: Invalid ATR value (", atr_points, "), using default 100 points");
      atr_points = 100.0;
   }

   if(atr_multiplier <= 0)
   {
      Print("CalculateDynamicSL: Invalid multiplier, using default 1.5");
      atr_multiplier = 1.5;
   }

   // Calculate SL distance in price units
   double sl_distance = atr_points * atr_multiplier * _Point;

   // Calculate SL price based on direction
   double sl_price;
   if(is_buy)
   {
      // For BUY: SL is below entry
      sl_price = entry_price - sl_distance;
   }
   else
   {
      // For SELL: SL is above entry
      sl_price = entry_price + sl_distance;
   }

   // Normalize to symbol digits
   sl_price = NormalizeDouble(sl_price, _Digits);

   return sl_price;
}

//+------------------------------------------------------------------+
//| Auto Break-Even                                                    |
//| Moves SL to entry price + padding when profit threshold is reached |
//|                                                                   |
//| Parameters:                                                       |
//|   break_even_profit_pts - Profit trigger in points (default 200)  |
//|   sl_padding_pts - SL padding in points (default 10)              |
//|                                                                   |
//| Logic:                                                            |
//|   1. Check each position for profit level                         |
//|   2. If profit >= trigger AND BE not yet triggered:              |
//|      - Move SL to Open + Padding (protect small profit)           |
//|      - Mark position as BE triggered                              |
//+------------------------------------------------------------------+
void CTradeManager::AutoBreakEven(double break_even_profit_pts = 200.0, double sl_padding_pts = 10.0)
{
   // Validate inputs
   if(break_even_profit_pts <= 0 || sl_padding_pts < 0)
      return;

   // Convert points to price
   double beTrigger = break_even_profit_pts * _Point;
   double slPadding = sl_padding_pts * _Point;

   // Get current positions count (limit to array size)
   int totalPos = MathMin(PositionsTotal(), 100);

   for(int i = 0; i < totalPos; i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         // Filter: Only our positions
         if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
            PositionGetInteger(POSITION_MAGIC) != m_magic_number)
            continue;

         ulong ticket = PositionGetTicket(i);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL = PositionGetDouble(POSITION_SL);
         double currentTP = PositionGetDouble(POSITION_TP);
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         // Get current price
         double currentPrice = SymbolInfoDouble(_Symbol,
            (posType == POSITION_TYPE_BUY) ? SYMBOL_BID : SYMBOL_ASK);

         // Calculate current profit
         double currentProfit = 0.0;
         if(posType == POSITION_TYPE_BUY)
            currentProfit = currentPrice - openPrice;
         else
            currentProfit = openPrice - currentPrice;

         // Check if BE already triggered for this position
         if(m_break_even_triggered[i])
            continue; // Skip if already done

         // Check profit trigger
         if(currentProfit >= beTrigger)
         {
            // Calculate new SL (Open + Padding)
            double newSL;
            if(posType == POSITION_TYPE_BUY)
               newSL = openPrice + slPadding;
            else
               newSL = openPrice - slPadding;

            newSL = NormalizeDouble(newSL, _Digits);

            // Only modify if new SL is better than current
            bool shouldModify = false;
            if(posType == POSITION_TYPE_BUY)
               shouldModify = (newSL > currentSL || currentSL == 0);
            else
               shouldModify = (newSL < currentSL || currentSL == 0);

            if(shouldModify)
            {
               if(m_trade.PositionModify(ticket, newSL, currentTP))
               {
                  m_break_even_triggered[i] = true; // Mark as triggered
                  Print("Auto Break-Even #", ticket, " SL: ", DoubleToString(currentSL, _Digits),
                        " -> ", DoubleToString(newSL, _Digits), " (Profit: ", DoubleToString(currentProfit/_Point, 0), " pts)");
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Smart Trail (ATR-Based Trailing Stop)                             |
//| Trailing stop based on ATR to maximize runners                    |
//|                                                                   |
//| Parameters:                                                       |
//|   atr_points - Current ATR value in points                         |
//|   trail_multiplier - Trail distance multiplier (default 1.0x ATR)  |
//|   min_profit_pts - Minimum profit before trail activates          |
//|                                                                   |
//| Logic:                                                            |
//|   1. Only trail if profit >= min_profit_pts                       |
//|   2. Trail distance = ATR * multiplier                            |
//|   3. For BUY: SL = Price - TrailDist                              |
//|   4. For SELL: SL = Price + TrailDist                             |
//|   5. Only modify if new SL is better (not worse)                  |
//+------------------------------------------------------------------+
void CTradeManager::SmartTrail(double atr_points, double trail_multiplier = 1.0, double min_profit_pts = 200.0)
{
   // Validate inputs
   if(atr_points <= 0 || trail_multiplier <= 0 || min_profit_pts < 0)
      return;

   // Convert points to price
   double minProfit = min_profit_pts * _Point;
   double trailDist = atr_points * trail_multiplier * _Point;

   // Minimum trail distance (prevent tight stops)
   double minTrail = 50 * _Point; // Minimum 50 points
   if(trailDist < minTrail)
      trailDist = minTrail;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         // Filter: Only our positions
         if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
            PositionGetInteger(POSITION_MAGIC) != m_magic_number)
            continue;

         ulong ticket = PositionGetTicket(i);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL = PositionGetDouble(POSITION_SL);
         double currentTP = PositionGetDouble(POSITION_TP);
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         // Get current price
         double currentPrice = SymbolInfoDouble(_Symbol,
            (posType == POSITION_TYPE_BUY) ? SYMBOL_BID : SYMBOL_ASK);

         // Calculate current profit
         double currentProfit = 0.0;
         if(posType == POSITION_TYPE_BUY)
            currentProfit = currentPrice - openPrice;
         else
            currentProfit = openPrice - currentPrice;

         // Check minimum profit requirement
         if(currentProfit < minProfit)
            continue; // Skip - not enough profit to trail

         // Calculate new trailing SL
         double newSL;
         if(posType == POSITION_TYPE_BUY)
         {
            // BUY: Trail below current price
            newSL = currentPrice - trailDist;
         }
         else
         {
            // SELL: Trail above current price
            newSL = currentPrice + trailDist;
         }

         newSL = NormalizeDouble(newSL, _Digits);

         // Only modify if new SL is better than current
         bool shouldModify = false;
         if(posType == POSITION_TYPE_BUY)
            shouldModify = (newSL > currentSL || currentSL == 0);
         else
            shouldModify = (newSL < currentSL || currentSL == 0);

         if(shouldModify)
         {
            if(m_trade.PositionModify(ticket, newSL, currentTP))
            {
               // Optional: Debug logging (commented out for performance)
               // Print("SmartTrail #", ticket, " SL: ", DoubleToString(currentSL, _Digits),
               //       " -> ", DoubleToString(newSL, _Digits), " (Profit: ", DoubleToString(currentProfit/_Point, 0), " pts)");
            }
         }
      }
   }
}

//+------------------------------------------------------------------+