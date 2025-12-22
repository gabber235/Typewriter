use serde::de::{self, MapAccess, SeqAccess, Visitor};
use serde::{Deserialize, Deserializer, Serialize};
use std::collections::HashMap;
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize)]
pub struct RecordId {
    pub tb: String,
    pub id: RecordIdKey,
}

impl RecordId {
    pub fn new(tb: impl Into<String>, id: impl Into<String>) -> Self {
        Self {
            tb: tb.into(),
            id: RecordIdKey::String(id.into()),
        }
    }
}

impl fmt::Display for RecordId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}:{}", self.tb, self.id)
    }
}

/// Represents a SurrealDB record ID key.
///
/// Mirrors the `Id` enum from surrealdb-core, supporting:
/// - `Number(i64)` - integer IDs
/// - `String(String)` - string IDs
/// - `Uuid(String)` - UUID IDs (stored as string)
/// - `Array(Vec<RecordIdValue>)` - composite array IDs
/// - `Object(HashMap<String, RecordIdValue>)` - composite object IDs
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(untagged)]
pub enum RecordIdKey {
    Number(i64),
    String(String),
    Uuid(String),
    Array(Vec<RecordIdValue>),
    Object(HashMap<String, RecordIdValue>),
}

impl std::hash::Hash for RecordIdKey {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        core::mem::discriminant(self).hash(state);
        match self {
            RecordIdKey::Number(n) => n.hash(state),
            RecordIdKey::String(s) => s.hash(state),
            RecordIdKey::Uuid(u) => u.hash(state),
            RecordIdKey::Array(a) => a.hash(state),
            RecordIdKey::Object(o) => {
                for (k, v) in o {
                    k.hash(state);
                    v.hash(state);
                }
            }
        }
    }
}

/// A value that can appear within a composite record ID (Array or Object).
#[derive(Debug, Clone, PartialEq, Serialize)]
#[serde(untagged)]
pub enum RecordIdValue {
    Null,
    Bool(bool),
    Number(i64),
    Float(f64),
    String(String),
    Array(Vec<RecordIdValue>),
    Object(HashMap<String, RecordIdValue>),
}

impl Eq for RecordIdValue {}

impl std::hash::Hash for RecordIdValue {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        core::mem::discriminant(self).hash(state);
        match self {
            RecordIdValue::Null => {}
            RecordIdValue::Bool(b) => b.hash(state),
            RecordIdValue::Number(n) => n.hash(state),
            RecordIdValue::Float(f) => f.to_bits().hash(state),
            RecordIdValue::String(s) => s.hash(state),
            RecordIdValue::Array(a) => a.hash(state),
            RecordIdValue::Object(o) => {
                for (k, v) in o {
                    k.hash(state);
                    v.hash(state);
                }
            }
        }
    }
}

impl fmt::Display for RecordIdKey {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RecordIdKey::Number(n) => write!(f, "{}", n),
            RecordIdKey::String(s) => write!(f, "{}", s),
            RecordIdKey::Uuid(u) => write!(f, "{}", u),
            RecordIdKey::Array(a) => {
                write!(f, "[")?;
                for (i, v) in a.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}", v)?;
                }
                write!(f, "]")
            }
            RecordIdKey::Object(o) => {
                write!(f, "{{")?;
                for (i, (k, v)) in o.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}: {}", k, v)?;
                }
                write!(f, "}}")
            }
        }
    }
}

impl fmt::Display for RecordIdValue {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RecordIdValue::Null => write!(f, "null"),
            RecordIdValue::Bool(b) => write!(f, "{}", b),
            RecordIdValue::Number(n) => write!(f, "{}", n),
            RecordIdValue::Float(n) => write!(f, "{}", n),
            RecordIdValue::String(s) => write!(f, "\"{}\"", s),
            RecordIdValue::Array(a) => {
                write!(f, "[")?;
                for (i, v) in a.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}", v)?;
                }
                write!(f, "]")
            }
            RecordIdValue::Object(o) => {
                write!(f, "{{")?;
                for (i, (k, v)) in o.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}: {}", k, v)?;
                }
                write!(f, "}}")
            }
        }
    }
}

impl<'de> Deserialize<'de> for RecordIdValue {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct RecordIdValueVisitor;

        impl<'de> Visitor<'de> for RecordIdValueVisitor {
            type Value = RecordIdValue;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a valid record ID value")
            }

            fn visit_unit<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdValue::Null)
            }

            fn visit_none<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdValue::Null)
            }

            fn visit_bool<E>(self, value: bool) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdValue::Bool(value))
            }

            fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdValue::Number(value))
            }

            fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdValue::Number(value as i64))
            }

            fn visit_f64<E>(self, value: f64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdValue::Float(value))
            }

            fn visit_str<E>(self, value: &str) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdValue::String(value.to_string()))
            }

            fn visit_string<E>(self, value: String) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdValue::String(value))
            }

            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let mut values = Vec::new();
                while let Some(value) = seq.next_element()? {
                    values.push(value);
                }
                Ok(RecordIdValue::Array(values))
            }

            fn visit_map<M>(self, mut map: M) -> Result<Self::Value, M::Error>
            where
                M: MapAccess<'de>,
            {
                let mut values = HashMap::new();
                while let Some((key, value)) = map.next_entry()? {
                    values.insert(key, value);
                }
                Ok(RecordIdValue::Object(values))
            }
        }

        deserializer.deserialize_any(RecordIdValueVisitor)
    }
}

impl<'de> Deserialize<'de> for RecordIdKey {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct RecordIdKeyVisitor;

        impl<'de> Visitor<'de> for RecordIdKeyVisitor {
            type Value = RecordIdKey;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str(
                    "a string, integer, UUID, array, object, or map with type discriminator",
                )
            }

            fn visit_str<E>(self, value: &str) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdKey::String(value.to_string()))
            }

            fn visit_string<E>(self, value: String) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdKey::String(value))
            }

            fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdKey::Number(value))
            }

            fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdKey::Number(value as i64))
            }

            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let mut values = Vec::new();
                while let Some(value) = seq.next_element()? {
                    values.push(value);
                }
                Ok(RecordIdKey::Array(values))
            }

            fn visit_map<M>(self, mut map: M) -> Result<Self::Value, M::Error>
            where
                M: MapAccess<'de>,
            {
                // First, collect all key-value pairs to determine the map type
                let mut entries: Vec<(String, serde_json::Value)> = Vec::new();

                while let Some(key) = map.next_key::<String>()? {
                    let value: serde_json::Value = map.next_value()?;
                    entries.push((key, value));
                }

                // Check for tagged enum format (single key that's a type discriminator)
                if entries.len() == 1 {
                    let (key, value) = &entries[0];
                    match key.as_str() {
                        "String" => {
                            if let Some(s) = value.as_str() {
                                return Ok(RecordIdKey::String(s.to_string()));
                            }
                        }
                        "Number" | "Integer" => {
                            if let Some(n) = value.as_i64() {
                                return Ok(RecordIdKey::Number(n));
                            }
                        }
                        "Uuid" => {
                            if let Some(s) = value.as_str() {
                                return Ok(RecordIdKey::Uuid(s.to_string()));
                            }
                        }
                        "Array" => {
                            if let Some(arr) = value.as_array() {
                                let values: Result<Vec<RecordIdValue>, _> = arr
                                    .iter()
                                    .map(|v| {
                                        serde_json::from_value(v.clone()).map_err(de::Error::custom)
                                    })
                                    .collect();
                                return Ok(RecordIdKey::Array(values?));
                            }
                        }
                        "Object" => {
                            if let Some(obj) = value.as_object() {
                                let values: Result<HashMap<String, RecordIdValue>, _> = obj
                                    .iter()
                                    .map(|(k, v)| {
                                        let val: RecordIdValue = serde_json::from_value(v.clone())
                                            .map_err(de::Error::custom)?;
                                        Ok((k.clone(), val))
                                    })
                                    .collect();
                                return Ok(RecordIdKey::Object(values?));
                            }
                        }
                        _ => {}
                    }
                }

                // Not a tagged enum, treat as a regular object ID
                let values: Result<HashMap<String, RecordIdValue>, _> = entries
                    .into_iter()
                    .map(|(k, v)| {
                        let val: RecordIdValue =
                            serde_json::from_value(v).map_err(de::Error::custom)?;
                        Ok((k, val))
                    })
                    .collect();
                Ok(RecordIdKey::Object(values?))
            }
        }

        deserializer.deserialize_any(RecordIdKeyVisitor)
    }
}

impl<'de> Deserialize<'de> for RecordId {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct RecordIdVisitor;

        impl<'de> Visitor<'de> for RecordIdVisitor {
            type Value = RecordId;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a map with 'tb' and 'id' fields")
            }

            fn visit_map<M>(self, mut map: M) -> Result<Self::Value, M::Error>
            where
                M: MapAccess<'de>,
            {
                let mut tb: Option<String> = None;
                let mut id: Option<RecordIdKey> = None;

                while let Some(key) = map.next_key::<String>()? {
                    match key.as_str() {
                        "tb" => {
                            tb = Some(map.next_value()?);
                        }
                        "id" => {
                            id = Some(map.next_value()?);
                        }
                        _ => {
                            let _: serde::de::IgnoredAny = map.next_value()?;
                        }
                    }
                }

                let tb = tb.ok_or_else(|| de::Error::missing_field("tb"))?;
                let id = id.ok_or_else(|| de::Error::missing_field("id"))?;

                Ok(RecordId { tb, id })
            }
        }

        deserializer.deserialize_map(RecordIdVisitor)
    }
}

// Convenience From implementations
impl From<i64> for RecordIdKey {
    fn from(v: i64) -> Self {
        RecordIdKey::Number(v)
    }
}

impl From<String> for RecordIdKey {
    fn from(v: String) -> Self {
        RecordIdKey::String(v)
    }
}

impl From<&str> for RecordIdKey {
    fn from(v: &str) -> Self {
        RecordIdKey::String(v.to_string())
    }
}

impl From<Vec<RecordIdValue>> for RecordIdKey {
    fn from(v: Vec<RecordIdValue>) -> Self {
        RecordIdKey::Array(v)
    }
}

impl From<HashMap<String, RecordIdValue>> for RecordIdKey {
    fn from(v: HashMap<String, RecordIdValue>) -> Self {
        RecordIdKey::Object(v)
    }
}
