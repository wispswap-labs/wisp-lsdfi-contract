module stwisp::stwisp {
    use std::option;
    use std::ascii;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url;

    struct STWISP has drop {}

    fun init(witness: STWISP, ctx: &mut TxContext) {
        let (treasury, coin_metadata) = coin::create_currency (
            witness,
            9,
            b"stWisp",
            b"stWisp",
            b"stWisp",
            option::some<url::Url>(url::new_unsafe(ascii::string(b""))),
            ctx
        );

        transfer::public_freeze_object(coin_metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }

    public entry fun mint_for_testing(treasury: &mut TreasuryCap<STWISP>, amount: u64, recipient: address, ctx: &mut TxContext) {
        transfer::public_transfer(coin::mint(treasury, amount, ctx), recipient)
    }

    public fun mint_for_testing_non_entry(treasury: &mut TreasuryCap<STWISP>, amount: u64, ctx: &mut TxContext): Coin<STWISP> {
        coin::mint(treasury, amount, ctx)
    }

    public entry fun transfer(c: coin::Coin<STWISP>, recipient: address) {
        transfer::public_transfer(c, recipient)
    }

    #[test_only]
    public fun init_for_testing(witness: STWISP, ctx: &mut TxContext) {
        init(witness, ctx)
    }
}