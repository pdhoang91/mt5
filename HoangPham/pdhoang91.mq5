#include <Trade/Trade.mqh>

int handleDarkPoint;
int barsTotal;

CTrade trade;

int OnInit(){
   handleDarkPoint = iCustom(_Symbol,PERIOD_CURRENT,"Market/Dark Point MT5.ex5","","DP_",40,3,1.0,"",14,"",true,0.8,true,1.6,true,3.2,true,1.6,true,3.2,true,5.0,"",true);
   barsTotal = iBars(_Symbol,PERIOD_CURRENT);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}

void OnTick(){
   int bars = iBars(_Symbol,PERIOD_CURRENT);
   if(barsTotal != bars){
      barsTotal = bars;
   
      double dpBuy[], dpSell[], dpBuyStar[], dpSellStar[];
      CopyBuffer(handleDarkPoint,0,1,1,dpBuy);
      CopyBuffer(handleDarkPoint,1,1,1,dpSell);
      CopyBuffer(handleDarkPoint,2,1,1,dpBuyStar);
      CopyBuffer(handleDarkPoint,3,1,1,dpSellStar);
      
      if(dpBuy[0] > 0 || dpBuyStar[0] > 0){
         Print(__FUNCTION__," > New buy signal...");
         
         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         ask = NormalizeDouble(ask,_Digits);
         
         double tp = ObjectGetDouble(0,"DP_TP_Line_1"+IntegerToString(iTime(_Symbol,PERIOD_CURRENT,1)),OBJPROP_PRICE);
         tp = NormalizeDouble(tp,_Digits);
                  
         double sl = ObjectGetDouble(0,"DP_SL_Line_1"+IntegerToString(iTime(_Symbol,PERIOD_CURRENT,1)),OBJPROP_PRICE);
         sl = NormalizeDouble(sl,_Digits);
                 
         if(ask > 0 && tp > 0 && sl > 0){ 
            trade.Buy(0.1,_Symbol,ask,sl,tp);
         }
      }else if(dpSell[0] > 0 || dpSellStar[0] > 0){      
         Print(__FUNCTION__," > New sell signal...");

         double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         bid = NormalizeDouble(bid,_Digits);
         
         double tp = ObjectGetDouble(0,"DP_TP_Line_1"+IntegerToString(iTime(_Symbol,PERIOD_CURRENT,1)),OBJPROP_PRICE);
         tp = NormalizeDouble(tp,_Digits);
                  
         double sl = ObjectGetDouble(0,"DP_SL_Line_1"+IntegerToString(iTime(_Symbol,PERIOD_CURRENT,1)),OBJPROP_PRICE);
         sl = NormalizeDouble(sl,_Digits);
                 
         if(bid > 0 && tp > 0 && sl > 0){ 
            trade.Sell(0.1,_Symbol,bid,sl,tp);
         }
      }
   }
}