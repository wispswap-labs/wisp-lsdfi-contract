module wisp_token::vewisp {
    use std::option;
    use std::ascii;
    use sui::url;
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use wisp_token::vecoin;
    
    struct VEWISP has drop {} // veWisp token

    fun init(vewisp: VEWISP, ctx: &mut TxContext) {
        let (vewisp_treasury_cap, vewisp_metadata, controller_cap) = vecoin::create_currency(
            vewisp,
            9,
            b"veWISP",
            b"veWisp",
            b"",
            option::some<url::Url>(url::new_unsafe(ascii::string(b""))),
            ctx
        );

        transfer::public_transfer(vewisp_treasury_cap, tx_context::sender(ctx));
        transfer::public_transfer(vewisp_metadata, tx_context::sender(ctx));
        transfer::public_transfer(controller_cap, tx_context::sender(ctx));
    }

    #[test_only]
    public fun init_for_testing(vewisp: VEWISP, ctx: &mut TxContext) {
        init(vewisp, ctx);
    }
}