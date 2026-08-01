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

#[cfg(test)]
mod tests {
    use super::{database_record_key, skir_record_id};

    #[test]
    fn creates_string_keyed_skir_record_id() {
        let record_id = skir_record_id("organization", "writers");

        assert_eq!(record_id.table, "organization");
        assert_eq!(record_id.key.to_string(), "writers");
    }

    #[test]
    fn extracts_plain_database_record_key() {
        let value = serde_json::json!(["organization:writers"]);

        assert_eq!(
            database_record_key(&value, "organization").unwrap(),
            "writers"
        );
    }

    #[test]
    fn extracts_quoted_database_record_key() {
        let value = serde_json::json!(["organization:`writer role`"]);

        assert_eq!(
            database_record_key(&value, "organization").unwrap(),
            "writer role"
        );
    }

    #[test]
    fn rejects_missing_or_wrong_table_database_record() {
        assert!(database_record_key(&serde_json::json!([]), "organization").is_err());
        assert!(database_record_key(&serde_json::json!(["user:writers"]), "organization").is_err());
    }
}
