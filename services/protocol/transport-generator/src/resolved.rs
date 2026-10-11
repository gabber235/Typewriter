use std::sync::Arc;

use crate::{
    manifest::{
        ComponentSubscription, Delivery, Endpoints, Grant, KotlinSymbol, KotlinTarget,
        NativeKotlinFormat, RouteName, ScopeKind, Side, SymbolRef,
    },
    subject::{Parameter, SubjectTemplate},
    symbols::{BindingImport, BindingReference, CanonicalType},
};

#[derive(Clone)]
pub struct NativeKotlinRequestResponseBinding {
    pub format: NativeKotlinFormat,
    pub target: KotlinTarget,
    pub request_type: KotlinSymbol,
    pub response_type: KotlinSymbol,
    pub request_codec: KotlinSymbol,
    pub response_codec: KotlinSymbol,
}

#[derive(Clone)]
pub struct NativeKotlinEventBinding {
    pub format: NativeKotlinFormat,
    pub target: KotlinTarget,
    pub event_type: KotlinSymbol,
    pub event_codec: KotlinSymbol,
}

pub enum ResolvedEventBinding {
    Skir(Arc<RecordBinding>),
    NativeKotlin(NativeKotlinEventBinding),
}

pub struct MethodBinding {
    pub reference: SymbolRef,
    pub request: Arc<RecordBinding>,
    pub response: Arc<RecordBinding>,
    pub target: BindingReference,
    pub target_request_type: String,
    pub target_response_type: String,
    pub imports: Vec<BindingImport>,
}

pub struct RecordBinding {
    pub key: String,
    pub fields: Vec<FieldBinding>,
    pub target_type: String,
    pub target: Option<BindingReference>,
    pub kind: crate::symbols::RecordKind,
}

pub struct FieldBinding {
    pub source_name: String,
    pub field_type: Option<CanonicalType>,
    pub target_name: String,
}

pub struct ResolvedEvent {
    pub payload: Arc<RecordBinding>,
    pub addresses: Endpoints,
    pub delivery: Delivery,
}

pub struct ResolvedEventEndpoint {
    pub subject: SubjectTemplate,
    pub subscription_wildcards: std::collections::BTreeSet<Parameter>,
}

pub type ResolvedEventEndpoints = std::collections::BTreeMap<Side, ResolvedEventEndpoint>;

pub enum ResolvedFlow {
    Unary {
        method: Arc<MethodBinding>,
        requests: Endpoints,
    },
    Watch {
        method: Arc<MethodBinding>,
        requests: Endpoints,
        updates: ResolvedEvent,
    },
    BoundedWatch {
        method: Arc<MethodBinding>,
        requests: Endpoints,
        updates: Endpoints,
        transfer_field: usize,
    },
    Scatter {
        binding: NativeKotlinRequestResponseBinding,
        requests: Endpoints,
    },
    Event {
        binding: ResolvedEventBinding,
        addresses: ResolvedEventEndpoints,
        delivery: Delivery,
    },
}

pub struct ResolvedRoute {
    pub name: RouteName,
    pub scope: ScopeKind,
    pub grants: Vec<Grant>,
    pub subscription: Option<ComponentSubscription>,
    pub operation: String,
    pub failure_slug: String,
    pub flow: ResolvedFlow,
}

impl RecordBinding {
    pub fn string_field(&self, name: &str) -> Result<usize, String> {
        self.fields
            .iter()
            .enumerate()
            .find_map(|(index, field)| {
                (field.source_name == name
                    && matches!(
                        field.field_type,
                        Some(CanonicalType::Primitive { ref primitive }) if primitive == "string"
                    ))
                .then_some(index)
            })
            .ok_or_else(|| format!("expected string field {name} on {}", self.key))
    }

    pub fn rust_type(&self) -> Result<syn::Type, String> {
        syn::parse_str(&self.target_type)
            .map_err(|error| format!("invalid generated Rust type {}: {error}", self.target_type))
    }
}

impl MethodBinding {
    pub fn rust_method(&self) -> Result<syn::Path, String> {
        match &self.target {
            BindingReference::Rust { absolute_path } => syn::parse_str(absolute_path)
                .map_err(|error| format!("invalid generated Rust method {absolute_path}: {error}")),
            _ => Err("Rust emission requires Rust binding metadata".to_owned()),
        }
    }
}
