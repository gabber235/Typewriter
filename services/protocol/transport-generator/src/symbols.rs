use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

use crate::manifest::SymbolRef;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SymbolDocument {
    pub methods: Vec<CanonicalMethod>,
    pub records: Vec<CanonicalRecord>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CanonicalMethod {
    pub module: String,
    pub name: String,
    pub number: u64,
    pub request: CanonicalType,
    pub response: CanonicalType,
    pub source: Source,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CanonicalRecord {
    pub key: String,
    pub module: String,
    pub path: Vec<String>,
    pub kind: RecordKind,
    pub declaration_number: Option<u64>,
    pub source: Source,
    pub fields: Vec<CanonicalField>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RecordKind {
    Struct,
    Enum,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CanonicalField {
    pub name: String,
    pub number: u64,
    #[serde(rename = "type")]
    pub field_type: Option<CanonicalType>,
    pub source: Source,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum CanonicalType {
    Primitive { primitive: String },
    Record { key: String },
    Array { item: Box<CanonicalType> },
    Optional { other: Box<CanonicalType> },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Source {
    pub module: String,
    pub line: usize,
    pub column: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LanguageBindings {
    pub language: Language,
    pub methods: Vec<MethodNames>,
    pub records: Vec<RecordNames>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Language {
    Kotlin,
    Dart,
    Rust,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MethodNames {
    pub module: String,
    pub name: String,
    pub method: BindingReference,
    pub request_type: String,
    pub response_type: String,
    #[serde(default)]
    pub imports: Vec<BindingImport>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BindingImport {
    pub import_uri: String,
    pub alias: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(
    tag = "language",
    rename_all = "snake_case",
    rename_all_fields = "camelCase"
)]
pub enum BindingReference {
    Kotlin {
        package_name: String,
        symbol: String,
    },
    Dart {
        import_uri: String,
        symbol: String,
        alias: String,
    },
    Rust {
        absolute_path: String,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RecordNames {
    pub key: String,
    #[serde(rename = "type")]
    pub target_type: String,
    #[serde(default)]
    pub binding: Option<BindingReference>,
    pub fields: Vec<FieldNames>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FieldNames {
    pub source_name: String,
    pub target_name: String,
}

pub struct CanonicalSymbols {
    methods: BTreeMap<(String, String), CanonicalMethod>,
    records: BTreeMap<(String, Vec<String>), CanonicalRecord>,
    records_by_key: BTreeMap<String, CanonicalRecord>,
    method_names: BTreeMap<(String, String), MethodNames>,
    record_names: BTreeMap<String, RecordNames>,
}

impl CanonicalSymbols {
    pub fn new(document: SymbolDocument, bindings: LanguageBindings) -> Result<Self, String> {
        let mut methods = BTreeMap::new();
        for method in document.methods {
            let key = (method.module.clone(), method.name.clone());
            if methods.insert(key, method).is_some() {
                return Err("duplicate canonical method export".to_owned());
            }
        }
        let mut records = BTreeMap::new();
        let mut records_by_key = BTreeMap::new();
        for record in document.records {
            let path_key = (record.module.clone(), record.path.clone());
            if records.insert(path_key, record.clone()).is_some()
                || records_by_key.insert(record.key.clone(), record).is_some()
            {
                return Err("duplicate canonical record export".to_owned());
            }
        }
        let mut method_names = BTreeMap::new();
        for method in bindings.methods {
            let key = (method.module.clone(), method.name.clone());
            if method_names.insert(key, method).is_some() {
                return Err("duplicate method binding export".to_owned());
            }
        }
        let mut record_names = BTreeMap::new();
        for record in bindings.records {
            if record_names.insert(record.key.clone(), record).is_some() {
                return Err("duplicate record binding export".to_owned());
            }
        }
        Ok(Self {
            methods,
            records,
            records_by_key,
            method_names,
            record_names,
        })
    }

    pub fn method(
        &self,
        reference: &SymbolRef,
    ) -> Result<(&CanonicalMethod, &MethodNames), String> {
        if reference.path.len() != 1 {
            return Err(format!("method reference must be top level: {reference:?}"));
        }
        let key = (reference.module.clone(), reference.path[0].clone());
        Ok((
            self.methods
                .get(&key)
                .ok_or_else(|| format!("unknown method {reference:?}"))?,
            self.method_names
                .get(&key)
                .ok_or_else(|| format!("missing method binding {reference:?}"))?,
        ))
    }

    pub fn record(
        &self,
        reference: &SymbolRef,
    ) -> Result<(&CanonicalRecord, &RecordNames), String> {
        let record = self
            .records
            .get(&(reference.module.clone(), reference.path.clone()))
            .ok_or_else(|| format!("unknown record {reference:?}"))?;
        Ok((
            record,
            self.record_names
                .get(&record.key)
                .ok_or_else(|| format!("missing record binding for {}", record.key))?,
        ))
    }

    pub fn record_by_key(&self, key: &str) -> Result<(&CanonicalRecord, &RecordNames), String> {
        let record = self
            .records_by_key
            .get(key)
            .ok_or_else(|| format!("unknown record key {key}"))?;
        Ok((
            record,
            self.record_names
                .get(key)
                .ok_or_else(|| format!("missing record binding for {key}"))?,
        ))
    }
}
