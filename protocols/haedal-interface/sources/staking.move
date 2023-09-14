#[allow(unused_variable, unused_use, unused_function, unused_field)]
module haedal::staking {
    use sui::sui::{SUI};
    use std::vector;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use sui::vec_map::{Self, VecMap};

    use sui_system::staking_pool::{Self, StakedSui};
    use sui_system::sui_system::{Self, SuiSystemState};

    use haedal::config::{Self, StakingConfig};
    use haedal::hasui::{HASUI};
    use haedal::vault::{Self, Vault};
    use haedal::util::{Self};
    use haedal::table_queue::{Self, TableQueue};

    friend haedal::manage;
    friend haedal::operate;

    const MIN_STAKING_THRESHOLD: u64 = 1_000_000_000; // 1 SUI
    const DEFAULT_DEPOSIT_FEE_RATE: u64 = 0;
    const DEFAULT_REWARD_FEE_RATE: u64 = 100;
    const DEFAULT_VALIDATOR_REWARD_FEE_RATE: u64 = 0;
    const DEFAULT_SERVICE_FEE_RATE: u64 = 90;
    const FEE_DENOMINATOR: u64 = 1000;
    const EPOCH_FIRST_TWENTY_HOURS_MILI: u64 = 20*3600*1000;
    const EPOCH_DURATION: u64 = 24*3600*1000;
    const DEFAULT_VALIDATOR_COUNT: u64 = 10;
    const MAX_U64: u64 = 0xFFFFFFFFFFFFFFFF; // 18446744073709551615
    const USER_SELECTED_VALIDATORS: vector<u8> = b"user_selected_validators";
    const EXCHANGE_RATE_PRECISION: u64 = 1_000_000;

    const PROGRAM_VERSION: u64 = 0;

    const EDataNotMatchProgram: u64 = 1;
    const EStakedSuiRewardsNotMatched: u64 = 2;
    const EInvalidStakeParas: u64 = 3;
    const EStakeNotEnoughSui: u64 = 4;
    const EStakeNoStsuiMint: u64 = 5;
    const EUnstakeNormalTicketLocking: u64 = 6;
    const EUnstakeNotEnoughSui: u64 = 7;
    const EUnstakeExceedMaxSuiAmount: u64 = 8;
    const EUnstakeInstantNoServiceFee: u64 = 9;
    const EUnstakeNotEnoughStakedSui: u64 = 10;
    const EUnstakeNotZeroStSui: u64 = 11;
    const EStakePause: u64 = 12;
    const EUnstakePause: u64 = 13;
    const EReservedForClaim: u64 = 14;
    const ENoMinStakingThreshhold: u64 = 15;
    const EUnstakeNeedAmountIsNotZero: u64 = 16;


    struct Staking has key {
        id: UID,
        version: u64,
        config: StakingConfig,
        sui_vault: Vault<SUI>,
        claim_sui_vault: Vault<SUI>,
        protocol_sui_vault: Vault<SUI>,
        service_sui_vault: Vault<SUI>,
        stsui_treasury_cap: TreasuryCap<HASUI>,
        unstake_epochs: vector<EpochClaim>,
        total_staked: u64,
        total_unstaked: u64,
        total_rewards: u64,
        total_protocol_fees: u64,
        uncollected_protocol_fees: u64,
        stsui_supply: u64,
        unclaimed_sui_amount: u64,
        pause_stake: bool,
        pause_unstake: bool,
        validators: vector<address>,
        pools: Table<address, PoolInfo>,
        user_selected_validator_bals: VecMap<address, Balance<SUI>>,
        rewards_last_updated_epoch: u64
    }

    struct PoolInfo has store {
        staked_suis: TableQueue<StakedSui>,
        total_staked: u64,
        rewards: u64,
    }

    struct EpochClaim has store {
        epoch: u64,
        amount: u64,
        approved: bool,
    }

    struct UnstakeTicket has key {
        id: UID,
        unstake_timestamp_ms: u64,
        st_amount: u64,
        sui_amount: u64,
        claim_epoch: u64,
        claim_timestamp_ms: u64,
    }

    struct UserStaked has copy, drop {
        owner: address,
        sui_amount: u64,
        st_amount: u64,
        validator: address,
    }

    struct UserInstantUnstaked has copy, drop {
        owner: address,
        sui_amount: u64,
        st_amount: u64,
    }

    struct UserNormalUnstaked has copy, drop {
        owner: address,
        epoch: u64,
        epoch_timestamp_ms: u64,
        unstake_timestamp_ms: u64,
        sui_amount: u64,
        st_amount: u64,
    }

    struct UserClaimed has copy, drop {
        id: ID,
        owner: address,
        sui_amount: u64,
    }

    struct SystemStaked has copy, drop {
        staked_sui_id: ID,
        epoch: u64,
        sui_amount: u64,
        validator: address,
    }

    struct SystemUnstaked has copy, drop {
        epoch: u64,
        sui_amount: u64,
        approved_amount: u64,
    }

    struct PoolSystemUnstaked has copy, drop {
        validator: address,
        epoch: u64,
        sui_amount: u64,
        unstaked_all: bool,
    }

    struct SuiRewardsUpdated has copy, drop {
        old: u64,
        new: u64,
        fee: u64,
    }

    struct RewardsFeeCollected has copy, drop {
        owner: address,
        sui_amount: u64,
    }

    struct ServiceFeeCollected has copy, drop {
        owner: address,
        sui_amount: u64,
    }

    struct VersionUpdated has copy, drop {
        old: u64,
        new: u64,
    }

    struct ExchangeRateUpdated has copy, drop {
        old: u64,
        new: u64,
    }

    public(friend) fun initialize(cap: TreasuryCap<HASUI>, ctx: &mut TxContext) {
        abort 0
    }

    public fun request_stake_coin(wrapper: &mut SuiSystemState, staking: &mut Staking, input: Coin<SUI>, validator: address, ctx: &mut TxContext): Coin<HASUI> {
        abort 0
    }

    public fun import_stake_sui_vec(wrapper: &mut SuiSystemState, staking: &mut Staking, inputs: vector<StakedSui>, validator: address, ctx: &mut TxContext): Coin<HASUI>  {
        abort 0
    }

    fun save_user_selected_staking(staking: &mut Staking, input: Coin<SUI>, validator: address) {
        abort 0
    }

    public fun request_unstake_instant(staking: &mut Staking, input: Coin<HASUI>, ctx: &mut TxContext) {
        abort 0
    }

    public fun request_unstake_delay(staking: &mut Staking, clock: &Clock, input: Coin<HASUI>, ctx: &mut TxContext) {
        abort 0
    }

    fun get_epoch_claim(staking: &mut Staking, epoch: u64): &mut EpochClaim {
        abort 0
    }

    public fun claim(staking: &mut Staking, ticket: UnstakeTicket, ctx: &mut TxContext) {
        abort 0
    }

    public fun claim_coin(staking: &mut Staking, ticket: UnstakeTicket, ctx: &mut TxContext): Coin<SUI> {
        abort 0
    }

    fun claim_epoch_record(staking: &mut Staking, epoch: u64, sui_amount: u64) {
        abort 0
    }

    public fun assert_version(staking: &Staking) {
        abort 0
    }

    public(friend) fun migrate(staking: &mut Staking) {
        abort 0
    }

    public(friend) fun do_stake(
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validators: vector<address>,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public(friend) fun update_total_rewards_onchain(staking: &mut Staking, wrapper: &mut SuiSystemState, ctx: &mut TxContext) {  
        abort 0
    }

    public(friend) fun do_unstake_onchain_by_validator(
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validators: vector<address>,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    fun unstake_inactive_validators(staking: &mut Staking, wrapper: &mut SuiSystemState, ctx: &mut TxContext) {
        abort 0
    }

    public(friend) fun unstake_validator_pools(
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validators: vector<address>,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    fun stake_user_selected_validators(staking: &mut Staking, wrapper: &mut SuiSystemState, active_validators: &vector<address>, ctx: &mut TxContext): Balance<SUI> {
        abort 0
    }

    fun get_user_selected_validators(staking: &mut Staking, active_validators: &vector<address>):(vector<address>, vector<Balance<SUI>>, Balance<SUI>) {
        abort 0
    }

    fun stake_to_validator(
        bal: Balance<SUI>,
        staking: &mut Staking,
        wrapper: &mut SuiSystemState,
        validator: address,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    fun is_active_validator(validator: address, active_validators: &vector<address>): bool {
        abort 0
    }
    
    fun calculate_validator_pool_rewards_increase(wrapper: &mut SuiSystemState, pool: &mut PoolInfo, current_epoch: u64): u64 { 
        abort 0
    }

    fun calculate_staked_sui_rewards(wrapper: &mut SuiSystemState, staked_sui_ref: &StakedSui, current_epoch: u64): u64 {
        abort 0
    }

    fun approve_claim_and_fee(
        staking: &mut Staking,
        unstaked_bal: Balance<SUI>,
        epoch: u64,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    fun do_validator_unstake(
        staking: &mut Staking, 
        wrapper: &mut SuiSystemState, 
        unstaked_bal: &mut Balance<SUI>,
        validator: address, 
        need_amount: u64, 
        current_epoch: u64,
        ctx: &mut TxContext,
    ): u64 {
        abort 0
    }

    fun get_split_amount(wrapper: &mut SuiSystemState, staked_sui_ref: &StakedSui, need_amount: u64, current_epoch: u64): (u64, u64) {
        abort 0
    }

    fun withdraw_staked_sui(wrapper: &mut SuiSystemState, staked_sui: StakedSui, unstaked_bal: &mut Balance<SUI>, ctx: &mut TxContext):(u64, u64) {
        abort 0
    }

    public(friend) fun do_before_unstake(
        staking: &mut Staking,
        approve: bool,
        ctx: &mut TxContext,
    ): (u64, u64, u64) {
        abort 0
    }
    
    public(friend) fun collect_rewards_fee(staking: &mut Staking, account: address, ctx: &mut TxContext) {
        abort 0
    }

    public(friend) fun collect_service_fee(staking: &mut Staking, account: address, ctx: &mut TxContext) {
        abort 0
    }

    public fun get_stsui_by_sui(staking: &Staking, sui_amount: u64): u64 {
        abort 0
    }

    public fun get_sui_by_stsui(staking: &Staking, st_amount: u64): u64 {
        abort 0
    }

    public fun get_exchange_rate(staking: &Staking): u64 {
        abort 0
    }

    public fun get_total_sui(staking: &Staking): u64 {
        abort 0
    }

    public fun get_total_sui_cap(staking: &Staking): u64 {
        abort 0
    }

    public fun get_version(staking: &Staking): u64 {
        abort 0
    }

    public fun get_config_mut(staking: &mut Staking): &mut StakingConfig {
        abort 0
    }

    public fun get_total_staked(staking: &Staking): u64 {
        abort 0
    }
    public fun get_total_unstaked(staking: &Staking): u64 {
        abort 0
    }
    public fun get_total_rewards(staking: &Staking): u64 {
        abort 0
    }
    public fun get_stsui_supply(staking: &Staking): u64 {
        abort 0
    }

    public fun get_sui_vault_amount(staking: &Staking): u64 {
        abort 0
    }
    public fun get_protocol_sui_vault_amount(staking: &Staking): u64 {
        abort 0
    }
    public fun get_service_sui_vault_amount(staking: &Staking): u64 {
        abort 0
    }
    public fun get_total_protocol_fees(staking: &Staking): u64 {
        abort 0
    }
    public fun get_uncollected_protocol_fees(staking: &Staking): u64 {
        abort 0
    }
    public fun get_unclaimed_sui_amount(staking: &Staking): u64 {
        abort 0
    }

    public(friend) fun toggle_stake(staking: &mut Staking, status: bool) {
        abort 0
    }

    public(friend) fun toggle_unstake(staking: &mut Staking, status: bool) {
        abort 0
    }

    public fun get_staked_validators(staking: &Staking): vector<address> {
        abort 0
    }

    public fun get_cached_validator_number(staking: &Staking): u64 {
        abort 0
    }

    public fun get_staked_validator(staking: &Staking, validator: address): bool {
        abort 0
    }

    struct ValidatorStakedInfo has store {
        validator: address,
        total_staked: u64,
        rewards: u64,
        staked_sui_count: u64
    }
    public fun get_validator_staked_info(staking: &Staking): vector<ValidatorStakedInfo> {
        abort 0
    }

    struct UserSelectedStaking has drop {
        validator: address,
        amount: u64
    }
    public fun get_user_selected_staking(staking: &mut Staking): vector<UserSelectedStaking> {
        abort 0
    }

    public fun ticket_unstake_timestamp_ms(ticket: &UnstakeTicket): u64 {
        abort 0
    }
    public fun ticket_st_amount(ticket: &UnstakeTicket): u64 {
        abort 0
    }
    public fun ticket_sui_amount(ticket: &UnstakeTicket): u64 {
        abort 0
    }
    public fun ticket_claim_epoch(ticket: &UnstakeTicket): u64 {
        abort 0
    }
    public fun ticket_claim_timestamp_ms(ticket: &UnstakeTicket): u64 {
        abort 0
    }

}
