use otel_wasi::{main_attribute, wasi_error};
use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    decode_skir,
    skir::base::{
        access::v1::permission::Permissions,
        service::v1::status::{GetServiceStatusRequest, GetServiceStatusResponse, ServiceBinding},
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
    let mut tags = vec![format!("service:{}", service_id)];

    allow_subscribe.push(format!("_INBOX.{}.>", service_id));
    allow_publish.push(format!("_INBOX.>"));

    allow_publish.push(format!("cloud.to.service.{}.status", service_id));
    allow_publish.push(format!("cloud.to.service.{}.heartbeat", service_id));
    allow_publish.push(format!("cloud.to.service.{}.shutdown", service_id));

    match status {
        GetServiceStatusResponse::Status(status) => handle_service_status(
            *status,
            &service_id,
            &mut allow_publish,
            &mut allow_subscribe,
            &mut tags,
        )?,
        GetServiceStatusResponse::ServiceNotFound(_) => {
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
    let subject = format!("typewriter.from.service.{}.status", service_id);

    let data = GetServiceStatusRequest::default();

    let response = request(
        subject,
        GetServiceStatusRequest::serializer().to_bytes(&data),
    )
    .await?;

    decode_skir!(GetServiceStatusResponse, &response.body)
}

fn handle_service_status(
    status: wasmcloud_utils::skir::base::service::v1::status::GetServiceStatusResponse_Status,
    service_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
    tags: &mut Vec<String>,
) -> Result<(), otel_wasi::Error> {
    match status.binding {
        ServiceBinding::Bound(bound) => {
            handle_bound_binding(*bound, service_id, allow_publish, allow_subscribe, tags);
        }
        ServiceBinding::Unbound(_) => {
            handle_unbound_binding(service_id, allow_subscribe);
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

fn handle_bound_binding(
    bound: wasmcloud_utils::skir::base::service::v1::status::ServiceBinding_Bound,
    service_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
    tags: &mut Vec<String>,
) {
    let org_id = bound.organization_id.clone();
    main_attribute!(
        "auth.permissions.service.binding" = "bound",
        "auth.entity.organization_id" = org_id.clone(),
        "auth.permissions.category.cloud" = true,
        "auth.permissions.category.realm" = true,
    );

    tags.push(format!("org:{}", org_id));

    // TODO: Don't make this broad, make it narrow.
    allow_publish.push(format!(
        "cloud.to.service.{}.organization.{}.>",
        service_id, org_id
    ));
    allow_subscribe.push(format!(
        "cloud.from.service.{}.organization.{}.>",
        service_id, org_id
    ));

    allow_publish.push(format!(
        "realm.from.{}.organization.{}.>",
        service_id, org_id
    ));
    allow_subscribe.push(format!("realm.to.{}.organization.{}.>", service_id, org_id));
}

fn handle_unbound_binding(service_id: &str, allow_subscribe: &mut Vec<String>) {
    main_attribute!(
        "auth.permissions.service.binding" = "unbound",
        "auth.permissions.category.registration" = true,
    );
    allow_subscribe.push(format!(
        "cloud.from.service.{}.registration.bound",
        service_id
    ));
}
