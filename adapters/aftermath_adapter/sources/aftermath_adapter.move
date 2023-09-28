module aftermath_adapter::aftermath_adapter {
    use sui::clock::Clock;
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;
    use sui::coin::{TreasuryCap};
    use std::option::{Self, Option};
    use sui_system::sui_system::{SuiSystemState};
    
    use afsui::afsui::AFSUI;
    use afsui::safe::Safe;
    use referral_vault::referral_vault::ReferralVault;
    use aftermath::staked_sui_vault::{Self, StakedSuiVault};

    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::OperatorCap;

    use wisp_lsdfi::pool::{Self, AdapterCap, AdminCap, LSDFIPoolRegistry, DepositSUIReceipt};

    const EInitialized: u64 = 0;
    const ENotInitialized: u64 = 1;

    struct AftermathAdapter has key {
        id: UID,
        adapter_cap: Option<AdapterCap>
    }

    fun init (ctx: &mut TxContext) {
        let adapter = AftermathAdapter {
            id: object::new(ctx),
            adapter_cap: option::none()
        };
        
        transfer::share_object(adapter)
    }

    public entry fun initialize(
        admin_cap: &AdminCap,
        adapter: &mut AftermathAdapter,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&adapter.adapter_cap), EInitialized);
        let adapter_cap = pool::create_adapter_cap(admin_cap, ctx);
        option::fill(&mut adapter.adapter_cap, adapter_cap);
    }

    public entry fun set_aftermath_result(
        operator_cap: &OperatorCap,
        aggregator: &mut Aggregator,
        staked_sui_vault: &StakedSuiVault,
        clock: &Clock,
    ) {
        let result = staked_sui_vault::total_sui_amount(staked_sui_vault) - staked_sui_vault::total_rewards_amount(staked_sui_vault);
        aggregator::set_result<AFSUI>(operator_cap, aggregator, result, clock);
    }

    public fun stake(
        adapter: &AftermathAdapter,
        registry: &mut LSDFIPoolRegistry,
        staked_sui_vault: &mut StakedSuiVault,
        safe: &mut Safe<TreasuryCap<AFSUI>>,
        state: &mut SuiSystemState,
        referral_vault: &ReferralVault,
        validator: address,
        receipt: &mut DepositSUIReceipt,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&adapter.adapter_cap), ENotInitialized);
        let sui = pool::take_out_SUI_deposit_SUI_receipt<AFSUI>(option::borrow(&adapter.adapter_cap), receipt, ctx);
        let aftermath = staked_sui_vault::request_stake( 
            staked_sui_vault, 
            safe,
            state,
            referral_vault,
            sui, 
            validator, 
            ctx
        );

        pool::pay_back_deposit_SUI_receipt<AFSUI>(option::borrow(&adapter.adapter_cap), registry, receipt, aftermath);
    }
}