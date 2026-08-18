use wasmcloud_utils::transaction_query;

struct Outcome;

fn main() {
    let _query = transaction_query!(
        Outcome,
        "BEGIN TRANSACTION; RETURN true; COMMIT TRANSACTION;",
    );
}
