module volo::native_pool{
    use sui::object::{UID};
    use sui::coin::Coin;
    use sui::table::Table;
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use volo::validator_set::ValidatorSet;
    use volo::unstake_ticket::{Metadata as UnstakeMetadata};

    use sui_system::sui_system::SuiSystemState;

    use volo::cert::{CERT, Metadata};
    struct NativePool has key {
        id: UID,
        pending: Coin<SUI>,
        collectable_fee: Coin<SUI>,
        validator_set: ValidatorSet,
        ticket_metadata: UnstakeMetadata,
        total_staked: Table<u64, u64>,
        staked_update_epoch: u64,
        base_unstake_fee: u64,
        unstake_fee_threshold: u64,
        base_reward_fee: u64,
        version: u64,
        paused: bool,
        min_stake: u64,
        total_rewards: u64,
        collected_rewards: u64,
        rewards_threshold: u64,
        rewards_update_ts: u64
    }
    public fun stake_non_entry(self: &mut NativePool, metadata: &mut Metadata<CERT>, wrapper: &mut SuiSystemState, coin: Coin<SUI>, ctx: &mut TxContext): Coin<CERT> {
        abort 0
    }

    public fun get_total_active_stake(self: &NativePool, ctx: &mut TxContext): u64 {
        abort 0
    }
}