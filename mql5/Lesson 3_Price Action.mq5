//+------------------------------------------------------------------+
//|                                        Lesson 3_Price Action.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include      <Trade\Trade.mqh>
#include      <Trade\SYmbolInfo.mqh>
#include      <Trade\PositionInfo.mqh>

// Declaration variable for librari trade function.
CTrade                            trade;
CSymbolInfo                       m_symbol;
CPositionInfo                     m_position;

string input aa = "-----------------------SETTINGS---------------------------";
string input BOT_NAME = "Lesson 3_Price Action";
input    double                   lotsize=0.2;
input    double                   SL_factor=2000;// Stop loss factor
input    double                   TP_factor=4000; //Take profit factor
input    double           Trailling= 2000;// Trailling Pipi
input    double           Trailling_Step=5;// Trailling step
input    ulong                    m_magicnumber=123456789;
input    ENUM_TIMEFRAMES      timeframe= PERIOD_H1;
input    int                    HL_period =20;
input     int                   HL_shift  =2;  

// Input parameter of indicator RSI
input     int                     Period_RSI=14;// Period of RSI
// Global variable declaration

double                            Extstoploss;// stoploss return point value  
double                            Exttakeprofit;// Take profit return point value  
double                            ExtTraill_Stop=0.0;
double                            ExtTraill_Step=0.0;
double                            m_adjustpoint;
ulong                             Slippage;// Slippage
// Global indicator RSI
int                               Handle_RSI;
double                              RSI[];


  //+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
if(!m_symbol.Name(_Symbol))
return  INIT_FAILED;

// Set Trade parameter
trade.SetTypeFillingBySymbol(m_symbol.Name());
trade.SetExpertMagicNumber(m_magicnumber);
trade.SetDeviationInPoints(Slippage);

// Turning 3 or 5 Digit
int    adjustdigit=1;
if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
{
adjustdigit=10;
}

m_adjustpoint=adjustdigit*m_symbol.Point();
Extstoploss= m_adjustpoint*SL_factor;
Exttakeprofit= m_adjustpoint*TP_factor;
ExtTraill_Stop=m_adjustpoint*Trailling;
ExtTraill_Step=m_adjustpoint*Trailling_Step;
// Indicator RSI declaration

Handle_RSI= iRSI(m_symbol.Name(),timeframe,Period_RSI,PRICE_CLOSE);
if(Handle_RSI==INVALID_HANDLE)
return  INIT_FAILED;

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
// Candle declaration
double High[],Low[];
ArraySetAsSeries(High,true);ArraySetAsSeries(Low,true);
CopyHigh(Symbol(),timeframe,0,1000,High);
CopyLow(Symbol(),timeframe,0,1000,Low);
// Highest high and lowest low declation
int highesthigh= ArrayMaximum(High,HL_shift,HL_period);
double  HH      = High[highesthigh];
Drawnline(" Highest high ", clrRed,HH );
int lowestlow= ArrayMinimum(Low,HL_shift,HL_period);
double  LL      = Low[lowestlow];
Drawnline(" Lowest low ", clrBlue,LL );

// mqltick declaration

MqlTick tick;
SymbolInfoTick(_Symbol,tick);

//+------------------------------------------------------------------+
//|   Broker parameter                                               |
//+------------------------------------------------------------------+
      
double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
double ask= SymbolInfoDouble(_Symbol,SYMBOL_ASK);
double bid= SymbolInfoDouble(_Symbol,SYMBOL_BID);
double spread=ask-bid;
double stoplevel= (int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
int freezerlevel= (int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
// Count bjuy and count sell
int count_buy=0; int count_sell=0;
count_position(count_buy,count_sell);

// Main condition for buy and sell

if(OpenBar(Symbol()))
   {
    if(count_buy==0)
      {
       if(tick.ask > ( HH+100*_Point) && CheckVolumeValue(lotsize))
       {
        double  entryprice= tick.ask;
        double  sl         =entryprice-Extstoploss;
        double  tp          =entryprice+Exttakeprofit;
        if(  bid-sl>stoplevel && tp-bid>stoplevel )
        {
         trade.Buy(lotsize,_Symbol,entryprice,sl,tp, " Buy Mr.Tan 0964299486 ");
        }      
       }
      }
    if(count_sell==0)
     {
      if(tick.bid < (LL-100*_Point)&& CheckVolumeValue(lotsize))
       {
        double  entryprice= tick.bid;
        double  sl         =entryprice+Extstoploss;
        double  tp          =entryprice-Exttakeprofit;
        if( sl-ask>stoplevel && ask-tp>stoplevel)
        {
         trade.Sell(lotsize,_Symbol,entryprice,sl,tp, " Buy Mr.Tan 0964299486 ");
        }
       }
      }
  
  }

  }
//+------------------------------------------------------------------+
//|Count position and Trailling Functiom                              |
//+------------------------------------------------------------------+

void  count_position(int &count_buy, int &count_sell)

  {
   count_buy=0; count_sell=0;
   int total_postion=PositionsTotal();
   double cp=0.0, op=0.0, sl=0.0,tp=0.0; ulong ticket=0.0;
   for ( int i=total_postion-1; i>=0; i--)
     {
     if(m_position.SelectByIndex(i))
      {
      if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()== m_magicnumber)
       cp=m_position.PriceCurrent();op=m_position.PriceOpen();sl=m_position.StopLoss();tp=m_position.TakeProfit();ticket=m_position.Ticket();
       {      
       if(m_position.PositionType()== POSITION_TYPE_BUY)
        {
        count_buy++;
        double Traill= cp- ExtTraill_Stop;
        if(cp>sl+ExtTraill_Step && Traill>sl&& PositionModifyCheck(ticket,Traill,tp,_Symbol))
         {
          trade.PositionModify(ticket,Traill,tp);
         }
        }
      else
       if(m_position.PositionType()== POSITION_TYPE_SELL)
        {
         count_sell++;
        double Traill= cp+ ExtTraill_Stop;
        if(cp<sl-ExtTraill_Step && Traill<sl && PositionModifyCheck(ticket,Traill,tp,_Symbol))
         {
          trade.PositionModify(ticket,Traill,tp);
         }
        }
        
       }
      }
    
     }
  }
    
// Only buy or sell at new candle
datetime    mprevBar;
bool    OpenBar(string  symbol)

{
  datetime     CurBar=iTime(symbol,timeframe,0);
  if(  CurBar==mprevBar)
    {
     return   false;
    }
    mprevBar=CurBar;
    return  true;
}


void  Drawnline(string name, color  Color, double  price)

   {
    if(ObjectFind(0,name)<0)
     {
      ResetLastError();
     }
    
     if(!ObjectCreate(0,name,OBJ_HLINE,0,0,price))
      {
        return;
      }
      
    // Setup BBJ style for object
    ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASHDOT);
    // Setup BBJ cloer for object
    ObjectSetInteger(0,name,OBJPROP_COLOR,Color);
    // Setup BBJ width for object
    ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
    if(!ObjectMove(0,name,0,0,price))
     {
       return;
     }
    ChartRedraw();
  
   }
  
//+------------------------------------------------------------------+
//| Checking the new values of levels before order modification      |
//+------------------------------------------------------------------+
bool PositionModifyCheck(ulong ticket,double sl,double tp,string symbol)
  {
   CPositionInfo pos;
   COrderInfo    order;
   if (PositionGetString(POSITION_SYMBOL) == symbol)
   {
//--- select order by ticket
   if(pos.SelectByTicket(ticket))
     {
      //--- point size and name of the symbol, for which a pending order was placed
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      //--- check if there are changes in the StopLoss level
      bool StopLossChanged=(MathAbs(pos.StopLoss()-sl)>point);
      //--- if there are any changes in levels
      if(StopLossChanged)// || TakeProfitChanged)
         return(true);  // position can be modified      
      //--- there are no changes in the StopLoss and Takeprofit levels
      else
      //--- notify about the error
         PrintFormat("Order #%d already has levels of Open=%.5f SL=.5f TP=%.5f",
                     ticket,order.StopLoss(),order.TakeProfit());
     }
    }
//--- came to the end, no changes for the order
   return(false);       // no point in modifying
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
  