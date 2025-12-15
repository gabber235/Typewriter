use chrono::{DateTime, Utc};
use serde::de::{self, Visitor};
use serde::{Deserialize, Deserializer, Serialize};
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Datetime(pub DateTime<Utc>);

impl Datetime {
    pub fn into_inner(self) -> DateTime<Utc> {
        self.0
    }
}

impl std::ops::Deref for Datetime {
    type Target = DateTime<Utc>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl fmt::Display for Datetime {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0.to_rfc3339())
    }
}

impl From<Datetime> for DateTime<Utc> {
    fn from(dt: Datetime) -> Self {
        dt.0
    }
}

impl<'de> Deserialize<'de> for Datetime {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct DatetimeVisitor;

        impl<'de> Visitor<'de> for DatetimeVisitor {
            type Value = Datetime;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a datetime string in RFC 3339 format")
            }

            fn visit_str<E>(self, value: &str) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                DateTime::parse_from_rfc3339(value)
                    .map(|dt| Datetime(dt.with_timezone(&Utc)))
                    .map_err(de::Error::custom)
            }

            fn visit_string<E>(self, value: String) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                self.visit_str(&value)
            }
        }

        deserializer.deserialize_any(DatetimeVisitor)
    }
}
