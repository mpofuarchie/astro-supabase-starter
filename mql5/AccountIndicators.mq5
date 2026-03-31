//+------------------------------------------------------------------+
//|  AccountIndicators.mq5                                           |
//|  MT5 Account Overview Panel                                      |
//|                                                                  |
//|  Displays on-chart panel showing:                                |
//|    • Equity  (vs Balance)                                        |
//|    • Floating P&L  (open positions)                             |
//|    • Swap  (total rollover on open positions)                    |
//|    • Total Margin  (used + free)                                 |
//|    • Margin Level  (colour-coded)                                |
//|    • Sharpe Ratio  (annualised, from deal history)              |
//|                                                                  |
//|  Install: copy to MQL5/Indicators/ and compile in MetaEditor.   |
//+------------------------------------------------------------------+
#property copyright   "MT5 Account Indicators"
#property version     "1.00"
#property description "On-chart account overview: equity, P&L, swaps, margin, Sharpe ratio"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//── Inputs ──────────────────────────────────────────────────────────
input group            "Panel Position"
input int              InpPanelX         = 16;               // X offset (px from left)
input int              InpPanelY         = 28;               // Y offset (px from top)
input ENUM_BASE_CORNER InpCorner         = CORNER_LEFT_UPPER;// Chart corner

input group            "Appearance"
input int              InpFontSize       = 9;                 // Base font size
input string           InpFont           = "Courier New";     // Font
input color            InpColorBg        = C'32,32,32';       // Panel background
input color            InpColorBorder    = C'70,80,90';       // Border
input color            InpColorTitle     = clrWhite;          // Title text
input color            InpColorLabel     = C'150,160,170';    // Label text
input color            InpColorNeutral   = clrWhite;          // Neutral values
input color            InpColorPositive  = C'74,222,128';     // Positive (green-400)
input color            InpColorNegative  = C'248,113,113';    // Negative (red-400)
input color            InpColorWarning   = C'250,204,21';     // Warning (yellow-400)

input group            "Sharpe Ratio"
input int              InpSharpedays     = 365;               // History window (days)
input int              InpSharpeRefresh  = 60;                // Recalc interval (sec)

//── Constants ────────────────────────────────────────────────────────
#define PFX  "ACCT_"     // Object name prefix
#define PAD  10          // Inner padding
#define COL2 180         // X offset of value column

//── Panel row IDs (used to build object names) ───────────────────────
enum ERow
{
   ROW_BG = 0,
   ROW_TITLE,
   ROW_ACCT,
   ROW_DIV1,
   ROW_EQ,
   ROW_BAL,
   ROW_PL,
   ROW_SWAP,
   ROW_DIV2,
   ROW_MARGIN,
   ROW_FREEMARGIN,
   ROW_ML,
   ROW_DIV3,
   ROW_SHARPE,
   ROW_SHARPE_SUB,
   ROW_DIV4,
   ROW_OPENPOS,
   ROW_UPDATED,
   ROW_COUNT
};

//── Label slot per row: Label + Value ───────────────────────────────
struct SRow
{
   string lbl;   // object name for label
   string val;   // object name for value
};

SRow     g_rows[ROW_COUNT];
double   g_sharpe         = EMPTY_VALUE;
datetime g_lastSharpeTime = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   // Build object name arrays
   BuildNames();

   // Create all objects once
   CreateAllObjects();

   // First Sharpe calculation (can take a moment)
   g_sharpe = CalcSharpe(InpSharpedays);
   g_lastSharpeTime = TimeCurrent();

   // Full panel redraw
   RefreshPanel();
   ChartRedraw();

   EventSetTimer(InpSharpeRefresh);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(ChartID(), PFX);
   ChartRedraw();
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
   RefreshPanel();
   ChartRedraw();
   return rates_total;
}

//+------------------------------------------------------------------+
void OnTimer()
{
   // Periodically recalculate Sharpe (expensive history query)
   if(TimeCurrent() - g_lastSharpeTime >= InpSharpeRefresh)
   {
      g_sharpe         = CalcSharpe(InpSharpedays);
      g_lastSharpeTime = TimeCurrent();
   }
   RefreshPanel();
   ChartRedraw();
}

//+------------------------------------------------------------------+
//  Core: populate every label/value on the panel
//+------------------------------------------------------------------+
void RefreshPanel()
{
   string ccy      = AccountInfoString(ACCOUNT_CURRENCY);
   long   acctNo   = AccountInfoInteger(ACCOUNT_LOGIN);
   long   leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   string broker   = AccountInfoString(ACCOUNT_COMPANY);

   double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin     = AccountInfoDouble(ACCOUNT_MARGIN);
   double freeMargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
   double mlevel     = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   double openProfit = AccountInfoDouble(ACCOUNT_PROFIT); // total open P&L incl swap

   // Compute total swap across open positions
   double totalSwap = 0;
   int    posCount  = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i) == 0) continue;
      totalSwap += PositionGetDouble(POSITION_SWAP);
      posCount++;
   }

   // Pure floating P&L (strip swap out)
   double floatingPL = openProfit - totalSwap;

   //── Row: Title ────────────────────────────────────────────────────
   int y = InpPanelY + PAD;

   SetText(ROW_TITLE, true,  "MT5 Account Indicators", "",
           InpPanelX + PAD, y, InpColorTitle, InpFontSize + 1);
   y += RowH(InpFontSize + 1) + 4;

   //── Row: Account info ─────────────────────────────────────────────
   SetText(ROW_ACCT, true,
           StringFormat("#%d  %s  1:%d  %s", acctNo, broker, leverage, ccy),
           "", InpPanelX + PAD, y, InpColorLabel, InpFontSize - 1);
   y += RowH(InpFontSize - 1) + 2;

   Divider(ROW_DIV1, y);
   y += RowH(InpFontSize - 2) + 2;

   //── Row: Equity ───────────────────────────────────────────────────
   color eqColor = equity >= balance ? InpColorPositive : InpColorNegative;
   SetPair(ROW_EQ, "EQUITY", Money(equity, ccy),
           InpPanelX + PAD, y, InpColorLabel, eqColor, InpFontSize);
   y += RowH(InpFontSize) + 1;

   //── Row: Balance (sub-row) ────────────────────────────────────────
   SetPair(ROW_BAL, "  Balance", Money(balance, ccy),
           InpPanelX + PAD, y, InpColorLabel, InpColorNeutral, InpFontSize - 1);
   y += RowH(InpFontSize - 1) + 4;

   //── Row: Floating P&L ────────────────────────────────────────────
   color plColor = floatingPL >= 0 ? InpColorPositive : InpColorNegative;
   string plStr  = (floatingPL >= 0 ? "+" : "") + Money(floatingPL, ccy);
   SetPair(ROW_PL, "FLOATING P&L", plStr,
           InpPanelX + PAD, y, InpColorLabel, plColor, InpFontSize);
   y += RowH(InpFontSize) + 4;

   //── Row: Swap ─────────────────────────────────────────────────────
   color swapColor = totalSwap < 0 ? InpColorNegative
                   : totalSwap > 0 ? InpColorPositive
                   : InpColorNeutral;
   string swapStr = (totalSwap >= 0 ? "+" : "") + Money(totalSwap, ccy);
   SetPair(ROW_SWAP, "SWAP", swapStr,
           InpPanelX + PAD, y, InpColorLabel, swapColor, InpFontSize);
   y += RowH(InpFontSize) + 2;

   Divider(ROW_DIV2, y);
   y += RowH(InpFontSize - 2) + 2;

   //── Row: Total Margin ─────────────────────────────────────────────
   SetPair(ROW_MARGIN, "TOTAL MARGIN", Money(margin, ccy),
           InpPanelX + PAD, y, InpColorLabel, InpColorNeutral, InpFontSize);
   y += RowH(InpFontSize) + 1;

   //── Row: Free Margin (sub-row) ───────────────────────────────────
   SetPair(ROW_FREEMARGIN, "  Free Margin", Money(freeMargin, ccy),
           InpPanelX + PAD, y, InpColorLabel, InpColorNeutral, InpFontSize - 1);
   y += RowH(InpFontSize - 1) + 4;

   //── Row: Margin Level ────────────────────────────────────────────
   string mlStr;
   color  mlColor;
   if(margin <= 0)
   {
      mlStr  = "N/A";
      mlColor = InpColorLabel;
   }
   else
   {
      mlStr  = DoubleToString(mlevel, 2) + " %";
      mlColor = mlevel >= 200 ? InpColorPositive
               : mlevel < 100 ? InpColorNegative
               : InpColorWarning;
   }
   SetPair(ROW_ML, "MARGIN LEVEL", mlStr,
           InpPanelX + PAD, y, InpColorLabel, mlColor, InpFontSize);
   y += RowH(InpFontSize) + 2;

   Divider(ROW_DIV3, y);
   y += RowH(InpFontSize - 2) + 2;

   //── Row: Sharpe Ratio ────────────────────────────────────────────
   string sharpeStr;
   color  sharpeColor;
   if(g_sharpe == EMPTY_VALUE)
   {
      sharpeStr   = "Calculating...";
      sharpeColor = InpColorLabel;
   }
   else if(g_sharpe == 0)
   {
      sharpeStr   = "N/A  (<2 days data)";
      sharpeColor = InpColorLabel;
   }
   else
   {
      sharpeStr   = DoubleToString(g_sharpe, 2);
      sharpeColor = g_sharpe >= 1.0 ? InpColorPositive
                  : g_sharpe <  0   ? InpColorNegative
                  : InpColorWarning;
   }
   SetPair(ROW_SHARPE, "SHARPE RATIO", sharpeStr,
           InpPanelX + PAD, y, InpColorLabel, sharpeColor, InpFontSize);
   y += RowH(InpFontSize) + 1;

   // Sub-label: history window
   SetText(ROW_SHARPE_SUB, false,
           StringFormat("  Annualised · last %d days", InpSharpedays),
           "", InpPanelX + PAD, y, InpColorLabel, InpFontSize - 2);
   y += RowH(InpFontSize - 2) + 2;

   Divider(ROW_DIV4, y);
   y += RowH(InpFontSize - 2) + 2;

   //── Row: Open positions count ────────────────────────────────────
   SetPair(ROW_OPENPOS, "OPEN POSITIONS", IntegerToString(posCount),
           InpPanelX + PAD, y, InpColorLabel, InpColorNeutral, InpFontSize);
   y += RowH(InpFontSize) + 4;

   //── Row: Last updated ────────────────────────────────────────────
   SetText(ROW_UPDATED, false,
           "Updated: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES),
           "", InpPanelX + PAD, y, InpColorLabel, InpFontSize - 2);
   y += RowH(InpFontSize - 2) + PAD;

   // Resize background to snugly fit content
   long chartId = ChartID();
   ObjectSetInteger(chartId, PFX + "BG", OBJPROP_YSIZE, y - InpPanelY + 4);
}

//+------------------------------------------------------------------+
//  Sharpe ratio  (annualised from daily deal returns)
//+------------------------------------------------------------------+
double CalcSharpe(int historyDays)
{
   datetime fromTime = TimeCurrent() - (datetime)(historyDays * 86400);
   if(!HistorySelect(fromTime, TimeCurrent()))
      return 0;

   int totalDeals = HistoryDealsTotal();
   if(totalDeals < 2) return 0;

   // Aggregate net P&L per calendar day
   double   dayProfit[];
   datetime dayDate[];
   int      dayCount = 0;
   ArrayResize(dayProfit, totalDeals);
   ArrayResize(dayDate,   totalDeals);

   for(int i = 0; i < totalDeals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;

      ENUM_DEAL_TYPE  dt = (ENUM_DEAL_TYPE) HistoryDealGetInteger(ticket, DEAL_TYPE);
      ENUM_DEAL_ENTRY de = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);

      // Only closing deals that realise P&L
      if((dt != DEAL_TYPE_BUY && dt != DEAL_TYPE_SELL) ||
         (de != DEAL_ENTRY_OUT && de != DEAL_ENTRY_INOUT))
         continue;

      double net = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                 + HistoryDealGetDouble(ticket, DEAL_SWAP)
                 + HistoryDealGetDouble(ticket, DEAL_COMMISSION);

      datetime closeTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      string   dayKey    = TimeToString(closeTime, TIME_DATE);

      bool found = false;
      for(int d = 0; d < dayCount; d++)
      {
         if(TimeToString(dayDate[d], TIME_DATE) == dayKey)
         {
            dayProfit[d] += net;
            found = true;
            break;
         }
      }
      if(!found)
      {
         dayDate[dayCount]   = closeTime;
         dayProfit[dayCount] = net;
         dayCount++;
      }
   }

   if(dayCount < 2) return 0;

   // Estimate starting balance (current balance minus total realised P&L)
   double realisedTotal = 0;
   for(int d = 0; d < dayCount; d++) realisedTotal += dayProfit[d];
   double startBal = AccountInfoDouble(ACCOUNT_BALANCE) - realisedTotal;
   if(startBal <= 0) startBal = AccountInfoDouble(ACCOUNT_BALANCE);

   // Build daily-return series
   double returns[];
   ArrayResize(returns, dayCount);
   double runBal = startBal;
   for(int d = 0; d < dayCount; d++)
   {
      returns[d] = (runBal > 0) ? dayProfit[d] / runBal : 0;
      runBal    += dayProfit[d];
   }

   // Mean
   double sum = 0;
   for(int d = 0; d < dayCount; d++) sum += returns[d];
   double mean = sum / dayCount;

   // Sample std dev
   double varSum = 0;
   for(int d = 0; d < dayCount; d++)
      varSum += MathPow(returns[d] - mean, 2);
   double stdDev = MathSqrt(varSum / (dayCount - 1));

   if(stdDev == 0) return 0;

   // Annualise using √252 trading days
   return (mean / stdDev) * MathSqrt(252);
}

//+------------------------------------------------------------------+
//  Object creation helpers
//+------------------------------------------------------------------+
void BuildNames()
{
   string ids[] = {
      "BG",
      "TITLE","ACCT","DIV1",
      "EQ_L","EQ_V","BAL_L","BAL_V",
      "PL_L","PL_V","SWAP_L","SWAP_V",
      "DIV2",
      "MARGIN_L","MARGIN_V","FREEMARGIN_L","FREEMARGIN_V","ML_L","ML_V",
      "DIV3",
      "SHARPE_L","SHARPE_V","SHARPE_SUB_L","SHARPE_SUB_V",
      "DIV4",
      "OPENPOS_L","OPENPOS_V",
      "UPDATED_L","UPDATED_V"
   };

   // Map row IDs to label/val object names
   g_rows[ROW_BG]          = MakeRow("BG",          "BG");
   g_rows[ROW_TITLE]       = MakeRow("TITLE",        "TITLE");
   g_rows[ROW_ACCT]        = MakeRow("ACCT",         "ACCT");
   g_rows[ROW_DIV1]        = MakeRow("DIV1",         "DIV1");
   g_rows[ROW_EQ]          = MakeRow("EQ_L",         "EQ_V");
   g_rows[ROW_BAL]         = MakeRow("BAL_L",        "BAL_V");
   g_rows[ROW_PL]          = MakeRow("PL_L",         "PL_V");
   g_rows[ROW_SWAP]        = MakeRow("SWAP_L",       "SWAP_V");
   g_rows[ROW_DIV2]        = MakeRow("DIV2",         "DIV2");
   g_rows[ROW_MARGIN]      = MakeRow("MARGIN_L",     "MARGIN_V");
   g_rows[ROW_FREEMARGIN]  = MakeRow("FREEMARGIN_L", "FREEMARGIN_V");
   g_rows[ROW_ML]          = MakeRow("ML_L",         "ML_V");
   g_rows[ROW_DIV3]        = MakeRow("DIV3",         "DIV3");
   g_rows[ROW_SHARPE]      = MakeRow("SHARPE_L",     "SHARPE_V");
   g_rows[ROW_SHARPE_SUB]  = MakeRow("SHARPE_SUB_L", "SHARPE_SUB_V");
   g_rows[ROW_DIV4]        = MakeRow("DIV4",         "DIV4");
   g_rows[ROW_OPENPOS]     = MakeRow("OPENPOS_L",    "OPENPOS_V");
   g_rows[ROW_UPDATED]     = MakeRow("UPDATED_L",    "UPDATED_V");
}

SRow MakeRow(string lblSuffix, string valSuffix)
{
   SRow r;
   r.lbl = PFX + lblSuffix;
   r.val = PFX + valSuffix;
   return r;
}

void CreateAllObjects()
{
   long chartId = ChartID();

   // Background rectangle
   ObjectCreate(chartId, PFX+"BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_CORNER,       InpCorner);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_XDISTANCE,    InpPanelX - PAD);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_YDISTANCE,    InpPanelY - PAD);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_XSIZE,        COL2 + 145);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_YSIZE,        300);  // resized later
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_BGCOLOR,      InpColorBg);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_BORDER_COLOR, InpColorBorder);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_BORDER_TYPE,  BORDER_FLAT);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_WIDTH,        1);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_BACK,         false);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_HIDDEN,       true);
   ObjectSetInteger(chartId, PFX+"BG", OBJPROP_ZORDER,       0);

   // Label objects for each row
   for(int r = ROW_TITLE; r < ROW_COUNT; r++)
   {
      CreateLabel(chartId, g_rows[r].lbl);
      if(g_rows[r].lbl != g_rows[r].val) // avoid duplicate for single-col rows
         CreateLabel(chartId, g_rows[r].val);
   }
}

void CreateLabel(long chartId, string name)
{
   ObjectCreate(chartId, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, name, OBJPROP_CORNER,    InpCorner);
   ObjectSetInteger(chartId, name, OBJPROP_XDISTANCE, InpPanelX + PAD);
   ObjectSetInteger(chartId, name, OBJPROP_YDISTANCE, InpPanelY + PAD);
   ObjectSetInteger(chartId, name, OBJPROP_FONTSIZE,  InpFontSize);
   ObjectSetString(chartId,  name, OBJPROP_FONT,      InpFont);
   ObjectSetInteger(chartId, name, OBJPROP_COLOR,     InpColorLabel);
   ObjectSetInteger(chartId, name, OBJPROP_BACK,      false);
   ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(chartId, name, OBJPROP_HIDDEN,    true);
   ObjectSetInteger(chartId, name, OBJPROP_ZORDER,    1);
}

//+------------------------------------------------------------------+
//  SetPair: update a label+value row
//+------------------------------------------------------------------+
void SetPair(ERow row, string labelText, string valueText,
             int x, int y,
             color labelColor, color valueColor, int fontSize)
{
   long chartId = ChartID();
   // Label
   ObjectSetString(chartId,  g_rows[row].lbl, OBJPROP_TEXT,      labelText);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_COLOR,     labelColor);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_FONTSIZE,  fontSize - 1);
   ObjectSetString(chartId,  g_rows[row].lbl, OBJPROP_FONT,      InpFont);

   // Value (right-hand column)
   ObjectSetString(chartId,  g_rows[row].val, OBJPROP_TEXT,      valueText);
   ObjectSetInteger(chartId, g_rows[row].val, OBJPROP_XDISTANCE, InpPanelX + PAD + COL2);
   ObjectSetInteger(chartId, g_rows[row].val, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(chartId, g_rows[row].val, OBJPROP_COLOR,     valueColor);
   ObjectSetInteger(chartId, g_rows[row].val, OBJPROP_FONTSIZE,  fontSize);
   ObjectSetString(chartId,  g_rows[row].val, OBJPROP_FONT,      InpFont);
}

//+------------------------------------------------------------------+
//  SetText: single full-width label (no value column)
//+------------------------------------------------------------------+
void SetText(ERow row, bool isTitle,
             string labelText, string /*unused*/,
             int x, int y, color clr, int fontSize)
{
   long chartId = ChartID();
   ObjectSetString(chartId,  g_rows[row].lbl, OBJPROP_TEXT,      labelText);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_COLOR,     clr);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_FONTSIZE,  fontSize);
   ObjectSetString(chartId,  g_rows[row].lbl, OBJPROP_FONT,
                   isTitle ? InpFont + " Bold" : InpFont);
   // Clear value column for full-width rows
   ObjectSetString(chartId, g_rows[row].val, OBJPROP_TEXT, "");
}

//+------------------------------------------------------------------+
//  Divider row
//+------------------------------------------------------------------+
void Divider(ERow row, int y)
{
   long chartId = ChartID();
   string dashes = "──────────────────────────────────────";
   ObjectSetString(chartId,  g_rows[row].lbl, OBJPROP_TEXT,      dashes);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_XDISTANCE, InpPanelX + PAD);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_COLOR,     InpColorBorder);
   ObjectSetInteger(chartId, g_rows[row].lbl, OBJPROP_FONTSIZE,  InpFontSize - 3);
   ObjectSetString(chartId,  g_rows[row].val, OBJPROP_TEXT,      "");
}

//+------------------------------------------------------------------+
//  Utility: row pixel height for a given font size
//+------------------------------------------------------------------+
int RowH(int fontSize)
{
   return fontSize + 8;
}

//+------------------------------------------------------------------+
//  Utility: format monetary value
//+------------------------------------------------------------------+
string Money(double value, string ccy)
{
   return StringFormat("%s %.2f", ccy, value);
}
//+------------------------------------------------------------------+
