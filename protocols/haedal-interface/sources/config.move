#[allow(unused_variable, unused_use, unused_function, unused_field)]
module haedal::config {

    use sui::event;

    friend haedal::manage;
    friend haedal::staking;

    const FEE_DENOMINATOR: u64 = 1000;

    const EConfigUnchanged: u64 = 1;
    const EFeeInvalid: u64 = 2;

    struct StakingConfig has store {
        deposit_fee: u64,
        reward_fee: u64,
        validator_reward_fee: u64,
        service_fee: u64,
        withdraw_time_limit: u64,
        validator_count: u64,
    }

    struct StakingConfigCreated has copy, drop {
        deposit_fee: u64,
        reward_fee: u64,
        validator_reward_fee: u64,
        service_fee: u64,
        withdraw_time_limit: u64,
        validator_count: u64,
    }

    struct StakingFeeConfigUpdated has copy, drop {
        name: vector<u8>,
        old: u64,
        new: u64,
    }

    public(friend) fun new(
        deposit_fee: u64,
        reward_fee: u64,
        validator_reward_fee: u64,
        service_fee: u64,
        withdraw_time_limit: u64,
        validator_count: u64,
    ) : StakingConfig {
        abort 0
    }

    public(friend) fun set_deposit_fee(config: &mut StakingConfig, deposit_fee: u64) {
        abort 0
    }

    public(friend) fun set_reward_fee(config: &mut StakingConfig, reward_fee: u64) {
        abort 0
    }

    public(friend) fun set_validator_reward_fee(config: &mut StakingConfig, validator_reward_fee: u64) {
        abort 0
    }

    public(friend) fun set_service_fee(config: &mut StakingConfig, service_fee: u64) {
        abort 0
    }

    public(friend) fun set_withdraw_time_limit(config: &mut StakingConfig, withdraw_time_limit: u64) {
        abort 0
    }

    public(friend) fun set_validator_count(config: &mut StakingConfig, validator_count: u64) {
        abort 0
    }

    public fun get_deposit_fee(config: &StakingConfig): u64 {
        abort 0
    }

    public fun get_reward_fee(config: &StakingConfig): u64 {
        abort 0
    }

    public fun get_validator_reward_fee(config: &StakingConfig): u64 {
        abort 0
    }

    public fun get_service_fee(config: &StakingConfig): u64 {
        abort 0
    }

    public fun get_withdraw_time_limit(config: &StakingConfig): u64 {
        abort 0
    }

    public fun get_validator_count(config: &StakingConfig): u64 {
        abort 0
    }

    fun new_event(
        deposit_fee: u64,
        reward_fee: u64,
        validator_reward_fee: u64,
        service_fee: u64,
        withdraw_time_limit: u64,
        validator_count: u64,
    ) {
        abort 0
    }
}
