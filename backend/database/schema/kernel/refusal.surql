-- Refuses a transaction with a typed value and rolls back every write it made.
--
-- Only a thrown error rolls a transaction back, and SurrealDB flattens a thrown value to a
-- string. The refusal is therefore thrown as JSON behind the `refused:` marker, which
-- `TransactionResponse::decode_refusable` in wasmcloud-utils reads back as its type. Keep the
-- marker in step with that decoder.
DEFINE FUNCTION OVERWRITE fn::refuse($refusal: any) -> none {
    THROW string::concat('refused:', encoding::json::encode($refusal));
};
