use std::fmt::Display;

use prost::Message;
use wasmcloud_utils::wasmcloud::messaging::send;

use crate::typewriter::api::v1::{ListOrganizationServicesRequest, ServiceBoundNotification};

pub fn publish_bound_notification(
    service_id: impl Display,
    organization_id: impl Display,
    organization_name: impl Display,
) -> Result<(), String> {
    let notification = ServiceBoundNotification {
        organization_id: organization_id.to_string(),
        organization_name: Some(organization_name.to_string()),
    };

    send(
        format!("typewriter.out.service.{}.registration.bound", service_id),
        String::new(),
        notification.encode_to_vec(),
    )
}

pub fn refresh_organization_services_list(
    org_id: impl Display,
    user_id: Option<&String>,
) -> Result<(), String> {
    let user_id = user_id.map(|u| u.as_str()).unwrap_or("x");

    send(
        format!(
            "typewriter.in.user.{}.organization.{}.services.list",
            user_id, org_id,
        ),
        format!("typewriter.out.organization.{}.services.list", org_id),
        ListOrganizationServicesRequest {}.encode_to_vec(),
    )
}
