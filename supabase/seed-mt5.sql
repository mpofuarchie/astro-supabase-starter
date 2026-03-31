-- Demo MT5 account seed data
-- Run after applying the migration: 20260331000000_init-mt5-accounts.sql

-- ── Account ──────────────────────────────────────────────────────────────────
INSERT INTO mt5_accounts (
  account_number, account_name, broker, currency, leverage,
  balance, equity, margin, free_margin, margin_level,
  floating_pl, swap, commission, last_updated
) VALUES (
  '10045892',
  'Demo Trading Account',
  'MetaQuotes Ltd',
  'USD',
  100,
  12450.00,          -- balance
  12318.75,          -- equity  (balance + floating_pl + swap)
  620.00,            -- margin in use
  11698.75,          -- free margin
  1986.90,           -- margin level % (equity/margin*100)
  -108.50,           -- floating P&L on open positions
  -22.75,            -- total swap
  0.00,              -- commission
  NOW()
) ON CONFLICT (account_number) DO NOTHING;

-- ── Open positions ────────────────────────────────────────────────────────────
DO $$
DECLARE
  acc_id UUID;
BEGIN
  SELECT id INTO acc_id FROM mt5_accounts WHERE account_number = '10045892';

  INSERT INTO mt5_positions (
    account_id, ticket, symbol, type, volume,
    open_price, current_price, sl, tp,
    profit, swap, commission, open_time
  ) VALUES
    (acc_id, 12340001, 'EURUSD', 'buy',  0.50, 1.08520, 1.08310, 1.07800, 1.09500,  -105.00, -5.25, 0, NOW() - INTERVAL '3 days'),
    (acc_id, 12340002, 'GBPUSD', 'sell', 0.30, 1.27450, 1.27680, 1.28200, 1.26500,  -69.00, -8.40, 0, NOW() - INTERVAL '5 days'),
    (acc_id, 12340003, 'XAUUSD', 'buy',  0.10, 2315.00, 2318.50, 2290.00, 2380.00,   35.00, -5.20, 0, NOW() - INTERVAL '1 day'),
    (acc_id, 12340004, 'USDJPY', 'sell', 0.20, 149.850, 149.920, 151.000, 148.000,  -18.67, -3.90, 0, NOW() - INTERVAL '2 days'),
    (acc_id, 12340005, 'AUDUSD', 'buy',  0.40, 0.65230, 0.65370, 0.64800, 0.66000,   56.00,  0.00, 0, NOW() - INTERVAL '6 hours')
  ON CONFLICT (account_id, ticket) DO NOTHING;
END $$;

-- ── Trade history (for Sharpe ratio) ─────────────────────────────────────────
DO $$
DECLARE
  acc_id UUID;
BEGIN
  SELECT id INTO acc_id FROM mt5_accounts WHERE account_number = '10045892';

  INSERT INTO mt5_trade_history (
    account_id, ticket, symbol, type, volume,
    open_price, close_price,
    profit, swap, commission,
    open_time, close_time
  ) VALUES
    (acc_id, 12330001, 'EURUSD', 'buy',  0.50, 1.07800, 1.08450,  325.00,  -6.30, 0, NOW()-INTERVAL '30 days', NOW()-INTERVAL '25 days'),
    (acc_id, 12330002, 'GBPUSD', 'sell', 0.20, 1.28900, 1.27600,  260.00,  -4.80, 0, NOW()-INTERVAL '28 days', NOW()-INTERVAL '24 days'),
    (acc_id, 12330003, 'XAUUSD', 'buy',  0.10, 2280.00, 2305.00,  250.00,  -5.10, 0, NOW()-INTERVAL '22 days', NOW()-INTERVAL '18 days'),
    (acc_id, 12330004, 'USDJPY', 'buy',  0.30, 147.500, 148.900,  280.50,  -9.00, 0, NOW()-INTERVAL '20 days', NOW()-INTERVAL '15 days'),
    (acc_id, 12330005, 'EURUSD', 'sell', 0.40, 1.09200, 1.08500,  280.00,  -8.40, 0, NOW()-INTERVAL '18 days', NOW()-INTERVAL '12 days'),
    (acc_id, 12330006, 'AUDUSD', 'sell', 0.50, 0.66500, 0.65800,  350.00,   0.00, 0, NOW()-INTERVAL '15 days', NOW()-INTERVAL '10 days'),
    (acc_id, 12330007, 'GBPUSD', 'buy',  0.20, 1.26500, 1.25800, -140.00,  -3.60, 0, NOW()-INTERVAL '12 days', NOW()-INTERVAL '8 days'),
    (acc_id, 12330008, 'XAUUSD', 'sell', 0.10, 2325.00, 2340.00, -150.00,  -5.20, 0, NOW()-INTERVAL '10 days', NOW()-INTERVAL '6 days'),
    (acc_id, 12330009, 'EURUSD', 'buy',  0.30, 1.08100, 1.08900,  240.00,  -4.50, 0, NOW()-INTERVAL '8 days',  NOW()-INTERVAL '4 days'),
    (acc_id, 12330010, 'USDJPY', 'sell', 0.20, 150.200, 149.600,  120.00,  -6.00, 0, NOW()-INTERVAL '6 days',  NOW()-INTERVAL '2 days')
  ON CONFLICT (account_id, ticket) DO NOTHING;
END $$;
