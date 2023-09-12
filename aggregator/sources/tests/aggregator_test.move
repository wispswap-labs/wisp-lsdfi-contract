#[test_only]
#[allow(unused_function)]
module wisp_lsdfi_aggregator::aggregator_test {
    use sui::test_scenario::{Self as test, Scenario, ctx, next_tx};
    use sui::transfer;
    use sui::vec_set;
    use sui::test_utils::assert_eq;
    use sui::clock::{Self, Clock};
    
    use std::option;
    use std::type_name;

    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::{AdminCap, OperatorCap};

    struct LST_1 has drop {}
    struct LST_2 has drop {}

    const LST_1_BACKED: u64 = 1_000_000_000_000_000;
    const LST_2_BACKED: u64 = 2_000_000_000_000_000;

    #[test]
    fun test_init_package() {
        let test = scenario();
        test_init_package_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_set_support_lst() {
        let test = scenario();
        test_set_support_lst_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_set_result() {
        let test = scenario();
        test_set_result_(&mut test);
        test::end(test);
    }

    fun test_init_package_(test: &mut Scenario) {
        let (owner, operator, _) = people();

        let clock: Clock = clock::create_for_testing(ctx(test));
        clock::set_for_testing(&mut clock, 1000);
        clock::share_for_testing(clock);

        next_tx(test, owner);
        {
            aggregator::init_for_testing(ctx(test));
        };

        next_tx(test, owner);
        {
            let admin_cap = test::take_from_sender<AdminCap>(test);
            let operator_cap = test::take_from_sender<OperatorCap>(test);
            let registry = test::take_shared<Aggregator>(test);
            let clock = test::take_shared<Clock>(test);

            transfer::public_transfer(operator_cap, operator);

            test::return_to_sender(test, admin_cap);
            test::return_shared(registry);
            test::return_shared(clock);
        };
    }

    fun test_set_support_lst_(test: &mut Scenario) {
        let(owner, _, _) = people();
        test_init_package_(test);

        next_tx(test, owner);
        {
            let admin_cap = test::take_from_sender<AdminCap>(test);
            let registry = test::take_shared<Aggregator>(test);

            aggregator::set_support_lst<LST_1>(&admin_cap, &mut registry, true);
            aggregator::set_support_lst<LST_2>(&admin_cap, &mut registry, true);

            test::return_to_sender(test, admin_cap);
            test::return_shared(registry);
        };

        next_tx(test, owner);
        {
            let registry = test::take_shared<Aggregator>(test);
            let list_name = aggregator::get_list_name(&registry);

            assert_eq(vec_set::contains(list_name, &type_name::get<LST_1>()), true);
            assert_eq(vec_set::contains(list_name, &type_name::get<LST_2>()), true);

            test::return_shared(registry);
        }
    }

    public fun test_set_result_(test: &mut Scenario) {
        let (_, operator, _) = people();
        test_set_support_lst_(test);

        next_tx(test, operator);
        {
            let operator_cap = test::take_from_sender<OperatorCap>(test);
            let registry = test::take_shared<Aggregator>(test);
            let clock = test::take_shared<Clock>(test);

            aggregator::set_result<LST_1>(&operator_cap, &mut registry, LST_1_BACKED, &clock);
            aggregator::set_result<LST_2>(&operator_cap, &mut registry, LST_2_BACKED, &clock);

            test::return_to_sender(test, operator_cap);
            test::return_shared(registry);
            test::return_shared(clock);
        };

        next_tx(test, operator);
        {
            let clock = test::take_shared<Clock>(test);
            let registry = test::take_shared<Aggregator>(test);

            let option_result_lst_1 = aggregator::get_result(&registry, type_name::get<LST_1>());
            
            let (value, timestamp) = aggregator::get_result_value(option::borrow(option_result_lst_1));

            assert_eq(value, LST_1_BACKED);
            assert_eq(timestamp, clock::timestamp_ms(&clock));

            let option_result_lst_2 = aggregator::get_result(&registry, type_name::get<LST_2>());
            
            let (value, timestamp) = aggregator::get_result_value(option::borrow(option_result_lst_2));

            assert_eq(value, LST_2_BACKED);
            assert_eq(timestamp, clock::timestamp_ms(&clock));

            test::return_shared(registry);
            test::return_shared(clock);
        }
    }

    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address) { (@0xBEEF, @0x1337, @0x1234) }
}