module wisp_lsdfi::lsdfi_errors {
    public fun LSTNotSupport(): u64 {0} 
    public fun AggregatorLSTNotSupport(): u64 {1} 
    public fun NotEnoughBalance(): u64 {2}
    public fun StatusAlreadySet(): u64 {3}
    public fun AggregatorResultNotSet(): u64 {4}
    public fun AggregatorResultTooOld(): u64 {5}
    public fun VectorLengthNotEqual(): u64 {6}
    public fun ReceiptTokenEmpty(): u64 {7}
    public fun ReceiptNotEmpty(): u64 {8}
}