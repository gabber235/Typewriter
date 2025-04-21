wit_bindgen::generate!({ generate_all });

use crate::seamlezz::surrealdb::call;
use anyhow::{Context, Result, anyhow};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use serde_content::{Deserializer, Value};

pub trait SingleQueryResultExtractor: Sized {
    fn from_bytes(bytes: &[u8]) -> Result<Self>;
}

impl<D> SingleQueryResultExtractor for Vec<D>
where
    D: DeserializeOwned,
{
    fn from_bytes(bytes: &[u8]) -> Result<Self> {
        let value: Value = serde_cbor::from_slice(bytes).context("CBOR Deserialization failed")?;
        let deserializer = Deserializer::new(value).coerce_numbers();
        Vec::<D>::deserialize(deserializer).context("Deserialization content error")
    }
}

impl<D> SingleQueryResultExtractor for Option<D>
where
    D: DeserializeOwned,
{
    fn from_bytes(bytes: &[u8]) -> Result<Self> {
        let value: Value = serde_cbor::from_slice(bytes).context("CBOR Deserialization failed")?;
        let deserializer = Deserializer::new(value).coerce_numbers();
        let items = Vec::<D>::deserialize(deserializer).context("Deserialization content error")?;
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

pub fn query(query_str: &str) -> Query {
    Query {
        query_str,
        params: Vec::new(),
        bind_error: None,
    }
}
