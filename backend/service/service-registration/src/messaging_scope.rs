//! Resolves the Realm relationships used to scope a service's messaging.
//!
//! The result combines the service organization with the Realm owned by its host and the Realm
//! attached to its engine. A service can exist before host registration, so both Realm fields are
//! optional even when the service itself is found.

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, read_query},
    skir::base::service::v1::topology::{
        GetServiceMessagingScopeRequest, GetServiceMessagingScopeResponse,
        GetServiceMessagingScopeResponse_NotFound, ServiceMessagingScope,
    },
    skir_utils::RecordIdKeyIdentity,
    skir_variant,
    transport_routes::ServiceScope,
    wasmcloud::messaging::types::NatsMessage,
};

#[derive(Debug, Deserialize)]
struct MessagingScopeRecord {
    organization_id: RecordId,
    owned_realm: Option<RecordId>,
    attached_realm: Option<RecordId>,
}

#[tracing::instrument(skip_all)]
/// Returns the service organization, host owned Realm, and engine attached Realm.
///
/// This is a read only lookup keyed by the service identifier in the request. `NotFound` means
/// the service record does not exist. A found service with no registered host is still returned,
/// with both Realm relationships absent.
pub async fn handle(
    _msg: NatsMessage,
    scope: ServiceScope,
    _request: GetServiceMessagingScopeRequest,
) -> Result<GetServiceMessagingScopeResponse, otel_wasi::Error> {
    let service_id = RecordId::new("service", scope.service.as_str());
    let result = read_query!(
        r#"
        LET $service = array::first(SELECT organization FROM $service_id);
        LET $host = array::first(SELECT id FROM service_host WHERE service_id = $service_id);

        RETURN IF $service = NONE {
            NONE
        } ELSE {
            {
                organization_id: $service.organization,
                owned_realm: IF $host = NONE { NONE } ELSE {
                    array::first(SELECT VALUE id FROM realm_instance WHERE owner_host_id = $host.id)
                },
                attached_realm: IF $host = NONE { NONE } ELSE {
                    array::first(SELECT VALUE realm_id FROM engine_instance WHERE owner_host_id = $host.id)
                },
            }
        };
        "#,
    )
    .bind("service_id", service_id)
    .execute()
    .await
    .error_with_slug("service-messaging-scope-query-failed")?;

    let scope: Option<MessagingScopeRecord> = result
        .parse()
        .error_with_slug("service-messaging-scope-decode-failed")?;

    Ok(match scope {
        Some(scope) => GetServiceMessagingScopeResponse::Found(Box::new(ServiceMessagingScope {
            organization_id: scope.organization_id.key.raw_identity()?.to_owned(),
            owned_realm: scope.owned_realm.map(Into::into),
            attached_realm: scope.attached_realm.map(Into::into),
            _unrecognized: None,
        })),
        None => skir_variant!(GetServiceMessagingScopeResponse::NotFound {}),
    })
}
