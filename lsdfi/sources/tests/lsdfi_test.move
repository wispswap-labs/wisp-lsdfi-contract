#[test_only]
#[allow(unused_function)]
module wisp_lsdfi::lsdfi_test {
    use sui::test_scenario::{Self as test, Scenario, ctx, next_tx};
    use sui::transfer;
    use sui::vec_set;
    use sui::test_utils::{assert_eq, create_one_time_witness};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin, TreasuryCap};
    
    use std::type_name;

    use aggregator::aggregator::{Self, AggregatorRegistry};
    use aggregator::aggregator_test::{Self, LST_1, LST_2};
    use wisp_lsdfi::pool::{Self, AdminCap, PoolRegistry};
    use wisp_lsdfi::lsdfi;
    use wisp_lsdfi::wispSUI::{Self, WISPSUI};

    #[test]
    fun test_init_package() {
        let test = scenario();
        test_init_package_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_mint_wispSUI() {
        let test = scenario();
        test_mint_wispSUI_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_burn_wispSUI() {
        let test = scenario();
        test_burn_wispSUI_(&mut test);
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
            let registry = test::take_shared<PoolRegistry>(test);
            let wispSUI_treasury_cap = test::take_from_sender<TreasuryCap<WISPSUI>>(test);

            pool::initialize(&admin_cap, &mut registry, wispSUI_treasury_cap);
            pool::set_supported_lsd<LST_1>(&admin_cap, &mut registry, true);
            pool::set_supported_lsd<LST_2>(&admin_cap, &mut registry, true);

            test::return_shared(registry);
            test::return_to_sender(test, admin_cap);
        };
    }

    fun test_mint_wispSUI_(test: &mut Scenario) {
        let (_, _, user) = people();

        test_init_package_(test);

        next_tx(test, user);
        {
            let registry = test::take_shared<PoolRegistry>(test);
            let aggregator_registry = test::take_shared<AggregatorRegistry>(test);

            let lst_1 = coin::mint_for_testing<LST_1>(1_000_000_000, ctx(test));

            lsdfi::mint_wispSUI(&mut registry, &aggregator_registry, lst_1, ctx(test));

            test::return_shared(registry);
            test::return_shared(aggregator_registry);
        };

        next_tx(test, user);
        {
            let wispSUI = test::take_from_sender<Coin<WISPSUI>>(test);

            assert_eq(coin::burn_for_testing(wispSUI), 1_000_000_000);
        }
    }

    fun test_burn_wispSUI_(test: &mut Scenario) {
        let (_, _, user) = people();

        test_mint_wispSUI_(test);

        next_tx(test, user);
        {
            let registry = test::take_shared<PoolRegistry>(test);
            let aggregator_registry = test::take_shared<AggregatorRegistry>(test);

            let wispSUI = coin::mint_for_testing<WISPSUI>(1_000_000_000, ctx(test));

            lsdfi::burn_wispSUI<LST_1>(&mut registry, &aggregator_registry, wispSUI, ctx(test));

            test::return_shared(registry);
            test::return_shared(aggregator_registry);
        };

        next_tx(test, user);
        {
            let lst = test::take_from_sender<Coin<LST_1>>(test);

            assert_eq(coin::burn_for_testing(lst), 1_000_000_000);
        }
    }

    fun test_swap_(test: &mut Scenario) {
        let (_, _, user) = people();

        test_mint_wispSUI_(test);

        next_tx(test, user);
        {
            let registry = test::take_shared<PoolRegistry>(test);
            let aggregator_registry = test::take_shared<AggregatorRegistry>(test);

            let lst_2 = coin::mint_for_testing<LST_2>(1_000_000_000, ctx(test));

            lsdfi::swap<LST_2, LST_1>(&mut registry, &aggregator_registry, lst_2, ctx(test));

            test::return_shared(registry);
            test::return_shared(aggregator_registry);
        };

        next_tx(test, user);
        {
            let lst_1 = test::take_from_sender<Coin<LST_1>>(test);

            assert_eq(coin::burn_for_testing(lst_1), 1_000_000_000);
        }
    }

    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address) { (@0xBEEF, @0x1337, @0x1234) }
}