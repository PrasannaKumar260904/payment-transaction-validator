Payment Transaction Validator

A command-line utility built in Haskell that validates and processes batch payment transactions against an account ledger. The application applies pure functional programming patterns — algebraic data types (ADTs), monadic error handling, and fold-based state transitions — to process transactions without any mutable state.

Why This Was Built

This project is a practical exploration of applying pure functional programming to the fintech domain. In financial systems, correctness, auditability, and predictable failure handling are non-negotiable. Haskell's strong static type system, pure computation model, and explicit error handling via the Either monad make it a natural fit for writing transaction processing logic where invalid states should be unrepresentable rather than merely avoided.

Key Design Decisions
Illegal states are unrepresentable — every failure mode (InsufficientBalance, CurrencyMismatch, DuplicateTransaction, InvalidAccount, FraudFlagged) is enumerated as a constructor in the TxError ADT. The compiler forces every case to be handled; there's no way to "forget" an error type.
No exceptions — all validation failures flow through Either TxError Transaction, so every function's signature honestly describes whether it can fail, and every caller must explicitly handle both outcomes.
No mutable state — the entire ledger is rebuilt on each run via a pure foldl over the transaction list. This makes the system trivially testable: given the same accounts and transactions, the output is always identical.
Idempotency by construction — transaction IDs are tracked in a Set across the batch. A duplicate ID is rejected deterministically, regardless of whether the original transaction succeeded or failed.
Tech Stack
Language: Haskell (GHC 9.14+)
Build Tool: Cabal 3.16+
Libraries: base, containers (Map/Set), Text.Printf
No external CSV library — parsing is hand-written to keep the build fast and dependency-free.
Project Structure
payment-transaction-validator/
├── payment-transaction-validator.cabal
├── cabal.project
├── data/
│   ├── accounts.csv
│   └── transactions.csv
├── src/
│   ├── Types.hs        -- Core domain models: Transaction, Account, Currency, TxError
│   ├── Validation.hs   -- Business rule checks (idempotency, account existence, currency, balance)
│   ├── Fraud.hs        -- Configurable currency-specific fraud thresholds
│   ├── Ledger.hs       -- Fold-based batch ledger state transitions
│   └── Parser.hs       -- Hand-written, dependency-free CSV parser
└── app/
    └── Main.hs          -- CLI entry point: orchestrates I/O, validation, and report output
Assumptions Made
Idempotency scope: transaction IDs are tracked across the entire batch. Once an ID has been seen — whether the transaction succeeded or was rejected — any later transaction with the same ID is flagged as DuplicateTransaction.
Account resolution: if either the sender or receiver account is missing from the ledger, the transaction fails with InvalidAccount.
Currency matching: a transaction's currency must match both the sender's and receiver's account currency; otherwise it fails with CurrencyMismatch.
Validation order: idempotency → account existence → currency match → sender balance → fraud threshold. Validation short-circuits on the first failure.
Fraud thresholds are currency-specific: USD $10,000 · EUR €9,000 · INR ₹800,000.
Setup & Running
Prerequisites

Install the Haskell toolchain via GHCup, or on macOS with Homebrew:

bash
brew install ghc cabal-install
Build
bash
cabal build
Run
bash
cabal run payment-transaction-validator
Sample Data

data/accounts.csv:

id,balance,currency
ACC001,25000.00,USD
ACC002,30000.00,EUR
ACC003,1500000.00,INR
ACC004,1500.00,USD
ACC005,0.00,EUR
ACC006,250000.00,INR

data/transactions.csv contains 20 transactions covering: valid transfers, insufficient balance, currency mismatch, duplicate transaction IDs, non-existent accounts, and fraud threshold violations — including one transaction ID (TX018) that appears twice, deliberately, to demonstrate idempotency: the first instance is processed successfully, and the second is rejected as a duplicate.

Sample Output
==================================================
        PAYMENT TRANSACTION VALIDATOR CLI         
==================================================
Loading accounts from 'data/accounts.csv'...
Loaded 6 accounts successfully.
Loading transactions from 'data/transactions.csv'...
Loaded 20 transactions to process.

=== SUCCESSFULLY PROCESSED TRANSACTIONS ===
Tx ID      | Sender ID    | Receiver ID  |       Amount | Currency | Timestamp
------------------------------------------------------------------------------
TX001      | ACC001       | ACC004       |       500.00 | USD      | 2026-07-28T08:00:00Z
TX002      | ACC003       | ACC006       |     10000.00 | INR      | 2026-07-28T08:01:00Z
TX003      | ACC002       | ACC005       |      1000.00 | EUR      | 2026-07-28T08:02:00Z
TX006      | ACC001       | ACC004       |       100.00 | USD      | 2026-07-28T08:05:00Z
TX011      | ACC003       | ACC006       |      5000.00 | INR      | 2026-07-28T08:10:00Z
TX012      | ACC005       | ACC002       |       500.00 | EUR      | 2026-07-28T08:11:00Z
TX013      | ACC004       | ACC001       |       150.00 | USD      | 2026-07-28T08:12:00Z
TX016      | ACC003       | ACC006       |     40000.00 | INR      | 2026-07-28T08:15:00Z
TX017      | ACC006       | ACC003       |     15000.00 | INR      | 2026-07-28T08:16:00Z
TX018      | ACC002       | ACC005       |       200.00 | EUR      | 2026-07-28T08:17:00Z

=== REJECTED TRANSACTIONS ===
Tx ID      | Sender ID    | Receiver ID  |       Amount | Currency | Error Type           | Reason
--------------------------------------------------------------------------------------------------------------
TX004      | ACC001       | ACC002       |       200.00 | USD      | CurrencyMismatch     | Currency mismatch with sender and/or receiver account currency.
TX005      | ACC004       | ACC001       |      2500.00 | USD      | InsufficientBalance  | Insufficient balance in sender account.
TX006      | ACC001       | ACC004       |       100.00 | USD      | DuplicateTransaction | Duplicate transaction ID (idempotency check failed).
TX007      | ACC001       | ACC999       |       100.00 | USD      | InvalidAccount       | Sender or receiver account does not exist in ledger.
TX008      | ACC001       | ACC004       |     12000.00 | USD      | FraudFlagged         | Transaction flags high-risk amount (configurable threshold exceeded).
TX009      | ACC002       | ACC005       |      9500.00 | EUR      | FraudFlagged         | Transaction flags high-risk amount (configurable threshold exceeded).
TX010      | ACC003       | ACC006       |    900000.00 | INR      | FraudFlagged         | Transaction flags high-risk amount (configurable threshold exceeded).
TX014      | ACC999       | ACC001       |       100.00 | USD      | InvalidAccount       | Sender or receiver account does not exist in ledger.
TX015      | ACC001       | ACC004       |        10.00 | EUR      | CurrencyMismatch     | Currency mismatch with sender and/or receiver account currency.
TX018      | ACC002       | ACC005       |       200.00 | EUR      | DuplicateTransaction | Duplicate transaction ID (idempotency check failed).

=== FINAL ACCOUNT BALANCES ===
Account ID   |         Balance | Currency
-------------------------------------------
ACC001       |        24550.00 | USD     
ACC002       |        29300.00 | EUR     
ACC003       |      1460000.00 | INR     
ACC004       |         1950.00 | USD     
ACC005       |          700.00 | EUR     
ACC006       |       290000.00 | INR     
==================================================
Possible Extensions
Property-based testing with QuickCheck (e.g., verifying total ledger balance is conserved across all processed transactions)
Wrapping the core logic in a lightweight HTTP API (e.g., with Scotty)
Persisting the idempotency set across runs instead of scoping it to a single batch
