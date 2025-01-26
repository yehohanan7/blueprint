# Bank

* Accepts deposit of Coin from user
* Moves the deposited Coin<T> to the dynamic field identified by (`bank_id, AssetType<T>`)
* If the dynamic field for the asset is already present, the deposited coin is joined

# Test
Used test scenario to test the deposit/withdraw functionality

# Scripts
There are some typescript code under `etc/scripts` directory to test the contract in other environments easily
