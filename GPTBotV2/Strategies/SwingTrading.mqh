//+------------------------------------------------------------------+
//|                      SwingTrading.mqh                            |
//+------------------------------------------------------------------+
//#pragma once

bool SwingTradingEntry(double &entry, double &tp, double &sl, bool &isBuy, 
                      ENUM_TIMEFRAMES timeframe, int RSIPeriod, int FastMAPeriod, 
                      int SlowMAPeriod, double ATRMultiplier, double SwingRiskRewardRatio)
{
    // Create RSI handle
    int rsi_handle = iRSI(_Symbol, timeframe, RSIPeriod, PRICE_CLOSE);
    if(rsi_handle == INVALID_HANDLE)
    {
        Print("Error creating RSI handle for Swing Trading: ", GetLastError());
        return false;
    }

    // Copy RSI value
    double rsi[];
    if(CopyBuffer(rsi_handle, 0, 0, 1, rsi) <= 0)
    {
        Print("Error copying RSI data for Swing Trading: ", GetLastError());
        IndicatorRelease(rsi_handle);
        return false;
    }
    IndicatorRelease(rsi_handle);

    // Create Fast MA handle
    int ma_fast_handle = iMA(_Symbol, timeframe, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
    if(ma_fast_handle == INVALID_HANDLE)
    {
        Print("Error creating Fast MA handle for Swing Trading: ", GetLastError());
        return false;
    }

    // Copy Fast MA value
    double fastMA[];
    if(CopyBuffer(ma_fast_handle, 0, 0, 1, fastMA) <= 0)
    {
        Print("Error copying Fast MA data for Swing Trading: ", GetLastError());
        IndicatorRelease(ma_fast_handle);
        return false;
    }
    IndicatorRelease(ma_fast_handle);

    // Create Slow MA handle
    int ma_slow_handle = iMA(_Symbol, timeframe, SlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
    if(ma_slow_handle == INVALID_HANDLE)
    {
        Print("Error creating Slow MA handle for Swing Trading: ", GetLastError());
        return false;
    }

    // Copy Slow MA value
    double slowMA[];
    if(CopyBuffer(ma_slow_handle, 0, 0, 1, slowMA) <= 0)
    {
        Print("Error copying Slow MA data for Swing Trading: ", GetLastError());
        IndicatorRelease(ma_slow_handle);
        return false;
    }
    IndicatorRelease(ma_slow_handle);

    // Current price
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Buy Condition: RSI < 30 and price > Fast MA
    if(rsi[0] < 30 && current_price > fastMA[0])
    {
        isBuy = true;
        entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        // Create ATR handle
        int atr_handle = iATR(_Symbol, timeframe, 14); // ATR period fixed at 14
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for Swing Trading: ", GetLastError());
            return false;
        }

        // Copy ATR value
        double atr[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
        {
            Print("Error copying ATR data for Swing Trading: ", GetLastError());
            IndicatorRelease(atr_handle);
            return false;
        }
        IndicatorRelease(atr_handle);

        // Calculate SL and TP
        sl = entry - ATRMultiplier * atr[0];
        tp = entry + SwingRiskRewardRatio * (entry - sl);
        return true;
    }

    // Sell Condition: RSI > 70 and price < Slow MA
    if(rsi[0] > 70 && current_price < slowMA[0])
    {
        isBuy = false;
        entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        // Create ATR handle
        int atr_handle = iATR(_Symbol, timeframe, 14); // ATR period fixed at 14
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for Swing Trading: ", GetLastError());
            return false;
        }

        // Copy ATR value
        double atr[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
        {
            Print("Error copying ATR data for Swing Trading: ", GetLastError());
            IndicatorRelease(atr_handle);
            return false;
        }
        IndicatorRelease(atr_handle);

        // Calculate SL and TP
        sl = entry + ATRMultiplier * atr[0];
        tp = entry - SwingRiskRewardRatio * (sl - entry);
        return true;
    }

    return false; // No trading signal
}
