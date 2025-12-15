use serde::de::{self, MapAccess, Visitor};
use serde::{Deserialize, Deserializer, Serialize};
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

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize)]
#[serde(untagged)]
pub enum RecordIdKey {
    String(String),
    Integer(i64),
}

impl fmt::Display for RecordIdKey {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RecordIdKey::String(s) => write!(f, "{}", s),
            RecordIdKey::Integer(i) => write!(f, "{}", i),
        }
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
                formatter.write_str("a string, integer, or map with String/Integer key")
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
                Ok(RecordIdKey::Integer(value))
            }

            fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RecordIdKey::Integer(value as i64))
            }

            fn visit_map<M>(self, mut map: M) -> Result<Self::Value, M::Error>
            where
                M: MapAccess<'de>,
            {
                let mut result: Option<RecordIdKey> = None;

                while let Some(key) = map.next_key::<String>()? {
                    match key.as_str() {
                        "String" => {
                            let value: String = map.next_value()?;
                            result = Some(RecordIdKey::String(value));
                        }
                        "Integer" => {
                            let value: i64 = map.next_value()?;
                            result = Some(RecordIdKey::Integer(value));
                        }
                        _ => {
                            let _: serde::de::IgnoredAny = map.next_value()?;
                        }
                    }
                }

                result.ok_or_else(|| de::Error::custom("expected String or Integer key in map"))
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
