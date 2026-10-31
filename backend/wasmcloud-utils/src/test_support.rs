//! Helpers for unit testing the crate's Skir and database adapters on the host.

use crate::database::{SkirDb, SkirType};
use crate::skir::base::kernel::v1::record_id::{RecordId, RecordIdKey};

/// A Skir record id of `table` with a string `key`.
pub(crate) fn record_id(table: &str, key: &str) -> RecordId {
    RecordId {
        table: table.to_owned(),
        key: RecordIdKey::String(key.to_owned()),
        _unrecognized: None,
    }
}

/// The JSON a database stores for `value`.
pub(crate) fn stored<T: SkirType>(value: T) -> serde_json::Value {
    serde_json::to_value(SkirDb(value)).unwrap()
}

/// The value a database loads from `json`.
pub(crate) fn loaded<T: SkirType>(json: serde_json::Value) -> Result<T, serde_json::Error> {
    serde_json::from_value::<SkirDb<T>>(json).map(|SkirDb(value)| value)
}
