//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                       BetaMT.mq5 |
//|                                          Copyright 2020, Another |
//|                                              pdhoang91@gmail.com |
//|//////////////////////////////////////////////////////////////////|
//|//////////////////////pdhoang91@gmail.com//////////|
//|//////////////////////////////////////////////////////////////////|
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Another"
#property link "pdhoang91@gmail.com"
#property version "1.0"
#property strict
#include <Trade\Trade.mqh> //Instatiate Trades Execution Library
#include <Trade\OrderInfo.mqh> //Instatiate Library for Orders Information
#include <Trade\PositionInfo.mqh> //Instatiate Library for Positions Information
#include <Trade\SymbolInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;
COrderInfo     m_order; //Library for Orders information


double         ExtStopLoss=0;
double         ExtTakeProfit=0;

int            handle_iStochastic;           // variable for storing the handle of the iStochastic indicator
int            handle_iBands_teeth;          // variable for storing the handle of the iBands indicator
int            handle_iBands_jaws;           // variable for storing the handle of the iBands indicator
int            handle_iBands_lips;           // variable for storing the handle of the iBands indicator
int            handle_iRSI;                  // variable for storing the handle of the iRSI indicator
double         m_adjusted_point;             // point value adjusted for 3 or 5 points


#define MAGICMA 686868

enum ENUM_TYPE_ENTER
  {
   enter_between_yellow_and_blue=0,    // enter between yellow and blue
   enter_between_blue_and_red=1,       // enter between blue and red
   enter_yellow_line=2,                // yellow line enter
   enter_blue_line=3,                  // blue line enter
   enter_red_line=4,                   // red line enter
  };
//+------------------------------------------------------------------+
//| Enum type of closing by reverse touch                            |
//+------------------------------------------------------------------+
enum ENUM_TYPE_CLOSURE
  {
   closing_middle_line=0,              // middle line closure
   closing_between_yellow_and_blue=1,  // closing between yellow and blue
   closing_between_blue_and_red=2,     // closing between blue and red
   closing_yellow_line=3,              // yellow line closing
   closing_blue_line=4,                // blue line closing
   closing_red_line=5,                 // red line closing
  };
//--- input parameters
input ENUM_TYPE_ENTER   enter          = enter_between_yellow_and_blue;
input int               bands_period   = 140;                     // Bollinger Bands: period for average line calculation
input double            deviation_teeth= 2.0;                     // Bollinger Bands: number of standard deviations
input bool              RSIFilter      = false;                   // RSI filter
input int               rsi_ma_period  = 8;                       // RSI: averaging period
input int               rsi_lower_level= 70;                      // RSI lower level (100-80)
input bool              StohasticFilter= true;                    // Stohastic filter
input int               sto_Kperiod    = 20;                      // Stohastic: the K period (the number of bars for calculation)
input int               sto_lower_level= 95;                      // Stohastic lower level (100-80)
input ENUM_TYPE_CLOSURE closure        = closing_between_blue_and_red;
input int               bar_shift          = 1;                   // Bar index
input bool              OnlyOnePosition= true;                    // Only one position
input double            InpLots        = 0.1;                     // Lots
input ushort            InpStopLoss    = 200;                     // Stop Loss (in pips)
input ushort            InpTakeProfit  = 200;                     // Take Profit (in pips)
input ulong             m_magic        = 143279874;               // Magic number

input double Min_Profit = 5.0;
input double SL = 50.0;
input double TP = 50.0;

int INPUT_CORNER = 1;
int INPUT_X_DISTANCE = 0;
int INPUT_Y_DISTANCE = 0;
int INPUT_X_SIZE = 120;
int INPUT_Y_SIZE = 30;
int INPUT_FONT_SIZE = 10;


string NAME_BUTTON_1 = "SetSLToEntry";
string TEXT_BUTTON_1 = "SetSLToEntry";

string NAME_BUTTON_2 = "CloseIfLose";
string TEXT_BUTTON_2 = "CloseIfLose";

string NAME_BUTTON_3 = "Exit";
string TEXT_BUTTON_3 = "Exit";

string NAME_BUTTON_4 = "CloseAllBuy";
string TEXT_BUTTON_4 = "CloseAllBuy";

string NAME_BUTTON_5 = "CloseAllSell";
string TEXT_BUTTON_5 = "CloseAllSell";

string NAME_BUTTON_6 = "CloseAll";
string TEXT_BUTTON_6 = "CloseAllOrder";

string NAME_BUTTON_7 = "SetSL";
string TEXT_BUTTON_7 = "SetSL";

string NAME_BUTTON_8 = "SetTP";
string TEXT_BUTTON_8 = "SetTP";

string NAME_BUTTON_9 = "INPUT";
string TEXT_BUTTON_9 = "10";


// Indicator Data Structure
struct Indicator
  {
   // KD indicator
   double            StocMain;
   double            StocSignal;
   // KD overbought and oversold
   bool              IsOverBuy;
   bool              IsOverSell;

   // Bollinger Bands indicator
   double            BollUpper;
   double            BollLower;
   double            BollMain;

   // buy long signal
   bool              IsBuySignal;
   // short selling signal
   bool              IsSellSignal;

   double            buyHight;
   double            sellLow;
  };

// Order statistics
struct Counter
  {
   int               BuyTotal;
   int               SellTotal;
   double            PointTotal;
   double            ProfitTotal;
   double            BuyProfit;
   double            SellProfit;
   double            LastSellLots;
   double            LastBuyLots;
   int               BarsDelta;

   double            LastSellPrice;
   double            LastBuyPrice;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   DrawDashBoard();
   DrawLable();
   DrawInfor();

   return (INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) {}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   Indicator ind = CalcInd();
//Counter counter = CalcTotal();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Indicator CalcInd()
  {
   Indicator ind = {};


   ind.BollUpper = iBands(_Symbol, PERIOD_M5, 100, 2, 0, PRICE_CLOSE);
   ind.BollLower = iBands(_Symbol, PERIOD_M5, 100, 2, 0, PRICE_CLOSE);
   ind.BollMain = iBands(_Symbol, PERIOD_M5, 100, 2, 0, PRICE_CLOSE);

//--- create handle of the indicator iStochastic
   handle_iStochastic=iStochastic(m_symbol.Name(),Period(),sto_Kperiod,3,3,MODE_SMA,STO_LOWHIGH);
//--- if the handle is not created
   if(handle_iStochastic==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iStochastic indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      //return(INIT_FAILED);
     }
//--- create handle of the indicator iBands
   handle_iBands_teeth=iBands(m_symbol.Name(),Period(),bands_period,0,deviation_teeth,PRICE_CLOSE);
//--- if the handle is not created
   if(handle_iBands_teeth==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      // return(INIT_FAILED);
     }
//--- create handle of the indicator iBands
   handle_iBands_jaws=iBands(m_symbol.Name(),Period(),bands_period,0,deviation_teeth/2.0,PRICE_CLOSE);
//--- if the handle is not created
   if(handle_iBands_jaws==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      // return(INIT_FAILED);
     }
//--- create handle of the indicator iBands
   handle_iBands_lips=iBands(m_symbol.Name(),Period(),bands_period,0,deviation_teeth*2.0,PRICE_CLOSE);
//--- if the handle is not created
   if(handle_iBands_lips==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      //return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI=iRSI(m_symbol.Name(),Period(),rsi_ma_period,PRICE_CLOSE);
//--- if the handle is not created
   if(handle_iRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      //return(INIT_FAILED);
     }

   double upper_teeth=iBandsGet(handle_iBands_teeth,UPPER_BAND,bar_shift);
   double base_teeth=iBandsGet(handle_iBands_teeth,BASE_LINE,bar_shift);
   double lower_teeth=iBandsGet(handle_iBands_teeth,LOWER_BAND,bar_shift);

   double upper_jaws=iBandsGet(handle_iBands_jaws,UPPER_BAND,bar_shift);
   double lower_jaws=iBandsGet(handle_iBands_jaws,LOWER_BAND,bar_shift);

   double upper_lips=iBandsGet(handle_iBands_lips,UPPER_BAND,bar_shift);
   double lower_lips=iBandsGet(handle_iBands_lips,LOWER_BAND,bar_shift);

   double rsi=0.0;
   if(RSIFilter)
      rsi=iRSIGet(bar_shift);

   double stohastic=0.0;
   if(StohasticFilter)
      stohastic=iStochasticGet(MAIN_LINE,bar_shift);

   double enterpriceBuy=0.0,enterpriceSell=0.0,priceclosebuy=0.0,proceclosesell=0.0;
   switch(enter)
     {
      case  enter_between_yellow_and_blue:
         enterpriceBuy=upper_teeth+((upper_jaws-upper_teeth)/2);
         enterpriceSell=lower_teeth-((lower_teeth-lower_jaws)/2);
         break;
      case  enter_between_blue_and_red:
         enterpriceBuy=upper_jaws+((upper_lips-upper_jaws)/2);
         enterpriceSell=lower_jaws-((lower_jaws-lower_lips)/2);
         break;
      case enter_yellow_line:
         enterpriceBuy=upper_teeth;
         enterpriceSell=lower_teeth;
         break;
      case enter_blue_line:
         enterpriceBuy=upper_jaws;
         enterpriceSell=upper_jaws;
         break;
      case enter_red_line:
         enterpriceBuy=upper_lips;
         enterpriceSell=lower_lips;
         break;
     }

   if((closure==closing_between_yellow_and_blue && enter==enter_between_yellow_and_blue) ||
      (closure==closing_between_blue_and_red && enter==enter_between_blue_and_red))
     {
      priceclosebuy=enterpriceSell;
      proceclosesell=enterpriceBuy;
     }
   else
     {
      priceclosebuy=lower_jaws-((lower_jaws-lower_lips)/2.0);
      proceclosesell=upper_jaws+((upper_lips-upper_jaws)/2.0);
     }

   if(m_symbol.Ask()<=enterpriceSell && RSIFilter==0 && StohasticFilter==0)
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
      // OpenBuy(sl,tp);
      ind.IsBuySignal = true;
      //ind.IsSellSignal = true
     }
   if(m_symbol.Bid()>=enterpriceBuy && RSIFilter==0 && StohasticFilter==0)
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
      //OpenSell(sl,tp);
      ind.IsSellSignal = true;
     }

   if(m_symbol.Bid()>=enterpriceBuy && (RSIFilter==1 && rsi>=rsi_lower_level) && StohasticFilter==0)
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
      //OpenSell(sl,tp);
      ind.IsSellSignal = true;
     }
   if(m_symbol.Ask()<=enterpriceSell  && (RSIFilter==1 && rsi<=(100-rsi_lower_level)) && StohasticFilter==0)
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
      //OpenBuy(sl,tp);
      ind.IsBuySignal = true;
     }

   if(m_symbol.Bid()>=enterpriceBuy  && RSIFilter==0 && (StohasticFilter==1 && stohastic>sto_lower_level))
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
      // OpenSell(sl,tp);
      // OpenSell(sl,tp);
      ind.IsSellSignal = true;
     }
   if(m_symbol.Ask()<=enterpriceSell  && RSIFilter==0 && (StohasticFilter==1 && stohastic<(100-sto_lower_level)))
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
      //OpenBuy(sl,tp);
      // OpenBuy(sl,tp);
      ind.IsBuySignal = true;
     }

   if(m_symbol.Bid()>=enterpriceBuy && (RSIFilter==1 && rsi>=rsi_lower_level) && (StohasticFilter==1 && stohastic>sto_lower_level))
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
      // OpenSell(sl,tp);
      ind.IsSellSignal = true;
     }
   if(m_symbol.Ask()<=enterpriceSell && (RSIFilter==1 && rsi<=(100-rsi_lower_level)) && (StohasticFilter==1 && stohastic<(100-sto_lower_level)))
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
      //OpenBuy(sl,tp);
      ind.IsBuySignal = true;
     }


//  ind.IsBuySignal = SymbolInfoDouble(_Symbol, SYMBOL_ASK) > ind.buyHight &&  !ind.IsOverBuy;
//  ind.IsSellSignal = SymbolInfoDouble(_Symbol, SYMBOL_BID) < ind.sellLow &&  !ind.IsOverSell;
//ind.IsBuySignal = true
//ind.IsSellSignal = true

   return ind;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iStochasticGet(const int buffer,const int index)
  {
   double Stochastic[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iStochasticBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iStochastic,buffer,index,1,Stochastic)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iStochastic indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(Stochastic[0]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iBandsGet(int handle_iBands,const int buffer,const int index)
  {
   double Bands[1];
//ArraySetAsSeries(Bands,true);
//--- reset error code
   ResetLastError();
//--- fill a part of the iStochasticBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iBands,buffer,index,1,Bands)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iBands indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(Bands[0]);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iRSIGet(const int index)
  {
   double RSI[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iRSI array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iRSI,0,index,1,RSI)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(RSI[0]);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseIfLose()
  {
   while(PositionSelect(_Symbol) > 0)
     {
      if(PositionGetDouble(POSITION_PROFIT) < Min_Profit)
         CloseAllOrders();
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+



// Call this function to close all buy orders
void CloseBuy()
  {
   CloseAllOrders(POSITION_TYPE_BUY);
  }

// Call this function to close all sell orders
void CloseSell()
  {
   CloseAllOrders(POSITION_TYPE_SELL);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllOrders(int positionType)
  {
// Close all open positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         // Check if the position type matches the specified type
         if(m_position.Type() == positionType)
           {
            m_trade.PositionClose(m_position.Ticket());
            // Optionally add a delay here if needed
            // Sleep(100);
           }
        }
     }

// Delete all pending orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(m_order.SelectByIndex(i))
        {
         // Check if the order type matches the specified type
         if(m_order.Type() == positionType)
           {
            m_trade.OrderDelete(m_order.Ticket());
            // Optionally add a delay here if needed
            // Sleep(100);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllOrders()
  {
// Close all open positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         m_trade.PositionClose(m_position.Ticket());
         // Optionally add a delay here if needed
         // Sleep(100);
        }
     }

// Delete all pending orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(m_order.SelectByIndex(i))
        {
         m_trade.OrderDelete(m_order.Ticket());
         // Optionally add a delay here if needed
         // Sleep(100);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStopLoss(double stopLoss, double trailingStop)
  {
   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double newStopLoss = 0;
   double currentStopLoss = PositionGetDouble(POSITION_SL);
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
     {
      newStopLoss = entryPrice + stopLoss;
      if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > entryPrice + trailingStop)
         newStopLoss = SymbolInfoDouble(_Symbol, SYMBOL_BID) - trailingStop;
      if(newStopLoss > currentStopLoss)
        {
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);
         request.action = TRADE_ACTION_SLTP;
         request.position = PositionGetInteger(POSITION_TICKET);
         request.symbol = _Symbol;
         request.sl = newStopLoss;

         if(!OrderSend(request, result))
            Print("Failed to set stop loss. Error: ", GetLastError());
        }
     }
   else
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
         newStopLoss = entryPrice - stopLoss;
         if(SymbolInfoDouble(_Symbol, SYMBOL_BID) < entryPrice - trailingStop)
            newStopLoss = SymbolInfoDouble(_Symbol, SYMBOL_BID) + trailingStop;
         if(newStopLoss < currentStopLoss)
           {
            MqlTradeRequest request;
            MqlTradeResult result;
            ZeroMemory(request);
            request.action = TRADE_ACTION_SLTP;
            request.position = PositionGetInteger(POSITION_TICKET);
            request.symbol = _Symbol;
            request.sl = newStopLoss;

            if(!OrderSend(request, result))
               Print("Failed to set stop loss. Error: ", GetLastError());
           }
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetTP()
  {
// Get the number of open positions
   int total = PositionsTotal();

// Loop through all open positions
   for(int i = 0; i < total; i++)
     {
      // Select the position by index
      if(m_position.SelectByIndex(i))
        {
         // Get the symbol of the current position
         string symbol = m_position.Symbol();

         // Update symbol information
         m_symbol.Name(symbol);

         // Get the point size for the symbol
         double point = m_symbol.Point();

         // Get the entry price
         double entryPrice = m_position.PriceOpen();

         // Determine the position type (buy or sell)
         ENUM_POSITION_TYPE positionType = m_position.PositionType();

         // Calculate the new take profit based on the position type
         double newTakeProfit;
         if(positionType == POSITION_TYPE_BUY)
           {
            newTakeProfit = entryPrice + TP * point;
           }
         else
            if(positionType == POSITION_TYPE_SELL)
              {
               newTakeProfit = entryPrice - TP * point;
              }

         // Modify the position to set the new Take Profit
         bool res = m_trade.PositionModify(m_position.Ticket(), m_position.StopLoss(), newTakeProfit);

         // Check for errors in the order modification
         if(!res)
           {
            Print("Error setting take profit for position ", m_position.Ticket(), " error code ", GetLastError());
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetSL()
  {
// Get the number of open positions
   int total = PositionsTotal();

// Loop through all open positions
   for(int i = 0; i < total; i++)
     {
      // Select the position by index
      if(m_position.SelectByIndex(i))
        {
         // Get the symbol of the current position
         string symbol = m_position.Symbol();

         // Update symbol information
         m_symbol.Name(symbol);

         // Get the point size for the symbol
         double point = m_symbol.Point();

         // Get the entry price and current stop loss
         double entryPrice = m_position.PriceOpen();
         double currentStopLoss = m_position.StopLoss();

         // Calculate the new stop loss
         double newStopLoss = entryPrice - SL * point;

         // Ensure the new stop loss is valid (if you have additional logic, it can be applied here)
         newStopLoss = MathMax(newStopLoss, entryPrice);

         // Modify the position to set the new Stop Loss
         bool res = m_trade.PositionModify(m_position.Ticket(), newStopLoss, m_position.TakeProfit());

         // Check for errors in the order modification
         if(!res)
           {
            Print("Error setting stop loss for position ", m_position.Ticket(), " error code ", GetLastError());
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetSLToEntry()
  {
// Get the number of open positions
   int total =  PositionsTotal();

// Loop through all open positions
   for(int i = 0; i < total; i++)
     {
      // Select the position
      if(m_position.SelectByIndex(i))
        {
         // Get the position ticket (identifier)
         ulong ticket = m_position.Ticket();

         // Get the entry price
         double entryPrice = m_position.PriceOpen();

         // Modify the position to set Stop Loss to entry price
         bool res = m_trade.PositionModify(ticket, entryPrice, m_position.TakeProfit());

         // Check for errors in the order send
         if(!res)
           {
            Print("Error setting stop loss for position ", ticket, " error code ", GetLastError());
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Counter CalcTotal()
  {
   Counter counter;
   int total = PositionsTotal();

   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetInteger(POSITION_TICKET);
      double lots = PositionGetDouble(POSITION_VOLUME);
      double profit = PositionGetDouble(POSITION_PROFIT);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
         counter.BuyTotal++;
         counter.BuyProfit += profit;
         counter.LastBuyLots = lots;
         counter.LastBuyPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        }
      else
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
           {
            counter.SellTotal++;
            counter.SellProfit += profit;
            counter.LastSellLots = lots;
            counter.LastSellPrice = PositionGetDouble(POSITION_PRICE_OPEN);
           }

      counter.PointTotal += (profit / lots) / point;
      counter.ProfitTotal += profit;
     }

   return counter;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,          // EventId
                  const long &lparam,    // Parameter of type long event
                  const double &dparam,  // Parameter of type double event
                  const string &sparam)  // Parameter of type string event
  {
   if(sparam == "Exit")
     {
      // ObjectSetInteger(0, "Exit", OBJPROP_STATE, false);
      //ObjectsDeleteAll();
      ExpertRemove();
     }

   if(sparam == "CloseAllOrder")
     {
      // ObjectSetInteger(0, "CloseIfLose", OBJPROP_STATE, false);
      CloseAllOrders();
      CloseBuy();
      CloseSell();
     }

   if(sparam == "CloseAllBuy")
     {
      // ObjectSetInteger(0, "CloseAllBuy", OBJPROP_STATE, false);
      CloseBuy();
     }

   if(sparam == "CloseAllSell")
     {
      // ObjectSetInteger(0, "CloseAllSell", OBJPROP_STATE, false);
      CloseSell();
     }

   if(sparam == "SetSLToEntry")
     {
      ///ObjectSetInteger(0, "SetSLToEntry", OBJPROP_STATE, false);
      SetSLToEntry();
     }

   if(sparam == "SetSL")
     {
      SetSL();
     }

   if(sparam == "SetTP")
     {
      // ObjectSetInteger(0, "SetSLToEntry", OBJPROP_STATE, false);
      SetTP();
     }
  }

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawButton(string name,ENUM_OBJECT type, int CORNER, int XDISTANCE, int YDISTANCE, int XSIZE, int YSIZE,
                string Text, int Fontsize, color FontColor, color Background)
  {
   ObjectCreate(0,name,type,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,XDISTANCE);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,XSIZE);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,YDISTANCE);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,YSIZE);
   ObjectSetString(0,name,OBJPROP_TEXT,Text);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,Fontsize);
   ObjectSetInteger(0,name,OBJPROP_COLOR,FontColor);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,Background);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawDashBoard()
  {
   DrawButton(NAME_BUTTON_1,OBJ_BUTTON,INPUT_CORNER,INPUT_X_DISTANCE + 0,INPUT_Y_DISTANCE + INPUT_Y_SIZE,INPUT_X_SIZE,INPUT_Y_SIZE,TEXT_BUTTON_1,INPUT_FONT_SIZE,clrBlack,clrWhite);
   DrawButton(NAME_BUTTON_2,OBJ_BUTTON,INPUT_CORNER,INPUT_X_DISTANCE + INPUT_X_SIZE,INPUT_Y_DISTANCE + INPUT_Y_SIZE,INPUT_X_SIZE,INPUT_Y_SIZE,TEXT_BUTTON_2,INPUT_FONT_SIZE,clrBlack,clrWhite);
   DrawButton(NAME_BUTTON_3,OBJ_BUTTON,INPUT_CORNER,INPUT_X_DISTANCE + 2*INPUT_X_SIZE,INPUT_Y_DISTANCE + INPUT_Y_SIZE,INPUT_X_SIZE,INPUT_Y_SIZE,TEXT_BUTTON_3,INPUT_FONT_SIZE,clrBlack,clrWhite);

   DrawButton(NAME_BUTTON_4,OBJ_BUTTON,INPUT_CORNER,INPUT_X_DISTANCE + 0,INPUT_Y_DISTANCE + 2*INPUT_Y_SIZE,INPUT_X_SIZE,INPUT_Y_SIZE,TEXT_BUTTON_4,INPUT_FONT_SIZE,clrBlack,clrWhite);
   DrawButton(NAME_BUTTON_5,OBJ_BUTTON,INPUT_CORNER,INPUT_X_DISTANCE + INPUT_X_SIZE,INPUT_Y_DISTANCE + 2*INPUT_Y_SIZE,INPUT_X_SIZE,INPUT_Y_SIZE,TEXT_BUTTON_5,INPUT_FONT_SIZE,clrBlack,clrWhite);
   DrawButton(TEXT_BUTTON_6,OBJ_BUTTON,INPUT_CORNER,INPUT_X_DISTANCE + 2*INPUT_X_SIZE,INPUT_Y_DISTANCE + 2*INPUT_Y_SIZE,INPUT_X_SIZE,INPUT_Y_SIZE,TEXT_BUTTON_6,INPUT_FONT_SIZE,clrBlack,clrWhite);

   DrawButton(NAME_BUTTON_7,OBJ_BUTTON,INPUT_CORNER,INPUT_X_DISTANCE + 0,INPUT_Y_DISTANCE + 3*INPUT_Y_SIZE,INPUT_X_SIZE,INPUT_Y_SIZE,TEXT_BUTTON_7,INPUT_FONT_SIZE,clrBlack,clrWhite);
   DrawButton(NAME_BUTTON_8,OBJ_BUTTON,INPUT_CORNER,INPUT_X_DISTANCE + INPUT_X_SIZE,INPUT_Y_DISTANCE + 3*INPUT_Y_SIZE,INPUT_X_SIZE,INPUT_Y_SIZE,TEXT_BUTTON_8,INPUT_FONT_SIZE,clrBlack,clrWhite);
   DrawButton(TEXT_BUTTON_9,OBJ_EDIT,INPUT_CORNER,INPUT_X_DISTANCE + 2*INPUT_X_SIZE,INPUT_Y_DISTANCE + 3*INPUT_Y_SIZE,INPUT_X_SIZE,INPUT_Y_SIZE,TEXT_BUTTON_9,INPUT_FONT_SIZE,clrBlack,clrWhite);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLable()
  {
   if(ObjectFind(0, "Label") == 0)
      return;

// Create the label
   if(ObjectCreate(0, "Label", OBJ_LABEL, 0, 0, 0))
     {
      ObjectSetInteger(0, "Label", OBJPROP_XSIZE, 120);
      ObjectSetInteger(0, "Label", OBJPROP_YSIZE, 30);
      ObjectSetInteger(0, "Label", OBJPROP_XDISTANCE, 0);
      ObjectSetInteger(0, "Label", OBJPROP_YDISTANCE, 0);
      ObjectSetInteger(0, "Label", OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, "Label", OBJPROP_COLOR, clrBlack);
      ObjectSetString(0, "Label", OBJPROP_TEXT, "Some Text Here");
      ObjectSetInteger(0, "Label", OBJPROP_FONTSIZE, 14);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawInfor()
  {
   if(ObjectFind(0, "Infor") == 0)
      return;

// Create the information panel
   if(ObjectCreate(0, "Infor", OBJ_RECTANGLE_LABEL, 0, 0, 0))
     {
      ObjectSetInteger(0, "Infor", OBJPROP_XSIZE, 200);
      ObjectSetInteger(0, "Infor", OBJPROP_YSIZE, 50);
      ObjectSetInteger(0, "Infor", OBJPROP_XDISTANCE, 0);
      ObjectSetInteger(0, "Infor", OBJPROP_YDISTANCE, 0);
      ObjectSetInteger(0, "Infor", OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, "Infor", OBJPROP_COLOR, clrLightGray);
     }

// Add information text
   ObjectCreate(0, "InfoText", OBJ_TEXT, 0, 0, 0);
   ObjectSetInteger(0, "InfoText", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "InfoText", OBJPROP_YDISTANCE, 10);
   ObjectSetInteger(0, "InfoText", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "InfoText", OBJPROP_COLOR, clrBlack);
   ObjectSetString(0, "InfoText", OBJPROP_TEXT, "Info: ");
   ObjectSetInteger(0, "InfoText", OBJPROP_FONTSIZE, 10);
  }
//+------------------------------------------------------------------+
