//! Registers the runtime capabilities of a service host.
//!
//! Registration is keyed by the service identity, so repeating the same advertisement is
//! idempotent. A changed advertisement increments the host configuration `revision` and emits a
//! topology update. It does not change the desired execution topology, which is owned by
//! `configure_topology`.

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{
        RecordId, TransactionOutcome,
        topology::{ServiceHostRecord, SupportedEngineRecord},
        transaction_query,
    },
    skir::base::service::v1::topology::{
        OrganizationTopologyChanged, RegisterServiceHostRequest, RegisterServiceHostResponse,
    },
    skir_utils::RecordIdKeyIdentity,
    transport_routes::ServiceScope,
    wasmcloud::messaging::types::NatsMessage,
};

#[derive(Debug, Deserialize)]
struct RegisterHostResult {
    host: ServiceHostRecord,
    organization_id: RecordId,
    changed: bool,
}

#[tracing::instrument(skip_all)]
/// Creates or refreshes the host record advertised by a running service.
///
/// The host record stores the entrypoint, Realm capability, and supported engine identifiers.
/// Repeated equal advertisements return the existing revision and publish nothing. Changed
/// advertisements are committed before the organization topology update is published.
pub async fn handle(
    _msg: NatsMessage,
    scope: ServiceScope,
    request: RegisterServiceHostRequest,
) -> Result<RegisterServiceHostResponse, otel_wasi::Error> {
    let service_id = scope.service;
    otel_wasi::main_attribute!(
        "service.id" = service_id.to_string(),
        "host.entrypoint" = request.entrypoint.clone(),
        "host.can_host_realm" = request.can_host_realm,
        "host.supported_engine_count" = request.supported_engines.len() as i64,
    );

    let service_id = RecordId::new("service", service_id.as_str());
    let host_id = RecordId::new("service_host", service_id.key.raw_identity()?);
    let supported_engines = request
        .supported_engines
        .iter()
        .map(|engine| SupportedEngineRecord {
            engine_id: engine.engine_id.clone(),
        })
        .collect::<Vec<_>>();
    let result = transaction_query!(
        RegisterHostResult,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $service = array::first(
                SELECT * FROM $service_id
                WHERE role.type = 'host' AND organization != NONE
            );
            IF $service = NONE {
                THROW 'host-service-invalid-error'
            };

            LET $existing = array::first(SELECT * FROM $host_id);
            LET $changed = $existing = NONE
                OR $existing.entrypoint != $entrypoint
                OR $existing.can_host_realm != $can_host_realm
                OR $existing.supported_engines != $supported_engines;
            LET $host = IF $existing = NONE {
                CREATE ONLY $host_id SET
                    service_id = $service_id,
                    entrypoint = $entrypoint,
                    can_host_realm = $can_host_realm,
                    supported_engines = $supported_engines
            } ELSE IF $changed {
                UPDATE ONLY $host_id SET
                    revision += 1,
                    entrypoint = $entrypoint,
                    can_host_realm = $can_host_realm,
                    supported_engines = $supported_engines
                RETURN AFTER
            } ELSE {
                $existing
            };

            RETURN {
                host: $host,
                organization_id: $service.organization,
                changed: $changed,
            };
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("service_id", service_id)
    .bind("host_id", host_id)
    .bind("entrypoint", request.entrypoint)
    .bind("can_host_realm", request.can_host_realm)
    .bind("supported_engines", supported_engines)
    .execute()
    .await
    .error_with_slug("service-host-register-query-failed")?
    .decode()
    .error_with_slug("service-host-register-result-parse-failed")?;

    let result = match result {
        TransactionOutcome::Committed(result) => result,
        TransactionOutcome::Rejected(error) => {
            return Err(otel_wasi::Error::new(
                "service-host-register-rejected",
                error.message(),
            ));
        }
    };
    let host = wasmcloud_utils::skir::base::service::v1::topology::ServiceHost::from(result.host);
    if result.changed {
        let organization_id = result.organization_id.key.raw_identity()?;
        wasmcloud_utils::transport_routes::OrganizationTopologyWatchRoute::delivery(
            &wasmcloud_utils::transport_routes::OrganizationScope::try_from(organization_id)?,
        )
        .publish(OrganizationTopologyChanged::HostAdvertised(Box::new(
            host.clone(),
        )))
        .await?;
    }

    Ok(RegisterServiceHostResponse::Success(Box::new(host)))
}
