module Types where

-- | Currency supported by the transaction validator
data Currency = INR | USD | EUR
  deriving (Show, Eq, Read, Ord)

-- | Transaction error categories for validation failure reporting
data TxError
  = InsufficientBalance
  | CurrencyMismatch
  | DuplicateTransaction
  | InvalidAccount
  | FraudFlagged
  deriving (Show, Eq)

-- | Customer account model
data Account = Account
  { accId       :: String
  , accBalance  :: Double
  , accCurrency :: Currency
  } deriving (Show, Eq)

-- | Payment transaction model
data Transaction = Transaction
  { txId        :: String
  , txSender    :: String
  , txReceiver  :: String
  , txAmount    :: Double
  , txCurrency  :: Currency
  , txTimestamp :: String
  } deriving (Show, Eq)
