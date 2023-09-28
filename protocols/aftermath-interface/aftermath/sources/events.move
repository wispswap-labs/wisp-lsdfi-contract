module aftermath::events {
	struct CreatedStakedSuiVaultEvent has copy, drop {
		staking_entity_id: sui::object::ID
	}

	struct StakedEvent has copy, drop {
		staker: address,
		validator: address,
		staked_sui_id: sui::object::ID,
		sui_id: sui::object::ID,
		sui_amount: u64,
		afsui_id: sui::object::ID,
		afsui_amount: u64,
		validator_fee: u64,
		referrer: std::option::Option<address>,
		epoch: u64,
		is_restaked: bool
	}

	struct UnstakeRequestedEvent has copy, drop {
		afsui_id: sui::object::ID,
		provided_afsui_amount: u64,
		requester: address,
		epoch: u64
	}

	struct UnstakedEvent has copy, drop {
		afsui_id: sui::object::ID,
		provided_afsui_amount: u64,
		sui_id: sui::object::ID,
		returned_sui_amount: u64,
		requester: std::option::Option<address>,
		epoch: u64
	}

	struct OneRoundOfEpochProcessingFinished has copy, drop {
		staking_entity_id: sui::object::ID,
		epoch: u64,
		is_epoch_processing: bool,
		is_pending_unstakes_processed: bool,
		is_unstaking_deque_sorted: bool
	}

	struct EpochWasChangedEvent has copy, drop {
		active_epoch: u64,
		total_sui_amount: u64,
		total_rewards_amount: u64,
		total_afsui_supply: u64
	}

	public(friend) fun emit_created_staked_sui_vault_event(
		_arg0: sui::object::ID
	)
	{
		abort 0
	}

	public(friend) fun emit_staked_event(
		_arg0: address,
		_arg1: address,
		_arg2: sui::object::ID,
		_arg3: sui::object::ID,
		_arg4: u64,
		_arg5: sui::object::ID,
		_arg6: u64,
		_arg7: u64,
		_arg8: std::option::Option<address>,
		_arg9: u64,
		_arg10: bool
	)
	{
		abort 0
	}

	public(friend) fun emit_unstake_requested_event(
		_arg0: sui::object::ID,
		_arg1: u64,
		_arg2: address,
		_arg3: u64
	)
	{
		abort 0
	}

	public(friend) fun emit_unstaked_event(
		_arg0: sui::object::ID,
		_arg1: u64,
		_arg2: sui::object::ID,
		_arg3: u64,
		_arg4: std::option::Option<address>,
		_arg5: u64
	)
	{
		abort 0
	}

	public(friend) fun emit_one_round_of_epoch_processing_finished_event(
		_arg0: sui::object::ID,
		_arg1: u64,
		_arg2: bool,
		_arg3: bool,
		_arg4: bool
	)
	{
		abort 0
	}

	public(friend) fun emit_epoch_was_changed_event(
		_arg0: u64,
		_arg1: u64,
		_arg2: u64,
		_arg3: u64
	)
	{
		abort 0
	}


}