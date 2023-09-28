#[allow(unused_field)]
module wisp_lsdfi_aggregator::aggregator {
    use std::type_name::{Self, TypeName};
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_set::{Self, VecSet};
    use sui::clock::{Self, Clock};
    use sui::event;

    use std::option::{Self, Option};

    use wisp_lsdfi_aggregator::access_control::{Self, AdminCap, OperatorCap};
    use wisp_lsdfi_aggregator::errors;
    
    struct Aggregator has key, store {
        id: UID,
        lst_names: VecSet<TypeName>,
        total_staked_sui: Table<TypeName, Option<Result>>,
        version: u64
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
        lst_name: TypeName,
        status: bool,
    }

    struct ResultUpdated has copy, drop {
        lst_name: TypeName,
        result: Result,
    }

    struct RiskCoefficientUpdated has copy, drop {
        lst_name: TypeName,
        risk_coefficient: u64,
    }

    fun init(ctx: &mut TxContext) {
        let registry = Aggregator {
            id: object::new(ctx),
            lst_names: vec_set::empty(),
            total_staked_sui: table::new(ctx),
            version: 1
        };

        let admin_cap = access_control::create_admin_cap(ctx);
        let operator_cap = access_control::create_operator_cap(&admin_cap, ctx);
        
        transfer::share_object(registry);
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_transfer(operator_cap, tx_context::sender(ctx));
    }

    public entry fun set_support_lst<T>(
        _: &AdminCap,
        registry: &mut Aggregator,
        status: bool,
    ) {
        let name = type_name::get<T>();

        if (!status) {
            assert!(vec_set::contains(&registry.lst_names, &name), errors::StatusAlreadySet());
            vec_set::remove(&mut registry.lst_names, &name);
            table::remove(&mut registry.total_staked_sui, name);
        } else {
            assert!(!vec_set::contains(&registry.lst_names, &name), errors::StatusAlreadySet());
            vec_set::insert(&mut registry.lst_names, name);
            table::add(&mut registry.total_staked_sui, name, option::none());
        };

        event::emit(LSTStatusUpdated {
            lst_name: name,
            status: status
        });
    }

    public entry fun set_result<T>(
        operator: &OperatorCap,
        registry: &mut Aggregator,
        value: u64,
        clock: &Clock,
    ) {
        let name = type_name::get<T>();
        set_result_type_name(operator, registry, name, value, clock);
    }

    public fun set_result_type_name(
        _: &OperatorCap,
        registry: &mut Aggregator,
        name: TypeName,
        value: u64,
        clock: &Clock,
    ) {
        assert!(vec_set::contains(&registry.lst_names, &name), errors::LSTNotSupport());

        let result = Result {
            value: value,
            timestamp: clock::timestamp_ms(clock)
        };

        event::emit(ResultUpdated {
            lst_name: name,
            result: result
        });

        option::swap_or_fill(table::borrow_mut(&mut registry.total_staked_sui, name), result);
    }

    public fun get_list_name(registry: &Aggregator): &VecSet<TypeName> {
        &registry.lst_names
    }

    public fun supported_lst(registry: &Aggregator, name: TypeName): bool {
        vec_set::contains(&registry.lst_names, &name)
    }

    public fun get_result(registry: &Aggregator, name: TypeName): &Option<Result> {
        table::borrow(&registry.total_staked_sui, name)
    }

    public fun get_result_value(result: &Result): (u64, u64) {
        (result.value, result.timestamp)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}