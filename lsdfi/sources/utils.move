module wisp_lsdfi::utils {
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::pay;
    use sui::tx_context::{Self, TxContext};
    use std::vector;

    public fun extract_coin<T>(coins: vector<Coin<T>>, amount: u64, ctx: &mut TxContext): Coin<T> {
        let merged_coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coin, coins);

        let coin = coin::split(&mut merged_coin, amount, ctx);
        // transfer back the remainder if non zero.
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, tx_context::sender(ctx));
        } else {
            coin::destroy_zero(merged_coin);
        };
        coin
    }
}