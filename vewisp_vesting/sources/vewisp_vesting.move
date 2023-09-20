module vewisp_vesting::vesting {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::pay;
    use sui::event;

    use std::option::{Self, Option};
    use std::vector;    
    // use std::debug;

    use wisp_token::vecoin::{Self, VeCoin, ModifyCap};
    use wisp_token::vewisp::{VEWISP};
    use wisp_token::wisp::{WISP};
    use wisp_vault::vault::{Self, TreasuryVault};

    const EInvalidInputLength: u64 = 1;
    const EInvalidMilestone: u64 = 2;
    const EZeroAmount: u64 = 3;
    const EInsufficientInputAmount: u64 = 4;
    const EUninitialized: u64 = 5;
    const EInvalidTimestamp: u64 = 6;
    const EInvalidEndMilestone: u64 = 7;
    const ENotTGE: u64 = 8;

    const BASIS_POINTS: u64 = 10000;

    struct ControllerCap has key, store {
        id: UID,
    }

    struct Milestone has copy, store, drop {
        locked_ms: u64,
        released_percent: u64,
    }

    struct VestingRegistry has key, store {
        id: UID,
        treasury_vault: Option<TreasuryVault>,
        milestones: vector<Milestone>,
        modify_cap: Option<ModifyCap<VEWISP>>,
    }

    struct VestingVeWisp has key, store {
        id: UID,
        vewisp: Balance<VEWISP>,
        lock_timestamp: u64,
    }

    //events
    struct VestingVeWispCreated has copy, drop {
        id: ID,
        vewisp: u64,
        lock_timestamp: u64,
    }

    struct VestingVeWispRedeemed has copy, drop {
        id: ID,
        vewisp: u64,
        redeemed_amount: u64,
        lock_period: u64,
    }

    struct EmergencyWithdrawal has copy, drop {
        id: ID,
        vewisp: u64,
    }
    
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            ControllerCap {
                id: object::new(ctx)
            },
            tx_context::sender(ctx),
        );

        transfer::share_object(
            VestingRegistry {
                id: object::new(ctx),
                treasury_vault: option::none(),
                milestones: vector::empty(),
                modify_cap: option::none(),
            }
        )
    }

    public entry fun initialize(
        _: &ControllerCap,
        vesting_registry: &mut VestingRegistry,
        treasury_vault: TreasuryVault,
        modify_cap: ModifyCap<VEWISP>,
        milestones_locked_ms: vector<u64>,
        milestones_released_percent: vector<u64>,
    ) {
        update_milestones_(vesting_registry, milestones_locked_ms, milestones_released_percent);

        option::fill(&mut vesting_registry.treasury_vault, treasury_vault);
        option::fill(&mut vesting_registry.modify_cap, modify_cap);
    }

    public entry fun update_milestones(
        _: &ControllerCap,
        vesting_registry: &mut VestingRegistry,
        milestones_locked_ms: vector<u64>,
        milestones_released_percent: vector<u64>,
    ) {
        update_milestones_(vesting_registry, milestones_locked_ms, milestones_released_percent);
    }

    fun update_milestones_(
        vesting_registry: &mut VestingRegistry,
        milestones_locked_ms: vector<u64>,
        milestones_released_percent: vector<u64>,
    ) {
        assert!(vector::length(&milestones_locked_ms) == vector::length(&milestones_released_percent) 
            && vector::length(&milestones_locked_ms) > 0, EInvalidInputLength);
        vesting_registry.milestones = vector::empty();

        vector::reverse(&mut milestones_locked_ms);
        vector::reverse(&mut milestones_released_percent);

        let last_locked_ms = 0;
        let last_released_percent = 0;
        while(vector::length(&milestones_locked_ms) > 0) {
            let locked_ms = vector::pop_back(&mut milestones_locked_ms);
            let released_percent = vector::pop_back(&mut milestones_released_percent);
            assert!(locked_ms > last_locked_ms && released_percent >= last_released_percent, EInvalidMilestone);

            vector::push_back(&mut vesting_registry.milestones, Milestone {
                locked_ms: locked_ms,
                released_percent: released_percent,
            });
            last_locked_ms = locked_ms;
            last_released_percent = released_percent;
        };

        assert!(last_released_percent == BASIS_POINTS, EInvalidEndMilestone);
    }

    public entry fun retake_treasury_vault(
        _: &ControllerCap,
        vesting_registry: &mut VestingRegistry,
        ctx: &mut TxContext,
    ) {
        let treasury_vault = option::extract(&mut vesting_registry.treasury_vault);
        transfer::public_transfer(
            treasury_vault,
            tx_context::sender(ctx),
        );
    }

    public entry fun retake_modify_cap(
        _: &ControllerCap,
        vesting_registry: &mut VestingRegistry,
        ctx: &mut TxContext,
    ) {
        let modify_cap = option::extract(&mut vesting_registry.modify_cap);
        transfer::public_transfer(
            modify_cap,
            tx_context::sender(ctx),
        );
    }

    public entry fun wisp_to_vewisp(
        vesting_registry: &mut VestingRegistry,
        wisps: vector<Coin<WISP>>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_tge_time(clock);
        only_initialized(vesting_registry);
        assert!(amount > 0, EZeroAmount);   
        let wisp: Coin<WISP> = coin::zero<WISP>(ctx);
        pay::join_vec(&mut wisp, wisps);
        assert!(coin::value(&wisp) >= amount, EInsufficientInputAmount);
        
        let burn_wisp = coin::split(&mut wisp, amount, ctx);
        vault::burn_wisp(option::borrow_mut(&mut vesting_registry.treasury_vault), burn_wisp);
        let vewisp_balance = vault::mint_vewisp(option::borrow_mut(&mut vesting_registry.treasury_vault), amount);
        let vewisp = vecoin::from_balance(option::borrow(&vesting_registry.modify_cap), vewisp_balance, ctx);
        vecoin::transfer(option::borrow(&vesting_registry.modify_cap), vewisp, tx_context::sender(ctx));

        execute_return_token(wisp, ctx);
    }
    
    public entry fun create_vesting_vewisp_nft(
        vesting_registry: &mut VestingRegistry,
        vewisps: vector<VeCoin<VEWISP>>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ){
        check_tge_time(clock);
        only_initialized(vesting_registry);
        assert!(amount > 0, EZeroAmount);
        let vewisp: VeCoin<VEWISP> = vecoin::zero<VEWISP>(ctx);
        join_vec_vewisp(option::borrow(&vesting_registry.modify_cap), &mut vewisp, vewisps);
        assert!(vecoin::value(&vewisp) >= amount, EInsufficientInputAmount);
        
        let vesting_vewisp = vecoin::split(option::borrow(&vesting_registry.modify_cap), &mut vewisp, amount, ctx);
        let vesting_vewisp_balance = vecoin::into_balance(option::borrow(&vesting_registry.modify_cap), vesting_vewisp);

        let id = object::new(ctx);
        
        event::emit(VestingVeWispCreated{
            id: object::uid_to_inner(&id),
            vewisp: balance::value(&vesting_vewisp_balance),
            lock_timestamp: clock::timestamp_ms(clock),
        });

        let vesting_vewisp_nft = VestingVeWisp {
            id,
            vewisp: vesting_vewisp_balance,
            lock_timestamp: clock::timestamp_ms(clock),
        };

        transfer::public_transfer(
            vesting_vewisp_nft,
            tx_context::sender(ctx),
        );

        execute_vewisp(option::borrow(&vesting_registry.modify_cap), vewisp, ctx);
    }

    public entry fun redeem_wisp(
        vesting_registry: &mut VestingRegistry,
        vesting_vewisp_nft: VestingVeWisp,
        clock: &Clock,
        ctx: &mut TxContext,
    ){
        only_initialized(vesting_registry);
        
        let redeem_amount = get_redeem_amount(
            &vesting_registry.milestones,
            balance::value(&vesting_vewisp_nft.vewisp),
            vesting_vewisp_nft.lock_timestamp,
            clock::timestamp_ms(clock),
        );
        
        assert!(redeem_amount > 0, EZeroAmount);

        let VestingVeWisp {id, vewisp, lock_timestamp} = vesting_vewisp_nft;

        let vewisp_amount = balance::value(&vewisp);
        let vewisp_coin = vecoin::from_balance(option::borrow(&vesting_registry.modify_cap), vewisp, ctx);
        vault::burn_vewisp(option::borrow_mut(&mut vesting_registry.treasury_vault), vewisp_coin);

        let wisp_balance = vault::mint_wisp(option::borrow_mut(&mut vesting_registry.treasury_vault), redeem_amount);
        let wisp = coin::from_balance(wisp_balance, ctx);
        transfer::public_transfer(
            wisp,
            tx_context::sender(ctx),
        );

        event::emit(VestingVeWispRedeemed {
            id: object::uid_to_inner(&id),
            vewisp: vewisp_amount,
            redeemed_amount: redeem_amount,
            lock_period: clock::timestamp_ms(clock) - lock_timestamp
        });
        
        object::delete(id);
    }

    public fun get_redeem_amount(
        milestones: &vector<Milestone>,
        locked_amount: u64,
        lock_timestamp: u64,
        current_timestamp: u64,
    ): u64{
        assert!(current_timestamp > lock_timestamp, EInvalidTimestamp);
        let locked_ms: u64 = current_timestamp - lock_timestamp;
        let first_milestone = *vector::borrow(milestones, 0);
        if (locked_ms < first_milestone.locked_ms) {
            0
        } else {
            let milestone_index = look_up_milestone(milestones, locked_ms);

            if (milestone_index == vector::length(milestones) - 1) {
                locked_amount
            } else {
                let milestone = *vector::borrow(milestones, milestone_index);
                let next_milestone = *vector::borrow(milestones, milestone_index + 1);

                let released_percent = milestone.released_percent + (next_milestone.released_percent - milestone.released_percent) * (locked_ms - milestone.locked_ms) / (next_milestone.locked_ms - milestone.locked_ms);
                let released_amount = locked_amount * released_percent / BASIS_POINTS;
                released_amount
            }
        }
    }
    
    // Binary search
    fun look_up_milestone(
        milestones: &vector<Milestone>,
        locked_ms: u64
    ): u64 {
        let left = 0;
        let right = vector::length(milestones) - 1;

        while(left < right) {
            let mid = (((left as u128) + (right as u128)) / 2 as u64);
            let milestone_ms = vector::borrow(milestones, mid).locked_ms;
            
            if (locked_ms > milestone_ms) {
                left = mid + 1;
            } else {
                right = mid;
            };
        };

        right
    }

    public entry fun emergency_withdraw_vewisp(
        vesting_registry: &VestingRegistry,
        vesting_vewisp_nft: VestingVeWisp,
        ctx: &mut TxContext,
    ){
        let VestingVeWisp {id, vewisp, lock_timestamp: _} = vesting_vewisp_nft;
        event::emit(EmergencyWithdrawal{
            id: object::uid_to_inner(&id),
            vewisp: balance::value(&vewisp),
        });
        object::delete(id);

        let return_vewisp = vecoin::from_balance(option::borrow(&vesting_registry.modify_cap), vewisp, ctx);
        execute_vewisp(option::borrow(&vesting_registry.modify_cap), return_vewisp, ctx);
    }

    public fun only_initialized(
        vesting_registry: &VestingRegistry,
    ) {
        assert!(option::is_some(&vesting_registry.treasury_vault)
            && option::is_some(&vesting_registry.modify_cap)
            && vector::length(&vesting_registry.milestones) > 0, EUninitialized);
    }

    public fun execute_return_token<T>(token: Coin<T>, ctx: &mut TxContext) {
        if(coin::value(&token) > 0) {
            transfer::public_transfer(token, tx_context::sender(ctx));
        } else {
            coin::destroy_zero(token);
        };
    }

    fun join_vec_vewisp(
        modify_cap: &ModifyCap<VEWISP>,
        self: &mut VeCoin<VEWISP>,
        vewisps: vector<VeCoin<VEWISP>>,
    ) {
        let (i, len) = (0, vector::length(&vewisps));
        while (i < len) {
            let coin = vector::pop_back(&mut vewisps);
            vecoin::join(modify_cap, self, coin);
            i = i + 1
        };
        // safe because we've drained the vector
        vector::destroy_empty(vewisps)
    }

    fun execute_vewisp(
        modify_cap: &ModifyCap<VEWISP>,
        vewisp: VeCoin<VEWISP>,
        ctx: &mut TxContext,
    ) {
        if(vecoin::value(&vewisp) > 0) {
            vecoin::transfer(modify_cap, vewisp, tx_context::sender(ctx));
        } else {
            vecoin::destroy_zero(vewisp);
        }
    }

    fun check_tge_time(
        clock: &Clock
    ) {
        assert!(clock::timestamp_ms(clock) >= vault::tge_time(), ENotTGE);
    }

    public fun get_milestones(
        vesting_registry: &VestingRegistry,
    ): &vector<Milestone> {
        &vesting_registry.milestones
    }

    public fun get_milestone_data(
        milestone: &Milestone,
    ): (u64, u64) {
        (milestone.locked_ms, milestone.released_percent)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}