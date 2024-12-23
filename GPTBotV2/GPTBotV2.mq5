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
CSymbolInfo      m_symbol;                     // Symbol info object
CAccountInfo     m_account;                    // Account info wrapper
// CMoneyFixedMargin *m_money;                 // Nếu bạn cần quản lý margin

//--- Input Parameters
input int AnalysisPeriod = 30; // Number of days for historical analysis (tăng lên để backtest hiệu quả hơn)
input ENUM_TIMEFRAMES Timeframe = PERIOD_M15; // Trading timeframe
input string RiskManagementMode = "FixedLot"; // "FixedLot" or "Risk-Based"
input double FixedLotSize = 0.01; // Fixed lot size
input double RiskPercentage = 2.0; // Risk percentage per trade

// Performance Evaluation Parameters
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

//--- Structures for Backtesting
struct TradeResult
{
    double profit;
    double balance;
    double drawdown;
};

//--- Global Variables for Backtesting
double initialBalance = 10000.0; // Initial account balance for backtesting
double balance_bt = initialBalance;
double peakBalance_bt = initialBalance;
double maxDrawdown_bt = 0.0;
TradeResult tradeResults_bt[];

//--- Dashboard Variables
// Define dashboard labels
string dashboard_labels[] = {
    "Dashboard_Profit",
    "Dashboard_Drawdown",
    "Dashboard_SelectedStrategy"
};

//+------------------------------------------------------------------+
//| Initialize Dashboard                                            |
//+------------------------------------------------------------------+
void InitializeDashboard()
{
    // Create dashboard labels
    for(int i = 0; i < ArraySize(dashboard_labels); i++)
    {
        if(!ObjectCreate(0, dashboard_labels[i], OBJ_LABEL, 0, 0, 0))
        {
            Print("Failed to create dashboard label: ", dashboard_labels[i]);
            continue;
        }
        ObjectSetInteger(0, dashboard_labels[i], OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, dashboard_labels[i], OBJPROP_YDISTANCE, 10 + i * 20);
        ObjectSetInteger(0, dashboard_labels[i], OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, dashboard_labels[i], OBJPROP_FONTSIZE, 12);
        ObjectSetString(0, dashboard_labels[i], OBJPROP_TEXT, " ");
    }
}

//+------------------------------------------------------------------+
//| Delete Dashboard                                                 |
//+------------------------------------------------------------------+
void DeleteDashboard()
{
    // Delete dashboard labels
    for(int i = 0; i < ArraySize(dashboard_labels); i++)
    {
        ObjectDelete(0, dashboard_labels[i]);
    }
}

//+------------------------------------------------------------------+
//| Update Dashboard                                                 |
//+------------------------------------------------------------------+
void UpdateDashboard(string strategy, double profit, double drawdown, string sessionName)
{
    // Update Profit
    string profit_text = StringFormat("Session: %s | Strategy: %s | Profit: %.2f", sessionName, strategy, profit);
    ObjectSetString(0, dashboard_labels[0], OBJPROP_TEXT, profit_text);

    // Update Drawdown
    string drawdown_text = StringFormat("Drawdown: %.2f%%", drawdown * 100);
    ObjectSetString(0, dashboard_labels[1], OBJPROP_TEXT, drawdown_text);

    // Update Selected Strategy
    string strategy_text = StringFormat("Selected Strategy: %s", strategy);
    ObjectSetString(0, dashboard_labels[2], OBJPROP_TEXT, strategy_text);
}

//+------------------------------------------------------------------+
//| Backtesting Functions                                           |
//+------------------------------------------------------------------+

//--- Function to load historical data
bool LoadHistoricalData(string symbol, ENUM_TIMEFRAMES timeframe, int period, MqlRates &rates[])
{
    datetime to_time = TimeCurrent();
    datetime from_time = to_time - period * 24 * 2; // Number of days of historical data

    int copied = CopyRates(symbol, timeframe, from_time, to_time, rates);
    if(copied <= 0)
    {
        Print("Failed to load historical data. Error: ", GetLastError());
        return false;
    }
    return true;
}

//--- Function to simulate a single trade
double SimulateTrade(double entry, double tp, double sl, bool isBuy, const MqlRates &nextRate, double lotSize, double contractSize)
{
    if(isBuy)
    {
        // Buy: Check SL and TP
        if(nextRate.low <= sl)
        {
            return (sl - entry) * lotSize * contractSize; // Loss
        }
        else if(nextRate.high >= tp)
        {
            return (tp - entry) * lotSize * contractSize; // Profit
        }
    }
    else
    {
        // Sell: Check SL and TP
        if(nextRate.high >= sl)
        {
            return (entry - sl) * lotSize * contractSize; // Loss
        }
        else if(nextRate.low <= tp)
        {
            return (entry - tp) * lotSize * contractSize; // Profit
        }
    }
    return 0.0; // No profit/loss if neither TP nor SL is hit
}

//--- Function to simulate backtest for a strategy
bool SimulateStrategy(string symbol, ENUM_TIMEFRAMES timeframe, int period, string strategy, double lotSize, double contractSize, double &totalProfit, double &maxDrawdown)
{
    MqlRates rates[];
    if(!LoadHistoricalData(symbol, timeframe, period, rates))
    {
        return false;
    }

    // Initialize backtest variables
    double balance = initialBalance;
    double peakBalance = initialBalance;
    double maxDD = 0.0;

    // Iterate through historical data
    for(int i = 0; i < ArraySize(rates) -1; i++) // i < n-1 to access rates[i+1]
    {
        double entry = 0.0, tp = 0.0, sl = 0.0;
        bool isBuy = true;
        bool signal = false;

        // Determine trading signal based on strategy
        if(strategy == "Breakout")
        {
            signal = BreakoutEntry(entry, tp, sl, isBuy, timeframe, BreakoutVolumeThreshold, BreakoutRiskRewardRatio);
        }
        else if(strategy == "Scalping")
        {
            signal = ScalpingEntry(entry, tp, sl, isBuy, 
                                   timeframe, ScalpingRSIPeriod, ScalpingBollingerBandsPeriod, 
                                   ScalpingATRMultiplier, ScalpingRiskRewardRatio);
        }
        else if(strategy == "SwingTrading")
        {
            signal = SwingTradingEntry(entry, tp, sl, isBuy, 
                                       timeframe, SwingRSIPeriod, SwingFastMAPeriod, SwingSlowMAPeriod, 
                                       SwingATRMultiplier, SwingRiskRewardRatio);
        }
        else if(strategy == "MeanReversion")
        {
            signal = MeanReversionEntry(entry, tp, sl, isBuy, 
                                       timeframe, MeanReversionBollingerBandsPeriod, MeanReversionDeviation, 
                                       MeanReversionATRMultiplier, MeanReversionRiskRewardRatio);
        }

        // If signal is found, simulate trade
        if(signal && entry > 0)
        {
            double profit = SimulateTrade(entry, tp, sl, isBuy, rates[i+1], lotSize, contractSize);
            balance += profit;

            // Update peak balance
            if(balance > peakBalance)
            {
                peakBalance = balance;
            }

            // Calculate current drawdown
            double drawdown = peakBalance - balance;
            if(drawdown > maxDD)
            {
                maxDD = drawdown;
            }
        }
    }

    // Assign results
    totalProfit = balance - initialBalance;
    maxDrawdown = maxDD;

    return true;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Initialize symbol
    if(!m_symbol.Name(Symbol())) // sets symbol name
        return(INIT_FAILED);
    if(!RefreshRates())
        return(INIT_FAILED);

    //--- Initialize trade settings
    trade.SetExpertMagicNumber(MAGIC_NUMBER);
    trade.SetDeviationInPoints(10); // Slippage
    trade.SetTypeFilling(ORDER_FILLING_FOK); // Corrected ENUM_ORDER_TYPE_FILLING

    //--- Initialize Dashboard
    InitializeDashboard();

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
    DeleteDashboard();

    ChartRedraw();
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

            // Step 1: Analyze Historical Data
            // Perform backtest for each strategy
            double profit_sc, drawdown_sc;
            double profit_sw, drawdown_sw;
            double profit_br, drawdown_br;
            double profit_mr, drawdown_mr;

            // Backtest Scalping
            if(!SimulateStrategy(Symbol(), Timeframe, AnalysisPeriod, "Scalping", FixedLotSize, m_symbol.ContractSize(), profit_sc, drawdown_sc))
            {
                Print("Backtest failed for Scalping strategy.");
            }

            // Backtest Swing Trading
            if(!SimulateStrategy(Symbol(), Timeframe, AnalysisPeriod, "SwingTrading", FixedLotSize, m_symbol.ContractSize(), profit_sw, drawdown_sw))
            {
                Print("Backtest failed for SwingTrading strategy.");
            }

            // Backtest Breakout
            if(!SimulateStrategy(Symbol(), Timeframe, AnalysisPeriod, "Breakout", FixedLotSize, m_symbol.ContractSize(), profit_br, drawdown_br))
            {
                Print("Backtest failed for Breakout strategy.");
            }

            // Backtest Mean Reversion
            if(!SimulateStrategy(Symbol(), Timeframe, AnalysisPeriod, "MeanReversion", FixedLotSize, m_symbol.ContractSize(), profit_mr, drawdown_mr))
            {
                Print("Backtest failed for MeanReversion strategy.");
            }

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

            // Step 3: Update Dashboard
            UpdateDashboard(selected_strategy, selected_profit, selected_drawdown, session.Name);

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
