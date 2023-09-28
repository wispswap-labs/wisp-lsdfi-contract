module haedal_adapter::haedal_adapter {
    use sui::clock::Clock;
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;
    use std::option::{Self, Option};
    use sui_system::sui_system::{SuiSystemState};
    
    use haedal::staking::{Self, Staking};
    use haedal::hasui::HASUI;

    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::OperatorCap;

    use wisp_lsdfi::pool::{Self, AdapterCap, AdminCap, LSDFIPoolRegistry, DepositSUIReceipt};

    const EInitialized: u64 = 0;
    const ENotInitialized: u64 = 1;

    struct HeadalAdapter has key {
        id: UID,
        adapter_cap: Option<AdapterCap>
    }

    fun init (ctx: &mut TxContext) {
        let adapter = HeadalAdapter {
            id: object::new(ctx),
            adapter_cap: option::none()
        };
        
        transfer::share_object(adapter)
    }

    public entry fun initialize(
        admin_cap: &AdminCap,
        adapter: &mut HeadalAdapter,
        ctx: &mut TxContext
    ) {
        assert!(option::is_none(&adapter.adapter_cap), EInitialized);
        let adapter_cap = pool::create_adapter_cap(admin_cap, ctx);
        option::fill(&mut adapter.adapter_cap, adapter_cap);
    }

    public entry fun set_haedal_result(
        operator_cap: &OperatorCap,
        aggregator: &mut Aggregator,
        haedal_staking: &Staking,
        clock: &Clock,
    ) {
        let result = staking::get_total_sui(haedal_staking);
        aggregator::set_result<HASUI>(operator_cap, aggregator, result, clock);
    }

    public fun stake(
        adapter: &HeadalAdapter,
        wrapper: &mut SuiSystemState,
        registry: &mut LSDFIPoolRegistry,
        haedal_staking: &mut Staking,
        validator: address,
        receipt: &mut DepositSUIReceipt,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&adapter.adapter_cap), ENotInitialized);
        let sui = pool::take_out_SUI_deposit_SUI_receipt<HASUI>(option::borrow(&adapter.adapter_cap), receipt, ctx);
        let haedal = staking::request_stake_coin(wrapper, haedal_staking, sui, validator, ctx);

        pool::pay_back_deposit_SUI_receipt<HASUI>(option::borrow(&adapter.adapter_cap), registry, receipt, haedal);
    }
}