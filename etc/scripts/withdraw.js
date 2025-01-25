import {SuiClient} from '@mysten/sui/client';
import {Transaction} from '@mysten/sui/transactions';
import {bank_id, bank_pkg_id, my_key} from "./common.js";

const client = new SuiClient({url: 'http://127.0.0.1:9000 '});
const receipt_id = '0x2f9f3ab59f59105a11b01d69de7865c294a70fc0e020b421a4752bf8fa1f8b8d'

const tx = new Transaction()
tx.moveCall(
    {
        target: `${bank_pkg_id}::bank::withdraw`,
        typeArguments: ["0x2::sui::SUI"],
        arguments: [tx.object(bank_id), tx.object(receipt_id)]
    }
)
tx.setGasBudget(10000000);

const result = await client.signAndExecuteTransaction({
    signer: my_key,
    transaction: tx
});

await client.waitForTransaction({digest: result.digest});
console.log("Transaction successful. Digest:", result);
