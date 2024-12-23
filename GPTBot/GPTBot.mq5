//+------------------------------------------------------------------+
//|                                             TradingBot.mq5        |
//|                        Created by OpenAI's ChatGPT                 |
//+------------------------------------------------------------------+
#property strict

//--- Include Strategy Files
#include "Strategies/Scalping.mqh"
#include "Strategies/SwingTrading.mqh"
#include "Strategies/Breakout.mqh"
#include "Strategies/MeanReversion.mqh"

//--- Include Trade Classes
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>

//--- Create Objects
CPositionInfo    m_position;                   // Trade position object
CTrade           trade;                        // Trading object
CSymbolInfo      m_symbol;                      // Symbol info object
CAccountInfo     m_account;                     // Account info wrapper
// CMoneyFixedMargin *m_money;                 // Nếu bạn cần quản lý margin

//--- Input Parameters
input int AnalysisPeriod = 2; // Number of days for historical analysis
input ENUM_TIMEFRAMES Timeframe = PERIOD_M15; // Trading timeframe
input string RiskManagementMode = "FixedLot"; // "FixedLot" or "Risk-Based"
input double FixedLotSize = 0.01; // Fixed lot size
input double RiskPercentage = 2.0; // Risk percentage per trade

// Performance Evaluation Parameters (Placeholder)
input double MaxDrawdownWeight = 0.5;
input double WinRateWeight = 0.3;
input double AvgProfitWeight = 0.2;

// Strategy-Specific Parameters
// Scalping
input int ScalpingRSIPeriod = 14;
input int ScalpingBollingerBandsPeriod = 20;
input double ScalpingATRMultiplier = 1.5;
input double ScalpingRiskRewardRatio = 2.0;

// Swing Trading
input int SwingRSIPeriod = 14;
input int SwingFastMAPeriod = 9;
input int SwingSlowMAPeriod = 21;
input double SwingATRMultiplier = 1.5;
input double SwingRiskRewardRatio = 2.0;

// Breakout
input double BreakoutVolumeThreshold = 1.5;
input double BreakoutRiskRewardRatio = 2.0;

// Mean Reversion
input int MeanReversionBollingerBandsPeriod = 20;
input double MeanReversionDeviation = 2.0;
input double MeanReversionATRMultiplier = 1.5;
input double MeanReversionRiskRewardRatio = 2.0;

// Stop Loss and Take Profit Fallbacks
input double SL_Fallback = 1200;
input double TP_Fallback = 1500;

// Trailing Stop and Max Holding Time
input double TrailingStopPips = 10;     // Trailing stop in pips
input int MaxHoldingTime = 1440;        // Max holding time in minutes
input double RiskRewardRatio = 2.0;     // Risk-Reward ratio

// Magic Number for Orders
input ulong MAGIC_NUMBER = 123456;

//--- Indicator Handles
int handle_MA_fast;

//--- Global Variables
datetime last_analysis_time = 0;

//--- Structure for Trading Sessions
struct TradingSession {
    string Name;
    int StartHour;
    int StartMinute;
    int EndHour;
    int EndMinute;
};

// Define Trading Sessions
TradingSession sessions[] = {
    {"Asia",    0,  0,  8, 0},
    {"Europe",  8,  0, 16, 0},
    {"US",     16,  0, 24, 0}
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Initialize symbol
    if(!m_symbol.Name(Symbol())) // sets symbol name
        return(INIT_FAILED);
    RefreshRates();

    //--- Initialize trade settings
    trade.SetExpertMagicNumber(MAGIC_NUMBER);
    trade.SetDeviationInPoints(10); // Slippage
    trade.SetTypeFilling(ORDER_FILLING_FOK); // Corrected ENUM_ORDER_TYPE_FILLING

    //--- Initialize margin management if needed
    // m_money = new CMoneyFixedMargin();
    // if(m_money == NULL)
    // {
    //     Print("Failed to create money management object.");
    //     return(INIT_FAILED);
    // }

    //--- Create handle for Moving Average if needed
    // Example: Not used in this TradingBot as strategies handle their own indicators

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Release any indicator handles if created globally
    if(handle_MA_fast != INVALID_HANDLE)
        IndicatorRelease(handle_MA_fast);

    //--- Delete any dynamically created objects
    // if(m_money != NULL)
    //     delete m_money;

    //--- Clean up
    // Delete dashboard objects if any
    // ObjectsDeleteAll(0, OBJ_LABEL, 0, 0);

    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    datetime current_time = TimeCurrent();

    //--- Check if it's time to perform analysis (e.g., 15 minutes before a session)
    for(int i = 0; i < ArraySize(sessions); i++)
    {
        TradingSession session = sessions[i];
        string session_start_str = TimeToString(current_time, TIME_DATE) + " " + FormatTime(session.StartHour, session.StartMinute);
        datetime session_start = StringToTime(session_start_str);
        string session_end_str = TimeToString(current_time, TIME_DATE) + " " + FormatTime(session.EndHour, session.EndMinute);
        datetime session_end = StringToTime(session_end_str);

        // Handle overnight sessions where EndHour is 0
        if(session.EndHour == 0)
            session_end += 24 * 3600;

        // If session start today has already passed, consider next day's session
        if(session_start <= current_time)
        {
            session_start += 24 * 3600;
            session_end += 24 * 3600;
        }

        // Calculate analysis time (15 minutes before session start)
        datetime analysis_time = session_start - 15 * 60;

        // If current time is equal or greater than analysis_time and analysis hasn't been done for this session
        if(current_time >= analysis_time && last_analysis_time < analysis_time)
        {
            // Perform analysis for this session
            Print("Performing analysis for ", session.Name, " session.");

            // Step 1: Analyze Historical Data (Placeholder)
            // Implement actual profit and drawdown calculation based on historical data
            double profit_sc = 500.0;      // Placeholder
            double drawdown_sc = 0.10;     // Placeholder (10%)
            double profit_sw = 800.0;      // Placeholder
            double drawdown_sw = 0.15;     // Placeholder (15%)
            double profit_br = 600.0;      // Placeholder
            double drawdown_br = 0.18;     // Placeholder (18%)
            double profit_mr = 700.0;      // Placeholder
            double drawdown_mr = 0.12;     // Placeholder (12%)

            // Store scores with drawdown consideration
            double scores[] = { -1, -1, -1, -1 };
            string selected_strategy = "";
            double selected_profit = 0.0;
            double selected_drawdown = 0.0;

            // Evaluate Scalping
            if(drawdown_sc <= 0.20)
            {
                scores[0] = profit_sc;
            }

            // Evaluate Swing Trading
            if(drawdown_sw <= 0.20)
            {
                scores[1] = profit_sw;
            }

            // Evaluate Breakout
            if(drawdown_br <= 0.20)
            {
                scores[2] = profit_br;
            }

            // Evaluate Mean Reversion
            if(drawdown_mr <= 0.20)
            {
                scores[3] = profit_mr;
            }

            // Select the strategy with the highest profit among those with drawdown <=20%
            int best_strategy_index = -1;
            double max_profit = -1.0;
            for(int j = 0; j < ArraySize(scores); j++)
            {
                if(scores[j] > max_profit)
                {
                    max_profit = scores[j];
                    best_strategy_index = j;
                }
            }

            if(best_strategy_index >=0 && best_strategy_index < ArraySize(scores) && scores[best_strategy_index] != -1)
            {
                switch(best_strategy_index)
                {
                    case 0: 
                        selected_strategy = "Scalping";
                        selected_profit = profit_sc;
                        selected_drawdown = drawdown_sc;
                        break;
                    case 1: 
                        selected_strategy = "SwingTrading";
                        selected_profit = profit_sw;
                        selected_drawdown = drawdown_sw;
                        break;
                    case 2: 
                        selected_strategy = "Breakout";
                        selected_profit = profit_br;
                        selected_drawdown = drawdown_br;
                        break;
                    case 3: 
                        selected_strategy = "MeanReversion";
                        selected_profit = profit_mr;
                        selected_drawdown = drawdown_mr;
                        break;
                    default: 
                        selected_strategy = "";
                        break;
                }
            }
            else
            {
                Print("No strategy meets the Drawdown criteria for ", session.Name, " session.");
            }

            // Step 2: Execute Selected Strategy
            if(selected_strategy != "")
            {
                Print("Selected Strategy: ", selected_strategy, 
                      " | Profit: ", selected_profit, 
                      " | Drawdown: ", selected_drawdown * 100, "% | Session: ", session.Name);
                ExecuteStrategy(selected_strategy, session.Name);
            }

            // Step 3: Update Dashboard (Placeholder)
            // Implement dashboard updates if needed

            // Update last_analysis_time
            last_analysis_time = current_time;
        }
    }

    //--- Manage all open positions
    ManageOrders();
}

//+------------------------------------------------------------------+
//| Execute Strategy                                                |
//+------------------------------------------------------------------+
void ExecuteStrategy(string strategy, string sessionName)
{
    double entry = 0.0;
    double tp = 0.0;
    double sl = 0.0;
    bool isBuy = true;

    bool entry_found = false;

    if(strategy == "Scalping")
    {
        entry_found = ScalpingEntry(entry, tp, sl, isBuy, 
                                    Timeframe, ScalpingRSIPeriod, ScalpingBollingerBandsPeriod, 
                                    ScalpingATRMultiplier, ScalpingRiskRewardRatio);
    }
    else if(strategy == "SwingTrading")
    {
        entry_found = SwingTradingEntry(entry, tp, sl, isBuy, 
                                        Timeframe, SwingRSIPeriod, SwingFastMAPeriod, 
                                        SwingSlowMAPeriod, SwingATRMultiplier, SwingRiskRewardRatio);
    }
    else if(strategy == "Breakout")
    {
        entry_found = BreakoutEntry(entry, tp, sl, isBuy, 
                                    Timeframe, BreakoutVolumeThreshold, BreakoutRiskRewardRatio);
    }
    else if(strategy == "MeanReversion")
    {
        entry_found = MeanReversionEntry(entry, tp, sl, isBuy, 
                                        Timeframe, MeanReversionBollingerBandsPeriod, 
                                        MeanReversionDeviation, MeanReversionATRMultiplier, 
                                        MeanReversionRiskRewardRatio);
    }

    // If a trading signal is found, place the order
    if(entry_found && entry > 0)
    {
        string comment = StringFormat("%s | Session: %s", strategy, sessionName);
        if(isBuy)
        {
            if(trade.Buy(FixedLotSize, _Symbol, entry, sl, tp, comment))
            {
                Print("Buy Order placed successfully. Comment: ", comment);
            }
            else
            {
                Print("Failed to place Buy Order. Error: ", trade.ResultRetcodeDescription());
            }
        }
        else
        {
            if(trade.Sell(FixedLotSize, _Symbol, entry, sl, tp, comment))
            {
                Print("Sell Order placed successfully. Comment: ", comment);
            }
            else
            {
                Print("Failed to place Sell Order. Error: ", trade.ResultRetcodeDescription());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop                                             |
//+------------------------------------------------------------------+
void ApplyTrailingStop(ulong ticket)
{
    if(!m_position.SelectByTicket(ticket))
        return;

    double sl = m_position.StopLoss();
    double newSL = 0.0;

    if(m_position.Type() == POSITION_TYPE_BUY)
    {
        newSL = m_position.PriceCurrent() - TrailingStopPips * m_symbol.Point();
        if(newSL > sl)
        {
            if(!trade.PositionModify(ticket, newSL, m_position.TakeProfit()))
            {
                Print("Error applying trailing stop for Buy Order: ", trade.ResultRetcodeDescription());
            }
        }
    }
    else if(m_position.Type() == POSITION_TYPE_SELL)
    {
        newSL = m_position.PriceCurrent() + TrailingStopPips * m_symbol.Point();
        if(newSL < sl)
        {
            if(!trade.PositionModify(ticket, newSL, m_position.TakeProfit()))
            {
                Print("Error applying trailing stop for Sell Order: ", trade.ResultRetcodeDescription());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Close Order After Max Holding Time                              |
//+------------------------------------------------------------------+
void CloseOrderAfterMaxTime(ulong ticket)
{
    if(!m_position.SelectByTicket(ticket))
        return;

    datetime openTime = m_position.Time();
    if(TimeCurrent() - openTime > MaxHoldingTime * 60)
    {
        if(trade.PositionClose(ticket))
        {
            Print("Position closed due to max holding time: ", ticket);
        }
        else
        {
            Print("Failed to close position due to max holding time. Error: ", trade.ResultRetcodeDescription());
        }
    }
}

//+------------------------------------------------------------------+
//| Manage All Open Orders                                          |
//+------------------------------------------------------------------+
void ManageOrders()
{
    for(int i = PositionsTotal()-1; i >=0; i--)
    {
        if(m_position.SelectByIndex(i))
        {
            if(m_position.Symbol() == m_symbol.Name() && m_position.Magic() == MAGIC_NUMBER)
            {
                ulong ticket = m_position.Ticket();
                ApplyTrailingStop(ticket);
                CloseOrderAfterMaxTime(ticket);
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
    if(m_symbol.Ask() == 0 || m_symbol.Bid() == 0)
        return(false);
    //---
    return(true);
}

//+------------------------------------------------------------------+
//| Format Time Helper Function                                     |
//+------------------------------------------------------------------+
string FormatTime(int hour, int minute)
{
    return StringFormat("%02d:%02d", hour, minute);
}
