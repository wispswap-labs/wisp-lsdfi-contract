module volo_adapter::volo_adapter {
    use sui::clock::Clock;
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;
    use std::option::{Self, Option};
    use sui_system::sui_system::{SuiSystemState};
    
    use volo::native_pool::{Self, NativePool};
    use volo::cert::{CERT, Metadata};

    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::OperatorCap;

    use wisp_lsdfi::pool::{Self, AdapterCap, AdminCap, LSDFIPoolRegistry, DepositSUIReceipt};

    const EInitialized: u64 = 0;
    const ENotInitialized: u64 = 1;

    struct VoloAdapter has key {
        id: UID,
        adapter_cap: Option<AdapterCap>
    }

    fun init (ctx: &mut TxContext) {
        let adapter = VoloAdapter {
            id: object::new(ctx),
            adapter_cap: option::none()
        };
        
        transfer::share_object(adapter)
    }

    public entry fun initialize(
        admin_cap: &AdminCap,
        adapter: &mut VoloAdapter,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&adapter.adapter_cap), EInitialized);
        let adapter_cap = pool::create_adapter_cap(admin_cap, ctx);
        option::fill(&mut adapter.adapter_cap, adapter_cap);
    }

    public entry fun set_volo_result(
        operator_cap: &OperatorCap,
        aggregator: &mut Aggregator,
        volo_native_pool: &mut NativePool,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let result = native_pool::get_total_active_stake(volo_native_pool, ctx);
        aggregator::set_result<CERT>(operator_cap, aggregator, result, clock);
    }

    public fun stake(
        adapter: &VoloAdapter,
        wrapper: &mut SuiSystemState,
        registry: &mut LSDFIPoolRegistry,
        volo_native_pool: &mut NativePool,
        volo_metadata: &mut Metadata<CERT>,
        validator: address,
        receipt: &mut DepositSUIReceipt,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&adapter.adapter_cap), ENotInitialized);
        let sui = pool::take_out_SUI_deposit_SUI_receipt<CERT>(option::borrow(&adapter.adapter_cap), receipt, ctx);
        let volo = native_pool::stake_non_entry(volo_native_pool, volo_metadata, wrapper, sui, ctx);

        pool::pay_back_deposit_SUI_receipt<CERT>(option::borrow(&adapter.adapter_cap), registry, receipt, volo);
    }
}