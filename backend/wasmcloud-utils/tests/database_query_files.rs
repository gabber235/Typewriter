use serde::Deserialize;
use wasmcloud_utils::{transaction_outcome_index_file, transaction_query_file};

#[derive(Deserialize)]
struct Outcome;

#[test]
fn builds_a_validated_file_backed_transaction() {
    const OUTCOME_INDEX: usize =
        transaction_outcome_index_file!("tests/valid_file_transaction.surql");

    let _query = transaction_query_file!(Outcome, "tests/valid_file_transaction.surql");

    assert_eq!(OUTCOME_INDEX, 2);
}
