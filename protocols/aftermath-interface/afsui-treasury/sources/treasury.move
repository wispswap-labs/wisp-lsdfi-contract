module afsui_treasury::treasury {
    use sui::object::UID;
    use sui::bag::Bag;
    struct Treasury has key {
        id: UID,
        version: u64,
        funds: Bag
    }
}