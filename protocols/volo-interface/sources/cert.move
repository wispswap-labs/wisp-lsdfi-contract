module volo::cert {
    use sui::object::UID;
    use sui::balance::Supply;
    struct CERT has drop {
	    dummy_field: bool
    }
    struct Metadata<T> has store, key {
        id: UID,
        version: u64,
        total_supply: Supply<T>
    }
}