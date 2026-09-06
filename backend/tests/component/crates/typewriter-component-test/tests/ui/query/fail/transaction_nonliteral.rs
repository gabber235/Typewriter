use serde::Deserialize;
use wasmcloud_utils::transaction_query;

#[derive(Deserialize)]
struct Outcome;

fn main() {
    let query = "BEGIN TRANSACTION; RETURN true; COMMIT TRANSACTION;";
    let _query = transaction_query!(Outcome, query);
}
