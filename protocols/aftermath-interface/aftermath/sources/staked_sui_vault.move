module aftermath::staked_sui_vault {
    use sui::object::UID;
    struct StakedSuiVault has key {
        id: UID,
        version: u64
    }

    public fun total_sui_amount(vault: &StakedSuiVault) : u64 {
        abort 0
    }
}