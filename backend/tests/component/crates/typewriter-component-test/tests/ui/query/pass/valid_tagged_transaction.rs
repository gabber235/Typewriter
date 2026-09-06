use serde::Deserialize;
use wasmcloud_utils::transaction_query;

#[derive(Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
enum Outcome {
    Success { value: bool },
}

fn main() {
    let _query = transaction_query!(
        Outcome,
        r#"
        BEGIN TRANSACTION;
        UPDATE user:test SET active = true;
        RETURN { kind: "success", value: true };
        COMMIT TRANSACTION;
        "#,
    );
}
