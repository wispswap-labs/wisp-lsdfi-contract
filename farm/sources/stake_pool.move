module wisp_farm::stake_pool {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::clock::{Clock};
    use sui::event;
    use std::type_name::{Self, TypeName};

    use wisp_farm::utils;

    friend wisp_farm::farm;
    friend wisp_farm::spnft;

    const ETypeEqual: u64 = 0;
    const EInsufficientStakePoint: u64 = 1;
    const EInsufficientBoostBalance: u64 = 2;

    struct StakePool has key, store {
        id: UID,
        stake_token_type: TypeName, // Stake token type
        pool_alloc_point: u64, // How many allocation points assigned to this pool
        total_stake_point: u128, // Total stake token in pool * boost multiplier
        total_boost_balance: u64, // Total boost balance in pool
        acc_wisp_per_share: u128, // Accumulated WISP per share, times ACC_WISP_PRECISION, use u128 to avoid overflow
        last_claim_timestamp: u64, // Last timestamp that WISP distribution occurs
        boost_rate: u64, // Boost rate * 10e9 | Boost multiplier = Vewisp Boost / Amount LP * Boost rate
    }

    // Events
    struct StakePoolCreated<phantom T> has copy, drop{
        pool_id: ID,
        alloc_point: u64,
    }

    struct PoolRewardUpdated has copy, drop {
        pool_id: ID,
        last_claim_timestamp: u64,
        acc_wisp_per_share: u128
    }

    struct PoolTotalStakePointUpdated has copy, drop {
        pool_id: ID,
        old_total_stake_point: u128,
        new_total_stake_point: u128
    } 

    struct PoolAllocPointUpdated has copy, drop {
        pool_id: ID,
        old_pool_alloc_point: u64,
        new_pool_alloc_point: u64
    }

    public (friend) fun create_stake_pool<T>(
        alloc_point: u64, 
        start_timestamp: u64, 
        boost_rate: u64, 
        ctx: &mut TxContext
    ): StakePool {
        let id = object::new(ctx);

        event::emit(StakePoolCreated<T>{
            pool_id: object::uid_to_inner(&id),
            alloc_point
        });

        StakePool {
            id,
            pool_alloc_point: alloc_point,
            total_stake_point: 0,
            total_boost_balance: 0,
            acc_wisp_per_share: 0,
            last_claim_timestamp: start_timestamp,
            stake_token_type: type_name::get<T>(),
            boost_rate
        }
    }

    public (friend) fun set_pool_info(
        stake_pool: &mut StakePool,
        pool_alloc_point: u64,
    ) {
        event::emit(PoolAllocPointUpdated{
            pool_id: object::uid_to_inner(&stake_pool.id),
            old_pool_alloc_point: stake_pool.pool_alloc_point,
            new_pool_alloc_point: pool_alloc_point
        });

        stake_pool.pool_alloc_point = pool_alloc_point;
    }

    public (friend) fun set_pool_last_claim_timestamp(
        stake_pool: &mut StakePool,
        last_claim_timestamp: u64,
    ) {
        stake_pool.last_claim_timestamp = last_claim_timestamp;
    }

    public (friend) fun update_stake_pool(
        stake_pool: &mut StakePool,
        wisp_per_sec: u64,
        total_alloc_amount: u64,
        clock: &Clock
    ) {
        let now = utils::timestamp_sec(clock);
        
        if(now < stake_pool.last_claim_timestamp) {
            return
        };

        if (stake_pool.total_stake_point == 0 || stake_pool.pool_alloc_point == 0) {
            stake_pool.last_claim_timestamp = now;
            return
        };

        let multiplier = get_multiplier(stake_pool.last_claim_timestamp, now);
        let wisp_reward = (multiplier as u128) * (wisp_per_sec as u128) * (stake_pool.pool_alloc_point as u128) / (total_alloc_amount as u128);
        stake_pool.acc_wisp_per_share = stake_pool.acc_wisp_per_share + wisp_reward * utils::acc_wisp_precision() / stake_pool.total_stake_point;

        stake_pool.last_claim_timestamp = now;

        event::emit(PoolRewardUpdated{
            pool_id: object::uid_to_inner(&stake_pool.id),
            last_claim_timestamp: now,
            acc_wisp_per_share: stake_pool.acc_wisp_per_share
        });
    }

    public (friend) fun change_stake_point(
        stake_pool: &mut StakePool,
        point_change: u128,
        boost_change: u64,
        positive: bool,
    ) {
        let old_stake_point = stake_pool.total_stake_point;
        if (positive) {
            stake_pool.total_stake_point = stake_pool.total_stake_point + point_change;
            stake_pool.total_boost_balance = stake_pool.total_boost_balance + boost_change;
        } else {
            assert!(stake_pool.total_stake_point >= point_change, EInsufficientStakePoint);
            assert!(stake_pool.total_boost_balance >= boost_change, EInsufficientBoostBalance);
            stake_pool.total_stake_point = stake_pool.total_stake_point - point_change;
            stake_pool.total_boost_balance = stake_pool.total_boost_balance - boost_change;
        };

        event::emit(PoolTotalStakePointUpdated{
            pool_id: object::uid_to_inner(&stake_pool.id),
            old_total_stake_point: old_stake_point,
            new_total_stake_point: stake_pool.total_stake_point
        });
    }

    public fun pool_alloc_point(
        stake_pool: &StakePool
    ): u64 {
        stake_pool.pool_alloc_point
    }

    public fun acc_wisp_per_share(
        stake_pool: &StakePool
    ): u128 {
        stake_pool.acc_wisp_per_share
    }

    public fun stake_token_type(
        stake_pool: &StakePool
    ): TypeName {
        stake_pool.stake_token_type
    }

    public fun boost_rate(
        stake_pool: &StakePool
    ): u64 {
        stake_pool.boost_rate
    }

    fun get_multiplier(
        from: u64,
        to: u64,
    ): u64 {
        let multiplier;
        if (from < to) {
            multiplier = to - from;
        } else {
            multiplier = 0;
        };

        multiplier
    }

    public fun get_stake_pool_data(
        stake_pool: &StakePool
    ): (u64, u128, u64, u128, u64) {
        (
            stake_pool.pool_alloc_point,
            stake_pool.total_stake_point,
            stake_pool.total_boost_balance,
            stake_pool.acc_wisp_per_share,
            stake_pool.last_claim_timestamp,
        )
    }
}