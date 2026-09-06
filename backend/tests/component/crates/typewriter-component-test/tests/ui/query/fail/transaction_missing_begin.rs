use serde::Deserialize;
use wasmcloud_utils::transaction_query;

#[derive(Deserialize)]
struct Outcome;

fn main() {
    let _query = transaction_query!(
        Outcome,
        "UPDATE user:test SET active = true; RETURN true; COMMIT TRANSACTION;",
    );
}
