module wisp_lsdfi::utils {
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::pay;
    use sui::tx_context::{Self, TxContext};
    use std::vector;

    const NORMALIZE_FACTOR: u64 = 1_000_000_000_000_000_000;
    const SLOPE_DECIMALS: u128 = 1_000_000;
    const BASIS_POINTS: u64 = 10_000;

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

    public fun normalize_factor_u256(): u256 {
        (NORMALIZE_FACTOR as u256)
    }

    public fun basis_points(): u64 {
        BASIS_POINTS
    }

    public fun basis_points_u128(): u128 {
        (BASIS_POINTS as u128)
    }

    public fun basis_points_u256(): u256 {
        (BASIS_POINTS as u256)
    }

    public fun slope_decimals_u256(): u256 {
        (SLOPE_DECIMALS as u256)
    }

    public fun transfer_coin<T>(coin: Coin<T>, receipient: address) {
        if(coin::value(&coin) > 0) {
            transfer::public_transfer(coin, receipient);
        } else {
            coin::destroy_zero(coin);
        };
    }
}