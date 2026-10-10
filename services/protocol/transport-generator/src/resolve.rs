use std::{collections::BTreeSet, sync::Arc};

use crate::{
    manifest::{
        Channel, Endpoints, EventBinding, EventEndpoint, EventEndpoints, Flow, Manifest,
        RequestResponseBinding, ScopeKind, SymbolRef,
    },
    resolved::{
        FieldBinding, MethodBinding, NativeKotlinEventBinding, NativeKotlinRequestResponseBinding,
        RecordBinding, ResolvedEvent, ResolvedEventBinding, ResolvedEventEndpoint,
        ResolvedEventEndpoints, ResolvedFlow, ResolvedRoute,
    },
    symbols::{CanonicalSymbols, CanonicalType},
};

fn admit_grant_shape(route: &crate::manifest::Route) -> Result<(), String> {
    for grant in &route.grants {
        let addresses = match (&route.flow, grant.channel) {
            (Flow::Unary { requests, .. }, Channel::Request)
            | (Flow::Watch { requests, .. }, Channel::Request)
            | (Flow::BoundedWatch { requests, .. }, Channel::Request)
            | (Flow::Scatter { requests, .. }, Channel::Request) => requests,
            (Flow::Watch { updates, .. }, Channel::Updates) => &updates.addresses,
            (Flow::BoundedWatch { updates, .. }, Channel::Updates) => updates,
            (Flow::Event { addresses, .. }, Channel::Event) => {
                if !addresses.contains_key(&grant.side) {
                    return Err(format!(
                        "missing {:?} endpoint in {}",
                        grant.side, route.name
                    ));
                }
                continue;
            }
            _ => return Err(format!("invalid grant channel in {}", route.name)),
        };
        if !addresses.contains_key(&grant.side) {
            return Err(format!(
                "missing {:?} endpoint in {}",
                grant.side, route.name
            ));
        }
    }
    Ok(())
}

fn admit_event_endpoints(
    route: &crate::manifest::RouteName,
    addresses: EventEndpoints,
    scope: ScopeKind,
) -> Result<ResolvedEventEndpoints, String> {
    if addresses.is_empty() {
        return Err("endpoint set must not be empty".to_owned());
    }
    addresses
        .into_iter()
        .map(|(side, endpoint)| {
            let (subject, subscription_wildcards) = match endpoint {
                EventEndpoint::Direct(subject) => (subject, BTreeSet::new()),
                EventEndpoint::Directed {
                    subject,
                    subscription,
                } => (
                    subject,
                    subscription.map(|value| value.wildcard).unwrap_or_default(),
                ),
            };
            subject.validate_scope(scope, false).map_err(|error| {
                format!("route {route} event endpoint {side:?} is invalid: {error}")
            })?;
            for parameter in &subscription_wildcards {
                if !subject
                    .tokens()
                    .contains(&crate::subject::Token::Parameter(*parameter))
                {
                    return Err(format!(
                        "route {route} subscription projects an absent parameter"
                    ));
                }
                if !matches!(
                    (scope, parameter),
                    (
                        ScopeKind::OrganizationActor,
                        crate::subject::Parameter::User
                    )
                ) {
                    return Err(format!(
                        "route {route} subscription projects an authoritative scope identity"
                    ));
                }
            }
            Ok((
                side,
                ResolvedEventEndpoint {
                    subject,
                    subscription_wildcards,
                },
            ))
        })
        .collect()
}

fn admit_endpoints(
    route: &crate::manifest::RouteName,
    channel: Channel,
    addresses: &Endpoints,
    scope: ScopeKind,
    transfer: bool,
) -> Result<(), String> {
    if addresses.is_empty() {
        return Err("endpoint set must not be empty".to_owned());
    }
    for (side, subject) in addresses {
        let admitted = match channel {
            Channel::Request => subject.validate_request_scope(scope),
            Channel::Updates | Channel::Event => subject.validate_scope(scope, transfer),
        };
        let channel_name = match channel {
            Channel::Request => "request",
            Channel::Updates => "updates",
            Channel::Event => "event",
        };
        admitted.map_err(|error| {
            format!("route {route} {channel_name} endpoint {side:?} is invalid: {error}")
        })?;
    }
    Ok(())
}

fn record_binding(symbols: &CanonicalSymbols, key: &str) -> Result<Arc<RecordBinding>, String> {
    let (record, names) = symbols.record_by_key(key)?;
    let target_fields = names
        .fields
        .iter()
        .map(|field| (field.source_name.as_str(), field.target_name.as_str()))
        .collect::<std::collections::BTreeMap<_, _>>();
    let fields = record
        .fields
        .iter()
        .filter(|_| matches!(record.kind, crate::symbols::RecordKind::Struct))
        .map(|field| {
            Ok(FieldBinding {
                source_name: field.name.clone(),
                field_type: field.field_type.clone(),
                target_name: target_fields
                    .get(field.name.as_str())
                    .ok_or_else(|| format!("missing target field name for {}", field.name))?
                    .to_string(),
            })
        })
        .collect::<Result<Vec<_>, String>>()?;
    Ok(Arc::new(RecordBinding {
        key: record.key.clone(),
        fields,
        target_type: names.target_type.clone(),
        target: names.binding.clone(),
        kind: record.kind,
    }))
}

fn record_key(value: &CanonicalType) -> Result<&str, String> {
    match value {
        CanonicalType::Record { key } => Ok(key),
        _ => Err("transport methods must use record request and response types".to_owned()),
    }
}

fn method_binding(
    symbols: &CanonicalSymbols,
    reference: &SymbolRef,
) -> Result<Arc<MethodBinding>, String> {
    let (method, names) = symbols.method(reference)?;
    if let crate::symbols::BindingReference::Rust { absolute_path } = &names.method {
        syn::parse_str::<syn::Path>(absolute_path)
            .map_err(|error| format!("invalid generated Rust method path: {error}"))?;
        syn::parse_str::<syn::Type>(&names.request_type)
            .map_err(|error| format!("invalid generated Rust request type: {error}"))?;
        syn::parse_str::<syn::Type>(&names.response_type)
            .map_err(|error| format!("invalid generated Rust response type: {error}"))?;
    }
    Ok(Arc::new(MethodBinding {
        reference: reference.clone(),
        request: record_binding(symbols, record_key(&method.request)?)?,
        response: record_binding(symbols, record_key(&method.response)?)?,
        target: names.method.clone(),
        target_request_type: names.request_type.clone(),
        target_response_type: names.response_type.clone(),
        imports: names.imports.clone(),
    }))
}

impl Manifest {
    pub fn requested_symbols(&self) -> RequestedSymbols {
        let mut methods = BTreeSet::new();
        let mut records = BTreeSet::new();
        for route in &self.routes {
            match &route.flow {
                Flow::Unary { method, .. }
                | Flow::Watch { method, .. }
                | Flow::BoundedWatch { method, .. } => {
                    methods.insert(method.clone());
                }
                Flow::Scatter {
                    binding: RequestResponseBinding::Skir { method },
                    ..
                } => {
                    methods.insert(method.clone());
                }
                Flow::Event {
                    binding: EventBinding::Skir { payload },
                    ..
                } => {
                    records.insert(payload.clone());
                }
                Flow::Scatter {
                    binding: RequestResponseBinding::NativeKotlin { .. },
                    ..
                }
                | Flow::Event {
                    binding: EventBinding::NativeKotlin { .. },
                    ..
                } => {}
            }
            if let Flow::Watch { updates, .. } = &route.flow {
                records.insert(updates.payload.clone());
            }
        }
        RequestedSymbols {
            methods: methods
                .into_iter()
                .map(|reference| MethodRequest {
                    module: reference.module,
                    name: reference.path[0].clone(),
                })
                .collect(),
            records: records
                .into_iter()
                .map(|reference| RecordRequest {
                    module: reference.module,
                    path: reference.path,
                })
                .collect(),
        }
    }

    pub fn resolve(self, symbols: &CanonicalSymbols) -> Result<Vec<ResolvedRoute>, String> {
        let mut names = BTreeSet::new();
        for route in &self.routes {
            if !names.insert(route.name.clone()) {
                return Err(format!("duplicate logical route {}", route.name));
            }
            let mut grants = BTreeSet::new();
            for grant in &route.grants {
                if !grants.insert(grant.clone()) {
                    return Err(format!("duplicate grant in {}", route.name));
                }
            }
            admit_grant_shape(route)?;
            match route.scope {
                ScopeKind::InternalComponent => {
                    if !route.grants.is_empty() || route.subscription.is_none() {
                        return Err(format!(
                            "internal component route {} requires a subscription and no grants",
                            route.name
                        ));
                    }
                }
                _ if route.subscription.is_some() => {
                    return Err(format!(
                        "subscription metadata is invalid for {}",
                        route.name
                    ));
                }
                _ => {}
            }
        }
        self.routes
            .into_iter()
            .map(|route| {
                let (flow, operation, failure_slug) = match route.flow {
                    Flow::Unary {
                        method,
                        requests,
                        operation,
                        failure_slug,
                    } => {
                        admit_endpoints(
                            &route.name,
                            Channel::Request,
                            &requests,
                            route.scope,
                            false,
                        )?;
                        (
                            ResolvedFlow::Unary {
                                method: method_binding(symbols, &method)?,
                                requests,
                            },
                            operation,
                            failure_slug,
                        )
                    }
                    Flow::Watch {
                        method,
                        requests,
                        updates,
                        operation,
                        failure_slug,
                    } => {
                        admit_endpoints(
                            &route.name,
                            Channel::Request,
                            &requests,
                            route.scope,
                            false,
                        )?;
                        admit_endpoints(
                            &route.name,
                            Channel::Updates,
                            &updates.addresses,
                            route.scope,
                            false,
                        )?;
                        let (record, _) = symbols.record(&updates.payload)?;
                        (
                            ResolvedFlow::Watch {
                                method: method_binding(symbols, &method)?,
                                requests,
                                updates: ResolvedEvent {
                                    payload: record_binding(symbols, &record.key)?,
                                    addresses: updates.addresses,
                                    delivery: updates.delivery,
                                },
                            },
                            operation,
                            failure_slug,
                        )
                    }
                    Flow::BoundedWatch {
                        method,
                        requests,
                        updates,
                        transfer_field,
                        operation,
                        failure_slug,
                    } => {
                        admit_endpoints(
                            &route.name,
                            Channel::Request,
                            &requests,
                            route.scope,
                            false,
                        )?;
                        admit_endpoints(
                            &route.name,
                            Channel::Updates,
                            &updates,
                            route.scope,
                            true,
                        )?;
                        let method = method_binding(symbols, &method)?;
                        let transfer_field = method.request.string_field(&transfer_field)?;
                        (
                            ResolvedFlow::BoundedWatch {
                                method,
                                requests,
                                updates,
                                transfer_field,
                            },
                            operation,
                            failure_slug,
                        )
                    }
                    Flow::Scatter {
                        binding,
                        requests,
                        operation,
                        failure_slug,
                    } => {
                        admit_endpoints(
                            &route.name,
                            Channel::Request,
                            &requests,
                            route.scope,
                            false,
                        )?;
                        let RequestResponseBinding::NativeKotlin {
                            format,
                            target,
                            request_type,
                            response_type,
                            request_codec,
                            response_codec,
                        } = binding
                        else {
                            return Err(format!(
                                "scatter route {} requires a native Kotlin binding",
                                route.name
                            ));
                        };
                        (
                            ResolvedFlow::Scatter {
                                binding: NativeKotlinRequestResponseBinding {
                                    format,
                                    target,
                                    request_type,
                                    response_type,
                                    request_codec,
                                    response_codec,
                                },
                                requests,
                            },
                            operation,
                            failure_slug,
                        )
                    }
                    Flow::Event {
                        binding,
                        addresses,
                        delivery,
                        operation,
                        failure_slug,
                    } => {
                        let addresses = admit_event_endpoints(&route.name, addresses, route.scope)?;
                        let binding = match binding {
                            EventBinding::Skir { payload } => {
                                let (record, _) = symbols.record(&payload)?;
                                ResolvedEventBinding::Skir(record_binding(symbols, &record.key)?)
                            }
                            EventBinding::NativeKotlin {
                                format,
                                target,
                                event_type,
                                event_codec,
                            } => ResolvedEventBinding::NativeKotlin(NativeKotlinEventBinding {
                                format,
                                target,
                                event_type,
                                event_codec,
                            }),
                        };
                        (
                            ResolvedFlow::Event {
                                binding,
                                addresses,
                                delivery,
                            },
                            operation,
                            failure_slug,
                        )
                    }
                };
                let resolved = ResolvedRoute {
                    name: route.name,
                    scope: route.scope,
                    grants: route.grants,
                    subscription: route.subscription,
                    operation,
                    failure_slug,
                    flow,
                };
                resolved.grants()?;
                Ok(resolved)
            })
            .collect()
    }
}

#[derive(serde::Serialize)]
pub struct RequestedSymbols {
    pub(crate) methods: Vec<MethodRequest>,
    pub(crate) records: Vec<RecordRequest>,
}

#[derive(serde::Serialize)]
pub struct MethodRequest {
    module: String,
    name: String,
}

#[derive(serde::Serialize)]
pub struct RecordRequest {
    module: String,
    path: Vec<String>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::symbols::{Language, LanguageBindings, SymbolDocument};

    fn empty_symbols() -> CanonicalSymbols {
        CanonicalSymbols::new(
            SymbolDocument {
                methods: vec![],
                records: vec![],
            },
            LanguageBindings {
                language: Language::Rust,
                methods: vec![],
                records: vec![],
            },
        )
        .unwrap()
    }

    #[test]
    fn rejects_duplicate_routes_before_symbol_resolution() {
        let source = r#"
routes:
  - &route
    name: duplicate_route
    scope: user
    grants: []
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: duplicate.route
      failure_slug: duplicate-route-failed
      requests:
        panel: "cloud.to.user.{user}.watch"
  - *route
"#;
        let error = Manifest::parse(source)
            .unwrap()
            .resolve(&empty_symbols())
            .err()
            .unwrap();
        assert!(error.contains("duplicate logical route"));
    }

    #[test]
    fn rejects_duplicate_and_incompatible_grants() {
        let duplicate = r#"
routes:
  - name: duplicate_grant
    scope: user
    grants:
      - &grant { role: authenticated_user, side: panel, direction: publish, channel: request }
      - *grant
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: duplicate.grant
      failure_slug: duplicate-grant-failed
      requests:
        panel: "cloud.to.user.{user}.watch"
"#;
        let error = Manifest::parse(duplicate)
            .unwrap()
            .resolve(&empty_symbols())
            .err()
            .unwrap();
        assert!(error.contains("duplicate grant"));

        let incompatible = r#"
routes:
  - name: incompatible_grant
    scope: user
    grants:
      - { role: authenticated_user, side: panel, direction: subscribe, channel: updates }
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: incompatible.grant
      failure_slug: incompatible-grant-failed
      requests:
        panel: "cloud.to.user.{user}.watch"
"#;
        let error = Manifest::parse(incompatible)
            .unwrap()
            .resolve(&empty_symbols())
            .err()
            .unwrap();
        assert!(error.contains("invalid grant channel"));
    }

    #[test]
    fn reports_missing_required_capture_with_route_context() {
        let source = r#"
routes:
  - name: missing_actor
    scope: organization_actor
    grants: []
    flow:
      kind: unary
      method: "organization/v1/member.skir:WatchOrganizationMembers"
      operation: missing.actor
      failure_slug: missing-actor-failed
      requests:
        panel: "cloud.to.organization.{organization}.members.watch"
"#;
        let error = Manifest::parse(source)
            .unwrap()
            .resolve(&empty_symbols())
            .err()
            .unwrap();
        assert!(error.contains("route missing_actor request endpoint Panel"));
        assert!(error.contains("missing required User"));
    }

    #[test]
    fn reports_unresolved_canonical_method() {
        let source = r#"
routes:
  - name: unresolved_method
    scope: user
    grants: []
    flow:
      kind: unary
      method: "organization/v1/user.skir:Missing"
      operation: unresolved.method
      failure_slug: unresolved-method-failed
      requests:
        panel: "cloud.to.user.{user}.watch"
"#;
        let error = Manifest::parse(source)
            .unwrap()
            .resolve(&empty_symbols())
            .err()
            .unwrap();
        assert!(error.contains("unknown method"));
    }

    #[test]
    fn rejects_presence_projection_of_authoritative_or_absent_identity() {
        for (parameter, expected) in [
            ("organization", "authoritative scope identity"),
            ("realm", "absent parameter"),
        ] {
            let source = format!(
                r#"
routes:
  - name: invalid_presence
    scope: organization_actor
    grants: []
    flow:
      kind: event
      binding: {{ kind: native_kotlin, format: kotlin_serialization_cbor, target: loader_core, event_type: com.example.Event, event_codec: com.example.Codecs.event }}
      operation: invalid.presence
      failure_slug: invalid-presence-failed
      addresses:
        panel:
          subject: "typewriter.presence.organization.{{organization}}.user.{{user}}"
          subscription: {{ wildcard: [{parameter}] }}
      delivery: {{ kind: transient }}
"#
            );
            let error = Manifest::parse(&source)
                .unwrap()
                .resolve(&empty_symbols())
                .err()
                .unwrap();
            assert!(error.contains(expected), "{error}");
        }
    }

    #[test]
    fn rejects_grants_on_internal_component_routes() {
        let source = r#"
routes:
  - name: invalid_internal
    scope: internal_component
    grants:
      - { role: native_client, side: backend_internal, direction: publish, channel: request }
    subscription: { component: auth-typewriter-permissions, group: typewriter.auth-auth-typewriter-permissions }
    flow:
      kind: unary
      method: "access/v1/permission.skir:GetEntityPermission"
      operation: invalid.internal
      failure_slug: invalid-internal-failed
      requests: { backend_internal: "auth.permissions.typewriter-panel" }
"#;
        let error = Manifest::parse(source)
            .unwrap()
            .resolve(&empty_symbols())
            .err()
            .unwrap();
        assert!(error.contains("requires a subscription and no grants"));
    }
}
