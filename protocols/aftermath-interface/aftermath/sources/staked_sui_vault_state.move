module aftermath::staked_sui_vault_state {
	struct DefaultUnstakeProtocolFeeConfig has store {
		total_fee: u64,
		treasury_allocation: u64,
		dev_wallet_allocation: u64,
		crank_incentive_allocation: u64,
		referee_discount: u64
	}

	struct AtomicUnstakeProtocolFeeConfig has store {
		max_fee: u64,
		min_fee: u64,
		treasury_allocation: u64,
		dev_wallet_allocation: u64,
		crank_incentive_allocation: u64,
		referee_discount: u64
	}

	struct ProtocolConfig has store {
		max_validator_fee: u64,
		dev_account: address,
		default_unstake_protocol_fee: aftermath::staked_sui_vault_state::DefaultUnstakeProtocolFeeConfig,
		atomic_unstake_protocol_fee: aftermath::staked_sui_vault_state::AtomicUnstakeProtocolFeeConfig,
		atomic_unstake_sui_reserves_target_value: u64,
		min_staking_threshold: u64,
		crank_incentive_reward_per_instruction: u64,
		max_crank_incentive_reward: u64,
		reference_gas_price: u64,
		min_fields_requests_per_tx: u64,
		pool_rates_epoch_gap: u64,
		unstaking_bunch_size: u64
	}

	struct ValidatorConfig has store {
		sui_address: address,
		operation_cap_id: sui::object::ID,
		fee: u64
	}

	struct EpochWasChangedState has store {
		is_epoch_processing: bool,
		is_inactive_stakes_processed: bool,
		is_unstaking_deque_sorted: bool,
		is_total_sui_amount_updated: bool,
		is_unstaking_from_storage_processed: bool,
		is_pending_unstakes_processed: bool,
		amount_to_unstake: u64,
		reserves_before_unstake: u64
	}

	struct StakedSuiVaultStateV1 has store, key {
		id: sui::object::UID,
		protocol_config: aftermath::staked_sui_vault_state::ProtocolConfig,
		validator_configs: sui::linked_table::LinkedTable<address, aftermath::staked_sui_vault_state::ValidatorConfig>,
		staked_sui_storage: aftermath::storage::Storage,
		crank_incentive_reward_pool: sui::balance::Balance<sui::sui::SUI>,
		sui_reserves: sui::balance::Balance<sui::sui::SUI>,
		atomic_unstake_sui_reserves: sui::balance::Balance<sui::sui::SUI>,
		afsui_bin: sui::balance::Balance<afsui::afsui::AFSUI>,
		pending_unstake_records: sui::table_vec::TableVec<aftermath::record::PendingUnstakeRecord>,
		inactive_stakes: sui::table_vec::TableVec<sui_system::staking_pool::StakedSui>,
		active_epoch: u64,
		epoch_was_changed_state: aftermath::staked_sui_vault_state::EpochWasChangedState,
		total_sui_amount: u64,
		total_rewards_amount: u64
	}

	public(friend) fun create(
		_arg0: &mut sui_system::sui_system::SuiSystemState,
		_arg1: address,
		_arg2: u64,
		_arg3: u64,
		_arg4: u64,
		_arg5: u64,
		_arg6: u64,
		_arg7: u64,
		_arg8: u64,
		_arg9: u64,
		_arg10: u64,
		_arg11: u64,
		_arg12: u64,
		_arg13: u64,
		_arg14: u64,
		_arg15: u64,
		_arg16: u64,
		_arg17: u64,
		_arg18: &mut sui::tx_context::TxContext
	): aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	{
		abort 0
	}

	fun new(
		_arg0: &mut sui_system::sui_system::SuiSystemState,
		_arg1: address,
		_arg2: u64,
		_arg3: u64,
		_arg4: u64,
		_arg5: u64,
		_arg6: u64,
		_arg7: u64,
		_arg8: u64,
		_arg9: u64,
		_arg10: u64,
		_arg11: u64,
		_arg12: u64,
		_arg13: u64,
		_arg14: u64,
		_arg15: u64,
		_arg16: u64,
		_arg17: u64,
		_arg18: &mut sui::tx_context::TxContext
	): aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	{
		abort 0
	}

	public(friend) fun active_epoch(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun calculate_total_amounts_in_vault(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: u64,
		_arg3: &mut u64,
		_arg4: &sui::tx_context::TxContext
	): (bool, u64, u64)
	{
		abort 0
	}

	public(friend) fun total_sui_amount(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun total_rewards_amount(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun afsui_to_sui_exchange_rate(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &afsui::safe::Safe<sui::coin::TreasuryCap<afsui::afsui::AFSUI>>
	): u128
	{
		abort 0
	}

	public(friend) fun afsui_to_sui(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &afsui::safe::Safe<sui::coin::TreasuryCap<afsui::afsui::AFSUI>>,
		_arg2: u64
	): u64
	{
		abort 0
	}

	public(friend) fun sui_to_afsui_exchange_rate(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &afsui::safe::Safe<sui::coin::TreasuryCap<afsui::afsui::AFSUI>>
	): u128
	{
		abort 0
	}

	public(friend) fun sui_to_afsui(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &afsui::safe::Safe<sui::coin::TreasuryCap<afsui::afsui::AFSUI>>,
		_arg2: u64
	): u64
	{
		abort 0
	}

	public(friend) fun max_validator_fee(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun dev_account(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): address
	{
		abort 0
	}

	public(friend) fun atomic_unstake_sui_reserves_target_value(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun crank_incentive_reward_per_instruction(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun max_crank_incentive_reward(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun reference_gas_price(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun min_staking_threshold(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun min_fields_requests_per_tx(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun pool_rates_epoch_gap(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun unstaking_bunch_size(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun default_unstake_total_fee(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun default_unstake_treasury_allocation(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun default_unstake_dev_wallet_allocation(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun default_unstake_crank_incentive_allocation(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun default_unstake_referee_discount(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun max_atomic_unstake_fee(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun min_atomic_unstake_fee(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun atomic_unstake_treasury_allocation(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun atomic_unstake_dev_wallet_allocation(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun atomic_unstake_crank_incentive_allocation(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun atomic_unstake_referee_discount(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun has_validator_config_for(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: address
	): bool
	{
		abort 0
	}

	public(friend) fun borrow_validator_config(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: address
	): &aftermath::staked_sui_vault_state::ValidatorConfig
	{
		abort 0
	}

	public(friend) fun borrow_validator_config_mut(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: address
	): &mut aftermath::staked_sui_vault_state::ValidatorConfig
	{
		abort 0
	}

	public(friend) fun validator_fee(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: address,
		_arg2: &mut sui::tx_context::TxContext
	): u64
	{
		abort 0
	}

	public(friend) fun crank_incentive_reward_pool_value(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun sui_reserves_value(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun atomic_unstake_sui_reserves_value(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun afsui_bin_value(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun pending_unstake_records_amount(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun is_pending_unstake_records_empty(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): bool
	{
		abort 0
	}

	public(friend) fun borrow_pending_unstake_records(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): &sui::table_vec::TableVec<aftermath::record::PendingUnstakeRecord>
	{
		abort 0
	}

	public(friend) fun borrow_pending_unstake_records_mut(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): &mut sui::table_vec::TableVec<aftermath::record::PendingUnstakeRecord>
	{
		abort 0
	}

	public(friend) fun is_inactive_stakes_empty(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): bool
	{
		abort 0
	}

	public(friend) fun inactive_stakes_amount(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun is_epoch_processing(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): bool
	{
		abort 0
	}

	public(friend) fun is_inactive_stakes_processed(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): bool
	{
		abort 0
	}

	public(friend) fun is_unstaking_deque_sorted(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): bool
	{
		abort 0
	}

	public(friend) fun is_total_sui_amount_updated(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): bool
	{
		abort 0
	}

	public(friend) fun is_unstaking_from_storage_processed(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): bool
	{
		abort 0
	}

	public(friend) fun is_pending_unstakes_processed(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): bool
	{
		abort 0
	}

	public(friend) fun amount_to_unstake(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun reserves_before_unstake(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): u64
	{
		abort 0
	}

	public(friend) fun set_active_epoch(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun inc_total_sui_amount(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun dec_total_sui_amount(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_total_sui_amount(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun dec_total_rewards_amount(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_total_rewards_amount(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun move_to_afsui_bin(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: sui::coin::Coin<afsui::afsui::AFSUI>
	)
	{
		abort 0
	}

	public(friend) fun mint_afsui(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &mut afsui::safe::Safe<sui::coin::TreasuryCap<afsui::afsui::AFSUI>>,
		_arg2: u64,
		_arg3: &mut sui::tx_context::TxContext
	): sui::coin::Coin<afsui::afsui::AFSUI>
	{
		abort 0
	}

	public(friend) fun burn_afsui(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &mut afsui::safe::Safe<sui::coin::TreasuryCap<afsui::afsui::AFSUI>>,
		_arg2: sui::coin::Coin<afsui::afsui::AFSUI>
	): u64
	{
		abort 0
	}

	public(friend) fun burn_afsui_bin(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &mut afsui::safe::Safe<sui::coin::TreasuryCap<afsui::afsui::AFSUI>>,
		_arg2: &mut sui::tx_context::TxContext
	): u64
	{
		abort 0
	}

	public(friend) fun add_default_validator_config(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: address,
		_arg2: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	public(friend) fun push_staked_sui(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: sui_system::staking_pool::StakedSui,
		_arg2: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	public(friend) fun unstake_from_storage(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: u64,
		_arg3: u64,
		_arg4: &mut u64,
		_arg5: &mut sui::tx_context::TxContext
	): sui::balance::Balance<sui::sui::SUI>
	{
		abort 0
	}

	public(friend) fun sort_unstaking_deque(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: u64,
		_arg3: &mut u64,
		_arg4: &mut sui::tx_context::TxContext
	): bool
	{
		abort 0
	}

	public(friend) fun add_crank_incentives(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: sui::coin::Coin<sui::sui::SUI>
	)
	{
		abort 0
	}

	public(friend) fun reward_caller_with_crank_incentives(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64,
		_arg2: address,
		_arg3: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	public(friend) fun join_into_sui_reserves(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: sui::balance::Balance<sui::sui::SUI>
	)
	{
		abort 0
	}

	public(friend) fun split_from_sui_reserves(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	): sui::balance::Balance<sui::sui::SUI>
	{
		abort 0
	}

	public(friend) fun add_atomic_unstake_sui_reserves(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: sui::coin::Coin<sui::sui::SUI>
	)
	{
		abort 0
	}

	public(friend) fun join_into_atomic_unstake_sui_reserves(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: sui::balance::Balance<sui::sui::SUI>
	)
	{
		abort 0
	}

	public(friend) fun split_from_atomic_unstake_sui_reserves(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	): sui::balance::Balance<sui::sui::SUI>
	{
		abort 0
	}

	public(friend) fun push_pending_unstake_record(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: aftermath::record::PendingUnstakeRecord
	)
	{
		abort 0
	}

	public(friend) fun pop_pending_unstake_record(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): aftermath::record::PendingUnstakeRecord
	{
		abort 0
	}

	public(friend) fun push_inactive_stake(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: sui_system::staking_pool::StakedSui
	)
	{
		abort 0
	}

	public(friend) fun pop_inactive_stake(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	): sui_system::staking_pool::StakedSui
	{
		abort 0
	}

	public(friend) fun switch_epoch_processing(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1
	)
	{
		abort 0
	}

	public(friend) fun set_is_inactive_stakes_processed(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: bool
	)
	{
		abort 0
	}

	public(friend) fun set_is_pending_unstakes_processed(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: bool
	)
	{
		abort 0
	}

	public(friend) fun set_is_unstaking_deque_sorted(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: bool
	)
	{
		abort 0
	}

	public(friend) fun set_is_total_sui_amount_updated(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: bool
	)
	{
		abort 0
	}

	public(friend) fun set_is_unstaking_from_storage_processed(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: bool
	)
	{
		abort 0
	}

	public(friend) fun set_amount_to_unstake(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun dec_amount_to_unstake(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun set_reserves_before_unstake(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun rotate_operation_cap(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	public(friend) fun update_validator_fee(
		_arg0: &aftermath::validator::UnverifiedValidatorOperationCap,
		_arg1: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg2: u64
	)
	{
		abort 0
	}

	public(friend) fun authorize(
		_arg0: &afsui::safe::OwnerCap,
		_arg1: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg2: &mut afsui::safe::Safe<sui::coin::TreasuryCap<afsui::afsui::AFSUI>>
	)
	{
		abort 0
	}

	public(friend) fun update_dev_account(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: address
	)
	{
		abort 0
	}

	public(friend) fun update_crank_incentive_reward_per_instruction(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_max_crank_incentive_reward(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_reference_gas_price(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_min_staking_threshold(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_min_fields_requests_per_tx(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_pool_rates_epoch_gap(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_unstaking_bunch_size(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_default_unstake_total_fee(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_default_unstake_treasury_allocation(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_default_unstake_dev_wallet_allocation(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_default_unstake_crank_incentive_allocation(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_default_unstake_referee_discount(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_atomic_unstake_max_fee(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_atomic_unstake_min_fee(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_atomic_unstake_treasury_allocation(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_atomic_unstake_dev_wallet_allocation(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_atomic_unstake_crank_incentive_allocation(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_atomic_unstake_referee_discount(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun update_atomic_unstake_sui_reserves_target_value(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: u64
	)
	{
		abort 0
	}

	public(friend) fun calculate_default_unstake_protocol_fee(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &referral_vault::referral_vault::ReferralVault,
		_arg2: &sui::coin::Coin<sui::sui::SUI>,
		_arg3: address,
		_arg4: u64,
		_arg5: u64
	): (u64, u64, u64)
	{
		abort 0
	}

	public(friend) fun take_default_unstake_protocol_fee(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &referral_vault::referral_vault::ReferralVault,
		_arg2: &mut treasury::treasury::Treasury,
		_arg3: &mut sui::coin::Coin<sui::sui::SUI>,
		_arg4: address,
		_arg5: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	public(friend) fun calculate_atomic_unstake_protocol_fee(
		_arg0: &aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &referral_vault::referral_vault::ReferralVault,
		_arg2: &sui::coin::Coin<sui::sui::SUI>,
		_arg3: address
	): (u64, u64, u64)
	{
		abort 0
	}

	public(friend) fun take_atomic_unstake_protocol_fee(
		_arg0: &mut aftermath::staked_sui_vault_state::StakedSuiVaultStateV1,
		_arg1: &referral_vault::referral_vault::ReferralVault,
		_arg2: &mut treasury::treasury::Treasury,
		_arg3: &mut sui::coin::Coin<sui::sui::SUI>,
		_arg4: address,
		_arg5: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	public(friend) fun take_validator_fee(
		_arg0: &mut sui::coin::Coin<afsui::afsui::AFSUI>,
		_arg1: address,
		_arg2: u64,
		_arg3: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	fun initialize_validator_configs(
		_arg0: &mut sui_system::sui_system::SuiSystemState,
		_arg1: &mut sui::tx_context::TxContext
	): sui::linked_table::LinkedTable<address, aftermath::staked_sui_vault_state::ValidatorConfig>
	{
		abort 0
	}


}