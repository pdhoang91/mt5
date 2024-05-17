//+------------------------------------------------------------------+
//|                                                       Breakout.mq5|
//|                        Copyright 2024, MetaQuotes Software Corp.  |
//|                                             https://www.mql5.com  |
//+------------------------------------------------------------------+
#property strict
#include <Trade\Trade.mqh> //Instatiate Trades Execution Library
#include <Trade\OrderInfo.mqh> //Instatiate Library for Orders Information
#include <Trade\PositionInfo.mqh> //Instatiate Library for Positions Information
#include <Trade\SymbolInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;
COrderInfo     m_order; //Library for Orders information


//--- input parameters
input int    BreakoutPeriod = 20;    // Period to calculate breakout levels
input double LotSize        = 0.1;   // Lot size
input int    StopLossPoints = 100;   // Stop Loss in points
input int    TakeProfitPoints = 200; // Take Profit in points

//--- global variables
double HighLevel;
double LowLevel;
bool   BreakoutUp = false;
bool   BreakoutDown = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- initialization
   // Draw initial lines on the chart
   DrawLines();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- remove objects
   ObjectDelete(0, "HighLevelLine");
   ObjectDelete(0, "LowLevelLine");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //--- Calculate breakout levels
   HighLevel = iHigh(_Symbol, PERIOD_M15, iHighest(_Symbol, PERIOD_M15, MODE_HIGH, BreakoutPeriod, 1));
   LowLevel = iLow(_Symbol, PERIOD_M15, iLowest(_Symbol, PERIOD_M15, MODE_LOW, BreakoutPeriod, 1));

   //--- Update lines on the chart
   DrawLines();

   //--- Check for breakout
   double closePrice = iClose(_Symbol, PERIOD_M15, 1);
   if (closePrice > HighLevel)
     {
      BreakoutUp = true;
      BreakoutDown = false;
     }
   else if (closePrice < LowLevel)
     {
      BreakoutDown = true;
      BreakoutUp = false;
     }

   //--- Execute trades
   if (BreakoutUp && PositionsTotal() == 0)
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl = ask - StopLossPoints * _Point;
      double tp = ask + TakeProfitPoints * _Point;
      m_trade.Buy(LotSize, NULL, ask, sl, tp, "Breakout Buy");
      BreakoutUp = false;
     }
   else if (BreakoutDown && PositionsTotal() == 0)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl = bid + StopLossPoints * _Point;
      double tp = bid - TakeProfitPoints * _Point;
      m_trade.Sell(LotSize, NULL, bid, sl, tp, "Breakout Sell");
      BreakoutDown = false;
     }
  }

//+------------------------------------------------------------------+
//| Draw breakout lines on the chart                                 |
//+------------------------------------------------------------------+
void DrawLines()
  {
   //--- Draw high level line
   if (!ObjectFind(0, "HighLevelLine"))
     {
      ObjectCreate(0, "HighLevelLine", OBJ_HLINE, 0, 0, HighLevel);
      ObjectSetInteger(0, "HighLevelLine", OBJPROP_COLOR, clrBlue);
     }
   else
     {
      ObjectSetDouble(0, "HighLevelLine", OBJPROP_PRICE, HighLevel);
     }

   //--- Draw low level line
   if (!ObjectFind(0, "LowLevelLine"))
     {
      ObjectCreate(0, "LowLevelLine", OBJ_HLINE, 0, 0, LowLevel);
      ObjectSetInteger(0, "LowLevelLine", OBJPROP_COLOR, clrRed);
     }
   else
     {
      ObjectSetDouble(0, "LowLevelLine", OBJPROP_PRICE, LowLevel);
     }
  }
