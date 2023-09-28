module volo::cert {
    use sui::object::UID;
    use sui::balance::Supply;
    struct CERT has drop {}
    
    struct Metadata<T> has store, key {
        id: UID,
        version: u64,
        total_supply: Supply<T>
    }
}