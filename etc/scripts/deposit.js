import {SuiClient} from '@mysten/sui/client';
import {Transaction} from '@mysten/sui/transactions';
import {bank_id, bank_pkg_id, my_key} from "./common.js";

const client = new SuiClient({url: 'http://127.0.0.1:9000 '});
const coin_to_deposit = '0x8b0cf8a84b359ddf215323b2761ffe8b2052f76cea947da877a339d57880967f'

const tx = new Transaction()
tx.moveCall(
    {
        target: `${bank_pkg_id}::bank::deposit`,
        typeArguments: ["0x2::sui::SUI"],
        arguments: [tx.object(bank_id), tx.object(coin_to_deposit)]
    }
)
tx.setGasBudget(10000000);

const result = await client.signAndExecuteTransaction({
    signer: my_key,
    transaction: tx
});

await client.waitForTransaction({digest: result.digest});
console.log("Transaction successful. Digest:", result);
