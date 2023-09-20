module wisp_token::wisp {
    use std::option;
    use std::ascii;
    use sui::url;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self};
    use sui::transfer;

    struct WISP has drop {} // xWisp token

    fun init(wisp: WISP, ctx: &mut TxContext) {
        let (wisp_treasury_cap, wisp_metadata) = coin::create_currency (
            wisp,
            9,
            b"WISP",
            b"Wisp",
            b"",
            option::some<url::Url>(url::new_unsafe(ascii::string(b""))),
            ctx
        );

        transfer::public_transfer(wisp_treasury_cap, tx_context::sender(ctx));
        transfer::public_transfer(wisp_metadata, tx_context::sender(ctx));
    }

    #[test_only]
    public fun init_for_testing(wisp: WISP, ctx: &mut TxContext) {
        init(wisp, ctx);
    }
}