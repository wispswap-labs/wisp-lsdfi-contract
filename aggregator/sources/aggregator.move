module aggregator::aggregator {
    use std::type_name::{Self, TypeName};
    use sui::object::{Self, UID, ID};
    use sui::object_table::{Self, ObjectTable};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_set::{Self, VecSet};
    use sui::clock::{Self, Clock};
    use sui::event;

    use aggregator::access_control::{Self, AdminCap, OperatorCap};
    use aggregator::errors;
    
    struct AggregatorRegistry has key, store {
        id: UID,
        aggregators: ObjectTable<TypeName, LSDAggregator>,
        lst_names: VecSet<TypeName>
    }

    struct LSDAggregator has key, store {
        id: UID,
        lst_name: TypeName,
        last_result: Result,

        // dynamic fields
        // b"history": AggregatorHistoryData,
    }

    struct Result has copy, store, drop {
        value: u64,
        timestamp: u64
    }

    // [SHARED]
    struct AggregatorHistoryData has key, store {
        id: UID,
        data: vector<Result>,
        history_write_idx: u64,
    }

    // Events
    struct LSTStatusUpdated has copy, drop {
        aggregator_id: ID,
        lst_name: TypeName,
        status: bool,
    }

    struct ResultUpdated has copy, drop {
        aggregator_id: ID,
        lst_name: TypeName,
        result: Result,
    }

    fun init(ctx: &mut TxContext) {
        let registry = AggregatorRegistry {
            id: object::new(ctx),
            aggregators: object_table::new(ctx),
            lst_names: vec_set::empty()
        };

        let admin_cap = access_control::create_admin_cap(ctx);
        let operator_cap = access_control::create_operator_cap(&admin_cap, ctx);
        
        transfer::share_object(registry);
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_transfer(operator_cap, tx_context::sender(ctx));
    }

    public entry fun set_support_lst<T>(
        _: &AdminCap,
        registry: &mut AggregatorRegistry,
        status: bool,
        ctx: &mut TxContext
    ) {
        let name = type_name::get<T>();
        let id: ID;

        if (!status) {
            assert!(vec_set::contains(&registry.lst_names, &name), errors::StatusAlreadySet());
            vec_set::remove(&mut registry.lst_names, &name);
            let aggregator = object_table::remove(&mut registry.aggregators, name);
            let LSDAggregator {id: uid, last_result: _, lst_name:_} = aggregator;
            id = object::uid_to_inner(&uid);
            object::delete(uid);
        } else {
            assert!(!vec_set::contains(&registry.lst_names, &name), errors::StatusAlreadySet());
            vec_set::insert(&mut registry.lst_names, name);
            let uid = object::new(ctx);
            id = object::uid_to_inner(&uid);
            let aggregator = LSDAggregator {
                id: uid,
                lst_name: name,
                last_result: Result {
                    value: 0,
                    timestamp: 0
                }
            };
            object_table::add(&mut registry.aggregators, name, aggregator);
        };

        event::emit(LSTStatusUpdated {
            aggregator_id: id,
            lst_name: name,
            status: status
        });
    }

    public entry fun set_result<T>(
        operator: &OperatorCap,
        registry: &mut AggregatorRegistry,
        value: u64,
        clock: &Clock,
    ) {
        let name = type_name::get<T>();
        set_result_type_name(operator, registry, name, value, clock);
    }

    public fun set_result_type_name(
        _: &OperatorCap,
        registry: &mut AggregatorRegistry,
        name: TypeName,
        value: u64,
        clock: &Clock,
    ) {
        assert!(vec_set::contains(&registry.lst_names, &name), errors::LSTNotSupported());
        let aggregator = object_table::borrow_mut(&mut registry.aggregators, name);
        aggregator.last_result = Result {
            value: value,
            timestamp: clock::timestamp_ms(clock)
        };

        event::emit(ResultUpdated {
            aggregator_id: object::uid_to_inner(&aggregator.id),
            lst_name: name,
            result: aggregator.last_result
        });
    }

    public fun get_list_name(registry: &AggregatorRegistry): &VecSet<TypeName> {
        &registry.lst_names
    }

    public fun get_aggregator(registry: &AggregatorRegistry, name: TypeName): &LSDAggregator {
        object_table::borrow(&registry.aggregators, name)
    }

    public fun get_aggregator_result(aggregator: &LSDAggregator): &Result {
        &aggregator.last_result
    }

    public fun get_result_value(result: &Result): (u64, u64) {
        (result.value, result.timestamp)
    }

    public fun get_aggregator_value(registry: &AggregatorRegistry, name: TypeName): (u64, u64){
        get_result_value(get_aggregator_result(get_aggregator(registry, name)))
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}