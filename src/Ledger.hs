module Ledger where

import qualified Data.Map as M
import qualified Data.Set as S
import Types
import Validation (validateTransaction)

-- | State of the ledger during batch transaction processing
data LedgerState = LedgerState
  { ledgerAccounts  :: M.Map String Account        -- ^ Account balances indexed by Account ID
  , ledgerProcessed :: [Transaction]               -- ^ List of successfully processed transactions (chronological order)
  , ledgerRejected  :: [(Transaction, TxError)]    -- ^ List of rejected transactions and their errors (chronological order)
  , ledgerTxIds     :: S.Set String                -- ^ Set of all seen transaction IDs (idempotency key registry)
  } deriving (Show, Eq)

-- | Create an initial ledger state from a list of accounts
initLedgerState :: [Account] -> LedgerState
initLedgerState accounts = LedgerState
  { ledgerAccounts  = M.fromList [ (accId acc, acc) | acc <- accounts ]
  , ledgerProcessed = []
  , ledgerRejected  = []
  , ledgerTxIds     = S.empty
  }

-- | Processes a single transaction, returning the updated 'LedgerState'.
-- The function runs validations first.
-- - On success: Updates the sender's and receiver's account balances, adds the transaction to
--   the processed list, and registers the transaction ID.
-- - On failure: Adds the transaction and the validation error to the rejected list,
--   and registers the transaction ID to ensure idempotency.
processTransaction :: LedgerState -> Transaction -> LedgerState
processTransaction state tx =
  case validateTransaction (ledgerAccounts state) (ledgerTxIds state) tx of
    Left err -> state
      { ledgerRejected = (tx, err) : ledgerRejected state
      , ledgerTxIds    = S.insert (txId tx) (ledgerTxIds state)
      }
    Right validTx ->
      let accounts = ledgerAccounts state
          senderId = txSender validTx
          receiverId = txReceiver validTx
          amount = txAmount validTx
          
          -- Deduct from sender and credit receiver (adjust only performs update if key exists)
          deducted = M.adjust (\acc -> acc { accBalance = accBalance acc - amount }) senderId accounts
          updatedAccounts = M.adjust (\acc -> acc { accBalance = accBalance acc + amount }) receiverId deducted
      in state
        { ledgerAccounts  = updatedAccounts
        , ledgerProcessed = validTx : ledgerProcessed state
        , ledgerTxIds     = S.insert (txId validTx) (ledgerTxIds state)
        }

-- | Process a list of transactions sequentially using a pure fold.
-- The lists of processed and rejected transactions are reversed at the end to restore
-- original chronological order efficiently.
processTransactions :: LedgerState -> [Transaction] -> LedgerState
processTransactions initialState txs =
  let finalState = foldl processTransaction initialState txs
  in finalState
    { ledgerProcessed = reverse (ledgerProcessed finalState)
    , ledgerRejected  = reverse (ledgerRejected finalState)
    }
