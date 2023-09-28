module wisp_lsdfi::pool {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self, Balance};
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::bag::{Self, Bag};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_set::{Self, VecSet};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use sui::sui::{SUI};

    use std::type_name::{Self, TypeName};
    use std::option::{Self, Option};
    use std::vector;

    use wisp_lsdfi::wispSUI::WISPSUI;
    use wisp_lsdfi::lsdfi_errors;
    use wisp_lsdfi::math;
    use wisp_lsdfi::utils;

    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};

    use wisp::pool::{Self, PoolRegistry};
    use wisp::comparator;

    friend wisp_lsdfi::lsdfi;

    struct AdminCap has key, store {
        id: UID,
    }

    struct AdapterCap has key, store {
        id: UID,
    }

    struct LSDFIPoolRegistry has key, store {
        id: UID,
        balances: Bag,
        supported_lsts: VecSet<TypeName>,
        available_balances: Table<TypeName, u64>,
        max_diff_weights: Table<TypeName, u64>,
        risk_coefficients: Table<TypeName, u64>,
        wispSUI_treasury: Option<TreasuryCap<WISPSUI>>,
        acceptable_result_time: u64,
        slope: u64, // times basis points
        base_fee: u64, // times basis points
        redemption_fee: u64, // times basis points
        sui_split_bps: u64, // times basis points
        fee_to: address,
        is_sui_smaller_than_wispSUI: bool,
        version: u64
    }

    // "Hot potato" object
    struct WithdrawReceipt {
        withdraw_amounts: Table<TypeName, u64>
    }

    // "Hot potato" object
    struct DepositSUIReceipt {
        sui: Coin<SUI>,
        stake_amounts: Table<TypeName, u64>,
        total_SUI_deposited: u64,
        lst_names: vector<TypeName>,
        lst_amounts: vector<u64>,
    }

    // Events
    struct LSTStatusUpdated has copy, drop {
        lst_name: TypeName,
        status: bool,
    }

    struct AcceptableResultTimeUpdated has copy, drop {
        time: u64,
    }

    struct RiskWeightUpdated has copy, drop {
        lst_name: TypeName,
        max_diff_weight: u64,
    }

    struct RiskCoefficientUpdated has copy, drop {
        lst_name: TypeName,
        risk_coefficient: u64,
    }

    struct SlopeUpdated has copy, drop {
        slope: u64,
    }

    struct FeeToUpdated has copy, drop {
        fee_to: address,
    }

    struct SUIDeposited has copy, drop {
        sender: address,
        sui_amount: u64,
        wispSUI_amount: u64,
        lst_names: vector<TypeName>,
        lst_amounts: vector<u64>,
    }

    struct Deposited has copy, drop {
        sender: address,
        in_token: TypeName,
        in_amount: u64,
        wispSUI_amount: u64,
    }

    struct Swapped has copy, drop {
        sender: address,
        in_token: TypeName,
        in_amount: u64,
        out_token: TypeName,
        out_amount: u64,
    }

    struct Withdrawal has copy, drop {
        sender: address,
        wispSUI_amount: u64,
        out_tokens: vector<TypeName>,
        out_amounts: vector<u64>,
    }

    struct AdapterCapCreated has copy, drop {
        id: ID
    }

    fun init (ctx: &mut TxContext){
        let sender = tx_context::sender(ctx);

        let admin_cap = AdminCap {
            id: object::new(ctx)
        };

        let res = comparator::compare(&type_name::get<SUI>(), &type_name::get<WISPSUI>());
        let is_sui_smaller_than_wispSUI = if (comparator::is_smaller_than(&res)) {
            true
        } else {
            false
        };

        let pool_registry = LSDFIPoolRegistry {
            id: object::new(ctx),
            balances: bag::new(ctx),
            supported_lsts: vec_set::empty(),
            available_balances: table::new(ctx),
            max_diff_weights: table::new(ctx),
            risk_coefficients: table::new(ctx),
            wispSUI_treasury: option::none(),
            acceptable_result_time: 300_000, // 5 minutes
            slope: 0,
            base_fee: 10, // 0.1%
            redemption_fee: 25, // 0.25%
            sui_split_bps: 500, // 5%
            fee_to: sender,
            is_sui_smaller_than_wispSUI,
            version: 1
        };

        transfer::transfer(admin_cap, sender);
        transfer::share_object(pool_registry);
    }

    public entry fun initialize (
        _: &AdminCap,
        registry: &mut LSDFIPoolRegistry,
        wispSUI_treasury: TreasuryCap<WISPSUI>,
        fee_to: address,
        slope: u64
    ) {
        option::fill(&mut registry.wispSUI_treasury, wispSUI_treasury);
        registry.fee_to = fee_to;
        registry.slope = slope;

        event::emit (SlopeUpdated {
            slope: slope
        });

        event::emit (FeeToUpdated {
            fee_to: fee_to
        });
    }

    public fun create_adapter_cap(
        _: &AdminCap,
        ctx: &mut TxContext
    ): AdapterCap {
        let id = object::new(ctx);

        event::emit(AdapterCapCreated {
            id: object::uid_to_inner(&id)
        });

        AdapterCap {
            id
        }
    }

    public entry fun set_support_lst<T> (
        admin_cap: &AdminCap,
        registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        status: bool,
        max_diff_weight: u64,
        risk_coefficient: u64
    ) {
        let name = type_name::get<T>();
        if (!status) {
            assert!(vec_set::contains(&registry.supported_lsts, &name), lsdfi_errors::StatusAlreadySet());
            vec_set::remove(&mut registry.supported_lsts, &name);
            table::remove(&mut registry.max_diff_weights, name);
            table::remove(&mut registry.risk_coefficients, name);
        } else {
            assert!(!vec_set::contains(&registry.supported_lsts, &name), lsdfi_errors::StatusAlreadySet());
            assert!(aggregator::supported_lst(aggregator, name), lsdfi_errors::AggregatorLSTNotSupport());
            vec_set::insert(&mut registry.supported_lsts, name);
            table::add(&mut registry.max_diff_weights, name, 0);
            table::add(&mut registry.risk_coefficients, name, 0);
            set_max_diff_weight<T>(admin_cap, registry, max_diff_weight);
            set_risk_coefficient<T>(admin_cap, registry, risk_coefficient);

            if(!bag::contains(&registry.balances, name)) {
                bag::add(&mut registry.balances, name, balance::zero<T>());
            };

            if(!table::contains(&registry.available_balances, name)) {
                table::add(&mut registry.available_balances, name, 0);
            };
        };

        event::emit (LSTStatusUpdated {
            lst_name: name,
            status: status
        });
    }

    public entry fun set_max_diff_weight<T>(
        _: &AdminCap,
        registry: &mut LSDFIPoolRegistry,
        max_diff_weight: u64
    ) {
        let name = type_name::get<T>();
        assert!(vec_set::contains(&registry.supported_lsts, &name), lsdfi_errors::LSTNotSupport());

        *table::borrow_mut(&mut registry.max_diff_weights, name) = max_diff_weight;

        event::emit (RiskWeightUpdated {
            lst_name: name,
            max_diff_weight
        });
    }

    public entry fun set_risk_coefficient<T>(
        _: &AdminCap,
        registry: &mut LSDFIPoolRegistry,
        risk_coefficient: u64
    ) {
        let name = type_name::get<T>();
        assert!(vec_set::contains(&registry.supported_lsts, &name), lsdfi_errors::LSTNotSupport());

        *table::borrow_mut(&mut registry.risk_coefficients, name) = risk_coefficient;

        event::emit(RiskCoefficientUpdated {
            lst_name: name,
            risk_coefficient: risk_coefficient
        });
    }

    public entry fun set_acceptable_result_time (
        _: &AdminCap,
        registry: &mut LSDFIPoolRegistry,
        time: u64
    ) {
        registry.acceptable_result_time = time;

        event::emit (AcceptableResultTimeUpdated {
            time: time
        });
    }

    public (friend) fun deposit<T> (
        registry: &mut LSDFIPoolRegistry,
        aggregator : &Aggregator,
        lst: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<WISPSUI> {
        let lst_name = type_name::get<T>();
        assert!(vec_set::contains(&registry.supported_lsts, &lst_name), lsdfi_errors::LSTNotSupport());
        let lst_amount = coin::value(&lst);
        let wispSUI_amount = get_deposit_amount(
            registry,
            aggregator,
            lst_name,
            lst_amount,
            clock,
        );
        
        put_coin_in(registry, lst);

        let wispSUI = mint_wispSUI(registry, wispSUI_amount, ctx);

        event::emit(Deposited {
            sender: tx_context::sender(ctx),
            in_token: lst_name,
            in_amount: lst_amount,
            wispSUI_amount: wispSUI_amount
        });

        wispSUI
    }

    // SUI deposit rate is 1:1
    public (friend) fun deposit_SUI (
        registry: &mut LSDFIPoolRegistry,
        exchange_pool_registry: &mut PoolRegistry,
        aggregator : &Aggregator,
        sui: Coin<SUI>, 
        clock: &Clock,
        ctx: &mut TxContext
    ): DepositSUIReceipt {
        let sui_amount = coin::value(&sui);
        let to_pool_amount = ((sui_amount as u128) * (registry.sui_split_bps as u128) / (utils::basis_points_u128() as u128) as u64);
        let to_pool_SUI = coin::split<SUI>(&mut sui, to_pool_amount, ctx);
        
        if (registry.is_sui_smaller_than_wispSUI) {
            let (lp, wisp_SUI) = pool::zap_in_first<SUI, WISPSUI>(exchange_pool_registry, &mut to_pool_SUI, to_pool_amount, ctx);
            transfer::public_transfer(lp, registry.fee_to);
            utils::transfer_coin<SUI>(to_pool_SUI, registry.fee_to);
            utils::transfer_coin<WISPSUI>(wisp_SUI, registry.fee_to);
        } else {
            let (lp, wisp_SUI) = pool::zap_in_second<WISPSUI, SUI>(exchange_pool_registry, &mut to_pool_SUI, to_pool_amount, ctx);
            transfer::public_transfer(lp, registry.fee_to);
            utils::transfer_coin<SUI>(to_pool_SUI, registry.fee_to);
            utils::transfer_coin<WISPSUI>(wisp_SUI, registry.fee_to);
        };

        let total_stake_amount = sui_amount - to_pool_amount;

        let target_weights = vector::empty<u256>();
        let total_target_weights = 0;

        let supported_lsts = vec_set::keys(&registry.supported_lsts);
        let index = 0;
        
        while (index < vector::length(supported_lsts)) {
            let lst_name = *vector::borrow(supported_lsts, index);
            let target_weight = get_single_weight_from_aggregator(
                registry,
                aggregator,
                lst_name,
                clock
            );
            vector::push_back(&mut target_weights, target_weight);
            total_target_weights = total_target_weights + target_weight;
            index = index + 1;
        };

        index = 0;
        
        let deposit_sui_receipt = DepositSUIReceipt {
            sui: sui,
            stake_amounts: table::new(ctx),
            total_SUI_deposited: sui_amount,
            lst_names: vector::empty<TypeName>(),
            lst_amounts: vector::empty<u64>(),
        };
        let sum = 0;

        while (index < vector::length(supported_lsts) - 1) {
            let lst_name = *vector::borrow(supported_lsts, index);
            let target_weight = *vector::borrow(&target_weights, index);
            let stake_amount = ((total_stake_amount as u128) * (target_weight as u128) / (total_target_weights as u128) as u64);
            table::add(&mut deposit_sui_receipt.stake_amounts, lst_name, stake_amount);
            sum = sum + stake_amount;
            index = index + 1;
        };
        // Add remaining sui to the last lst
        let lst_name = *vector::borrow(supported_lsts, index);
        let stake_amount = total_stake_amount - sum;
        table::add(&mut deposit_sui_receipt.stake_amounts, lst_name, stake_amount);

        deposit_sui_receipt
    }

    public fun take_out_SUI_deposit_SUI_receipt<T>(
        _: &AdapterCap,
        receipt: &mut DepositSUIReceipt,
        ctx: &mut TxContext
    ): Coin<SUI> {
        let lst_name = type_name::get<T>();
        assert!(table::contains(&receipt.stake_amounts, lst_name), lsdfi_errors::ReceiptTokenEmpty());
        let stake_amount = *table::borrow(&mut receipt.stake_amounts, lst_name);
        coin::split<SUI>(&mut receipt.sui, stake_amount, ctx)
    }

    public fun pay_back_deposit_SUI_receipt<T>(
        _: &AdapterCap,
        registry: &mut LSDFIPoolRegistry,
        receipt: &mut DepositSUIReceipt,
        lst: Coin<T>,
    ) {
        let lst_name = type_name::get<T>();
        assert!(table::contains(&receipt.stake_amounts, lst_name), lsdfi_errors::ReceiptTokenEmpty());
        table::remove(&mut receipt.stake_amounts, lst_name);
        vector::push_back(&mut receipt.lst_names, lst_name);
        vector::push_back(&mut receipt.lst_amounts, coin::value(&lst));
        put_coin_in(registry, lst);
    }

    public (friend) fun drop_deposit_SUI_receipt (
        registry: &mut LSDFIPoolRegistry,
        receipt: DepositSUIReceipt,
        ctx: &mut TxContext
    ): Coin<WISPSUI> {
        assert!(table::is_empty(&receipt.stake_amounts), lsdfi_errors::ReceiptNotEmpty());
        let DepositSUIReceipt{sui, stake_amounts, total_SUI_deposited, lst_names, lst_amounts} = receipt;
        coin::destroy_zero<SUI>(sui);
        table::drop(stake_amounts);
        
        event::emit(SUIDeposited {
            sender: tx_context::sender(ctx),
            sui_amount: total_SUI_deposited,
            wispSUI_amount: total_SUI_deposited,
            lst_names: lst_names,
            lst_amounts: lst_amounts
        });

        let wispSUI = mint_wispSUI(registry, total_SUI_deposited, ctx);
        wispSUI
    }

    public (friend) fun withdraw (
        registry: &mut LSDFIPoolRegistry,
        wispSUI: Coin<WISPSUI>,
        ctx: &mut TxContext
    ): WithdrawReceipt {
        let wispSUI_amount = coin::value(&wispSUI);
        let withdraw_amount = wispSUI_amount - ((wispSUI_amount as u128) * (registry.redemption_fee as u128) / (utils::basis_points_u128() as u128) as u64);
        let wispSUI_supply: u64 = coin::total_supply<WISPSUI>(option::borrow(&registry.wispSUI_treasury));

        let supported_lsts = vec_set::keys(&registry.supported_lsts);
        
        let index = 0;

        let receipt = WithdrawReceipt {
            withdraw_amounts: table::new(ctx)
        };

        let withdraw_tokens = vector::empty<TypeName>();
        let withdraw_amounts = vector::empty<u64>();
        while (index < vector::length(supported_lsts)) {
            let lst_name = *vector::borrow(supported_lsts, index);
            let lst_balance = *table::borrow(&registry.available_balances, lst_name);
            let withdraw_lst_amount = ((lst_balance as u128) * (withdraw_amount as u128) / (wispSUI_supply as u128) as u64);

            vector::push_back(&mut withdraw_tokens, lst_name);
            vector::push_back(&mut withdraw_amounts, withdraw_lst_amount);
            table::add(&mut receipt.withdraw_amounts, lst_name, withdraw_lst_amount);

            index = index + 1;
        };

        coin::burn(option::borrow_mut(&mut registry.wispSUI_treasury), wispSUI);

        event::emit(Withdrawal {
            sender: tx_context::sender(ctx),
            wispSUI_amount: wispSUI_amount,
            out_tokens: withdraw_tokens,
            out_amounts: withdraw_amounts
        });

        receipt
    }

    public (friend) fun consume_withdraw_receipt<T> (
        registry: &mut LSDFIPoolRegistry,
        receipt: &mut WithdrawReceipt,
        ctx: &mut TxContext
    ): Coin<T> {
        let lst_name = type_name::get<T>();

        assert!(table::contains(&receipt.withdraw_amounts, lst_name), lsdfi_errors::ReceiptTokenEmpty());
        
        let withdraw_amount = table::remove(&mut receipt.withdraw_amounts, lst_name);
        take_coin_out(registry, withdraw_amount, ctx)
    }

    public (friend) fun drop_withdraw_receipt (
        receipt: WithdrawReceipt,
    ) {
        assert!(table::is_empty(&receipt.withdraw_amounts), lsdfi_errors::ReceiptNotEmpty());
        let WithdrawReceipt{withdraw_amounts} = receipt;
        table::drop(withdraw_amounts);
    }

    public (friend) fun swap<I, O> (
        registry: &mut LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_coin: Coin<I>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<O> {
        let (in_name, out_name) = (type_name::get<I>(), type_name::get<O>());

        assert!(vec_set::contains(&registry.supported_lsts, &in_name), lsdfi_errors::LSTNotSupport());
        assert!(vec_set::contains(&registry.supported_lsts, &out_name), lsdfi_errors::LSTNotSupport());

        let in_amount = coin::value(&in_coin);
        let out_amount = get_swap_amount(
            registry,
            aggregator,
            in_name,
            out_name,
            in_amount,
            clock
        );

        assert!(balance::value(bag::borrow<TypeName, Balance<O>>(&registry.balances, out_name)) >= out_amount, lsdfi_errors::NotEnoughBalance());

        event::emit(Swapped {
            sender: tx_context::sender(ctx),
            in_token: in_name,
            in_amount,
            out_token: out_name,
            out_amount
        });

        put_coin_in(registry, in_coin);
        take_coin_out(registry, out_amount, ctx)
    }

    fun put_coin_in<T>(
        registry: &mut LSDFIPoolRegistry,
        coin: Coin<T>
    ) {
        let name = type_name::get<T>();
        let amount = coin::value(&coin);
        let current_balance = *table::borrow(&mut registry.available_balances, name);

        *table::borrow_mut(&mut registry.available_balances, name) = current_balance + amount;
        balance::join(
            bag::borrow_mut<TypeName, Balance<T>>(&mut registry.balances, name),
            coin::into_balance(coin)
        );
    }

    fun take_coin_out<T>(
        registry: &mut LSDFIPoolRegistry,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<T> {
        let name = type_name::get<T>();
        let current_balance = *table::borrow(&mut registry.available_balances, name);

        *table::borrow_mut(&mut registry.available_balances, name) = current_balance - amount;
        let balance = balance::split(bag::borrow_mut<TypeName, Balance<T>>(&mut registry.balances, name), amount);

        coin::from_balance(balance, ctx)
    }

    fun mint_wispSUI(
        registry: &mut LSDFIPoolRegistry,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<WISPSUI> {
        coin::mint<WISPSUI>(option::borrow_mut(&mut registry.wispSUI_treasury), amount, ctx)
    }

    fun get_deposit_amount (
        registry: &LSDFIPoolRegistry,
        aggregator: &Aggregator,
        lst_name: TypeName,
        lst_amount: u64,
        clock: &Clock
    ): u64 {
        let dynamic_fee = cal_dynamic_fee(
            registry,
            aggregator,
            lst_name,
            lst_amount,
            type_name::get<WISPSUI>(),
            0,
            clock
        );

        let fee = if (dynamic_fee > (registry.base_fee as u128)) {
            dynamic_fee - (registry.base_fee as u128)
        } else {
            0
        };

        let wispSUI_amount = (lst_amount as u128) * (utils::basis_points_u128() - fee) / utils::basis_points_u128();
        (wispSUI_amount as u64)
    }

    fun get_swap_amount(
        registry: &LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_lst_name: TypeName,
        out_lst_name: TypeName,
        in_amount: u64,
        clock: &Clock
    ): u64 {
        let dynamic_fee = cal_dynamic_fee(
            registry,
            aggregator,
            in_lst_name,
            in_amount,
            out_lst_name,
            in_amount,
            clock
        );

        let out_amount = (in_amount as u128) * (utils::basis_points_u128() - (dynamic_fee + (registry.base_fee as u128))) / utils::basis_points_u128();
        (out_amount as u64)
    }


    // All weight are normalized to utils::NORMALIZED_FACTOR
    public fun cal_dynamic_fee(
        registry: &LSDFIPoolRegistry,
        aggregator: &Aggregator,
        in_name: TypeName,
        in_amount: u64,
        out_name: TypeName,
        out_amount: u64,
        clock: &Clock
    ): u128 {
        let target_weights = vector::empty<u256>();
        let cur_weights = vector::empty<u256>();
        let pos_weights = vector::empty<u256>();

        let total_target_weights = 0;
        let total_cur_weights = 0;
        let total_pos_weights = 0;

        let supported_lsts = vec_set::keys(&registry.supported_lsts);
        let index = 0;

        while (index < vector::length(supported_lsts)) {
            let lst_name = *vector::borrow(supported_lsts, index);
            let target_weight = get_single_weight_from_aggregator(
                registry,
                aggregator,
                lst_name,
                clock
            );
            vector::push_back(&mut target_weights, target_weight);
            total_target_weights = total_target_weights + target_weight;
            
            let risk_coefficient = (*table::borrow(&registry.risk_coefficients, lst_name) as u256);

            let cur_weight = (*table::borrow(&registry.available_balances, lst_name) as u256) * risk_coefficient;
            vector::push_back(&mut cur_weights, cur_weight);
            total_cur_weights = total_cur_weights + cur_weight;

            let pos_weight: u256;
            if (lst_name == in_name) {
                pos_weight = (*table::borrow(&registry.available_balances, lst_name) + in_amount as u256) * risk_coefficient;
            } else if (lst_name == out_name) {
                pos_weight = (*table::borrow(&registry.available_balances, lst_name) - out_amount as u256) * risk_coefficient;
            } else {
                pos_weight = (*table::borrow(&registry.available_balances, lst_name) as u256) * risk_coefficient;
            };
            vector::push_back(&mut pos_weights, pos_weight);
            total_pos_weights = total_pos_weights + pos_weight;

            index = index + 1;
        };

        let normalized_target_weights = math::normalize_weight(&target_weights, total_target_weights);
        let normalized_cur_weights = math::normalize_weight(&cur_weights, total_cur_weights);
        let normalized_pos_weights = math::normalize_weight(&pos_weights, total_pos_weights);

        let cur_diff = math::cal_diff(&normalized_target_weights, &normalized_cur_weights);
        let pos_diff = math::cal_diff(&normalized_target_weights, &normalized_pos_weights);

        cal_dynamic_fee_from_diffs(registry, cur_diff, pos_diff)
    }

    // Calculate dynamic_fee in basis points
    fun cal_dynamic_fee_from_diffs(
        registry: &LSDFIPoolRegistry,
        cur_diff: u256,
        pos_diff: u256
    ): u128 {
        let slope = (registry.slope as u256);
        let dynamic_fee = 0;

        if (pos_diff > cur_diff) {
            let change = pos_diff - cur_diff;
            dynamic_fee = (
                change * slope + 
                math::square_u256(change * slope) / utils::normalize_factor_u256() / utils::slope_decimals_u256() / 2
            ) * utils::basis_points_u256() / utils::normalize_factor_u256() / utils::slope_decimals_u256();
        };

        (dynamic_fee as u128)
    }

    fun get_single_weight_from_aggregator(
        registry: &LSDFIPoolRegistry,
        aggregator: &Aggregator,
        name: TypeName,
        clock: &Clock
    ): u256 {
        let result = aggregator::get_result(aggregator, name);
        assert!(option::is_some(result), lsdfi_errors::AggregatorResultNotSet());
        
        let (value, timestamp) = aggregator::get_result_value(option::borrow(result));
        assert!(clock::timestamp_ms(clock) - timestamp < registry.acceptable_result_time, lsdfi_errors::AggregatorResultTooOld());

        (value as u256) * (*table::borrow(&registry.risk_coefficients, name) as u256)
    }

    // VIEW FUNCTIONS
    public fun supported_lsts(registry: &LSDFIPoolRegistry): &VecSet<TypeName> {
        &registry.supported_lsts
    }

    public fun available_balances(registry: &LSDFIPoolRegistry): &Table<TypeName, u64> {
        &registry.available_balances
    }

    public fun max_diff_weights(registry: &LSDFIPoolRegistry): &Table<TypeName, u64> {
        &registry.max_diff_weights
    }

    public fun risk_coefficients(registry: &LSDFIPoolRegistry): &Table<TypeName, u64> {
        &registry.risk_coefficients
    }

    public fun wispSUI_treasury(registry: &LSDFIPoolRegistry): &Option<TreasuryCap<WISPSUI>> {
        &registry.wispSUI_treasury
    }

    public fun acceptable_result_time(registry: &LSDFIPoolRegistry): u64 {
        registry.acceptable_result_time
    }

    public fun slope(registry: &LSDFIPoolRegistry): u64 {
        registry.slope
    }

    public fun base_fee(registry: &LSDFIPoolRegistry): u64 {
        registry.base_fee
    }

    public fun redemption_fee(registry: &LSDFIPoolRegistry): u64 {
        registry.redemption_fee
    }

    public fun sui_split_bps(registry: &LSDFIPoolRegistry): u64 {
        registry.sui_split_bps
    }

    public fun fee_to(registry: &LSDFIPoolRegistry): address {
        registry.fee_to
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}