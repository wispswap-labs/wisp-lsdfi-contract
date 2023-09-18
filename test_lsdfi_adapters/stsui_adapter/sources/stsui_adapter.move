module stsui_adapter::stsui_adapter {
    use sui::clock::Clock;
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;

    use std::option::{Self, Option};

    use stsui::stsui::{STSUI};
    use stsui::stsui_protocol::{Self, StSUIProtocol};

    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::OperatorCap;

    use wisp_lsdfi::pool::{Self, AdminCap, AdapterCap, LSDFIPoolRegistry, DepositSUIReceipt};

    const EInitialized: u64 = 0;
    const ENotInitialized: u64 = 1;

    struct StSuiAdapter has key {
        id: UID,
        adapter_cap: Option<AdapterCap>
    }

    fun init (ctx: &mut TxContext) {
        let adapter = StSuiAdapter {
            id: object::new(ctx),
            adapter_cap: option::none()
        };
        
        transfer::share_object(adapter)
    }

    public entry fun initialize(
        admin_cap: &AdminCap,
        adapter: &mut StSuiAdapter,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&adapter.adapter_cap), EInitialized);
        let adapter_cap = pool::create_adapter_cap(admin_cap, ctx);
        option::fill(&mut adapter.adapter_cap, adapter_cap);
    }

    public entry fun set_stsui_result(
        operator_cap: &OperatorCap,
        aggregator: &mut Aggregator,
        stsui_protocol: &StSUIProtocol,
        clock: &Clock,
    ) {
        let result = stsui_protocol::get_staked_balance(stsui_protocol);
        aggregator::set_result<STSUI>(operator_cap, aggregator, result, clock);
    }

    public fun stake(
        adapter: &StSuiAdapter,
        registry: &mut LSDFIPoolRegistry,
        protocol: &mut StSUIProtocol,
        receipt: &mut DepositSUIReceipt,
        ctx: &mut TxContext
    ) {
        let sui = pool::take_out_SUI_deposit_SUI_receipt<STSUI>(option::borrow(&adapter.adapter_cap), receipt, ctx);
        let stsui = stsui_protocol::request_stake_non_entry(protocol, sui, ctx);

        pool::pay_back_deposit_SUI_receipt<STSUI>(option::borrow(&adapter.adapter_cap), registry, receipt, stsui);
    }
}

#[test_only]
module stsui_adapter::stsui_adapter_test {
    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::{OperatorCap, AdminCap};
    use stsui_adapter::stsui_adapter::{Self};
    use wisp_lsdfi_aggregator::aggregator_test::{Self, LST_1, LST_2};
    use wisp_lsdfi::lsdfi_test::{Self};
    use wisp_lsdfi::lsdfi::{Self};
    use wisp_lsdfi::pool::{Self, LSDFIPoolRegistry, AdminCap as LSDFIAdminCap};
    use wisp::pool::{PoolRegistry};
    use stsui::stsui_protocol::{Self, StSUIProtocol};
    use stsui::stsui::{STSUI};
    use stsui::stsui_test;
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
            stsui_test::test_init_package_(test);
            let admin_cap = test::take_from_sender<AdminCap>(test);
            let aggregator = test::take_shared<Aggregator>(test);

            aggregator::set_support_lst<STSUI>(&admin_cap, &mut aggregator, true);

            test::return_shared(aggregator);
            test::return_to_sender(test, admin_cap);
        };

        next_tx(test, operator);
        {
            let aggregator = test::take_shared<Aggregator>(test);
            let clock = test::take_shared<Clock>(test);
            let operator_cap = test::take_from_sender<OperatorCap>(test);
            let stsui_protocol = test::take_shared<StSUIProtocol>(test);

            stsui_adapter::set_stsui_result(&operator_cap, &mut aggregator, &stsui_protocol, &clock);
            stsui_protocol::set_staked_balance(&mut stsui_protocol, 1_000_000_000_000_000);

            test::return_shared(stsui_protocol);
            test::return_to_sender(test, operator_cap);
            test::return_shared(clock);
            test::return_shared(aggregator);
        };

        next_tx(test, operator);
        {
            let aggregator = test::take_shared<Aggregator>(test);
            let res = aggregator::get_result(&aggregator, type_name::get<STSUI>());
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
            pool::set_support_lst<STSUI>(&lsdfi_admin_cap, &mut registry, &aggregator, true, RISK_WEIGHT, RISK_COFFICIENT);

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
            let stsui_protocol = test::take_shared<StSUIProtocol>(test);

            let sui = coin::mint_for_testing<SUI>(1_000_000_000_000_000_000, ctx(test));

            let deposit_receipt = lsdfi::deposit_SUI(&mut registry, &mut wisp_registry, &aggregator, sui, &clock, ctx(test));

            stsui_adapter::stake(&mut registry, &mut stsui_protocol, &mut deposit_receipt, ctx(test));

            let wispSUI = lsdfi::drop_deposit_SUI_receipt_non_entry(&mut registry, deposit_receipt, ctx(test));
            coin::burn_for_testing(wispSUI);

            test::return_shared(stsui_protocol);
            test::return_shared(clock);
            test::return_shared(aggregator);
            test::return_shared(wisp_registry);
            test::return_shared(registry);
        }
    }

    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address) { (@0xBEEF, @0x1337, @0x1234) }
}