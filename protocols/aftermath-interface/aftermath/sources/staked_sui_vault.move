#[allow(unused_variable, unused_field)]
module aftermath::staked_sui_vault {
    use afsui::afsui::AFSUI;
    use afsui::safe::Safe;
    use afsui_referral::referral_vault::ReferralVault;

    use sui::coin::{Coin, TreasuryCap};
    use sui::tx_context::TxContext;
    use sui::object::UID;
    use sui::sui::SUI;

    use sui_system::sui_system::SuiSystemState;

    struct StakedSuiVault has key {
        id: UID,
        version: u64
    }

    public fun total_sui_amount(staked_sui_vault: &StakedSuiVault) : u64 {
        abort 0
    }

    public fun total_rewards_amount(staked_sui_vault: &StakedSuiVault): u64 {
        abort 0
    }

    public fun request_stake(
        staked_sui_vault: &mut StakedSuiVault,
        safe: &mut Safe<TreasuryCap<AFSUI>>,
        state: &mut SuiSystemState,
        referral_vault: &ReferralVault,
        sui_coin: Coin<SUI>,
        validator: address,
        ctx: &mut TxContext
    ): Coin<AFSUI> { 
        abort 0
    }
}