#[allow(unused_variable, unused_use, unused_function, unused_field)]
module haedal::interface {

    use sui::sui::{SUI};
    use sui_system::staking_pool::{StakedSui};
    use sui_system::sui_system::{SuiSystemState};

    use sui::clock::{Clock};
    use sui::coin::{Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    use haedal::hasui::{HASUI};
    use haedal::staking::{Self, Staking, UnstakeTicket};


    public entry fun request_stake(wrapper: &mut SuiSystemState, staking: &mut Staking, input: Coin<SUI>, validator: address, ctx: &mut TxContext) {
        abort 0
    }

    public entry fun request_unstake_instant(staking: &mut Staking, input: Coin<HASUI>, ctx: &mut TxContext) {
        abort 0
    }

    public entry fun request_unstake_delay(staking: &mut Staking, clock: &Clock, input: Coin<HASUI>, ctx: &mut TxContext) {
        abort 0
    }

    public entry fun claim(staking: &mut Staking, ticket: UnstakeTicket, ctx: &mut TxContext) {
        abort 0
    }

    public entry fun import_stake_sui_vec(wrapper: &mut SuiSystemState, staking: &mut Staking, inputs: vector<StakedSui>, validator: address, ctx: &mut TxContext) {
        abort 0
    }
}
