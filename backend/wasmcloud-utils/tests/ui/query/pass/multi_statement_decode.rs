use serde::Deserialize;
use wasmcloud_utils::{database::TransactionOutcome, transaction_query};

#[derive(Deserialize)]
struct Outcome {
    value: bool,
}

async fn compile_boundary() {
    let response = transaction_query!(
        Outcome,
        r#"
        BEGIN TRANSACTION;
        LET $first = SELECT * FROM user;
        LET $second = SELECT * FROM organization;
        RETURN { value: array::len($first) >= 0 AND array::len($second) >= 0 };
        COMMIT TRANSACTION;
        "#,
    )
    .execute()
    .await
    .unwrap();
    let _outcome: TransactionOutcome<Outcome> = response.decode().unwrap();
}

fn main() {}
