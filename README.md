# Payment Transaction Validator

A high-performance command-line utility built in Haskell that validates and processes batch payment transactions against an account database. The application leverages pure functional programming patterns, algebraic data types (ADTs), and state transitions using folds to execute transaction validation and ledger updates without mutable state.

## Why This Was Built
This project serves as a practical demonstration of applying pure functional programming principles to the fintech domain. In financial systems, consistency, safety, and auditability are paramount. Haskell's strong static type system, pure computation, and explicit error handling via the `Either` monad make it an exceptional tool for writing bug-free, idempotent transaction ledger processors.

## Tech Stack
- **Language**: Haskell (GHC 9.14+)
- **Build Tool**: Cabal 3.16+
- **Standard Library Modules**: `containers` (for Map and Set structures), `base`, `Text.Printf`

## Assumptions Made
1. **Idempotency Lifespan**: Transaction IDs are tracked across the entire batch. Once a transaction ID is seen (whether it succeeds or is rejected), any subsequent transaction with the same ID in the batch is marked as `DuplicateTransaction` to prevent replay attacks or duplicate processing.
2. **Account Balances**: Account balances are modified in-place inside the pure ledger map. If an account is not found, the transaction fails with `InvalidAccount`.
3. **Transaction Currencies**: A transaction currency (USD, EUR, INR) must match the currencies of *both* the sender and receiver accounts. A currency mismatch triggers a `CurrencyMismatch` error.
4. **Order of Validations**: Idempotency is checked first, followed by account existence, currency matching, sender balance, and finally the configurable fraud threshold.

## Project Structure
- `src/Types.hs`: Core models (`Transaction`, `Account`, `Currency`, `TxError` ADTs).
- `src/Validation.hs`: Business validation checks (idempotency, account check, currency match, balance).
- `src/Fraud.hs`: Configurable currency-specific transaction limit safety check.
- `src/Ledger.hs`: Fold-based batch ledger updates and chronological state tracking.
- `src/Parser.hs`: Hand-crafted CSV parser avoiding external dependencies for speed and compiling reliability.
- `app/Main.hs`: Orchestrator driving file I/O, validations, and tabular console reports.

---

## Setup & Running Instructions

### Prerequisites
Make sure you have [GHCup](https://www.haskell.org/ghcup/) installed to manage Haskell tools.
Alternatively, on macOS with Homebrew, you can install the toolchain using:
```bash
brew install ghc cabal-install
```

### Build the Project
Initialize Cabal and compile:
```bash
cabal build
```

### Run the Application
Execute the compiled binary:
```bash
cabal run payment-transaction-validator
```

---

## Sample Data & Output

### Sample Input
The project includes realistic test data in the `data/` directory.

`data/accounts.csv`:
```csv
id,balance,currency
ACC001,25000.00,USD
ACC002,30000.00,EUR
ACC003,1500000.00,INR
ACC004,1500.00,USD
ACC005,0.00,EUR
ACC006,250000.00,INR
```

`data/transactions.csv`:
Contains 20 transactions representing valid transfers, duplicate attempts, insufficient balances, nonexistent accounts, currency mismatches, and fraud threshold violations.

### Console Report Output
When run, the application prints a structured, aligned terminal report:

```text
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
```

---

## Resume Bullet Point

- **Engineered an end-to-end payment transaction validator CLI in Haskell**, processing large mock CSV batches using purely functional state transitions (`foldl`) over account models; structured domain error states with Algebraic Data Types (ADTs) and leveraged the `Either` monad to enforce robust validation rules (balance checks, currency alignment, and currency-specific fraud limits) while ensuring idempotency with a custom transaction tracking system.
