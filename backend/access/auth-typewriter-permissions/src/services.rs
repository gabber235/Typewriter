use otel_wasi::{main_attribute, wasi_error};
use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    decode_skir,
    skir::base::{
        access::v1::permission::Permissions,
        kernel::v1::record_id::{RecordId, RecordIdKey},
        service::v1::status::{GetServiceStatusRequest, GetServiceStatusResponse, ServiceBinding},
        service::v1::topology::{
            GetServiceMessagingScopeRequest, GetServiceMessagingScopeResponse,
        },
    },
    wasmcloud::messaging::request,
};

use crate::common::build_permissions;

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct ServiceClaims {
    pub preferred_username: Option<String>,
    pub name: Option<String>,
    #[serde(default)]
    pub groups: Vec<String>,
}

#[tracing::instrument]
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

    let status = query_service_status(&service_id).await?;

    let mut allow_publish = vec![];
    let mut allow_subscribe = vec![];
    let mut tags = vec![format!("service:{service_id}")];

    allow_subscribe.push(format!("_INBOX.{service_id}.>"));
    allow_publish.push("_INBOX.>".to_string());

    allow_publish.push(format!("cloud.to.service.{service_id}.status"));
    allow_publish.push(format!("cloud.to.service.{service_id}.heartbeat"));
    allow_publish.push(format!("cloud.to.service.{service_id}.shutdown"));
    allow_subscribe.push(format!(
        "cloud.from.service.{service_id}.registration.bound"
    ));
    allow_publish.push(format!("cloud.to.service.{service_id}.execution.watch"));
    allow_publish.push(format!("cloud.to.service.{service_id}.execution.register"));
    allow_publish.push(format!("cloud.to.service.{service_id}.execution.report"));
    allow_subscribe.push(format!("cloud.from.service.{service_id}.execution.watch"));
    main_attribute!("auth.permissions.category.registration" = true);

    match status {
        GetServiceStatusResponse::Status(status) => {
            handle_service_status(
                *status,
                &service_id,
                &mut allow_publish,
                &mut allow_subscribe,
                &mut tags,
            )
            .await?
        }
        GetServiceStatusResponse::ServiceNotFoundError(_) => {
            return Err(wasi_error!(
                "permissions-service-not-found",
                "service not found: {}",
                service_id
            ));
        }
        GetServiceStatusResponse::InternalError(_) => {
            return Err(wasi_error!(
                "permissions-service-status-internal-error",
                "service-registration internal error for: {}",
                service_id
            ));
        }
        GetServiceStatusResponse::Unknown(_) => {
            return Err(wasi_error!(
                "permissions-service-status-unknown-response",
                "unknown response from service status for: {}",
                service_id
            ));
        }
    }

    let permissions = build_permissions(allow_publish, allow_subscribe);

    main_attribute!(
        "auth.permissions.publish.allow.count" = permissions.publish.allow.len() as i64,
        "auth.permissions.subscribe.allow.count" = permissions.subscribe.allow.len() as i64,
    );

    Ok((permissions, tags))
}

async fn query_service_status(
    service_id: &str,
) -> Result<GetServiceStatusResponse, otel_wasi::Error> {
    let subject = format!("service.{service_id}.status");

    let data = GetServiceStatusRequest::default();

    let response = request(
        subject,
        GetServiceStatusRequest::serializer().to_bytes(&data),
    )
    .await?;

    decode_skir!(GetServiceStatusResponse, &response.body)
}

async fn handle_service_status(
    status: wasmcloud_utils::skir::base::service::v1::status::GetServiceStatusResponse_Status,
    service_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
    tags: &mut Vec<String>,
) -> Result<(), otel_wasi::Error> {
    match status.binding {
        ServiceBinding::Bound(bound) => {
            handle_bound_binding(*bound, service_id, allow_publish, allow_subscribe, tags).await?;
        }
        ServiceBinding::Unbound(_) => {
            handle_unbound_binding();
        }
        ServiceBinding::Unknown(_) => {
            return Err(wasi_error!(
                "permissions-service-no-binding",
                "service status has no binding information",
            ));
        }
    }
    Ok(())
}

async fn handle_bound_binding(
    bound: wasmcloud_utils::skir::base::service::v1::status::ServiceBinding_Bound,
    service_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
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

    for suffix in ["status", "heartbeat", "shutdown"] {
        allow_publish.push(format!(
            "cloud.to.service.{service_id}.organization.{org_id}.{suffix}",
        ));
    }
    for suffix in ["configuration", "command"] {
        allow_subscribe.push(format!(
            "cloud.from.service.{service_id}.organization.{org_id}.{suffix}",
        ));
    }

    let scope = query_service_messaging_scope(service_id).await?;
    if scope.organization_id != org_id {
        return Err(wasi_error!(
            "permissions-service-scope-organization-mismatch",
            "Service messaging scope belongs to another organization",
        ));
    }

    if let Some(realm) = scope.owned_realm.as_ref().map(record_key).transpose()? {
        add_realm_coordinator_permissions(&org_id, &realm, allow_publish, allow_subscribe);
        add_realm_participant_permissions(&org_id, &realm, allow_publish, allow_subscribe);
    }

    if let Some(realm) = scope.attached_realm.as_ref().map(record_key).transpose()? {
        add_realm_participant_permissions(&org_id, &realm, allow_publish, allow_subscribe);
    }

    Ok(())
}

fn add_realm_coordinator_permissions(
    organization_id: &str,
    realm_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    allow_subscribe.push(format!(
        "service.to.{realm_id}.organization.{organization_id}.realm.>"
    ));
    allow_subscribe.push(format!(
        "typewriter.organization.{organization_id}.realm.{realm_id}.hosts.state"
    ));
    allow_publish.push(format!(
        "service.from.{realm_id}.organization.{organization_id}.realm.>"
    ));
    for suffix in ["probe", "command", "status"] {
        allow_publish.push(format!(
            "typewriter.organization.{organization_id}.realm.{realm_id}.hosts.{suffix}"
        ));
    }
    allow_publish.push(format!(
        "typewriter.organization.{organization_id}.realm.{realm_id}.shared.changed"
    ));
}

fn add_realm_participant_permissions(
    organization_id: &str,
    realm_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    for suffix in ["probe", "command", "status"] {
        allow_subscribe.push(format!(
            "typewriter.organization.{organization_id}.realm.{realm_id}.hosts.{suffix}"
        ));
    }
    allow_subscribe.push(format!(
        "typewriter.organization.{organization_id}.realm.{realm_id}.shared.changed"
    ));
    allow_publish.push(format!(
        "typewriter.organization.{organization_id}.realm.{realm_id}.hosts.state"
    ));
    for suffix in SHARED_REQUEST_SUFFIXES {
        allow_publish.push(format!(
            "service.to.{realm_id}.organization.{organization_id}.realm.{suffix}"
        ));
    }
}

const SHARED_REQUEST_SUFFIXES: &[&str] = &[
    "shared.catalog.fetch",
    "shared.publish",
    "shared.blob.metadata",
    "shared.blob.read",
    "shared.blob.begin",
    "shared.blob.write",
    "shared.blob.complete",
];

async fn query_service_messaging_scope(
    service_id: &str,
) -> Result<
    wasmcloud_utils::skir::base::service::v1::topology::ServiceMessagingScope,
    otel_wasi::Error,
> {
    let subject = format!("service.{service_id}.messaging.scope");
    let request_value = GetServiceMessagingScopeRequest {
        service_id: RecordId {
            table: "service".into(),
            key: RecordIdKey::String(service_id.into()),
            _unrecognized: None,
        },
        _unrecognized: None,
    };
    let response = request(
        subject,
        GetServiceMessagingScopeRequest::serializer().to_bytes(&request_value),
    )
    .await?;
    let decoded = decode_skir!(GetServiceMessagingScopeResponse, &response.body)?;
    match decoded {
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

fn record_key(record: &RecordId) -> Result<String, otel_wasi::Error> {
    match &record.key {
        RecordIdKey::String(value) if !value.is_empty() => Ok(value.clone()),
        _ => Err(wasi_error!(
            "permissions-service-invalid-realm-id",
            "Service messaging scope contains an invalid Realm identifier",
        )),
    }
}

fn handle_unbound_binding() {
    main_attribute!("auth.permissions.service.binding" = "unbound");
}
