wit_bindgen::generate!({ generate_all });

mod types;

pub use types::{Datetime, RecordId, RecordIdKey};

use crate::seamlezz::surrealdb::call;
use anyhow::{anyhow, Context, Result};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};

pub trait SingleQueryResultExtractor: Sized {
    fn from_bytes(bytes: &[u8]) -> Result<Self>;
}

fn parse<D: DeserializeOwned>(bytes: &[u8]) -> Result<D> {
    ciborium::from_reader(bytes).with_context(|| {
        let json_preview: Result<serde_json::Value, _> = ciborium::from_reader(bytes);
        format!(
            "CBOR Deserialization failed, data preview: {:?}, target type: {}",
            json_preview.ok(),
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
        let items: Vec<D> = parse(bytes)?;
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
        let mut error_messages = Vec::new();

        for (idx, result) in self.results.iter().enumerate() {
            if let Err(err) = result {
                let err_str = err.to_string();
                if err_str.contains("The query was not executed due to a failed transaction") {
                    continue;
                }
                error_messages.push(format!("Statement {}: {}", idx, err_str));
            }
        }

        if error_messages.is_empty() {
            None
        } else {
            Some(error_messages.join("; "))
        }
    }

    pub fn len(&self) -> usize {
        self.results.len()
    }

    pub fn is_empty(&self) -> bool {
        self.results.is_empty()
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

        let mut bytes = Vec::new();
        match ciborium::into_writer(&value, &mut bytes) {
            Ok(()) => {
                self.params.push((key.to_string(), bytes));
            }
            Err(e) => {
                self.bind_error = Some(
                    anyhow!(e.to_string()).context(format!("CBOR serialization failed for key '{}'", key)),
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
