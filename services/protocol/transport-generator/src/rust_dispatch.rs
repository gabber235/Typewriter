use std::collections::BTreeMap;

use proc_macro2::{Literal, TokenStream};
use quote::{format_ident, quote};

use crate::{
    manifest::{Delivery, ScopeKind, Side},
    resolved::{MethodBinding, ResolvedFlow, ResolvedRoute},
    subject::{Parameter, SubjectTemplate, Token},
};

pub fn type_identifier(value: &str) -> syn::Ident {
    let mut output = String::new();
    for part in value.split('_').filter(|part| !part.is_empty()) {
        let mut characters = part.chars();
        if let Some(first) = characters.next() {
            output.extend(first.to_uppercase());
            output.extend(characters);
        }
    }
    format_ident!("{output}Route")
}

fn scope_type(kind: ScopeKind) -> syn::Ident {
    format_ident!(
        "{}Scope",
        match kind {
            ScopeKind::Realm => "Realm",
            ScopeKind::Service => "Service",
            ScopeKind::BoundService => "BoundService",
            ScopeKind::OrganizationActor => "OrganizationActor",
            ScopeKind::Organization => "Organization",
            ScopeKind::User => "User",
            ScopeKind::Native => "Native",
            ScopeKind::InternalComponent => "InternalComponent",
        }
    )
}

fn endpoint_scope_type(template: &SubjectTemplate) -> Result<syn::Ident, String> {
    let captures = template
        .tokens()
        .iter()
        .filter_map(|token| match token {
            Token::Parameter(parameter) => Some(*parameter),
            Token::Literal(_) => None,
        })
        .collect::<std::collections::BTreeSet<_>>()
        .into_iter()
        .collect::<Vec<_>>();
    let kind = match captures.as_slice() {
        [] => ScopeKind::Native,
        [Parameter::User] => ScopeKind::User,
        [Parameter::Organization] => ScopeKind::Organization,
        [Parameter::Service] => ScopeKind::Service,
        [Parameter::Organization, Parameter::User] => ScopeKind::OrganizationActor,
        [Parameter::Organization, Parameter::Realm] => ScopeKind::Realm,
        [Parameter::Organization, Parameter::Service] => ScopeKind::BoundService,
        _ => {
            return Err(format!(
                "unsupported delivery subject captures {captures:?}"
            ));
        }
    };
    Ok(scope_type(kind))
}

fn required_captures(kind: ScopeKind) -> &'static [Parameter] {
    match kind {
        ScopeKind::Realm => &[Parameter::Organization, Parameter::Realm],
        ScopeKind::Service => &[Parameter::Service],
        ScopeKind::BoundService => &[Parameter::Service, Parameter::Organization],
        ScopeKind::OrganizationActor => &[Parameter::Organization, Parameter::User],
        ScopeKind::Organization => &[Parameter::Organization],
        ScopeKind::User => &[Parameter::User],
        ScopeKind::Native | ScopeKind::InternalComponent => &[],
    }
}

fn field(parameter: Parameter) -> Result<syn::Ident, String> {
    let name = match parameter {
        Parameter::Organization => "organization",
        Parameter::Realm => "realm",
        Parameter::Service => "service",
        Parameter::User => "user",
        Parameter::TransferId => return Err("transfer capture is not a request scope".to_owned()),
    };
    Ok(format_ident!("{name}"))
}

fn capture_arm(template: &SubjectTemplate, kind: ScopeKind) -> Result<TokenStream, String> {
    template.validate_scope(kind, false)?;
    let mut captures = BTreeMap::new();
    let pattern = template
        .tokens()
        .iter()
        .map(|token| match token {
            Token::Literal(value) => Ok(quote! { #value }),
            Token::Parameter(parameter) => {
                let name = field(*parameter)?;
                captures.insert(*parameter, name.clone());
                Ok(quote! { #name })
            }
        })
        .collect::<Result<Vec<_>, String>>()?;
    let scope = scope_type(kind);
    let fields = required_captures(kind)
        .iter()
        .map(|parameter| {
            let name = captures
                .get(parameter)
                .ok_or_else(|| "required scope capture is absent".to_owned())?;
            Ok(quote! { #name: SubjectToken::try_from(*#name)? })
        })
        .collect::<Result<Vec<_>, String>>()?;
    Ok(quote! {
        [#(#pattern),*] => Ok(Some(#scope { #(#fields),* })),
    })
}

fn render_subject(template: &SubjectTemplate) -> Result<TokenStream, String> {
    let mut value = String::new();
    for (index, token) in template.tokens().iter().enumerate() {
        if index > 0 {
            value.push('.');
        }
        match token {
            Token::Literal(literal) => value.push_str(literal),
            Token::Parameter(parameter) => {
                let name = field(*parameter)?;
                value.push('{');
                value.push_str(&name.to_string());
                value.push('}');
            }
        }
    }
    let literal = Literal::string(&value);
    Ok(quote! { format!(#literal) })
}

fn request_parts(flow: &ResolvedFlow) -> Option<(&MethodBinding, &crate::manifest::Endpoints)> {
    match flow {
        ResolvedFlow::Unary { method, requests }
        | ResolvedFlow::Watch {
            method, requests, ..
        }
        | ResolvedFlow::BoundedWatch {
            method, requests, ..
        } => Some((method, requests)),
        ResolvedFlow::Scatter { .. } | ResolvedFlow::Event { .. } => None,
    }
}

pub fn emit_request_route(route: &ResolvedRoute) -> Result<Option<TokenStream>, String> {
    let Some((method, requests)) = request_parts(&route.flow) else {
        return Ok(None);
    };
    let name = type_identifier(&route.name.to_string());
    let scope = scope_type(route.scope);
    let request = method.request.rust_type()?;
    let response = method.response.rust_type()?;
    let delivery = match method.response.kind {
        crate::symbols::RecordKind::Enum => quote! { DomainResponseDelivery },
        crate::symbols::RecordKind::Struct => quote! { PlainResponseDelivery },
    };
    let method_path = method.rust_method()?;
    let request_subject = requests
        .get(&Side::BackendInternal)
        .or_else(|| requests.get(&Side::Backend));
    let scope_fields = required_captures(route.scope)
        .iter()
        .map(|parameter| field(*parameter))
        .collect::<Result<Vec<_>, String>>()?;
    let outbound = request_subject
        .map(|request_subject| {
            let subject = render_subject(request_subject)?;
            let destructure = if scope_fields.is_empty() {
                quote! { let _ = scope; }
            } else {
                quote! { let #scope { #(#scope_fields),* } = scope; }
            };
            Ok::<TokenStream, String>(quote! {
                impl OutboundRequestRoute for #name {
                    fn subject(scope: &Self::Scope) -> String {
                        #destructure
                        #subject
                    }
                }
            })
        })
        .transpose()?;
    let arms = requests
        .iter()
        .filter(|(side, _)| side.is_runtime_side())
        .map(|(_, template)| capture_arm(template, route.scope))
        .collect::<Result<Vec<_>, String>>()?;
    if arms.is_empty() {
        return Ok(None);
    }
    Ok(Some(quote! {
        pub struct #name;

        impl RequestRoute for #name {
            type Scope = #scope;
            type Request = #request;
            type Response = #response;
            type Delivery = #delivery;

            fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
                #method_path()
            }

            fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
                let parts: Vec<_> = subject.split('.').collect();
                match parts.as_slice() {
                    #(#arms)*
                    _ => Ok(None),
                }
            }
        }

        #outbound
    }))
}

pub fn emit_event_route(route: &ResolvedRoute) -> Result<Option<TokenStream>, String> {
    let ResolvedFlow::Event {
        binding: crate::resolved::ResolvedEventBinding::Skir(payload),
        addresses,
        ..
    } = &route.flow
    else {
        return Ok(None);
    };
    let name = type_identifier(&route.name.to_string());
    let scope = scope_type(route.scope);
    let event = payload.rust_type()?;
    let arms = addresses
        .iter()
        .filter(|(side, _)| side.is_runtime_side())
        .map(|(_, endpoint)| capture_arm(&endpoint.subject, route.scope))
        .collect::<Result<Vec<_>, String>>()?;
    if arms.is_empty() {
        return Ok(None);
    }
    Ok(Some(quote! {
        pub struct #name;

        impl EventRoute for #name {
            type Scope = #scope;
            type Event = #event;

            fn serializer() -> crate::skir_client::Serializer<Self::Event> {
                <Self::Event>::serializer()
            }

            fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
                let parts: Vec<_> = subject.split('.').collect();
                match parts.as_slice() {
                    #(#arms)*
                    _ => Ok(None),
                }
            }
        }
    }))
}

pub fn emit_update_delivery(route: &ResolvedRoute) -> Result<Option<TokenStream>, String> {
    let ResolvedFlow::Watch { updates, .. } = &route.flow else {
        return Ok(None);
    };
    let Some(address) = updates.addresses.get(&Side::Backend) else {
        return Ok(None);
    };
    let name = type_identifier(&route.name.to_string());
    let scope = endpoint_scope_type(address)?;
    let event = updates.payload.rust_type()?;
    let subject = render_subject(address)?;
    let fields = address
        .tokens()
        .iter()
        .filter_map(|token| match token {
            Token::Parameter(parameter) => Some(field(*parameter)),
            Token::Literal(_) => None,
        })
        .collect::<Result<Vec<_>, String>>()?;
    let destructure = if fields.is_empty() {
        quote! {}
    } else {
        quote! { let #scope { #(#fields),* } = scope; }
    };
    let delivery_kind = match &updates.delivery {
        Delivery::Transient => quote! {
            impl TransientEventRoute for #name {}
        },
        Delivery::Persistent { stream, .. } => quote! {
            impl PersistentEventRoute for #name {
                fn stream() -> &'static str { #stream }
            }
        },
    };
    Ok(Some(quote! {
        impl OutboundEventRoute for #name {
            type Scope = #scope;
            type Event = #event;

            fn serializer() -> crate::skir_client::Serializer<Self::Event> {
                <Self::Event>::serializer()
            }

            fn subject(scope: &Self::Scope) -> String {
                #destructure
                #subject
            }
        }

        impl #name {
            pub fn delivery(scope: &#scope) -> EventDelivery<Self> {
                EventDelivery::new(scope)
            }
        }

        #delivery_kind
    }))
}

pub fn side_subject<'a>(
    addresses: &'a crate::manifest::Endpoints,
    side: Side,
) -> Result<&'a SubjectTemplate, String> {
    addresses
        .get(&side)
        .ok_or_else(|| format!("missing {side:?} endpoint"))
}
