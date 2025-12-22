wit_bindgen::generate!({ generate_all });

mod types;

pub use types::{Datetime, RecordId, RecordIdKey};

use crate::seamlezz::surrealdb::call;
use anyhow::{anyhow, Context, Result};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use serde_content::{Deserializer, Value};

pub trait SingleQueryResultExtractor: Sized {
    fn from_bytes(bytes: &[u8]) -> Result<Self>;
}

fn parse<D: DeserializeOwned>(bytes: &[u8]) -> Result<D> {
    let value: Value = serde_cbor::from_slice(bytes).context("CBOR Deserialization failed")?;
    let deserializer = Deserializer::new(value.clone()).coerce_numbers();
    D::deserialize(deserializer).with_context(|| {
        format!(
            "Deserialization content error, could not parse {} into {}",
            serde_json::to_string(&value).unwrap_or_else(|_| format!("{:?}", value)),
            std::any::type_name::<D>()
        )
    })
}

impl<D> SingleQueryResultExtractor for Vec<D>
where
    D: DeserializeOwned,
{
    fn from_bytes(bytes: &[u8]) -> Result<Self> {
        parse(bytes)
    }
}

impl<D> SingleQueryResultExtractor for Option<D>
where
    D: DeserializeOwned,
{
    fn from_bytes(bytes: &[u8]) -> Result<Self> {
        let value: Value = serde_cbor::from_slice(bytes).context("CBOR Deserialization failed")?;
        let deserializer = Deserializer::new(value.clone()).coerce_numbers();
        let items = Vec::<D>::deserialize(deserializer).with_context(|| {
            format!(
                "Deserialization content error could not parse {} into Option<{}>",
                serde_json::to_string(&value).unwrap_or_else(|_| format!("{:?}", value)),
                std::any::type_name::<D>()
            )
        })?;
        Ok(items.into_iter().next())
    }
}

pub struct QueryResultHolder {
    results: Vec<Result<Vec<u8>, String>>,
}

impl QueryResultHolder {
    pub fn take<T: SingleQueryResultExtractor>(&self, index: usize) -> Result<T> {
        match self.results.get(index) {
            Some(Ok(bytes)) => T::from_bytes(bytes),
            Some(Err(e)) => Err(anyhow!(
                "Database query failed for statement {}: {}",
                index,
                e
            )),
            None => Err(anyhow!("Result index {} out of bounds", index)),
        }
    }

    pub fn take_result<T: SingleQueryResultExtractor>(
        &self,
        index: usize,
    ) -> Result<std::result::Result<T, String>> {
        if let Some(e) = self.find_user_error() {
            Ok(Err(e))
        } else {
            let result = self.take::<T>(index)?;
            Ok(Ok(result))
        }
    }

    pub fn parse<D: DeserializeOwned>(&self, index: usize) -> Result<D> {
        match self.results.get(index) {
            Some(Ok(bytes)) => parse(bytes),
            Some(Err(e)) => Err(anyhow!(
                "Database query failed for statement {}: {}",
                index,
                e
            )),
            None => Err(anyhow!("Result index {} out of bounds", index)),
        }
    }

    pub fn parse_result<D: DeserializeOwned>(
        &self,
        index: usize,
    ) -> Result<std::result::Result<D, String>> {
        if let Some(e) = self.find_user_error() {
            Ok(Err(e))
        } else {
            let result = self.parse::<D>(index)?;
            Ok(Ok(result))
        }
    }

    fn find_user_error(&self) -> Option<String> {
        let Some(Err(e)) = self.results.iter().find(|r| {
            r.as_ref()
                .is_err_and(|e| e.starts_with("An error occurred: "))
        }) else {
            return None;
        };

        Some(
            e.strip_prefix("An error occurred: ")
                .unwrap_or(e)
                .to_string(),
        )
    }

    pub fn len(&self) -> usize {
        self.results.len()
    }
}

pub struct Query<'a> {
    query_str: &'a str,
    params: Vec<(String, Vec<u8>)>,
    bind_error: Option<anyhow::Error>,
}

impl<'a> Query<'a> {
    pub fn bind<T: Serialize>(mut self, key: &str, value: T) -> Self {
        if self.bind_error.is_some() {
            return self;
        }

        match serde_cbor::to_vec(&value) {
            Ok(bytes) => {
                self.params.push((key.to_string(), bytes));
            }
            Err(e) => {
                self.bind_error = Some(
                    anyhow!(e).context(format!("CBOR serialization failed for key '{}'", key)),
                );
            }
        }
        self
    }

    pub fn execute(self) -> Result<QueryResultHolder> {
        if let Some(err) = self.bind_error {
            return Err(err);
        }
        let raw_results = call::query(self.query_str, &self.params);
        Ok(QueryResultHolder {
            results: raw_results,
        })
    }
}

pub fn query(query_str: &str) -> Query<'_> {
    Query {
        query_str,
        params: Vec::new(),
        bind_error: None,
    }
}
