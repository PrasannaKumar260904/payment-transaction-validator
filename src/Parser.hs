module Parser where

import Data.Char (isSpace, toLower)
import Data.List (isPrefixOf)
import Text.Read (readMaybe)
import Types

-- | Helper to convert a 'Maybe' to an 'Either'
maybeToEither :: e -> Maybe a -> Either e a
maybeToEither _ (Just x) = Right x
maybeToEither e Nothing  = Left e

-- | Trims leading and trailing whitespace from a 'String'
trim :: String -> String
trim = f . f
  where f = reverse . dropWhile isSpace

-- | Splits a string by a character delimiter, preserving empty fields
splitOn :: Char -> String -> [String]
splitOn _ "" = [""]
splitOn c s =
  let (before, after) = break (== c) s
  in before : case after of
                [] -> []
                (_:xs) -> splitOn c xs

-- | Parse a single CSV line into an 'Account'
parseAccountLine :: String -> Either String Account
parseAccountLine line =
  case map trim (splitOn ',' line) of
    [idStr, balanceStr, currStr] -> do
      balance <- maybeToEither ("Invalid balance: '" ++ balanceStr ++ "' in line: " ++ line) (readMaybe balanceStr)
      curr    <- maybeToEither ("Invalid currency: '" ++ currStr ++ "' in line: " ++ line) (readMaybe currStr)
      Right (Account idStr balance curr)
    _ -> Left ("Invalid account line format (expected id,balance,currency): " ++ line)

-- | Parse a single CSV line into a 'Transaction'
parseTransactionLine :: String -> Either String Transaction
parseTransactionLine line =
  case map trim (splitOn ',' line) of
    [idStr, senderStr, receiverStr, amountStr, currStr, timestampStr] -> do
      amount <- maybeToEither ("Invalid amount: '" ++ amountStr ++ "' in line: " ++ line) (readMaybe amountStr)
      curr    <- maybeToEither ("Invalid currency: '" ++ currStr ++ "' in line: " ++ line) (readMaybe currStr)
      Right (Transaction idStr senderStr receiverStr amount curr timestampStr)
    _ -> Left ("Invalid transaction line format (expected id,sender,receiver,amount,currency,timestamp): " ++ line)

-- | Parse the complete content of accounts.csv
parseAccounts :: String -> Either String [Account]
parseAccounts content =
  let dataLines = filter (not . null) $ map trim (lines content)
      nonHeaderLines = case dataLines of
        (h:xs) | "id" `isPrefixOf` map toLower h -> xs
        xs -> xs
  in mapM parseAccountLine nonHeaderLines

-- | Parse the complete content of transactions.csv
parseTransactions :: String -> Either String [Transaction]
parseTransactions content =
  let dataLines = filter (not . null) $ map trim (lines content)
      nonHeaderLines = case dataLines of
        (h:xs) | "id" `isPrefixOf` map toLower h -> xs
        xs -> xs
  in mapM parseTransactionLine nonHeaderLines
