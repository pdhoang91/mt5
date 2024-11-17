//+------------------------------------------------------------------+
//|                        MeanReversion.mqh                          |
//+------------------------------------------------------------------+
//#pragma once

bool MeanReversionEntry(double &entry, double &tp, double &sl, bool &isBuy, 
                        ENUM_TIMEFRAMES timeframe, int BollingerBandsPeriod, 
                        double Deviation, double MeanReversionATRMultiplier, double MeanReversionRiskRewardRatio)
{
    // Create Bollinger Bands handle
    int bb_handle = iBands(_Symbol, timeframe, BollingerBandsPeriod, Deviation, 0, PRICE_CLOSE);
    if(bb_handle == INVALID_HANDLE)
    {
        Print("Error creating Bollinger Bands handle for Mean Reversion: ", GetLastError());
        return false;
    }

    // Copy Bollinger Bands upper, middle, and lower bands
    double upperBand[], middleBand[], lowerBand[];
    if(CopyBuffer(bb_handle, 0, 0, 1, upperBand) <= 0 ||
       CopyBuffer(bb_handle, 1, 0, 1, middleBand) <= 0 ||
       CopyBuffer(bb_handle, 2, 0, 1, lowerBand) <= 0)
    {
        Print("Error copying Bollinger Bands data for Mean Reversion: ", GetLastError());
        IndicatorRelease(bb_handle);
        return false;
    }
    IndicatorRelease(bb_handle);

    // Current price
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Buy Signal: Price below lower Bollinger Band
    if(current_price < lowerBand[0])
    {
        isBuy = true;
        entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        // Create ATR handle
        int atr_handle = iATR(_Symbol, timeframe, 14); // ATR period fixed at 14
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for Mean Reversion: ", GetLastError());
            return false;
        }

        // Copy ATR value
        double atr[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
        {
            Print("Error copying ATR data for Mean Reversion: ", GetLastError());
            IndicatorRelease(atr_handle);
            return false;
        }
        IndicatorRelease(atr_handle);

        // Calculate SL and TP
        sl = entry - MeanReversionATRMultiplier * atr[0];
        tp = middleBand[0];
        return true;
    }

    // Sell Signal: Price above upper Bollinger Band
    if(current_price > upperBand[0])
    {
        isBuy = false;
        entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        // Create ATR handle
        int atr_handle = iATR(_Symbol, timeframe, 14); // ATR period fixed at 14
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for Mean Reversion: ", GetLastError());
            return false;
        }

        // Copy ATR value
        double atr[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
        {
            Print("Error copying ATR data for Mean Reversion: ", GetLastError());
            IndicatorRelease(atr_handle);
            return false;
        }
        IndicatorRelease(atr_handle);

        // Calculate SL and TP
        sl = entry + MeanReversionATRMultiplier * atr[0];
        tp = middleBand[0];
        return true;
    }

    return false; // No trading signal
}
