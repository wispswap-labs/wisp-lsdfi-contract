#[test_only]
#[allow(unused_function)]
module wisp_farm::farm_test {
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use sui::clock::{Self, Clock};
    use sui::table_vec;
    use sui::coin::{Coin, mint_for_testing as mint, burn_for_testing as burn};
    use sui::object;
    use sui::test_utils::{assert_eq};

    use std::vector;
    // use std::debug;

    use wisp_farm::farm::{Self, StakePoolRegistry, ControllerCap};
    use wisp_farm::spnft::{Self, SpNFT};
    use wisp_farm::utils;
    use wisp_token::vecoin::{Self, mint_for_testing as mint_vecoin};   
    use wisp_token::wisp::{WISP};
    use wisp_token::vewisp::{VEWISP};
    use wisp_vault::wisp_vault;

    use wisp::pool::WISPLP;

    const START_TIME: u64 = 1_688_058_001_000; //(TGE TIME + 1000ms)
    const START_TIME_SEC: u64 = 1_688_058_001;
    const WISP_PER_MS: u64 = 1000;

    const BASIS_POINTS: u64 = 10000;
    const BOOST_RATE: u64 = 1_000_000_000;

    const POOL_1_2_ALLOC_POINT: u64 = 1000;
    const POOL_1_3_ALLOC_POINT: u64 = 2000;
    const POOL_2_3_ALLOC_POINT: u64 = 3000;
    const POOL_1_4_ALLOC_POINT: u64 = 4000;

    const ONE_MONTH: u64 = 2_592_000;
    const TWO_MONTH: u64 = 5_184_000;

    struct COIN_1 has drop {}
    struct COIN_2 has drop {}
    struct COIN_3 has drop {}
    struct COIN_4 has drop {}
    
    #[test]
    fun test_init_package(){
        let test = scenario();
        test_init_package_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_initialize(){
        let test = scenario();
        test_initialize_(&mut test);
        test::end(test);
    }

    #[test]
    #[expected_failure(abort_code = farm::ENotInitialized)]
    fun test_create_pool_before_initialize(){
        let test = scenario();
        test_create_pool_before_initialize_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_create_pool(){
        let test = scenario();
        test_create_pool_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_create_more_pools(){
        let test = scenario();
        test_create_more_pools_(&mut test);
        test::end(test);
    }

    #[test]
    #[expected_failure(abort_code = farm::ENotInitialized)]
    fun test_start_farming_before_initialize(){
        let test = scenario();
        test_start_farming_before_initialize_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_start_farm_before_initial_start_time(){
        let test = scenario();
        test_start_farm_before_initial_start_time_(&mut test);
        test::end(test);
    }

    #[test]
    #[expected_failure(abort_code = farm::ENotInitialized)]
    fun test_start_farming_after_initial_start_time(){
        let test = scenario();
        test_start_farming_after_initial_start_time_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_create_pool_after_start(){
        let test = scenario();
        test_create_pool_after_start_(&mut test);
        test::end(test);
    }

    #[test]
    #[expected_failure(abort_code = farm::EInvalidPoolType)]
    fun create_sp_nft_invalid_pool_type(){
        let test = scenario();
        create_sp_nft_invalid_pool_type_(&mut test);
        test::end(test);
    }

    #[test]
    fun create_sp_nft(){
        let test = scenario();
        create_sp_nft_(&mut test);
        test::end(test);
    }

    #[test]
    fun claim_reward(){
        let test = scenario();
        claim_reward_(&mut test);
        test::end(test);
    }

    #[test]
    fun create_sp_nft_other_user(){
        let test = scenario();
        create_sp_nft_other_user_(&mut test);
        test::end(test);
    }

    #[test]
    fun unstake(){
        let test = scenario();
        unstake_(&mut test);
        test::end(test);
    }

    #[test]
    fun boost(){
        let test = scenario();
        boost_(&mut test);
        test::end(test);
    }

    #[test]
    fun boost_big_number(){
        let test = scenario();
        boost_big_number_(&mut test);
        test::end(test);
    }

    #[test]
    fun unboost(){
        let test = scenario();
        unboost_(&mut test);
        test::end(test);
    }

    #[test]
    #[expected_failure(abort_code = test::EEmptyInventory)]
    fun claim_should_return_no_vewisp(){
        let test = scenario();
        claim_should_return_no_vewisp_(&mut test);
        test::end(test);
    }

    #[test]
    #[expected_failure(abort_code = test::EEmptyInventory)]
    fun boost_should_return_no_vewisp(){
        let test = scenario();
        boost_should_return_no_vewisp_(&mut test);
        test::end(test);
    }

    fun test_init_package_(test: &mut Scenario) {
        let (owner, _, _, _) = people();

        let clock: Clock = clock::create_for_testing(ctx(test));
        clock::share_for_testing(clock);

        next_tx(test, owner);
        {
            farm::init_for_testing(ctx(test));
        };

        next_tx(test, owner);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            test::return_shared(stake_pool_registry);
        }
    }

    fun test_initialize_(test: &mut Scenario) {
        test_init_package_(test);
        let (owner, _, _, _) = people();

        next_tx(test, owner);
        {   
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let modify_cap = vecoin::create_modify_cap_for_testing(ctx(test));
            let clock = test::take_shared<Clock>(test);

            let liquidity_incentive_vault = wisp_vault::create_liquidity_incentive_vault(ctx(test));

            let lock_period = vector::empty<u64>();
            vector::push_back(&mut lock_period, ONE_MONTH);
            vector::push_back(&mut lock_period, TWO_MONTH);

            let lock_period_rate = vector::empty<u64>();
            vector::push_back(&mut lock_period_rate, BASIS_POINTS / 2);
            vector::push_back(&mut lock_period_rate, BASIS_POINTS);

            farm::initialize(
                &controller_cap,
                &mut stake_pool_registry,
                modify_cap,
                liquidity_incentive_vault,
                WISP_PER_MS,
                START_TIME_SEC,
                lock_period,
                lock_period_rate,
                &clock,
                ctx(test)
            );

            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, controller_cap);
        };

        next_tx(test, owner);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);

            let (
                pool_ids,
                active_pool_ids,
                wisp_per_sec,
                total_alloc_point,
                start_timestamp,
            ) = farm::get_registry_data(&stake_pool_registry);

            assert!(table_vec::length(pool_ids) == 0, 0);
            assert!(vector::length(&active_pool_ids) == 0, 1);
            assert!(wisp_per_sec == WISP_PER_MS, 2);
            assert!(total_alloc_point == 0, 3);
            assert!(start_timestamp == START_TIME_SEC, 4);

            test::return_shared(stake_pool_registry);
        };
    }

    fun test_create_pool_before_initialize_(test: &mut Scenario) {
        test_init_package_(test);

        let (owner, _, _, _) = people();

        next_tx(test, owner);
        {
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);

            farm::create_stake_pool<WISPLP<COIN_1, COIN_2>>(
                &controller_cap,
                &mut stake_pool_registry,
                1000,
                BOOST_RATE,
                &clock,
                ctx(test)
            );
            
            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, controller_cap);
        }
    }

    fun test_create_pool_(test: &mut Scenario) {
        test_initialize_(test);

        let (owner, _, _, _) = people();

        next_tx(test, owner);
        {
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);

            farm::create_stake_pool<WISPLP<COIN_1, COIN_2>>(
                &controller_cap,
                &mut stake_pool_registry,
                POOL_1_2_ALLOC_POINT,
                BOOST_RATE,
                &clock,
                ctx(test)
            );
            
            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, controller_cap);
        };

        next_tx(test, owner);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            
            let (
                pool_ids,
                active_pool_ids,
                _,
                total_alloc_point,
                _,
            ) = farm::get_registry_data(&stake_pool_registry);

            assert!(table_vec::length(pool_ids) == 1, 0);
            assert!(vector::length(&active_pool_ids) == 1, 1);
            assert!(total_alloc_point == POOL_1_2_ALLOC_POINT, 2);

            let pool_id = *table_vec::borrow(pool_ids, 0);

            let(
                pool_alloc_point,
                total_stake_point,
                total_boost_balance,
                acc_wisp_per_share,
                last_claim_timestamp,
            ) = farm::get_stake_pool_data<WISPLP<COIN_1, COIN_2>>(&stake_pool_registry, pool_id);

            assert!(pool_alloc_point == POOL_1_2_ALLOC_POINT, 4);
            assert!(total_stake_point == 0, 5);
            assert!(total_boost_balance == 0, 6);
            assert!(acc_wisp_per_share == 0, 7);
            assert!(last_claim_timestamp == START_TIME_SEC, 8);

            test::return_shared(stake_pool_registry);
        }
    }

    fun test_create_more_pools_(test: &mut Scenario) {
        test_create_pool_(test);

        let (owner, _, _, _) = people();

        next_tx(test, owner);
        {
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);

            farm::create_stake_pool<WISPLP<COIN_1, COIN_3>>(
                &controller_cap,
                &mut stake_pool_registry,
                POOL_1_3_ALLOC_POINT,
                BOOST_RATE,
                &clock,
                ctx(test)
            );

            farm::create_stake_pool<WISPLP<COIN_2, COIN_3>>(
                &controller_cap,
                &mut stake_pool_registry,
                POOL_2_3_ALLOC_POINT,
                BOOST_RATE,
                &clock,
                ctx(test)
            );
            
            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, controller_cap);
        };

        next_tx(test, owner);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            
            let (
                pool_ids,
                active_pool_ids,
                _,
                total_alloc_point,
                _,
            ) = farm::get_registry_data(&stake_pool_registry);

            assert!(table_vec::length(pool_ids) == 3, 0);
            assert!(vector::length(&active_pool_ids) == 3, 1);
            assert!(total_alloc_point == POOL_1_2_ALLOC_POINT + POOL_1_3_ALLOC_POINT + POOL_2_3_ALLOC_POINT, 2);

            let pool_id = *table_vec::borrow(pool_ids, 1);

            let(
                pool_alloc_point,
                total_stake_point,
                total_boost_balance,
                acc_wisp_per_share,
                last_claim_timestamp,
            ) = farm::get_stake_pool_data<WISPLP<COIN_1, COIN_3>>(&stake_pool_registry, pool_id);

            assert!(pool_alloc_point == POOL_1_3_ALLOC_POINT, 3);
            assert!(total_stake_point == 0, 4);
            assert!(total_boost_balance == 0, 5);
            assert!(acc_wisp_per_share == 0, 6);
            assert!(last_claim_timestamp == START_TIME_SEC, 7);

            let pool_id = *table_vec::borrow(pool_ids, 2);

            let(
                pool_alloc_point,
                total_stake_point,
                total_boost_balance,
                acc_wisp_per_share,
                last_claim_timestamp,
            ) = farm::get_stake_pool_data<WISPLP<COIN_2, COIN_3>>(&stake_pool_registry, pool_id);

            assert!(pool_alloc_point == POOL_2_3_ALLOC_POINT, 8);
            assert!(total_stake_point == 0, 9);
            assert!(total_boost_balance == 0, 10);
            assert!(acc_wisp_per_share == 0, 11);
            assert!(last_claim_timestamp == START_TIME_SEC, 12);

            test::return_shared(stake_pool_registry);
        }
    }

    fun test_start_farming_before_initialize_(test: &mut Scenario) {
        test_init_package_(test);

        let (owner, _, _, _) = people();

        next_tx(test, owner);
        {
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);

            farm::start_farming(
                &controller_cap,
                &mut stake_pool_registry,
                &clock
            );
            
            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, controller_cap);
        };
    }

    fun test_start_farm_before_initial_start_time_(test: &mut Scenario) {
        test_create_more_pools_(test);

        let (owner, _, _, _) = people();

        next_tx(test, owner);
        {
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);

            clock::set_for_testing(&mut clock, START_TIME - 1000);

            farm::start_farming(
                &controller_cap,
                &mut stake_pool_registry,
                &clock
            );
            
            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, controller_cap);
        };

        next_tx(test, owner);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);

            let (pool_ids, _, _, _, start_timestamp) = farm::get_registry_data(&stake_pool_registry);

            assert!(start_timestamp == START_TIME_SEC - 1, 0);

            let pool_id = *table_vec::borrow(pool_ids, 0);
            let(_, _, _, _, last_claim_timestamp) 
            = farm::get_stake_pool_data<WISPLP<COIN_1, COIN_2>>(&stake_pool_registry, pool_id);
            assert!(last_claim_timestamp == START_TIME_SEC - 1, 1);

            let pool_id = *table_vec::borrow(pool_ids, 1);
            let(_, _, _, _, last_claim_timestamp)
            = farm::get_stake_pool_data<WISPLP<COIN_1, COIN_3>>(&stake_pool_registry, pool_id);
            assert!(last_claim_timestamp == START_TIME_SEC - 1, 2);

            let pool_id = *table_vec::borrow(pool_ids, 2);
            let(_, _, _, _, last_claim_timestamp)
            = farm::get_stake_pool_data<WISPLP<COIN_2, COIN_3>>(&stake_pool_registry, pool_id);
            assert!(last_claim_timestamp == START_TIME_SEC - 1, 3);

            test::return_shared(stake_pool_registry);
        };
    }

    fun test_start_farming_after_initial_start_time_(test: &mut Scenario) {
        test_init_package_(test);

        let (owner, _, _, _) = people();

        next_tx(test, owner);
        {
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);

            clock::set_for_testing(&mut clock, START_TIME);

            farm::start_farming(
                &controller_cap,
                &mut stake_pool_registry,
                &clock
            );
            
            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, controller_cap);
        };
    }

    fun test_create_pool_after_start_(test: &mut Scenario) {
        test_create_more_pools_(test);

        let (owner, _, _, _) = people();

        next_tx(test, owner);
        {
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);

            clock::set_for_testing(&mut clock, START_TIME + 1000);

            farm::create_stake_pool<WISPLP<COIN_1, COIN_4>>(
                &controller_cap,
                &mut stake_pool_registry,
                POOL_1_4_ALLOC_POINT,
                BOOST_RATE,
                &clock,
                ctx(test)
            );
            
            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, controller_cap);
        };
    }

    fun create_sp_nft_invalid_pool_type_(test: &mut Scenario) {
        test_create_pool_after_start_(test);
        let (_, user1, _, _) = people();

        next_tx(test, user1);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            let (pool_ids, _, _, _, _) = farm::get_registry_data(&stake_pool_registry);
            let pool_id = *table_vec::borrow(pool_ids, 0);
            let lp_token = mint<WISPLP<COIN_1, COIN_3>>(1000, ctx(test));
            let lp_vec = vector::empty();
            vector::push_back(&mut lp_vec, lp_token);

            farm::create_sp_nft<WISPLP<COIN_1, COIN_3>>(
                &mut stake_pool_registry,
                lp_vec,
                object::id_to_address(&pool_id),
                1000,
                &clock,
                ctx(test)
            );

            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
        }
    }

    fun create_sp_nft_invalid_pool_id_(test: &mut Scenario) {
        test_create_pool_after_start_(test);
        let (_, user1, _, _) = people();

        next_tx(test, user1);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            let (pool_ids, _, _, _, _) = farm::get_registry_data(&stake_pool_registry);
            let pool_id = *table_vec::borrow(pool_ids, 0);
            let lp_token = mint<WISPLP<COIN_1, COIN_4>>(1000, ctx(test));
            let lp_vec = vector::empty();
            vector::push_back(&mut lp_vec, lp_token);

            farm::create_sp_nft<WISPLP<COIN_1, COIN_4>>(
                &mut stake_pool_registry,
                lp_vec,
                object::id_to_address(&pool_id),
                1000,
                &clock,
                ctx(test)
            );

            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
        }
    }

    fun create_sp_nft_(test: &mut Scenario) {
        test_create_pool_after_start_(test);
        let (_, user1, _, _) = people();

        next_tx(test, user1);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 1000);
            let (pool_ids, _, _, _, _) = farm::get_registry_data(&stake_pool_registry);
            let pool_id = *table_vec::borrow(pool_ids, 0);
            let lp_token = mint<WISPLP<COIN_1, COIN_2>>(1000, ctx(test));
            let lp_vec = vector::empty();
            vector::push_back(&mut lp_vec, lp_token);

            farm::create_sp_nft<WISPLP<COIN_1, COIN_2>>(
                &mut stake_pool_registry,
                lp_vec,
                object::id_to_address(&pool_id),
                1000,
                &clock,
                ctx(test)
            );
            
            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
        };

        next_tx(test, user1);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let (pool_ids, _, _, _, _) = farm::get_registry_data(&stake_pool_registry);
            let pool_id = *table_vec::borrow(pool_ids, 0);
            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);
            let clock = test::take_shared<Clock>(test);

            let (sp_pool_id, lp_balance, boost_balance, boost_multiplier, stake_point, reward_debt) = spnft::get_spnft_data(&sp_nft);

            assert_eq(sp_pool_id, pool_id);
            assert_eq(lp_balance, 1000);
            assert_eq(boost_balance, 0);
            assert_eq(boost_multiplier, (BASIS_POINTS as u128));
            assert_eq(stake_point, 1000);
            assert_eq(reward_debt, 0);

            let (
                _,
                total_stake_point,
                total_boost_balance,
                _,
                last_claim_timestamp,
            ) = farm::get_stake_pool_data<WISPLP<COIN_1, COIN_2>>(&stake_pool_registry, pool_id);

            assert_eq(total_stake_point, 1000);
            assert_eq(total_boost_balance, 0);
            assert_eq(last_claim_timestamp, utils::timestamp_sec(&clock));

            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, sp_nft);
            test::return_shared(clock);
        };
    }

    fun claim_reward_(test: &mut Scenario) {
        create_sp_nft_(test);
        let (_, user1, _, _) = people();
        let wisp_reward: u64;

        next_tx(test, user1);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 1_000_000);
            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);

            wisp_reward = get_reward_by_object<WISPLP<COIN_1, COIN_2>>(
                &stake_pool_registry,
                &sp_nft,
                &clock
            );

            farm::claim_reward<WISPLP<COIN_1, COIN_2>>(
                &mut stake_pool_registry,
                &mut sp_nft,
                &clock,
                ctx(test)
            );

            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, sp_nft);
            test::return_shared(clock);
        };

        next_tx(test, user1);
        {
            let wisp = test::take_from_sender<Coin<WISP>>(test);

            assert_eq(burn(wisp), wisp_reward);
        }
    }

    fun claim_should_return_no_vewisp_(test: &mut Scenario) {
        claim_reward_(test);

        let (_, user1, _, _) = people();

        next_tx(test, user1);
        {
            let vewisp = test::take_from_sender<vecoin::VeCoin<VEWISP>>(test);

            test::return_to_sender(test, vewisp);
        }
    }

    fun create_sp_nft_other_user_(test: &mut Scenario) {
        claim_reward_(test);
        let (_, _, user2, _) = people();
        next_tx(test, user2);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 2000);
            let (pool_ids, _, _, _, _) = farm::get_registry_data(&stake_pool_registry);
            let pool_id = *table_vec::borrow(pool_ids, 0);
            let lp_token = mint<WISPLP<COIN_1, COIN_2>>(2000, ctx(test));
            let lp_vec = vector::empty();
            vector::push_back(&mut lp_vec, lp_token);

            farm::create_sp_nft<WISPLP<COIN_1, COIN_2>>(
                &mut stake_pool_registry,
                lp_vec,
                object::id_to_address(&pool_id),
                2000,
                &clock,
                ctx(test)
            );
            
            test::return_shared(clock);
            test::return_shared(stake_pool_registry);
        };

        next_tx(test, user2);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let (pool_ids, _, _, _, _) = farm::get_registry_data(&stake_pool_registry);
            let pool_id = *table_vec::borrow(pool_ids, 0);
            let(
                _,
                _,
                _,
                acc_wisp_per_share,
                _,
            ) = farm::get_stake_pool_data<WISPLP<COIN_1, COIN_2>>(&stake_pool_registry, pool_id);
            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);
            let clock = test::take_shared<Clock>(test);

            let (sp_pool_id, lp_balance, boost_balance, boost_multiplier, stake_point, reward_debt) = spnft::get_spnft_data(&sp_nft);

            assert_eq(sp_pool_id, pool_id);
            assert_eq(lp_balance, 2000);
            assert_eq(boost_balance, 0);
            assert_eq(boost_multiplier, (BASIS_POINTS as u128));
            assert_eq(stake_point, 2000);
            assert_eq((reward_debt as u128), (acc_wisp_per_share * 2000) / utils::acc_wisp_precision());

            let (
                _,
                total_stake_point,
                total_boost_balance,
                _,
                last_claim_timestamp,
            ) = farm::get_stake_pool_data<WISPLP<COIN_1, COIN_2>>(&stake_pool_registry, pool_id);

            assert_eq(total_stake_point, 3000);
            assert_eq(total_boost_balance, 0);
            assert_eq(last_claim_timestamp, utils::timestamp_sec(&clock));

            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, sp_nft);
            test::return_shared(clock);
        };
    }

    fun stake_more_(test: &mut Scenario) {
        create_sp_nft_other_user_(test);
        let (_, user1, _, _) = people();
        let wisp_reward: u64;

        next_tx(test, user1);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 1_000_000);
            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);
            
            wisp_reward = get_reward_by_object<WISPLP<COIN_1, COIN_2>>(
                &stake_pool_registry,
                &sp_nft,
                &clock
            );

            let lp_token = mint<WISPLP<COIN_1, COIN_2>>(2000, ctx(test));
            let lp_vec = vector::empty();
            vector::push_back(&mut lp_vec, lp_token);
            farm::stake<WISPLP<COIN_1, COIN_2>>(
                &mut stake_pool_registry,
                &mut sp_nft,
                lp_vec,
                2000,
                0,
                &clock,
                ctx(test)
            );

            test::return_shared(stake_pool_registry);
            test::return_to_sender(test, sp_nft);
            test::return_shared(clock);
        };

        next_tx(test, user1);
        {
            let wisp = test::take_from_sender<Coin<WISP>>(test);
            assert_eq(burn(wisp), wisp_reward);
        }
    }

    fun unstake_(test: &mut Scenario) {
        stake_more_(test);
        let (_, user1, _, _) = people();
        let wisp_reward: u64;

        next_tx(test, user1);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 1_000_000);
            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);
            
            wisp_reward = get_reward_by_object<WISPLP<COIN_1, COIN_2>>(
                &stake_pool_registry,
                &sp_nft,
                &clock
            );

            let (_, lp_balance, _, _, _, _) = spnft::get_spnft_data(&sp_nft);

            farm::unstake<WISPLP<COIN_1, COIN_2>>(
                &mut stake_pool_registry,
                sp_nft,
                lp_balance,
                0,
                &clock,
                ctx(test)
            );

            test::return_shared(stake_pool_registry);
            test::return_shared(clock);
        };

        next_tx(test, user1);
        {
            let wisp = test::take_from_sender<Coin<WISP>>(test);
            assert_eq(burn(wisp), wisp_reward);
        }
    }

    fun boost_(test: &mut Scenario) {
        unstake_(test);
        let (_, _, user2, _) = people();
        let wisp_reward: u64;

        next_tx(test, user2);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 1_000_000);
            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);
            
            wisp_reward = get_reward_by_object<WISPLP<COIN_1, COIN_2>>(
                &stake_pool_registry,
                &sp_nft,
                &clock
            );

            let boost_token = mint_vecoin<VEWISP>(1000, ctx(test));
            let boost_vec = vector::empty();
            vector::push_back(&mut boost_vec, boost_token);

            farm::boost<WISPLP<COIN_1, COIN_2>>(
                &mut stake_pool_registry,
                &mut sp_nft,
                boost_vec,
                1000,
                TWO_MONTH,
                &clock,
                ctx(test)
            );

            test::return_shared(stake_pool_registry);
            test::return_shared(clock);
            test::return_to_sender(test, sp_nft);
        };

        next_tx(test, user2);
        {
            let wisp = test::take_from_sender<Coin<WISP>>(test);
            assert_eq(burn(wisp), wisp_reward);

            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);
            let (_, _, boost_balance, boost_multiplier, _, _) = spnft::get_spnft_data(&sp_nft);

            assert_eq(boost_balance, 1000);
            assert_eq(boost_multiplier, get_boost_multiplier());

            test::return_to_sender(test, sp_nft);
        }
    }

    fun boost_big_number_(test: &mut Scenario) {
        unstake_(test);
        let (_, _, user2, _) = people();
        let wisp_reward: u64;

        next_tx(test, user2);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 1_000_000);
            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);
            
            wisp_reward = get_reward_by_object<WISPLP<COIN_1, COIN_2>>(
                &stake_pool_registry,
                &sp_nft,
                &clock
            );

            let boost_token = mint_vecoin<VEWISP>(1_000_000_000, ctx(test));
            let boost_vec = vector::empty();
            vector::push_back(&mut boost_vec, boost_token);

            farm::boost<WISPLP<COIN_1, COIN_2>>(
                &mut stake_pool_registry,
                &mut sp_nft,
                boost_vec,
                1_000_000_000,
                TWO_MONTH,
                &clock,
                ctx(test)
            );

            test::return_shared(stake_pool_registry);
            test::return_shared(clock);
            test::return_to_sender(test, sp_nft);
        };
    }

    fun boost_should_return_no_vewisp_(test: &mut Scenario) {
        boost_(test);

        let (_, _, user2, _) = people();

        next_tx(test, user2);
        {
            let vewisp = test::take_from_sender<vecoin::VeCoin<VEWISP>>(test);

            test::return_to_sender(test, vewisp);
        }
    }

    fun unboost_(test: &mut Scenario) {
        boost_(test);
        let (_, _, user2, _) = people();
        let wisp_reward: u64;

        next_tx(test, user2);
        {
            let stake_pool_registry = test::take_shared<StakePoolRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 1_000_000);
            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);
            
            wisp_reward = get_reward_by_object<WISPLP<COIN_1, COIN_2>>(
                &stake_pool_registry,
                &sp_nft,
                &clock
            );

            farm::unboost<WISPLP<COIN_1, COIN_2>>(
                &mut stake_pool_registry,
                &mut sp_nft,
                1000,
                TWO_MONTH,
                &clock,
                ctx(test)
            );

            test::return_shared(stake_pool_registry);
            test::return_shared(clock);
            test::return_to_sender(test, sp_nft);
        };

        next_tx(test, user2);
        {
            let wisp = test::take_from_sender<Coin<WISP>>(test);
            assert_eq(burn(wisp), wisp_reward);

            let sp_nft = test::take_from_sender<SpNFT<WISPLP<COIN_1, COIN_2>>>(test);
            let (_, _, boost_balance, boost_multiplier, _, _) = spnft::get_spnft_data(&sp_nft);

            assert_eq(boost_balance, 0);
            assert_eq(boost_multiplier, (BASIS_POINTS as u128));

            test::return_to_sender(test, sp_nft);
        }
    }

    // utilities
    fun get_boost_multiplier(): u128 {
        20_000
    }

    fun get_reward_by_object<T>(
        stake_pool_registry: &StakePoolRegistry,
        sp_nft: &SpNFT<T>,
        clock: &Clock,
    ): u64 {
        let (pool_ids, _, wisp_per_sec, total_alloc_point, _) = farm::get_registry_data(stake_pool_registry);
        let pool_id = *table_vec::borrow(pool_ids, 0);
        let(
            pool_alloc_point,
            total_stake_point,
            _,
            acc_wisp_per_share,
            last_claim_timestamp,
        ) = farm::get_stake_pool_data<T>(stake_pool_registry, pool_id);
        let (_, _, _, _, stake_point, reward_debt) = spnft::get_spnft_data(sp_nft);

        get_reward(
            wisp_per_sec,
            total_alloc_point,
            pool_alloc_point,
            total_stake_point,
            acc_wisp_per_share,
            last_claim_timestamp,
            stake_point,
            reward_debt,
            clock,
        )
    }

    fun get_reward(
        wisp_per_sec: u64,
        total_alloc_point: u64,
        pool_alloc_point: u64,
        pool_total_stake_point: u128,
        pool_acc_wisp_per_share: u128,
        pool_last_claim_timestamp: u64,
        stake_point: u128,
        reward_debt: u64,
        clock: &Clock,
    ): u64 {
        let time_passed = utils::timestamp_sec(clock) - pool_last_claim_timestamp;
        let pool_wisp_reward: u128 = (time_passed as u128) * (wisp_per_sec as u128) * (pool_alloc_point as u128) * stake_point / pool_total_stake_point / (total_alloc_point as u128);
        let new_acc_wisp_per_share: u128 = pool_acc_wisp_per_share + pool_wisp_reward * utils::acc_wisp_precision() / stake_point;
        let wisp_reward: u128 = new_acc_wisp_per_share * stake_point / utils::acc_wisp_precision() - (reward_debt as u128);
        (wisp_reward as u64)
    }

    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address, address) { (@0xBEEF, @0x1337, @0x1234, @0x5678) }
}