//+------------------------------------------------------------------+
//|                          Scalping.mqh                            |
//+------------------------------------------------------------------+
//pragma once

bool ScalpingEntry(double &entry, double &tp, double &sl, bool &isBuy, 
                  ENUM_TIMEFRAMES timeframe, int RSIPeriod, int BollingerBandsPeriod, 
                  double ATRMultiplier, double ScalpingRiskRewardRatio)
{
    // Create RSI handle
    int rsi_handle = iRSI(_Symbol, timeframe, RSIPeriod, PRICE_CLOSE);
    if(rsi_handle == INVALID_HANDLE)
    {
        Print("Error creating RSI handle for Scalping: ", GetLastError());
        return false;
    }

    // Copy RSI value
    double rsi[];
    if(CopyBuffer(rsi_handle, 0, 0, 1, rsi) <= 0)
    {
        Print("Error copying RSI data for Scalping: ", GetLastError());
        IndicatorRelease(rsi_handle);
        return false;
    }
    IndicatorRelease(rsi_handle);

    // Create Bollinger Bands handle
    int bb_handle = iBands(_Symbol, timeframe, BollingerBandsPeriod, 2.0, 0, PRICE_CLOSE);
    if(bb_handle == INVALID_HANDLE)
    {
        Print("Error creating Bollinger Bands handle for Scalping: ", GetLastError());
        return false;
    }

    // Copy Bollinger Bands upper and lower bands
    double upperBand[], lowerBand[];
    if(CopyBuffer(bb_handle, 0, 0, 1, upperBand) <= 0 || 
       CopyBuffer(bb_handle, 2, 0, 1, lowerBand) <= 0)
    {
        Print("Error copying Bollinger Bands data for Scalping: ", GetLastError());
        IndicatorRelease(bb_handle);
        return false;
    }
    IndicatorRelease(bb_handle);

    // Current price
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Buy Signal: RSI < 30 and price <= lower Bollinger Band
    if(rsi[0] < 30 && current_price <= lowerBand[0])
    {
        isBuy = true;
        entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        // Create ATR handle
        int atr_handle = iATR(_Symbol, timeframe, 14); // ATR period fixed at 14
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for Scalping: ", GetLastError());
            return false;
        }

        // Copy ATR value
        double atr[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
        {
            Print("Error copying ATR data for Scalping: ", GetLastError());
            IndicatorRelease(atr_handle);
            return false;
        }
        IndicatorRelease(atr_handle);

        // Calculate SL and TP
        sl = entry - ATRMultiplier * atr[0];
        tp = entry + ScalpingRiskRewardRatio * (entry - sl);
        return true;
    }

    // Sell Signal: RSI > 70 and price >= upper Bollinger Band
    if(rsi[0] > 70 && current_price >= upperBand[0])
    {
        isBuy = false;
        entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        // Create ATR handle
        int atr_handle = iATR(_Symbol, timeframe, 14); // ATR period fixed at 14
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for Scalping: ", GetLastError());
            return false;
        }

        // Copy ATR value
        double atr[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
        {
            Print("Error copying ATR data for Scalping: ", GetLastError());
            IndicatorRelease(atr_handle);
            return false;
        }
        IndicatorRelease(atr_handle);

        // Calculate SL and TP
        sl = entry + ATRMultiplier * atr[0];
        tp = entry - ScalpingRiskRewardRatio * (sl - entry);
        return true;
    }

    return false; // No trading signal
}
