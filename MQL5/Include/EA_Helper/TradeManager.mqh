//+------------------------------------------------------------------+
//|                                                  TradeManager.mqh |
//|                                    Copyright 2025, EA Helper Project |
//|                                             https://ea-helper.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EA Helper Project"
#property link      "https://ea-helper.com"
#property version   "1.00"
#property strict

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

   //--- Position Management
   void CloseAllOrders();
   void ClosePositionsBySymbol(ENUM_POSITION_TYPE pos_type);
   void TrailingStop(double trailing_points);

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

   // Get symbol info
   long contractSize = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   // Validate symbol data
   if(contractSize == 0 || tickSize == 0 || tickValue == 0)
   {
      Print("Error: Invalid symbol data (contract size: ", contractSize,
            ", tick size: ", tickSize, ", tick value: ", tickValue, ")");
      return 0.0;
   }

   // Calculate risk amount in account currency
   double riskAmount = accountBalance * (risk_percent / 100.0);

   // Calculate the value of one full point movement
   double pointValue = (tickValue / tickSize) * _Point;

   // Calculate lot size: RiskAmount / (StopLossPoints * PointValue * ContractSize)
   double slPoints = priceDiff / _Point;
   double lotSize = riskAmount / (slPoints * pointValue * contractSize);

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
         ", Risk: ", riskPercent, "%, SL Distance: ", priceDiff / _Point, " points)");

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

   // Check if price is valid (0 means market order)
   if(price == 0)
      price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // Execute buy order
   if(m_trade.Buy(lot, _Symbol, price, sl, tp, comment))
   {
      Print("Buy order executed: Lot=", lot, " Price=", price, " SL=", sl, " TP=", tp);
      return true;
   }
   else
   {
      Print("Error executing Buy order: ", m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
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

   // Check if price is valid (0 means market order)
   if(price == 0)
      price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Execute sell order
   if(m_trade.Sell(lot, _Symbol, price, sl, tp, comment))
   {
      Print("Sell order executed: Lot=", lot, " Price=", price, " SL=", sl, " TP=", tp);
      return true;
   }
   else
   {
      Print("Error executing Sell order: ", m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
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
