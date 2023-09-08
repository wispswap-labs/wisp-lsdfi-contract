module wisp_lsdfi::pool {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self, Balance};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::bag::{Self, Bag};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_set::{Self, VecSet};
    use std::type_name::{Self, TypeName};
    use std::option::{Self, Option};

    use wisp_lsdfi::wispSUI::WISPSUI;
    use wisp_lsdfi::lsdfi_errors;

    use aggregator::aggregator::{Self, AggregatorRegistry};

    friend wisp_lsdfi::lsdfi;

    struct AdminCap has key, store {
        id: UID,
    }

    struct PoolRegistry has key, store {
        id: UID,
        balances: Bag,
        supported_lsts: VecSet<TypeName>,
        wispSUI_treasury: Option<TreasuryCap<WISPSUI>>,
        fee_to: address
    }

    // Events
    struct LSTStatusUpdated has copy, drop {
        lst_name: TypeName,
        status: bool,
    }

    struct BalanceChanged has copy, drop {
        sender: address,
        in_token: TypeName,
        in_amount: u64,
        out_token: TypeName,
        out_amount: u64,
    }

    fun init (ctx: &mut TxContext){
        let sender = tx_context::sender(ctx);

        let admin_cap = AdminCap {
            id: object::new(ctx)
        };

        let pool_registry = PoolRegistry {
            id: object::new(ctx),
            balances: bag::new(ctx),
            supported_lsts: vec_set::empty(),
            wispSUI_treasury: option::none(),
            fee_to: sender
        };

        transfer::transfer(admin_cap, sender);
        transfer::share_object(pool_registry);
    }

    public entry fun initialize (
        _: &AdminCap,
        registry: &mut PoolRegistry,
        wispSUI_treasury: TreasuryCap<WISPSUI>
    ) {
        option::fill(&mut registry.wispSUI_treasury, wispSUI_treasury);
    }

    public entry fun set_supported_lst<T> (
        _: &AdminCap,
        registry: &mut PoolRegistry,
        status: bool,
    ) {
        let name = type_name::get<T>();
        if (!status) {
            assert!(vec_set::contains(&registry.supported_lsts, &name), lsdfi_errors::StatusAlreadySet());
            vec_set::remove(&mut registry.supported_lsts, &name);
        } else {
            assert!(!vec_set::contains(&registry.supported_lsts, &name), lsdfi_errors::StatusAlreadySet());
            vec_set::insert(&mut registry.supported_lsts, name);
        };

        event::emit (LSTStatusUpdated {
            lst_name: name,
            status: status
        });
    }

    public (friend) fun mint_wispSUI<T> (
        registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        lst: Coin<T>,
        ctx: &mut TxContext
    ): Coin<WISPSUI> {
        let lst_name = type_name::get<T>();
        assert!(vec_set::contains(&registry.supported_lsts, &lst_name), lsdfi_errors::LSDNotSupport());
        let lst_amount = coin::value(&lst);
        let wispSUI_amount = get_wispSUI_mint_amount(lst_amount);

        if(!bag::contains(&registry.balances, lst_name)) {
            bag::add(&mut registry.balances, lst_name, balance::zero<T>());
        };
        
        balance::join(
            bag::borrow_mut<TypeName, Balance<T>>(&mut registry.balances, lst_name),
            coin::into_balance(lst)
        );

        let wispSUI = coin::mint<WISPSUI>(option::borrow_mut(&mut registry.wispSUI_treasury), wispSUI_amount, ctx);

        event::emit(BalanceChanged {
            sender: tx_context::sender(ctx),
            in_token: lst_name,
            in_amount: lst_amount,
            out_token: type_name::get<WISPSUI>(),
            out_amount: wispSUI_amount
        });

        wispSUI
    }

    public (friend) fun burn_wispSUI<T> (
        registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        wispSUI: Coin<WISPSUI>,
        ctx: &mut TxContext
    ): Coin<T> {
        let lst_name = type_name::get<T>();
        assert!(vec_set::contains(&registry.supported_lsts, &lst_name), lsdfi_errors::LSDNotSupport());
        let wispSUI_amount = coin::value(&wispSUI);
        let lst_amount = get_wispSUI_burn_amount(wispSUI_amount);
        
        assert!(balance::value(bag::borrow<TypeName, Balance<T>>(&registry.balances, lst_name)) >= lst_amount, lsdfi_errors::NotEnoughBalance());
        let lst_balance = balance::split(bag::borrow_mut<TypeName, Balance<T>>(&mut registry.balances, lst_name), lst_amount);

        coin::burn(option::borrow_mut(&mut registry.wispSUI_treasury), wispSUI);

        event::emit(BalanceChanged {
            sender: tx_context::sender(ctx),
            in_token: type_name::get<WISPSUI>(),
            in_amount: wispSUI_amount,
            out_token: lst_name,
            out_amount: lst_amount
        });

        coin::from_balance(lst_balance, ctx)
    }

    public (friend) fun swap<I, O> (
        registry: &mut PoolRegistry,
        _aggregator_registry: &AggregatorRegistry,
        in_coin: Coin<I>,
        ctx: &mut TxContext
    ): Coin<O> {
        let (in_name, out_name) = (type_name::get<I>(), type_name::get<O>());

        assert!(vec_set::contains(&registry.supported_lsts, &in_name), lsdfi_errors::LSDNotSupport());
        assert!(vec_set::contains(&registry.supported_lsts, &out_name), lsdfi_errors::LSDNotSupport());

        let in_amount = coin::value(&in_coin);
        let out_amount = get_swap_amount(in_amount);

        assert!(balance::value(bag::borrow<TypeName, Balance<O>>(&registry.balances, out_name)) >= out_amount, lsdfi_errors::NotEnoughBalance());
        let out_balance = balance::split(bag::borrow_mut<TypeName, Balance<O>>(&mut registry.balances, out_name), out_amount);

        if(!bag::contains(&registry.balances, in_name)) {
            bag::add(&mut registry.balances, in_name, balance::zero<I>());
        };

        balance::join(
            bag::borrow_mut<TypeName, Balance<I>>(&mut registry.balances, in_name),
            coin::into_balance(in_coin)
        );

        event::emit(BalanceChanged {
            sender: tx_context::sender(ctx),
            in_token: in_name,
            in_amount,
            out_token: out_name,
            out_amount
        });

        coin::from_balance(out_balance, ctx)
    }

    fun get_wispSUI_mint_amount (
        lst_amount: u64
    ): u64 {
        lst_amount * get_weigh()
    }

    fun get_wispSUI_burn_amount (
        wispSUI_amount: u64
    ): u64 {
        wispSUI_amount * get_weigh()
    }

    fun get_swap_amount(
        in_amount: u64,
    ): u64 {
        in_amount * get_weigh()
    }

    fun get_weigh (): u64 {
        1
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}