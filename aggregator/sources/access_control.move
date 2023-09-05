module aggregator::access_control {
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    
    friend aggregator::aggregator;

    struct AdminCap has key, store {
        id: UID,
    }

    struct OperatorCap has key, store {
        id: UID,
    }

    public (friend) fun create_admin_cap (ctx: &mut TxContext): AdminCap {
        let cap = AdminCap {
            id: object::new(ctx),
        };

        cap
    }

    public fun create_operator_cap (
        _: &AdminCap,
        ctx: &mut TxContext,
    ): OperatorCap {
        let cap = OperatorCap {
            id: object::new(ctx),
        };

        cap
    }
}