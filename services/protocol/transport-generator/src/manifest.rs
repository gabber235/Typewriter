use std::collections::{BTreeMap, BTreeSet};

use serde::{Deserialize, Serialize};

use crate::subject::SubjectTemplate;

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Manifest {
    pub routes: Vec<Route>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Route {
    pub name: RouteName,
    pub scope: ScopeKind,
    pub grants: Vec<Grant>,
    pub subscription: Option<ComponentSubscription>,
    pub flow: Flow,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case", deny_unknown_fields)]
pub enum Flow {
    Unary {
        method: SymbolRef,
        requests: Endpoints,
        operation: String,
        failure_slug: String,
    },
    Watch {
        method: SymbolRef,
        requests: Endpoints,
        updates: Event,
        operation: String,
        failure_slug: String,
    },
    BoundedWatch {
        method: SymbolRef,
        requests: Endpoints,
        updates: Endpoints,
        transfer_field: String,
        operation: String,
        failure_slug: String,
    },
    Scatter {
        binding: RequestResponseBinding,
        requests: Endpoints,
        operation: String,
        failure_slug: String,
    },
    Event {
        binding: EventBinding,
        addresses: EventEndpoints,
        delivery: Delivery,
        operation: String,
        failure_slug: String,
    },
}

#[derive(Debug, Clone, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case", deny_unknown_fields)]
pub enum RequestResponseBinding {
    Skir {
        method: SymbolRef,
    },
    NativeKotlin {
        format: NativeKotlinFormat,
        target: KotlinTarget,
        request_type: KotlinSymbol,
        response_type: KotlinSymbol,
        request_codec: KotlinSymbol,
        response_codec: KotlinSymbol,
    },
}

#[derive(Debug, Clone, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case", deny_unknown_fields)]
pub enum EventBinding {
    Skir {
        payload: SymbolRef,
    },
    NativeKotlin {
        format: NativeKotlinFormat,
        target: KotlinTarget,
        event_type: KotlinSymbol,
        event_codec: KotlinSymbol,
    },
}

#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum NativeKotlinFormat {
    KotlinSerializationCbor,
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
#[serde(try_from = "String")]
pub struct KotlinTarget(String);

impl KotlinTarget {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl TryFrom<String> for KotlinTarget {
    type Error = String;

    fn try_from(value: String) -> Result<Self, Self::Error> {
        if value != "loader_core" {
            return Err(format!("unsupported Kotlin generator target {value:?}"));
        }
        Ok(Self(value))
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
#[serde(try_from = "String")]
pub struct KotlinSymbol(String);

impl KotlinSymbol {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl TryFrom<String> for KotlinSymbol {
    type Error = String;

    fn try_from(value: String) -> Result<Self, Self::Error> {
        let valid = value.split('.').all(|part| {
            !part.is_empty()
                && part.bytes().enumerate().all(|(index, byte)| {
                    byte == b'_'
                        || byte.is_ascii_alphabetic()
                        || (index > 0 && byte.is_ascii_digit())
                })
        });
        if !valid {
            return Err(format!("invalid Kotlin symbol {value:?}"));
        }
        Ok(Self(value))
    }
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Event {
    pub payload: SymbolRef,
    pub addresses: Endpoints,
    pub delivery: Delivery,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case", deny_unknown_fields)]
pub enum Delivery {
    Transient,
    Persistent {
        stream: String,
        projection: RouteName,
        consumer: ConsumerOwnership,
    },
}

#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ConsumerOwnership {
    ConnectionProjection,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ScopeKind {
    Realm,
    Service,
    BoundService,
    OrganizationActor,
    Organization,
    User,
    Native,
    InternalComponent,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Side {
    Panel,
    Service,
    Backend,
    BackendInternal,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Role {
    AuthenticatedUser,
    OrganizationMember,
    RealmCoordinator,
    RealmParticipant,
    RegisteredService,
    NativeClient,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Channel {
    Request,
    Updates,
    Event,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Direction {
    Publish,
    Subscribe,
}

pub type Endpoints = BTreeMap<Side, SubjectTemplate>;
pub type EventEndpoints = BTreeMap<Side, EventEndpoint>;

#[derive(Debug, Clone, Deserialize)]
#[serde(untagged)]
pub enum EventEndpoint {
    Direct(SubjectTemplate),
    Directed {
        subject: SubjectTemplate,
        subscription: Option<SubscriptionProjection>,
    },
}

#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct SubscriptionProjection {
    pub wildcard: BTreeSet<crate::subject::Parameter>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ComponentSubscription {
    pub component: ComponentName,
    pub group: ConsumerGroup,
}

macro_rules! closed_identifier {
    ($name:ident, $label:literal) => {
        #[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Deserialize)]
        #[serde(try_from = "String")]
        pub struct $name(String);

        impl $name {
            pub fn as_str(&self) -> &str {
                &self.0
            }
        }

        impl TryFrom<String> for $name {
            type Error = String;
            fn try_from(value: String) -> Result<Self, Self::Error> {
                let valid = !value.is_empty()
                    && value.bytes().all(|byte| {
                        byte.is_ascii_lowercase()
                            || byte.is_ascii_digit()
                            || byte == b'_'
                            || byte == b'-'
                            || byte == b'.'
                    });
                if !valid {
                    return Err(format!("invalid {} {:?}", $label, value));
                }
                Ok(Self(value))
            }
        }
    };
}

closed_identifier!(ComponentName, "component name");
closed_identifier!(ConsumerGroup, "consumer group");

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Grant {
    pub role: Role,
    pub side: Side,
    pub channel: Channel,
    pub direction: Direction,
}

impl Manifest {
    pub fn parse(source: &str) -> Result<Self, serde_saphyr::Error> {
        serde_saphyr::from_str(source)
    }

    pub fn component_subscriptions(&self) -> Result<BTreeMap<String, BTreeSet<String>>, String> {
        let mut subscriptions: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
        for route in &self.routes {
            let Some(binding) = &route.subscription else {
                continue;
            };
            let Flow::Unary { requests, .. } = &route.flow else {
                return Err(format!(
                    "component subscription {} must be unary",
                    route.name
                ));
            };
            let subject = requests.get(&Side::BackendInternal).ok_or_else(|| {
                format!(
                    "component subscription {} requires backend_internal",
                    route.name
                )
            })?;
            if subject
                .tokens()
                .iter()
                .any(|token| matches!(token, crate::subject::Token::Parameter(_)))
            {
                return Err(format!(
                    "component subscription {} must be exact",
                    route.name
                ));
            }
            let value = format!("{}:{}", subject, binding.group.as_str());
            if !subscriptions
                .entry(binding.component.as_str().to_owned())
                .or_default()
                .insert(value)
            {
                return Err(format!(
                    "duplicate component subscription in {}",
                    route.name
                ));
            }
        }
        Ok(subscriptions)
    }

    pub fn validate_component_subscriptions(
        &self,
        component: &str,
        actual: &str,
    ) -> Result<(), String> {
        let expected = self
            .component_subscriptions()?
            .remove(component)
            .ok_or_else(|| format!("component {component:?} has no canonical subscriptions"))?;
        let actual_values = actual
            .split(',')
            .filter(|value| !value.is_empty())
            .map(str::to_owned)
            .collect::<Vec<_>>();
        let actual = actual_values.iter().cloned().collect::<BTreeSet<_>>();
        if actual.len() != actual_values.len() {
            return Err(format!("duplicate component subscription for {component}"));
        }
        if actual != expected {
            return Err(format!(
                "component subscription drift for {component}: expected {expected:?}, received {actual:?}"
            ));
        }
        Ok(())
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(try_from = "String", into = "String")]
pub struct RouteName(String);

impl TryFrom<String> for RouteName {
    type Error = String;

    fn try_from(value: String) -> Result<Self, Self::Error> {
        let valid = value.bytes().enumerate().all(|(index, byte)| {
            byte.is_ascii_lowercase() || byte == b'_' || (index > 0 && byte.is_ascii_digit())
        });
        if value.is_empty() || !valid {
            return Err(format!("invalid route identifier {value:?}"));
        }
        Ok(Self(value))
    }
}

impl From<RouteName> for String {
    fn from(value: RouteName) -> Self {
        value.0
    }
}

impl std::fmt::Display for RouteName {
    fn fmt(&self, output: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        output.write_str(&self.0)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(try_from = "String", into = "String")]
pub struct SymbolRef {
    pub module: String,
    pub path: Vec<String>,
}

impl TryFrom<String> for SymbolRef {
    type Error = String;

    fn try_from(value: String) -> Result<Self, Self::Error> {
        let (module, path) = value
            .split_once(':')
            .ok_or_else(|| "expected module.skir:Declaration".to_owned())?;
        if !module.ends_with(".skir")
            || module.starts_with('/')
            || module
                .split('/')
                .any(|part| part.is_empty() || part == "..")
        {
            return Err(format!("invalid canonical module path {module:?}"));
        }
        let path = path.split('.').map(str::to_owned).collect::<Vec<_>>();
        if path.is_empty()
            || path
                .iter()
                .any(|part| part.is_empty() || part.chars().any(char::is_whitespace))
        {
            return Err("invalid canonical declaration path".to_owned());
        }
        Ok(Self {
            module: module.to_owned(),
            path,
        })
    }
}

impl From<SymbolRef> for String {
    fn from(value: SymbolRef) -> Self {
        format!("{}:{}", value.module, value.path.join("."))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::symbols::{
        BindingReference, CanonicalField, CanonicalMethod, CanonicalRecord, CanonicalSymbols,
        CanonicalType, FieldNames, Language, LanguageBindings, MethodNames, RecordKind,
        RecordNames, Source, SymbolDocument,
    };

    #[test]
    fn complete_route_inventory_parses() {
        let manifest = Manifest::parse(include_str!("../../transport-routes.yaml")).unwrap();
        assert_eq!(manifest.routes.len(), 61);
        let symbols = manifest.requested_symbols();
        assert_eq!(symbols.methods.len(), 51);
        assert_eq!(symbols.records.len(), 17);
        manifest
            .validate_component_subscriptions(
                "auth-typewriter-permissions",
                "auth.permissions.typewriter-panel:typewriter.auth-auth-typewriter-permissions,auth.permissions.typewriter-services:typewriter.auth-auth-typewriter-permissions",
            )
            .unwrap();
        assert!(
            manifest
                .validate_component_subscriptions(
                    "auth-typewriter-permissions",
                    "auth.permissions.*:typewriter.auth-auth-typewriter-permissions",
                )
                .is_err()
        );
    }

    #[test]
    fn complete_inventory_emits_rust_from_canonical_metadata() {
        let manifest = Manifest::parse(include_str!("../../transport-routes.yaml")).unwrap();
        let source = |module: &str| Source {
            module: module.to_owned(),
            line: 1,
            column: 1,
        };
        let mut methods = BTreeMap::new();
        let mut records = BTreeMap::new();
        for route in &manifest.routes {
            let (method, transfer_field) = match &route.flow {
                Flow::Unary { method, .. } | Flow::Watch { method, .. } => (Some(method), None),
                Flow::BoundedWatch {
                    method,
                    transfer_field,
                    ..
                } => (Some(method), Some(transfer_field.as_str())),
                Flow::Scatter {
                    binding: RequestResponseBinding::Skir { method },
                    ..
                } => (Some(method), None),
                Flow::Scatter {
                    binding: RequestResponseBinding::NativeKotlin { .. },
                    ..
                }
                | Flow::Event { .. } => (None, None),
            };
            if let Some(method) = method {
                let name = method.path[0].clone();
                let request_key = format!("{}:{name}Request", method.module);
                let response_key = format!("{}:{name}Response", method.module);
                let request_fields = transfer_field
                    .map(|field| {
                        vec![CanonicalField {
                            name: field.to_owned(),
                            number: 1,
                            field_type: Some(CanonicalType::Primitive {
                                primitive: "string".to_owned(),
                            }),
                            source: source(&method.module),
                        }]
                    })
                    .unwrap_or_default();
                records
                    .entry(request_key.clone())
                    .or_insert_with(|| CanonicalRecord {
                        key: request_key.clone(),
                        module: method.module.clone(),
                        path: vec![format!("{name}Request")],
                        kind: RecordKind::Struct,
                        declaration_number: Some(1),
                        source: source(&method.module),
                        fields: request_fields,
                    });
                records
                    .entry(response_key.clone())
                    .or_insert_with(|| CanonicalRecord {
                        key: response_key.clone(),
                        module: method.module.clone(),
                        path: vec![format!("{name}Response")],
                        kind: RecordKind::Enum,
                        declaration_number: Some(2),
                        source: source(&method.module),
                        fields: vec![],
                    });
                methods
                    .entry((method.module.clone(), name.clone()))
                    .or_insert_with(|| CanonicalMethod {
                        module: method.module.clone(),
                        name,
                        number: 1,
                        request: CanonicalType::Record { key: request_key },
                        response: CanonicalType::Record { key: response_key },
                        source: source(&method.module),
                    });
            }
            let event = match &route.flow {
                Flow::Watch { updates, .. } => Some(&updates.payload),
                Flow::Event {
                    binding: EventBinding::Skir { payload },
                    ..
                } => Some(payload),
                _ => None,
            };
            if let Some(event) = event {
                let key = format!("{}:{}", event.module, event.path.join("."));
                records
                    .entry(key.clone())
                    .or_insert_with(|| CanonicalRecord {
                        key,
                        module: event.module.clone(),
                        path: event.path.clone(),
                        kind: RecordKind::Struct,
                        declaration_number: Some(3),
                        source: source(&event.module),
                        fields: vec![],
                    });
            }
        }
        let document = SymbolDocument {
            methods: methods.values().cloned().collect(),
            records: records.values().cloned().collect(),
        };
        let bindings = LanguageBindings {
            language: Language::Rust,
            methods: methods
                .values()
                .map(|method| MethodNames {
                    module: method.module.clone(),
                    name: method.name.clone(),
                    method: BindingReference::Rust {
                        absolute_path: format!("crate::skirout::fixture::{}_method", method.name),
                    },
                    request_type: match &method.request {
                        CanonicalType::Record { key } => {
                            format!("crate::skirout::fixture::{}", records[key].path.join("_"))
                        }
                        _ => unreachable!(),
                    },
                    response_type: match &method.response {
                        CanonicalType::Record { key } => {
                            format!("crate::skirout::fixture::{}", records[key].path.join("_"))
                        }
                        _ => unreachable!(),
                    },
                    imports: vec![],
                })
                .collect(),
            records: records
                .values()
                .map(|record| RecordNames {
                    key: record.key.clone(),
                    target_type: format!("crate::skirout::fixture::{}", record.path.join("_")),
                    binding: Some(BindingReference::Rust {
                        absolute_path: format!(
                            "crate::skirout::fixture::{}",
                            record.path.join("_")
                        ),
                    }),
                    fields: record
                        .fields
                        .iter()
                        .map(|field| FieldNames {
                            source_name: field.name.clone(),
                            target_name: field.name.clone(),
                        })
                        .collect(),
                })
                .collect(),
        };
        let symbols = CanonicalSymbols::new(document, bindings).unwrap();
        let routes = manifest.resolve(&symbols).unwrap();
        let loader_files = crate::kotlin::emit_loader(&routes).unwrap();
        assert_eq!(loader_files.len(), 1);
        assert_eq!(loader_files[0].path, "RolloutRoutes.kt");
        assert!(
            loader_files[0]
                .code
                .contains("fun RealmRouteScope.realmHostsProbe")
        );
        assert!(loader_files[0].code.contains("RolloutCodecs.probeRequest"));
        assert!(
            loader_files[0]
                .code
                .contains("val RealmRouteScope.realmRolloutState")
        );
        assert!(
            loader_files[0]
                .code
                .contains("RolloutCodecs.participantState")
        );
        let files = crate::rust::emit(&routes).unwrap();
        assert_eq!(files.len(), 1);
        assert!(
            files[0]
                .code
                .contains("impl OutboundRequestRoute for ServiceBindingQueryRoute")
        );
        assert!(
            !files[0]
                .code
                .contains("impl OutboundRequestRoute for EditorCatalogFetchRoute")
        );
        assert!(
            files[0]
                .code
                .contains("impl OutboundEventRoute for UserOrganizationsWatchRoute")
        );
        assert!(
            files[0]
                .code
                .contains("impl PersistentEventRoute for UserOrganizationsWatchRoute")
        );
        assert!(
            !files[0]
                .code
                .contains("impl TransientEventRoute for UserOrganizationsWatchRoute")
        );
        assert!(
            files[0]
                .code
                .contains("impl OutboundEventRoute for OrganizationTopologyWatchRoute")
        );
        assert!(
            files[0]
                .code
                .contains("impl TransientEventRoute for OrganizationTopologyWatchRoute")
        );
        assert!(
            !files[0]
                .code
                .contains("impl PersistentEventRoute for OrganizationTopologyWatchRoute")
        );
        assert!(files[0].code.contains("type Scope = OrganizationScope;"));
    }

    #[test]
    fn rejects_duplicate_endpoint_keys() {
        let source = r#"
routes:
  - name: duplicate_endpoint
    scope: user
    grants: []
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: duplicate.endpoint
      failure_slug: duplicate-endpoint-failed
      requests:
        panel: "cloud.to.user.{user}.one"
        panel: "cloud.to.user.{user}.two"
"#;
        assert!(Manifest::parse(source).is_err());
    }
}
