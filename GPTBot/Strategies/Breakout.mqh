//+------------------------------------------------------------------+
//|                            Breakout.mqh                          |
//+------------------------------------------------------------------+
//#pragma once

bool BreakoutEntry(double &entry, double &tp, double &sl, bool &isBuy, 
                  ENUM_TIMEFRAMES timeframe, double VolumeThreshold, double RiskRewardRatio)
{
    // Calculate Pivot Point
    double pivot = 0.0;
    double high_prev[];
    double low_prev[];
    double close_prev[];
    if(CopyHigh(_Symbol, timeframe, 1, 1, high_prev) != 1 ||
       CopyLow(_Symbol, timeframe, 1, 1, low_prev) != 1 ||
       CopyClose(_Symbol, timeframe, 1, 1, close_prev) != 1)
    {
        Print("Error copying previous candle data for Breakout: ", GetLastError());
        return false;
    }

    pivot = (high_prev[0] + low_prev[0] + close_prev[0]) / 3.0;
    double resistance = pivot + 0.0010; // Adjust as per asset
    double support = pivot - 0.0010;    // Adjust as per asset

    // Current Volume
    long current_volume_array[];
    if(CopyTickVolume(_Symbol, timeframe, 0, 1, current_volume_array) != 1)
    {
        Print("Error copying current volume for Breakout: ", GetLastError());
        return false;
    }
    double current_volume = (double)current_volume_array[0];

    // Calculate average volume over past 20 candles
    double avg_volume = 0.0;
    int period = 20;
    long volume_buffer[];
    if(CopyTickVolume(_Symbol, timeframe, 1, period, volume_buffer) != period)
    {
        Print("Error copying volume data for Breakout: ", GetLastError());
        return false;
    }
    for(int i = 0; i < period; i++)
    {
        avg_volume += (double)volume_buffer[i];
    }
    avg_volume /= period;

    // Current price
    double current_price = m_symbol.Bid();

    // Buy Signal: Price breaks above resistance with high volume
    if(current_price > resistance && current_volume > VolumeThreshold * avg_volume)
    {
        isBuy = true;
        entry = m_symbol.Ask();

        // Create ATR handle
        int atr_handle = iATR(_Symbol, timeframe, 14); // ATR period fixed at 14
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for Breakout: ", GetLastError());
            return false;
        }

        // Copy ATR value
        double atr[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
        {
            Print("Error copying ATR data for Breakout: ", GetLastError());
            IndicatorRelease(atr_handle);
            return false;
        }
        IndicatorRelease(atr_handle);

        // Calculate SL and TP
        sl = support;
        tp = entry + RiskRewardRatio * (entry - sl);
        return true;
    }

    // Sell Signal: Price breaks below support with high volume
    if(current_price < support && current_volume > VolumeThreshold * avg_volume)
    {
        isBuy = false;
        entry = m_symbol.Bid();

        // Create ATR handle
        int atr_handle = iATR(_Symbol, timeframe, 14); // ATR period fixed at 14
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for Breakout: ", GetLastError());
            return false;
        }

        // Copy ATR value
        double atr[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
        {
            Print("Error copying ATR data for Breakout: ", GetLastError());
            IndicatorRelease(atr_handle);
            return false;
        }
        IndicatorRelease(atr_handle);

        // Calculate SL and TP
        sl = resistance;
        tp = entry - RiskRewardRatio * (sl - entry);
        return true;
    }

    return false; // No trading signal
}
