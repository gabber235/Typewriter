use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{
        RecordId, TransactionOutcome,
        topology::{ServiceHostRecord, SupportedEngineRecord},
        transaction_query,
    },
    decode_skir, extract_params,
    skir::base::service::v1::topology::{
        RegisterServiceHostRequest, RegisterServiceHostResponse, WatchOrganizationTopologyResponse,
    },
    wasmcloud::messaging::types::BrokerMessage,
};

#[derive(Debug, Deserialize)]
struct RegisterHostResult {
    host: ServiceHostRecord,
    organization_id: RecordId,
    changed: bool,
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<RegisterServiceHostResponse, otel_wasi::Error> {
    let service_id = extract_params!(params, service_id)?;
    let request = decode_skir!(RegisterServiceHostRequest, &msg.body)?;
    otel_wasi::main_attribute!(
        "service.id" = service_id.to_string(),
        "host.entrypoint" = request.entrypoint.clone(),
        "host.can_host_realm" = request.can_host_realm,
        "host.supported_engine_count" = request.supported_engines.len() as i64,
    );

    let service_id = RecordId::new("service", service_id);
    let host_id = RecordId::new("service_host", service_id.key.to_string());
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
        wasmcloud_utils::skir_subjects::organization_topology(&result.organization_id.key)
            .publish(WatchOrganizationTopologyResponse::HostUpdated(Box::new(
                host.clone(),
            )))
            .await?;
    }

    Ok(RegisterServiceHostResponse::Success(Box::new(host)))
}
