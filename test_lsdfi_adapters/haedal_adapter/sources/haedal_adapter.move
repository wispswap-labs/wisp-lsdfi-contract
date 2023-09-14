module haedal_adapter::haedal_adapter {
    use sui::clock::Clock;
    use sui::tx_context::{TxContext};
    use sui_system::sui_system::{SuiSystemState};
    
    use haedal::staking::{Staking};
    use haedal::hasui::HASUI;

    use wisp_lsdfi_aggregator::aggregator::{Self, Aggregator};
    use wisp_lsdfi_aggregator::access_control::OperatorCap;

    use wisp_lsdfi::pool::{Self, LSDFIPoolRegistry, DepositSUIReceipt};

    public entry fun haha(
        operator_cap: &OperatorCap,
        aggregator: &mut Aggregator,
        haedal_staking: &Staking,
        clock: &Clock,
    ) {
    }

    // public entry fun set_haedal_result(
    //     operator_cap: &OperatorCap,
    //     aggregator: &mut Aggregator,
    //     haedal_staking: &Staking,
    //     clock: &Clock,
    // ) {
    //     let result = staking::get_total_sui(haedal_staking);
    //     aggregator::set_result<HASUI>(operator_cap, aggregator, result, clock);
    // }

    // public fun stake(
    //     wrapper: &mut SuiSystemState,
    //     registry: &mut LSDFIPoolRegistry,
    //     haedal_staking: &mut Staking,
    //     validator: address,
    //     receipt: &mut DepositSUIReceipt,
    //     ctx: &mut TxContext
    // ) {
    //     let sui = pool::take_out_SUI_deposit_SUI_receipt<HASUI>(receipt, ctx);
    //     let haedal = staking::request_stake_coin(wrapper, haedal_staking, sui, validator, ctx);

    //     pool::pay_back_deposit_SUI_receipt<HASUI>(registry, receipt, haedal);
    // }
}