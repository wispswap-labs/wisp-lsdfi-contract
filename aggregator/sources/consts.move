module aggregator::consts {
    const RESULT_DECIMALS: u64 = 8;

    public fun decimals(): u64 {
        RESULT_DECIMALS
    }
}