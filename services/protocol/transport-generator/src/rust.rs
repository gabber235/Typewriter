use std::collections::BTreeMap;

use proc_macro2::{Literal, TokenStream};
use quote::{format_ident, quote};

use crate::{
    grants::GrantSpec,
    manifest::{Delivery, Direction, Role, ScopeKind, Side},
    resolved::{ResolvedFlow, ResolvedRoute},
    rust_dispatch::{emit_event_route, emit_request_route, emit_update_delivery},
    subject::{Parameter, SubjectTemplate, Token},
};

use crate::OutputFile;

fn scope_name(scope: ScopeKind) -> &'static str {
    match scope {
        ScopeKind::Realm => "Realm",
        ScopeKind::Service => "Service",
        ScopeKind::BoundService => "BoundService",
        ScopeKind::OrganizationActor => "OrganizationActor",
        ScopeKind::Organization => "Organization",
        ScopeKind::User => "User",
        ScopeKind::Native => "Native",
        ScopeKind::InternalComponent => "InternalComponent",
    }
}

fn role_name(role: Role) -> &'static str {
    match role {
        Role::AuthenticatedUser => "AuthenticatedUser",
        Role::OrganizationMember => "OrganizationMember",
        Role::RealmCoordinator => "Coordinator",
        Role::RealmParticipant => "Participant",
        Role::RegisteredService => "RegisteredService",
        Role::NativeClient => "NativeClient",
    }
}

fn role_admitted(scope: ScopeKind, role: Role) -> bool {
    matches!(
        (scope, role),
        (ScopeKind::Realm, Role::OrganizationMember)
            | (ScopeKind::Realm, Role::RealmCoordinator)
            | (ScopeKind::Realm, Role::RealmParticipant)
            | (ScopeKind::Service, Role::RegisteredService)
            | (ScopeKind::BoundService, Role::RegisteredService)
            | (ScopeKind::OrganizationActor, Role::OrganizationMember)
            | (ScopeKind::Organization, Role::OrganizationMember)
            | (ScopeKind::User, Role::AuthenticatedUser)
            | (ScopeKind::Native, Role::NativeClient)
    )
}

fn subject_expression(
    template: &SubjectTemplate,
    transfer: bool,
    wildcards: &std::collections::BTreeSet<Parameter>,
) -> Result<TokenStream, String> {
    let mut value = String::new();
    for (index, token) in template.tokens().iter().enumerate() {
        if index > 0 {
            value.push('.');
        }
        match token {
            Token::Literal(literal) => value.push_str(literal),
            Token::Parameter(parameter) if wildcards.contains(parameter) => value.push('*'),
            Token::Parameter(Parameter::TransferId) if transfer => value.push('*'),
            Token::Parameter(parameter) => {
                let name = match parameter {
                    Parameter::Organization => "organization",
                    Parameter::Realm => "realm",
                    Parameter::Service => "service",
                    Parameter::User => "user",
                    Parameter::TransferId => {
                        return Err("transfer token requires a bounded update grant".to_owned());
                    }
                };
                value.push('{');
                value.push_str(name);
                value.push('}');
            }
        }
    }
    let literal = Literal::string(&value);
    Ok(quote! { format!(#literal) })
}

fn scope_fields(scope: ScopeKind) -> Vec<syn::Ident> {
    let names: &[&str] = match scope {
        ScopeKind::Realm => &["organization", "realm"],
        ScopeKind::Service => &["service"],
        ScopeKind::BoundService => &["service", "organization"],
        ScopeKind::OrganizationActor => &["user", "organization"],
        ScopeKind::Organization => &["organization"],
        ScopeKind::User => &["user"],
        ScopeKind::Native | ScopeKind::InternalComponent => &[],
    };
    names.iter().map(|name| format_ident!("{name}")).collect()
}

fn emit_scopes() -> TokenStream {
    quote! {
        #[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
        pub struct SubjectToken(String);

        impl SubjectToken {
            pub fn as_str(&self) -> &str { &self.0 }
        }

        impl TryFrom<&str> for SubjectToken {
            type Error = crate::otel_wasi::Error;

            fn try_from(value: &str) -> Result<Self, Self::Error> {
                if value.is_empty() || value.chars().any(|character| {
                    character.is_whitespace() || ".*>{}".contains(character)
                }) {
                    return Err(crate::otel_wasi::Error::new(
                        "transport-invalid-token",
                        "Invalid subject identity",
                    ));
                }
                Ok(Self(value.to_owned()))
            }
        }

        impl std::fmt::Display for SubjectToken {
            fn fmt(&self, output: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                output.write_str(self.as_str())
            }
        }

        #[derive(Default)]
        pub struct GrantSet {
            pub publish: std::collections::BTreeSet<String>,
            pub subscribe: std::collections::BTreeSet<String>,
        }

        pub trait GrantScope {
            type Role;
            fn grant(&self, role: Self::Role, grants: &mut GrantSet);
        }

        #[derive(Clone, Debug)]
        pub struct RealmScope { pub organization: SubjectToken, pub realm: SubjectToken }
        #[derive(Clone, Debug)]
        pub struct ServiceScope { pub service: SubjectToken }
        #[derive(Clone, Debug)]
        pub struct BoundServiceScope { pub service: SubjectToken, pub organization: SubjectToken }
        #[derive(Clone, Debug)]
        pub struct OrganizationActorScope { pub user: SubjectToken, pub organization: SubjectToken }
        #[derive(Clone, Debug)]
        pub struct OrganizationScope { pub organization: SubjectToken }
        #[derive(Clone, Debug)]
        pub struct UserScope { pub user: SubjectToken }
        #[derive(Clone, Copy, Debug)]
        pub struct NativeScope;
        #[derive(Clone, Copy, Debug)]
        pub struct InternalComponentScope;

        impl TryFrom<&str> for ServiceScope {
            type Error = crate::otel_wasi::Error;
            fn try_from(value: &str) -> Result<Self, Self::Error> {
                Ok(Self { service: SubjectToken::try_from(value)? })
            }
        }

        impl TryFrom<&str> for OrganizationScope {
            type Error = crate::otel_wasi::Error;
            fn try_from(value: &str) -> Result<Self, Self::Error> {
                Ok(Self { organization: SubjectToken::try_from(value)? })
            }
        }

        impl TryFrom<&str> for UserScope {
            type Error = crate::otel_wasi::Error;
            fn try_from(value: &str) -> Result<Self, Self::Error> {
                Ok(Self { user: SubjectToken::try_from(value)? })
            }
        }
    }
}

fn emit_grants(routes: &[ResolvedRoute]) -> Result<TokenStream, String> {
    let mut grouped: BTreeMap<(ScopeKind, Role), Vec<(Direction, TokenStream)>> = BTreeMap::new();
    for route in routes {
        for GrantSpec {
            role,
            direction,
            endpoint,
            transfer_token,
            wildcard_parameters,
        } in route.grants()?
        {
            if !role_admitted(route.scope, role) {
                return Err(format!(
                    "role {role:?} is invalid for scope {:?}",
                    route.scope
                ));
            }
            grouped.entry((route.scope, role)).or_default().push((
                direction,
                subject_expression(endpoint, transfer_token, &wildcard_parameters)?,
            ));
        }
    }

    let mut scopes: BTreeMap<ScopeKind, Vec<(Role, Vec<(Direction, TokenStream)>)>> =
        BTreeMap::new();
    for ((scope, role), grants) in grouped {
        scopes.entry(scope).or_default().push((role, grants));
    }

    let implementations = scopes
        .into_iter()
        .map(|(scope, roles)| {
            let scope_ident = format_ident!("{}Scope", scope_name(scope));
            let role_ident = format_ident!("{}Role", scope_name(scope));
            let variants = roles
                .iter()
                .map(|(role, _)| format_ident!("{}", role_name(*role)))
                .collect::<Vec<_>>();
            let arms = roles
                .into_iter()
                .map(|(role, grants)| {
                    let variant = format_ident!("{}", role_name(role));
                    let inserts =
                        grants
                            .into_iter()
                            .map(|(direction, expression)| match direction {
                                Direction::Publish => {
                                    quote! { grants.publish.insert(#expression); }
                                }
                                Direction::Subscribe => {
                                    quote! { grants.subscribe.insert(#expression); }
                                }
                            });
                    quote! { #role_ident::#variant => { #(#inserts)* } }
                })
                .collect::<Vec<_>>();
            let fields = scope_fields(scope);
            let destructure = if fields.is_empty() {
                quote! {}
            } else {
                quote! { let Self { #(#fields),* } = self; }
            };
            quote! {
                #[derive(Clone, Copy, Debug, PartialEq, Eq)]
                pub enum #role_ident { #(#variants),* }

                impl GrantScope for #scope_ident {
                    type Role = #role_ident;
                    fn grant(&self, role: Self::Role, grants: &mut GrantSet) {
                        #destructure
                        match role { #(#arms),* }
                    }
                }
            }
        })
        .collect::<Vec<_>>();
    Ok(quote! { #(#implementations)* })
}

fn emit_dispatch() -> TokenStream {
    quote! {
        pub trait RequestRoute {
            type Scope;
            type Request: 'static;
            type Response: 'static;
            type Delivery: RequestResponseDelivery<Self::Response>;
            fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response>;
            fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error>;
        }

        pub trait OutboundRequestRoute: RequestRoute {
            fn subject(scope: &Self::Scope) -> String;
        }

        pub trait RequestResponseDelivery<Response> {
            fn reply_result(
                msg: crate::wasmcloud::messaging::types::NatsMessage,
                result: Result<Response, crate::otel_wasi::Error>,
                serializer: crate::skir_client::Serializer<Response>,
            ) -> impl std::future::Future<Output = Result<(), crate::otel_wasi::Error>>;
        }

        pub struct DomainResponseDelivery;

        impl<Response: crate::SkirResponse> RequestResponseDelivery<Response> for DomainResponseDelivery {
            async fn reply_result(
                msg: crate::wasmcloud::messaging::types::NatsMessage,
                result: Result<Response, crate::otel_wasi::Error>,
                _serializer: crate::skir_client::Serializer<Response>,
            ) -> Result<(), crate::otel_wasi::Error> {
                crate::wasmcloud::messaging::reply_handler_result(msg, result).await
            }
        }

        pub struct PlainResponseDelivery;

        impl<Response: 'static> RequestResponseDelivery<Response> for PlainResponseDelivery {
            async fn reply_result(
                msg: crate::wasmcloud::messaging::types::NatsMessage,
                result: Result<Response, crate::otel_wasi::Error>,
                serializer: crate::skir_client::Serializer<Response>,
            ) -> Result<(), crate::otel_wasi::Error> {
                let response = result?;
                let body = serializer.to_bytes(&response);
                crate::wasmcloud::messaging::reply(msg, body).await
            }
        }

        pub trait EventRoute {
            type Scope;
            type Event: 'static;
            fn serializer() -> crate::skir_client::Serializer<Self::Event>;
            fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error>;
        }

        pub trait OutboundEventRoute {
            type Scope;
            type Event: 'static;
            fn serializer() -> crate::skir_client::Serializer<Self::Event>;
            fn subject(scope: &Self::Scope) -> String;
        }

        pub trait PersistentEventRoute: OutboundEventRoute {
            fn stream() -> &'static str;
        }

        pub trait TransientEventRoute: OutboundEventRoute {}

        pub struct EventDelivery<Route: OutboundEventRoute> {
            subject: String,
            route: std::marker::PhantomData<Route>,
        }

        impl<Route: OutboundEventRoute> EventDelivery<Route> {
            fn new(scope: &Route::Scope) -> Self {
                Self {
                    subject: Route::subject(scope),
                    route: std::marker::PhantomData,
                }
            }

            pub fn subject(&self) -> &str {
                &self.subject
            }

        }

        impl<Route: TransientEventRoute> EventDelivery<Route> {
            pub async fn publish(&self, event: Route::Event) -> Result<(), crate::otel_wasi::Error> {
                crate::wasmcloud::messaging::publish(
                    self.subject.clone(),
                    Route::serializer().to_bytes(&event),
                ).await
            }
        }

        impl<Route: PersistentEventRoute> EventDelivery<Route> {
            pub async fn persist(&self, event: Route::Event) -> Result<(), crate::otel_wasi::Error> {
                let acknowledgement = crate::wasmcloud::messaging::persist(
                    self.subject.clone(),
                    Route::serializer().to_bytes(&event),
                ).await?;
                if acknowledgement.stream_name != Route::stream() {
                    return Err(crate::otel_wasi::Error::new(
                        "transport-event-wrong-stream",
                        format!("expected {}, got {}", Route::stream(), acknowledgement.stream_name),
                    ));
                }
                Ok(())
            }
        }

        pub async fn dispatch_request<Route, Handler, Work>(
            msg: crate::wasmcloud::messaging::types::NatsMessage,
            handler: Handler,
        ) -> Option<Result<(), crate::otel_wasi::Error>>
        where
            Route: RequestRoute,
            Handler: FnOnce(
                crate::wasmcloud::messaging::types::NatsMessage,
                Route::Scope,
                Route::Request,
            ) -> Work,
            Work: std::future::Future<Output = Result<Route::Response, crate::otel_wasi::Error>>,
        {
            let scope = match Route::scope(&msg.subject) {
                Ok(None) => return None,
                Ok(Some(scope)) => Ok(scope),
                Err(error) => Err(error),
            };
            let result = async {
                let scope = scope?;
                let request = Route::method().request_serializer.from_bytes(
                    &msg.body,
                    crate::skir_client::UnrecognizedValues::Drop,
                ).map_err(|error| crate::otel_wasi::Error::new("transport-decode", error.to_string()))?;
                handler(msg.clone(), scope, request).await
            }.await;
            Some(Route::Delivery::reply_result(
                msg,
                result,
                Route::method().response_serializer.clone(),
            ).await)
        }

        pub async fn request_route<Route: OutboundRequestRoute>(
            scope: &Route::Scope,
            request: &Route::Request,
        ) -> Result<Route::Response, crate::otel_wasi::Error> {
            let response = crate::wasmcloud::messaging::request(
                Route::subject(scope),
                Route::method().request_serializer.to_bytes(request),
            ).await?;
            Route::method().response_serializer
                .from_bytes(&response.body, crate::skir_client::UnrecognizedValues::Drop)
                .map_err(|error| crate::otel_wasi::Error::new("transport-decode", error.to_string()))
        }

        pub fn unmatched_route(
            msg: &crate::wasmcloud::messaging::types::NatsMessage,
            slug: &'static str,
        ) -> crate::otel_wasi::Error {
            crate::otel_wasi::Error::new(slug, format!("Unknown subject: {}", msg.subject))
        }

        pub async fn dispatch_event<Route, Handler, Work>(
            msg: crate::wasmcloud::messaging::types::NatsMessage,
            handler: Handler,
        ) -> Option<Result<(), crate::otel_wasi::Error>>
        where
            Route: EventRoute,
            Handler: FnOnce(
                crate::wasmcloud::messaging::types::NatsMessage,
                Route::Scope,
                Route::Event,
            ) -> Work,
            Work: std::future::Future<Output = Result<(), crate::otel_wasi::Error>>,
        {
            let scope = match Route::scope(&msg.subject) {
                Ok(None) => return None,
                Ok(Some(scope)) => Ok(scope),
                Err(error) => Err(error),
            };
            Some(async {
                let scope = scope?;
                let event = Route::serializer().from_bytes(
                    &msg.body,
                    crate::skir_client::UnrecognizedValues::Drop,
                ).map_err(|error| crate::otel_wasi::Error::new("transport-decode", error.to_string()))?;
                handler(msg, scope, event).await
            }.await)
        }

        #[macro_export]
        macro_rules! dispatch_route {
            ($msg:expr, $route:ty, $handler:path) => {
                if let Some(result) = $crate::transport_routes::dispatch_request::<$route, _, _>(
                    $msg.clone(),
                    $handler,
                ).await {
                    return result;
                }
            };
        }

        #[macro_export]
        macro_rules! dispatch_event_route {
            ($msg:expr, $route:ty, $handler:path) => {
                if let Some(result) =
                    $crate::transport_routes::dispatch_event::<$route, _, _>($msg.clone(), $handler).await
                {
                    return result;
                }
            };
        }
    }
}

fn projection_identifier(value: &str) -> syn::Ident {
    let mut output = String::new();
    for part in value.split('_') {
        let mut characters = part.chars();
        if let Some(first) = characters.next() {
            output.extend(first.to_uppercase());
            output.extend(characters);
        }
    }
    format_ident!("{output}")
}

fn emit_membership_projections(routes: &[ResolvedRoute]) -> Result<TokenStream, String> {
    let projections = routes
        .iter()
        .filter_map(|route| {
            let ResolvedFlow::Watch { updates, .. } = &route.flow else {
                return None;
            };
            let Delivery::Persistent {
                stream, projection, ..
            } = &updates.delivery
            else {
                return None;
            };
            let address = updates.addresses.get(&Side::Panel)?;
            Some((route.scope, stream, projection, address))
        })
        .collect::<Vec<_>>();
    let variants = projections
        .iter()
        .map(|(_, _, projection, _)| projection_identifier(&projection.to_string()))
        .collect::<Vec<_>>();
    let id_arms = projections
        .iter()
        .zip(&variants)
        .map(|((_, _, projection, _), variant)| {
            let value = projection.to_string();
            quote! { Self::#variant => #value }
        });
    let stream_arms = projections
        .iter()
        .zip(&variants)
        .map(|((_, stream, _, _), variant)| quote! { Self::#variant => #stream });
    let subject_arms = projections
        .iter()
        .zip(&variants)
        .map(|((scope, _, _, address), variant)| {
            let expression = subject_expression(address, false, &Default::default())?;
            match scope {
                ScopeKind::User => Ok(quote! {
                    Self::#variant if organization.is_none() => {
                        let user = actor;
                        Ok(#expression)
                    }
                }),
                ScopeKind::OrganizationActor | ScopeKind::Organization => Ok(quote! {
                    Self::#variant => {
                        let organization = organization.ok_or_else(|| crate::otel_wasi::Error::new(
                            "permissions-consumer-organization-required",
                            "organization scope is not admitted",
                        ))?;
                        Ok(#expression)
                    }
                }),
                other => Err(format!(
                    "persistent projection has unsupported scope {other:?}"
                )),
            }
        })
        .collect::<Result<Vec<_>, String>>()?;

    Ok(quote! {
        #[derive(Clone, Copy, Debug, PartialEq, Eq)]
        pub enum MembershipProjection { #(#variants),* }

        impl MembershipProjection {
            pub fn id(self) -> &'static str {
                match self { #(#id_arms),* }
            }

            pub fn stream(self) -> &'static str {
                match self { #(#stream_arms),* }
            }

            pub fn event_subject(
                self,
                actor: &SubjectToken,
                organization: Option<&SubjectToken>,
            ) -> Result<String, crate::otel_wasi::Error> {
                match self {
                    #(#subject_arms),*,
                    _ => Err(crate::otel_wasi::Error::new(
                        "permissions-consumer-projection-scope-invalid",
                        "projection does not belong to the admitted scope",
                    )),
                }
            }
        }
    })
}

pub fn emit(routes: &[ResolvedRoute]) -> Result<Vec<OutputFile>, String> {
    let scope_tokens = emit_scopes();
    let grant_tokens = emit_grants(routes)?;
    let projection_tokens = emit_membership_projections(routes)?;
    let dispatch_tokens = emit_dispatch();
    let route_tokens = routes
        .iter()
        .map(emit_request_route)
        .collect::<Result<Vec<_>, String>>()?
        .into_iter()
        .flatten()
        .collect::<Vec<_>>();
    let event_tokens = routes
        .iter()
        .map(emit_event_route)
        .collect::<Result<Vec<_>, String>>()?
        .into_iter()
        .flatten()
        .collect::<Vec<_>>();
    let delivery_tokens = routes
        .iter()
        .map(emit_update_delivery)
        .collect::<Result<Vec<_>, String>>()?
        .into_iter()
        .flatten()
        .collect::<Vec<_>>();
    let tokens = quote! {
        #scope_tokens
        #grant_tokens
        #projection_tokens
        #dispatch_tokens
        #(#route_tokens)*
        #(#event_tokens)*
        #(#delivery_tokens)*
    };
    let syntax = syn::parse2::<syn::File>(tokens)
        .map_err(|error| format!("generated Rust source is invalid: {error}"))?;
    Ok(vec![OutputFile {
        path: "mod.rs".to_owned(),
        code: prettyplease::unparse(&syntax),
    }])
}
