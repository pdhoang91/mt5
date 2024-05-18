//+------------------------------------------------------------------+
//|                     Thanh Tan.mq5 |
//|                                                                  |
//+------------------------------------------------------------------+

//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CMoneyFixedMargin *m_money;

// Trading parameter

input int HL_period=156;
input int HL_Shift;
//--- input parameters
input double           Lot_size          =1  ;
input double           distance          =350 ;        // Distance from highestigh or loweslow to start trade
input double           TP=2800;                      // Take profit
input double           SL=1200;                      // Stop loss
input ushort           InpTrailingStop   = 6000;       // Trailing Stop (in pips)
input ushort           InpTrailingStep   = 35;        // Trailing Step (in pips)
input int              InpMaxPositions   = 5;        // Maximum positions
input ulong            m_magic=47978073;             // magic number
int input    EXPERT_MAGIC = 1234567;
input        ENUM_TIMEFRAMES              Trading_timframe=PERIOD_H1;    

// Input Indicator declaration

input int      period_MA_fast      =120;       // Moving Avarage: period  
input int      Shift_MA_fast       =6;       // Moving Avarage: period  

// Global Variable

//SL-TP management
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
ulong          m_slippage=10;                // slippage
double         ExtDistance=0.0;
double         ExtStopLoss=0.0;
double         ExtTakeProfit=0.0;
double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;
double         ExtSpreadLimit=0.0;

// Indicator Declaration
int handle_iIchimoku;
int handel_MA;

  //+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();
    //---
   trade.SetExpertMagicNumber(m_magic);
   trade.SetMarginMode();
   trade.SetTypeFillingBySymbol(m_symbol.Name());
   trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss    = SL     * m_adjusted_point;
   ExtTakeProfit  = TP   * m_adjusted_point;
   ExtTrailingStop= InpTrailingStop * m_adjusted_point;
   ExtTrailingStep= InpTrailingStep * m_adjusted_point;
   ExtDistance    = distance*m_adjusted_point; double profit=0;
//--- create handle of the indicator MA
   handel_MA=iMA(Symbol(),Trading_timframe,period_MA_fast,Shift_MA_fast,MODE_EMA,PRICE_CLOSE);
//--- if the handle is not created
   if(handel_MA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the Moving average indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

//---
   return(INIT_SUCCEEDED);
  }
  
  

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(m_money!=NULL)
      delete m_money;
    

   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {


  // Declaration the Candle
  double high[]; ArraySetAsSeries(high,true);CopyHigh(Symbol(),Trading_timframe,1,1000,high);
  double low[]; ArraySetAsSeries(low,true);CopyLow(Symbol(),Trading_timframe,1,1000,low);
  double open[]; ArraySetAsSeries(open,true);CopyLow(Symbol(),Trading_timframe,1,1000,open);
  double close[]; ArraySetAsSeries(close,true);CopyLow(Symbol(),Trading_timframe,1,1000,close);
  // Declaration Array for Moving average
  double MA_Slow[]; ArraySetAsSeries(MA_Slow,true);MA(0,1,MA_Slow);
  
  // Declaration Highest high and lowes low
  
  double HH= Highest(high,HL_period,HL_Shift);
  MoveLine(HH,"highesthigh",clrRed);// Draw line Resistance
  double LL= Lowest(low,HL_period,HL_Shift);
  MoveLine(LL,"lowestlow",clrRed);// Draw line Support
  // declaration count positions
  int count_buy=0; int count_sell=0;double profit=0;
  CalculatePositions(count_buy,count_sell,profit);
  // Execution main Trade
  
  // Only trade at new bar
   if(BarOpen(Symbol(),Trading_timframe))
   {
   CalculatePositions(count_buy,count_sell,profit);
    //Delete pending order
   (OrderManaging(Symbol(),Trading_timframe));
   Trailing();
    {
     // Looking for to go long if there is no long position
     if(count_buy==0 && CheckVolumeValue(Lot_size) && CheckMoney(Lot_size,ORDER_TYPE_BUY))
     {
      if(HH>MA_Slow[1])
       {
       double entryprice= HH+ExtDistance;
       double sl=entryprice-ExtStopLoss;
       double tp =entryprice + ExtTakeProfit;
       trade.BuyStop(Lot_size,entryprice,Symbol(),sl,tp,ORDER_TIME_GTC);
       // you enter code buy or sell
        }
      }
      if(count_sell==0 && CheckVolumeValue(Lot_size) && CheckMoney(Lot_size,ORDER_TYPE_SELL))
      {
      if(LL<MA_Slow[1])
       {
       double entryprice= LL-ExtDistance;
       double sl=entryprice+ExtStopLoss;
       double tp =entryprice - ExtTakeProfit;
       trade.SellStop(Lot_size,entryprice,Symbol(),sl,tp,ORDER_TIME_GTC);
       // you enter code buy or sell
       }
      }
      
      
     }
  
   }
}

//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveLine(double price,string name,color clr)
  {
   if(ObjectFind(0,name)<0)
     {
      //--- reset the error value
      ResetLastError();
      //--- create a horizontal line
      if(!ObjectCreate(0,name,OBJ_HLINE,0,0,price))
        {
         Print(__FUNCTION__,
               ": failed to create a horizontal line! Error code = ",GetLastError());
         return;
        }
      //--- set line color
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      //--- set line display style
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASHDOTDOT);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,4);
     }
//--- reset the error value
   ResetLastError();
//--- move a horizontal line
   if(!ObjectMove(0,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return;
     }
   ChartRedraw();
  }


//+------------------------------------------------------------------+
//| Calculate positions Buy and Sell                                 |
//+------------------------------------------------------------------+
void CalculatePositions(int &count_buys,int &count_sells,double &profit)
  {
   count_buys=0;
   count_sells=0;
   profit=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() //&& m_position.Magic()==m_magic
         )
           {
            profit+=m_position.Commission()+m_position.Swap()+m_position.Profit();
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               count_buys++;

            if(m_position.PositionType()==POSITION_TYPE_SELL)
               count_sells++;
           }
    }
//+------------------------------------------------------------------+
//| close all positions                                              |
//+------------------------------------------------------------------+
void ClosePositions(const ENUM_POSITION_TYPE pos_type)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            if(m_position.PositionType()==pos_type) // gets the position type
               trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }

    //+------------------------------------------------------------------+
//| get highest value for range                                      |
//+------------------------------------------------------------------+
double Highest(const double&array[],int range,int fromIndex)
{
   double res=0;
//---
   res=array[fromIndex];
   for(int i=fromIndex;i<fromIndex+range;i++)
   {
      if(res<array[i]) res=array[i];
   }
//---
   return(res);
}
//+------------------------------------------------------------------+
//| get lowest value for range                                       |
//+------------------------------------------------------------------+
double Lowest(const double&array[],int range,int fromIndex)
{
   double res=0;
//---
   res=array[fromIndex];
   for(int i=fromIndex;i<fromIndex+range;i++)
   {
      if(res>array[i]) res=array[i];
   }
//---
   return(res);
}
  
  //+------------------------------------------------------------------+
// Get value of buffers for the iIchimoku                          

double MA( int buffer, int index, double &MA_Slow[])
  {
//--- reset error code
   ResetLastError();
//--- fill a part of the iIchimoku array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handel_MA,buffer,index,1000,MA_Slow)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the Moving Arverage indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(MA_Slow[0]);
  }
  //+------------------------------------------------------------------+
//| Get current server time function                                 |
//+------------------------------------------------------------------+

datetime m_prev_bar;
bool BarOpen(string symbol,ENUM_TIMEFRAMES timeframe)
{
   datetime bar_time = iTime(symbol, timeframe, 0);
   if (bar_time == m_prev_bar)
   {
      return false;
   }
   m_prev_bar = bar_time;
   return true;
}

//+------------------------------------------------------------------+
//| Manage orders and delete all pending order after end of day                                                   |
//+------------------------------------------------------------------+
int OrderManaging(string symbol,ENUM_TIMEFRAMES timeframe)
{
   int orders = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong orderTicket = OrderGetTicket(i);
      if (OrderSelect(orderTicket))
      {
          if (OrderGetString(ORDER_SYMBOL) == Symbol() )
          {
              
               trade.OrderDelete(orderTicket);
          }
      }
   }
   return orders;
}

//+------------------------------------------------------------------+
//| Trailing                                                         |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(InpTrailingStop==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() //&& m_position.Magic()==m_magic
         )
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                    {
                     if(!trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",trade.ResultRetcode(),
                              ", description of result: ",trade.ResultRetcodeDescription());
                     RefreshRates();
                     m_position.SelectByIndex(i);
                     continue;
                    }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) ||
                     (m_position.StopLoss()==0))
                    {
                     if(!trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",trade.ResultRetcode(),
                              ", description of result: ",trade.ResultRetcodeDescription());
                     RefreshRates();
                     m_position.SelectByIndex(i);
                    }
              }

           }
  }
  
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume) {

//--- minimal allowed volume for trade operations
  double min_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(volume < min_volume)
     {
      //description = StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      //description = StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   int ratio = (int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      //description = StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f", volume_step,ratio*volume_step);
      return(false);
     }
      
   return(true);
}

//+------------------------------------------------------------------+
//| Check Money for Trade                                            |
//+------------------------------------------------------------------+
bool CheckMoney(double lots,ENUM_ORDER_TYPE Oder_type) {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(_Symbol,mqltick);
   double price=mqltick.ask;
   if(Oder_type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   //--- call of the checking function
   if(!OrderCalcMargin(Oder_type,_Symbol,lots,price,margin))
     {
      return(false);
     }
   //--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      return(false);
     }
   //--- checking successful
   return(true);
}