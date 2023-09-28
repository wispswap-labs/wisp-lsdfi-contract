# WispLSDFI

## Development progress

### vdAMM

| vdAMM features                                                   | To Do | In Progress | Done |
| ---------------------------------------------------------------- | :---: | :---------: | :--: |
| Multi-asset token pools                                          |       |             |  ✅  |
| Swap between LSTs                                                |       |             |  ✅  |
| Swap between SUI and LST                                         |  📝   |             |      |
| Swap between wispSUI and LST                                     |       |     🚧      |      |
| Mint wispSUI from SUI                                            |       |             |  ✅  |
| Mint wispSUI from LST                                            |       |             |  ✅  |
| Basket Withdrawal                                                |       |             |  ✅  |
| Basket target weight calculation                                 |       |             |  ✅  |
| Max cap set for LSTs                                             |       |             |  ✅  |
| Dynamic Fee Implementation                                       |       |             |  ✅  |
| Fee distribution implementation                                  |       |     🚧      |      |
| Liquidity Providing to wispSUI-SUI <br> pool when depositing SUI |       |             |  ✅  |
| Yield claiming from LST protocols                                |       |     🚧      |      |
| Unstake from LST protocols                                       |       |     🚧      |      |
| Integration with Lending/Borrowing protocol |       |      🚧       |    |
| On-chain Casino games |       |     🚧      |      |
| On-chain Crash game                                       |       |     🚧      |      |

### LST protocols integration

| LST protocols integration      | To Do | In Progress | Done |
| ------------------------------ | :---: | :---------: | :--: |
| [Haedel (haSUI)][haedal]       |       |             |  ✅  |
| [Volo (voloSUI)][volo]         |       |             |  ✅  |
| [Aftermath (afSUI)][aftermath] |       |             |  ✅  |
| [DegenHive (deSUI)][degenhive] |  📝   |             |      |

### veWISP governance token

| veWISP governance token features                                                          | To Do | In Progress | Done |
| ----------------------------------------------------------------------------------------- | :---: | :---------: | :--: |
| DAO voting for LSTs basket composition <br> (Risk Coefficients and Fee curve paramenters) |       |     🚧      |      |
| Stake veWISP to earn protocol's earnings                                                  |  📝   |             |      |

### wispSUI utilities

| wispSUI utilities                  | To Do | In Progress | Done |
| ---------------------------------- | :---: | :---------: | :--: |
| Stake wispSUI to earn WISP         |       |             |  ✅  |
| Yield Boosting using veWisp        |       |             |  ✅  |
| Lock mechanism                     |       |             |  ✅  |
| Block-by-block yield emissions     |       |             |  ✅  |
| Using wispSUI on Wisp-prediction   |       |             |  ✅  |
| wispSUI, SUI prediction aggregator |  📝   |             |      |

## Contract

Current deployed packages/objects:

### Mainnet

// TO BE UPDATED

### Testnet

#### LSDFi

-   Package address: 0x92cfde55a8021634e8377b07831d18b624f819f6a88d26dbe16a4a0979aaa1a7
-   AdminCap object: 0xbed7d5435e15fd48be835c00b0dc4eb559fb2284502454c2f3a82f7f890af9f0
-   LSDFiPoolRegistry object: 0x6c56f66099b83416ac77e0f79f9cb66e5c1bb9a9be8a239cdd8786eefd67d8eb

#### Aggregator

-   Package address: 0x7acce221f903b5498e4a82ef5c974058a2998e5939a55265302f4729aea2d6bf
-   Aggregator: 0xb1ab5d3bf2a5152fdee275fd6ac4d8734ba06b1301d7075f0ab542c1b6a96b89

#### Adapters

Aftermath:

-   Package address: 0x4aeb6357f338dbc4da1bc34ac06c5b09438fbe9d11e8f0666f0bd983e5c0bab8
-   Adapter: 0x2ba221c741f952572537137ab850f5f40f95ab88a7f5c78bef9d6a648ac89483

Haedal:

-   Package address: 0x80d5fd2f567fdc45f88139f11563aea980486466ec33c5719a70ce27435710ab
-   Adapter: 0x566c0784096fc0698babe787b261d594dde9e4da02de539fb4be2739e334488b

Volo:

-   Package address: 0xf449105218d90e68ca5cd530a375e40f392b249facc3374c85678afc18b3adf6
-   Adapter: 0x53ce50cf2f80e9891d3a8a06c2c953722b48d347bc26cebe1b30f28432b88eb5

## Structure

Wisp LSDFi Smart Contracts consists of 6 sub-modules

-   `pool`: implementation of core logic for Staking Liquidity Token pool and vdAMM
-   `wispSUI`: wispSUI token represent share of Staking Liquidity Token pool
-   `lsdfi`: wrapper module for pool's functions
-   `errors`: errors code
-   `utils`: utility functions and consts
-   `math`: functions for calculation

## Objects/Structs

### veWISP

Witness for veWISP coins - WispLSDFi governance coin represents share in the LSTs pool.

### AdminCap

This object represents ownership of this package. The object is required to perform certain permission assignments.

### PoolRegistry

This is the main storage object to store coins in pool and configure parameters. Fields:

-   `balances`: store all coins' balances in pool
-   `supported_lsts`: list of supported Liquid Staking Tokens in wispSUI protocol
-   `available_balances`: mapping from TypeName to available balances of coins in pool, used to query balances without a type argument
-   `max_diff_weights`: maximum weight differrence for each LST for every action. Each action can not move basket weights over these values.
-   `risk_coefficients`: risk parameters for each LST, used to calculate weight of LST in the pool
-   `wispSUI_treasury`: treasury object for wispSUI, use to store circulating wispSUI.
-   `acceptable_result_time`: max threshold time for updated time of aggregator data. If aggregator's updated time is greater than this value, the actions won't be able to be executed
-   `slope`: dynamic fee curve parameter
-   `base_fee`: base fee for LSTs swapping
-   `redemption_fee`: fixed fee for LSTs redemption
-   `sui_split_bps`: percentage of Sui to split and add to wispSUI/SUI AMM pool in basis points
-   `fee_to`: protocol fee receiver address
-   `is_sui_smaller_than_wispSUI`: pre-calculated value for adding SUI into pool, to reduce gas fee

### WithdrawReceipt

The "Hot potato" object represents the withdrawal output; it has no traits, so it cannot be transferred or stored elsewhere. Since withdrawal actions return coins in all types of supported LSTs, the WispSwap team uses this object type as a way to handle the withdrawals of multiple types of coins dynamically.
We take advantage of Programmable Transactions to consume this WithdrawReceipt object to retrieve coins after receiving them and drop it when all coins have been withdrawn.
Field:

-   `withdraw_amounts`: Mapping of coins' typenames to the amount to withdraw

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

-   `T`: LST to deposit into the pool

Parameters:

-   `pool_registry`: mutable reference to the LSDFIPoolRegistry object
-   `aggregator`: reference to the Aggregator object in the WispLSDFIAggregator package
-   `lst`: LST coin of type T
-   `clock`: reference to the Clock object (address: `0x6``)

Use: Put `lst` into the pool and transfer back to the sender corresponding amount of wispSUI

```rust
    public fun deposit_non_entry<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        lst: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<WISPSUI>
```

Same as `deposit` but returns a Coin of wispSUI type for further actions instead of transferring it to the sender.

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

Same as `deposit` but uses multiple Coins; leftovers will be transferred back to the sender.

-   `lsts`: a vector of coins of type T
-   `amount`: the amount to add to the pool

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

-   `pool_registry`: mutable reference to the LSDFIPoolRegistry object
-   `exchange_pool_registry`: mutable reference to the PoolRegistry object of WispSwap AMM contract
-   `aggregator`: reference to the Aggregator object in the WispLSDFIAggregator package
-   `lst`: LST coin of type T
-   `clock`: reference to Clock object (address: `0x6`)

Use: Put `sui` into pool and transfer back to the sender the corresponding amount of wispSUI

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

Same as `deposit_SUI` but return a Coin of wispSUI type for further actions instead of transferring it back to sender

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

Same as `deposit_SUI_mul_coin` but use multiple Coin objects, leftovers will be transferred back to sender

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

-   `pool_registry`: mutable reference to the LSDFIPoolRegistry object
-   `wispSUI`: wispSUI coin which will be burnt to withdraw LSTs
-   `ctx`: mutable reference to the TxContext

Use: Burn `wispSUI` to obtain WithdrawReceipt objects

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

Same as `withdraw` but use multiple Coins, leftovers will be transferred back to sender

```rust
    public fun consume_withdraw_receipt<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        receipt: &mut WithdrawReceipt,
        ctx: &mut TxContext
    )
```

Type parameters:

-   `T`: LST to withdraw from the pool

Parameters:

-   `pool_registry`: mutable reference to LSDFIPoolRegistry object
-   `receipt`:mutable reference to WithdrawReceipt object returned by withdraw function
-   `ctx`: mutable reference to TxContext

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
-   `O`: LST to get back

Parameters:

-   `pool_registry`: mutable reference to LSDFIPoolRegistry object
-   `aggregator`: reference to Aggregator object in WispLSDFIAggregator package
-   `in_coin`: LST coin of type I
-   `clock`: reference to Clock object (address: `0x6`)
-   `ctx`: mutable reference to TxContext

Use: Swap `in_coin` to the desired LST coin type. Returned coin will be transfered to sender

```rust
    public fun swap_non_entry<I, O>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_coin: Coin<I>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<O>
```

Same as `swap` but return a Coin of O type for further action instead of transferring to sender

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

Same as `swap` but use multiple Coins, leftovers will be transferred back to sender

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

[haedal]: https://haedal.xyz/
[volo]: https://www.volo.fi/
[aftermath]: https://aftermath.finance/
[degenhive]: https://www.degenhive.ai/
