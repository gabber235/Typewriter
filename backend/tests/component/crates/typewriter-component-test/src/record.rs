use wasmcloud_utils::skir::base::kernel::v1::record_id::{RecordId, RecordIdKey};

pub fn skir_record_id(table: impl Into<String>, key: impl Into<String>) -> RecordId {
    RecordId {
        table: table.into(),
        key: RecordIdKey::String(key.into()),
        _unrecognized: None,
    }
}

pub fn database_record_key(value: &serde_json::Value, table: &str) -> anyhow::Result<String> {
    value
        .as_array()
        .and_then(|values| values.first())
        .and_then(serde_json::Value::as_str)
        .and_then(|value| value.strip_prefix(&format!("{table}:")))
        .map(|value| value.trim_matches('`').to_string())
        .ok_or_else(|| anyhow::anyhow!("missing {table} record id"))
}
