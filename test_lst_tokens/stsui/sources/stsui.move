module stsui::stsui {
    use std::option;
    use std::ascii;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url;

    struct STSUI has drop {}

    fun init(witness: STSUI, ctx: &mut TxContext) {
        let (treasury, coin_metadata) = coin::create_currency (
            witness,
            9,
            b"StSui",
            b"StSui",
            b"StSui",
            option::some<url::Url>(url::new_unsafe(ascii::string(b""))),
            ctx
        );

        transfer::public_freeze_object(coin_metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }

    public entry fun mint_for_testing(treasury: &mut TreasuryCap<STSUI>, amount: u64, recipient: address, ctx: &mut TxContext) {
        transfer::public_transfer(coin::mint(treasury, amount, ctx), recipient)
    }

    public fun mint_for_testing_non_entry(treasury: &mut TreasuryCap<STSUI>, amount: u64, ctx: &mut TxContext): Coin<STSUI> {
        coin::mint(treasury, amount, ctx)
    }

    public entry fun transfer(c: coin::Coin<STSUI>, recipient: address) {
        transfer::public_transfer(c, recipient)
    }

    #[test_only]
    public fun init_for_testing(witness: STSUI, ctx: &mut TxContext) {
        init(witness, ctx)
    }
}