module stwisp::stwisp_protocol {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use std::option::{Self, Option};

    use stwisp::stwisp::{Self, STWISP};

    struct StWISPProtocol has key, store {
        id: UID,
        staked_balance: u64,
        sui: Balance<SUI>,
        stwisp_treasury: Option<TreasuryCap<STWISP>>
    }

    fun init(ctx: &mut TxContext) {
        let protocol = StWISPProtocol {
            id: object::new(ctx),
            staked_balance: 1_000_000_000_000_000,
            sui: balance::zero<SUI>(),
            stwisp_treasury: option::none()
        };

        transfer::public_share_object(protocol);
    }

    public entry fun initialize(protocol: &mut StWISPProtocol, stwisp_treasury: TreasuryCap<STWISP>) {
        option::fill(&mut protocol.stwisp_treasury, stwisp_treasury);
    }

    public entry fun request_stake(
        protocol: &mut StWISPProtocol, 
        sui: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let stwisp = request_stake_non_entry(protocol, sui, ctx);
        transfer::public_transfer(stwisp, tx_context::sender(ctx));
    }

    public fun request_stake_non_entry (
        protocol: &mut StWISPProtocol, 
        sui: Coin<SUI>,
        ctx: &mut TxContext
    ): Coin<STWISP> {
        let sui_amount = coin::value(&sui);
        let staked_balance = protocol.staked_balance;
        protocol.staked_balance = staked_balance + sui_amount;

        balance::join(&mut protocol.sui, coin::into_balance(sui));

        coin::mint<STWISP>(option::borrow_mut(&mut protocol.stwisp_treasury), sui_amount, ctx)
    }

    public fun get_staked_balance(protocol: &StWISPProtocol): u64 {
        protocol.staked_balance
    }

    public entry fun set_staked_balance(protocol: &mut StWISPProtocol, staked_balance: u64) {
        protocol.staked_balance = staked_balance;
    }

    public entry fun mint_for_testing(
        protocol: &mut StWISPProtocol, 
        amount: u64, 
        recipient: address,
        ctx: &mut TxContext
    ) {
        stwisp::mint_for_testing(option::borrow_mut(&mut protocol.stwisp_treasury), amount, recipient, ctx);
    }

    public fun mint_for_testing_non_entry(
        protocol: &mut StWISPProtocol, 
        amount: u64, 
        ctx: &mut TxContext
    ): Coin<STWISP> {
        stwisp::mint_for_testing_non_entry(option::borrow_mut(&mut protocol.stwisp_treasury), amount, ctx)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}

#[test_only]
module stwisp::stwisp_test {
    use stwisp::stwisp::{Self, STWISP};
    use stwisp::stwisp_protocol::{Self, StWISPProtocol};
    use sui::test_scenario::{Self as test, Scenario, ctx, next_tx};
    use sui::test_utils::{assert_eq, create_one_time_witness};
    use sui::coin::{Self, TreasuryCap};
    use sui::sui::SUI;

    #[test]
    fun test_stake() {
        let test = scenario();
        test_stake_(&mut test);
        test::end(test);
    }

    public fun test_init_package_(test: &mut Scenario) {
        let (owner, _, _) = people();

        next_tx(test, owner);
        {
            stwisp::init_for_testing(create_one_time_witness<STWISP>(), ctx(test));
            stwisp_protocol::init_for_testing(ctx(test));
        };

        next_tx(test, owner);
        {
            let stwisp_treasury = test::take_from_sender<TreasuryCap<STWISP>>(test);
            let protocol = test::take_shared<StWISPProtocol>(test);

            stwisp_protocol::initialize(&mut protocol, stwisp_treasury);

            test::return_shared(protocol);
        };
    }

    fun test_stake_(test: &mut Scenario) {
        let (_, user, _) = people();

        test_init_package_(test);

        next_tx(test, user);
        {
            let protocol = test::take_shared<StWISPProtocol>(test);
            let sui = coin::mint_for_testing<SUI>(1_000_000_000_000_000, ctx(test));
            let stwisp = stwisp_protocol::request_stake_non_entry(&mut protocol, sui, ctx(test));

            test::return_shared(protocol);
            
            assert_eq(coin::burn_for_testing<STWISP>(stwisp), 1_000_000_000_000_000);
        }
    }

    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address) { (@0xBEEF, @0x1337, @0x1234) }
}