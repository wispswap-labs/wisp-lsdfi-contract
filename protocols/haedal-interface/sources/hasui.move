#[allow(unused_variable, unused_use, unused_function, unused_field)]
module haedal::hasui {
    use std::option;
    use sui::coin::{Self};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self};

    friend haedal::staking;

    struct HASUI has drop {}

    fun init(_witness: HASUI, ctx: &mut TxContext) {
        abort 0
    }

    #[test_only]
    public fun init_stsui_for_test(ctx: &mut TxContext) {
        init(HASUI{}, ctx);
    }
}
