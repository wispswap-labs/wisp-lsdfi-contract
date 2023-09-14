#[allow(unused_variable, unused_use, unused_function, unused_field)]
module haedal::operate {
    use sui::tx_context::{TxContext};
    use sui_system::sui_system::{SuiSystemState};

    use haedal::manage::{OperatorCap};
    use haedal::staking::{Self, Staking};
    public entry fun do_stake(
        _: &OperatorCap,
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validators: vector<address>,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun update_total_rewards_onchain(_: &OperatorCap, staking: &mut Staking, wrapper: &mut SuiSystemState, ctx: &mut TxContext) {
        abort 0
    }

    public entry fun do_unstake_onchain(
        _: &OperatorCap,
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validators: vector<address>,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun unstake_pools(
        _: &OperatorCap,
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validators: vector<address>,
        ctx: &mut TxContext,
    ) {
        abort 0
    }
}
