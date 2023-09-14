#[test_only]
#[allow(unused_use, unused_function, unused_variable)]
module wisp_lsdfi::lsdfi_test {
    use sui::sui::{SUI};
    use sui::test_scenario::{Self as test, Scenario, ctx, next_tx};
    use sui::transfer;
    use sui::vec_set;
    use sui::test_utils::{assert_eq, create_one_time_witness};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin, TreasuryCap};
    
    use std::type_name;
    use std::debug::print;

    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::aggregator_test::{Self, LST_1, LST_2};
    use wisp_lsdfi::pool::{Self, AdminCap, LSDFIPoolRegistry};
    use wisp_lsdfi::lsdfi;
    use wisp_lsdfi::wispSUI::{Self, WISPSUI};

    use wisp::pool::{Self as wisp_pool, PoolRegistry};
    use wisp::pool_tests;

    const SLOPE: u64 = 10_000;
    const RISK_WEIGHT: u64 = 10_000;
    const RISK_COFFICIENT: u64 = 10_000;

    #[test]
    fun test_init_package() {
        let test = scenario();
        test_init_package_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_deposit() {
        let test = scenario();
        test_deposit_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_deposit_SUI() {
        let test = scenario();
        test_deposit_SUI_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_withdraw() {
        let test = scenario();
        test_withdraw_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_swap() {
        let test = scenario();
        test_swap_(&mut test);
        test::end(test);
    }

    fun test_init_package_(test: &mut Scenario) {
        let (owner, _, _) = people();

        aggregator_test::test_set_result_(test);

        next_tx(test, owner);
        {
            pool::init_for_testing(ctx(test));
            wispSUI::init_for_testing(create_one_time_witness<WISPSUI>(), ctx(test));
        };

        next_tx(test, owner);
        {
            let admin_cap = test::take_from_sender<AdminCap>(test);
            let registry = test::take_shared<LSDFIPoolRegistry>(test);
            let aggregator = test::take_shared<Aggregator>(test);
            let wispSUI_treasury_cap = test::take_from_sender<TreasuryCap<WISPSUI>>(test);

            pool::initialize(&admin_cap, &mut registry, wispSUI_treasury_cap, owner, SLOPE);
            pool::set_support_lst<LST_1>(&admin_cap, &mut registry, &aggregator, true, RISK_WEIGHT, RISK_COFFICIENT);
            pool::set_support_lst<LST_2>(&admin_cap, &mut registry, &aggregator, true, RISK_WEIGHT, RISK_COFFICIENT);
            
            test::return_shared(registry);
            test::return_to_sender(test, admin_cap);
            test::return_shared(aggregator);
        };
    }

    fun test_deposit_(test: &mut Scenario) {
        let (_, _, user) = people();

        test_init_package_(test);

        next_tx(test, user);
        {   
            let clock = test::take_shared<Clock>(test);
            let registry = test::take_shared<LSDFIPoolRegistry>(test);
            let aggregator = test::take_shared<Aggregator>(test);

            let lst_1 = coin::mint_for_testing<LST_1>(1_000_000_000_000_000_000, ctx(test));

            lsdfi::deposit(&mut registry, &aggregator, lst_1, &clock, ctx(test));

            test::return_shared(clock);
            test::return_shared(registry);
            test::return_shared(aggregator);
        };

        next_tx(test, user);
        {
            let wispSUI = test::take_from_sender<Coin<WISPSUI>>(test);

            assert_eq(coin::burn_for_testing(wispSUI), 999_100_000_000_000_000);
        };

        next_tx(test, user);
        {   
            let clock = test::take_shared<Clock>(test);
            let registry = test::take_shared<LSDFIPoolRegistry>(test);
            let aggregator = test::take_shared<Aggregator>(test);

            let lst_2 = coin::mint_for_testing<LST_2>(2_000_000_000_000_000_000, ctx(test));

            lsdfi::deposit(&mut registry, &aggregator, lst_2, &clock, ctx(test));

            test::return_shared(clock);
            test::return_shared(registry);
            test::return_shared(aggregator);
        };

        next_tx(test, user);
        {
            let wispSUI = test::take_from_sender<Coin<WISPSUI>>(test);

            assert_eq(coin::burn_for_testing(wispSUI), 2_000_000_000_000_000_000);
        };
    }

    fun test_deposit_SUI_(test: &mut Scenario) {
        let (_, _, user) = people();

        test_deposit_(test);
        pool_tests::test_init_package_(test);

        next_tx(test, user);
        {
            let registry = test::take_shared<PoolRegistry>(test);
            let sui = coin::mint_for_testing<SUI>(1_000_000_000_000_000_000, ctx(test));
            let wispSUI = coin::mint_for_testing<WISPSUI>(1_000_000_000_000_000_000, ctx(test));

            let lp = wisp_pool::create_pool(
                &mut registry,
                &mut sui,
                &mut wispSUI,
                1_000_000_000_000_000_000,
                1_000_000_000_000_000_000,
                ctx(test)
            );

            coin::burn_for_testing(sui);
            coin::burn_for_testing(wispSUI);
            coin::burn_for_testing(lp);

            test::return_shared(registry);
        };

        next_tx(test, user);
        {
            let registry = test::take_shared<LSDFIPoolRegistry>(test);
            let wisp_registry = test::take_shared<PoolRegistry>(test);
            let aggregator = test::take_shared<Aggregator>(test);
            let clock = test::take_shared<Clock>(test);

            let sui = coin::mint_for_testing<SUI>(1_000_000_000_000_000_000, ctx(test));

            let deposit_receipt = lsdfi::deposit_SUI(&mut registry, &mut wisp_registry, &aggregator, sui, &clock, ctx(test));
            
            let sui_lst_1 = pool::take_out_SUI_deposit_SUI_receipt<LST_1>(&mut deposit_receipt, ctx(test));
            let sui_lst_1_amount = coin::burn_for_testing(sui_lst_1);

            let lst_1 = coin::mint_for_testing<LST_1>(sui_lst_1_amount, ctx(test));
            pool::pay_back_deposit_SUI_receipt(&mut registry, &mut deposit_receipt, lst_1);

            let sui_lst_2 = pool::take_out_SUI_deposit_SUI_receipt<LST_2>(&mut deposit_receipt, ctx(test));
            let sui_lst_2_amount = coin::burn_for_testing(sui_lst_2);

            let lst_2 = coin::mint_for_testing<LST_2>(sui_lst_2_amount, ctx(test));
            pool::pay_back_deposit_SUI_receipt(&mut registry, &mut deposit_receipt, lst_2);

            let wispSUI = lsdfi::drop_deposit_SUI_receipt_non_entry(&mut registry, deposit_receipt, ctx(test));
            coin::burn_for_testing(wispSUI);

            test::return_shared(registry);
            test::return_shared(wisp_registry);
            test::return_shared(aggregator);
            test::return_shared(clock);
        }
    }

    fun test_withdraw_(test: &mut Scenario) {
        let (_, _, user) = people();

        test_deposit_(test);
        let wispSUI_mint = 1_500_000_000_000_000_000;
        next_tx(test, user);
        {
            let registry = test::take_shared<LSDFIPoolRegistry>(test);

            let wispSUI = coin::mint_for_testing<WISPSUI>(wispSUI_mint, ctx(test));

            let receipt = lsdfi::withdraw(&mut registry,  wispSUI, ctx(test));
            lsdfi::consume_withdraw_receipt<LST_1>(&mut registry, &mut receipt, ctx(test));
            lsdfi::consume_withdraw_receipt<LST_2>(&mut registry, &mut receipt, ctx(test));
            lsdfi::drop_withdraw_receipt(receipt);

            test::return_shared(registry);
        };

        next_tx(test, user);
        {
            let lst_1 = test::take_from_sender<Coin<LST_1>>(test);
            let lst_2 = test::take_from_sender<Coin<LST_2>>(test);

            let wispSUI_supply = 999_100_000_000_000_000 + 2_000_000_00_000_000_000;
            assert_eq(coin::burn_for_testing(lst_1), (((1_000_000_000_000_000_000 as u128) * (wispSUI_mint as u128) / (wispSUI_supply as u128) * (10_000  - 25) / 10_000) as u64));
            assert_eq(coin::burn_for_testing(lst_2), (((2_000_000_000_000_000_000 as u128) * (wispSUI_mint as u128) / (wispSUI_supply as u128) * (10_000  - 25) / 10_000) as u64));
        }
    }

    fun test_swap_(test: &mut Scenario) {
        let (_, _, user) = people();

        test_deposit_(test);

        next_tx(test, user);
        {
            let clock = test::take_shared<Clock>(test);
            let registry = test::take_shared<LSDFIPoolRegistry>(test);
            let aggregator = test::take_shared<Aggregator>(test);

            let lst_2 = coin::mint_for_testing<LST_2>(1_000_000_000_000_000_000, ctx(test));

            lsdfi::swap<LST_2, LST_1>(&mut registry, &aggregator, lst_2, &clock, ctx(test));

            test::return_shared(clock);
            test::return_shared(registry);
            test::return_shared(aggregator);
        };

        next_tx(test, user);
        {
            let lst_1 = test::take_from_sender<Coin<LST_1>>(test);

            assert_eq(coin::burn_for_testing(lst_1), 994_300_000_000_000_000);
        }
    }

    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address) { (@0xBEEF, @0x1337, @0x1234) }
}