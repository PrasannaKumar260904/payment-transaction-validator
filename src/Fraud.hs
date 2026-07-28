module Fraud where

import Types

-- | Configuration mapping each Currency to its maximum allowed single transaction amount.
-- Transactions exceeding this limit will be flagged as potential fraud.
currencyThresholds :: Currency -> Double
currencyThresholds USD = 10000.0
currencyThresholds EUR = 9000.0
currencyThresholds INR = 800000.0

-- | Checks if a transaction exceeds the configurable fraud threshold.
-- Returns 'Left FraudFlagged' if it exceeds the limit, otherwise 'Right Transaction'.
validateFraud :: Transaction -> Either TxError Transaction
validateFraud tx =
  let limit = currencyThresholds (txCurrency tx)
  in if txAmount tx > limit
     then Left FraudFlagged
     else Right tx
