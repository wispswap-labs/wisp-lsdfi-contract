#[allow(unused_variable, unused_use, unused_function, unused_field)]
module haedal::vault {

    use sui::balance::{Self, Balance};
    use sui::tx_context::{TxContext};
    use sui::object::{Self, UID};


    friend haedal::staking;


    struct Vault<phantom T> has key, store {
        id: UID,
        cache_pool: Balance<T>,
    }

    public(friend) fun new<T>(ctx: &mut TxContext) : Vault<T> {
        Vault {
            id: object::new(ctx),
            cache_pool: balance::zero(),
        }
    }

    public(friend) fun deposit<T>(vault: &mut Vault<T>, input: Balance<T>) {
        abort 0
    }

    public(friend) fun withdraw<T>(vault: &mut Vault<T>, amount: u64) : Balance<T> {
        abort 0
    }

    public(friend) fun withdraw_all<T>(vault: &mut Vault<T>) : Balance<T> {
        abort 0
    }

    public fun vault_amount<T>(vault: &Vault<T>) : u64 {
        abort 0
    }

}
