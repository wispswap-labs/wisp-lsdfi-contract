module wisp::math_utils {
    public fun sqrt(y: u128): u128 {
        if (y < 4) {
            if (y == 0) {
                0u128
            } else {
                1u128
            }
        } else {
            let z = y;
            let x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            };
            z
        }
    }

    public fun sqrt_u256(y: u256): u256 {
        if (y < 4) {
            if (y == 0) {
                0u256
            } else {
                1u256
            }
        } else {
            let z = y;
            let x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            };
            z
        }
    }

    public fun min(a: u128, b: u128): u128 {
        if (a > b) b else a
    }

    public fun max_u64(a: u64, b: u64): u64 {
        if (a < b) b else a
    }

    public fun max(a: u128, b: u128): u128 {
        if (a < b) b else a
    }

    public fun pow(base: u128, exp: u8): u128 {
        let result = 1u128;
        loop {
            if (exp & 1 == 1) { result = result * base; };
            exp = exp >> 1;
            base = base * base;
            if (exp == 0u8) { break };
        };
        result
    }
}