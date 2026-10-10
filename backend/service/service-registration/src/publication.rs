//! Current projection refreshes owned by service registration.

use otel_wasi::ResultWithSlug;
use wasmcloud_utils::{
    database::{RecordId, organization::OrganizationRecord, read_query},
    publication::{ProjectionRefresh, ProjectionRefresher},
    skir::base::service::v1::{
        organization::OrganizationServicesChanged, registration::ServiceBoundNotification,
        topology::OrganizationTopologyChanged,
    },
    skir_utils::RecordIdKeyIdentity,
    transport_routes::{
        OrganizationScope, OrganizationServicesWatchRoute, OrganizationTopologyWatchRoute,
        ServiceBindingQueryRoute, ServiceScope,
    },
};

pub struct ServiceProjectionRefresher;

impl ProjectionRefresher for ServiceProjectionRefresher {
    async fn refresh(&self, refresh: ProjectionRefresh) -> Result<(), otel_wasi::Error> {
        match refresh {
            ProjectionRefresh::Services { organization } => {
                let values = crate::watch::snapshot(&organization).await?;
                OrganizationServicesWatchRoute::delivery(&OrganizationScope::try_from(
                    organization.as_str(),
                )?)
                .publish(OrganizationServicesChanged::Replace(values))
                .await
            }
            ProjectionRefresh::Topology { organization } => {
                let value = crate::watch_topology::snapshot(&organization).await?;
                OrganizationTopologyWatchRoute::delivery(&OrganizationScope::try_from(
                    organization.as_str(),
                )?)
                .publish(OrganizationTopologyChanged::Replace(Box::new(value)))
                .await
            }
            ProjectionRefresh::ServiceBinding { service } => refresh_binding(service).await,
        }
    }
}

async fn refresh_binding(service: RecordId) -> Result<(), otel_wasi::Error> {
    let organization = read_query!("SELECT VALUE organization.* FROM ONLY $service")
        .bind("service", &service)
        .execute()
        .await
        .error_with_slug("service-binding-snapshot-query-failed")?
        .parse::<Option<OrganizationRecord>>()
        .error_with_slug("service-binding-snapshot-parse-failed")?;
    if let Some(organization) = organization {
        let service_id = service.key.raw_identity()?;
        ServiceBindingQueryRoute::delivery(&ServiceScope::try_from(service_id)?)
            .publish(ServiceBoundNotification {
                organization_id: organization.id.key.raw_identity()?.to_owned(),
                organization_name: Some(organization.name),
                _unrecognized: None,
            })
            .await?;
    }
    Ok(())
}
