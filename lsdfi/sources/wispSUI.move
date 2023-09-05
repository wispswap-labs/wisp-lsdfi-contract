module wisp_lsdfi::wispSUI {
    use std::option;
    use std::ascii;
    use sui::url;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self};
    use sui::transfer;

    struct WISPSUI has drop {}

    fun init(wispSUI: WISPSUI, ctx: &mut TxContext) {
        let (wispSUI_treasury_cap, wispSUI_metadata) = coin::create_currency (
            wispSUI,
            9,
            b"wispSUI",
            b"wispSUI",
            b"",
            option::some<url::Url>(url::new_unsafe(ascii::string(b""))),
            ctx
        );

        transfer::public_transfer(wispSUI_treasury_cap, tx_context::sender(ctx));
        transfer::public_transfer(wispSUI_metadata, tx_context::sender(ctx));
    }

    #[test_only]
    public fun init_for_testing(wispSUI: WISPSUI, ctx: &mut TxContext) {
        init(wispSUI, ctx);
    }
}