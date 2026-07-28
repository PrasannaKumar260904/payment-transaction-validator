module Validation where

import qualified Data.Map as M
import qualified Data.Set as S
import Types
import Fraud (validateFraud)

-- | Validates a transaction against the current state of accounts and already processed transaction IDs.
-- Validations performed in order:
-- 1. Idempotency: Checks for duplicate transaction ID.
-- 2. Existence: Verifies that both sender and receiver accounts exist.
-- 3. Currency Alignment: Verifies transaction currency matches both sender and receiver account currencies.
-- 4. Balance: Verifies sender has sufficient funds.
-- 5. Fraud: Verifies transaction doesn't exceed the fraud threshold for its currency.
validateTransaction :: M.Map String Account -> S.Set String -> Transaction -> Either TxError Transaction
validateTransaction accounts processedIds tx = do
  -- 1. Check for duplicate transaction ID
  if S.member (txId tx) processedIds
    then Left DuplicateTransaction
    else Right ()

  -- 2. Retrieve sender and receiver accounts
  senderAcc <- case M.lookup (txSender tx) accounts of
    Nothing  -> Left InvalidAccount
    Just acc -> Right acc
  receiverAcc <- case M.lookup (txReceiver tx) accounts of
    Nothing  -> Left InvalidAccount
    Just acc -> Right acc

  -- 3. Check for currency mismatches
  if txCurrency tx /= accCurrency senderAcc || txCurrency tx /= accCurrency receiverAcc
    then Left CurrencyMismatch
    else Right ()

  -- 4. Check for sufficient balance
  if accBalance senderAcc < txAmount tx
    then Left InsufficientBalance
    else Right ()

  -- 5. Validate against fraud rules
  validateFraud tx
