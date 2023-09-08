module wisp_lsdfi::lsdfi {
    use sui::coin::{Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    use wisp_lsdfi::pool::{Self, PoolRegistry};
    use wisp_lsdfi::utils;
    use wisp_lsdfi::wispSUI::{WISPSUI};
    
    use aggregator::aggregator::{AggregatorRegistry};

    public entry fun mint_wispSUI<T>(
        pool_registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        lst: Coin<T>,
        ctx: &mut TxContext
    ) {
        let wispSUI = pool::mint_wispSUI(pool_registry, _aggregator_registry, lst, ctx);
        transfer::public_transfer(wispSUI, tx_context::sender(ctx));
    }

    public fun mint_wispSUI_non_entry<T>(
        pool_registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        lst: Coin<T>,
        ctx: &mut TxContext
    ): Coin<WISPSUI> {
        pool::mint_wispSUI(pool_registry, _aggregator_registry, lst, ctx)
    }

    public entry fun mint_wispSUI_mul_coin<T>(
        pool_registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        lsts: vector<Coin<T>>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let lst = utils::extract_coin(lsts, amount, ctx);
        mint_wispSUI<T>(pool_registry, _aggregator_registry, lst, ctx);
    }

    public entry fun burn_wispSUI<T>(
        pool_registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        wispSUI: Coin<WISPSUI>,
        ctx: &mut TxContext
    ) {
        let lst = pool::burn_wispSUI<T>(pool_registry, _aggregator_registry, wispSUI, ctx);
        transfer::public_transfer(lst, tx_context::sender(ctx));
    }

    public fun burn_wispSUI_non_entry<T>(
        pool_registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        wispSUI: Coin<WISPSUI>,
        ctx: &mut TxContext
    ): Coin<T> {
        pool::burn_wispSUI<T>(pool_registry, _aggregator_registry, wispSUI, ctx)
    }

    public entry fun burn_wispSUI_mul_coin<T>(
        pool_registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        wispSUIs: vector<Coin<WISPSUI>>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let wispSUI = utils::extract_coin(wispSUIs, amount, ctx);
        burn_wispSUI<T>(pool_registry, _aggregator_registry, wispSUI, ctx);
    }

    public entry fun swap<I, O>(
        pool_registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        in_coin: Coin<I>,
        ctx: &mut TxContext,
    ) {
        let out_coin = pool::swap<I, O>(pool_registry, _aggregator_registry, in_coin, ctx);
        transfer::public_transfer(out_coin, tx_context::sender(ctx));
    }

    public fun swap_non_entry<I, O>(
        pool_registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        in_coin: Coin<I>,
        ctx: &mut TxContext,
    ): Coin<O> {
        pool::swap<I, O>(pool_registry, _aggregator_registry, in_coin, ctx)
    }

    public entry fun swap_mul_coin<I, O>(
        pool_registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        in_coins: vector<Coin<I>>,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        let in_coin = utils::extract_coin(in_coins, amount, ctx);
        swap<I, O>(pool_registry, _aggregator_registry, in_coin, ctx);
    }
}