module wisp_lsdfi::math {
    use std::vector;
    use wisp_lsdfi::utils;
    use wisp_lsdfi::lsdfi_errors;

    // Calculate square Euclidean distance between first and second
    public fun cal_diff( 
        first: &vector<u256>,
        second: &vector<u256>
    ): u256 {
        assert!(vector::length(first) == vector::length(second), lsdfi_errors::VectorLengthNotEqual());

        let square_diff: u256 = 0;

        let index = 0;
        while (index < vector::length(first)){
            let first_value = *vector::borrow(first, index);
            let second_value = *vector::borrow(second, index);
            
            square_diff = square_diff + square_u256(sub_u256(first_value, second_value));
            index = index + 1;
        };

        sqrt_u256(square_diff) // square_diff always < 2^128 since normalized factor is < 2^64
    }

    public fun normalize_weight(
        weights: &vector<u256>,
        total_weights: u256 // input total weights to reduce loop since it 
    ): vector<u256> {
        let normalized_weights = vector::empty<u256>();
        
        let index = 0;
        while (index < vector::length(weights)) {
            let weight = *vector::borrow(weights, index);
            if (weight == 0) {
                vector::push_back(&mut normalized_weights, 0);
            } else {
                vector::push_back(&mut normalized_weights, *vector::borrow(weights, index) * utils::normalize_factor_u256() / total_weights);
            };
            index = index + 1;
        };

        normalized_weights
    }

    public fun sub_u256(x: u256, y: u256): u256 {
        if (x > y) {
            x - y
        } else {
            y - x
        }
    }

    public fun square_u256(
        value: u256
    ): u256 {
        value * value
    }

    // use for u128 only
    public fun sqrt_u256(x: u256): u256 {
        let bit = 1u256 << 128;
        let res = 0u256;

        while (bit != 0) {
            if (x >= res + bit) {
                x = x - (res + bit);
                res = (res >> 1) + bit;
            } else {
                res = res >> 1;
            };
            bit = bit >> 2;
        };

        res
    }
}