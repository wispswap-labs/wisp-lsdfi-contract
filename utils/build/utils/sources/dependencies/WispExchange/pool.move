module wisp::pool {
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Supply, Balance};
    use sui::transfer;
    use sui::math;
    use sui::object_bag::{Self, ObjectBag};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use std::type_name::{TypeName};

    use wisp::pool_utils;
    use wisp::math_utils;
    use wisp::comparator;

    // Type error
    const ETypeNotSorted: u64 = 401;

    // For when supplied Coin is zero.
    const EZeroAmount: u64 = 501;

    // For when someone try to create pool that existed
    const EPoolCreated: u64 = 601;

    // For when someone tries to swap in an empty pool.
    const EReservesEmpty: u64 = 603;

    // For when someone tries to supply an object less than input amount
    const EInsufficientInput: u64 = 502;

    // For returned amount less than min amount
    const EInsufficientOutput: u64 = 503;

    // For when calculated price does not meet the required amount
    const EOutputExceed: u64 = 504;

    // For when someone want to get more amount than the reserve
    const EInsufficientReserve: u64 = 505;

    // For when liquidity minted is less than min liquidity
    const EInsufficientLiquidityMinted: u64 = 506;
    
    // Fee for swapping is 0.3% for all pool
    const FEE_PERCENT: u64 = 30;

    // Minimum liquidity to be locked forever
    const MINIMUM_LIQUIDITY: u64 = 1000;

    // Zero address
    const ZERO_ADDRESS: address = @0x0;

    // The Pool token that will be used to mark the pool share
    // of a liquidity provider. The first (F) is for the
    // First coin held in the pool and the second (S) is for the Second coin 
    struct WISPLP<phantom F, phantom S> has drop {}

    // The pool with exchange.
    //
    // - `fee_percent` should be in the range: [0-10000), meaning
    // that 10000 is 100% and 1 is 0.01%
    struct Pool<phantom F, phantom S> has key, store {
        id: UID,
        first_token: Balance<F>,
        second_token: Balance<S>,
        wisp_lp_supply: Supply<WISPLP<F, S>>,
        k_last: u128
    }

    // Struct respresent as key for pool in PoolRegistry
    struct PoolName has copy, drop, store {
        first_type: TypeName,
        second_type: TypeName
    }

    // For authenticate wisp owner
    // Only ControllerCap owner can create pool
    struct ControllerCap has key, store {
        id: UID
    }

    // For save pool setting and registry
    // fee_to = @0x0 means no fee minting
    struct PoolRegistry has key {
        id: UID,
        fee_to: address,
        pools: ObjectBag
    }

    // === Events ===
    
    struct PoolCreated<phantom F, phantom S> has copy, drop {
        pool: address,
        first_amount: u64,
        second_amount: u64,
        wisp_lp_amount: u64
    }

    struct LiquidityAdded<phantom F, phantom S> has copy, drop {
        user: address,
        first_amount: u64,
        second_amount: u64,
        first_reserve: u64,
        second_reserve: u64,
        wisp_lp_amount: u64,
        fee_amount: u64
    }

    struct LiquidityRemoved<phantom F, phantom S> has copy, drop {
        user: address,
        first_amount: u64,
        second_amount: u64,
        first_reserve: u64,
        second_reserve: u64,
        wisp_lp_amount: u64,
        fee_amount: u64
    }

    struct TokenSwapped<phantom F, phantom S> has copy, drop {
        user: address,
        first_amount_in: u64,
        second_amount_in: u64,
        first_amount_out: u64,
        second_amount_out: u64,
        first_reserve: u64,
        second_reserve: u64
    }

    struct FeeToSet has copy, drop {
        fee_to: address,
        caller: address
    }

    // Module initializer to create ControllerCap as owned object and PoolRegistry as shared_object
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            ControllerCap {id: object::new(ctx)}, 
            tx_context::sender(ctx)
        );
        transfer::share_object(
            PoolRegistry {
                id: object::new(ctx), 
                fee_to: ZERO_ADDRESS,
                pools: object_bag::new(ctx)
            }
        );
    }

    // Create new `Pool` for token `F` and S. Each Pool holds a `Coin<F>`
    // and a `Coin<S>`. Swaps are available in both directions.
    //
    // Share is calculated based on constant product formula: liquidity = sqrt( X * Y )
    public fun create_pool<F, S>(
        registry: &mut PoolRegistry,
        first_token: &mut Coin<F>,
        second_token: &mut Coin<S>,
        first_amount: u64,
        second_amount: u64,
        ctx: &mut TxContext
    ): Coin<WISPLP<F, S>> {
        let pools: &mut ObjectBag = &mut registry.pools;

        // get TypeName of two token
        let (type_F, type_S) = pool_utils::get_type<F, S>();

        // sort two token
        let sort_type = pool_utils::sort_token_type(&type_F, &type_S);
        assert!(comparator::is_smaller_than(&sort_type), ETypeNotSorted);

        let pool_name = PoolName {
            first_type: type_F, 
            second_type: type_S
        };

        assert!(!object_bag::contains_with_type<PoolName, Pool<F, S>>(pools, pool_name), EPoolCreated);

        let first_token_value = coin::value(first_token);
        let second_token_value = coin::value(second_token);

        // Check if input amount is enough
        assert!(first_token_value >= first_amount && second_token_value >= second_amount, EInsufficientInput);
        assert!(first_amount > 0 && second_amount > 0, EZeroAmount);

        // Take amount in balance 
        let first_balance = balance::split(coin::balance_mut(first_token), first_amount);
        let second_balance = balance::split(coin::balance_mut(second_token), second_amount);

        // Initial share of WISPLP is the sqrt(a) * sqrt(b)
        let share = math::sqrt(first_amount) * math::sqrt(second_amount);
        let wisp_lp_supply = balance::create_supply(WISPLP<F, S> {});
        let wisp_lp = balance::increase_supply(&mut wisp_lp_supply, share);
        let wisp_lp_value = balance::value(&wisp_lp);
        
        assert!(wisp_lp_value > MINIMUM_LIQUIDITY, EInsufficientLiquidityMinted);
        let wisp_lp_mut = &mut wisp_lp;
        let minimum_lock_wisp_lp = balance::split(wisp_lp_mut, MINIMUM_LIQUIDITY);
        transfer::public_transfer(coin::from_balance(minimum_lock_wisp_lp, ctx), ZERO_ADDRESS);

        let initial_K: u128 = (first_amount as u128) * (second_amount as u128);

        let new_pool = Pool {
            id: object::new(ctx),
            first_token: first_balance,
            second_token: second_balance,
            wisp_lp_supply,
            k_last: initial_K
        };

        // Emit Pool Created event
        event::emit(PoolCreated<F, S> {
            pool: object::id_to_address(object::uid_as_inner(&new_pool.id)),
            first_amount,
            second_amount,
            wisp_lp_amount: wisp_lp_value
        });

        object_bag::add(
            pools, 
            PoolName {first_type: type_F, second_type: type_S}, 
            new_pool
        );

        coin::from_balance(wisp_lp, ctx)
    }

    // Add liquidity to the `Pool`. Sender needs to provide both
    // `Coin<F>` and `Coin<S>`, and in exchange he gets `Coin<WISPLP>` -
    // liquidity provider tokens.
    public fun add_liquidity<F, S>(
        registry: &mut PoolRegistry, 
        first_token: &mut Coin<F>, 
        second_token: &mut Coin<S>, 
        amount_F_desired: u64, 
        amount_S_desired: u64, 
        amount_F_min: u64, 
        amount_S_min: u64, 
        ctx: &mut TxContext
    ): Coin<WISPLP<F, S>> {
        assert!(amount_F_desired > 0 && amount_S_desired > 0, EZeroAmount);
        assert!(
            coin::value(first_token) >= amount_F_desired 
            && coin::value(second_token) >= amount_S_desired, 
            EInsufficientInput
        );

        let fee_to: address = registry.fee_to;
        let pool: &mut Pool<F, S> = borrow_mut_pool<F, S>(registry);
        let (first_reserve, second_reserve, wisp_lp_supply) = get_amounts(pool);

        let (fee_on, fee_amount) = mint_fee(
            pool, 
            fee_to, 
            first_reserve, 
            second_reserve, 
            wisp_lp_supply, 
            ctx
        );
        wisp_lp_supply= balance::supply_value(&pool.wisp_lp_supply);

        let first_added: u64;
        let second_added: u64;

        let amount_S_optimal = pool_utils::quote(
            amount_F_desired, 
            first_reserve, 
            second_reserve
        );

        if (amount_S_optimal <= amount_S_desired) {
            assert!(amount_S_optimal >= amount_S_min, EInsufficientOutput);
            (first_added, second_added) = (amount_F_desired, amount_S_optimal);
        } else {
            let amount_F_optimal = pool_utils::quote(
                amount_S_desired, 
                second_reserve, 
                first_reserve
            );
            assert!(amount_F_optimal <= amount_F_desired, EOutputExceed);
            assert!(amount_F_optimal >= amount_F_min, EInsufficientOutput);
            (first_added, second_added) = (amount_F_optimal, amount_S_desired);
        };

        let first_balance = balance::split(coin::balance_mut(first_token), first_added);
        let second_balance = balance::split(coin::balance_mut(second_token), second_added);

        let share_minted: u128 = math_utils::min(
            (first_added as u128) * (wisp_lp_supply as u128) / (first_reserve as u128), 
            (second_added as u128) * (wisp_lp_supply as u128) / (second_reserve as u128)
        );
        assert!(share_minted > 0, EInsufficientLiquidityMinted);
    
        let first_amount = balance::join(&mut pool.first_token, first_balance);
        let second_amount = balance::join(&mut pool.second_token, second_balance);
      
        if (fee_on){
            let new_k: u128 = (first_amount as u128) * (second_amount as u128);
            pool.k_last = new_k;
        };

        let balance = balance::increase_supply(&mut pool.wisp_lp_supply, (share_minted as u64));

        // Emits Liquidity added event
        event::emit(LiquidityAdded<F, S> {
            user: tx_context::sender(ctx),
            first_amount: first_added,
            second_amount: second_added,
            first_reserve: first_reserve + first_added,
            second_reserve: second_reserve + second_added,
            wisp_lp_amount: (share_minted as u64),
            fee_amount
        });

        coin::from_balance(balance, ctx)
    }

    // Remove liquidity from the `Pool` by burning `Coin<WISPLP>`.
    // Returns `Coin<S>` and `Coin<F>`.
    public fun remove_liquidity<F, S>(
        registry: &mut PoolRegistry,
        wisp_lp: &mut Coin<WISPLP<F, S>>,
        wisp_lp_amount: u64,
        amount_F_min: u64,
        amount_S_min: u64,
        ctx: &mut TxContext
    ): (Coin<F>, Coin<S>) {
        // If there's a non-empty WISPLP, we can
        assert!(wisp_lp_amount > 0, EZeroAmount);
        assert!(coin::value(wisp_lp) >= wisp_lp_amount, EInsufficientInput);

        let fee_to: address = registry.fee_to;
        let pool: &mut Pool<F, S> = borrow_mut_pool<F, S>(registry);
        let (first_reserve, second_reserve, wisp_lp_supply) = get_amounts(pool);
        let (fee_on, fee_amount) = mint_fee(
            pool, 
            fee_to, 
            first_reserve, 
            second_reserve, 
            wisp_lp_supply, 
            ctx
        );
        
        wisp_lp_supply = balance::supply_value(&pool.wisp_lp_supply);
        let first_removed: u64 = ((first_reserve as u128) * (wisp_lp_amount as u128) / (wisp_lp_supply as u128) as u64);
        let second_removed: u64 = ((second_reserve as u128) * (wisp_lp_amount as u128) / (wisp_lp_supply as u128) as u64);
        
        assert!(first_removed >= amount_F_min && second_removed >= amount_S_min, EInsufficientOutput);

        if (fee_on){
            let new_k: u128 = (first_reserve - first_removed as u128) * (second_reserve - second_removed as u128);
            pool.k_last = new_k;
        };

        balance::decrease_supply(&mut pool.wisp_lp_supply, balance::split(coin::balance_mut(wisp_lp), wisp_lp_amount));
        
        event::emit(LiquidityRemoved<F, S> {
            user: tx_context::sender(ctx),
            first_amount: first_removed,
            second_amount: second_removed,
            first_reserve: first_reserve - first_removed,
            second_reserve: second_reserve - second_removed,
            wisp_lp_amount: wisp_lp_amount,
            fee_amount
        });

        (
            coin::take(&mut pool.first_token, first_removed, ctx),
            coin::take(&mut pool.second_token, second_removed, ctx)
        )
    }

    // Add liquidity with onesided input Coin<F>. First process swap with optimal amount, then add liquidity.
    public fun zap_in_first<F, S> (
        registry: &mut PoolRegistry,
        first_token: &mut Coin<F>,
        first_amount: u64,
        ctx: &mut TxContext
    ): (Coin<WISPLP<F, S>>, Coin<S>) {
        assert!(coin::value(first_token) >= first_amount, EInsufficientInput);
        
        let pool: &mut Pool<F, S> = borrow_mut_pool<F, S>(registry);
        let (first_reserve, _second_reserve, _) = get_amounts(pool);

        let zap_in_amount = pool_utils::get_optimal_zap_in_amount(first_amount, first_reserve);

        let second_token_output: Coin<S> = coin::zero<S>(ctx);
        process_swap_exact_input<F, S>(
            pool, 
            first_token, 
            &mut second_token_output, 
            zap_in_amount, 
            false, 
            ctx
        );

        let second_token_amount: u64 = coin::value(&second_token_output);
        let wisp_lp: Coin<WISPLP<F, S>> = add_liquidity(
            registry, 
            first_token, 
            &mut second_token_output, 
            first_amount - zap_in_amount, 
            second_token_amount, 
            0, 
            0, 
            ctx
        );
        (wisp_lp, second_token_output)
    }

    // Add liquidity with onesided input Coin<S>. First process swap with optimal amount, then add liquidity.
    public fun zap_in_second<F, S> (
        registry: &mut PoolRegistry,
        second_token: &mut Coin<S>,
        second_amount: u64,
        ctx: &mut TxContext
    ): (Coin<WISPLP<F, S>>, Coin<F>) {
        assert!(coin::value(second_token) >= second_amount, EInsufficientInput);
        
        let pool: &mut Pool<F, S> = borrow_mut_pool<F, S>(registry);
        let (_first_reserve, second_reserve, _) = get_amounts(pool);

        let zap_in_amount = pool_utils::get_optimal_zap_in_amount(second_amount, second_reserve);     

        let first_token_output: Coin<F> = coin::zero<F>(ctx);
        process_swap_exact_input<F, S>(
            pool, 
            &mut first_token_output, 
            second_token, 
            zap_in_amount, 
            true, 
            ctx
        );
        
        let first_token_amount: u64 = coin::value(&first_token_output);

        let wisp_lp: Coin<WISPLP<F, S>> = add_liquidity(
            registry, 
            &mut first_token_output, 
            second_token, 
            first_token_amount, 
            second_amount - zap_in_amount, 
            0, 
            0, 
            ctx
        );
        (wisp_lp, first_token_output)
    }

    // Swap exact `Coin<F>` for the `Coin<S>`. 
    // This function must call from package which sorted type by alphabet
    // Returns Coin<S>.
    public fun swap_exact_first_to_second<F, S>(
        registry: &mut PoolRegistry,
        first_token: &mut Coin<F>, 
        input_amount: u64, 
        min_output_amount: u64, 
        ctx: &mut TxContext
    ): (Coin<S>) {
        assert!(input_amount > 0, EZeroAmount);
        assert!(coin::value(first_token) >= input_amount, EInsufficientInput);

        let pool: &mut Pool<F, S> = borrow_mut_pool<F, S>(registry);
        let second_token_output: Coin<S> = coin::zero<S>(ctx);

        // Get output token
        process_swap_exact_input<F, S>(
            pool, first_token, 
            &mut second_token_output, 
            input_amount, 
            false, 
            ctx
        );
        assert!(coin::value(&second_token_output) >= min_output_amount, EInsufficientOutput);

        second_token_output
    }

    // Swap exact `Coin<S>` for the `Coin<F>`.
    // This function must call from package which sorted type by alphabet
    // Returns the swapped `Coin<F>`.
    public fun swap_exact_second_to_first<F, S>(
        registry: &mut PoolRegistry,
        second_token: &mut Coin<S>, 
        input_amount: u64, 
        min_output_amount: u64, 
        ctx: &mut TxContext
    ): (Coin<F>) {
        assert!(input_amount > 0, EZeroAmount);
        assert!(coin::value(second_token) >= input_amount, EInsufficientInput);

        let pool: &mut Pool<F, S> = borrow_mut_pool<F, S>(registry);
        let first_token_output: Coin<F> = coin::zero<F>(ctx);

        // Get output token
        process_swap_exact_input<F, S>(
            pool, 
            &mut first_token_output, 
            second_token, 
            input_amount, 
            true, 
            ctx
        );
        assert!(coin::value(&first_token_output) >= min_output_amount, EInsufficientOutput);

        first_token_output
    }

    // Swap `Coin<F>` for the exact `Coin<S>`.
    // This function must call from package which sorted type by alphabet
    // Returns Coin<S>.
    public fun swap_first_to_exact_second<F, S>(
        registry: &mut PoolRegistry,
        first_token: &mut Coin<F>, 
        output_amount: u64, 
        max_input_amount: u64, 
        ctx: &mut TxContext
    ): (Coin<S>) {
        assert!(output_amount > 0, EZeroAmount);
        assert!(max_input_amount > 0, EZeroAmount);
        let first_amount = coin::value(first_token);
        assert!(first_amount >= max_input_amount, EInsufficientInput);

        let pool: &mut Pool<F, S> = borrow_mut_pool<F, S>(registry);
        let second_token_output: Coin<S> = coin::zero<S>(ctx);

        // Calculate the input amount - fee
        process_swap_exact_output<F, S>(
            pool, 
            first_token, 
            &mut second_token_output, 
            output_amount, 
            false, 
            ctx
        );

        assert!(first_amount - coin::value(first_token) <= max_input_amount, EOutputExceed);
        second_token_output
    }

    // Swap `Coin<S>` for the exact `Coin<F>`.
    // This function must call from package which sorted type by alphabet
    // Returns the swapped `Coin<F>`.
    public fun swap_second_to_exact_first<F, S>(
        registry: &mut PoolRegistry, 
        second_token: &mut Coin<S>, 
        output_amount: u64, 
        max_input_amount: u64, 
        ctx: &mut TxContext
    ): (Coin<F>) {
        assert!(output_amount > 0, EZeroAmount);
        assert!(max_input_amount > 0, EZeroAmount);
        let second_amount = coin::value(second_token);
        assert!(second_amount >= max_input_amount, EInsufficientInput);

        let pool: &mut Pool<F, S> = borrow_mut_pool<F, S>(registry);
        let first_token_output: Coin<F> = coin::zero<F>(ctx);

        // Calculate the input amount - fee
        process_swap_exact_output<F, S>(
            pool, 
            &mut first_token_output, 
            second_token, 
            output_amount, 
            true, 
            ctx
        );

        assert!(second_amount - coin::value(second_token) <= max_input_amount, EOutputExceed);
        first_token_output
    }

    // Swapping exact input without concern about slippage, must be very careful to use this function
    public fun process_swap_exact_input<F, S>(
        pool: &mut Pool<F, S>, 
        first_token: &mut Coin<F>, 
        second_token: &mut Coin<S>, 
        input_amount: u64, 
        is_reverse: bool,
        ctx: &mut TxContext
    ) {
        // Calculate the output amount - fee
        let output_amount: u64 = get_output_amount<F, S>(pool, input_amount, is_reverse);
        
        swap<F, S>(
            pool, 
            first_token, 
            second_token, 
            input_amount, 
            output_amount, 
            is_reverse, 
            ctx
        );
    }

    // Swapping to get exact output without concern about slippage, must be very careful to use this function
    public fun process_swap_exact_output<F, S>(
        pool: &mut Pool<F, S>, 
        first_token: &mut Coin<F>,
        second_token: &mut Coin<S>,
        output_amount: u64,  
        is_reverse: bool,
        ctx: &mut TxContext
        ) {
        // Calculate the output amount - fee
        let input_amount: u64 = get_input_amount<F, S>(pool, output_amount, is_reverse); 
        
        swap<F, S>(
            pool, 
            first_token, 
            second_token, 
            input_amount, 
            output_amount, 
            is_reverse, 
            ctx
        );
    }

    // Set new fee_to address, only ControllerCap owner can call this function
    public entry fun set_fee_to_(
        _: &ControllerCap,
        registry: &mut PoolRegistry,
        fee_to: address,
        ctx: &mut TxContext
    ) {
        set_fee_to(registry, fee_to, ctx);
    }

    // mint service fee to fee_to address
    fun mint_fee<F, S>(
        pool: &mut Pool<F, S>, 
        fee_to: address, 
        reserve_F: u64, 
        reserve_S: u64, 
        wisp_lp_supply: u64,
        ctx: &mut TxContext
    ): (bool, u64) {
        let liquidity: u64 = 0;
        let fee_on = false;
        if (fee_to != @0x0) {
            fee_on = true;
            if (pool.k_last != 0){
                let root_k: u128 = math_utils::sqrt((reserve_F as u128) * (reserve_S as u128));
                let root_k_last: u128 = math_utils::sqrt(pool.k_last);

                if (root_k > root_k_last){
                    let numerator: u128 = (wisp_lp_supply as u128) * (root_k - root_k_last);
                    let denominator: u128 = root_k * 5 + root_k_last;
                    liquidity = ((numerator / denominator) as u64);     

                    if (liquidity > 0) {
                        let fee_balance = balance::increase_supply(&mut pool.wisp_lp_supply, liquidity);
                        transfer::public_transfer(coin::from_balance(fee_balance, ctx), fee_to)
                    }
                }
            }
        } else if (pool.k_last != 0) {
            pool.k_last = 0;
        }; 
        (fee_on, liquidity)
    }
    
    fun set_fee_to(
        registry: &mut PoolRegistry,
        fee_to: address,
        ctx: &mut TxContext
    ){
        registry.fee_to = fee_to;

        event::emit(FeeToSet {
            fee_to,
            caller: tx_context::sender(ctx)
        });
    }
    
    fun swap<F, S>(
        pool: &mut Pool<F, S>, 
        first_token: &mut Coin<F>,
        second_token: &mut Coin<S>,
        input_amount: u64,
        output_amount: u64,  
        is_reverse: bool,
        ctx: &mut TxContext
    ) {
        let (first_reserve, second_reserve, _) = get_amounts(pool);

        if (!is_reverse) {
            assert!(coin::value(first_token) >= input_amount, EInsufficientInput);
            let first_balance = balance::split(coin::balance_mut(first_token), input_amount);

            balance::join(&mut pool.first_token, first_balance);
            coin::join(second_token, coin::take(&mut pool.second_token, output_amount, ctx));

            event::emit(TokenSwapped<F, S> {
                user: tx_context::sender(ctx),
                first_amount_in: input_amount,
                second_amount_in: 0,
                first_amount_out: 0,
                second_amount_out: output_amount,
                first_reserve: first_reserve + input_amount,
                second_reserve: second_reserve - output_amount
            });
        } else {
            assert!(coin::value(second_token) >= input_amount, EInsufficientInput);
            let second_balance = balance::split(coin::balance_mut(second_token), input_amount);

            balance::join(&mut pool.second_token, second_balance);
            coin::join(first_token, coin::take(&mut pool.first_token, output_amount, ctx));

            event::emit(TokenSwapped<F, S> {
                user: tx_context::sender(ctx),
                first_amount_in: 0,
                second_amount_in: input_amount,
                first_amount_out: output_amount,
                second_amount_out: 0,
                first_reserve: first_reserve - output_amount,
                second_reserve: second_reserve + input_amount
            })
        }
    }

    // get output amount with the corresponding input amount
    public fun get_output_amount<F, S>(pool: &Pool<F, S>, input_amount: u64, is_reverse: bool): u64 {
        let (first_reserve, second_reserve, _) = get_amounts(pool);
        assert!(first_reserve > 0 && second_reserve > 0, EReservesEmpty);
        
        // Calculate the output amount - fee
        let output_amount: u64;
        if(!is_reverse) {
            output_amount = pool_utils::get_input_price(
                input_amount,
                first_reserve,
                second_reserve,
                FEE_PERCENT
            );
        } else {
            output_amount = pool_utils::get_input_price(
                input_amount,
                second_reserve,
                first_reserve,
                FEE_PERCENT
            );
        };
        output_amount
    }

    // get input amount with the corresponding output amount
    public fun get_input_amount<F, S>(pool: &Pool<F, S>, output_amount: u64, is_reverse: bool): u64 {
        let (first_reserve, second_reserve, _) = get_amounts(pool);
        assert!(first_reserve > 0 && second_reserve > 0, EReservesEmpty);
        assert!(output_amount < second_reserve, EInsufficientReserve);

        let input_amount: u64;

        // Calculate the inputput amount - fee
        if(!is_reverse) {
            input_amount = pool_utils::get_output_price(
                output_amount,
                first_reserve,
                second_reserve,
                FEE_PERCENT
            );
        } else {
            input_amount = pool_utils::get_output_price(
                output_amount,
                second_reserve,
                first_reserve,
                FEE_PERCENT
            );
        };
        input_amount
    }

    public fun create_pool_name(
        type_F: TypeName,
        type_S: TypeName
    ):PoolName {
        PoolName {first_type: type_F, second_type: type_S}
    }

    public fun is_pool_created<F, S>(registry: &PoolRegistry): bool {
        (is_pool_created_sorted<F, S>(registry) || is_pool_created_sorted<S, F>(registry))
    }

    public fun is_pool_created_sorted<F, S>(registry: &PoolRegistry): bool {
        let (type_F, type_S) = pool_utils::get_type<F, S>();
        let pool_name = PoolName {first_type: type_F, second_type: type_S};

        object_bag::contains_with_type<PoolName, Pool<F, S>>(&registry.pools, pool_name)
    }

    public fun borrow_pool<F, S>(registry: &PoolRegistry): &Pool<F, S> {
        let (type_F, type_S) = pool_utils::get_type<F, S>();
        let pool_name = PoolName {first_type: type_F, second_type: type_S};

        object_bag::borrow(&registry.pools, pool_name)
    }

    public fun borrow_mut_pool<F, S>(registry: &mut PoolRegistry): &mut Pool<F, S> {
        let (type_F, type_S) = pool_utils::get_type<F, S>();
        let pool_name = PoolName {first_type: type_F, second_type: type_S};

        object_bag::borrow_mut(&mut registry.pools, pool_name)
    }

    // Get most used values in a handy way:
    // - amount of F
    // - amount of S
    // - total supply of WISPLP
    public fun get_amounts<F, S>(pool: &Pool<F, S>): (u64, u64, u64) {
        (
            balance::value(&pool.first_token),
            balance::value(&pool.second_token),
            balance::supply_value(&pool.wisp_lp_supply)
        )
    }

    public fun get_pool_data<F, S>(pool: &Pool<F, S>): (u64, u64, u64, u64, u128) {
        (
            balance::value(&pool.first_token),
            balance::value(&pool.second_token),
            balance::supply_value(&pool.wisp_lp_supply),
            FEE_PERCENT,
            pool.k_last
        )
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        transfer::transfer(
            ControllerCap {id: object::new(ctx)}, 
            tx_context::sender(ctx)
        );
        transfer::share_object(
            PoolRegistry {
                id: object::new(ctx), 
                fee_to: @0x0,
                pools: object_bag::new(ctx)
            }
        );
    }

    #[test_only]
    public fun get_setting(
        registry: &PoolRegistry
    ): address {
        registry.fee_to
    }
}
