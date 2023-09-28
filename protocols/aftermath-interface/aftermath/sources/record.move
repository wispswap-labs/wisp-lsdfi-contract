module aftermath::record {
	struct PendingUnstakeRecord has drop, store {
		requester: std::option::Option<address>,
		afsui_amount: u64,
		afsui_id: sui::object::ID
	}

	public(friend) fun new(
		_arg0: std::option::Option<address>,
		_arg1: u64,
		_arg2: sui::object::ID
	): aftermath::record::PendingUnstakeRecord
	{
		abort 0
	}

	public(friend) fun requester(
		_arg0: &aftermath::record::PendingUnstakeRecord
	): std::option::Option<address>
	{
		abort 0
	}

	public(friend) fun afsui_amount(
		_arg0: &aftermath::record::PendingUnstakeRecord
	): u64
	{
		abort 0
	}

	public(friend) fun afsui_id(
		_arg0: &aftermath::record::PendingUnstakeRecord
	): sui::object::ID
	{
		abort 0
	}


}