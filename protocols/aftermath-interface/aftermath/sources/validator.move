module aftermath::validator {
	struct UnverifiedValidatorOperationCap has store, key {
		id: sui::object::UID,
		authorizer_validator_address: address
	}

	struct ValidatorOperationCap has drop {
		authorizer_validator_address: address
	}

	public(friend) fun new_unverified_validator_operation_cap(
		_arg0: address,
		_arg1: &mut sui::tx_context::TxContext
	): aftermath::validator::UnverifiedValidatorOperationCap
	{
		abort 0
	}

	public fun transfer_unverified_validator_operation_cap(
		_arg0: aftermath::validator::UnverifiedValidatorOperationCap,
		_arg1: address
	)
	{
		abort 0
	}

	public(friend) fun unverified_operation_cap_address(
		_arg0: &aftermath::validator::UnverifiedValidatorOperationCap
	): &address
	{
		abort 0
	}

	public(friend) fun new_from_unverified(
		_arg0: &aftermath::validator::UnverifiedValidatorOperationCap
	): aftermath::validator::ValidatorOperationCap
	{
		abort 0
	}

	public(friend) fun verified_operation_cap_address(
		_arg0: &aftermath::validator::ValidatorOperationCap
	): &address
	{
		abort 0
	}


}