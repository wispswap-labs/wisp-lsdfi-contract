module afsui_referral::treasury {
    use sui::object::UID;
    use sui::bag::Bag;
    use sui::table::Table;
    struct ReferralVault has key {
        id: UID,
        version: u64,
        referrer_addresses: Table<address, address>,
        rebates: Table<address, Bag>
    }
}