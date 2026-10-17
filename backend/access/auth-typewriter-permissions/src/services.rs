//! Authorization policy for service identities.
//!
//! Service claims provide the candidate service identity, but registration status and messaging
//! scope come from the service contracts. Unbound services receive only their registration
//! exchange. Bound services additionally receive organization and Realm subjects derived from
//! the authoritative binding query and scope responses. A missing service, failed lookup, unknown
//! contract variant, invalid Realm identifier, or organization mismatch aborts policy resolution.

use otel_wasi::{main_attribute, wasi_error};
use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    skir::base::{
        access::v1::permission::{Permissions, ResponsePermission},
        kernel::v1::duration::Duration,
        kernel::v1::record_id::{RecordId, RecordIdKey},
        service::v1::status::{
            QueryServiceBindingRequest, QueryServiceBindingResponse, ServiceBinding,
        },
        service::v1::topology::{
            GetServiceMessagingScopeRequest, GetServiceMessagingScopeResponse,
        },
    },
    skir_utils::RecordIdKeyIdentity,
    transport_routes::{
        GrantScope, GrantSet, RealmRole, RealmScope, ServiceBindingQueryRoute,
        ServiceMessagingScopeRoute, ServiceRole, ServiceScope, SubjectToken, request_route,
    },
};

use crate::common::build_permissions;

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
/// Claims consumed when deriving policy for a service identity.
///
/// The subject selects the service record to inspect. Registration and messaging state still come
/// from authoritative service contract responses, not from these claims.
pub struct ServiceClaims {
    pub preferred_username: Option<String>,
    pub name: Option<String>,
    #[serde(default)]
    pub groups: Vec<String>,
}

#[tracing::instrument]
/// Derive the NATS policy and tags for one authenticated service identity.
///
/// Registration subjects are scoped to the service identifier. Organization and Realm subjects
/// are added only when the binding and messaging scope agree. Lookup failures
/// remain failures because granting policy without current ownership data would cross the trust
/// boundary.
pub async fn handle_service(
    claims: jose::jwt::Claims<ServiceClaims>,
) -> Result<(Permissions, Vec<String>), otel_wasi::Error> {
    let service_id = claims
        .subject
        .ok_or_else(|| wasi_error!("permissions-panel-no-subject", "No subject in claims"))?;

    let service_name = claims
        .additional
        .preferred_username
        .or(claims.additional.name)
        .unwrap_or_else(|| "Unknown Service".to_string());

    main_attribute!(
        "auth.entity.id" = service_id.clone(),
        "auth.entity.type" = "service",
        "auth.entity.name" = service_name.clone(),
    );

    let service_scope = ServiceScope::try_from(service_id.as_str())?;
    let binding = query_service_binding(&service_scope).await?;
    let mut grants = GrantSet::default();
    service_scope.grant(ServiceRole::RegisteredService, &mut grants);
    let mut tags = vec![format!("service:{service_id}")];

    grants.subscribe.insert(format!("_INBOX.{service_id}.*"));
    main_attribute!("auth.permissions.category.registration" = true);

    handle_service_binding(binding, &service_id, &mut grants, &mut tags).await?;

    let permissions = build_permissions(
        grants.publish.into_iter().collect(),
        grants.subscribe.into_iter().collect(),
        Some(service_response_permission()),
    );

    main_attribute!(
        "auth.permissions.publish.allow.count" = permissions.publish.allow.len() as i64,
        "auth.permissions.subscribe.allow.count" = permissions.subscribe.allow.len() as i64,
    );

    Ok((permissions, tags))
}

pub(crate) fn service_response_permission() -> ResponsePermission {
    ResponsePermission {
        max_messages: Some(1),
        ttl: Some(Duration {
            milliseconds: 300_000,
            _unrecognized: None,
        }),
        _unrecognized: None,
    }
}

/// Read the durable binding without renewing a registration lease.
async fn query_service_binding(
    service_scope: &ServiceScope,
) -> Result<ServiceBinding, otel_wasi::Error> {
    let service_id = &service_scope.service;
    let data = QueryServiceBindingRequest::default();
    match request_route::<ServiceBindingQueryRoute>(service_scope, &data).await? {
        QueryServiceBindingResponse::Binding(binding) => Ok(binding.binding),
        QueryServiceBindingResponse::ServiceNotFoundError(_) => Err(wasi_error!(
            "permissions-service-not-found",
            "service not found: {}",
            service_id
        )),
        QueryServiceBindingResponse::InternalError(_) => Err(wasi_error!(
            "permissions-service-binding-internal-error",
            "service registration binding query failed for: {}",
            service_id
        )),
        QueryServiceBindingResponse::Unknown(_) => Err(wasi_error!(
            "permissions-service-binding-unknown-response",
            "unknown response from service binding query for: {}",
            service_id
        )),
    }
}

async fn handle_service_binding(
    binding: ServiceBinding,
    service_id: &str,
    grants: &mut GrantSet,
    tags: &mut Vec<String>,
) -> Result<(), otel_wasi::Error> {
    match binding {
        ServiceBinding::Bound(bound) => {
            handle_bound_binding(*bound, service_id, grants, tags).await?;
        }
        ServiceBinding::Unbound => {
            handle_unbound_binding();
        }
        ServiceBinding::Unknown(_) => {
            return Err(wasi_error!(
                "permissions-service-no-binding",
                "service binding query has no binding information",
            ));
        }
    }
    Ok(())
}

async fn handle_bound_binding(
    bound: wasmcloud_utils::skir::base::service::v1::status::ServiceBinding_Bound,
    service_id: &str,
    grants: &mut GrantSet,
    tags: &mut Vec<String>,
) -> Result<(), otel_wasi::Error> {
    let org_id = bound.organization_id.clone();
    main_attribute!(
        "auth.permissions.service.binding" = "bound",
        "auth.entity.organization_id" = org_id.clone(),
        "auth.permissions.category.cloud" = true,
        "auth.permissions.category.realm" = true,
    );

    tags.push(format!("organization:{org_id}"));

    let scope = query_service_messaging_scope(&ServiceScope::try_from(service_id)?).await?;
    if scope.organization_id != org_id {
        return Err(wasi_error!(
            "permissions-service-scope-organization-mismatch",
            "Service messaging scope belongs to another organization",
        ));
    }

    if let Some(realm) = scope
        .owned_realm
        .as_ref()
        .map(|record| record.key.raw_identity())
        .transpose()?
    {
        grant_realm(&org_id, realm, RealmRole::Coordinator, grants)?;
        grant_realm(&org_id, realm, RealmRole::Participant, grants)?;
    }

    if let Some(realm) = scope
        .attached_realm
        .as_ref()
        .map(|record| record.key.raw_identity())
        .transpose()?
    {
        grant_realm(&org_id, realm, RealmRole::Participant, grants)?;
    }

    Ok(())
}

fn grant_realm(
    organization_id: &str,
    realm_id: &str,
    role: RealmRole,
    grants: &mut GrantSet,
) -> Result<(), otel_wasi::Error> {
    let scope = RealmScope {
        organization: SubjectToken::try_from(organization_id)?,
        realm: SubjectToken::try_from(realm_id)?,
    };
    scope.grant(role, grants);
    Ok(())
}

/// Read the authoritative host messaging scope used to qualify Realm permissions.
async fn query_service_messaging_scope(
    service_scope: &ServiceScope,
) -> Result<
    wasmcloud_utils::skir::base::service::v1::topology::ServiceMessagingScope,
    otel_wasi::Error,
> {
    let service_id = &service_scope.service;
    let request_value = GetServiceMessagingScopeRequest {
        service_id: RecordId {
            table: "service".into(),
            key: RecordIdKey::String(service_id.as_str().into()),
            _unrecognized: None,
        },
        _unrecognized: None,
    };
    match request_route::<ServiceMessagingScopeRoute>(service_scope, &request_value).await? {
        GetServiceMessagingScopeResponse::Found(scope) => Ok(*scope),
        GetServiceMessagingScopeResponse::NotFound(_) => Err(wasi_error!(
            "permissions-service-messaging-scope-not-found",
            "Service has no host messaging scope",
        )),
        GetServiceMessagingScopeResponse::InternalError(_) => Err(wasi_error!(
            "permissions-service-messaging-scope-internal-error",
            "Service messaging scope query failed",
        )),
        GetServiceMessagingScopeResponse::Unknown(_) => Err(wasi_error!(
            "permissions-service-messaging-scope-unknown-response",
            "Service messaging scope returned an unknown response",
        )),
    }
}

fn handle_unbound_binding() {
    main_attribute!("auth.permissions.service.binding" = "unbound");
}
