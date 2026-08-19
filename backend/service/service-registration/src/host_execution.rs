use std::collections::HashMap;

use otel_wasi::{ResultWithSlug, wasi_error};
use serde::Deserialize;
use wasmcloud_utils::{
    database::{
        RecordId, TransactionOutcome, read_query,
        topology::{
            ChildRuntimeStateRecord, EngineInstanceRecord, RealmInstanceRecord, ServiceHostRecord,
        },
        transaction_query,
    },
    decode_skir, extract_params,
    skir::base::service::v1::topology::{
        ReportHostExecutionRequest, ReportHostExecutionResponse,
        ReportHostExecutionResponse_StaleRevisionError, ReportHostExecutionResponse_Success,
        WatchHostExecutionRequest, WatchHostExecutionResponse, WatchHostExecutionResponse_Desired,
    },
    wasmcloud::messaging::types::BrokerMessage,
};

#[derive(Debug, Deserialize)]
struct DesiredExecutionRecord {
    host: Option<ServiceHostRecord>,
    realm: Option<RealmInstanceRecord>,
    engine: Option<EngineInstanceRecord>,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum ReportExecutionOutcome {
    Updated {
        organization_id: RecordId,
        host: ServiceHostRecord,
        realm: Option<RealmInstanceRecord>,
        engine: Option<EngineInstanceRecord>,
    },
    StaleRevision,
    HostNotFound,
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchHostExecutionResponse, otel_wasi::Error> {
    let service_id = extract_params!(params, service_id)?;
    let request = decode_skir!(WatchHostExecutionRequest, &msg.body)?;
    if request.host_id.table != "service_host" {
        return Err(wasi_error!(
            "host-id-invalid",
            "host id must reference a service host"
        ));
    }
    let host_id = RecordId::from(&request.host_id);
    let service_id = RecordId::new("service", service_id);
    let desired = read_query!(
        r#"
        RETURN {
            host: array::first((SELECT * FROM $host_id WHERE service_id = $service_id)),
            realm: array::first((SELECT * FROM realm_instance WHERE owner_host_id = $host_id)),
            engine: array::first((SELECT * FROM engine_instance WHERE owner_host_id = $host_id)),
        };
        "#,
    )
    .bind("host_id", host_id)
    .bind("service_id", service_id)
    .execute()
    .await
    .error_with_slug("host-execution-watch-query-failed")?
    .parse::<DesiredExecutionRecord>()
    .error_with_slug("host-execution-watch-result-parse-failed")?;
    let Some(host) = desired.host else {
        return Err(wasi_error!(
            "host-not-found",
            "host was not found for service"
        ));
    };
    Ok(WatchHostExecutionResponse::Desired(Box::new(
        WatchHostExecutionResponse_Desired {
            topology_revision: host.desired_topology_revision,
            realm: desired.realm.map(Into::into),
            engine: desired.engine.map(Into::into),
            _unrecognized: None,
        },
    )))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_report(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<ReportHostExecutionResponse, otel_wasi::Error> {
    let service_id = extract_params!(params, service_id)?;
    let request = decode_skir!(ReportHostExecutionRequest, &msg.body)?;
    if request.host_id.table != "service_host" {
        return Err(wasi_error!(
            "host-id-invalid",
            "host id must reference a service host"
        ));
    }
    let realm_state = request
        .realm_state
        .as_ref()
        .map(ChildRuntimeStateRecord::try_from)
        .transpose()
        .map_err(|()| wasi_error!("realm-state-invalid", "Realm state is invalid"))?;
    let engine_state = request
        .engine_state
        .as_ref()
        .map(ChildRuntimeStateRecord::try_from)
        .transpose()
        .map_err(|()| wasi_error!("engine-state-invalid", "engine state is invalid"))?;
    let outcome = transaction_query!(
        ReportExecutionOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $hosts = SELECT * FROM $host_id WHERE service_id = $service_id;
            IF array::is_empty($hosts) {
                RETURN { outcome: 'host-not-found' }
            };
            LET $host = array::first($hosts);
            IF $host.desired_topology_revision != $topology_revision {
                RETURN { outcome: 'stale-revision' }
            };
            LET $realm = array::first(SELECT * FROM realm_instance WHERE owner_host_id = $host_id);
            LET $engine = array::first(SELECT * FROM engine_instance WHERE owner_host_id = $host_id);
            IF $realm_state != NONE AND $realm_state != NULL {
                UPDATE realm_instance SET
                    state = {
                        status: $realm_state.status,
                        active_artifact_version: IF $realm_state.active_artifact_version = NULL {
                            NONE
                        } ELSE {
                            $realm_state.active_artifact_version
                        },
                        message: IF $realm_state.message = NULL {
                            NONE
                        } ELSE {
                            $realm_state.message
                        },
                        updated_at: <datetime>$realm_state.updated_at,
                    },
                    applied_manifest_revision = IF $realm_state.status = 'ACTIVE' {
                        desired_manifest_revision
                    } ELSE {
                        applied_manifest_revision
                    }
                WHERE owner_host_id = $host_id
            };
            IF $engine_state != NONE AND $engine_state != NULL {
                UPDATE engine_instance SET
                    state = {
                        status: $engine_state.status,
                        active_artifact_version: IF $engine_state.active_artifact_version = NULL {
                            NONE
                        } ELSE {
                            $engine_state.active_artifact_version
                        },
                        message: IF $engine_state.message = NULL {
                            NONE
                        } ELSE {
                            $engine_state.message
                        },
                        updated_at: <datetime>$engine_state.updated_at,
                    },
                    applied_manifest_revision = IF $engine_state.status = 'ACTIVE' {
                        desired_manifest_revision
                    } ELSE {
                        applied_manifest_revision
                    }
                WHERE owner_host_id = $host_id
            };
            LET $complete = (
                $realm = NONE
                OR ($realm_state != NONE AND $realm_state != NULL AND $realm_state.status = 'ACTIVE')
            ) AND (
                $engine = NONE
                OR ($engine_state != NONE AND $engine_state != NULL AND $engine_state.status = 'ACTIVE')
            );
            LET $failed = (
                $realm_state != NONE AND $realm_state != NULL AND $realm_state.status = 'FAILED'
            ) OR (
                $engine_state != NONE AND $engine_state != NULL AND $engine_state.status = 'FAILED'
            );
            LET $drifted = (
                $realm_state != NONE
                AND $realm_state != NULL
                AND $realm_state.status IN ['ROLLED_BACK', 'DRIFTED']
            ) OR (
                $engine_state != NONE
                AND $engine_state != NULL
                AND $engine_state.status IN ['ROLLED_BACK', 'DRIFTED']
            );
            LET $host_status = IF $complete {
                'ACTIVE'
            } ELSE IF $failed {
                'FAILED'
            } ELSE IF $drifted {
                'DRIFTED'
            } ELSE {
                'RECONCILING'
            };
            LET $updated_host = UPDATE ONLY $host_id SET
                applied_topology_revision = IF $complete {
                    $topology_revision
                } ELSE {
                    applied_topology_revision
                },
                state = { status: $host_status, updated_at: time::now() }
            RETURN AFTER;
            RETURN {
                outcome: 'updated',
                organization_id: $host.service_id.organization,
                host: $updated_host,
                realm: array::first(SELECT * FROM realm_instance WHERE owner_host_id = $host_id),
                engine: array::first(SELECT * FROM engine_instance WHERE owner_host_id = $host_id),
            };
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("host_id", RecordId::from(&request.host_id))
    .bind("service_id", RecordId::new("service", service_id))
    .bind("topology_revision", request.topology_revision)
    .bind("realm_state", realm_state)
    .bind("engine_state", engine_state)
    .execute()
    .await
    .error_with_slug("host-execution-report-query-failed")?
    .decode()
    .map_err(|error| {
        wasi_error!(
            "host-execution-report-result-parse-failed",
            "host execution report result could not be decoded: {error:?}"
        )
    })?;
    let outcome = match outcome {
        TransactionOutcome::Committed(outcome) => outcome,
        TransactionOutcome::Rejected(error) => wasmcloud_utils::skir_domain_result!(
            ReportHostExecutionResponse,
            TransactionOutcome::Rejected(error)
        ),
    };
    Ok(match outcome {
        ReportExecutionOutcome::Updated {
            organization_id,
            host,
            realm,
            engine,
        } => {
            publish_report(&organization_id, &host, realm.as_ref(), engine.as_ref()).await?;
            ReportHostExecutionResponse::Success(Box::new(ReportHostExecutionResponse_Success {
                _unrecognized: None,
            }))
        }
        ReportExecutionOutcome::StaleRevision => ReportHostExecutionResponse::StaleRevisionError(
            Box::new(ReportHostExecutionResponse_StaleRevisionError {
                _unrecognized: None,
            }),
        ),
        ReportExecutionOutcome::HostNotFound => {
            return Err(wasi_error!(
                "host-not-found",
                "host was not found for service"
            ));
        }
    })
}

async fn publish_report(
    organization_id: &RecordId,
    host: &ServiceHostRecord,
    realm: Option<&RealmInstanceRecord>,
    engine: Option<&EngineInstanceRecord>,
) -> Result<(), otel_wasi::Error> {
    let topology =
        wasmcloud_utils::skir_subjects::organization_topology(&organization_id.key.to_string());
    topology
        .publish(
            wasmcloud_utils::skir::base::service::v1::topology::WatchOrganizationTopologyResponse::HostUpdated(
                Box::new(host.clone().into()),
            ),
        )
        .await?;
    if let Some(realm) = realm {
        topology
            .publish(
                wasmcloud_utils::skir::base::service::v1::topology::WatchOrganizationTopologyResponse::RealmUpdated(
                    Box::new(realm.clone().into()),
                ),
            )
            .await?;
    }
    if let Some(engine) = engine {
        topology
            .publish(
                wasmcloud_utils::skir::base::service::v1::topology::WatchOrganizationTopologyResponse::EngineUpdated(
                    Box::new(engine.clone().into()),
                ),
            )
            .await?;
    }
    Ok(())
}
