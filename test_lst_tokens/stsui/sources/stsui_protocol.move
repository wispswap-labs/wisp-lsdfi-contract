module stsui::stsui_protocol {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use std::option::{Self, Option};

    use stsui::stsui::{Self, STSUI};

    struct StSUIProtocol has key, store {
        id: UID,
        staked_balance: u64,
        sui: Balance<SUI>,
        stsui_treasury: Option<TreasuryCap<STSUI>>
    }

    fun init(ctx: &mut TxContext) {
        let protocol = StSUIProtocol {
            id: object::new(ctx),
            staked_balance: 1_000_000_000_000_000,
            sui: balance::zero<SUI>(),
            stsui_treasury: option::none()
        };

        transfer::public_share_object(protocol);
    }

    public entry fun initialize(protocol: &mut StSUIProtocol, stsui_treasury: TreasuryCap<STSUI>) {
        option::fill(&mut protocol.stsui_treasury, stsui_treasury);
    }

    public entry fun request_stake(
        protocol: &mut StSUIProtocol, 
        sui: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let stsui = request_stake_non_entry(protocol, sui, ctx);
        transfer::public_transfer(stsui, tx_context::sender(ctx));
    }

    public fun request_stake_non_entry (
        protocol: &mut StSUIProtocol, 
        sui: Coin<SUI>,
        ctx: &mut TxContext
    ): Coin<STSUI> {
        let sui_amount = coin::value(&sui);
        let staked_balance = protocol.staked_balance;
        protocol.staked_balance = staked_balance + sui_amount;

        balance::join(&mut protocol.sui, coin::into_balance(sui));

        coin::mint<STSUI>(option::borrow_mut(&mut protocol.stsui_treasury), sui_amount, ctx)
    }

    public fun get_staked_balance(protocol: &StSUIProtocol): u64 {
        protocol.staked_balance
    }

    public entry fun set_staked_balance(protocol: &mut StSUIProtocol, staked_balance: u64) {
        protocol.staked_balance = staked_balance;
    }

    public entry fun mint_for_testing(
        protocol: &mut StSUIProtocol, 
        amount: u64, 
        recipient: address,
        ctx: &mut TxContext
    ) {
        stsui::mint_for_testing(option::borrow_mut(&mut protocol.stsui_treasury), amount, recipient, ctx);
    }

    public fun mint_for_testing_non_entry(
        protocol: &mut StSUIProtocol, 
        amount: u64, 
        ctx: &mut TxContext
    ): Coin<STSUI> {
        stsui::mint_for_testing_non_entry(option::borrow_mut(&mut protocol.stsui_treasury), amount, ctx)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}

#[test_only]
module stsui::stsui_test {
    use stsui::stsui::{Self, STSUI};
    use stsui::stsui_protocol::{Self, StSUIProtocol};
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
            stsui::init_for_testing(create_one_time_witness<STSUI>(), ctx(test));
            stsui_protocol::init_for_testing(ctx(test));
        };

        next_tx(test, owner);
        {
            let stsui_treasury = test::take_from_sender<TreasuryCap<STSUI>>(test);
            let protocol = test::take_shared<StSUIProtocol>(test);

            stsui_protocol::initialize(&mut protocol, stsui_treasury);
            test::return_shared(protocol);
        };
    }

    public fun test_stake_(test: &mut Scenario) {
        let (_, user, _) = people();

        test_init_package_(test);

        next_tx(test, user);
        {
            let protocol = test::take_shared<StSUIProtocol>(test);
            let sui = coin::mint_for_testing<SUI>(1_000_000_000_000_000, ctx(test));
            let stsui = stsui_protocol::request_stake_non_entry(&mut protocol, sui, ctx(test));

            test::return_shared(protocol);
            
            assert_eq(coin::burn_for_testing<STSUI>(stsui), 1_000_000_000_000_000);
        }
    }

    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address, address) { (@0xBEEF, @0x1337, @0x1234) }
}