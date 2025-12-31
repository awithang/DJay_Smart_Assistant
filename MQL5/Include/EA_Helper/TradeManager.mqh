//+------------------------------------------------------------------+
//|                                                  TradeManager.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"

#include <EA_Helper/Definitions.mqh>
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

public:
   //--- Constructor/Destructor
   CTradeManager();
   ~CTradeManager();

   //--- Initialization
   void Init(int magic_number);

   //--- Risk Calculation
   double CalculateLotSize(double entry_price, double sl_price, double risk_percent);

   //--- Order Execution
   bool ExecuteOrder(TradeRequest &req);
   bool ExecuteBuy(double price, double sl, double tp, double lot, string comment);
   bool ExecuteSell(double price, double sl, double tp, double lot, string comment);
   bool ExecutePending(ENUM_ORDER_TYPE type, double price, double sl, double tp, double risk_percent, string comment);

   //--- Position Management
   void CloseAllOrders();
   void ClosePositionsBySymbol(ENUM_POSITION_TYPE pos_type);
   void TrailingStop(double trailing_points);
   void SmartProfitLock(double trigger_percent, double lock_percent);

   //--- Utility Functions
   double GetPositionProfit();
   int    GetOpenPositionsCount();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager()
{
   m_magic_number = 123456;
   m_point = _Point;
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
//| Apply trailing stop to open positions                            |
//+------------------------------------------------------------------+
void CTradeManager::TrailingStop(double trailing_points)
{
   if(trailing_points <= 0) return;

   double trailingPoints = trailing_points * _Point;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == m_magic_number)
         {
            ulong ticket = PositionGetTicket(i);
            double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double posSL = PositionGetDouble(POSITION_SL);
            double posTP = PositionGetDouble(POSITION_TP);
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double currentPrice = SymbolInfoDouble(_Symbol,
               (posType == POSITION_TYPE_BUY) ? SYMBOL_BID : SYMBOL_ASK);

            if(posType == POSITION_TYPE_BUY)
            {
               // Trailing for Buy positions
               double newSL = currentPrice - trailingPoints;
               if(newSL > posSL)
               {
                  m_trade.PositionModify(ticket, newSL, posTP);
               }
            }
            else if(posType == POSITION_TYPE_SELL)
            {
               // Trailing for Sell positions
               double newSL = currentPrice + trailingPoints;
               if((posSL == 0 || newSL < posSL) && newSL != 0)
               {
                  m_trade.PositionModify(ticket, newSL, posTP);
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
//| Smart Profit Lock (Step Trailing based on % of TP)               |
//+------------------------------------------------------------------+
void CTradeManager::SmartProfitLock(double trigger_percent, double lock_percent)
{
   if(trigger_percent <= 0 || lock_percent < 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == m_magic_number)
         {
            ulong ticket = PositionGetTicket(i);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double tp = PositionGetDouble(POSITION_TP);
            double sl = PositionGetDouble(POSITION_SL);
            
            // Requires TP to calculate percentage
            if(tp == 0) continue; 
            
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double currentPrice = SymbolInfoDouble(_Symbol, (type == POSITION_TYPE_BUY) ? SYMBOL_BID : SYMBOL_ASK);
            
            double totalDist = MathAbs(tp - openPrice);
            if(totalDist == 0) continue;
            
            double currentDist = MathAbs(currentPrice - openPrice);
            double progress = (currentDist / totalDist) * 100.0;
            
            // Check if price moved in the right direction
            bool isProfit = false;
            if(type == POSITION_TYPE_BUY && currentPrice > openPrice) isProfit = true;
            if(type == POSITION_TYPE_SELL && currentPrice < openPrice) isProfit = true;
            
            if(isProfit && progress >= trigger_percent)
            {
               // Calculate Lock Price (e.g. 30% of way to TP)
               double lockDist = totalDist * (lock_percent / 100.0);
               double newSL = 0.0;
               
               if(type == POSITION_TYPE_BUY)
               {
                  newSL = openPrice + lockDist;
                  // Only modify if new SL is higher (better) than current
                  if(newSL > sl)
                  {
                     m_trade.PositionModify(ticket, newSL, tp);
                     Print("Smart Lock Triggered (Buy): Progress=", DoubleToString(progress, 1), "%, NewSL=", newSL);
                  }
               }
               else if(type == POSITION_TYPE_SELL)
               {
                  newSL = openPrice - lockDist;
                  // Only modify if new SL is lower (better) than current (or SL is 0)
                  if(sl == 0 || newSL < sl)
                  {
                     m_trade.PositionModify(ticket, newSL, tp);
                     Print("Smart Lock Triggered (Sell): Progress=", DoubleToString(progress, 1), "%, NewSL=", newSL);
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
