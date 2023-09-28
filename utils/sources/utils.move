module utils::utils {
    use wisp_lsdfi::pool::{Self, LSDFIPoolRegistry};
    use wisp_lsdfi::wispSUI::{WISPSUI};
    use std::option;
    use std::ascii;
    use sui::coin::{Self, CoinMetadata};

    public entry fun set_name(
        pool: &LSDFIPoolRegistry,
        metadata: &mut CoinMetadata<WISPSUI>,
        url: ascii::String
    ) {
        let treasury = option::borrow(pool::wispSUI_treasury(pool));
        coin::update_icon_url(treasury, metadata, url)
    }

}