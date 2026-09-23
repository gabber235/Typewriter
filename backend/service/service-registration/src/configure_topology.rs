//! Applies complete desired host execution configurations.
//!
//! The organization topology owner sends a configuration with the host's current `revision`.
//! The transaction validates the host and assignments, changes desired resources atomically, and
//! increments `topology_revision.desired` whenever the configuration is accepted. The returned
//! change is published to both organization topology watchers and the host execution watcher.
//! Runtime activation is separate and arrives through `host_execution::handle_report`.

use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{
        RecordId, TransactionOutcome,
        topology::{
            EngineInstanceViewRecord, EngineTargetRecord, RealmInstanceViewRecord,
            ServiceHostRecord,
        },
        transaction_query,
    },
    decode_skir, extract_params,
    skir::base::service::v1::topology::{
        ConfigureServiceHostRequest, ConfigureServiceHostResponse,
        ConfigureServiceHostResponse_ConflictError,
        ConfigureServiceHostResponse_IncompatibleEngineError,
        ConfigureServiceHostResponse_InvalidConfigurationError,
        ConfigureServiceHostResponse_InvalidOperationIdError,
        ConfigureServiceHostResponse_OperationIdentityReusedError,
        ConfigureServiceHostResponse_RealmNotFoundError, EngineRealmSelection, EngineTarget,
        HostConfigurationChange, WatchHostExecutionResponse, WatchHostExecutionResponse_Desired,
        WatchOrganizationTopologyResponse,
    },
    skir_transaction_outcome, skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum ConfigureTopologyOutcome {
    Configured {
        host: ServiceHostRecord,
        realm: Option<RealmInstanceViewRecord>,
        engine: Option<EngineInstanceViewRecord>,
        removed_realm: Option<RecordId>,
        removed_engine: Option<RecordId>,
    },
    ConflictError {
        host: ServiceHostRecord,
        realm: Option<RealmInstanceViewRecord>,
        engine: Option<EngineInstanceViewRecord>,
    },
    InvalidConfigurationError {
        message: String,
    },
    IncompatibleEngineError {
        target: EngineTargetRecord,
    },
    RealmNotFoundError {
        realm_id: RecordId,
    },
}

#[tracing::instrument(skip(msg, params))]
/// Validates and persists one complete host execution configuration.
///
/// `expected_revision` protects concurrent host edits. `operation_id` makes a retried command
/// replayable through the database mutation receipt. A successful response describes desired
/// resources, not runtime readiness. Invalid assignments and stale revisions return domain
/// responses without publishing a topology change.
pub async fn handle_configure(
    msg: NatsMessage,
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

    wasmcloud_utils::validate_record_ids!(
        ConfigureServiceHostResponse,
        request.host_id,
        "service_host"
    );
    let realm_target = request
        .execution
        .realm
        .as_ref()
        .map(|realm| &realm.primary_engine);
    if let Some(target) = realm_target
        && !valid_target(target)
    {
        return Ok(invalid_configuration("Realm target is invalid"));
    }
    let engine_target = request
        .execution
        .primary_engine
        .as_ref()
        .map(|engine| &engine.target);
    if let Some(target) = engine_target
        && !valid_target(target)
    {
        return Ok(invalid_configuration("Engine target is invalid"));
    }

    let existing_realm_id = match request
        .execution
        .primary_engine
        .as_ref()
        .map(|engine| &engine.realm)
    {
        Some(EngineRealmSelection::HostedRealm) | None => None,
        Some(EngineRealmSelection::ExistingRealm(selection)) => {
            wasmcloud_utils::validate_record_ids!(
                ConfigureServiceHostResponse,
                selection.realm_id,
                "realm_instance"
            );
            Some(RecordId::from(&selection.realm_id))
        }
        Some(EngineRealmSelection::Unknown(_)) => {
            return Ok(invalid_configuration("Engine Realm selection is unknown"));
        }
    };
    let uses_hosted_realm = matches!(
        request
            .execution
            .primary_engine
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
    if request.operation_id.is_empty() {
        return Ok(skir_variant!(
            ConfigureServiceHostResponse::InvalidOperationIdError
        ));
    }
    let receipt = wasmcloud_utils::database::mutation::receipt_id(
        actor_id,
        org_id,
        "topology.configure",
        &request.operation_id,
    );
    let outcome = transaction_query!(
        ConfigureTopologyOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $previous = fn::mutation::recall($receipt, $request_bytes);
            IF $previous != NONE { RETURN $previous };
            LET $hosts = SELECT * FROM $host_id
                WHERE service_id.organization = $organization_id;
            IF array::is_empty($hosts) {
                RETURN {
                    outcome: 'invalid-configuration-error',
                    message: 'Host was not found in this organization',
                }
            };
            LET $host = array::first($hosts);
            IF $host.revision != $expected_revision {
                RETURN {
                    outcome: 'conflict-error',
                    host: $host,
                    realm: array::first(
                        (SELECT * FROM realm_instance
                            WHERE owner_host_id = $host_id)
                            .map(|$row| fn::service::realm_view($row))
                    ),
                    engine: array::first(
                        (SELECT * FROM engine_instance
                            WHERE owner_host_id = $host_id)
                            .map(|$row| fn::service::engine_view($row))
                    ),
                }
            };
            IF $has_realm AND !$host.can_host_realm {
                RETURN {
                    outcome: 'invalid-configuration-error',
                    message: 'Host cannot run a Realm',
                }
            };
            IF $has_engine AND !array::any(
                $host.supported_engines,
                |$supported| $supported.engine_id = $engine_target.engine_id,
            ) {
                RETURN { outcome: 'incompatible-engine-error', target: $engine_target }
            };

            LET $current_realm = array::first(SELECT * FROM realm_instance WHERE owner_host_id = $host_id);
            LET $current_engine = array::first(SELECT * FROM engine_instance WHERE owner_host_id = $host_id);

            LET $external_realm = IF $has_engine AND !$uses_hosted_realm {
                array::first(
                    SELECT * FROM $existing_realm_id
                    WHERE owner_host_id.service_id.organization = $organization_id
                )
            } ELSE {
                NONE
            };
            IF $has_engine AND !$uses_hosted_realm AND $external_realm = NONE {
                RETURN { outcome: 'realm-not-found-error', realm_id: $existing_realm_id }
            };
            LET $assigned_target = IF $uses_hosted_realm { $realm_target } ELSE { $external_realm.target_engine };
            IF $has_engine AND $assigned_target != $engine_target {
                RETURN { outcome: 'incompatible-engine-error', target: $engine_target }
            };
            IF !$has_realm AND $current_realm != NONE {
                LET $dependents = SELECT id FROM engine_instance
                    WHERE realm_id = $current_realm.id
                    AND (id != $current_engine.id OR ($has_engine AND $existing_realm_id = $current_realm.id));
                IF !array::is_empty($dependents) {
                    RETURN {
                        outcome: 'invalid-configuration-error',
                        message: 'Realm is still assigned to an execution engine',
                    }
                };
            };

            LET $realm = IF $has_realm {
                IF $current_realm = NONE {
                    CREATE ONLY realm_instance SET
                        owner_host_id = $host_id,
                        target_engine = $realm_target
                } ELSE IF $current_realm.target_engine != $realm_target {
                    UPDATE ONLY $current_realm.id SET
                        target_engine = $realm_target,
                        revision += 1,
                        state = { status: 'STAGING', updated_at: time::now() }
                } ELSE {
                    $current_realm
                }
            } ELSE {
                NONE
            };

            LET $assigned_realm = IF $uses_hosted_realm { $realm } ELSE { $external_realm };

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
                DELETE $removed_realm
            };

            LET $updated_host = UPDATE ONLY $host_id SET
                revision += 1,
                topology_revision.desired += 1,
                state = { status: 'RECONCILING', updated_at: time::now() }
            RETURN AFTER;

            LET $result = {
                outcome: 'configured',
                host: $updated_host,
                realm: array::first(
                    (SELECT * FROM realm_instance
                        WHERE owner_host_id = $host_id)
                        .map(|$row| fn::service::realm_view($row))
                ),
                engine: array::first(
                    (SELECT * FROM engine_instance
                        WHERE owner_host_id = $host_id)
                        .map(|$row| fn::service::engine_view($row))
                ),
                removed_realm: $removed_realm,
                removed_engine: $removed_engine,
            };
            RETURN fn::mutation::commit($receipt, $request_bytes, $result);
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("host_id", host_id)
    .bind("organization_id", organization_id)
    .bind("expected_revision", request.expected_revision)
    .bind("has_realm", request.execution.realm.is_some())
    .bind("realm_target", realm_target.map(EngineTargetRecord::from))
    .bind("has_engine", request.execution.primary_engine.is_some())
    .bind("engine_target", engine_target.map(EngineTargetRecord::from))
    .bind("uses_hosted_realm", uses_hosted_realm)
    .bind("existing_realm_id", existing_realm_id)
    .bind("receipt", receipt)
    .bind("request_bytes", msg.body.clone())
    .execute()
    .await
    .error_with_slug("service-host-configure-query-failed")?
    .decode()
    .error_with_slug("service-host-configure-result-parse-failed")?;

    let outcome = match outcome {
        TransactionOutcome::Committed(outcome) => outcome,
        TransactionOutcome::Rejected(error) => wasmcloud_utils::skir_domain_result!(
            ConfigureServiceHostResponse,
            TransactionOutcome::Rejected(error),
            "operation-identity-reused-error" => {}
        ),
    };
    let change = skir_transaction_outcome!(
        ConfigureServiceHostResponse,
        outcome,
        success ConfigureTopologyOutcome::Configured {
            host,
            realm,
            engine,
            removed_realm,
            removed_engine,
        } => HostConfigurationChange {
            host: host.into(),
            realm: realm.map(Into::into),
            engine: engine.map(Into::into),
            removed_resources: [removed_engine, removed_realm]
                .into_iter().flatten().map(Into::into).collect(),
            ..Default::default()
        },
        errors {
            ConfigureTopologyOutcome::ConflictError { host, realm, engine } => {
                actual: HostConfigurationChange {
                    host: host.into(), realm: realm.map(Into::into), engine: engine.map(Into::into), removed_resources: Vec::new(), ..Default::default()
                }
            },
            ConfigureTopologyOutcome::InvalidConfigurationError { message } => {
                message
            },
            ConfigureTopologyOutcome::IncompatibleEngineError { target } => {
                target: target.into()
            },
            ConfigureTopologyOutcome::RealmNotFoundError { realm_id } => {
                realm_id: realm_id.into()
            },
        }
    );

    publish_configuration(org_id, &change).await?;
    Ok(ConfigureServiceHostResponse::Success(Box::new(change)))
}

/// Publishes the committed configuration to both topology consumers.
///
/// The organization event carries the complete change, including removed resources. The host
/// event carries only the desired assignment and its new desired topology revision, which is the
/// revision the runtime must later report.
async fn publish_configuration(
    organization_id: &str,
    change: &HostConfigurationChange,
) -> Result<(), otel_wasi::Error> {
    wasmcloud_utils::skir_subjects::organization_topology(organization_id)
        .publish(WatchOrganizationTopologyResponse::ConfigurationChanged(
            Box::new(change.clone()),
        ))
        .await?;
    wasmcloud_utils::skir_subjects::host_execution(&change.host.service_id.key.to_string())
        .publish(skir_variant!(WatchHostExecutionResponse::Desired {
            topology_revision: change.host.topology_revision.desired,
            realm: change.realm.clone(),
            engine: change.engine.clone(),
        }))
        .await
}

/// Builds the protocol error used for rejected configuration input or relationships.
fn invalid_configuration(message: impl Into<String>) -> ConfigureServiceHostResponse {
    skir_variant!(ConfigureServiceHostResponse::InvalidConfigurationError {
        message: message.into(),
    })
}

/// Checks the nonempty target fields required before the database transaction runs.
fn valid_target(target: &EngineTarget) -> bool {
    !target.version_constraint.trim().is_empty() && valid_artifact_id(&target.engine_id)
}

/// Accepts the artifact identifier grammar used by service engine targets.
fn valid_artifact_id(value: &str) -> bool {
    !value.is_empty()
        && value.split(':').all(|segment| {
            !segment.is_empty()
                && segment.chars().enumerate().all(|(index, character)| {
                    character.is_ascii_alphanumeric()
                        || (index > 0 && matches!(character, '_' | '.' | '-'))
                })
        })
}
