use opentelemetry::Value;

use crate::skir_client::KeyedVec;
use crate::skirout::base::kernel::v1::color::Color;
use crate::skirout::base::kernel::v1::record_id::{
    ObjectRecordIdKey, ObjectRecordIdValue, RecordId, RecordIdKey, RecordIdValue,
};
use std::collections::HashMap;
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

impl From<RecordId> for surrealdb_component_sdk::RecordId {
    fn from(value: RecordId) -> Self {
        surrealdb_component_sdk::RecordId {
            table: value.table,
            key: value.key.into(),
        }
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
