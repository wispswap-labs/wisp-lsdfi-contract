module stsui::stsui_protocol {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{TxContext};

    use stsui::stsui::STSUI;

    struct StSUIProtocol has key, store {
        id: UID,
        staked_balance: u64,
    }

    fun init(ctx: &mut TxContext) {
        let protocol = StSUIProtocol {
            id: object::new(ctx),
            staked_balance: 1_000_000_000_000_000,
        };

        transfer::public_share_object(protocol);
    }

    public fun get_staked_balance(protocol: &StSUIProtocol): u64 {
        protocol.staked_balance
    }

    public fun set_staked_balance(protocol: &mut StSUIProtocol, staked_balance: u64) {
        protocol.staked_balance = staked_balance;
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}