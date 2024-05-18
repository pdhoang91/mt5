//+------------------------------------------------------------------+
//|                                               TurtleStrategy.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh> //Instatiate Trades Execution Library
#include <Trade\OrderInfo.mqh> //Instatiate Library for Orders Information
#include <Trade\PositionInfo.mqh> //Instatiate Library for Positions Information
#include <Trade\SymbolInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;
COrderInfo     m_order; //Library for Orders information


input group "General Settings"
// Bollinger Bands: period for average line calculation
input    ENUM_TIMEFRAMES TimeFrame = PERIOD_H1;
input    double Lots = 1;
input double AtrEntryFactor = 0.5;
input double AtrTpFactor = 2.0;
input double AtrSlFactor = 1.0;
input ulong Magic = 686868;


input group "Indicator Settings"
input    ENUM_TIMEFRAMES MaTimeFrame = PERIOD_H1;
input    int MaPriods = 100;
input    ENUM_MA_METHOD MaMethod = MODE_SMA;
input ENUM_APPLIED_PRICE MaAppPrice = PRICE_CLOSE;

input ENUM_TIMEFRAMES AtrTimeFrame = PERIOD_H1;
input int AtrPeriods = 14;
// global variable
int handleMa, handlerAtr;
int barsTotal;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
// init the indicator  handler
   handleMa = iMA(_Symbol,MaTimeFrame,MaPriods,0,MaMethod,MaAppPrice);
   handlerAtr = iATR(_Symbol,AtrTimeFrame,AtrPeriods);
//init the barsTotal  variable so the first order will be plaaced with a new bar
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int bars = iBars(_Symbol, TimeFrame);
   if(barsTotal != bars)
     {
      barsTotal = bars;

      double ma[];
      CopyBuffer(handleMa,MAIN_LINE,1,1,ma);

      double atr[];
      CopyBuffer(handlerAtr,MAIN_LINE,1,1,atr);

      // get bid and ask price
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);


      // find the ma trend direction
      int counter = 0;
      for(int i = PositionsTotal() -1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Magic() == Magic)
              {
               counter++;
              }
           }
        }

      // check number order
      if(counter == 0)
        {
         // check for buy trend
         if(bid > ma[0])
           {
            // caculate order parameter
            double entry =   ask - atr[0] *AtrEntryFactor;
            double TP =   entry + atr[0] *AtrTpFactor;
            double SL =   entry - atr[0] *AtrSlFactor;
            datetime expiredTime = iTime(_Symbol,TimeFrame,0) + PeriodSeconds(TimeFrame);
            m_trade.BuyLimit(Lots,entry,_Symbol,SL,TP,ORDER_TIME_SPECIFIED_DAY,expiredTime);
           }
         else
            if(bid < ma[0]) // check for sell trend
              {
               // check for sell trend
               // caculate order parameter
               double entry =   bid - atr[0] *AtrEntryFactor;
               double TP =   entry - atr[0] *AtrTpFactor;
               double SL =   entry + atr[0] *AtrSlFactor;
               datetime expiredTime = iTime(_Symbol,TimeFrame,0) + PeriodSeconds(TimeFrame);
               m_trade.SellLimit(Lots,entry,_Symbol,SL,TP,ORDER_TIME_SPECIFIED_DAY,expiredTime);
              }
        }


     }
  }
//+------------------------------------------------------------------+
