//! Applies complete desired host execution configurations.
//!
//! The organization topology owner sends a batch of configurations, each with its host's current
//! `revision`, that applies all or nothing. Items that are malformed on their face (record
//! identifiers from another table, an unknown Realm selection, the same host twice) refuse the
//! batch before the database is read. The transaction then finds revision conflicts before any
//! item applies; a conflict depends only on its own host, because configuring one host never
//! changes another host's revision. Without conflicts, items apply in request order, so a later
//! item sees the Realms an earlier one created or removed. Any refused item throws, which rolls
//! back every earlier item; the thrown message is a JSON list of the refused items, because a
//! rolled back transaction returns no statement result. Each accepted configuration increments
//! its host's `topology_revision.desired`, and every resulting change is published to both
//! organization topology watchers and the host execution watcher after commit. Runtime
//! activation is separate and arrives through `host_execution::handle_report`.

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    database::{
        RecordId, TransactionOutcome,
        topology::{EngineInstanceViewRecord, RealmInstanceViewRecord, ServiceHostRecord},
        transaction_query,
    },
    skir::base::{
        kernel::v1::errors::InvalidRecordIdError,
        service::v1::topology::{
            ConfigureServiceHostsRequest, ConfigureServiceHostsResponse, EngineRealmSelection,
            HostConfigurationChange, HostConfigurationEdit, HostConfigurationRefusal,
            HostConfigurationRefusal_ConflictError, HostConfigurationRefusal_DuplicateError,
            HostConfigurationRefusal_IncompatibleEngineError,
            HostConfigurationRefusal_InvalidConfigurationError,
            HostConfigurationRefusal_RealmNotFoundError, OrganizationTopologyChanged,
            RefusedHostConfiguration, WatchHostExecutionResponse,
            WatchHostExecutionResponse_Desired,
        },
    },
    skir_utils::{RecordIdKeyIdentity, RecordIdTableInput},
    skir_variant,
};

use crate::host_configuration_input::HostConfigurationInput;

/// One configuration as the transaction reads it; `index` is its position in the request.
#[derive(Serialize)]
struct ConfigurationInput {
    index: usize,
    host: RecordId,
    expected_revision: i64,
    desired: HostConfigurationInput,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum ConfigureBatchOutcome {
    /// Every item applied; `changes` holds them in request order.
    Configured { changes: Vec<ConfiguredHost> },
    /// Some items' revisions are stale; nothing was written.
    Conflicted { conflicts: Vec<ConflictedHost> },
}

#[derive(Debug, Deserialize)]
struct ConfiguredHost {
    host: ServiceHostRecord,
    realm: Option<RealmInstanceViewRecord>,
    engine: Option<EngineInstanceViewRecord>,
    removed_realm: Option<RecordId>,
    removed_engine: Option<RecordId>,
}

#[derive(Debug, Deserialize)]
struct ConflictedHost {
    index: usize,
    host: ServiceHostRecord,
    realm: Option<RealmInstanceViewRecord>,
    engine: Option<EngineInstanceViewRecord>,
}

/// One item that kept an applying batch from committing, as the rolled back transaction
/// threw it. The payloads of these refusals come from the request item.
#[derive(Debug, Deserialize)]
struct RefusedApplication {
    index: usize,
    outcome: String,
    message: Option<String>,
}

#[tracing::instrument(skip_all)]
/// Validates and persists complete host execution configurations as one batch.
///
/// Each `expected_revision` protects concurrent host edits. A successful response describes
/// desired resources, not runtime readiness, for every item in request order. A refused batch
/// lists each refused item with its reason and publishes nothing. A stale item whose assignment
/// is already stored, as when a resend follows a send that landed, succeeds with the stored state
/// and publishes it again, so a resend delivers a change whose first publish failed.
pub async fn handle_configure(
    scope: wasmcloud_utils::transport::OrganizationActorScope,
    request: ConfigureServiceHostsRequest,
) -> Result<ConfigureServiceHostsResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "host.batch_size" = request.configurations.len() as i64,
    );

    let edits = request.configurations;
    let mut inputs = Vec::with_capacity(edits.len());
    let mut malformed = Vec::new();
    let hosts = edits.iter().map(|edit| &edit.host_id).collect::<Vec<_>>();
    for (index, edit) in edits.iter().enumerate() {
        match configuration_input(&hosts, index, edit) {
            Ok(input) => inputs.push(input),
            Err(reason) => malformed.push(refused(edit, reason)),
        }
    }
    if !malformed.is_empty() {
        otel_wasi::main_attribute!("host.outcome" = "malformed");
        return Ok(ConfigureServiceHostsResponse::RefusedError(malformed));
    }

    let outcome = configure_in_transaction(inputs, org_id).await?;
    let changes = match outcome {
        TransactionOutcome::Committed(ConfigureBatchOutcome::Configured { changes }) => changes
            .into_iter()
            .map(ConfiguredHost::into_change)
            .collect::<Vec<_>>(),
        TransactionOutcome::Committed(ConfigureBatchOutcome::Conflicted { conflicts }) => {
            otel_wasi::main_attribute!("host.outcome" = "conflicted");
            return Ok(ConfigureServiceHostsResponse::RefusedError(
                conflicts
                    .into_iter()
                    .map(|conflict| {
                        let edit = item(&edits, conflict.index)?;
                        Ok(refused(edit, conflict.into_refusal()))
                    })
                    .collect::<Result<Vec<_>, otel_wasi::Error>>()?,
            ));
        }
        TransactionOutcome::Rejected(error) => {
            otel_wasi::main_attribute!("host.outcome" = "refused");
            let refusals: Vec<RefusedApplication> =
                serde_json::from_str(wasmcloud_utils::database_domain_slug(error.message()))
                    .error_with_slug("service-host-configure-refusal-parse-failed")?;
            return Ok(ConfigureServiceHostsResponse::RefusedError(
                refusals
                    .into_iter()
                    .map(|refusal| {
                        let edit = item(&edits, refusal.index)?;
                        Ok(refused(edit, refusal.into_refusal(edit)?))
                    })
                    .collect::<Result<Vec<_>, otel_wasi::Error>>()?,
            ));
        }
    };
    otel_wasi::main_attribute!("host.outcome" = "configured");

    for change in &changes {
        publish_configuration(org_id, change).await?;
    }
    Ok(ConfigureServiceHostsResponse::Success(changes))
}

/// Finds every conflict before any item applies, then applies each item in request order and
/// rolls back when any item is refused.
async fn configure_in_transaction(
    inputs: Vec<ConfigurationInput>,
    org_id: &str,
) -> Result<TransactionOutcome<ConfigureBatchOutcome>, otel_wasi::Error> {
    let organization_id = RecordId::new("organization", org_id);
    transaction_query!(
        ConfigureBatchOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            -- A conflict depends only on its own host, so every conflict is found before
            -- any item writes. A stale item whose assignment is stored is no conflict.
            LET $conflicts = $configurations.map(|$item| {
                LET $host = array::first(
                    SELECT revision FROM $item.host
                    WHERE service_id.organization = $organization
                );
                IF $host = NONE OR $host.revision = $item.expected_revision {
                    RETURN NONE
                };
                LET $checked = fn::service::configure_host(
                    $item.host,
                    $organization,
                    $item.expected_revision,
                    $item.desired
                );
                RETURN IF $checked.outcome = 'conflict-error' {
                    {
                        index: $item.index,
                        host: $checked.host,
                        realm: $checked.realm,
                        engine: $checked.engine,
                    }
                } ELSE {
                    NONE
                };
            }).filter(|$conflict| $conflict != NONE);
            IF !array::is_empty($conflicts) {
                RETURN { outcome: 'conflicted', conflicts: $conflicts }
            };

            LET $applied = $configurations.map(|$item| {
                LET $result = fn::service::configure_host(
                    $item.host,
                    $organization,
                    $item.expected_revision,
                    $item.desired
                );
                RETURN { index: $item.index, result: $result };
            });
            LET $refused = $applied
                .filter(|$item| $item.result.outcome != 'configured')
                .map(|$item| {
                    RETURN {
                        index: $item.index,
                        outcome: $item.result.outcome,
                        message: $item.result.message,
                    };
                });
            IF !array::is_empty($refused) {
                THROW encoding::json::encode($refused)
            };

            LET $result = {
                outcome: 'configured',
                changes: $applied.map(|$item| $item.result),
            };
            RETURN $result;
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("configurations", inputs)
    .bind("organization", organization_id)
    .execute()
    .await
    .error_with_slug("service-host-configure-query-failed")?
    .decode()
    .error_with_slug("service-host-configure-result-parse-failed")
}

/// The transaction input for one item, or the reason it is refused before the database is
/// read.
fn configuration_input(
    hosts: &[&wasmcloud_utils::skir::base::kernel::v1::record_id::RecordId],
    index: usize,
    edit: &HostConfigurationEdit,
) -> Result<ConfigurationInput, HostConfigurationRefusal> {
    invalid_record_id(edit.host_id.invalid_tables("service_host"), "service_host")?;
    if let Some(engine) = &edit.execution.primary_engine
        && let EngineRealmSelection::ExistingRealm(selection) = &engine.realm
    {
        invalid_record_id(
            selection.realm_id.invalid_tables("realm_instance"),
            "realm_instance",
        )?;
    }
    if crate::utils::repeats_earlier(hosts, index) {
        return Err(skir_variant!(HostConfigurationRefusal::DuplicateError));
    }
    let desired = HostConfigurationInput::try_from(edit.execution.clone())
        .map_err(|unknown| unknown.into_refusal())?;
    Ok(ConfigurationInput {
        index,
        host: RecordId::from(&edit.host_id),
        expected_revision: edit.expected_revision,
        desired,
    })
}

fn invalid_record_id(
    given_tables: Vec<String>,
    expected_table: &str,
) -> Result<(), HostConfigurationRefusal> {
    if given_tables.is_empty() {
        return Ok(());
    }
    Err(HostConfigurationRefusal::InvalidRecordIdError(Box::new(
        InvalidRecordIdError {
            expected_table: expected_table.to_owned(),
            given_tables,
            _unrecognized: None,
        },
    )))
}

fn item(
    edits: &[HostConfigurationEdit],
    index: usize,
) -> Result<&HostConfigurationEdit, otel_wasi::Error> {
    edits.get(index).ok_or_else(|| {
        otel_wasi::Error::new(
            "service-host-configure-refusal-index-invalid",
            format!("refusal names item {index} of {}", edits.len()),
        )
    })
}

fn refused(
    edit: &HostConfigurationEdit,
    reason: HostConfigurationRefusal,
) -> RefusedHostConfiguration {
    RefusedHostConfiguration {
        host_id: edit.host_id.clone(),
        reason,
        _unrecognized: None,
    }
}

impl ConfiguredHost {
    fn into_change(self) -> HostConfigurationChange {
        HostConfigurationChange {
            host: self.host.into(),
            realm: self.realm.map(Into::into),
            engine: self.engine.map(Into::into),
            removed_resources: [self.removed_engine, self.removed_realm]
                .into_iter()
                .flatten()
                .map(Into::into)
                .collect(),
            ..Default::default()
        }
    }
}

impl ConflictedHost {
    fn into_refusal(self) -> HostConfigurationRefusal {
        skir_variant!(HostConfigurationRefusal::ConflictError {
            actual: HostConfigurationChange {
                host: self.host.into(),
                realm: self.realm.map(Into::into),
                engine: self.engine.map(Into::into),
                removed_resources: Vec::new(),
                ..Default::default()
            },
        })
    }
}

impl RefusedApplication {
    fn into_refusal(
        self,
        edit: &HostConfigurationEdit,
    ) -> Result<HostConfigurationRefusal, otel_wasi::Error> {
        let engine = edit.execution.primary_engine.as_ref();
        match self.outcome.as_str() {
            "invalid-configuration-error" => Ok(skir_variant!(
                HostConfigurationRefusal::InvalidConfigurationError {
                    message: self.message.unwrap_or_default(),
                }
            )),
            "incompatible-engine-error" => Ok(skir_variant!(
                HostConfigurationRefusal::IncompatibleEngineError {
                    target: engine
                        .map(|engine| engine.target.clone())
                        .unwrap_or_default(),
                }
            )),
            "realm-not-found-error" => match engine.map(|engine| &engine.realm) {
                Some(EngineRealmSelection::ExistingRealm(selection)) => Ok(skir_variant!(
                    HostConfigurationRefusal::RealmNotFoundError {
                        realm_id: selection.realm_id.clone(),
                    }
                )),
                _ => Err(otel_wasi::Error::new(
                    "service-host-configure-refusal-realm-missing",
                    "a missing Realm was reported for an item that selects no existing Realm",
                )),
            },
            outcome => Err(otel_wasi::Error::new(
                "service-host-configure-refusal-unknown",
                format!("unexpected refusal outcome `{outcome}`"),
            )),
        }
    }
}

/// Publishes one committed configuration to both topology consumers.
///
/// The organization event carries the complete change, including removed resources. The host
/// event carries only the desired assignment and its new desired topology revision, which is the
/// revision the runtime must later report.
async fn publish_configuration(
    organization_id: &str,
    change: &HostConfigurationChange,
) -> Result<(), otel_wasi::Error> {
    wasmcloud_utils::transport_routes::OrganizationTopologyWatchRoute::delivery(
        &wasmcloud_utils::transport::OrganizationScope::try_from(organization_id)?,
    )
    .publish(OrganizationTopologyChanged::ConfigurationChanged(Box::new(
        change.clone(),
    )))
    .await?;
    let service_id = change.host.service_id.key.raw_identity()?;
    wasmcloud_utils::transport_routes::HostExecutionWatchRoute::delivery(
        &wasmcloud_utils::transport::ServiceScope::try_from(service_id)?,
    )
    .publish(skir_variant!(WatchHostExecutionResponse::Desired {
        topology_revision: change.host.topology_revision.desired,
        realm: change.realm.clone(),
        engine: change.engine.clone(),
    }))
    .await
}
