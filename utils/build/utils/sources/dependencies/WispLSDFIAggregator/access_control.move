module wisp_lsdfi_aggregator::access_control {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};
    use sui::event;
    
    friend wisp_lsdfi_aggregator::aggregator;

    struct AdminCap has key, store {
        id: UID,
    }

    struct OperatorCap has key, store {
        id: UID,
    }

    // Events 
    struct AdminCapCreated has copy, drop {
        admin_cap: ID
    }

    struct OperatorCapCreated has copy, drop {
        operator_cap: ID
    }

    public (friend) fun create_admin_cap (ctx: &mut TxContext): AdminCap {
        let cap = AdminCap {
            id: object::new(ctx),
        };

        event::emit(AdminCapCreated{admin_cap: object::uid_to_inner(&cap.id)});

        cap
    }

    public fun create_operator_cap (
        _: &AdminCap,
        ctx: &mut TxContext,
    ): OperatorCap {
        let cap = OperatorCap {
            id: object::new(ctx),
        };

        event::emit(OperatorCapCreated{operator_cap: object::uid_to_inner(&cap.id)});

        cap
    }
}