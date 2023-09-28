module aftermath::storage {
	struct ProcessingState has store {
		is_totals_calculating: bool,
		total_sui_amount: u64,
		total_rewards_amount: u64,
		pool_id_opt: std::option::Option<sui::object::ID>,
		stake_number: u64
	}

	struct StorageStateV1 has store, key {
		id: sui::object::UID,
		stakes: sui::linked_table::LinkedTable<sui::object::ID, sui::table_vec::TableVec<sui_system::staking_pool::StakedSui>>,
		unstaking_deque: linked_set::linked_set::LinkedSet<sui::object::ID>,
		sorting_sandbox: vector<sui::object::ID>,
		sorting_keys: vector<u64>,
		processing_state: aftermath::storage::ProcessingState,
		is_sandbox_sorted: bool
	}

	struct Storage has store {
		id: sui::object::UID
	}

	public(friend) fun create(
		_arg0: &mut sui::tx_context::TxContext
	): aftermath::storage::Storage
	{
		abort 0
	}

	public(friend) fun push_stake(
		_arg0: &mut aftermath::storage::Storage,
		_arg1: sui_system::staking_pool::StakedSui,
		_arg2: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	fun push_stake_inner(
		_arg0: &mut aftermath::storage::StorageStateV1,
		_arg1: sui_system::staking_pool::StakedSui,
		_arg2: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	public(friend) fun unstake(
		_arg0: &mut aftermath::storage::Storage,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: u64,
		_arg3: u64,
		_arg4: u64,
		_arg5: u64,
		_arg6: &mut u64,
		_arg7: &mut sui::tx_context::TxContext
	): sui::balance::Balance<sui::sui::SUI>
	{
		abort 0
	}

	public(friend) fun calculate_total_amounts(
		_arg0: &mut aftermath::storage::Storage,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: u64,
		_arg3: &mut u64,
		_arg4: &sui::tx_context::TxContext
	): (bool, u64, u64)
	{
		abort 0
	}

	fun calculate_total_pool_amounts(
		_arg0: &sui::table_vec::TableVec<sui_system::staking_pool::StakedSui>,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: u64,
		_arg3: &mut u64,
		_arg4: u64,
		_arg5: &sui::tx_context::TxContext
	): (bool, u64, u64, u64)
	{
		abort 0
	}

	public(friend) fun sort_unstaking_deque(
		_arg0: &mut aftermath::storage::Storage,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: u64,
		_arg3: &mut u64,
		_arg4: u64,
		_arg5: &mut sui::tx_context::TxContext
	): bool
	{
		abort 0
	}

	fun move_unstaking_deque_to_sorting_sandbox_and_calc_keys(
		_arg0: &mut aftermath::storage::StorageStateV1,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: u64,
		_arg3: &mut u64,
		_arg4: u64,
		_arg5: &sui::tx_context::TxContext
	): bool
	{
		abort 0
	}

	fun move_sorting_sandbox_to_unstaking_deque(
		_arg0: &mut aftermath::storage::StorageStateV1,
		_arg1: u64,
		_arg2: &mut u64
	): bool
	{
		abort 0
	}

	fun sort_sandbox(
		_arg0: &mut aftermath::storage::StorageStateV1
	)
	{
		abort 0
	}

	fun sorting_key(
		_arg0: &mut sui_system::sui_system::SuiSystemState,
		_arg1: sui::object::ID,
		_arg2: &mut u64,
		_arg3: u64,
		_arg4: &sui::tx_context::TxContext
	): u64
	{
		abort 0
	}

	fun borrow_state(
		_arg0: &aftermath::storage::Storage
	): &aftermath::storage::StorageStateV1
	{
		abort 0
	}

	fun borrow_state_mut(
		_arg0: &mut aftermath::storage::Storage
	): &mut aftermath::storage::StorageStateV1
	{
		abort 0
	}

	fun is_pool_empty(
		_arg0: &aftermath::storage::StorageStateV1,
		_arg1: sui::object::ID
	): bool
	{
		abort 0
	}

	fun register_staking_pool(
		_arg0: &mut aftermath::storage::StorageStateV1,
		_arg1: sui::object::ID,
		_arg2: &mut sui::tx_context::TxContext
	): bool
	{
		abort 0
	}

	fun unregister_staking_pool(
		_arg0: &mut aftermath::storage::StorageStateV1,
		_arg1: sui::object::ID
	): bool
	{
		abort 0
	}

	fun unstake_from_pool(
		_arg0: &mut aftermath::storage::StorageStateV1,
		_arg1: &mut sui_system::sui_system::SuiSystemState,
		_arg2: sui::object::ID,
		_arg3: u64,
		_arg4: u64,
		_arg5: u64,
		_arg6: &mut u64,
		_arg7: &mut sui::tx_context::TxContext
	): sui::balance::Balance<sui::sui::SUI>
	{
		abort 0
	}


}