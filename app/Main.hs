module Main where

import qualified Data.Map as M
import System.Exit (exitFailure)
import Text.Printf (printf)

import Types
import Ledger
import Parser

-- | Main entry point for the payment-transaction-validator CLI
main :: IO ()
main = do
  putStrLn "=================================================="
  putStrLn "        PAYMENT TRANSACTION VALIDATOR CLI         "
  putStrLn "=================================================="
  
  -- 1. Read and parse accounts data
  putStrLn "Loading accounts from 'data/accounts.csv'..."
  accountsContent <- readFile "data/accounts.csv"
  accounts <- case parseAccounts accountsContent of
    Left err -> do
      putStrLn $ "Error parsing accounts file: " ++ err
      exitFailure
    Right accs -> return accs
  printf "Loaded %d accounts successfully.\n" (length accounts)

  -- 2. Read and parse transactions data
  putStrLn "Loading transactions from 'data/transactions.csv'..."
  transactionsContent <- readFile "data/transactions.csv"
  transactions <- case parseTransactions transactionsContent of
    Left err -> do
      putStrLn $ "Error parsing transactions file: " ++ err
      exitFailure
    Right txs -> return txs
  printf "Loaded %d transactions to process.\n\n" (length transactions)

  -- 3. Initialize Ledger State and process batch via fold
  let initialState = initLedgerState accounts
      finalState = processTransactions initialState transactions

  -- 4. Print clean terminal reports
  
  putStrLn "=== SUCCESSFULLY PROCESSED TRANSACTIONS ==="
  printProcessed (ledgerProcessed finalState)
  putStrLn ""

  putStrLn "=== REJECTED TRANSACTIONS ==="
  printRejected (ledgerRejected finalState)
  putStrLn ""

  putStrLn "=== FINAL ACCOUNT BALANCES ==="
  printBalances (ledgerAccounts finalState)
  putStrLn "=================================================="

-- | Custom user-friendly error messages
errorReason :: TxError -> String
errorReason InsufficientBalance  = "Insufficient balance in sender account."
errorReason CurrencyMismatch     = "Currency mismatch with sender and/or receiver account currency."
errorReason DuplicateTransaction  = "Duplicate transaction ID (idempotency check failed)."
errorReason InvalidAccount       = "Sender or receiver account does not exist in ledger."
errorReason FraudFlagged         = "Transaction flags high-risk amount (configurable threshold exceeded)."

-- | Print successfully processed transactions table
printProcessed :: [Transaction] -> IO ()
printProcessed [] = putStrLn "No transactions were successfully processed."
printProcessed txs = do
  putStrLn $ printf "%-10s | %-12s | %-12s | %12s | %-8s | %s" 
                    "Tx ID" "Sender ID" "Receiver ID" "Amount" "Currency" "Timestamp"
  putStrLn $ replicate 78 '-'
  mapM_ (\tx -> putStrLn $ printf "%-10s | %-12s | %-12s | %12.2f | %-8s | %s"
                 (txId tx) (txSender tx) (txReceiver tx) (txAmount tx) (show (txCurrency tx)) (txTimestamp tx)) txs

-- | Print rejected transactions table grouped by error types with details
printRejected :: [(Transaction, TxError)] -> IO ()
printRejected [] = putStrLn "No transactions were rejected."
printRejected txs = do
  putStrLn $ printf "%-10s | %-12s | %-12s | %12s | %-8s | %-20s | %s"
                    "Tx ID" "Sender ID" "Receiver ID" "Amount" "Currency" "Error Type" "Reason"
  putStrLn $ replicate 110 '-'
  mapM_ (\(tx, err) -> putStrLn $ printf "%-10s | %-12s | %-12s | %12.2f | %-8s | %-20s | %s"
                 (txId tx) (txSender tx) (txReceiver tx) (txAmount tx) (show (txCurrency tx)) (show err) (errorReason err)) txs

-- | Print final account balances table
printBalances :: M.Map String Account -> IO ()
printBalances accs = do
  putStrLn $ printf "%-12s | %15s | %-8s" "Account ID" "Balance" "Currency"
  putStrLn $ replicate 43 '-'
  mapM_ (\acc -> putStrLn $ printf "%-12s | %15.2f | %-8s"
                 (accId acc) (accBalance acc) (show (accCurrency acc))) (M.elems accs)
