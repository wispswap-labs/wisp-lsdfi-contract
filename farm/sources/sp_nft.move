module wisp_farm::spnft {
    use sui::object::{Self, UID, ID};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::event;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Clock};

    use wisp_token::vewisp::VEWISP;

    use wisp_farm::utils;

    friend wisp_farm::farm;

    const EZeroAmount: u64 = 0;
    const EInsufficientBalance: u64 = 1;
    const ENonZero: u64 = 2;
    const ELocked: u64 = 3;
    
    struct SpNFT<phantom T> has key, store {
        id: UID, 
        stake_pool_id: ID,
        lp_balance: Balance<T>,
        boost_balance: Balance<VEWISP>,
        boost_multiplier: u128, // Boost multiplier time 1e4 |  Boost multiplier = Vewisp Boost / Amount LP * Boost rate
        stake_point: u128,
        reward_debt: u64,
        lock_period: u64,
        unlock_time: u64,
    }

    // Event
    struct SpNFTCreated<phantom T> has copy, drop {
        sp_nft_id: ID,
        stake_pool_id: ID,
    }

    struct Staked<phantom T> has copy, drop {
        sp_nft_id: ID,
        stake_pool_id: ID,
        user: address,
        stake_token_amount: u64,
        current_stake_point: u128,
        reward_debt: u64,
    }

    struct UnStaked<phantom T> has copy, drop {
        sp_nft_id: ID,
        stake_pool_id: ID,
        user: address,
        unstake_token_amount: u64,
        current_stake_point: u128,
        reward_debt: u64,
    }

    struct Boosted<phantom T> has copy, drop {
        sp_nft_id: ID,
        stake_pool_id: ID,
        user: address,
        boost_token_amount: u64,
        boost_multiplier: u128,
        current_stake_point: u128,
        reward_debt: u64,
    }

    struct UnBoosted<phantom T> has copy, drop {
        sp_nft_id: ID,
        stake_pool_id: ID,
        user: address,
        unboost_token_amount: u64,
        boost_multiplier: u128,
        current_stake_point: u128,
        reward_debt: u64,
    }

    public (friend) fun create_sp_nft<T>(
        stake_pool_id: ID,
        ctx: &mut TxContext
    ): SpNFT<T>{
        let id = object::new(ctx);

        event::emit(SpNFTCreated<T> {
            sp_nft_id: object::uid_to_inner(&id),
            stake_pool_id,
        });

        SpNFT<T> {
            id: id,
            stake_pool_id,
            lp_balance: balance::zero(),
            boost_balance: balance::zero(),
            boost_multiplier: utils::boost_multiplier_precision(),
            stake_point: 0,
            reward_debt: 0,
            lock_period: 0,
            unlock_time: 0,
        }
    }

    public (friend) fun stake<T>(
        sp_nft: &mut SpNFT<T>,
        wisp_lp: &mut Coin<T>,
        stake_amount: u64,
        acc_wisp_per_share: u128,
        boost_rate: u64,
        lock_period: u64,
        lock_rate: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): (u64, u128, u64, bool) { // return reward, point change, boost change, positive
        assert!(stake_amount > 0, EZeroAmount);
        assert!(coin::value(wisp_lp) >= stake_amount, EInsufficientBalance);

        let actual_stake_point = (balance::value(&sp_nft.lp_balance) as u128);
        let stake_balance = coin::into_balance(coin::split(wisp_lp, stake_amount, ctx));
        sp_nft.lock_period = lock_period;
        let (reward, stake_point_change, positive) = update_stake_point(
            sp_nft, 
            stake_balance,
            balance::zero<VEWISP>(),
            actual_stake_point,
            boost_rate,
            lock_rate,
            acc_wisp_per_share,
            clock,
        );

        if (sp_nft.lock_period > 0) {
            sp_nft.unlock_time = utils::timestamp_sec(clock) + sp_nft.lock_period;
        };

        event::emit(Staked<T> {
            sp_nft_id: object::uid_to_inner(&sp_nft.id),
            stake_pool_id: sp_nft.stake_pool_id,
            user: tx_context::sender(ctx),
            stake_token_amount: stake_amount,
            current_stake_point: sp_nft.stake_point,
            reward_debt: sp_nft.reward_debt,
        });

        (reward, stake_point_change, 0, positive)
    }

    public (friend) fun unstake<T>(
        sp_nft: &mut SpNFT<T>,
        unstake_amount: u64,
        acc_wisp_per_share: u128,
        boost_rate: u64,
        lock_period: u64,
        lock_rate: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): (Coin<T>, u64, u128, u64, bool){ // return reward, point change, boost change, positive
        assert!(unstake_amount > 0, EZeroAmount);
        assert!(balance::value(&sp_nft.lp_balance) >= unstake_amount, EInsufficientBalance);

        let actual_stake_point = (balance::value(&sp_nft.lp_balance) as u128);
        let unstake_balance = balance::split(&mut sp_nft.lp_balance, unstake_amount);
        sp_nft.lock_period = lock_period;
        let (reward, stake_point_change, positive) = update_stake_point(
            sp_nft, 
            balance::zero<T>(),
            balance::zero<VEWISP>(),
            actual_stake_point,
            boost_rate,
            lock_rate,
            acc_wisp_per_share,
            clock
        );

        event::emit(UnStaked<T> {
            sp_nft_id: object::uid_to_inner(&sp_nft.id),
            stake_pool_id: sp_nft.stake_pool_id,
            user: tx_context::sender(ctx),
            unstake_token_amount: unstake_amount,
            current_stake_point: sp_nft.stake_point,
            reward_debt: sp_nft.reward_debt,
        });

        (coin::from_balance(unstake_balance, ctx), reward, stake_point_change, 0, positive)
    }

    public (friend) fun boost<T>(
        sp_nft: &mut SpNFT<T>,
        boost_balance: Balance<VEWISP>,
        acc_wisp_per_share: u128,
        boost_rate: u64,
        lock_period: u64,
        lock_rate: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): (u64, u128, u64, bool){ // return reward, point change, boost change, positive
        let boost_amount: u64 = balance::value(&boost_balance);
        assert!(boost_amount > 0, EZeroAmount);

        let actual_stake_point = (balance::value(&sp_nft.lp_balance) as u128);
        sp_nft.lock_period = lock_period;
        let (reward, stake_point_change, positive) = update_stake_point(
            sp_nft, 
            balance::zero<T>(),
            boost_balance,
            actual_stake_point,
            boost_rate,
            lock_rate,
            acc_wisp_per_share,
            clock
        );

        event::emit(Boosted<T> {
            sp_nft_id: object::uid_to_inner(&sp_nft.id),
            stake_pool_id: sp_nft.stake_pool_id,
            user: tx_context::sender(ctx),
            boost_token_amount: boost_amount,
            boost_multiplier: sp_nft.boost_multiplier,
            current_stake_point: sp_nft.stake_point,
            reward_debt: sp_nft.reward_debt,
        });

        (reward, stake_point_change, boost_amount, positive)
    }

    public (friend) fun unboost<T>(
        sp_nft: &mut SpNFT<T>,
        unboost_amount: u64,
        acc_wisp_per_share: u128,
        boost_rate: u64,
        lock_period: u64,
        lock_rate: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): (Balance<VEWISP>, u64, u128, u64, bool){ // return reward, point change, boost change, positive
        assert!(unboost_amount > 0, EZeroAmount);
        assert!(balance::value(&sp_nft.boost_balance) >= unboost_amount, EInsufficientBalance);

        let actual_stake_point = (balance::value(&sp_nft.lp_balance) as u128);
        let unboost_balance = balance::split(&mut sp_nft.boost_balance, unboost_amount);

        sp_nft.lock_period = lock_period;
        let (reward, stake_point_change, positive) = update_stake_point(
            sp_nft, 
            balance::zero<T>(),
            balance::zero<VEWISP>(),
            actual_stake_point,
            boost_rate,
            lock_rate,
            acc_wisp_per_share,
            clock
        );

        event::emit(UnBoosted<T> {
            sp_nft_id: object::uid_to_inner(&sp_nft.id),
            stake_pool_id: sp_nft.stake_pool_id,
            user: tx_context::sender(ctx),
            unboost_token_amount: unboost_amount,
            boost_multiplier: sp_nft.boost_multiplier,
            current_stake_point: sp_nft.stake_point,
            reward_debt: sp_nft.reward_debt,
        });
 
        (unboost_balance, reward, stake_point_change, unboost_amount, positive)
    }

    fun update_stake_point<T>(
        sp_nft: &mut SpNFT<T>,
        stake_balance: Balance<T>,
        boost_balance: Balance<VEWISP>,
        actual_stake_point: u128,
        boost_rate: u64,
        lock_rate: u64,
        acc_wisp_per_share: u128,
        clock: &Clock,
    ): (u64, u128, bool) {
        let old_stake_point = sp_nft.stake_point;
        if (sp_nft.unlock_time >= utils::timestamp_sec(clock)) {
            actual_stake_point = old_stake_point;
        };

        balance::join(&mut sp_nft.lp_balance, stake_balance);
        balance::join(&mut sp_nft.boost_balance, boost_balance);

        let boost_multiplier = get_boost_multiplier(
            balance::value(&sp_nft.boost_balance), 
            balance::value(&sp_nft.lp_balance), 
            boost_rate,
            lock_rate
        );
        sp_nft.boost_multiplier = boost_multiplier;
        sp_nft.stake_point = (balance::value(&sp_nft.lp_balance) as u128) * (sp_nft.boost_multiplier as u128) / utils::boost_multiplier_precision();
        let reward = update_reward_debt_<T>(sp_nft, actual_stake_point, old_stake_point, acc_wisp_per_share, clock);

        if (sp_nft.stake_point > old_stake_point) {
            (reward, sp_nft.stake_point - old_stake_point, true)
        } else {
            (reward, old_stake_point - sp_nft.stake_point, false)
        }
    }

    public (friend) fun claim_reward<T> (
        sp_nft: &mut SpNFT<T>,
        acc_wisp_per_share: u128,
        clock: &Clock,
    ): u64 {

        let old_stake_point = sp_nft.stake_point;
        let actual_stake_point = old_stake_point;
        if (sp_nft.unlock_time < utils::timestamp_sec(clock)) {
            actual_stake_point = (balance::value(&sp_nft.lp_balance) as u128);
        };

        update_reward_debt_<T>(sp_nft, actual_stake_point, old_stake_point, acc_wisp_per_share, clock)
    }

    fun update_reward_debt_<T> (
        sp_nft: &mut SpNFT<T>,
        actual_stake_point: u128,
        old_stake_point: u128,
        acc_wisp_per_share: u128,
        clock: &Clock,
    ): u64 {
        let reward = 0;
        if (old_stake_point > 0) {
            reward = (((old_stake_point * acc_wisp_per_share / utils::acc_wisp_precision()) - (sp_nft.reward_debt as u128)) * actual_stake_point / old_stake_point as u64);
        };
        
        sp_nft.reward_debt = ((sp_nft.stake_point * acc_wisp_per_share / utils::acc_wisp_precision()) as u64);
        if (sp_nft.lock_period > 0) {
            sp_nft.unlock_time = utils::timestamp_sec(clock) + sp_nft.lock_period;
        };
        reward
    }

    fun get_boost_multiplier(
        boost_balance: u64, 
        lp_balance: u64, 
        boost_rate: u64,
        lock_rate: u64
    ): u128 {
        if (lp_balance == 0) {
            return utils::basis_point_u128()
        };

        utils::basis_point_u128() + 
            ((boost_rate as u128) * (boost_balance as u128) * utils::boost_multiplier_precision() 
                / ((lp_balance as u128) * utils::boost_rate_precision()))
            * (utils::basis_point_u128() + (lock_rate as u128)) / utils::basis_point_u128()
    }


    public (friend) fun destroy_zero<T> (
        sp_nft: SpNFT<T>
    ) {
        assert!(balance::value(&sp_nft.lp_balance) == 0, ENonZero);
        assert!(balance::value(&sp_nft.boost_balance) == 0, ENonZero);

        let SpNFT {
            id, 
            stake_pool_id: _, 
            lp_balance, 
            boost_balance,
            boost_multiplier: _, 
            stake_point: _, 
            reward_debt: _,
            lock_period: _,
            unlock_time: _,
        } = sp_nft;

        object::delete(id);
        balance::destroy_zero(lp_balance);
        balance::destroy_zero(boost_balance);
    }

    // view functions
    public fun stake_pool_id<T>(sp_nft: &SpNFT<T>): ID{
        sp_nft.stake_pool_id
    }

    public fun lp_balance<T>(sp_nft: &SpNFT<T>):u64 {
        balance::value(&sp_nft.lp_balance)
    }

    public fun boost_balance<T>(sp_nft: &SpNFT<T>):u64 {
        balance::value(&sp_nft.boost_balance)
    }

    public fun get_spnft_data<T>(sp_nft: &SpNFT<T>): (ID, u64, u64, u128, u128, u64) {
        (
            sp_nft.stake_pool_id,
            balance::value(&sp_nft.lp_balance),
            balance::value(&sp_nft.boost_balance),
            sp_nft.boost_multiplier,
            sp_nft.stake_point,
            sp_nft.reward_debt,
        )
    }
}