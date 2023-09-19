module wisp_farm::utils {
    use sui::clock::{Self, Clock};

    const BOOST_PRECISION: u128 = 10_000; // ~ 100%
    const ACC_WISP_PRECISION: u128 = 1_000_000_000_000_000_000;
    const BOOST_RATE_PRECISION: u128 = 1_000_000_000;
    const BASIS_POINT: u64 = 10_000;

    public fun timestamp_sec(clock: &Clock): u64 {
        let timestamp_ms = clock::timestamp_ms(clock);
        ms_to_sec(timestamp_ms)
    }

    public fun ms_to_sec(timestamp_ms: u64): u64 {
        (timestamp_ms / 1000)
    }

    public fun acc_wisp_precision(): u128 {
        ACC_WISP_PRECISION
    }

    public fun boost_multiplier_precision(): u128 {
        BOOST_PRECISION
    }

    public fun basis_point(): u64 {
        BASIS_POINT
    }

    public fun basis_point_u32(): u32 {
        (BASIS_POINT as u32)
    }

    public fun basis_point_u128(): u128 {
        (BASIS_POINT as u128)
    }

    public fun  boost_rate_precision(): u128 {
        BOOST_RATE_PRECISION
    }
}