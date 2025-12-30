use anyhow::Result;
use nats_jwt_rs::types::Permissions as NatsPermissions;
use serde::{Deserialize, Serialize};
use wasmcloud_component::debug;

use crate::common::build_nats_permissions;

/// Claims structure for service JWT tokens (simpler than user claims)
#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct ServiceClaims {
    pub preferred_username: Option<String>,
    pub name: Option<String>,
    #[serde(default)]
    pub groups: Vec<String>,
}

/// Handle permission request for services (realm, engine, etc.)
pub fn handle_service(
    claims: jose::jwt::Claims<ServiceClaims>,
    organization_id: Option<String>,
) -> Result<(NatsPermissions, Vec<String>)> {
    let service_id = claims
        .subject
        .ok_or(anyhow::anyhow!("No subject in claims"))?;

    let service_name = claims
        .additional
        .preferred_username
        .or(claims.additional.name)
        .unwrap_or_else(|| "Unknown Service".to_string());

    debug!("handling service permission request for service {} ({})", service_name, service_id);

    let mut allow_publish = vec![];
    let mut allow_subscribe = vec![];
    let mut tags = vec![];

    // ########### PERMISSIONS ###########
    {
        // Basic inbox permission for responses
        allow_subscribe.push(format!("_INBOX.{}.>", &service_id));

        // Organization context (if provided)
        if let Some(ref org_id) = organization_id {
            tags.push(format!("org:{}", org_id));

            // Allow services to communicate within their organization context
            // These can be expanded as specific features are implemented
            allow_publish.push(format!(
                "cloud.service.{}.organization.{}.*",
                service_id, org_id
            ));
            allow_subscribe.push(format!(
                "cloud.service.{}.organization.{}.*",
                service_id, org_id
            ));
        }

        // Service-specific subjects for general service communication
        // This provides a foundation for future service-to-service messaging
        allow_publish.push(format!("cloud.service.{}.>", service_id));
        allow_subscribe.push(format!("cloud.service.{}.>", service_id));
    }
    // ######### END PERMISSIONS #########

    let permissions = build_nats_permissions(allow_publish, allow_subscribe);

    debug!("finished handling permissions request for service {}", service_name);

    Ok((permissions, tags))
}
