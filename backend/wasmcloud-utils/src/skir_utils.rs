use opentelemetry::Value;

use crate::skir_client::KeyedVec;
use crate::skirout::base::kernel::v1::color::Color;
use crate::skirout::base::kernel::v1::record_id::{
    ObjectRecordIdKey, ObjectRecordIdValue, RecordId, RecordIdKey, RecordIdValue,
};
use std::collections::{BTreeSet, HashMap};
use std::fmt;

// =============================================================================
// Display helpers
// =============================================================================

/// Returns true if the string is a "simple" identifier that can be displayed
/// without backtick quoting. Simple means: only alphanumeric + underscore,
/// and not parseable as an i64 (to avoid ambiguity with numeric IDs).
fn is_simple_id(s: &str) -> bool {
    if s.is_empty() {
        return false;
    }
    if !s.chars().all(|c| c.is_ascii_alphanumeric() || c == '_') {
        return false;
    }
    s.parse::<i64>().is_err()
}

/// Format a string as a record ID key: bare if simple, backtick-quoted otherwise.
fn fmt_string_key(s: &str, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    if is_simple_id(s) {
        write!(f, "{s}")
    } else {
        write!(f, "`{s}`")
    }
}

/// Format a string as a record ID value: single-quoted with internal single quotes escaped.
fn fmt_string_value(s: &str, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(f, "'")?;
    for c in s.chars() {
        if c == '\'' {
            write!(f, "\\'")?;
        } else {
            write!(f, "{c}")?;
        }
    }
    write!(f, "'")
}

// =============================================================================
// Skir → Surreal
// =============================================================================

pub trait RecordIdTableInput {
    fn invalid_tables(&self, expected_table: &str) -> Vec<String>;
}

impl RecordIdTableInput for RecordId {
    fn invalid_tables(&self, expected_table: &str) -> Vec<String> {
        (self.table != expected_table)
            .then(|| self.table.clone())
            .into_iter()
            .collect()
    }
}

impl RecordIdTableInput for [RecordId] {
    fn invalid_tables(&self, expected_table: &str) -> Vec<String> {
        self.iter()
            .filter_map(|record_id| {
                (record_id.table != expected_table).then_some(record_id.table.as_str())
            })
            .collect::<BTreeSet<_>>()
            .into_iter()
            .map(str::to_owned)
            .collect()
    }
}

impl RecordIdTableInput for Vec<RecordId> {
    fn invalid_tables(&self, expected_table: &str) -> Vec<String> {
        self.as_slice().invalid_tables(expected_table)
    }
}

impl<T> RecordIdTableInput for &T
where
    T: RecordIdTableInput + ?Sized,
{
    fn invalid_tables(&self, expected_table: &str) -> Vec<String> {
        (*self).invalid_tables(expected_table)
    }
}

impl From<RecordId> for surrealdb_component_sdk::RecordId {
    fn from(value: RecordId) -> Self {
        surrealdb_component_sdk::RecordId {
            table: value.table,
            key: value.key.into(),
        }
    }
}

impl From<&RecordId> for surrealdb_component_sdk::RecordId {
    fn from(value: &RecordId) -> Self {
        value.clone().into()
    }
}

impl From<RecordId> for surrealdb_types::RecordId {
    fn from(value: RecordId) -> Self {
        surrealdb_types::RecordId::new(value.table, value.key)
    }
}

impl From<&RecordId> for surrealdb_types::RecordId {
    fn from(value: &RecordId) -> Self {
        value.clone().into()
    }
}

/// Converts Skir record ID collections into SurrealDB record IDs.
pub trait IntoSurrealRecordIds {
    fn into_surreal_record_ids(self) -> Vec<surrealdb_component_sdk::RecordId>;
}

impl IntoSurrealRecordIds for Vec<RecordId> {
    fn into_surreal_record_ids(self) -> Vec<surrealdb_component_sdk::RecordId> {
        self.into_iter().map(Into::into).collect()
    }
}

impl IntoSurrealRecordIds for &[RecordId] {
    fn into_surreal_record_ids(self) -> Vec<surrealdb_component_sdk::RecordId> {
        self.iter().map(Into::into).collect()
    }
}

impl From<RecordIdKey> for surrealdb_component_sdk::RecordIdKey {
    fn from(value: RecordIdKey) -> Self {
        match value {
            RecordIdKey::Unknown(_) => surrealdb_component_sdk::RecordIdKey::String(String::new()),
            RecordIdKey::Number(n) => surrealdb_component_sdk::RecordIdKey::Number(n),
            RecordIdKey::String(s) => surrealdb_component_sdk::RecordIdKey::String(s),
            RecordIdKey::Uuid(u) => surrealdb_component_sdk::RecordIdKey::Uuid(u),
            RecordIdKey::Array(arr) => surrealdb_component_sdk::RecordIdKey::Array(
                arr.into_iter().map(Into::into).collect(),
            ),
            RecordIdKey::Object(obj) => {
                let map: HashMap<String, surrealdb_component_sdk::RecordIdValue> = obj
                    .into_iter()
                    .map(|item| (item.key, item.value.into()))
                    .collect();
                surrealdb_component_sdk::RecordIdKey::Object(map)
            }
        }
    }
}

impl From<RecordIdValue> for surrealdb_component_sdk::RecordIdValue {
    fn from(value: RecordIdValue) -> Self {
        match value {
            RecordIdValue::Unknown(_) => surrealdb_component_sdk::RecordIdValue::Null,
            RecordIdValue::Null => surrealdb_component_sdk::RecordIdValue::Null,
            RecordIdValue::Boolean(b) => surrealdb_component_sdk::RecordIdValue::Bool(b),
            RecordIdValue::Number(n) => surrealdb_component_sdk::RecordIdValue::Number(n),
            RecordIdValue::Float(f) => surrealdb_component_sdk::RecordIdValue::Float(f),
            RecordIdValue::String(s) => surrealdb_component_sdk::RecordIdValue::String(s),
            RecordIdValue::Array(arr) => surrealdb_component_sdk::RecordIdValue::Array(
                arr.into_iter().map(Into::into).collect(),
            ),
            RecordIdValue::Object(obj) => {
                let map: HashMap<String, surrealdb_component_sdk::RecordIdValue> = obj
                    .into_iter()
                    .map(|item| (item.key, item.value.into()))
                    .collect();
                surrealdb_component_sdk::RecordIdValue::Object(map)
            }
        }
    }
}

impl From<RecordIdKey> for surrealdb_types::RecordIdKey {
    fn from(value: RecordIdKey) -> Self {
        match value {
            RecordIdKey::Unknown(_) => surrealdb_types::RecordIdKey::String(String::new()),
            RecordIdKey::Number(number) => surrealdb_types::RecordIdKey::Number(number),
            RecordIdKey::String(string) => surrealdb_types::RecordIdKey::String(string),
            RecordIdKey::Uuid(uuid) => surrealdb_types::RecordIdKey::Uuid(
                uuid.parse()
                    .expect("Skir RecordIdKey::Uuid must contain a valid UUID"),
            ),
            RecordIdKey::Array(array) => surrealdb_types::RecordIdKey::Array(
                array
                    .into_iter()
                    .map(surrealdb_types::Value::from)
                    .collect(),
            ),
            RecordIdKey::Object(object) => surrealdb_types::RecordIdKey::Object(
                object
                    .into_iter()
                    .map(|item| (item.key, surrealdb_types::Value::from(item.value)))
                    .collect(),
            ),
        }
    }
}

impl From<RecordIdValue> for surrealdb_types::Value {
    fn from(value: RecordIdValue) -> Self {
        match value {
            RecordIdValue::Unknown(_) | RecordIdValue::Null => surrealdb_types::Value::Null,
            RecordIdValue::Boolean(boolean) => surrealdb_types::Value::Bool(boolean),
            RecordIdValue::Number(number) => {
                surrealdb_types::Value::Number(surrealdb_types::Number::Int(number))
            }
            RecordIdValue::Float(float) => {
                surrealdb_types::Value::Number(surrealdb_types::Number::Float(float))
            }
            RecordIdValue::String(string) => surrealdb_types::Value::String(string),
            RecordIdValue::Array(array) => surrealdb_types::Value::Array(
                array
                    .into_iter()
                    .map(surrealdb_types::Value::from)
                    .collect(),
            ),
            RecordIdValue::Object(object) => surrealdb_types::Value::Object(
                object
                    .into_iter()
                    .map(|item| (item.key, surrealdb_types::Value::from(item.value)))
                    .collect(),
            ),
        }
    }
}

// =============================================================================
// Surreal → Skir
// =============================================================================

impl From<surrealdb_component_sdk::RecordId> for RecordId {
    fn from(value: surrealdb_component_sdk::RecordId) -> Self {
        RecordId {
            table: value.table,
            key: value.key.into(),
            _unrecognized: None,
        }
    }
}

impl From<&surrealdb_component_sdk::RecordId> for RecordId {
    fn from(value: &surrealdb_component_sdk::RecordId) -> Self {
        value.clone().into()
    }
}

impl From<surrealdb_types::RecordId> for RecordId {
    fn from(value: surrealdb_types::RecordId) -> Self {
        RecordId {
            table: value.table.into_string(),
            key: value.key.into(),
            _unrecognized: None,
        }
    }
}

impl From<&surrealdb_types::RecordId> for RecordId {
    fn from(value: &surrealdb_types::RecordId) -> Self {
        value.clone().into()
    }
}

/// Converts SurrealDB record ID collections into Skir record IDs.
pub trait IntoSkirRecordIds {
    fn into_skir_record_ids(self) -> Vec<RecordId>;
}

impl IntoSkirRecordIds for Vec<surrealdb_component_sdk::RecordId> {
    fn into_skir_record_ids(self) -> Vec<RecordId> {
        self.into_iter().map(Into::into).collect()
    }
}

impl IntoSkirRecordIds for &[surrealdb_component_sdk::RecordId] {
    fn into_skir_record_ids(self) -> Vec<RecordId> {
        self.iter().map(Into::into).collect()
    }
}

impl From<surrealdb_component_sdk::RecordIdKey> for RecordIdKey {
    fn from(value: surrealdb_component_sdk::RecordIdKey) -> Self {
        match value {
            surrealdb_component_sdk::RecordIdKey::Number(n) => RecordIdKey::Number(n),
            surrealdb_component_sdk::RecordIdKey::String(s) => RecordIdKey::String(s),
            surrealdb_component_sdk::RecordIdKey::Uuid(u) => RecordIdKey::Uuid(u),
            surrealdb_component_sdk::RecordIdKey::Array(arr) => {
                RecordIdKey::Array(arr.into_iter().map(Into::into).collect())
            }
            surrealdb_component_sdk::RecordIdKey::Object(map) => {
                let items: Vec<ObjectRecordIdKey> = map
                    .into_iter()
                    .map(|(key, value)| ObjectRecordIdKey {
                        key,
                        value: value.into(),
                        _unrecognized: None,
                    })
                    .collect();
                RecordIdKey::Object(KeyedVec::new(items))
            }
        }
    }
}

impl From<surrealdb_component_sdk::RecordIdValue> for RecordIdValue {
    fn from(value: surrealdb_component_sdk::RecordIdValue) -> Self {
        match value {
            surrealdb_component_sdk::RecordIdValue::Null => RecordIdValue::Null,
            surrealdb_component_sdk::RecordIdValue::Bool(b) => RecordIdValue::Boolean(b),
            surrealdb_component_sdk::RecordIdValue::Number(n) => RecordIdValue::Number(n),
            surrealdb_component_sdk::RecordIdValue::Float(f) => RecordIdValue::Float(f),
            surrealdb_component_sdk::RecordIdValue::String(s) => RecordIdValue::String(s),
            surrealdb_component_sdk::RecordIdValue::Array(arr) => {
                RecordIdValue::Array(arr.into_iter().map(Into::into).collect())
            }
            surrealdb_component_sdk::RecordIdValue::Object(map) => {
                let items: Vec<ObjectRecordIdValue> = map
                    .into_iter()
                    .map(|(key, value)| ObjectRecordIdValue {
                        key,
                        value: value.into(),
                        _unrecognized: None,
                    })
                    .collect();
                RecordIdValue::Object(KeyedVec::new(items))
            }
        }
    }
}

impl From<surrealdb_types::RecordIdKey> for RecordIdKey {
    fn from(value: surrealdb_types::RecordIdKey) -> Self {
        match value {
            surrealdb_types::RecordIdKey::Number(number) => RecordIdKey::Number(number),
            surrealdb_types::RecordIdKey::String(string) => RecordIdKey::String(string),
            surrealdb_types::RecordIdKey::Uuid(uuid) => RecordIdKey::Uuid(uuid.to_string()),
            surrealdb_types::RecordIdKey::Array(array) => {
                RecordIdKey::Array(array.into_iter().map(Into::into).collect())
            }
            surrealdb_types::RecordIdKey::Object(object) => {
                let items = object
                    .into_iter()
                    .map(|(key, value)| ObjectRecordIdKey {
                        key,
                        value: value.into(),
                        _unrecognized: None,
                    })
                    .collect();
                RecordIdKey::Object(KeyedVec::new(items))
            }
            surrealdb_types::RecordIdKey::Range(_) => RecordIdKey::Unknown(None),
        }
    }
}

impl From<surrealdb_types::Value> for RecordIdValue {
    fn from(value: surrealdb_types::Value) -> Self {
        match value {
            surrealdb_types::Value::Null => RecordIdValue::Null,
            surrealdb_types::Value::Bool(boolean) => RecordIdValue::Boolean(boolean),
            surrealdb_types::Value::Number(surrealdb_types::Number::Int(number)) => {
                RecordIdValue::Number(number)
            }
            surrealdb_types::Value::Number(surrealdb_types::Number::Float(float)) => {
                RecordIdValue::Float(float)
            }
            surrealdb_types::Value::String(string) => RecordIdValue::String(string),
            surrealdb_types::Value::Array(array) => {
                RecordIdValue::Array(array.into_iter().map(Into::into).collect())
            }
            surrealdb_types::Value::Object(object) => {
                let items = object
                    .into_iter()
                    .map(|(key, value)| ObjectRecordIdValue {
                        key,
                        value: value.into(),
                        _unrecognized: None,
                    })
                    .collect();
                RecordIdValue::Object(KeyedVec::new(items))
            }
            _ => RecordIdValue::Unknown(None),
        }
    }
}

// =============================================================================
// Display
// =============================================================================

impl fmt::Display for RecordIdValue {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RecordIdValue::Unknown(_) => write!(f, "<unknown>"),
            RecordIdValue::Null => write!(f, "NONE"),
            RecordIdValue::Boolean(b) => write!(f, "{b}"),
            RecordIdValue::Number(n) => write!(f, "{n}"),
            RecordIdValue::Float(fl) => write!(f, "{fl}f"),
            RecordIdValue::String(s) => fmt_string_value(s, f),
            RecordIdValue::Array(arr) => {
                write!(f, "[")?;
                for (i, v) in arr.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    fmt::Display::fmt(v, f)?;
                }
                write!(f, "]")
            }
            RecordIdValue::Object(obj) => {
                write!(f, "{{")?;
                for (i, item) in obj.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    fmt_string_key(&item.key, f)?;
                    write!(f, ": ")?;
                    fmt::Display::fmt(&item.value, f)?;
                }
                write!(f, "}}")
            }
        }
    }
}

impl fmt::Display for RecordIdKey {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RecordIdKey::Unknown(_) => write!(f, "<unknown>"),
            RecordIdKey::Number(n) => write!(f, "{n}"),
            RecordIdKey::String(s) => fmt_string_key(s, f),
            RecordIdKey::Uuid(u) => write!(f, "u'{u}'"),
            RecordIdKey::Array(arr) => {
                write!(f, "[")?;
                for (i, v) in arr.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    fmt::Display::fmt(v, f)?;
                }
                write!(f, "]")
            }
            RecordIdKey::Object(obj) => {
                write!(f, "{{")?;
                for (i, item) in obj.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    fmt_string_key(&item.key, f)?;
                    write!(f, ": ")?;
                    fmt::Display::fmt(&item.value, f)?;
                }
                write!(f, "}}")
            }
        }
    }
}

impl fmt::Display for RecordId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt_string_key(&self.table, f)?;
        write!(f, ":")?;
        fmt::Display::fmt(&self.key, f)
    }
}

impl From<RecordId> for Value {
    fn from(value: RecordId) -> Self {
        (&value).into()
    }
}

impl From<&RecordId> for Value {
    fn from(value: &RecordId) -> Self {
        value.to_string().into()
    }
}

impl From<i64> for Color {
    fn from(value: i64) -> Self {
        (value as i32).into()
    }
}

impl From<i32> for Color {
    fn from(value: i32) -> Self {
        Color {
            argb: value,
            _unrecognized: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn record_id(table: &str) -> RecordId {
        RecordId {
            table: table.to_owned(),
            key: RecordIdKey::String("id".to_owned()),
            _unrecognized: None,
        }
    }

    #[test]
    fn single_record_id_reports_only_a_wrong_table() {
        assert!(record_id("user").invalid_tables("user").is_empty());
        assert_eq!(record_id("service").invalid_tables("user"), ["service"]);
    }

    #[test]
    fn record_id_list_sorts_and_deduplicates_wrong_tables() {
        let ids = vec![
            record_id("user"),
            record_id("zebra"),
            record_id("service"),
            record_id("zebra"),
        ];

        assert_eq!(ids.invalid_tables("user"), ["service", "zebra"]);
        assert_eq!(ids.as_slice().invalid_tables("user"), ["service", "zebra"]);
        assert!(Vec::<RecordId>::new().invalid_tables("user").is_empty());
    }

    #[test]
    fn surrealdb_types_record_id_round_trips_supported_values() {
        let original = RecordId {
            table: "user".to_owned(),
            key: RecordIdKey::Object(KeyedVec::new(vec![ObjectRecordIdKey {
                key: "parts".to_owned(),
                value: RecordIdValue::Array(vec![
                    RecordIdValue::Number(42),
                    RecordIdValue::Boolean(true),
                    RecordIdValue::String("value".to_owned()),
                ]),
                _unrecognized: None,
            }])),
            _unrecognized: None,
        };

        let surreal = surrealdb_types::RecordId::from(original.clone());

        assert_eq!(RecordId::from(surreal), original);
    }

    #[test]
    fn surrealdb_types_record_id_round_trips_uuid_keys() {
        let original = RecordId {
            table: "user".to_owned(),
            key: RecordIdKey::Uuid("019fd869-a293-7020-8745-24ba2ca92541".to_owned()),
            _unrecognized: None,
        };

        let surreal = surrealdb_types::RecordId::from(original.clone());

        assert_eq!(RecordId::from(surreal), original);
    }
}
