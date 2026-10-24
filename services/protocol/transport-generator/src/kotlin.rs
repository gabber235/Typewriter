use std::collections::BTreeSet;

use genco::prelude::*;

use crate::{
    OutputFile,
    manifest::{ScopeKind, Side},
    resolved::{ResolvedEventBinding, ResolvedFlow, ResolvedRoute},
    symbols::BindingReference,
};

fn camel(value: &str) -> String {
    let mut parts = value.split('_');
    let mut output = parts.next().unwrap_or_default().to_owned();
    for part in parts {
        let mut chars = part.chars();
        if let Some(first) = chars.next() {
            output.extend(first.to_uppercase());
            output.extend(chars);
        }
    }
    output
}

fn method(route: &ResolvedRoute) -> Result<(&str, &str, &str, &str), String> {
    let binding = match &route.flow {
        ResolvedFlow::Unary { method, .. }
        | ResolvedFlow::Watch { method, .. }
        | ResolvedFlow::BoundedWatch { method, .. } => method,
        ResolvedFlow::Scatter { .. } | ResolvedFlow::Event { .. } => {
            return Err("route has no Skir method".to_owned());
        }
    };
    let BindingReference::Kotlin {
        package_name,
        symbol,
    } = &binding.target
    else {
        return Err("Kotlin emission requires Kotlin bindings".to_owned());
    };
    Ok((
        package_name,
        symbol,
        &binding.target_request_type,
        &binding.target_response_type,
    ))
}

fn emit_file(routes: &[&ResolvedRoute], realm: bool, path: &str) -> Result<OutputFile, String> {
    let scope = if realm {
        "RealmRouteScope"
    } else {
        "ServiceRouteScope"
    };
    let template = if realm {
        "realmTemplate()"
    } else {
        "serviceTemplate()"
    };
    let mut imports = BTreeSet::from([
        "com.typewritermc.services.libs.communicator.address.MessageAddress".to_owned(),
        "com.typewritermc.services.libs.communicator.address.addressTemplate".to_owned(),
        "com.typewritermc.services.libs.communicator.address.addressValuesOf".to_owned(),
        "com.typewritermc.services.libs.communicator.contract.EventContract".to_owned(),
        "com.typewritermc.services.libs.communicator.contract.OperationName".to_owned(),
        "com.typewritermc.services.libs.communicator.contract.ResponseClassifier".to_owned(),
        "com.typewritermc.services.libs.communicator.contract.ResponsePolicy".to_owned(),
        "com.typewritermc.services.libs.communicator.skir.asPayloadCodec".to_owned(),
        "com.typewritermc.services.libs.communicator.skir.skirUnaryContract".to_owned(),
        "com.typewritermc.services.libs.communicator.skir.skirWatchContract".to_owned(),
        "com.typewritermc.services.libs.telemetry.ErrorSlug".to_owned(),
    ]);
    let mut tokens = kotlin::Tokens::new();
    if realm {
        quote_in! { tokens =>
            data class RealmRouteScope(val organizationId: String, val realmId: String)
            private fun String.realmTemplate() = addressTemplate(
                render = { it: RealmRouteScope -> addressValuesOf("organization" to it.organizationId, "realm" to it.realmId) },
                parse = { RealmRouteScope(it.require("organization"), it.require("realm")) },
            )

        };
    } else {
        quote_in! { tokens =>
            data class ServiceRouteScope(val serviceId: String)
            private fun String.serviceTemplate() = addressTemplate(
                render = { addressValuesOf("service" to it.serviceId) },
                parse = { ServiceRouteScope(it.require("service")) },
            )

        };
    }
    tokens.line();
    for route in routes {
        let name = camel(&route.name.to_string());
        let request_address = format!("{name}RequestAddress");
        let operation = &route.operation;
        let slug = &route.failure_slug;
        match &route.flow {
            ResolvedFlow::Unary { requests, .. } => {
                let (package, symbol, _, response) = method(route)?;
                imports.insert(format!("{package}.{symbol}"));
                let address = requests[&Side::Service].to_string();
                quote_in! { tokens =>
                    private val $(&request_address) = $(quoted(address)).$template
                    fun $scope.$name(policy: ResponsePolicy<$response>) = skirUnaryContract(
                        method = $symbol, name = OperationName.of($(quoted(operation))),
                        address = $(&request_address).subscribedAt(this), responsePolicy = policy,
                        failureSlug = ErrorSlug.of($(quoted(slug))),
                    )

                };
            }
            ResolvedFlow::Watch {
                requests, updates, ..
            } => {
                let (package, symbol, _, response) = method(route)?;
                imports.insert(format!("{package}.{symbol}"));
                let address = requests[&Side::Service].to_string();
                let update_address = format!("{name}UpdateAddress");
                let update = updates.addresses[&Side::Service].to_string();
                let update_type = &updates.payload.target_type;
                quote_in! { tokens =>
                    private val $(&request_address) = $(quoted(address)).$template
                    private val $(&update_address) = $(quoted(update)).$template
                    fun $scope.$name(policy: ResponsePolicy<$response>, updates: ResponseClassifier<$update_type>) = skirWatchContract(
                        method = $symbol, updateSerializer = $update_type.serializer,
                        name = OperationName.of($(quoted(operation))), requestAddress = $(&request_address).subscribedAt(this),
                        updateAddress = $(&update_address), initialPolicy = policy, updateClassifier = updates,
                        failureSlug = ErrorSlug.of($(quoted(slug))),
                    )

                };
            }
            ResolvedFlow::BoundedWatch {
                method: binding,
                requests,
                updates,
                transfer_field,
            } => {
                let (package, symbol, request, response) = method(route)?;
                imports.insert(format!("{package}.{symbol}"));
                let address = requests[&Side::Service].to_string();
                let update_address = format!("{name}UpdateAddress");
                let update = updates[&Side::Service]
                    .to_string()
                    .trim_end_matches(".{transfer_id}")
                    .to_owned();
                let field = &binding.request.fields[*transfer_field].target_name;
                let resolver = format!(
                    "MessageAddress.of(\"${{{update_address}.render(routeScope).value}}.${{request.{field}}}\")"
                );
                quote_in! { tokens =>
                    private val $(&request_address) = $(quoted(address)).$template
                    private val $(&update_address) = $(quoted(update)).$template
                    fun $scope.$name(policy: ResponsePolicy<$response>, updates: ResponseClassifier<$response>) = skirWatchContract(
                        method = $symbol, updateSerializer = $response.serializer,
                        name = OperationName.of($(quoted(operation))), requestAddress = $(&request_address).subscribedAt(this),
                        updateAddress = $(&update_address), initialPolicy = policy, updateClassifier = updates,
                        failureSlug = ErrorSlug.of($(quoted(slug))),
                        updateAddressResolver = { routeScope, request: $request -> $resolver },
                    )

                };
            }
            ResolvedFlow::Scatter { .. } => continue,
            ResolvedFlow::Event {
                binding, addresses, ..
            } => {
                let ResolvedEventBinding::Skir(payload) = binding else {
                    continue;
                };
                let address_name = format!("{name}Address");
                let address = addresses[&Side::Service].subject.to_string();
                let payload = &payload.target_type;
                quote_in! { tokens =>
                    private val $(&address_name) = $(quoted(address)).$template
                    val $scope.$name get() = EventContract(
                        OperationName.of($(quoted(operation))), $(&address_name),
                        $payload.serializer.asPayloadCodec(), ErrorSlug.of($(quoted(slug))),
                    )

                };
            }
        }
        tokens.line();
    }
    let body = tokens.to_file_string().map_err(|error| error.to_string())?;
    let mut code = "package com.typewritermc.protocol.transport.generated\n\n".to_owned();
    for import in imports {
        code.push_str(&format!("import {import}\n"));
    }
    code.push('\n');
    code.push_str(&body);
    Ok(OutputFile {
        path: path.to_owned(),
        code,
    })
}

fn short_symbol(symbol: &crate::manifest::KotlinSymbol) -> &str {
    symbol
        .as_str()
        .rsplit('.')
        .next()
        .unwrap_or(symbol.as_str())
}

pub fn emit_loader(routes: &[ResolvedRoute]) -> Result<Vec<OutputFile>, String> {
    let native = routes
        .iter()
        .filter(|route| {
            matches!(
                route.flow,
                ResolvedFlow::Scatter { .. }
                    | ResolvedFlow::Event {
                        binding: ResolvedEventBinding::NativeKotlin(_),
                        ..
                    }
            )
        })
        .collect::<Vec<_>>();
    let mut imports = BTreeSet::from([
        "com.typewritermc.protocol.transport.generated.RealmRouteScope".to_owned(),
        "com.typewritermc.services.libs.communicator.address.addressTemplate".to_owned(),
        "com.typewritermc.services.libs.communicator.address.addressValuesOf".to_owned(),
        "com.typewritermc.services.libs.communicator.contract.EventContract".to_owned(),
        "com.typewritermc.services.libs.communicator.contract.OperationName".to_owned(),
        "com.typewritermc.services.libs.communicator.contract.ResponsePolicy".to_owned(),
        "com.typewritermc.services.libs.communicator.contract.ScatterContract".to_owned(),
        "com.typewritermc.services.libs.telemetry.ErrorSlug".to_owned(),
    ]);
    let mut tokens = kotlin::Tokens::new();
    quote_in! { tokens =>
        private fun String.loaderRealmTemplate() = addressTemplate(
            render = { it: RealmRouteScope -> addressValuesOf("organization" to it.organizationId, "realm" to it.realmId) },
            parse = { RealmRouteScope(it.require("organization"), it.require("realm")) },
        )

    };
    tokens.line();
    for route in native {
        if route.scope != ScopeKind::Realm {
            return Err(format!(
                "native Kotlin route {} must use realm scope",
                route.name
            ));
        }
        let name = camel(&route.name.to_string());
        let operation = &route.operation;
        let slug = &route.failure_slug;
        match &route.flow {
            ResolvedFlow::Scatter { binding, requests } => {
                if binding.target.as_str() != "loader_core" {
                    return Err(format!(
                        "unsupported native Kotlin target for {}",
                        route.name
                    ));
                }
                let request_type = short_symbol(&binding.request_type);
                let response_type = short_symbol(&binding.response_type);
                let request_codec = binding.request_codec.as_str();
                let response_codec = binding.response_codec.as_str();
                imports.insert(binding.request_type.as_str().to_owned());
                imports.insert(binding.response_type.as_str().to_owned());
                let address_name = format!("{name}RequestAddress");
                let address = requests[&Side::Service].to_string();
                quote_in! { tokens =>
                    private val $(&address_name) = $(quoted(address)).loaderRealmTemplate()
                    fun RealmRouteScope.$name(policy: ResponsePolicy<$response_type>): ScatterContract<RealmRouteScope, $request_type, $response_type> = ScatterContract(
                        name = OperationName.of($(quoted(operation))),
                        requestAddress = $(&address_name).subscribedAt(this),
                        requestCodec = $request_codec,
                        responseCodec = $response_codec,
                        responsePolicy = policy,
                        failureSlug = ErrorSlug.of($(quoted(slug))),
                    )

                };
            }
            ResolvedFlow::Event {
                binding: ResolvedEventBinding::NativeKotlin(binding),
                addresses,
                ..
            } => {
                if binding.target.as_str() != "loader_core" {
                    return Err(format!(
                        "unsupported native Kotlin target for {}",
                        route.name
                    ));
                }
                let event_type = short_symbol(&binding.event_type);
                let event_codec = binding.event_codec.as_str();
                imports.insert(binding.event_type.as_str().to_owned());
                let address_name = format!("{name}Address");
                let address = addresses[&Side::Service].subject.to_string();
                quote_in! { tokens =>
                    private val $(&address_name) = $(quoted(address)).loaderRealmTemplate()
                    val RealmRouteScope.$name: EventContract<RealmRouteScope, $event_type>
                        get() = EventContract(
                            name = OperationName.of($(quoted(operation))),
                            address = $(&address_name),
                            codec = $event_codec,
                            failureSlug = ErrorSlug.of($(quoted(slug))),
                        )

                };
            }
            _ => return Err(format!("unsupported loader route {}", route.name)),
        }
        tokens.line();
    }
    let body = tokens.to_file_string().map_err(|error| error.to_string())?;
    let mut code = "package com.typewritermc.loader.rollout\n\n".to_owned();
    for import in imports {
        if !import.starts_with("com.typewritermc.loader.rollout.") {
            code.push_str(&format!("import {import}\n"));
        }
    }
    code.push('\n');
    code.push_str(&body);
    Ok(vec![OutputFile {
        path: "RolloutRoutes.kt".to_owned(),
        code,
    }])
}

pub fn emit(routes: &[ResolvedRoute]) -> Result<Vec<OutputFile>, String> {
    let realm = routes
        .iter()
        .filter(|route| route.scope == ScopeKind::Realm)
        .collect::<Vec<_>>();
    let service = routes
        .iter()
        .filter(|route| route.scope == ScopeKind::Service)
        .collect::<Vec<_>>();
    Ok(vec![
        emit_file(&realm, true, "RealmRoutes.kt")?,
        emit_file(&service, false, "ServiceRegistrationRoutes.kt")?,
    ])
}
