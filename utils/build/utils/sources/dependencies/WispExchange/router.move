module wisp::router {
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::pay;

    use wisp::pool::{Self, PoolRegistry, WISPLP};
    use wisp::comparator;
    use wisp::pool_utils;
    
    const ETypeEqual: u64 = 402;
    const EPoolNotCreated: u64 = 602;

    // For when calculated price does not meet the required amount
    const ENotMeetRequiredAmount: u64 = 504;
   
    // Entry function to create new pool
    // Take first_amount of first_token object and second_amount of second_token object
    public entry fun create_pool_<F, S>(
        registry: &mut PoolRegistry,
        first_tokens: vector<Coin<F>>,
        second_tokens: vector<Coin<S>>,
        first_amount: u64,
        second_amount: u64,
        ctx: &mut TxContext
    ){
        // get TypeName of two token
        let (type_F, type_S) = pool_utils::get_type<F, S>();

        // sort two token
        let sort_type = pool_utils::sort_token_type(&type_F, &type_S);
        assert!(!comparator::is_equal(&sort_type), ETypeEqual);

        let first_token: Coin<F> = coin::zero<F>(ctx);
        let second_token: Coin<S> = coin::zero<S>(ctx);
        pay::join_vec<F>(&mut first_token, first_tokens);
        pay::join_vec<S>(&mut second_token, second_tokens);

        if(comparator::is_smaller_than(&sort_type)) {
            let wisp_lp: Coin<WISPLP<F, S>>;
            wisp_lp = pool::create_pool(
                registry,
                &mut first_token, 
                &mut second_token, 
                first_amount, 
                second_amount, 
                ctx
            );
            transfer::public_transfer(wisp_lp, tx_context::sender(ctx));
        } else {
            let wisp_lp: Coin<WISPLP<S, F>>;
            wisp_lp = pool::create_pool(
                registry,
                &mut second_token, 
                &mut first_token, 
                second_amount, 
                first_amount, 
                ctx
            );
            transfer::public_transfer(wisp_lp, tx_context::sender(ctx));
        };
        
        pool_utils::execute_return_token<F>(first_token, ctx);
        pool_utils::execute_return_token<S>(second_token, ctx);  
    }

    // Entrypoint for the `add_liquidity` method. Sends `Coin<WISPLP>` to
    // the transaction sender.
    public entry fun add_liquidity_<F, S>(
        registry: &mut PoolRegistry, 
        first_tokens: vector<Coin<F>>,
        second_tokens: vector<Coin<S>>, 
        amount_first_desired: u64, 
        amount_second_desired: u64, 
        amount_first_min: u64, 
        amount_second_min: u64, 
        ctx: &mut TxContext
    ) {
        // get TypeName of two token
        let (type_F, type_S) = pool_utils::get_type<F, S>();

        // sort two token
        let sort_type = pool_utils::sort_token_type(&type_F, &type_S);
        assert!(!comparator::is_equal(&sort_type), ETypeEqual);

        let first_token: Coin<F> = coin::zero<F>(ctx);
        let second_token: Coin<S> = coin::zero<S>(ctx);
        pay::join_vec<F>(&mut first_token, first_tokens);
        pay::join_vec<S>(&mut second_token, second_tokens);

        if(comparator::is_smaller_than(&sort_type)) {
            let wisp_lp: Coin<WISPLP<F, S>>;
            wisp_lp = pool::add_liquidity(
                registry, 
                &mut first_token, 
                &mut second_token, 
                amount_first_desired, 
                amount_second_desired, 
                amount_first_min, 
                amount_second_min, 
                ctx
            );
        
            transfer::public_transfer(wisp_lp, tx_context::sender(ctx));
        } else {
            let wisp_lp: Coin<WISPLP<S, F>>;
            wisp_lp = pool::add_liquidity(
                registry, 
                &mut second_token, 
                &mut first_token, 
                amount_second_desired, 
                amount_first_desired,
                amount_second_min, 
                amount_first_min,  
                ctx
            );
        
            transfer::public_transfer(wisp_lp, tx_context::sender(ctx));
        };
        
        pool_utils::execute_return_token<F>(first_token, ctx);
        pool_utils::execute_return_token<S>(second_token, ctx);  
    }

    // Entrypoint for the `remove_liquidity` method. Transfers
    // withdrawn assets to the sender.
    public entry fun remove_liquidity_<F, S>(
        registry: &mut PoolRegistry,
        wisp_lps: vector<Coin<WISPLP<F, S>>>,
        wisp_lp_amount: u64,
        amount_first_min: u64,
        amount_second_min: u64,
        ctx: &mut TxContext
    ) {
        let wisp_lp: Coin<WISPLP<F, S>> = coin::zero<WISPLP<F, S>>(ctx);
        pay::join_vec<WISPLP<F, S>>(&mut wisp_lp, wisp_lps);

        let (first, second) = pool::remove_liquidity(
            registry, 
            &mut wisp_lp, 
            wisp_lp_amount, 
            amount_first_min, 
            amount_second_min, 
            ctx
        );

        let sender = tx_context::sender(ctx);

        transfer::public_transfer(first, sender);
        transfer::public_transfer(second, sender);

        pool_utils::execute_return_token<WISPLP<F, S>>(wisp_lp, ctx);
    }

    public entry fun zap_in_<F, S>(
        registry: &mut PoolRegistry,
        input_tokens: vector<Coin<F>>, 
        input_amount: u64, 
        ctx: &mut TxContext
    ) {
        // get TypeName of two token
        let (type_F, type_S) = pool_utils::get_type<F, S>();
        // sort two token
        let sort_type = pool_utils::sort_token_type(&type_F, &type_S);
        assert!(!comparator::is_equal(&sort_type), ETypeEqual);
        assert!(pool::is_pool_created<F, S>(registry), EPoolNotCreated);

        let input_token: Coin<F> = coin::zero<F>(ctx);
        pay::join_vec<F>(&mut input_token, input_tokens); 
        let output_token: Coin<S>;   

        if(comparator::is_smaller_than(&sort_type)) {
            let wisp_lp: Coin<WISPLP<F, S>>;
 
            (wisp_lp, output_token) = pool::zap_in_first(
                registry, 
                &mut input_token, 
                input_amount, 
                ctx
            );
            transfer::public_transfer(wisp_lp, tx_context::sender(ctx));
        } else {
            let wisp_lp: Coin<WISPLP<S, F>>;
   
            (wisp_lp, output_token) = pool::zap_in_second(
                registry, 
                &mut input_token, 
                input_amount, 
                ctx
            );
            transfer::public_transfer(wisp_lp, tx_context::sender(ctx));
        };
        pool_utils::execute_return_token<F>(input_token, ctx);
        pool_utils::execute_return_token<S>(output_token, ctx);
    }

    // Entrypoint for the `swap_exact_first_to_second` method. Sends swapped token
    // to sender.
    public entry fun swap_exact_input_<F, S>(
        registry: &mut PoolRegistry,
        input_tokens: vector<Coin<F>>, 
        input_amount: u64, 
        min_output_amount: u64, 
        ctx: &mut TxContext
    ) {
        // get TypeName of two token
        let (type_F, type_S) = pool_utils::get_type<F, S>();
        // sort two token
        let sort_type = pool_utils::sort_token_type(&type_F, &type_S);
        assert!(!comparator::is_equal(&sort_type), ETypeEqual);
        assert!(pool::is_pool_created<F, S>(registry), EPoolNotCreated);
        
        let input_token: Coin<F> = coin::zero<F>(ctx);
        pay::join_vec<F>(&mut input_token, input_tokens);

        let output_token: Coin<S>;

        if (comparator::is_smaller_than(&sort_type)) {
            output_token = pool::swap_exact_first_to_second<F, S>(
                registry,
                &mut input_token,
                input_amount,
                min_output_amount,
                ctx
            );
        } else {
            output_token = pool::swap_exact_second_to_first<S, F>(
                registry,
                &mut input_token,
                input_amount,
                min_output_amount,
                ctx
            );
        };

        pool_utils::execute_return_token<F>(input_token, ctx);

        transfer::public_transfer(output_token, tx_context::sender(ctx));
    }

    public entry fun swap_exact_output_<F, S>(
        registry: &mut PoolRegistry, 
        input_tokens: vector<Coin<F>>, 
        output_amount: u64, 
        max_input_amount: u64, 
        ctx: &mut TxContext
    ) {
        // get TypeName of two token
        let (type_F, type_S) = pool_utils::get_type<F, S>();
        // sort two token
        let sort_type = pool_utils::sort_token_type(&type_F, &type_S);
        assert!(!comparator::is_equal(&sort_type), ETypeEqual);
        assert!(pool::is_pool_created<F, S>(registry), EPoolNotCreated);

        let input_token: Coin<F> = coin::zero<F>(ctx);
        pay::join_vec<F>(&mut input_token, input_tokens);

        let output_token: Coin<S>;

        if (comparator::is_smaller_than(&sort_type)) {
            output_token = pool::swap_first_to_exact_second<F, S>(
                registry,
                &mut input_token,
                output_amount,
                max_input_amount,
                ctx
            );
        } else {
            output_token = pool::swap_second_to_exact_first<S, F>(
                registry,
                &mut input_token,
                output_amount,
                max_input_amount,
                ctx
            );
        };

        pool_utils::execute_return_token<F>(input_token, ctx);

        transfer::public_transfer(output_token, tx_context::sender(ctx));
    }

    public entry fun swap_exact_input_doublehop_<F, S, T>(
        registry: &mut PoolRegistry,
        input_tokens: vector<Coin<F>>, 
        input_amount: u64, 
        min_output_amount: u64, 
        ctx: &mut TxContext
    ) {
        let (type_F, type_S, type_T) = pool_utils::get_triple_type<F, S, T>();
        
        let sort_first_pool = pool_utils::sort_token_type(&type_F, &type_S);
        assert!(!comparator::is_equal(&sort_first_pool), ETypeEqual);
        assert!(pool::is_pool_created<F, S>(registry), EPoolNotCreated);

        let sort_second_pool = pool_utils::sort_token_type(&type_S, &type_T);
        assert!(!comparator::is_equal(&sort_second_pool), ETypeEqual);
        assert!(pool::is_pool_created<S, T>(registry), EPoolNotCreated);

        let input_token: Coin<F> = coin::zero<F>(ctx);
        pay::join_vec<F>(&mut input_token, input_tokens);

        let inter_token: Coin<S> = coin::zero<S>(ctx);
        if (comparator::is_smaller_than(&sort_first_pool)) {
            let first_pool = pool::borrow_mut_pool<F, S>(registry);
            pool::process_swap_exact_input<F, S>(
                first_pool, 
                &mut input_token, 
                &mut inter_token, 
                input_amount, 
                false, 
                ctx
            );
        } else {
            let first_pool = pool::borrow_mut_pool<S, F>(registry);
            pool::process_swap_exact_input<S, F>(
                first_pool, 
                &mut inter_token, 
                &mut input_token, 
                input_amount, 
                true, 
                ctx
            );
        };

        let inter_amount: u64 = coin::value<S>(&inter_token);
        let output_token: Coin<T> = coin::zero<T>(ctx);
        if (comparator::is_smaller_than(&sort_second_pool)) {
            let second_pool = pool::borrow_mut_pool<S, T>(registry);
            pool::process_swap_exact_input<S, T>(
                second_pool, 
                &mut inter_token, 
                &mut output_token, 
                inter_amount, 
                false, 
                ctx
            );
        } else {
            let second_pool = pool::borrow_mut_pool<T, S>(registry);
            pool::process_swap_exact_input<T, S>(
                second_pool, 
                &mut output_token, 
                &mut inter_token, 
                inter_amount, 
                true, 
                ctx
            );
        };

        assert!(coin::value(&output_token) >= min_output_amount, ENotMeetRequiredAmount);

        coin::destroy_zero<S>(inter_token);

        pool_utils::execute_return_token<F>(input_token, ctx);

        transfer::public_transfer(output_token, tx_context::sender(ctx));
    }

    public entry fun swap_exact_output_doublehop_<F, S, T>(
        registry: &mut PoolRegistry, 
        input_tokens: vector<Coin<F>>, 
        output_amount: u64, 
        max_input_amount: u64, 
        ctx: &mut TxContext
    ) {
        let (type_F, type_S, type_T) = pool_utils::get_triple_type<F, S, T>();
        
        let sort_first_pool = pool_utils::sort_token_type(&type_F, &type_S);
        assert!(!comparator::is_equal(&sort_first_pool), ETypeEqual);
        assert!(pool::is_pool_created<F, S>(registry), EPoolNotCreated);

        let sort_second_pool = pool_utils::sort_token_type(&type_S, &type_T);
        assert!(!comparator::is_equal(&sort_second_pool), ETypeEqual);
        assert!(pool::is_pool_created<S, T>(registry), EPoolNotCreated);

        let inter_amount: u64;
        if (comparator::is_smaller_than(&sort_second_pool)) {
            let second_pool = pool::borrow_mut_pool<S, T>(registry);
            inter_amount= pool::get_input_amount<S, T>(second_pool, output_amount, false);            
        } else {
            let second_pool = pool::borrow_mut_pool<T, S>(registry);
            inter_amount= pool::get_input_amount<T, S>(second_pool, output_amount, true);
        };
        
        let input_amount: u64;
        if (comparator::is_smaller_than(&sort_first_pool)) {
            let first_pool = pool::borrow_mut_pool<F, S>(registry);
            input_amount = pool::get_input_amount<F, S>(first_pool, inter_amount, false);
        } else {
            let first_pool = pool::borrow_mut_pool<S, F>(registry);
            input_amount = pool::get_input_amount<S, F>(first_pool, inter_amount, true);
        };

        assert!(input_amount <= max_input_amount, ENotMeetRequiredAmount);
        
        
        let input_token: Coin<F> = coin::zero<F>(ctx);
        pay::join_vec<F>(&mut input_token, input_tokens);

        let inter_token: Coin<S> = coin::zero<S>(ctx);
        if (comparator::is_smaller_than(&sort_first_pool)) {
            let first_pool = pool::borrow_mut_pool<F, S>(registry);
            pool::process_swap_exact_output<F, S>(
                first_pool, 
                &mut input_token, 
                &mut inter_token, 
                inter_amount, 
                false, 
                ctx
            );
        } else {
            let first_pool = pool::borrow_mut_pool<S, F>(registry);
            pool::process_swap_exact_output<S, F>(
                first_pool, 
                &mut inter_token, 
                &mut input_token, 
                inter_amount, 
                true, 
                ctx
            );
        };

        let output_token: Coin<T> = coin::zero<T>(ctx);
        if (comparator::is_smaller_than(&sort_second_pool)) {
            let second_pool = pool::borrow_mut_pool<S, T>(registry);
            pool::process_swap_exact_output<S, T>(
                second_pool, 
                &mut inter_token, 
                &mut output_token, 
                output_amount, 
                false, 
                ctx
            );
        } else {
            let second_pool = pool::borrow_mut_pool<T, S>(registry);
            pool::process_swap_exact_output<T, S>(
                second_pool, 
                &mut output_token, 
                &mut inter_token, 
                output_amount, 
                true, 
                ctx
            );
        };

        coin::destroy_zero<S>(inter_token);

        pool_utils::execute_return_token<F>(input_token, ctx);

        transfer::public_transfer(output_token, tx_context::sender(ctx));
    }
}