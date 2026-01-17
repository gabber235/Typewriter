use anyhow::{anyhow, Result};
use nats_jwt_rs::types::Permissions as NatsPermissions;
use prost::Message;
use serde::{Deserialize, Serialize};
use wasmcloud_component::debug;
use wasmcloud_utils::wasmcloud::messaging::consumer;

use crate::common::build_nats_permissions;
use crate::typewriter::api::v1::{
    get_service_status_response, service_status, GetServiceStatusRequest,
    GetServiceStatusResponse, ServiceStatus,
};

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct ServiceClaims {
    pub preferred_username: Option<String>,
    pub name: Option<String>,
    #[serde(default)]
    pub groups: Vec<String>,
}

fn query_service_status(service_id: &str) -> Result<ServiceStatus> {
    let subject = format!("typewriter.in.service.{}.status", service_id);
    let request = GetServiceStatusRequest {};
    let body = request.encode_to_vec();

    debug!("querying service status on subject: {}", subject);

    let response = consumer::request(&subject, &body, 5000).map_err(|e| anyhow!(e))?;
    let status_response = GetServiceStatusResponse::decode(&response.body[..])?;

    match status_response.result {
        Some(get_service_status_response::Result::Status(status)) => Ok(status),
        Some(get_service_status_response::Result::Error(err)) => {
            Err(anyhow!("service status error: {} - {}", err.code, err.message))
        }
        None => Err(anyhow!("empty response from service status")),
    }
}

pub fn handle_service(
    claims: jose::jwt::Claims<ServiceClaims>,
    _organization_id: Option<String>,
) -> Result<(NatsPermissions, Vec<String>)> {
    let service_id = claims
        .subject
        .ok_or(anyhow!("No subject in claims"))?;

    let service_name = claims
        .additional
        .preferred_username
        .or(claims.additional.name)
        .unwrap_or_else(|| "Unknown Service".to_string());

    debug!(
        "handling service permission request for service {} ({})",
        service_name, service_id
    );

    let status = query_service_status(&service_id)?;

    let mut allow_publish = vec![];
    let mut allow_subscribe = vec![];
    let mut tags = vec![format!("service:{}", service_id)];

    allow_subscribe.push(format!("_INBOX.{}.>", service_id));
    allow_publish.push(format!("cloud.out.service.{}.status", service_id));

    match status.binding {
        Some(service_status::Binding::Bound(bound)) => {
            let org_id = bound.organization_id;
            debug!("service {} is bound to org {}", service_id, org_id);

            tags.push(format!("org:{}", org_id));

            allow_publish.push(format!(
                "cloud.out.service.{}.organization.{}.>",
                service_id, org_id
            ));
            allow_subscribe.push(format!(
                "cloud.in.service.{}.organization.{}.>",
                service_id, org_id
            ));
        }
        Some(service_status::Binding::Unbound(_)) => {
            debug!("service {} is unbound, granting minimal permissions", service_id);

            allow_subscribe.push(format!(
                "cloud.in.service.{}.registration.bound",
                service_id
            ));
        }
        None => {
            return Err(anyhow!("service status has no binding information"));
        }
    }

    let permissions = build_nats_permissions(allow_publish, allow_subscribe);

    debug!(
        "finished handling permissions request for service {}",
        service_name
    );

    Ok((permissions, tags))
}
