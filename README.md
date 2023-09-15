# WispLSDFI

## Contract

Current deployed package/objects:

### Mainnet

// TO BE UPDATED

### Testnet

#### LSDFi

-   Package address: 0x3c57f671f3d4cbdae9ca433636a6b24628469322b931f7c89fc03c1f4984e64b
-   AdminCap object: 0x3000f0b0d393825e2398ca9208e3988ce764c5a0082d51047ce4eecdcf376ad0
-   LSDFiPoolRegistry object: 0x8b0ebf9e5fab704e5829cb83dfa584542135d98f920560d4a0d7ad30d2f5ed4a

#### Aggregator

-   Package address: 0xcbb27865df487acdffb16f770409aa83d97e8189f5855e29247cc4d574a201e6
-   Aggregator: 0x38367d79002f528fea9d79e5978621328bd7b04df2c2a9f86a2b9d15495ccc8b

## Structure

Wisp LSDFi Smart Contracts consists of 6 sub-module

-   `pool`: implementation of core logic for Staking Liquidity Token pool and vdAMM
-   `wispSUI`: wispSUI token represent share of Staking Liquidity Token pool
-   `lsdfi`: wrapper module for pool's functions
-   `errors`: errors code
-   `utils`: utility functions and consts
-   `math`: function for calculating

## Object

### AdminCap

Object represent ownership of this package. Required to perform some permissioned actions.

### PoolRegistry

Main storage object for storing coins in pool and also other config parameters. Fields:

-   `balances`: store all coins' balances in pool
-   `supported_lsts`: list of supported liquidity token in protocol
-   `available_balances`: mapping from TypeName to available balances of coins in pool. Use to query balances without a type argument
-   `max_diff_weights`: maximum weight differrent for each lst for every action can not make weights fluctuate over this rate
-   `risk_coefficients`: risk parameters for each lst, use to calculate weight of lst in the pool
-   `wispSUI_treasury`: treasury object of wispSUI, use to mint/burn wispSUI for lst provider
-   `acceptable_result_time`: maximum time for a result in aggregator be valid. if aggregator's result is too old (greater than this value since last time updated until now), action won't be execute
-   `slope`: dynamic fee calculate factor
-   `base_fee`: base fee for swapping lst in pool
-   `redemption_fee`: fix fee for withdraw lst
-   `sui_split_bps`: percent of sui to split and add to wispSUI/SUI AMM pool in basis points
-   `fee_to`: protocol fee receiver address
-   `is_sui_smaller_than_wispSUI`: pre-calculate value for adding SUI into pool, to reduce gas fee

### WithdrawReceipt

"Hot potato" object represent of withdraw output, it has no traits so can not be transfer or store somewhere. Since withdraw action return coin in all type of supported lsts, we use it as a way to withdraw multiple type of coins dynamically.\
We take advantage of Programmable Transaction to consume this WithdrawReceipt object to get out coins after receiving it and drop it when all coins are withdrawn. Field:

-   `withdraw_amounts`: Mapping of coins' typenames to amount to withdraw

## Public Interface

### Deposit

**Module: `lsdfi`**

```rust
    public entry fun deposit<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        lst: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    )
```

Type parameters:

-   `T`: LST to deposit into pool

Parameters:

-   `pool_registry`: mutable reference of LSDFIPoolRegistry object
-   `aggregator`: reference of Aggregator object in WispLSDFIAggregator package
-   `lst`: LST coin of type T
-   `clock`: reference of Clock object (address: `0x6`)

Use: Put `lst` into pool and transfer back to sender corresponding amount of wispSUI

```rust
    public fun deposit_non_entry<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        lst: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<WISPSUI>
```

Same as `deposit` but return Coin of wispSUI type for further action instead of transfer to sender

```rust
    public entry fun deposit_mul_coin<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        lsts: vector<Coin<T>>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    )
```

Same as `deposit` but use multiple Coin, leftovers will be transfer back to sender

-   `lsts`: vector of coins of type T
-   `amount`: amount to add into pool

### Deposit SUI

**Module: `lsdfi`**

```rust
    public entry fun deposit_SUI(
        pool_registry: &mut LSDFIPoolRegistry,
        exchange_pool_registry: &mut PoolRegistry,
        aggregator: &Aggregator,
        sui: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    )
```

Type parameters:

-   `T`: LST to deposit into pool

Parameters:

-   `pool_registry`: mutable reference of LSDFIPoolRegistry object
-   `exchange_pool_registry`: mutable reference of PoolRegistry object of WispSwap AMM contract
-   `aggregator`: reference of Aggregator object in WispLSDFIAggregator package
-   `lst`: LST coin of type T
-   `clock`: reference of Clock object (address: `0x6`)

Use: Put `sui` into pool and transfer back to sender corresponding amount of wispSUI

```rust
    public fun deposit_SUI_non_entry(
        pool_registry: &mut LSDFIPoolRegistry,
        exchange_pool_registry: &mut PoolRegistry,
        aggregator: &Aggregator,
        sui: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<WISPSUI>
```

Same as `deposit_SUI` but return Coin of wispSUI type for further action instead of transfer to sender

```rust
    public entry fun deposit_SUI_mul_coin(
        pool_registry: &mut LSDFIPoolRegistry,
        exchange_pool_registry: &mut PoolRegistry,
        aggregator: &Aggregator,
        suis: vector<Coin<SUI>>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    )
```

Same as `deposit_SUI_mul_coin` but use multiple Coin, leftovers will be transfer back to sender

-   `suis`: vector of SUI coins
-   `amount`: amount to add into pool

### Withdraw

**Module: `lsdfi`**

```rust
    public fun withdraw(
        pool_registry: &mut LSDFIPoolRegistry,
        wispSUI: Coin<WISPSUI>,
        ctx: &mut TxContext
    ): WithdrawReceipt
```

Parameters:

-   `pool_registry`: mutable reference of LSDFIPoolRegistry object
-   `wispSUI`: wispSUI coin to burn to withdraw LSTs
-   `ctx`: mutable reference of TxContext

Use: Burn `wispSUI` to get WithdrawReceipt object

```rust
    public fun withdraw_mul_coin(
        pool_registry: &mut LSDFIPoolRegistry,
        wispSUIs: vector<Coin<WISPSUI>>,
        amount: u64,
        ctx: &mut TxContext
    ): WithdrawReceipt {
        let wispSUI = utils::extract_coin(wispSUIs, amount, ctx);
        withdraw(pool_registry, wispSUI, ctx)
    }
```

Same as `withdraw` but use multiple Coin, leftovers will be transfer back to sender

```rust
    public fun consume_withdraw_receipt<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        receipt: &mut WithdrawReceipt,
        ctx: &mut TxContext
    )
```

Type parameters:

-   `T`: LST to withdraw from pool

Parameters:

-   `pool_registry`: mutable reference of LSDFIPoolRegistry object
-   `receipt`:mutable reference of WithdrawReceipt object returned by withdraw function
-   `ctx`: mutable reference of TxContext

Use: Take out LST coin from the pool and mark this type in `receipt` as withdrawn

```rust
    public fun drop_withdraw_receipt(
        receipt: WithdrawReceipt
    )
```

Parameters:

-   `receipt`: WithdrawReceipt object

Use: Drop WithdrawReceipt object after withdraw all returned coins

### Swap

**Module: `lsdfi`**

```rust
    public entry fun swap<I, O>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_coin: Coin<I>,
        clock: &Clock,
        ctx: &mut TxContext,
    )
```

Type parameters:

-   `I`: LST to put into pool
-   `O`: LST to to get back

Parameters:

-   `pool_registry`: mutable reference of LSDFIPoolRegistry object
-   `aggregator`: reference of Aggregator object in WispLSDFIAggregator package
-   `in_coin`: LST coin of type I
-   `clock`: reference of Clock object (address: `0x6`)
-   `ctx`: mutable reference of TxContext

Use: Swap `in_coin` to desire lst coin type. Returned coin will be transfered to sender

```rust
    public fun swap_non_entry<I, O>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_coin: Coin<I>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<O>
```

Same as `swap` but return Coin of O type for further action instead of transfer to sender

```rust
    public entry fun swap_mul_coin<I, O>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_coins: vector<Coin<I>>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    )
```

Same as `swap` but use multiple Coin, leftovers will be transfer back to sender

### View functions

```rust
public fun supported_lsts(registry: &LSDFIPoolRegistry): &VecSet<TypeName>
```

```rust
public fun available_balances(registry: &LSDFIPoolRegistry): &Table<TypeName, u64>
```

```rust
public fun max_diff_weights(registry: &LSDFIPoolRegistry): &Table<TypeName, u64>
```

```rust
public fun risk_coefficients(registry: &LSDFIPoolRegistry): &Table<TypeName, u64>
```

```rust
public fun wispSUI_treasury(registry: &LSDFIPoolRegistry): &Option<TreasuryCap<WISPSUI>>
```

```rust
public fun acceptable_result_time(registry: &LSDFIPoolRegistry): u64
```

```rust
public fun slope(registry: &LSDFIPoolRegistry): u64
```

```rust
public fun base_fee(registry: &LSDFIPoolRegistry): u64
```

```rust
public fun redemption_fee(registry: &LSDFIPoolRegistry): u64
```

```rust
public fun sui_split_bps(registry: &LSDFIPoolRegistry): u64
```
