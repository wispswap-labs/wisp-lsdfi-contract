module stwisp_adapter::stwisp_adapter {
    use sui::clock::Clock;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::{TxContext};
    use sui::transfer;

    use stwisp::stwisp::{STWISP};
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
        let stwisp = stwisp_protocol::request_stake_non_entry(protocol, sui, ctx);

        pool::pay_back_deposit_SUI_receipt<STWISP>(registry, receipt, stwisp);
    }
}

#[test_only]
module stwisp_adapter::stwisp_adapter_test {
    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::{OperatorCap, AdminCap};
    use stwisp_adapter::stwisp_adapter::{Self};
    use wisp_lsdfi_aggregator::aggregator_test::{Self, LST_1, LST_2};
    use wisp_lsdfi::lsdfi_test::{Self};
    use wisp_lsdfi::lsdfi::{Self};
    use wisp_lsdfi::pool::{Self, LSDFIPoolRegistry, AdminCap as LSDFIAdminCap};
    use wisp::pool::{PoolRegistry};
    use stwisp::stwisp_protocol::{Self, StWISPProtocol};
    use stwisp::stwisp::{STWISP};
    use stwisp::stwisp_test;
    use sui::test_scenario::{Self as test, Scenario, ctx, next_tx};
    use sui::test_utils::assert_eq;
    use sui::clock::{Clock};
    use std::type_name;
    use std::option;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    const RISK_WEIGHT: u64 = 10_000;
    const RISK_COFFICIENT: u64 = 10_000;

    #[test]
    fun test_set_result() {
        let test = scenario();
        aggregator_test::test_init_package_(&mut test);
        test_set_result_(&mut test);
        test::end(test);
    }

    #[test]
    fun test_stake(){
        let test = scenario();
        test_stake_(&mut test);
        test::end(test);
    }

    fun test_set_result_(test: &mut Scenario) {
        let (owner, operator, _) = people();
        next_tx(test, owner);
        {
            stwisp_test::test_init_package_(test);
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

    fun test_stake_(test: &mut Scenario) {
        let (owner, operator, _) = people();
        
        lsdfi_test::test_init_package_(test);
        test_set_result_(test);

        next_tx(test, owner);
        {
            let lsdfi_admin_cap = test::take_from_sender<LSDFIAdminCap>(test);
            let aggregator = test::take_shared<Aggregator>(test);
            let registry = test::take_shared<LSDFIPoolRegistry>(test);
            pool::set_support_lst<LST_1>(&lsdfi_admin_cap, &mut registry, &aggregator, false, RISK_WEIGHT, RISK_COFFICIENT);
            pool::set_support_lst<LST_2>(&lsdfi_admin_cap, &mut registry, &aggregator, false, RISK_WEIGHT, RISK_COFFICIENT);
            pool::set_support_lst<STWISP>(&lsdfi_admin_cap, &mut registry, &aggregator, true, RISK_WEIGHT, RISK_COFFICIENT);

            test::return_shared(registry);
            test::return_shared(aggregator);
            test::return_to_sender(test, lsdfi_admin_cap);
        };

        next_tx(test, owner);
        {
            let registry = test::take_shared<LSDFIPoolRegistry>(test);
            let wisp_registry = test::take_shared<PoolRegistry>(test);
            let aggregator = test::take_shared<Aggregator>(test);
            let clock = test::take_shared<Clock>(test);
            let stwisp_protocol = test::take_shared<StWISPProtocol>(test);

            let sui = coin::mint_for_testing<SUI>(1_000_000_000_000_000_000, ctx(test));

            let deposit_receipt = lsdfi::deposit_SUI(&mut registry, &mut wisp_registry, &aggregator, sui, &clock, ctx(test));

            stwisp_adapter::stake(&mut registry, &mut stwisp_protocol, &mut deposit_receipt, ctx(test));

            let wispSUI = lsdfi::drop_deposit_SUI_receipt_non_entry(&mut registry, deposit_receipt, ctx(test));
            coin::burn_for_testing(wispSUI);

            test::return_shared(stwisp_protocol);
            test::return_shared(clock);
            test::return_shared(aggregator);
            test::return_shared(wisp_registry);
            test::return_shared(registry);
        }
    }

    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address) { (@0xBEEF, @0x1337, @0x1234) }
}