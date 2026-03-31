-- MT5 Account Indicators Schema
-- Stores account-level data: equity, balance, margin, P&L, swaps
-- Stores open positions for per-position breakdown
-- Stores trade history for Sharpe ratio computation

CREATE TABLE mt5_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_number TEXT NOT NULL UNIQUE,
  account_name TEXT NOT NULL,
  broker TEXT NOT NULL DEFAULT 'Demo Broker',
  currency TEXT NOT NULL DEFAULT 'USD',
  leverage INTEGER NOT NULL DEFAULT 100,
  balance DECIMAL(15,2) NOT NULL DEFAULT 0,
  equity DECIMAL(15,2) NOT NULL DEFAULT 0,
  margin DECIMAL(15,2) NOT NULL DEFAULT 0,
  free_margin DECIMAL(15,2) NOT NULL DEFAULT 0,
  margin_level DECIMAL(10,2),        -- equity / margin * 100, NULL when no positions
  floating_pl DECIMAL(15,2) NOT NULL DEFAULT 0,  -- sum of open position profits
  swap DECIMAL(15,2) NOT NULL DEFAULT 0,          -- total swap on open positions
  commission DECIMAL(15,2) NOT NULL DEFAULT 0,
  last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Open positions
CREATE TABLE mt5_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id UUID NOT NULL REFERENCES mt5_accounts(id) ON DELETE CASCADE,
  ticket BIGINT NOT NULL,
  symbol TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('buy', 'sell')),
  volume DECIMAL(10,2) NOT NULL,
  open_price DECIMAL(15,5) NOT NULL,
  current_price DECIMAL(15,5),
  sl DECIMAL(15,5),
  tp DECIMAL(15,5),
  profit DECIMAL(15,2) NOT NULL DEFAULT 0,
  swap DECIMAL(15,2) NOT NULL DEFAULT 0,
  commission DECIMAL(15,2) NOT NULL DEFAULT 0,
  open_time TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (account_id, ticket)
);

-- Closed trade history — used to calculate Sharpe ratio
CREATE TABLE mt5_trade_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id UUID NOT NULL REFERENCES mt5_accounts(id) ON DELETE CASCADE,
  ticket BIGINT NOT NULL,
  symbol TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('buy', 'sell')),
  volume DECIMAL(10,2) NOT NULL,
  open_price DECIMAL(15,5) NOT NULL,
  close_price DECIMAL(15,5) NOT NULL,
  profit DECIMAL(15,2) NOT NULL DEFAULT 0,
  swap DECIMAL(15,2) NOT NULL DEFAULT 0,
  commission DECIMAL(15,2) NOT NULL DEFAULT 0,
  open_time TIMESTAMPTZ NOT NULL,
  close_time TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (account_id, ticket)
);

-- Indexes
CREATE INDEX idx_mt5_positions_account ON mt5_positions(account_id);
CREATE INDEX idx_mt5_trade_history_account ON mt5_trade_history(account_id);
CREATE INDEX idx_mt5_trade_history_close_time ON mt5_trade_history(close_time);
