module wisp::pool_utils{
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use std::type_name::{Self, TypeName};
    
    use wisp::comparator::{Self, Result};
    use wisp::math_utils;

    // The integer scaling setting for fees calculation.
    const FEE_SCALING: u256 = 10000;
    // For when someone try to add zero liquidity
    const EZeroAmount: u64 = 501;
    
    // For when liquidity pool is empty
    const EReservesEmpty: u64 = 603;

    // give some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    public fun quote(amount_A: u64, reserve_A: u64, reserve_B: u64): u64 {
        assert!(amount_A > 0, EZeroAmount);
        assert!(reserve_A > 0 && reserve_B > 0, EReservesEmpty);
        let return_value: u128 = (amount_A as u128) * (reserve_B as u128) / (reserve_A as u128);
        (return_value as u64)
    }

    // Calculate the output amount minus the fee 
    public fun get_input_price(
        input_amount: u64, input_reserve: u64, output_reserve: u64, fee_percent: u64
    ): u64 {
        // up casts
        let (
            input_amount,
            input_reserve,
            output_reserve,
            fee_percent
        ) = (
            (input_amount as u256),
            (input_reserve as u256),
            (output_reserve as u256),
            (fee_percent as u256)
        );

        let input_amount_with_fee = input_amount * (FEE_SCALING - fee_percent);
        let numerator = input_amount_with_fee * output_reserve;
        let denominator = (input_reserve * FEE_SCALING) + input_amount_with_fee;

        (numerator / denominator as u64)
    }

    // Calculate the input amount minus the fee 
    public fun get_output_price(
        out_amount: u64, input_reserve: u64, output_reserve: u64, fee_percent: u64
    ): u64 {
        // up casts
        let (
            out_amount,
            input_reserve,
            output_reserve,
            fee_percent
        ) = (
            (out_amount as u256),
            (input_reserve as u256),
            (output_reserve as u256),
            (fee_percent as u256)
        );

        let numerator = input_reserve * out_amount * FEE_SCALING;
        let denominator = (output_reserve - out_amount) * (FEE_SCALING - fee_percent);

        ((numerator / denominator as u64) + 1)
    }

    public fun get_optimal_zap_in_amount(input_amount: u64, input_reserve: u64): u64 {
        let input_amount_u256 = (input_amount as u256);
        let input_reserve_u256 = (input_reserve as u256);

        (((math_utils::sqrt_u256(input_reserve_u256 
            * (input_amount_u256 * 3988000 + input_reserve_u256 * 3988009)) 
            - input_reserve_u256 * 1997) / 1994) 
            as u64)
    }

    // check if token pair is sort
    public fun sort_token_type(type_F: &TypeName, type_S: &TypeName): Result {
        comparator::compare(type_name::borrow_string(type_F), type_name::borrow_string(type_S))
    }

    // return TypeName of two type
    public fun get_type<F, S>(): (TypeName, TypeName) {
        (type_name::get<F>(), type_name::get<S>())
    }

    public fun get_triple_type<F, S, T>(): (TypeName, TypeName, TypeName) {
        (type_name::get<F>(), type_name::get<S>(), type_name::get<T>())
    }

    public fun execute_return_token<T>(token: Coin<T>, ctx: &mut TxContext) {
        if(coin::value(&token) > 0) {
            transfer::public_transfer(token, tx_context::sender(ctx));
        } else {
            coin::destroy_zero(token);
        };
    }
}