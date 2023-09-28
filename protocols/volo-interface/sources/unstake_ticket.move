module volo::unstake_ticket {
    use sui::object::UID;
    use sui::table::Table;

    struct Metadata has store, key {
        id: UID,
        version: u64,
        total_supply: u64,
        max_history_value: Table<u64, u64>
    }
}