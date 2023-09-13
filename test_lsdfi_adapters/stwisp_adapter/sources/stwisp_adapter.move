module stwisp_adapter::stwisp_adapter {
    use sui::clock::Clock;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::sui::SUI;
    use sui::tx_context::{TxContext};
    use sui::transfer;

    use stwisp::stwisp::{Self, STWISP};
    use stwisp::stwisp_protocol::{Self, StWISPProtocol};

    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::OperatorCap;

    use wisp_lsdfi::pool::{Self, LSDFIPoolRegistry, DepositSUIReceipt};

    public fun set_stwisp_result(
        operator_cap: &OperatorCap,
        aggregator: &mut Aggregator,
        stwisp_protocol: &StWISPProtocol,
        clock: &Clock,
    ) {
        let result = stwisp_protocol::get_staked_balance(stwisp_protocol);
        aggregator::set_result<STWISP>(operator_cap, aggregator, result, clock);
    }

    public fun stake(
        registry: &mut LSDFIPoolRegistry,
        protocol: &mut StWISPProtocol,
        receipt: &mut DepositSUIReceipt,
        ctx: &mut TxContext
    ) {
        let sui = pool::take_out_SUI_deposit_SUI_receipt<STWISP>(receipt, ctx);
        let stsui = stwisp_protocol::request_stake_non_entry(protocol, sui, ctx);

        pool::pay_back_deposit_SUI_receipt<STWISP>(registry, receipt, stsui);
    }
}

#[test_only]
module stwisp_adapter::stwisp_adapter_test {
    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::{OperatorCap, AdminCap};
    use stwisp_adapter::stwisp_adapter::{Self};
    use wisp_lsdfi_aggregator::aggregator_test;
    use stwisp::stwisp_protocol::{Self, StWISPProtocol};
    use stwisp::stwisp::{STWISP};
    use sui::test_scenario::{Self as test, Scenario, ctx, next_tx};
    use sui::test_utils::assert_eq;
    use sui::clock::{Self, Clock};
    use std::type_name;
    use std::option;

    #[test]
    fun test_set_result() {
        let test = scenario();
        aggregator_test::test_init_package_(&mut test);
        test_set_result_(&mut test);
        test::end(test);
    }

    fun test_set_result_(test: &mut Scenario) {
        let (owner, operator, _) = people();

        next_tx(test, owner);
        {
            stwisp_protocol::init_for_testing(test::ctx(test));
            let admin_cap = test::take_from_sender<AdminCap>(test);
            let aggregator = test::take_shared<Aggregator>(test);

            aggregator::set_support_lst<STWISP>(&admin_cap, &mut aggregator, true);

            test::return_shared(aggregator);
            test::return_to_sender(test, admin_cap);
        };

        next_tx(test, operator);
        {
            let aggregator = test::take_shared<Aggregator>(test);
            let clock = test::take_shared<Clock>(test);
            let operator_cap = test::take_from_sender<OperatorCap>(test);
            let stwisp_protocol = test::take_shared<StWISPProtocol>(test);

            stwisp_adapter::set_stwisp_result(&operator_cap, &mut aggregator, &stwisp_protocol, &clock);
            stwisp_protocol::set_staked_balance(&mut stwisp_protocol, 1_000_000_000_000_000);

            test::return_shared(stwisp_protocol);
            test::return_to_sender(test, operator_cap);
            test::return_shared(clock);
            test::return_shared(aggregator);
        };

        next_tx(test, operator);
        {
            let aggregator = test::take_shared<Aggregator>(test);
            let res = aggregator::get_result(&aggregator, type_name::get<STWISP>());
            let (value, _) = aggregator::get_result_value(option::borrow(res));

            assert_eq(value, 1_000_000_000_000_000);
            test::return_shared(aggregator);
        }
    }

    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address) { (@0xBEEF, @0x1337, @0x1234) }
}