//! Database records and view conversions for organization service topology.
//!
//! Topology state has separate desired and applied revisions. Database mutations advance desired
//! state, while host execution reports applied state. View records join related storage records
//! for reads and publication without changing ownership of the underlying state.

use serde::{Deserialize, Serialize};
use surrealdb_component_sdk::{Datetime, RecordId};

use super::{SkirDb, SkirType};
use crate::skir::base::service::v1::topology::{
    ChildRuntimeState, ChildRuntimeStatus, EngineInstance, EngineTarget, HostRuntimeState,
    HostRuntimeStatus, OwnerHost, RealmInfo, RealmInstance, ReconciledRevision, ServiceHost,
    SupportedEngine,
};

/// Stored engine target. It stays a storage shape instead of [`SkirDb`] because the schema
/// validates every stored field: [`SkirDb`] omits an empty version constraint, which would
/// replace the schema's typed validation error with a type mismatch.
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct EngineTargetRecord {
    pub engine_id: String,
    pub version_constraint: String,
}

impl From<&EngineTarget> for EngineTargetRecord {
    fn from(value: &EngineTarget) -> Self {
        Self {
            engine_id: value.engine_id.clone(),
            version_constraint: value.version_constraint.clone(),
        }
    }
}

impl From<EngineTargetRecord> for EngineTarget {
    fn from(value: EngineTargetRecord) -> Self {
        Self {
            engine_id: value.engine_id,
            version_constraint: value.version_constraint,
            _unrecognized: None,
        }
    }
}

/// Stored supported engine. Like [`EngineTargetRecord`] it keeps every field, so an empty engine id
/// reaches the schema's typed validation error.
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct SupportedEngineRecord {
    pub engine_id: String,
}

impl From<SupportedEngineRecord> for SupportedEngine {
    fn from(value: SupportedEngineRecord) -> Self {
        Self {
            engine_id: value.engine_id,
            _unrecognized: None,
        }
    }
}

/// Stored host observation. The status is the generated Skir enum; `updated_at` stays a storage
/// field because the schema declares it as a `datetime`.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct HostRuntimeStateRecord {
    pub status: SkirDb<HostRuntimeStatus>,
    pub message: Option<String>,
    pub updated_at: Datetime,
}

impl From<HostRuntimeStateRecord> for HostRuntimeState {
    fn from(value: HostRuntimeStateRecord) -> Self {
        Self {
            status: value.status.0,
            message: value.message,
            updated_at: value.updated_at.into(),
            _unrecognized: None,
        }
    }
}

/// Stored Realm or engine observation. The status is the generated Skir enum; `updated_at` stays
/// a storage field because the schema declares it as a `datetime`.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ChildRuntimeStateRecord {
    pub status: SkirDb<ChildRuntimeStatus>,
    pub active_artifact_version: Option<String>,
    pub message: Option<String>,
    pub updated_at: Datetime,
}

impl From<ChildRuntimeStateRecord> for ChildRuntimeState {
    fn from(value: ChildRuntimeStateRecord) -> Self {
        Self {
            status: value.status.0,
            active_artifact_version: value.active_artifact_version,
            message: value.message,
            updated_at: value.updated_at.into(),
            _unrecognized: None,
        }
    }
}

/// Converts a reported observation into its stored shape, rejecting the unknown status.
impl TryFrom<&ChildRuntimeState> for ChildRuntimeStateRecord {
    type Error = ();

    fn try_from(value: &ChildRuntimeState) -> Result<Self, Self::Error> {
        if value.status.is_unknown() {
            return Err(());
        }
        Ok(Self {
            status: SkirDb(value.status.clone()),
            active_artifact_version: value.active_artifact_version.clone(),
            message: value.message.clone(),
            updated_at: value.updated_at.into(),
        })
    }
}

/// Stored service host and the topology state it owns.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServiceHostRecord {
    pub id: RecordId,
    pub service_id: RecordId,
    pub revision: i64,
    pub entrypoint: String,
    pub can_host_realm: bool,
    pub supported_engines: Vec<SupportedEngineRecord>,
    /// Desired and applied topology revisions. Desired state is what configuration requests
    /// require; applied state is what host execution reported as completed.
    pub topology_revision: SkirDb<ReconciledRevision>,
    pub state: HostRuntimeStateRecord,
}

impl From<ServiceHostRecord> for ServiceHost {
    fn from(value: ServiceHostRecord) -> Self {
        Self {
            host_id: value.id.into(),
            service_id: value.service_id.into(),
            revision: value.revision,
            entrypoint: value.entrypoint.into(),
            can_host_realm: value.can_host_realm,
            supported_engines: value
                .supported_engines
                .into_iter()
                .map(Into::into)
                .collect(),
            topology_revision: value.topology_revision.0,
            state: value.state.into(),
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OwnerHostRecord {
    pub id: RecordId,
    pub name: String,
}

impl From<OwnerHostRecord> for OwnerHost {
    fn from(value: OwnerHostRecord) -> Self {
        Self {
            id: value.id.into(),
            name: value.name,
            _unrecognized: None,
        }
    }
}

/// Read projection of a realm instance with its owning host.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RealmInstanceViewRecord {
    pub id: RecordId,
    pub owner_host: OwnerHostRecord,
    pub revision: i64,
    pub target_engine: EngineTargetRecord,
    pub state: ChildRuntimeStateRecord,
}

impl From<RealmInstanceViewRecord> for RealmInstance {
    fn from(value: RealmInstanceViewRecord) -> Self {
        Self {
            realm_id: value.id.into(),
            owner_host: value.owner_host.into(),
            revision: value.revision,
            target_engine: value.target_engine.into(),
            state: value.state.into(),
            _unrecognized: None,
        }
    }
}

/// Minimal realm and owner information embedded in an engine view.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RealmInfoRecord {
    pub realm_id: RecordId,
    pub owner_host: OwnerHostRecord,
}

impl From<RealmInfoRecord> for RealmInfo {
    fn from(value: RealmInfoRecord) -> Self {
        Self {
            realm_id: value.realm_id.into(),
            owner_host: value.owner_host.into(),
            _unrecognized: None,
        }
    }
}

/// Read projection of an engine instance with its owning host and realm.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EngineInstanceViewRecord {
    pub id: RecordId,
    pub owner_host: OwnerHostRecord,
    pub realm: RealmInfoRecord,
    pub revision: i64,
    pub target: EngineTargetRecord,
    pub state: ChildRuntimeStateRecord,
}

impl From<EngineInstanceViewRecord> for EngineInstance {
    fn from(value: EngineInstanceViewRecord) -> Self {
        Self {
            engine_id: value.id.into(),
            owner_host: value.owner_host.into(),
            realm: value.realm.into(),
            revision: value.revision,
            target: value.target.into(),
            state: value.state.into(),
            _unrecognized: None,
        }
    }
}
