//! Applies complete desired host execution configurations.
//!
//! The organization topology owner sends a configuration with the host's current `revision`.
//! The transaction validates the host and assignments, changes desired resources atomically, and
//! increments `topology_revision.desired` whenever the configuration is accepted. The returned
//! change is published to both organization topology watchers and the host execution watcher.
//! Runtime activation is separate and arrives through `host_execution::handle_report`.

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
    skir::base::service::v1::topology::{
        ConfigureServiceHostRequest, ConfigureServiceHostResponse,
        ConfigureServiceHostResponse_ConflictError,
        ConfigureServiceHostResponse_IncompatibleEngineError,
        ConfigureServiceHostResponse_InvalidConfigurationError,
        ConfigureServiceHostResponse_InvalidOperationIdError,
        ConfigureServiceHostResponse_OperationIdentityReusedError,
        ConfigureServiceHostResponse_RealmNotFoundError, EngineRealmSelection,
        HostConfigurationChange, OrganizationTopologyChanged, WatchHostExecutionResponse,
        WatchHostExecutionResponse_Desired,
    },
    skir_transaction_outcome,
    skir_utils::RecordIdKeyIdentity,
    skir_variant,
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

#[tracing::instrument(skip_all)]
/// Validates and persists one complete host execution configuration.
///
/// `expected_revision` protects concurrent host edits. `operation_id` makes a retried command
/// replayable through the database mutation receipt. A successful response describes desired
/// resources, not runtime readiness. Invalid assignments and stale revisions return domain
/// responses without publishing a topology change.
pub async fn handle_configure(
    msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
    request: ConfigureServiceHostRequest,
) -> Result<ConfigureServiceHostResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
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
    if let Some(engine) = &request.execution.primary_engine
        && let EngineRealmSelection::ExistingRealm(selection) = &engine.realm
    {
        wasmcloud_utils::validate_record_ids!(
            ConfigureServiceHostResponse,
            selection.realm_id,
            "realm_instance"
        );
    }
    let desired = match crate::host_configuration_input::HostConfigurationInput::try_from(
        request.execution,
    ) {
        Ok(value) => value,
        Err(error) => return Ok(error.into_configuration_response()),
    };

    let host_id = RecordId::from(&request.host_id);
    let organization_id = RecordId::new("organization", org_id);
    if request.operation_id.is_empty() {
        return Ok(skir_variant!(
            ConfigureServiceHostResponse::InvalidOperationIdError
        ));
    }
    let receipt = wasmcloud_utils::database::mutation::MutationReceipt::new(
        actor_id,
        org_id,
        "topology.configure",
        &request.operation_id,
        msg.body,
    );
    let outcome = receipt
        .bind(
            transaction_query!(
                ConfigureTopologyOutcome,
                r#"
                BEGIN TRANSACTION;

                RETURN fn::service::configure_host(
                    $host,
                    $organization,
                    $expected_revision,
                    $desired,
                    $operation_id,
                    $receipt,
                    $request_bytes
                );

                COMMIT TRANSACTION;
                "#,
            )
            .bind("host", host_id)
            .bind("organization", organization_id)
            .bind("expected_revision", request.expected_revision)
            .bind("desired", desired)
            .bind("operation_id", &request.operation_id),
        )
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
    wasmcloud_utils::transport_routes::OrganizationTopologyWatchRoute::delivery(
        &wasmcloud_utils::transport_routes::OrganizationScope::try_from(organization_id)?,
    )
    .publish(OrganizationTopologyChanged::ConfigurationChanged(Box::new(
        change.clone(),
    )))
    .await?;
    let service_id = change.host.service_id.key.raw_identity()?;
    wasmcloud_utils::transport_routes::HostExecutionWatchRoute::delivery(
        &wasmcloud_utils::transport_routes::ServiceScope::try_from(service_id)?,
    )
    .publish(skir_variant!(WatchHostExecutionResponse::Desired {
        topology_revision: change.host.topology_revision.desired,
        realm: change.realm.clone(),
        engine: change.engine.clone(),
    }))
    .await
}
