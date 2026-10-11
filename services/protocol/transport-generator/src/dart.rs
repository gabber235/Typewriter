use genco::prelude::*;

use crate::{
    OutputFile,
    grants::GrantSpec,
    manifest::{Delivery, Direction, Role, ScopeKind, Side},
    resolved::{ResolvedFlow, ResolvedRoute},
    rust_dispatch::type_identifier,
    subject::{Parameter, SubjectTemplate, Token},
    symbols::BindingReference,
};

fn dart_name(route: &ResolvedRoute) -> String {
    type_identifier(&route.name.to_string()).to_string()
}

fn panel_import(symbol: &str) -> dart::Import {
    dart::import("package:typewriter_panel/typewriter_panel.dart", symbol)
}

fn scope_parameters(scope: ScopeKind) -> &'static [(Parameter, &'static str, &'static str)] {
    match scope {
        ScopeKind::Realm => &[
            (Parameter::Organization, "organizationId", "_skir.RecordId"),
            (Parameter::Realm, "realmId", "_skir.RecordId"),
        ],
        ScopeKind::OrganizationActor => &[
            (Parameter::User, "userId", "String"),
            (Parameter::Organization, "organizationId", "_skir.RecordId"),
        ],
        ScopeKind::Organization => &[(Parameter::Organization, "organizationId", "_skir.RecordId")],
        ScopeKind::User => &[(Parameter::User, "userId", "String")],
        ScopeKind::Service => &[(Parameter::Service, "serviceId", "String")],
        ScopeKind::BoundService => &[
            (Parameter::Service, "serviceId", "String"),
            (Parameter::Organization, "organizationId", "_skir.RecordId"),
        ],
        ScopeKind::Native | ScopeKind::InternalComponent => &[],
    }
}

fn parameter_name(parameter: Parameter) -> &'static str {
    match parameter {
        Parameter::Organization => "organization",
        Parameter::Realm => "realm",
        Parameter::Service => "service",
        Parameter::User => "user",
        Parameter::TransferId => "transfer",
    }
}

fn scope_signature(scope: ScopeKind) -> dart::Tokens {
    let mut tokens = dart::Tokens::new();
    for &(_, name, target_type) in scope_parameters(scope) {
        quote_in! { tokens => required $target_type $name, };
        tokens.line();
    }
    tokens
}

fn scope_values(scope: ScopeKind) -> dart::Tokens {
    let mut tokens = dart::Tokens::new();
    for &(parameter, name, target_type) in scope_parameters(scope) {
        let parameter = parameter_name(parameter);
        if target_type == "_skir.RecordId" {
            quote_in! { tokens => final $parameter = $name.id._transportIdentity; };
        } else {
            quote_in! { tokens => final $parameter = $name._transportIdentity; };
        }
        tokens.line();
    }
    tokens
}

fn scope_arguments(scope: ScopeKind) -> dart::Tokens {
    let mut tokens = dart::Tokens::new();
    for &(_, name, _) in scope_parameters(scope) {
        quote_in! { tokens => $name: $name, };
        tokens.line();
    }
    tokens
}

fn subject(
    template: &SubjectTemplate,
    transfer_field: Option<&str>,
) -> Result<dart::Tokens, String> {
    let mut output = dart::Tokens::new();
    for (index, token) in template.tokens().iter().enumerate() {
        if index > 0 {
            quote_in! { output => + "." + };
        }
        match token {
            Token::Literal(value) => quote_in! { output => $(quoted(value)) },
            Token::Parameter(Parameter::TransferId) => {
                let field = transfer_field
                    .ok_or_else(|| "bounded Dart subject requires a transfer field".to_owned())?;
                quote_in! { output => $field._transportTransfer };
            }
            Token::Parameter(parameter) => {
                let parameter = parameter_name(*parameter);
                quote_in! { output => $parameter };
            }
        }
    }
    Ok(output)
}

fn grant_subject(
    template: &SubjectTemplate,
    transfer_token: bool,
    wildcards: &std::collections::BTreeSet<Parameter>,
) -> Result<dart::Tokens, String> {
    let mut output = dart::Tokens::new();
    for (index, token) in template.tokens().iter().enumerate() {
        if index > 0 {
            quote_in! { output => + "." + };
        }
        match token {
            Token::Literal(value) => quote_in! { output => $(quoted(value)) },
            Token::Parameter(parameter) if wildcards.contains(parameter) => {
                quote_in! { output => "*" }
            }
            Token::Parameter(Parameter::TransferId) if transfer_token => {
                quote_in! { output => "*" }
            }
            Token::Parameter(Parameter::TransferId) => {
                return Err("transfer grant requires a bounded wildcard".to_owned());
            }
            Token::Parameter(parameter) => {
                let parameter = parameter_name(*parameter);
                quote_in! { output => $parameter };
            }
        }
    }
    Ok(output)
}

fn add_permission(mut output: &mut dart::Tokens, direction: Direction, expression: dart::Tokens) {
    let set = match direction {
        Direction::Publish => "publish",
        Direction::Subscribe => "subscribe",
    };
    quote_in! { output => $set.add($expression); };
    output.line();
}

fn realm_discovery_parts(anchor: &str) -> Result<(String, dart::Tokens), String> {
    let (prefix, suffix) = anchor
        .split_once("{realm}")
        .ok_or_else(|| "Realm discovery anchor has no Realm token".to_owned())?;
    if prefix.contains('{') {
        return Err("Realm discovery prefix contains an unresolved parameter".to_owned());
    }
    let (before_organization, after_organization) = suffix
        .split_once("{organization}")
        .ok_or_else(|| "Realm discovery suffix has no organization token".to_owned())?;
    if before_organization.contains('{') || after_organization.contains('{') {
        return Err("Realm discovery suffix contains an unsupported parameter".to_owned());
    }
    Ok((
        prefix.to_owned(),
        quote!($(quoted(before_organization)) + organization + $(quoted(after_organization))),
    ))
}

fn emit_panel_permissions(routes: &[ResolvedRoute]) -> Result<dart::Tokens, String> {
    let mut user = dart::Tokens::new();
    let mut organization = dart::Tokens::new();
    let mut realm = dart::Tokens::new();
    let mut realm_anchor = None;
    for route in routes {
        let specs = route.grants()?;
        for (grant, spec) in route.grants.iter().zip(specs) {
            if grant.side != Side::Panel {
                continue;
            }
            let GrantSpec {
                role,
                direction,
                endpoint,
                transfer_token,
                wildcard_parameters,
            } = spec;
            let expression = grant_subject(endpoint, transfer_token, &wildcard_parameters)?;
            match (route.scope, role) {
                (ScopeKind::User, Role::AuthenticatedUser) => {
                    add_permission(&mut user, direction, expression)
                }
                (
                    ScopeKind::OrganizationActor | ScopeKind::Organization,
                    Role::OrganizationMember,
                ) => add_permission(&mut organization, direction, expression),
                (ScopeKind::Realm, Role::OrganizationMember) => {
                    if direction == Direction::Publish && !transfer_token && realm_anchor.is_none()
                    {
                        realm_anchor = Some(endpoint.to_string());
                    }
                    add_permission(&mut realm, direction, expression)
                }
                _ => return Err(format!("unsupported panel grant scope in {}", route.name)),
            }
        }

        let ResolvedFlow::Watch {
            updates, requests, ..
        } = &route.flow
        else {
            continue;
        };
        let Delivery::Persistent {
            stream, projection, ..
        } = &updates.delivery
        else {
            continue;
        };
        if !requests.contains_key(&Side::Panel) {
            continue;
        }
        let event = updates.addresses.get(&Side::Panel).ok_or_else(|| {
            format!(
                "persistent panel route {} has no update address",
                route.name
            )
        })?;
        let filter = grant_subject(event, false, &Default::default())?;
        let target = match route.scope {
            ScopeKind::User => &mut user,
            ScopeKind::OrganizationActor | ScopeKind::Organization => &mut organization,
            scope => {
                return Err(format!(
                    "persistent panel route has unsupported scope {scope:?}"
                ));
            }
        };
        let organization_value = if route.scope == ScopeKind::User {
            "null"
        } else {
            "organization"
        };
        let stream = stream.to_string();
        let projection = projection.to_string();
        quote_in! { *target =>
            _grantPersistentProjection(
                publish,
                stream: $(quoted(stream)),
                consumer: _persistentConsumerName(
                    actor: user, organization: $organization_value, session: session,
                    projection: $(quoted(projection)),
                ),
                filter: $filter,
            );
        };
        target.line();
    }

    let anchor =
        realm_anchor.ok_or_else(|| "panel Realm grants need a discovery anchor".to_owned())?;
    let (anchor_prefix, anchor_suffix) = realm_discovery_parts(&anchor)?;
    let record_id = dart::import(
        "package:typewriter_panel/infrastructure/protocols/skir/skir.dart",
        "RecordId",
    )
    .with_alias("_skir");
    let record_id_key = dart::import(
        "package:typewriter_panel/infrastructure/protocols/skir/skir.dart",
        "RecordIdKey",
    )
    .with_alias("_skir");
    let snapshot = panel_import("ServerPermissionSnapshot");
    let client = panel_import("NatsClient");
    Ok(quote! {
        final class TransportPermissionGrant {
            TransportPermissionGrant({required Set<String> publish, required Set<String> subscribe})
                : publish = Set.unmodifiable(publish), subscribe = Set.unmodifiable(subscribe);
            final Set<String> publish;
            final Set<String> subscribe;
        }

        TransportPermissionGrant panelTransportPermissions({
            required String actorId,
            required $(&record_id)? organizationId,
            required String connectionSession,
            required Iterable<$(&record_id)> realmIds,
        }) {
            final user = actorId._transportIdentity;
            final session = connectionSession._transportSession;
            final publish = <String>{$(quoted("$SYS.REQ.USER.INFO"))};
            final subscribe = <String>{$[str](_INBOX.$(user).$(session).*)};
            $user
            final organization = organizationId?.id._transportIdentity;
            final realms = realmIds.map((value) => value.id._transportIdentity).toSet();
            if (organizationId != null || realms.isNotEmpty) {
                if (organization == null) throw StateError("Realm permissions require an admitted organization");
                $organization
                for (final realm in realms) {
                    $realm
                }
            }
            return TransportPermissionGrant(publish: publish, subscribe: subscribe);
        }

        extension GeneratedRealmAdmission on $(&snapshot) {
            Set<$(&record_id)> admittedRealms($(&client) client) {
                final organization = client.organizationId?._transportIdentity;
                if (organization == null) return const {};
                const prefix = $(quoted(anchor_prefix));
                final suffix = $anchor_suffix;
                return publish.where((subject) => subject.startsWith(prefix) && subject.endsWith(suffix))
                    .map((subject) => subject.substring(prefix.length, subject.length - suffix.length))
                    .where((realm) => realm._isTransportIdentity)
                    .map((realm) => $(&record_id)(table: "realm_instance", key: $(&record_id_key).wrapString(realm)))
                    .where((realm) => realm.admittedBy(this, client)).toSet();
            }
        }

        extension GeneratedRealmPermission on $(&record_id) {
            bool admittedBy($(&snapshot) snapshot, $(&client) client) {
                final required = panelTransportPermissions(
                    actorId: client.actorId,
                    organizationId: client.organizationId == null ? null : $(&record_id)(
                        table: "organization", key: $(&record_id_key).wrapString(client.organizationId!),
                    ),
                    connectionSession: client.connectionSession, realmIds: [this],
                );
                return snapshot.publish.containsAll(required.publish) && snapshot.subscribe.containsAll(required.subscribe);
            }
        }

        void _grantPersistentProjection(Set<String> publish, {required String stream, required String consumer, required String filter}) {
            publish.addAll({
                $[str]($$JS.API.STREAM.INFO.$(stream)),
                $[str]($$JS.API.CONSUMER.CREATE.$(stream).$(consumer).$(filter)),
                $[str]($$JS.API.CONSUMER.INFO.$(stream).$(consumer)),
                $[str]($$JS.API.CONSUMER.MSG.NEXT.$(stream).$(consumer)),
                $[str]($$JS.API.CONSUMER.DELETE.$(stream).$(consumer)),
            });
        }
    })
}

fn dart_reference(reference: &BindingReference) -> Result<dart::Import, String> {
    let BindingReference::Dart {
        import_uri,
        alias,
        symbol,
    } = reference
    else {
        return Err("Dart emission requires Dart binding metadata".to_owned());
    };
    Ok(dart::import(import_uri, symbol).with_alias(alias))
}

fn method_reference(route: &ResolvedRoute) -> Result<dart::Import, String> {
    let method = match &route.flow {
        ResolvedFlow::Unary { method, .. }
        | ResolvedFlow::Watch { method, .. }
        | ResolvedFlow::BoundedWatch { method, .. } => method,
        ResolvedFlow::Scatter { .. } | ResolvedFlow::Event { .. } => {
            return Err("route has no Skir method".to_owned());
        }
    };
    dart_reference(&method.target)
}

fn target_type(route: &ResolvedRoute, target: &str) -> Result<dart::Import, String> {
    let method = match &route.flow {
        ResolvedFlow::Unary { method, .. }
        | ResolvedFlow::Watch { method, .. }
        | ResolvedFlow::BoundedWatch { method, .. } => method,
        ResolvedFlow::Scatter { .. } | ResolvedFlow::Event { .. } => {
            return Err("route has no Skir method".to_owned());
        }
    };
    let (alias, symbol) = target
        .split_once('.')
        .ok_or_else(|| format!("Dart type {target} is not canonically qualified"))?;
    let binding = method
        .imports
        .iter()
        .find(|binding| binding.alias == alias)
        .ok_or_else(|| format!("Dart type {target} has no canonical import"))?;
    Ok(dart::import(&binding.import_uri, symbol).with_alias(alias))
}

fn emit_unary(
    route: &ResolvedRoute,
    routes: &[ResolvedRoute],
) -> Result<Option<dart::Tokens>, String> {
    let ResolvedFlow::Unary { method, requests } = &route.flow else {
        return Ok(None);
    };
    let Some(request_address) = requests.get(&Side::Panel) else {
        return Ok(None);
    };
    let method_reference = method_reference(route)?;
    let request_type = target_type(route, &method.target_request_type)?;
    let response_type = target_type(route, &method.target_response_type)?;
    let operation_type = panel_import("SkirRouteOperation");
    let name = dart_name(route);
    let parameters = scope_signature(route.scope);
    let values = scope_values(route.scope);
    let request_subject = subject(request_address, None)?;
    let collisions = routes
        .iter()
        .filter(|candidate| {
            matches!(
                &candidate.flow,
                ResolvedFlow::Unary { method: candidate_method, requests }
                    if requests.contains_key(&Side::Panel)
                        && candidate_method.target_request_type == method.target_request_type
            )
        })
        .collect::<Vec<_>>();
    let operation_name = if collisions.len() == 1 {
        "operation".to_owned()
    } else {
        let parts = route.operation.split('.').collect::<Vec<_>>();
        let unique = parts
            .iter()
            .rev()
            .find(|part| {
                collisions.iter().all(|candidate| {
                    candidate.name == route.name
                        || !candidate.operation.split('.').any(|value| value == **part)
                })
            })
            .ok_or_else(|| format!("cannot disambiguate Dart operation for {}", route.name))?;
        format!("{unique}Operation")
    };
    Ok(Some(quote! {
        extension $(&name)Nats on $request_type {
            $(&operation_type)<$response_type> $operation_name({
                $parameters
            }) {
                $values
                final method = $method_reference;
                return $operation_type(
                    subject: $request_subject,
                    requestBytes: method.requestSerializer.toBytes(this),
                    responseSerializer: method.responseSerializer,
                );
            }
        }
    }))
}

fn delivery(value: &Delivery, route_name: &str) -> dart::Tokens {
    let projection_delivery = panel_import("ProjectionDelivery");
    let nats_provider = panel_import("natsProvider");
    let projection_name = format!("{route_name}Projection");
    match value {
        Delivery::Transient => quote!(const $projection_delivery.ephemeral()),
        Delivery::Persistent { stream, .. } => quote!(
            $projection_delivery.persistent(
                stream: $(quoted(stream)),
                consumer: $projection_name.consumerName(ref.read($nats_provider)),
            )
        ),
    }
}

fn emit_watch(route: &ResolvedRoute) -> Result<Option<dart::Tokens>, String> {
    let ResolvedFlow::Watch {
        method,
        requests,
        updates,
    } = &route.flow
    else {
        return Ok(None);
    };
    let (Some(request_address), Some(update_address)) = (
        requests.get(&Side::Panel),
        updates.addresses.get(&Side::Panel),
    ) else {
        return Ok(None);
    };
    let target = updates
        .payload
        .target
        .as_ref()
        .ok_or_else(|| format!("Dart event binding is missing for {}", updates.payload.key))?;
    let event_type = dart_reference(target)?;
    let method_reference = method_reference(route)?;
    let request_type = target_type(route, &method.target_request_type)?;
    let response_type = target_type(route, &method.target_response_type)?;
    let ref_type = panel_import("Ref");
    let reconciliation_type = panel_import("ProjectionReconciliation");
    let operation_type = panel_import("SkirRouteOperation");
    let name = dart_name(route);
    let parameters = scope_signature(route.scope);
    let values = scope_values(route.scope);
    let arguments = scope_arguments(route.scope);
    let request_subject = subject(request_address, None)?;
    let update_subject = subject(update_address, None)?;
    let delivery = delivery(&updates.delivery, &name);
    let projection: dart::Tokens = match &updates.delivery {
        Delivery::Transient => quote!(),
        Delivery::Persistent { projection, .. } => {
            let organization_scoped = if matches!(
                route.scope,
                ScopeKind::Organization | ScopeKind::OrganizationActor
            ) {
                "true"
            } else {
                "false"
            };
            let projection = projection.to_string();
            quote! {
                const $(&name)Projection = PersistentProjectionRoute(
                    id: $(quoted(projection)),
                    organizationScoped: $organization_scoped,
                );
            }
        }
    };
    Ok(Some(quote! {
        $projection
        extension $(&name)Nats on $request_type {
            $(&operation_type)<$(&response_type)> operation({
                $(&parameters)
            }) {
                $(&values)
                final method = $method_reference;
                return $(&operation_type)(
                    subject: $request_subject,
                    requestBytes: method.requestSerializer.toBytes(this),
                    responseSerializer: method.responseSerializer,
                );
            }

            Stream<TData> watch<TData>($ref_type ref, {
                $(&parameters)
                required TData Function($(&response_type)) snapshot,
                required TData Function(TData, $(&event_type)) reduce,
                required $reconciliation_type<TData, $(&response_type), $(&event_type)> reconciliation,
                Stream<$(&event_type)>? confirmedEvents,
                TData Function(TData, $(&event_type))? reduceConfirmed,
                TData Function(TData, TData)? reconcileSnapshot,
                TData? initialValue,
            }) {
                $(&values)
                final operation = this.operation(
                    $arguments
                );
                return ref.watchProjection<TData, $(&response_type), $(&event_type)>(
                    subject: operation.subject,
                    eventSubject: $update_subject,
                    requestBytes: operation.requestBytes,
                    responseSerializer: operation.responseSerializer,
                    eventSerializer: $(&event_type).serializer,
                    snapshot: snapshot, reduce: reduce, delivery: $delivery,
                    reconciliation: reconciliation, confirmedEvents: confirmedEvents,
                    reduceConfirmed: reduceConfirmed, reconcileSnapshot: reconcileSnapshot,
                    initialValue: initialValue,
                );
            }
        }
    }))
}

fn emit_bounded_watch(route: &ResolvedRoute) -> Result<Option<dart::Tokens>, String> {
    let ResolvedFlow::BoundedWatch {
        method,
        requests,
        updates,
        transfer_field,
    } = &route.flow
    else {
        return Ok(None);
    };
    let (Some(request_address), Some(update_address)) =
        (requests.get(&Side::Panel), updates.get(&Side::Panel))
    else {
        return Ok(None);
    };
    let method_reference = method_reference(route)?;
    let request_type = target_type(route, &method.target_request_type)?;
    let response_type = target_type(route, &method.target_response_type)?;
    let mutation_client = panel_import("SkirMutationClient");
    let name = dart_name(route);
    let parameters = scope_signature(route.scope);
    let values = scope_values(route.scope);
    let request_subject = subject(request_address, None)?;
    let field = &method.request.fields[*transfer_field].target_name;
    let update_subject = subject(update_address, Some(&format!("this.{field}")))?;
    Ok(Some(quote! {
        extension $(&name)Nats on $request_type {
            Stream<$response_type> watch($mutation_client transport, {
                $parameters
            }) {
                $values
                final method = $method_reference;
                return transport.watchRequest(
                    $request_subject,
                    $update_subject,
                    method.requestSerializer.toBytes(this),
                    method.responseSerializer,
                );
            }
        }
    }))
}

fn emit_event(route: &ResolvedRoute) -> Result<Option<dart::Tokens>, String> {
    let ResolvedFlow::Event {
        binding: crate::resolved::ResolvedEventBinding::Skir(payload),
        addresses,
        ..
    } = &route.flow
    else {
        return Ok(None);
    };
    let Some(address) = addresses.get(&Side::Panel) else {
        return Ok(None);
    };
    let target = payload
        .target
        .as_ref()
        .ok_or_else(|| format!("Dart event binding is missing for {}", payload.key))?;
    let payload_type = dart_reference(target)?;
    let name = dart_name(route);
    let parameters = scope_signature(route.scope);
    let values = scope_values(route.scope);
    let event_subject = subject(&address.subject, None)?;
    let projection = if address.subscription_wildcards.contains(&Parameter::User) {
        let subscription = grant_subject(&address.subject, false, &address.subscription_wildcards)?;
        let mut rejected = dart::Tokens::new();
        let mut user_index = None;
        for (index, token) in address.subject.tokens().iter().enumerate() {
            match token {
                Token::Literal(value) => {
                    quote_in! { rejected => || parts[$index] != $(quoted(value)) };
                }
                Token::Parameter(Parameter::Organization) => {
                    quote_in! { rejected => || parts[$index] != organization };
                }
                Token::Parameter(Parameter::User) => user_index = Some(index),
                Token::Parameter(_) => {
                    return Err(format!(
                        "unsupported Dart event projection in {}",
                        route.name
                    ));
                }
            }
        }
        let user_index =
            user_index.ok_or_else(|| "user projection has no user token".to_owned())?;
        let token_count = address.subject.tokens().len();
        quote! {
            static String subscriptionPattern({
                required _skir.RecordId organizationId,
            }) {
                final organization = organizationId.id._transportIdentity;
                return $subscription;
            }

            static String? userIdFromSubject(
                String subject, {
                required _skir.RecordId organizationId,
            }) {
                final organization = organizationId.id._transportIdentity;
                final parts = subject.split(".");
                if (parts.length != $token_count $rejected) return null;
                final userId = parts[$user_index];
                return userId._isTransportIdentity ? userId : null;
            }
        }
    } else {
        quote! {}
    };
    Ok(Some(quote! {
        final class $(&name)Event {
            const $(&name)Event._();

            static final serializer = $payload_type.serializer;

            static String subject({
                $parameters
            }) {
                $values
                return $event_subject;
            }

            $projection
        }
    }))
}

pub fn emit(routes: &[ResolvedRoute]) -> Result<Vec<OutputFile>, String> {
    let mut tokens = dart::Tokens::new();
    let panel = "package:typewriter_panel/typewriter_panel.dart";
    let nats_client = dart::import(panel, "NatsClient");
    let json_encode = dart::import("dart:convert", "jsonEncode");
    let base64_url = dart::import("dart:convert", "base64Url");
    let utf8 = dart::import("dart:convert", "utf8");
    for route in routes {
        let declaration = match &route.flow {
            ResolvedFlow::Unary { .. } => emit_unary(route, routes)?,
            ResolvedFlow::Watch { .. } => emit_watch(route)?,
            ResolvedFlow::BoundedWatch { .. } => emit_bounded_watch(route)?,
            ResolvedFlow::Scatter { .. } => None,
            ResolvedFlow::Event { .. } => emit_event(route)?,
        };
        if let Some(declaration) = declaration {
            tokens.append(declaration);
            tokens.line();
        }
    }
    tokens.append(emit_panel_permissions(routes)?);
    tokens.line();
    quote_in! { tokens =>
        final class PersistentProjectionRoute {
            const PersistentProjectionRoute({required this.id, required this.organizationScoped});
            final String id;
            final bool organizationScoped;
            String consumerName($nats_client client) {
                final organization = client.organizationId;
                if (organizationScoped && organization == null) {
                    throw StateError("Persistent organization projection requires an admitted organization");
                }
                return _persistentConsumerName(
                    actor: client.actorId._transportIdentity,
                    organization: organizationScoped ? organization?._transportIdentity : null,
                    session: client.connectionSession._transportSession,
                    projection: id,
                );
            }
        }

        String _persistentConsumerName({required String actor, required String? organization, required String session, required String projection}) {
            final identity = $json_encode([actor, organization, session, projection]);
            final encoded = $base64_url.encode($utf8.encode(identity)).replaceAll("=", "");
            return $[str](TW_$(encoded));
        }

        extension _TransportSegment on String {
            static final _identity = RegExp(r"^[^\s.*>{}]+$");
            static final _transfer = RegExp(r"^[A-Za-z0-9_\-]{1,64}$");
            static final _session = RegExp(r"^[a-f0-9]{32}$");
            bool get _isTransportIdentity => _identity.hasMatch(this);
            String get _transportIdentity {
                if (!_isTransportIdentity) throw ArgumentError.value(this, "identity", "Invalid identity segment");
                return this;
            }
            String get _transportTransfer {
                if (!_transfer.hasMatch(this)) throw ArgumentError.value(this, "transferId", "Invalid transfer segment");
                return this;
            }
            String get _transportSession {
                if (!_session.hasMatch(this)) throw ArgumentError.value(this, "connectionSession", "Invalid connection session");
                return this;
            }
        }
    };
    let code = tokens.to_file_string().map_err(|error| error.to_string())?;

    Ok(vec![OutputFile {
        path: "transport_routes.dart".to_owned(),
        code,
    }])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn realm_admission_suffix_uses_the_concrete_organization() {
        let (prefix, suffix) = realm_discovery_parts(
            "service.to.{realm}.organization.{organization}.realm.editor.catalog.fetch",
        )
        .unwrap();

        assert_eq!(prefix, "service.to.");
        assert_eq!(
            suffix.to_string().unwrap(),
            "\".organization.\" + organization + \".realm.editor.catalog.fetch\""
        );
    }
}
