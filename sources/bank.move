module blueprint::bank {
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::dynamic_field as df;

    //  Error codes
    const EIncorrectAmount: u64 = 0;

    public struct DepositEvent<phantom T> has copy, drop {
        deposit_id: u64,
        depositor: address,
        amount: u64,
    }

    public struct WithdrawEvent<phantom T> has copy, drop {
        deposit_id: u64,
        depositor: address,
        amount: u64,
    }

    // acts as a key for the deposited asset type
    public struct AssetType<phantom T> has copy, drop, store {}

    // no store ability to be able to share & avoid transfers
    public struct AssetBank has key {
        id: UID,
        total_deposits: u64,
        active_nfts: u64,
    }

    // no store ability for Receipt to avoid transfers
    public struct Receipt<phantom T> has key {
        id: UID,
        deposit_id: u64,
        depositor: address,
        amount: u64,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(AssetBank {
            id: object::new(ctx),
            total_deposits: 0,
            active_nfts: 0,
        });
    }

    public fun total_deposits(self: &AssetBank): u64 {
        self.total_deposits
    }

    public fun active_nfts(self: &AssetBank): u64 {
        self.active_nfts
    }

    public fun deposit<T>(bank: &mut AssetBank, coin: Coin<T>, ctx: &mut TxContext) {
        let bank_id = &mut bank.id;
        let asset = AssetType<T> {};
        let amount = coin.value();
        let depositor = ctx.sender();
        assert!(amount > 0, EIncorrectAmount);

        // add deposited coin to the bank
        if (df::exists_(bank_id, asset)) {
            let balance: &mut Coin<T> = df::borrow_mut(bank_id, asset);
            balance.join(coin);
        } else {
            df::add(bank_id, asset, coin);
        };

        // update bank stats
        bank.total_deposits = bank.total_deposits + 1;
        bank.active_nfts = bank.active_nfts + 1;

        // send receipt to depositor
        let deposit_id = bank.total_deposits;
        transfer::transfer(Receipt<T> {
            id: object::new(ctx),
            deposit_id,
            depositor,
            amount,
        }, ctx.sender());

        event::emit(DepositEvent<T> {
            deposit_id,
            depositor,
            amount,
        });
    }

    public fun withdraw<T>(bank: &mut AssetBank, receipt: Receipt<T>, ctx: &mut TxContext) {
        let bank_id = &mut bank.id;
        let asset = AssetType<T> {};
        let amount = receipt.amount;
        let depositor = receipt.depositor;

        // remove deposited coin from the bank
        let balance: &mut Coin<T> = df::borrow_mut(bank_id, asset);
        let coin = balance.split(amount, ctx);

        // update bank stats
        bank.active_nfts = bank.active_nfts - 1;

        // send coin to depositor
        transfer::public_transfer(coin, depositor);

        // delete receipt
        let Receipt<T> { id: receipt_id, deposit_id, depositor: _, amount: _ } = receipt;
        object::delete(receipt_id);

        event::emit(WithdrawEvent<T> {
            deposit_id,
            depositor,
            amount,
        });
    }

    #[test_only]
    use sui::sui::SUI;
    #[test_only]
    use sui::test_scenario as ts;

    #[test_only]
    const ADMIN: address = @0xAD;
    #[test_only]
    const DEPOSITER: address = @0xA;

    #[test]
    fun test_deposit() {
        let mut ts = ts::begin(@0x0);

        // when the package is published
        {
            ts::next_tx(&mut ts, ADMIN);
            init(ts.ctx());
        };

        // then it is initialised with correct state
        {
            ts::next_tx(&mut ts, ADMIN);
            let bank = ts::take_shared<AssetBank>(&ts);
            assert!(bank.total_deposits() == 0);
            assert!(bank.active_nfts() == 0);
            ts::return_shared(bank);
        };

        // when a depositer deposits an asset
        {
            ts::next_tx(&mut ts, DEPOSITER);
            let coin = coin::mint_for_testing<SUI>(100, ts::ctx(&mut ts));
            let mut bank = ts::take_shared<AssetBank>(&ts);
            deposit<SUI>(&mut bank, coin, ts.ctx());
            ts::return_shared(bank);
        };

        // then the depositor owns a receipt
        {
            ts::next_tx(&mut ts, DEPOSITER);
            let receipt = ts::take_from_sender<Receipt<SUI>>(&ts);
            assert!(receipt.deposit_id == 1);
            assert!(receipt.amount == 100);
            assert!(receipt.depositor == DEPOSITER);
            ts::return_to_sender(&ts, receipt);
        };

        // cleanup
        ts::end(ts);
    }
}

