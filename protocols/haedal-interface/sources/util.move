#[allow(unused_variable, unused_use, unused_function, unused_field)]
module haedal::util {

    use sui::object::{ID};
    use sui::table::{Self, Table};
    use sui_system::staking_pool::{Self, PoolTokenExchangeRate};
    use sui_system::sui_system::{Self, SuiSystemState};


    public fun calculate_rewards(wrapper: &mut SuiSystemState, pool_id: ID, staked_amount: u64, stake_activation_epoch: u64, current_epoch: u64):u64 {
        abort 0
    }

    public fun pool_token_exchange_rate_at_epoch(exchange_rates: &Table<u64, PoolTokenExchangeRate>, epoch: u64): PoolTokenExchangeRate {
        abort 0
    }

    public fun get_sui_amount(exchange_rate: &PoolTokenExchangeRate, token_amount: u64): u64 {
        abort 0
    }

    public fun get_token_amount(exchange_rate: &PoolTokenExchangeRate, input_sui_amount: u64): u64 {
        abort 0
    }

    public fun mul_div(x: u64, y: u64, z: u64): u64 {
        abort 0
    }

}
