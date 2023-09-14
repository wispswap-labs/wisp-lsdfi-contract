#[allow(unused_variable, unused_use, unused_function, unused_field)]
module haedal::manage {

    use sui::transfer;
    use sui::coin::{TreasuryCap};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    use sui_system::sui_system::{SuiSystemState};

    use haedal::hasui::{HASUI};
    use haedal::staking::{Self, Staking};
    use haedal::config::{Self};


    const EInitialized: u64 = 1;

    struct AdminCap has store, key {
        id: UID,
        init: bool,
    }

    struct OperatorCap has store, key {
        id: UID,
    }

    fun init(ctx: &mut TxContext) {
        abort 0
    }

    #[test_only]
    public fun init_staking_for_test(ctx: &mut TxContext) {
        init(ctx);
    }

    public entry fun initialize(cap: &mut AdminCap, treasuryCap: TreasuryCap<HASUI>, ctx: &mut TxContext) {
        abort 0
    }

    public entry fun set_deposit_fee(_: &AdminCap, staking: &mut Staking, deposit_fee: u64) {
        abort 0
    }

    public entry fun set_reward_fee(_: &AdminCap, staking: &mut Staking, reward_fee: u64) {
        abort 0
    }

    public entry fun set_validator_reward_fee(_: &AdminCap, staking: &mut Staking, validator_reward_fee: u64) {
        abort 0
    }

    public entry fun set_service_fee(_: &AdminCap, staking: &mut Staking, service_fee: u64) {
        abort 0
    }

    public entry fun set_withdraw_time_limit(_: &AdminCap, staking: &mut Staking, withdraw_time_limit: u64) {
        abort 0
    }

    public entry fun set_validator_count(_: &AdminCap, staking: &mut Staking, validator_count: u64) {
        abort 0
    }

    public entry fun migrate(_: &AdminCap, staking: &mut Staking) {
        abort 0
    }

    public entry fun collect_rewards_fee(_: &AdminCap, staking: &mut Staking, account: address, ctx: &mut TxContext) {
        abort 0
    }

    public entry fun collect_service_fee(_: &AdminCap, staking: &mut Staking, account: address, ctx: &mut TxContext) {
        abort 0
    }

    public entry fun toggle_stake(_: &AdminCap, staking: &mut Staking, status: bool) {
        abort 0
    }

    public entry fun toggle_unstake(_: &AdminCap, staking: &mut Staking, status: bool) {
        abort 0
    }

    public entry fun do_stake(
        _: &AdminCap,
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validators: vector<address>,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun update_total_rewards_onchain(_: &AdminCap, staking: &mut Staking, wrapper: &mut SuiSystemState, ctx: &mut TxContext) {
        abort 0
    }

    public entry fun do_unstake_onchain(
        _: &AdminCap,
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validators: vector<address>,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun unstake_pools(
        _: &AdminCap,
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validators: vector<address>,
        ctx: &mut TxContext,
    ) {
        abort 0
    }
}
