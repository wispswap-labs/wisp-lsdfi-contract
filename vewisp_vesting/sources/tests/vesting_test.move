module vewisp_vesting::vesting_test {
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use sui::coin::{Coin, TreasuryCap, mint_for_testing as mint, burn_for_testing as burn};
    use sui::test_utils::{assert_eq, create_one_time_witness};
    use sui::clock::{Self, Clock};

    use std::vector;
    // use std::debug;

    use vewisp_vesting::vesting::{Self, ControllerCap, VestingRegistry, VestingVeWisp};

    use wisp_token::vecoin::{Self, VeTreasuryCap, VeCoin, burn_for_testing as burn_vecoin, mint_for_testing as mint_vecoin};
    use wisp_token::wisp::{Self, WISP};
    use wisp_token::vewisp::{Self, VEWISP};

    use wisp_vault::vault::{Self, TreasuryVault};
    use wisp_vault::vesting_vault::{Self, VaultControllerCap};
    use wisp_vault::wisp_vault;

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
    fun test_convert_wisp_to_vewisp(){
        let test = scenario();
        test_convert_wisp_to_vewisp_(&mut test);
        test::end(test);
    }
    
    #[test]
    fun test_create_vesting_vewisp(){
        let test = scenario();
        test_create_vesting_vewisp_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_redeem_wisp(){
        let test = scenario();
        test_redeem_wisp_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_redeem_wisp_end(){
        let test = scenario();
        test_redeem_wisp_end_(&mut test);
        test::end(test);
    }

    fun test_init_package_(test: &mut Scenario) {
        let (owner, _, _, _) = people();
        
        next_tx(test, owner);
        {
            vesting::init_for_testing(ctx(test));
            let clock = clock::create_for_testing(ctx(test));
            clock::share_for_testing(clock);
        };

        next_tx(test, owner);
        {
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let vesting_registry = test::take_shared<VestingRegistry>(test);

            test::return_to_sender(test, controller_cap);
            test::return_shared(vesting_registry);
        }
    }

    fun test_initialize_(test: &mut Scenario) {
        test_init_package_(test);
        let (owner, _, _, _) = people();

        next_tx(test, owner);
        {
            wisp::init_for_testing(create_one_time_witness<WISP>(), ctx(test));
            vewisp::init_for_testing(create_one_time_witness<VEWISP>(), ctx(test));
            vesting_vault::init_for_testing(ctx(test));
        };

        next_tx(test, owner);
        {
            
            let ve_wisp_treasury = test::take_from_sender<VeTreasuryCap<VEWISP>>(test);
            let wisp_treasury = test::take_from_sender<TreasuryCap<WISP>>(test);
            let vecoin_controller_cap = test::take_from_sender<vecoin::ControllerCap<VEWISP>>(test);
            let vault_controller_cap = test::take_from_sender<VaultControllerCap>(test);

            wisp_vault::initialize(
                &vault_controller_cap,
                &vecoin_controller_cap,
                wisp_treasury,
                ve_wisp_treasury,
                ctx(test)
            );

            test::return_to_sender(test, vecoin_controller_cap);
            test::return_to_sender(test, vault_controller_cap);
        };

        next_tx(test, owner);
        {
            let controller_cap = test::take_from_sender<ControllerCap>(test);
            let vesting_registry = test::take_shared<VestingRegistry>(test);
            
            let modify_cap = vecoin::create_modify_cap_for_testing<VEWISP>(ctx(test));
            let treasury_vault = test::take_from_sender<TreasuryVault>(test);

            let milestones_locked_ms = vector::empty<u64>();
            vector::push_back(&mut milestones_locked_ms, 1000);
            vector::push_back(&mut milestones_locked_ms, 2000);
            vector::push_back(&mut milestones_locked_ms, 4000);

            let milestones_released_percent = vector::empty<u64>();
            vector::push_back(&mut milestones_released_percent, 3000);
            vector::push_back(&mut milestones_released_percent, 6000);
            vector::push_back(&mut milestones_released_percent, 10000);

            vesting::initialize(
                &controller_cap,
                &mut vesting_registry,
                treasury_vault,
                modify_cap,
                milestones_locked_ms,
                milestones_released_percent
            );

            test::return_to_sender(test, controller_cap);
            test::return_shared(vesting_registry);
        };

        next_tx(test, owner);
        {
            let vesting_registry = test::take_shared<VestingRegistry>(test);
            let milestones = vesting::get_milestones(&vesting_registry);

            assert_eq(vector::length(milestones), 3);

            let (locked_ms_1, released_percent_1) = vesting::get_milestone_data(vector::borrow(milestones, 0));
            assert_eq(locked_ms_1, 1000);
            assert_eq(released_percent_1, 3000);

            let (locked_ms_2, released_percent_2) = vesting::get_milestone_data(vector::borrow(milestones, 1));
            assert_eq(locked_ms_2, 2000);
            assert_eq(released_percent_2, 6000);

            let (locked_ms_3, released_percent_3) = vesting::get_milestone_data(vector::borrow(milestones, 2));
            assert_eq(locked_ms_3, 4000);
            assert_eq(released_percent_3, 10000);

            test::return_shared(vesting_registry);
        }
    }

    fun test_convert_wisp_to_vewisp_(test: &mut Scenario) {
        test_initialize_(test);
        let (_, user, _, _) = people();

        next_tx(test, user);
        {
            let clock = test::take_shared<Clock>(test);
            clock::set_for_testing(&mut clock, vault::tge_time() + 1);
            let vesting_registry = test::take_shared<VestingRegistry>(test);

            let wisp = mint<WISP>(10000, ctx(test));

            let wisp_vec = vector::empty<Coin<WISP>>();
            vector::push_back(&mut wisp_vec, wisp);

            vesting::wisp_to_vewisp(
                &mut vesting_registry,
                wisp_vec,
                10000,
                &clock,
                ctx(test)
            );

            test::return_shared(clock);
            test::return_shared(vesting_registry);
        };

        next_tx(test, user);
        {
            let vewisp = test::take_from_sender<VeCoin<VEWISP>>(test);

            assert_eq(burn_vecoin(vewisp), 10000);
        };
    }

    fun test_create_vesting_vewisp_(test: &mut Scenario) {
        test_convert_wisp_to_vewisp_(test);
        let (_, user, _, _) = people();

        next_tx(test, user);
        {
            let vesting_registry = test::take_shared<VestingRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            let vewisp = mint_vecoin<VEWISP>(10000, ctx(test));

            let vewisp_vec = vector::empty<VeCoin<VEWISP>>();
            vector::push_back(&mut vewisp_vec, vewisp);

            vesting::create_vesting_vewisp_nft(
                &mut vesting_registry,
                vewisp_vec,
                10000,
                &clock,
                ctx(test)
            );

            test::return_shared(clock);
            test::return_shared(vesting_registry);
        };
    }

    fun test_redeem_wisp_(test: &mut Scenario) {
        test_create_vesting_vewisp_(test);
        let (_, user, _, _) = people();

        next_tx(test, user);
        {
            let vesting_registry = test::take_shared<VestingRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 1000);
            let vesting_vewisp = test::take_from_sender<VestingVeWisp>(test);
            vesting::redeem_wisp(
                &mut vesting_registry,
                vesting_vewisp,
                &clock,
                ctx(test)
            );
            test::return_shared(clock);
            test::return_shared(vesting_registry);
        };

        next_tx(test, user);
        {
            let wisp = test::take_from_sender<Coin<WISP>>(test);
            assert_eq(burn(wisp), 3000);
        };
    }

    fun test_redeem_wisp_end_(test: &mut Scenario) {
        test_create_vesting_vewisp_(test);
        let (_, user, _, _) = people();

        next_tx(test, user);
        {
            let vesting_registry = test::take_shared<VestingRegistry>(test);
            let clock = test::take_shared<Clock>(test);
            clock::increment_for_testing(&mut clock, 5000);
            let vesting_vewisp = test::take_from_sender<VestingVeWisp>(test);
            vesting::redeem_wisp(
                &mut vesting_registry,
                vesting_vewisp,
                &clock,
                ctx(test)
            );
            test::return_shared(clock);
            test::return_shared(vesting_registry);
        };

        next_tx(test, user);
        {
            let wisp = test::take_from_sender<Coin<WISP>>(test);
            assert_eq(burn(wisp), 10000);
        };
    }

    // utilities
    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address, address) { (@0xBEEF, @0x1337, @0x1234, @0x5678) }
}