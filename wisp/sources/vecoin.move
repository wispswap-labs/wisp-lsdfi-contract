module wisp_token::vecoin {
    use std::option::{Option};
    use sui::url::{Url};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, CoinMetadata};
    use sui::transfer;
    use sui::balance::{Self, Balance, Supply};
    use sui::object::{Self, UID};
    use std::vector;

    /// A type passed to create_supply is not a one-time witness.
    const EBadWitness: u64 = 0;
    /// Invalid arguments are passed to a function.
    const EInvalidArg: u64 = 1;
    /// Trying to split a coin more times than its balance allows.
    const ENotEnough: u64 = 2;

    struct ControllerCap<phantom T> has key, store {
        id: UID,
    }

    struct ModifyCap<phantom T> has key, store {
        id: UID,
    }

    // Vote-escrowed, non-transferable token
    struct VeCoin<phantom T> has key {
        id: UID,
        balance: Balance<T>
    }

    struct VeTreasuryCap<phantom T> has key, store {
        id: UID,
        total_supply: Supply<T>
    }

    /// Create a new currency type `T` as and return the `VeTreasuryCap` for
    /// `T` to the caller. Can only be called with a `one-time-witness`
    /// type, ensuring that there's only one `TreasuryCap` per `T`.
    public fun create_currency<T: drop>(
        witness: T,
        decimals: u8,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        icon_url: Option<Url>,
        ctx: &mut TxContext
    ): (VeTreasuryCap<T>, CoinMetadata<T>, ControllerCap<T>) {
        // Make sure there's only one instance of the type T
        assert!(sui::types::is_one_time_witness(&witness), EBadWitness);

        let (treasury, metadata) = coin::create_currency(
            witness, 
            decimals, 
            symbol, 
            name, 
            description, 
            icon_url, 
            ctx
        );

        let supply = coin::treasury_into_supply(treasury);

        let ve_treasury = VeTreasuryCap {
            id: object::new(ctx),
            total_supply: supply
        };

        let controller_cap = ControllerCap<T> {
            id: object::new(ctx)
        };
        
        (ve_treasury, metadata, controller_cap)
    }

    public entry fun create_and_transfer_modify_cap<T>(controller: &ControllerCap<T>, ctx: &mut TxContext){
        let modify_cap = create_modify_cap(controller, ctx);
        transfer::transfer(modify_cap, tx_context::sender(ctx));
    }

    public fun create_modify_cap<T>(_: &ControllerCap<T>, ctx: &mut TxContext): ModifyCap<T> {
        ModifyCap {
            id: object::new(ctx)
        }
    }

    public fun total_supply<T>(cap: &VeTreasuryCap<T>): u64 {
        balance::supply_value(&cap.total_supply)
    }

    /// Get mutable reference to the treasury's `Supply`.
    public fun supply_mut<T>(treasury: &mut VeTreasuryCap<T>): &mut Supply<T> {
        &mut treasury.total_supply
    }

    /// Get immutable reference to the treasury's `Supply`.
    public fun supply_immut<T>(treasury: &VeTreasuryCap<T>): &Supply<T> {
        &treasury.total_supply
    }

    // === Balance <-> VeCoin accessors and type morphing ===

    /// Public getter for the coin's value
    public fun value<T>(self: &VeCoin<T>): u64 {
        balance::value(&self.balance)
    }

    /// Get immutable reference to the balance of a coin.
    public fun balance<T>(_: &ModifyCap<T>, coin: &VeCoin<T>): &Balance<T> {
        &coin.balance
    }

    /// Get a mutable reference to the balance of a coin.
    public fun balance_mut<T>(_: &ModifyCap<T>, coin: &mut VeCoin<T>): &mut Balance<T> {
        &mut coin.balance
    }

    /// Wrap a balance into a VeCoin.
    public fun from_balance<T>(_: &ModifyCap<T>, balance: Balance<T>, ctx: &mut TxContext): VeCoin<T> {
        VeCoin { id: object::new(ctx), balance }
    }

    /// Destruct a VeCoin wrapper and keep the balance.
    public fun into_balance<T>(_: &ModifyCap<T>, coin: VeCoin<T>): Balance<T> {
        let VeCoin { id, balance } = coin;
        object::delete(id);
        balance
    }

    /// Take a `VeCoin` worth of `value` from `Balance`.
    /// Aborts if `value > balance.value`
    public fun take<T>(
        modify_cap: &ModifyCap<T>, balance: &mut Balance<T>, value: u64, ctx: &mut TxContext,
    ): VeCoin<T> {
        from_balance(modify_cap, balance::split(balance, value), ctx)
    }

    /// Put a `VeCoin<T>` to the `Balance<T>`.
    public fun put<T>(modify_cap: &ModifyCap<T>, balance: &mut Balance<T>, coin: VeCoin<T>) {
        balance::join(balance, into_balance(modify_cap, coin));
    }

    // === Base VeCoin functionality ===

    /// Transfer a coin `coin` to `recipient`.
    /// Restrict to ModifyCap owner
    public fun transfer<T>(_: &ModifyCap<T>, coin: VeCoin<T>, recipient: address) {
        transfer::transfer(coin, recipient);
    }

    /// Consume the coin `c` and add its value to `self`.
    /// Aborts if `c.value + self.value > U64_MAX`
    public fun join<T>(_: &ModifyCap<T>, self: &mut VeCoin<T>, c: VeCoin<T>) {
        let VeCoin { id, balance } = c;
        object::delete(id);
        balance::join(&mut self.balance, balance);
    }
    
    /// Split coin `self` to two coins, one with balance `split_amount`,
    /// and the retestneting balance is left is `self`.
    public fun split<T>(
        modify_cap: &ModifyCap<T>, self: &mut VeCoin<T>, split_amount: u64, ctx: &mut TxContext
    ): VeCoin<T> {
        take(modify_cap,&mut self.balance, split_amount, ctx)
    }

    /// Split coin `self` into `n - 1` coins with equal balances. The retestnetder is left in
    /// `self`. Return newly created coins.
    public fun divide_into_n<T>(
        modify_cap: &ModifyCap<T>, self: &mut VeCoin<T>, n: u64, ctx: &mut TxContext
    ): vector<VeCoin<T>> {
        assert!(n > 0, EInvalidArg);
        assert!(n <= value(self), ENotEnough);

        let vec = vector::empty<VeCoin<T>>();
        let i = 0;
        let split_amount = value(self) / n;
        while ({
            spec {
                invariant i <= n-1;
                invariant self.balance.value == old(self).balance.value - (i * split_amount);
                invariant ctx.ids_created == old(ctx).ids_created + i;
            };
            i < n - 1
        }) {
            vector::push_back(&mut vec, split(modify_cap, self, split_amount, ctx));
            i = i + 1;
        };
        vec
    }

    /// Make any VeCoin with a zero value. Useful for placeholding
    /// bids/payments or preemptively making empty balances.
    public fun zero<T>(ctx: &mut TxContext): VeCoin<T> {
        VeCoin { id: object::new(ctx), balance: balance::zero() }
    }

    /// Destroy a coin with value zero
    public fun destroy_zero<T>(c: VeCoin<T>) {
        let VeCoin { id, balance } = c;
        object::delete(id);
        balance::destroy_zero(balance)
    }

    /// Create a coin worth `value`. and increase the total supply
    /// in `cap` accordingly.
    public fun mint<T>(
        cap: &mut VeTreasuryCap<T>, value: u64, ctx: &mut TxContext,
    ): VeCoin<T> {
        VeCoin {
            id: object::new(ctx),
            balance: balance::increase_supply(&mut cap.total_supply, value)
        }
    }

    /// Mint some amount of T as a `Balance` and increase the total
    /// supply in `cap` accordingly.
    /// Aborts if `value` + `cap.total_supply` >= U64_MAX
    public fun mint_balance<T>(
        cap: &mut VeTreasuryCap<T>, value: u64
    ): Balance<T> {
        balance::increase_supply(&mut cap.total_supply, value)
    }

    /// Destroy the coin `c` and decrease the total supply in `cap`
    /// accordingly.
    public entry fun burn<T>(cap: &mut VeTreasuryCap<T>, c: VeCoin<T>): u64 {
        let VeCoin { id, balance } = c;
        object::delete(id);
        balance::decrease_supply(&mut cap.total_supply, balance)
    }

    // === Test-only code ===

    #[test_only]
    /// Mint vecoins of any type for (obviously!) testing purposes only
    public fun mint_for_testing<T>(value: u64, ctx: &mut TxContext): VeCoin<T> {
        VeCoin { id: object::new(ctx), balance: balance::create_for_testing(value) }
    }

    #[test_only]
    /// Burn vecoins of any type for testing purposes only
    public fun burn_for_testing<T>(coin: VeCoin<T>): u64 {
        let VeCoin { id, balance } = coin;
        object::delete(id);
        balance::destroy_for_testing(balance)
    }

    #[test_only]
    /// Destruct a VeCoin wrapper and keep the balance for testing purposes only
    public fun into_balance_for_testing<T>(coin: VeCoin<T>): Balance<T> {
        let VeCoin { id, balance } = coin;
        object::delete(id);
        balance
    }

    #[test_only]
    /// Create a ModifyCap with specific type for testing purposes only
    public fun create_modify_cap_for_testing<T>(ctx: &mut TxContext): ModifyCap<T> {
        ModifyCap { id: object::new(ctx) }
    }
}