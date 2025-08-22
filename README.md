# Subscription Pass Smart Contract

A Clarity smart contract for managing subscription-based access control on the Stacks blockchain.

## Overview

This smart contract implements a configurable subscription system where users can pay STX tokens to gain time-limited access. The contract supports automatic subscription extensions, owner configuration, and fund management.

## Features

- **Pay-to-Subscribe**: Users pay in micro-STX to activate their subscription
- **Configurable Parameters**: 
  - Subscription price (in micro-STX)
  - Duration (in blocks)
- **Automatic Extension**: Renewal extends from the maximum of current block or previous expiry
- **Owner Controls**:
  - Configure price and duration
  - Withdraw collected funds
- **Public Functions**:
  - Check subscription status
  - View configuration and statistics
  - Cancel subscription

## Functions

### Owner Functions

```clarity
(set-config (new-price uint) (new-duration uint))
(withdraw (amount uint))
```

### User Functions

```clarity
(subscribe)
(cancel)
```

### Read-Only Functions

```clarity
(is-active (who principal))
(get-expiry (who principal))
(get-config)
(get-stats)
```

## Error Codes

- `ERR-NOT-OWNER (u100)`: Caller is not the contract owner
- `ERR-ALREADY_ACTIVE (u101)`: Subscription already active
- `ERR-NOT_ACTIVE (u102)`: No active subscription
- `ERR-INSUFFICIENT (u103)`: Insufficient STX sent
- `ERR-NO-FUNDS (u104)`: Not enough funds to withdraw

