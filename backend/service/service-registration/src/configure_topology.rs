use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{
        RecordId, TransactionOutcome,
        topology::{
            EngineInstanceRecord, EngineTargetRecord, RealmInstanceRecord, ServiceHostRecord,
        },
        transaction_query,
    },
    decode_skir, extract_params,
    skir::base::service::v1::topology::{
        ConfigureServiceHostRequest, ConfigureServiceHostResponse,
        ConfigureServiceHostResponse_ConflictError,
        ConfigureServiceHostResponse_IncompatibleEngineError,
        ConfigureServiceHostResponse_InvalidConfigurationError,
        ConfigureServiceHostResponse_RealmNotFoundError, ConfigureServiceHostResponse_Success,
        EngineRealmSelection, EngineTarget, WatchHostExecutionResponse,
        WatchHostExecutionResponse_Desired, WatchOrganizationTopologyResponse,
    },
    wasmcloud::messaging::types::BrokerMessage,
};

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum ConfigureTopologyOutcome {
    Configured {
        host: ServiceHostRecord,
        realm: Option<RealmInstanceRecord>,
        engine: Option<EngineInstanceRecord>,
        removed_realm: Option<RecordId>,
        removed_engine: Option<RecordId>,
    },
    Conflict {
        host: ServiceHostRecord,
    },
    InvalidConfiguration {
        message: String,
    },
    IncompatibleEngine {
        target: EngineTargetRecord,
    },
    RealmNotFound {
        realm_id: RecordId,
    },
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_configure(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<ConfigureServiceHostResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let request = decode_skir!(ConfigureServiceHostRequest, &msg.body)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "host.id" = request.host_id.to_string(),
        "host.expected_revision" = request.expected_revision,
    );

    if request.host_id.table != "service_host" {
        return Ok(invalid_configuration(
            "Host id must reference a service host",
        ));
    }
    let realm_target = request
        .execution
        .realm
        .as_ref()
        .map(|realm| &realm.target_engine);
    if let Some(target) = realm_target
        && !valid_target(target)
    {
        return Ok(invalid_configuration("Realm target is invalid"));
    }
    let engine_target = request
        .execution
        .engine
        .as_ref()
        .map(|engine| &engine.target);
    if let Some(target) = engine_target
        && !valid_target(target)
    {
        return Ok(invalid_configuration("Engine target is invalid"));
    }

    let existing_realm_id = match request
        .execution
        .engine
        .as_ref()
        .map(|engine| &engine.realm)
    {
        Some(EngineRealmSelection::HostedRealm) | None => None,
        Some(EngineRealmSelection::ExistingRealm(selection)) => {
            if selection.realm_id.table != "realm_instance" {
                return Ok(invalid_configuration(
                    "Realm id must reference a Realm instance",
                ));
            }
            Some(RecordId::from(&selection.realm_id))
        }
        Some(EngineRealmSelection::Unknown(_)) => {
            return Ok(invalid_configuration("Engine Realm selection is unknown"));
        }
    };
    let uses_hosted_realm = matches!(
        request
            .execution
            .engine
            .as_ref()
            .map(|engine| &engine.realm),
        Some(EngineRealmSelection::HostedRealm)
    );
    if uses_hosted_realm && request.execution.realm.is_none() {
        return Ok(invalid_configuration(
            "A hosted engine requires a hosted Realm configuration",
        ));
    }

    let host_id = RecordId::from(&request.host_id);
    let organization_id = RecordId::new("organization", org_id);
    let outcome = transaction_query!(
        ConfigureTopologyOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $hosts = SELECT * FROM $host_id
                WHERE service_id.organization = $organization_id;
            IF array::is_empty($hosts) {
                RETURN {
                    outcome: 'invalid-configuration',
                    message: 'Host was not found in this organization',
                }
            };
            LET $host = array::first($hosts);
            IF $host.revision != $expected_revision {
                RETURN { outcome: 'conflict', host: $host }
            };
            IF $has_realm AND !$host.can_host_realm {
                RETURN {
                    outcome: 'invalid-configuration',
                    message: 'Host cannot run a Realm',
                }
            };
            IF $has_engine AND $host.entrypoint != 'PAPER' {
                RETURN {
                    outcome: 'invalid-configuration',
                    message: 'Only Paper hosts can run an execution engine',
                }
            };
            IF $has_realm AND !array::any(
                $host.supported_engines,
                |$supported| $supported.engine_id = $realm_target.engine_id
                    AND $realm_target.major_version IN $supported.supported_major_versions,
            ) {
                RETURN { outcome: 'incompatible-engine', target: $realm_target }
            };
            IF $has_engine AND !array::any(
                $host.supported_engines,
                |$supported| $supported.engine_id = $engine_target.engine_id
                    AND $engine_target.major_version IN $supported.supported_major_versions,
            ) {
                RETURN { outcome: 'incompatible-engine', target: $engine_target }
            };

            LET $current_realm = array::first(SELECT * FROM realm_instance WHERE owner_host_id = $host_id);
            LET $current_engine = array::first(SELECT * FROM engine_instance WHERE owner_host_id = $host_id);

            LET $realm = IF $has_realm {
                IF $current_realm = NONE {
                    CREATE ONLY realm_instance SET
                        owner_host_id = $host_id,
                        target_engine = $realm_target
                } ELSE IF $current_realm.target_engine != $realm_target {
                    UPDATE ONLY $current_realm.id SET
                        target_engine = $realm_target,
                        revision += 1,
                        desired_manifest_revision += 1,
                        state = { status: 'STAGING', updated_at: time::now() }
                } ELSE {
                    $current_realm
                }
            } ELSE {
                NONE
            };

            LET $external_realm = IF $has_engine AND !$uses_hosted_realm {
                array::first(
                    SELECT * FROM $existing_realm_id
                    WHERE owner_host_id.service_id.organization = $organization_id
                )
            } ELSE {
                NONE
            };
            IF $has_engine AND !$uses_hosted_realm AND $external_realm = NONE {
                RETURN { outcome: 'realm-not-found', realm_id: $existing_realm_id }
            };
            LET $assigned_realm = IF $uses_hosted_realm { $realm } ELSE { $external_realm };
            IF $has_engine AND $assigned_realm.target_engine != $engine_target {
                RETURN { outcome: 'incompatible-engine', target: $engine_target }
            };

            LET $engine = IF $has_engine {
                IF $current_engine = NONE {
                    CREATE ONLY engine_instance SET
                        owner_host_id = $host_id,
                        realm_id = $assigned_realm.id,
                        target = $engine_target
                } ELSE IF $current_engine.target != $engine_target
                    OR $current_engine.realm_id != $assigned_realm.id {
                    UPDATE ONLY $current_engine.id SET
                        realm_id = $assigned_realm.id,
                        target = $engine_target,
                        revision += 1,
                        desired_manifest_revision += 1,
                        state = { status: 'STAGING', updated_at: time::now() }
                } ELSE {
                    $current_engine
                }
            } ELSE {
                NONE
            };

            LET $removed_engine = IF !$has_engine AND $current_engine != NONE {
                $current_engine.id
            } ELSE {
                NONE
            };
            IF $removed_engine != NONE {
                DELETE $removed_engine
            };

            LET $removed_realm = IF !$has_realm AND $current_realm != NONE {
                $current_realm.id
            } ELSE {
                NONE
            };
            IF $removed_realm != NONE {
                LET $dependents = SELECT id FROM engine_instance WHERE realm_id = $removed_realm;
                IF !array::is_empty($dependents) {
                    RETURN {
                        outcome: 'invalid-configuration',
                        message: 'Realm is still assigned to an execution engine',
                    }
                };
                DELETE $removed_realm
            };

            LET $updated_host = UPDATE ONLY $host_id SET
                revision += 1,
                desired_topology_revision += 1,
                state = { status: 'RECONCILING', updated_at: time::now() }
            RETURN AFTER;

            RETURN {
                outcome: 'configured',
                host: $updated_host,
                realm: IF $has_realm { $realm } ELSE { NONE },
                engine: IF $has_engine { $engine } ELSE { NONE },
                removed_realm: $removed_realm,
                removed_engine: $removed_engine,
            };
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("host_id", host_id)
    .bind("organization_id", organization_id)
    .bind("expected_revision", request.expected_revision)
    .bind("has_realm", request.execution.realm.is_some())
    .bind("realm_target", realm_target.map(EngineTargetRecord::from))
    .bind("has_engine", request.execution.engine.is_some())
    .bind("engine_target", engine_target.map(EngineTargetRecord::from))
    .bind("uses_hosted_realm", uses_hosted_realm)
    .bind("existing_realm_id", existing_realm_id)
    .execute()
    .await
    .error_with_slug("service-host-configure-query-failed")?
    .decode()
    .error_with_slug("service-host-configure-result-parse-failed")?;

    let outcome = match outcome {
        TransactionOutcome::Committed(outcome) => outcome,
        TransactionOutcome::Rejected(error) => wasmcloud_utils::skir_domain_result!(
            ConfigureServiceHostResponse,
            TransactionOutcome::Rejected(error)
        ),
    };
    publish_configuration(org_id, &outcome).await?;
    map_outcome(outcome)
}

async fn publish_configuration(
    organization_id: &str,
    outcome: &ConfigureTopologyOutcome,
) -> Result<(), otel_wasi::Error> {
    let ConfigureTopologyOutcome::Configured {
        host,
        realm,
        engine,
        removed_realm,
        removed_engine,
    } = outcome
    else {
        return Ok(());
    };
    let host = wasmcloud_utils::skir::base::service::v1::topology::ServiceHost::from(host.clone());
    let realm: Option<wasmcloud_utils::skir::base::service::v1::topology::RealmInstance> =
        realm.clone().map(Into::into);
    let engine: Option<wasmcloud_utils::skir::base::service::v1::topology::EngineInstance> =
        engine.clone().map(Into::into);
    let topology = wasmcloud_utils::skir_subjects::organization_topology(organization_id);
    topology
        .publish(WatchOrganizationTopologyResponse::HostUpdated(Box::new(
            host.clone(),
        )))
        .await?;
    if let Some(realm) = &realm {
        topology
            .publish(WatchOrganizationTopologyResponse::RealmUpdated(Box::new(
                realm.clone(),
            )))
            .await?;
    }
    if let Some(engine) = &engine {
        topology
            .publish(WatchOrganizationTopologyResponse::EngineUpdated(Box::new(
                engine.clone(),
            )))
            .await?;
    }
    for removed in [removed_engine, removed_realm].into_iter().flatten() {
        topology
            .publish(WatchOrganizationTopologyResponse::ResourceRemoved(
                Box::new(removed.clone().into()),
            ))
            .await?;
    }
    wasmcloud_utils::skir_subjects::host_execution(&host.service_id.key.to_string())
        .publish(WatchHostExecutionResponse::Desired(Box::new(
            WatchHostExecutionResponse_Desired {
                topology_revision: host.desired_topology_revision,
                realm,
                engine,
                _unrecognized: None,
            },
        )))
        .await
}

fn map_outcome(
    outcome: ConfigureTopologyOutcome,
) -> Result<ConfigureServiceHostResponse, otel_wasi::Error> {
    Ok(match outcome {
        ConfigureTopologyOutcome::Configured {
            host,
            realm,
            engine,
            removed_realm: _,
            removed_engine: _,
        } => {
            ConfigureServiceHostResponse::Success(Box::new(ConfigureServiceHostResponse_Success {
                host: host.into(),
                realm: realm.map(Into::into),
                engine: engine.map(Into::into),
                _unrecognized: None,
            }))
        }
        ConfigureTopologyOutcome::Conflict { host } => ConfigureServiceHostResponse::ConflictError(
            Box::new(ConfigureServiceHostResponse_ConflictError {
                actual: host.into(),
                _unrecognized: None,
            }),
        ),
        ConfigureTopologyOutcome::InvalidConfiguration { message } => {
            invalid_configuration(message)
        }
        ConfigureTopologyOutcome::IncompatibleEngine { target } => {
            ConfigureServiceHostResponse::IncompatibleEngineError(Box::new(
                ConfigureServiceHostResponse_IncompatibleEngineError {
                    target: target.into(),
                    _unrecognized: None,
                },
            ))
        }
        ConfigureTopologyOutcome::RealmNotFound { realm_id } => {
            ConfigureServiceHostResponse::RealmNotFoundError(Box::new(
                ConfigureServiceHostResponse_RealmNotFoundError {
                    realm_id: realm_id.into(),
                    _unrecognized: None,
                },
            ))
        }
    })
}

fn invalid_configuration(message: impl Into<String>) -> ConfigureServiceHostResponse {
    ConfigureServiceHostResponse::InvalidConfigurationError(Box::new(
        ConfigureServiceHostResponse_InvalidConfigurationError {
            message: message.into(),
            _unrecognized: None,
        },
    ))
}

fn valid_target(target: &EngineTarget) -> bool {
    target.major_version >= 1
        && target.engine_id.len() >= 3
        && target.engine_id.split('_').all(|part| {
            !part.is_empty()
                && part
                    .chars()
                    .all(|character| character.is_ascii_lowercase() || character.is_ascii_digit())
        })
}
