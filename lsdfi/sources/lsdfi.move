module wisp_lsdfi::lsdfi {
    use sui::coin::{Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::Clock;
    use sui::sui::SUI;

    use wisp_lsdfi::pool::{Self, LSDFIPoolRegistry, WithdrawReceipt};
    use wisp_lsdfi::utils;
    use wisp_lsdfi::wispSUI::{WISPSUI};
    
    use wisp_lsdfi_aggregator::aggregator::{Aggregator};

    use wisp::pool::{PoolRegistry};

    public entry fun deposit<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        lst: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let wispSUI = pool::deposit(pool_registry, aggregator, lst, clock, ctx);
        transfer::public_transfer(wispSUI, tx_context::sender(ctx));
    }

    public fun deposit_non_entry<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        lst: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<WISPSUI> {
        pool::deposit(pool_registry, aggregator, lst, clock, ctx)
    }

    public entry fun deposit_mul_coin<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        lsts: vector<Coin<T>>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let lst = utils::extract_coin(lsts, amount, ctx);
        deposit<T>(pool_registry, aggregator, lst, clock, ctx);
    }

    public entry fun deposit_SUI(
        pool_registry: &mut LSDFIPoolRegistry,
        exchange_pool_registry: &mut PoolRegistry,
        aggregator: &Aggregator,
        sui: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let wispSUI = pool::deposit_SUI(pool_registry, exchange_pool_registry, aggregator, sui, clock, ctx);
        transfer::public_transfer(wispSUI, tx_context::sender(ctx));
    }

    public fun deposit_SUI_non_entry(
        pool_registry: &mut LSDFIPoolRegistry,
        exchange_pool_registry: &mut PoolRegistry,
        aggregator: &Aggregator,
        sui: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<WISPSUI> {
        pool::deposit_SUI(pool_registry, exchange_pool_registry, aggregator, sui, clock, ctx)
    }

    public entry fun deposit_SUI_mul_coin(
        pool_registry: &mut LSDFIPoolRegistry,
        exchange_pool_registry: &mut PoolRegistry,
        aggregator: &Aggregator,
        suis: vector<Coin<SUI>>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sui = utils::extract_coin(suis, amount, ctx);
        deposit_SUI(pool_registry, exchange_pool_registry, aggregator, sui, clock, ctx);
    }

    public fun withdraw(
        pool_registry: &mut LSDFIPoolRegistry,
        wispSUI: Coin<WISPSUI>,
        ctx: &mut TxContext
    ): WithdrawReceipt {
        pool::withdraw(pool_registry, wispSUI, ctx)
    }

    public fun withdraw_mul_coin(
        pool_registry: &mut LSDFIPoolRegistry,
        wispSUIs: vector<Coin<WISPSUI>>,
        amount: u64,
        ctx: &mut TxContext
    ): WithdrawReceipt {
        let wispSUI = utils::extract_coin(wispSUIs, amount, ctx);
        withdraw(pool_registry, wispSUI, ctx)
    }

    public fun consume_withdraw_receipt<T>(
        pool_registry: &mut LSDFIPoolRegistry,
        receipt: &mut WithdrawReceipt,
        ctx: &mut TxContext
    ) {
        let lst = pool::consume_withdraw_receipt<T>(pool_registry, receipt, ctx);
        utils::transfer_coin<T>(lst, tx_context::sender(ctx));
    }

    public fun drop_withdraw_receipt(
        receipt: WithdrawReceipt
    ) {
        pool::drop_withdraw_receipt(receipt);
    }

    public entry fun swap<I, O>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_coin: Coin<I>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let out_coin = pool::swap<I, O>(pool_registry, aggregator, in_coin, clock, ctx);
        transfer::public_transfer(out_coin, tx_context::sender(ctx));
    }

    public fun swap_non_entry<I, O>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_coin: Coin<I>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<O> {
        pool::swap<I, O>(pool_registry, aggregator, in_coin, clock, ctx)
    }

    public entry fun swap_mul_coin<I, O>(
        pool_registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_coins: vector<Coin<I>>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let in_coin = utils::extract_coin(in_coins, amount, ctx);
        swap<I, O>(pool_registry, aggregator, in_coin, clock, ctx);
    }
}