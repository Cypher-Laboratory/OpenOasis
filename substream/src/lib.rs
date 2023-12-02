mod pb;


use pb::eth::tx_meta::v1::TxMeta; // Import TxMeta
use substreams::store::{
    self, DeltaProto, StoreNew, StoreSetIfNotExists, StoreSetIfNotExistsProto,
};


use substreams::{Hex, log};
use substreams_database_change::pb::database::{table_change::Operation, DatabaseChanges};
use substreams_ethereum::pb as ethpb;

#[substreams::handlers::store]
fn store_tx_meta_start(blk: ethpb::eth::v2::Block, s: StoreSetIfNotExistsProto<TxMeta>) {

    let txs = blk.transactions();
    for tx in txs {
        let tx_meta = transform_transaction_to_tx_meta(tx.clone());
        let key = tx_meta.ordinal.to_string(); // Convert ordinal to a string

        s.set_if_not_exists(tx_meta.ordinal, key,  &tx_meta);
    }

}

#[substreams::handlers::map]
fn db_out(
    tx_meta_start: store::Deltas<DeltaProto<TxMeta>>,
) -> Result<DatabaseChanges, substreams::errors::Error> {
    let mut database_changes: DatabaseChanges = Default::default();
    transform_tx_meta_to_database_changes(&mut database_changes, tx_meta_start);
    Ok(database_changes)
}

fn transform_transaction_to_tx_meta(
    tx: ethpb::eth::v2::TransactionTrace,
) -> TxMeta {

    TxMeta {
            hash: tx.hash,
            pubkey: tx.public_key,
            from: tx.from,
            to: tx.to,
            ordinal: tx.begin_ordinal + tx.end_ordinal,
            r: tx.r,
            s: tx.s,
            v: tx.v,
        }
}

fn transform_tx_meta_to_database_changes(
    changes: &mut DatabaseChanges,
    deltas: store::Deltas<DeltaProto<TxMeta>>,
) {
    use substreams::pb::substreams::store_delta::Operation;

    for delta in deltas.deltas {
        match delta.operation {
            Operation::Create => push_create(
                changes,
                &delta.key,
                delta.ordinal,
                delta.new_value,
            ),
            Operation::Update => push_update(
                changes,
                &delta.key,
                delta.ordinal,
                delta.old_value,
                delta.new_value,
            ),
            Operation::Delete => todo!(),
            x => panic!("unsupported operation {:?}", x),
        }
    }
}

// Define the push_create and push_update functions similar to what you did for BlockMeta


fn push_create(
    changes: &mut DatabaseChanges,
    key: &str,
    ordinal: u64,
    value: TxMeta,
) {
    log::info!("push_create: key: {}, ordinal: {}, value: {:?}", key, ordinal, value);

    changes
        .push_change("txs_meta", key, ordinal, Operation::Create)
        .change("hash", (None, Hex(value.hash)))
        .change("pubkey", (None, Hex(value.pubkey)))
        .change("from", (None, Hex(value.from)))
        .change("to", (None, Hex(value.to)))
        .change("r", (None, Hex(value.r)))
        .change("s", (None, Hex(value.s)))
        .change("v", (None, Hex(value.v)))
        ;
        
}


fn push_update(
    changes: &mut DatabaseChanges,
    key: &str,
    ordinal: u64,
    old_value: TxMeta,
    new_value: TxMeta,
) {
    log::info!("push_update: key: {}, ordinal: {}, old_value: {:?}, new_value: {:?}", key, ordinal, old_value, new_value);
    changes
        .push_change("txs_meta",key, ordinal, Operation::Update)
        .change("hash", (Hex(old_value.hash), Hex(new_value.hash)))
        .change(
            "pubkey",
            (Hex(old_value.pubkey), Hex(new_value.pubkey)),
        )
        .change("from", (Hex(old_value.from), Hex(new_value.from)))
        .change("to", (Hex(old_value.to), Hex(new_value.to)))
        .change("r", (Hex(old_value.r), Hex(new_value.r)))
        .change("s", (Hex(old_value.s), Hex(new_value.s)))
        .change("v", (Hex(old_value.v), Hex(new_value.v)))
        
        ;
}
