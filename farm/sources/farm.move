module wisp_farm::farm {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::clock::{Clock};
    use sui::event;
    use sui::object::{Self, UID, ID};
    use sui::object_table::{Self, ObjectTable};
    use sui::table_vec::{Self, TableVec};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use sui::pay;
    use sui::transfer;

    use std::vector;
    use std::option::{Self, Option};
    use std::type_name;

    use wisp_farm::stake_pool::{Self, StakePool};
    use wisp_farm::spnft::{Self, SpNFT};
    use wisp_farm::utils;

    use wisp_token::vecoin::{Self, ModifyCap, VeCoin};
    use wisp_token::vewisp::{VEWISP};

    use wisp_vault::vault::{Self, Vault};

    const EInitialized: u64 = 0;
    const ENotInitialized: u64 = 1;
    const ETypeEqual: u64 = 2;
    const EPoolCreated: u64 = 3;
    const EPoolNotCreated: u64 = 4;
    const EInsufficientBalance: u64 = 5;
    const EZeroAmount: u64 = 6;
    const ENothingToClaim: u64 = 7;
    const EInvalidPoolType: u64 = 8;
    const EInvalidStartTime: u64 = 9;
    const EFarmStarted: u64 = 10;
    const ENotTgeTime: u64 = 11;
    const EInvalidInputLength: u64 = 12;
    const EInvalidRate: u64 = 13;
    const EInvalidLockTime: u64 = 14;

    struct ControllerCap has key, store {
        id: UID,
    }

    struct StakePoolRegistry has key, store {
        id: UID,
        stake_pools: ObjectTable<ID, StakePool>,
        pool_ids: TableVec<ID>,
        active_pool_ids: vector<ID>,
        wisp_per_sec: u64,
        total_alloc_point: u64,
        start_timestamp: u64,
        vecoin_modify_cap: Option<ModifyCap<VEWISP>>,
        wisp: Option<Vault>,
        lock_period_rate: Option<Table<u64, u64>>, // lock period (in s) -> boost rate * 10e4
    }

    // Events
    struct RewardClaimed has copy, drop {
        sp_nft_id: ID,
        wisp_amount: u64,
        vewisp_amount: u64,
    }

    struct EmissionRateChanged has copy, drop {
        old_value: u64,
        new_value: u64,
    }

    struct VaultRetaken has copy, drop {
        caller: address
    }

    struct LockPeriodRateChanged has copy, drop {
        new_periods: vector<u64>,
        new_rates: vector<u64>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            ControllerCap {
                id: object::new(ctx),
            }, 
            tx_context::sender(ctx)
        );

        transfer::share_object(
            StakePoolRegistry {
                id: object::new(ctx),
                stake_pools: object_table::new(ctx),
                pool_ids: table_vec::empty(ctx),
                active_pool_ids: vector::empty(),
                wisp_per_sec: 0,
                total_alloc_point: 0,
                start_timestamp: 0,
                vecoin_modify_cap: option::none(),
                wisp: option::none(),
                lock_period_rate: option::none(),
            }
        );
    }

    public entry fun initialize(
        _: &ControllerCap,
        stake_pool_registry: &mut StakePoolRegistry,
        vecoin_modify_cap: ModifyCap<VEWISP>,
        wisp: Vault,
        wisp_per_sec: u64,
        start_timestamp: u64,
        lock_period: vector<u64>,
        lock_boost_rate: vector<u64>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(option::is_none(&stake_pool_registry.vecoin_modify_cap) && option::is_none(&stake_pool_registry.wisp), EInitialized);
        assert!(utils::timestamp_sec(clock) <= start_timestamp, EInvalidStartTime);
        assert!(start_timestamp >= utils::ms_to_sec(vault::tge_time()), ENotTgeTime);
        assert!(vector::length(&lock_period) == vector::length(&lock_boost_rate), EInvalidInputLength);

        option::fill(&mut stake_pool_registry.vecoin_modify_cap, vecoin_modify_cap);
        option::fill(&mut stake_pool_registry.wisp, wisp);
        stake_pool_registry.wisp_per_sec = wisp_per_sec;
        stake_pool_registry.start_timestamp = start_timestamp;
        
        let lock_period_rate = table::new(ctx);
        while(vector::length(&lock_period) > 0) {
            let period = vector::pop_back(&mut lock_period);
            let rate = vector::pop_back(&mut lock_boost_rate);
            assert!(period > 0 && rate > 0, EInvalidRate);
            table::add(&mut lock_period_rate, period, rate);
        };
        option::fill(&mut stake_pool_registry.lock_period_rate, lock_period_rate);
    }

    public entry fun start_farming(
        _: &ControllerCap,
        stake_pool_registry: &mut StakePoolRegistry,
        clock: &Clock,
    ) {
        check_initialized(stake_pool_registry);
        let start_timestamp = utils::timestamp_sec(clock);
        assert!(start_timestamp >= utils::ms_to_sec(vault::tge_time()), ENotTgeTime);
        assert!(start_timestamp < stake_pool_registry.start_timestamp, EFarmStarted);

        let index = 0;
        let pool_ids_length = table_vec::length(&stake_pool_registry.pool_ids);
        while(index < pool_ids_length) {
            let pool_id = *table_vec::borrow(&stake_pool_registry.pool_ids, index);
            let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, pool_id);
            stake_pool::set_pool_last_claim_timestamp(stake_pool, start_timestamp);
            index = index + 1;
        };

        stake_pool_registry.start_timestamp = start_timestamp;
    }

    public entry fun create_stake_pool<T>(
        _: &ControllerCap,
        stake_pool_registry: &mut StakePoolRegistry,   
        alloc_point: u64,
        boost_rate: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_initialized(stake_pool_registry);

        mass_update_pools_(stake_pool_registry, clock);
        create_stake_pool_<T>(
            stake_pool_registry,
            alloc_point,
            boost_rate,
            clock,
            ctx
        )
    }

    public entry fun set_pool_alloc_point(
        _: &ControllerCap,
        stake_pool_registry: &mut StakePoolRegistry,
        stake_pool_address: address,   
        alloc_point: u64,
        clock: &Clock,
    ) {
        check_initialized(stake_pool_registry);

        mass_update_pools_(stake_pool_registry, clock);
        
        let stake_pool_id = object::id_from_address(stake_pool_address);
        set_pool_alloc_point_(
                stake_pool_registry,
                stake_pool_id,
                alloc_point,
            )
    }

    public entry fun set_emission_rate(
        _: &ControllerCap,
        stake_pool_registry: &mut StakePoolRegistry,
        wisp_per_sec: u64,
        clock: &Clock,
    ) {
        check_initialized(stake_pool_registry);

        mass_update_pools_(stake_pool_registry, clock);

        event::emit(EmissionRateChanged {
            old_value: stake_pool_registry.wisp_per_sec,
            new_value: wisp_per_sec,
        });

        stake_pool_registry.wisp_per_sec = wisp_per_sec;
    }

    public entry fun retake_vault(
        _: &ControllerCap,
        stake_pool_registry: &mut StakePoolRegistry,
        ctx: &mut TxContext,
    ) {
        check_initialized(stake_pool_registry);

        let wisp = option::extract(&mut stake_pool_registry.wisp);

        transfer::public_transfer(wisp, tx_context::sender(ctx));
        event::emit(VaultRetaken {
            caller: tx_context::sender(ctx),
        });
    }

    public entry fun set_lock_period_rate(
        _: &ControllerCap,
        stake_pool_registry: &mut StakePoolRegistry,
        lock_period: vector<u64>,
        lock_boost_rate: vector<u64>,
        ctx: &mut TxContext,
    ) {
        check_initialized(stake_pool_registry);
        assert!(vector::length(&lock_period) == vector::length(&lock_boost_rate), EInvalidInputLength);
        table::drop(option::extract(&mut stake_pool_registry.lock_period_rate));

        event::emit(LockPeriodRateChanged{
            new_periods: lock_period,
            new_rates: lock_boost_rate,
        });

        let lock_period_rate = table::new(ctx);
        while(vector::length(&lock_period) > 0) {
            let period = vector::pop_back(&mut lock_period);
            let rate = vector::pop_back(&mut lock_boost_rate);
            assert!(period > 0 && rate > 0, EInvalidRate);
            table::add(&mut lock_period_rate, period, rate);
        };
        option::fill(&mut stake_pool_registry.lock_period_rate, lock_period_rate);
    }

    public entry fun create_sp_nft<T>(
        stake_pool_registry: &mut StakePoolRegistry,
        lp_tokens: vector<Coin<T>>,
        stake_pool_address: address,
        stake_amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_initialized(stake_pool_registry);
        
        // check if stake pool exist
        let pool_id = object::id_from_address(stake_pool_address);
        check_pool_created_with_type<T>(stake_pool_registry, pool_id);
        
        let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, pool_id);

        // update stake pool reward
        stake_pool::update_stake_pool(
            stake_pool,
            stake_pool_registry.wisp_per_sec,
            stake_pool_registry.total_alloc_point,
            clock,
        );
        // create sp nft
        let sp_nft = spnft::create_sp_nft<T>(
            pool_id,
            ctx
        );

        let lp_token = coin::zero<T>(ctx);
        pay::join_vec(&mut lp_token, lp_tokens);

        // stake lp token into sp nft
        let(_, point_change, boost_change, positive) = spnft::stake<T>(
            &mut sp_nft,
            &mut lp_token,
            stake_amount,
            stake_pool::acc_wisp_per_share(stake_pool),
            stake_pool::boost_rate(stake_pool),
            0,
            0,
            clock,
            ctx
        );

        stake_pool::change_stake_point(
            stake_pool,
            point_change,
            boost_change,
            positive
        );

        transfer::public_transfer(sp_nft, tx_context::sender(ctx));
        execute_return_token(lp_token, ctx);
    }

    public entry fun stake<T>(
        stake_pool_registry: &mut StakePoolRegistry,
        sp_nft: &mut SpNFT<T>,
        lp_tokens: vector<Coin<T>>,
        stake_amount: u64,
        lock_period: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_initialized(stake_pool_registry);

        let stake_pool_id = spnft::stake_pool_id(sp_nft);
        let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, stake_pool_id);

        // update stake pool reward
        stake_pool::update_stake_pool(
            stake_pool,
            stake_pool_registry.wisp_per_sec,
            stake_pool_registry.total_alloc_point,
            clock,
        );

        let lp_token = coin::zero<T>(ctx);
        pay::join_vec(&mut lp_token, lp_tokens);
        let lock_rate = get_lock_rate(option::borrow(&stake_pool_registry.lock_period_rate), lock_period);

        // stake lp token into sp nft
        let (reward_amount, point_change, boost_change, positive) = spnft::stake<T>(
            sp_nft,
            &mut lp_token,
            stake_amount,
            stake_pool::acc_wisp_per_share(stake_pool),
            stake_pool::boost_rate(stake_pool),
            lock_period,
            lock_rate,
            clock,
            ctx
        );

        stake_pool::change_stake_point(
            stake_pool,
            point_change,
            boost_change,
            positive
        );

        if (reward_amount > 0) {
            claim_reward_(
                stake_pool_registry,
                object::id(sp_nft),
                reward_amount,
                clock,
                ctx
            );
        };

        execute_return_token(lp_token, ctx);
    }

    public entry fun unstake<T>(
        stake_pool_registry: &mut StakePoolRegistry,
        sp_nft: SpNFT<T>,
        unstake_amount: u64,
        lock_period: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_initialized(stake_pool_registry);

        let stake_pool_id = spnft::stake_pool_id(&sp_nft);
        let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, stake_pool_id);

        // update stake pool reward
        stake_pool::update_stake_pool(
            stake_pool,
            stake_pool_registry.wisp_per_sec,
            stake_pool_registry.total_alloc_point,
            clock,
        );

        let lock_rate = get_lock_rate(option::borrow(&stake_pool_registry.lock_period_rate), lock_period);

        let (unstake_coin, reward_amount, point_change, boost_change, positive) = spnft::unstake<T>(
            &mut sp_nft,
            unstake_amount,
            stake_pool::acc_wisp_per_share(stake_pool),
            stake_pool::boost_rate(stake_pool),
            lock_period,
            lock_rate,
            clock,
            ctx
        );

        stake_pool::change_stake_point(
            stake_pool,
            point_change,
            boost_change,
            positive
        );

        let sp_nft_id = object::id(&sp_nft);

        if (spnft::lp_balance(&sp_nft) == 0) {
            let boost_amount = spnft::boost_balance(&sp_nft);
            if (boost_amount > 0) {
                let (boost_balance, _, point_change, boost_change, positive) = spnft::unboost<T>(
                    &mut sp_nft,
                    boost_amount,
                    stake_pool::acc_wisp_per_share(stake_pool),
                    stake_pool::boost_rate(stake_pool),
                    0,
                    0,
                    clock,
                    ctx
                );

                stake_pool::change_stake_point(
                    stake_pool,
                    point_change,
                    boost_change,
                    positive
                );

                to_vecoin_and_transfer(stake_pool_registry, boost_balance, ctx);
            };

            spnft::destroy_zero<T>(sp_nft);
        } else {
            transfer::public_transfer(sp_nft, tx_context::sender(ctx));
        };

        if (reward_amount > 0) {
            claim_reward_(
                stake_pool_registry,
                sp_nft_id,
                reward_amount,
                clock,
                ctx
            );
        };

        execute_return_token(unstake_coin, ctx);
    }

    public entry fun boost<T>(
        stake_pool_registry: &mut StakePoolRegistry,
        sp_nft: &mut SpNFT<T>,
        boost_tokens: vector<VeCoin<VEWISP>>,
        boost_amount: u64,
        lock_period: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_initialized(stake_pool_registry);

        let stake_pool_id = spnft::stake_pool_id(sp_nft);
        let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, stake_pool_id);

        // update stake pool reward
        stake_pool::update_stake_pool(
            stake_pool,
            stake_pool_registry.wisp_per_sec,
            stake_pool_registry.total_alloc_point,
            clock,
        );

        let boost_token = vecoin::zero<VEWISP>(ctx);
        join_vec_vewisp(option::borrow(&stake_pool_registry.vecoin_modify_cap), &mut boost_token, boost_tokens);

        assert!(vecoin::value(&boost_token) > 0, EZeroAmount);
        assert!(vecoin::value(&boost_token) >= boost_amount, EInsufficientBalance);

        let vecoin_modify_cap = option::borrow(&stake_pool_registry.vecoin_modify_cap);
        let boost_balance = balance::split(vecoin::balance_mut(vecoin_modify_cap, &mut boost_token), boost_amount);
        let lock_rate = get_lock_rate(option::borrow(&stake_pool_registry.lock_period_rate), lock_period);
        // stake lp token into sp nft
        let (reward_amount, point_change, boost_change, positive) = spnft::boost<T>(
            sp_nft,
            boost_balance,
            stake_pool::acc_wisp_per_share(stake_pool),
            stake_pool::boost_rate(stake_pool),
            lock_period,
            lock_rate,
            clock,
            ctx
        );

        stake_pool::change_stake_point(
            stake_pool,
            point_change,
            boost_change,
            positive
        );

        if (reward_amount > 0) {
            claim_reward_(
                stake_pool_registry,
                object::id(sp_nft),
                reward_amount,
                clock,
                ctx
            );
        };

        execute_vewisp(stake_pool_registry, boost_token, ctx);
    }

    public entry fun unboost<T>(
        stake_pool_registry: &mut StakePoolRegistry,
        sp_nft: &mut SpNFT<T>,
        unboost_amount: u64,
        lock_period: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_initialized(stake_pool_registry);

        let stake_pool_id = spnft::stake_pool_id(sp_nft);
        let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, stake_pool_id);

        // update stake pool reward
        stake_pool::update_stake_pool(
            stake_pool,
            stake_pool_registry.wisp_per_sec,
            stake_pool_registry.total_alloc_point,
            clock,
        );

        let lock_rate = get_lock_rate(option::borrow(&stake_pool_registry.lock_period_rate), lock_period);
        let (unboost_balance, reward_amount, point_change, boost_change, positive) = spnft::unboost<T>(
            sp_nft,
            unboost_amount,
            stake_pool::acc_wisp_per_share(stake_pool),
            stake_pool::boost_rate(stake_pool),
            lock_period,
            lock_rate,
            clock,
            ctx
        );

        stake_pool::change_stake_point(
            stake_pool,
            point_change,
            boost_change,
            positive
        );

        if (reward_amount > 0) {
            claim_reward_(
                stake_pool_registry,
                object::id(sp_nft),
                reward_amount,
                clock,
                ctx
            );
        };

        to_vecoin_and_transfer(stake_pool_registry, unboost_balance, ctx);
    }

    public entry fun claim_reward<T>(
        stake_pool_registry: &mut StakePoolRegistry,
        sp_nft: &mut SpNFT<T>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_initialized(stake_pool_registry);

        let stake_pool_id = spnft::stake_pool_id(sp_nft);
        let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, stake_pool_id);

        // update stake pool reward
        stake_pool::update_stake_pool(
            stake_pool,
            stake_pool_registry.wisp_per_sec,
            stake_pool_registry.total_alloc_point,
            clock,
        );

        let reward_amount = spnft::claim_reward<T>(
            sp_nft,
            stake_pool::acc_wisp_per_share(stake_pool),
            clock,
        );

        assert!(reward_amount > 0, ENothingToClaim); 
        claim_reward_(
            stake_pool_registry,
            object::id(sp_nft),
            reward_amount,
            clock,
            ctx
        );
    }

    public fun mass_update_pools(
        stake_pool_registry: &mut StakePoolRegistry,
        clock: &Clock,
    ) {
        check_initialized(stake_pool_registry);
        mass_update_pools_(stake_pool_registry, clock);
    }

    public fun update_pool(
        stake_pool_registry: &mut StakePoolRegistry,
        stake_pool_address: address,
        clock: &Clock,
    ) {
        check_initialized(stake_pool_registry);
        
        // check if stake pool exist
        let pool_id = object::id_from_address(stake_pool_address);
        check_pool_created(stake_pool_registry, pool_id);
        
        let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, pool_id);

        // update stake pool reward
        stake_pool::update_stake_pool(
            stake_pool,
            stake_pool_registry.wisp_per_sec,
            stake_pool_registry.total_alloc_point,
            clock,
        );
    }

    fun mass_update_pools_(
        stake_pool_registry: &mut StakePoolRegistry,
        clock: &Clock,
    ) {
        let index = 0;
        let active_pool_ids_length = vector::length(&stake_pool_registry.active_pool_ids);
        while(index < active_pool_ids_length) {
            let pool_id = *vector::borrow(&stake_pool_registry.active_pool_ids, index);
            let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, pool_id);
            
            // update stake pool reward
            stake_pool::update_stake_pool(
                stake_pool,
                stake_pool_registry.wisp_per_sec,
                stake_pool_registry.total_alloc_point,
                clock,
            );

            index = index + 1;
        }
    }

    fun create_stake_pool_<T>(
        stake_pool_registry: &mut StakePoolRegistry,
        alloc_point: u64,
        boost_rate: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        create_stake_pool_checked<T>(
            stake_pool_registry,
            alloc_point,
            boost_rate,
            clock,
            ctx
        )
    }

    fun create_stake_pool_checked<T>(
        stake_pool_registry: &mut StakePoolRegistry,
        alloc_point: u64,
        boost_rate: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let start_timestamp = if(utils::timestamp_sec(clock) > stake_pool_registry.start_timestamp) {
            utils::timestamp_sec(clock)
        } else {
            stake_pool_registry.start_timestamp
        };
        let stake_pool = stake_pool::create_stake_pool<T>(
            alloc_point,
            start_timestamp,
            boost_rate,
            ctx
        );
        let stake_pool_id = object::id(&stake_pool);
        
        table_vec::push_back(&mut stake_pool_registry.pool_ids, stake_pool_id);
        object_table::add(&mut stake_pool_registry.stake_pools, stake_pool_id, stake_pool);

        if(alloc_point > 0) {
            vector::push_back(&mut stake_pool_registry.active_pool_ids, stake_pool_id);
            stake_pool_registry.total_alloc_point = stake_pool_registry.total_alloc_point + alloc_point;
        }
    }

    fun set_pool_alloc_point_(
        stake_pool_registry: &mut StakePoolRegistry,
        stake_pool_id: ID,
        alloc_point: u64,
    ) {
        check_pool_created(stake_pool_registry, stake_pool_id);

        let stake_pool = object_table::borrow_mut(&mut stake_pool_registry.stake_pools, stake_pool_id);
        stake_pool_registry.total_alloc_point = stake_pool_registry.total_alloc_point + alloc_point - stake_pool::pool_alloc_point(stake_pool);

        if(stake_pool::pool_alloc_point(stake_pool) == 0 && alloc_point > 0) {
            vector::push_back(&mut stake_pool_registry.active_pool_ids, stake_pool_id);
        } else if(stake_pool::pool_alloc_point(stake_pool) > 0 && alloc_point == 0) {
            let (_, index) = vector::index_of(&stake_pool_registry.active_pool_ids, &stake_pool_id);
            vector::remove(&mut stake_pool_registry.active_pool_ids, index);
        };

        stake_pool::set_pool_info(
            stake_pool,
            alloc_point,
        )
    }

    fun claim_reward_(
        stake_pool_registry: &mut StakePoolRegistry,
        sp_nft_id: ID,
        reward_amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let liquidity_incentive_vault = option::borrow_mut(&mut stake_pool_registry.wisp);
        let (wisp_reward, vewisp_reward) = vault::redeem_vault_wisp_and_vewisp(
            liquidity_incentive_vault,
            reward_amount,
            clock
        );

        event::emit(RewardClaimed {
            sp_nft_id,
            wisp_amount: balance::value(&wisp_reward),
            vewisp_amount: balance::value(&vewisp_reward)
        });

        transfer::public_transfer(coin::from_balance(wisp_reward, ctx), tx_context::sender(ctx));

        if (balance::value(&vewisp_reward) > 0){
            to_vecoin_and_transfer(stake_pool_registry, vewisp_reward, ctx);
        } else {
            balance::destroy_zero(vewisp_reward);
        }
    }

    fun get_lock_rate(
        lock_period_rate: &Table<u64, u64>,
        lock_time: u64
    ): u64 {
        let lock_rate = 0;
        if (lock_time != 0){
            assert!(table::contains(lock_period_rate, lock_time), EInvalidLockTime);
            lock_rate = *table::borrow(lock_period_rate, lock_time);
        };

        lock_rate
    }

    fun to_vecoin_and_transfer(
        stake_pool_registry: &StakePoolRegistry,
        vebalance: Balance<VEWISP>,
        ctx: &mut TxContext,
    ) {
        let vecoin_modify_cap = option::borrow(&stake_pool_registry.vecoin_modify_cap);
        let vewisp_coin = vecoin::from_balance(vecoin_modify_cap, vebalance, ctx);
        vecoin::transfer(vecoin_modify_cap, vewisp_coin, tx_context::sender(ctx));
    } 

    fun execute_vewisp(
        stake_pool_registry: &StakePoolRegistry,
        vewisp: VeCoin<VEWISP>,
        ctx: &mut TxContext,
    ) {
        if(vecoin::value(&vewisp) > 0) {
            let vecoin_modify_cap = option::borrow(&stake_pool_registry.vecoin_modify_cap);
            vecoin::transfer(vecoin_modify_cap, vewisp, tx_context::sender(ctx));
        } else {
            vecoin::destroy_zero(vewisp);
        }
    }

    fun join_vec_vewisp(
        modify_cap: &ModifyCap<VEWISP>,
        self: &mut VeCoin<VEWISP>,
        vewisps: vector<VeCoin<VEWISP>>,
    ) {
        let (i, len) = (0, vector::length(&vewisps));
        while (i < len) {
            let coin = vector::pop_back(&mut vewisps);
            vecoin::join(modify_cap, self, coin);
            i = i + 1
        };
        // safe because we've drained the vector
        vector::destroy_empty(vewisps)
    }
    
    fun check_pool_created(
        stake_pool_registry: &StakePoolRegistry,
        stake_pool_id: ID,
    ) {
        assert!(object_table::contains(&stake_pool_registry.stake_pools, stake_pool_id), EPoolNotCreated);
    }

    fun check_pool_created_with_type<T>(
        stake_pool_registry: &StakePoolRegistry,
        stake_pool_id: ID,
    ) {
        assert!(object_table::contains(&stake_pool_registry.stake_pools, stake_pool_id), EPoolNotCreated);
        let stake_pool = object_table::borrow(&stake_pool_registry.stake_pools, stake_pool_id);
        assert!(type_name::get<T>() == stake_pool::stake_token_type(stake_pool), EInvalidPoolType);
    }

    fun check_initialized(
        stake_pool_registry: &StakePoolRegistry
    ) {
        assert!(option::is_some(&stake_pool_registry.vecoin_modify_cap) && option::is_some(&stake_pool_registry.wisp), ENotInitialized)
    }

    public fun execute_return_token<T>(token: Coin<T>, ctx: &mut TxContext) {
        if(coin::value(&token) > 0) {
            transfer::public_transfer(token, tx_context::sender(ctx));
        } else {
            coin::destroy_zero(token);
        };
    }

    public fun get_registry_data(
        stake_pool_registry: &StakePoolRegistry,
    ): (&TableVec<ID>, vector<ID>, u64, u64, u64) {
        (
            &stake_pool_registry.pool_ids,
            stake_pool_registry.active_pool_ids,
            stake_pool_registry.wisp_per_sec,
            stake_pool_registry.total_alloc_point,
            stake_pool_registry.start_timestamp,
        )
    }

    public fun get_stake_pool_data<T>(
        stake_pool_registry: &StakePoolRegistry,
        stake_pool_id: ID,
    ): (u64, u128, u64, u128, u64) {
        check_pool_created_with_type<T>(stake_pool_registry, stake_pool_id);
        let stake_pool = object_table::borrow(&stake_pool_registry.stake_pools, stake_pool_id);
        let(
            pool_alloc_point,
            total_stake_point,
            total_boost_balance,
            acc_wisp_per_share,
            last_claim_timestamp,
        ) = stake_pool::get_stake_pool_data(stake_pool);
        
        (
            pool_alloc_point,
            total_stake_point,
            total_boost_balance,
            acc_wisp_per_share,
            last_claim_timestamp,
        ) 
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext){
        init(ctx);
    }
}