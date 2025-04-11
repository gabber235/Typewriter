pub(crate) mod bindings {
    use crate::SurrealDBTestComponent;
    wit_bindgen::generate!({ generate_all });
    export!(SurrealDBTestComponent);
}

use bindings::seamlezz::surrealdb::call;
// use bindings::wasi::logging::logging::*;
use bindings::exports::seamlezz::surrealdb_test::test::Guest;

struct SurrealDBTestComponent;

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct SurrealDBTestComponentData {
    pub id: surrealdb::sql::Thing,
    pub text: String,
    pub number: i32,
}

impl Guest for SurrealDBTestComponent {
    fn call() -> String {
        let result = call::query(
            "UPSERT test:test SET text = $txt, number = $number",
            &[
                (
                    "txt".to_string(),
                    serde_cbor::to_vec(&"Hello from SurrealDB testing component!".to_string())
                        .expect("failed to serialize"),
                ),
                (
                    "number".to_string(),
                    serde_cbor::to_vec(&42).expect("failed to serialize"),
                ),
            ],
        );
        let mut print = String::new();
        for r in result {
            match r {
                Ok(v) => {
                    let value: surrealdb_core::sql::Value = serde_cbor::from_slice(&v).unwrap();
                    let data = ser::from_value::<Vec<SurrealDBTestComponentData>>(value);
                    print.push_str(&format!("Result: {:?}\n", data));
                }
                Err(e) => {
                    print.push_str(&format!("Error: {:?}\n", e));
                }
            }
        }
        return print;
    }
}

mod ser {
    use serde::de::DeserializeOwned;
    use serde_content::Deserializer;
    use serde_content::Number;
    use serde_content::Serializer;
    use serde_content::Value as Content;
    use std::borrow::Cow;
    use surrealdb::sql::Value;
    use surrealdb_core::err::Error;
    use surrealdb_core::sql;

    fn into_content(value: Value) -> Result<Content<'static>, Error> {
        let serializer = Serializer::new();
        match value {
            Value::None => Ok(Content::Option(None)),
            Value::Null => Ok(Content::Option(None)),
            Value::Bool(v) => Ok(Content::Bool(v)),
            Value::Number(v) => match v {
                sql::Number::Int(v) => Ok(Content::Number(Number::I64(v))),
                sql::Number::Float(v) => Ok(Content::Number(Number::F64(v))),
                sql::Number::Decimal(v) => serializer.serialize(v).map_err(Into::into),
                _ => Err(Error::Thrown("Could not serialize number".to_string())),
            },
            Value::Strand(v) => Ok(Content::String(Cow::Owned(v.0))),
            Value::Duration(v) => serializer.serialize(v.0).map_err(Into::into),
            Value::Datetime(v) => serializer.serialize(v.0).map_err(Into::into),
            Value::Uuid(v) => serializer.serialize(v.0).map_err(Into::into),
            Value::Array(v) => {
                let mut vec = Vec::with_capacity(v.0.len());
                for value in v.0 {
                    vec.push(into_content(value)?);
                }
                Ok(Content::Seq(vec))
            }
            Value::Object(v) => {
                let mut vec = Vec::with_capacity(v.0.len());
                for (key, value) in v.0 {
                    let key = Content::String(Cow::Owned(key));
                    let value = into_content(value)?;
                    vec.push((key, value));
                }
                Ok(Content::Map(vec))
            }
            Value::Geometry(v) => match v {
                sql::Geometry::Point(v) => serializer.serialize(v).map_err(Into::into),
                sql::Geometry::Line(v) => serializer.serialize(v).map_err(Into::into),
                sql::Geometry::Polygon(v) => serializer.serialize(v).map_err(Into::into),
                sql::Geometry::MultiPoint(v) => serializer.serialize(v).map_err(Into::into),
                sql::Geometry::MultiLine(v) => serializer.serialize(v).map_err(Into::into),
                sql::Geometry::MultiPolygon(v) => serializer.serialize(v).map_err(Into::into),
                sql::Geometry::Collection(v) => serializer.serialize(v).map_err(Into::into),
                _ => Err(Error::Thrown("Could not serialize geometry".to_string())),
            },
            Value::Bytes(v) => Ok(Content::Bytes(Cow::Owned(v.into()))),
            Value::Thing(v) => serializer.serialize(v).map_err(Into::into),
            Value::Param(v) => serializer.serialize(v.0).map_err(Into::into),
            Value::Idiom(v) => serializer.serialize(v.0).map_err(Into::into),
            Value::Table(v) => serializer.serialize(v.0).map_err(Into::into),
            Value::Mock(v) => serializer.serialize(v).map_err(Into::into),
            Value::Regex(v) => serializer.serialize(v).map_err(Into::into),
            Value::Cast(v) => serializer.serialize(v).map_err(Into::into),
            Value::Block(v) => serializer.serialize(v).map_err(Into::into),
            Value::Range(v) => serializer.serialize(v).map_err(Into::into),
            Value::Edges(v) => serializer.serialize(v).map_err(Into::into),
            Value::Future(v) => serializer.serialize(v).map_err(Into::into),
            Value::Constant(v) => serializer.serialize(v).map_err(Into::into),
            Value::Function(v) => serializer.serialize(v).map_err(Into::into),
            Value::Subquery(v) => serializer.serialize(v).map_err(Into::into),
            Value::Expression(v) => serializer.serialize(v).map_err(Into::into),
            Value::Query(v) => serializer.serialize(v).map_err(Into::into),
            Value::Model(v) => serializer.serialize(v).map_err(Into::into),
            Value::Closure(v) => serializer.serialize(v).map_err(Into::into),
            Value::Refs(_) => Ok(Content::Seq(vec![])),
            _ => Err(Error::Thrown("Could not serialize value".to_string())),
        }
    }

    /// Deserializes a value `T` from `SurrealDB` [`Value`]
    pub fn from_value<T>(value: Value) -> Result<T, Error>
    where
        T: DeserializeOwned,
    {
        let content = into_content(value)?;
        let deserializer = Deserializer::new(content).coerce_numbers();
        T::deserialize(deserializer).map_err(Into::into)
    }
}
