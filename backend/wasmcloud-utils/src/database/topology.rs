use serde::{Deserialize, Serialize};
use surrealdb_component_sdk::{Datetime, RecordId};

use crate::skir::base::service::v1::topology::{
    ChildRuntimeState, ChildRuntimeStatus, EngineInstance, EngineTarget, HostEntrypoint,
    HostRuntimeState, HostRuntimeStatus, RealmInstance, ReconciledRevision, ServiceHost,
    SupportedEngine,
};

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct ReconciledRevisionRecord {
    pub desired: i64,
    pub applied: i64,
}

impl From<ReconciledRevisionRecord> for ReconciledRevision {
    fn from(value: ReconciledRevisionRecord) -> Self {
        Self {
            desired: value.desired,
            applied: value.applied,
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct EngineTargetRecord {
    pub engine_id: String,
    pub major_version: i32,
}

impl From<&EngineTarget> for EngineTargetRecord {
    fn from(value: &EngineTarget) -> Self {
        Self {
            engine_id: value.engine_id.clone(),
            major_version: value.major_version,
        }
    }
}

impl From<EngineTargetRecord> for EngineTarget {
    fn from(value: EngineTargetRecord) -> Self {
        Self {
            engine_id: value.engine_id,
            major_version: value.major_version,
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct SupportedEngineRecord {
    pub engine_id: String,
    pub supported_major_versions: Vec<i32>,
}

impl From<SupportedEngineRecord> for SupportedEngine {
    fn from(value: SupportedEngineRecord) -> Self {
        Self {
            engine_id: value.engine_id,
            supported_major_versions: value.supported_major_versions,
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "UPPERCASE")]
pub enum HostEntrypointRecord {
    Standalone,
    Paper,
}

impl From<HostEntrypointRecord> for HostEntrypoint {
    fn from(value: HostEntrypointRecord) -> Self {
        match value {
            HostEntrypointRecord::Standalone => HostEntrypoint::Standalone,
            HostEntrypointRecord::Paper => HostEntrypoint::Paper,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "UPPERCASE")]
pub enum HostRuntimeStatusRecord {
    Offline,
    Reconciling,
    Active,
    Failed,
    Drifted,
}

impl From<HostRuntimeStatusRecord> for HostRuntimeStatus {
    fn from(value: HostRuntimeStatusRecord) -> Self {
        match value {
            HostRuntimeStatusRecord::Offline => HostRuntimeStatus::Offline,
            HostRuntimeStatusRecord::Reconciling => HostRuntimeStatus::Reconciling,
            HostRuntimeStatusRecord::Active => HostRuntimeStatus::Active,
            HostRuntimeStatusRecord::Failed => HostRuntimeStatus::Failed,
            HostRuntimeStatusRecord::Drifted => HostRuntimeStatus::Drifted,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct HostRuntimeStateRecord {
    pub status: HostRuntimeStatusRecord,
    pub message: Option<String>,
    pub updated_at: Datetime,
}

impl From<HostRuntimeStateRecord> for HostRuntimeState {
    fn from(value: HostRuntimeStateRecord) -> Self {
        Self {
            status: value.status.into(),
            message: value.message,
            updated_at: value.updated_at.into(),
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "UPPERCASE")]
pub enum ChildRuntimeStatusRecord {
    Absent,
    Staging,
    Active,
    Quiescing,
    Failed,
    RolledBack,
    Drifted,
}

impl From<ChildRuntimeStatusRecord> for ChildRuntimeStatus {
    fn from(value: ChildRuntimeStatusRecord) -> Self {
        match value {
            ChildRuntimeStatusRecord::Absent => ChildRuntimeStatus::Absent,
            ChildRuntimeStatusRecord::Staging => ChildRuntimeStatus::Staging,
            ChildRuntimeStatusRecord::Active => ChildRuntimeStatus::Active,
            ChildRuntimeStatusRecord::Quiescing => ChildRuntimeStatus::Quiescing,
            ChildRuntimeStatusRecord::Failed => ChildRuntimeStatus::Failed,
            ChildRuntimeStatusRecord::RolledBack => ChildRuntimeStatus::RolledBack,
            ChildRuntimeStatusRecord::Drifted => ChildRuntimeStatus::Drifted,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ChildRuntimeStateRecord {
    pub status: ChildRuntimeStatusRecord,
    pub active_artifact_version: Option<String>,
    pub message: Option<String>,
    pub updated_at: Datetime,
}

impl From<ChildRuntimeStateRecord> for ChildRuntimeState {
    fn from(value: ChildRuntimeStateRecord) -> Self {
        Self {
            status: value.status.into(),
            active_artifact_version: value.active_artifact_version,
            message: value.message,
            updated_at: value.updated_at.into(),
            _unrecognized: None,
        }
    }
}

impl TryFrom<&ChildRuntimeState> for ChildRuntimeStateRecord {
    type Error = ();

    fn try_from(value: &ChildRuntimeState) -> Result<Self, Self::Error> {
        let status = match value.status {
            ChildRuntimeStatus::Absent => ChildRuntimeStatusRecord::Absent,
            ChildRuntimeStatus::Staging => ChildRuntimeStatusRecord::Staging,
            ChildRuntimeStatus::Active => ChildRuntimeStatusRecord::Active,
            ChildRuntimeStatus::Quiescing => ChildRuntimeStatusRecord::Quiescing,
            ChildRuntimeStatus::Failed => ChildRuntimeStatusRecord::Failed,
            ChildRuntimeStatus::RolledBack => ChildRuntimeStatusRecord::RolledBack,
            ChildRuntimeStatus::Drifted => ChildRuntimeStatusRecord::Drifted,
            ChildRuntimeStatus::Unknown(_) => return Err(()),
        };
        Ok(Self {
            status,
            active_artifact_version: value.active_artifact_version.clone(),
            message: value.message.clone(),
            updated_at: value.updated_at.into(),
        })
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServiceHostRecord {
    pub id: RecordId,
    pub service_id: RecordId,
    pub revision: i64,
    pub entrypoint: HostEntrypointRecord,
    pub can_host_realm: bool,
    pub supported_engines: Vec<SupportedEngineRecord>,
    pub topology_revision: ReconciledRevisionRecord,
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
            topology_revision: value.topology_revision.into(),
            state: value.state.into(),
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RealmInstanceRecord {
    pub id: RecordId,
    pub owner_host_id: RecordId,
    pub revision: i64,
    pub target_engine: EngineTargetRecord,
    pub manifest_revision: ReconciledRevisionRecord,
    pub state: ChildRuntimeStateRecord,
}

impl From<RealmInstanceRecord> for RealmInstance {
    fn from(value: RealmInstanceRecord) -> Self {
        Self {
            realm_id: value.id.into(),
            owner_host_id: value.owner_host_id.into(),
            revision: value.revision,
            target_engine: value.target_engine.into(),
            manifest_revision: value.manifest_revision.into(),
            state: value.state.into(),
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EngineInstanceRecord {
    pub id: RecordId,
    pub owner_host_id: RecordId,
    pub realm_id: RecordId,
    pub revision: i64,
    pub target: EngineTargetRecord,
    pub manifest_revision: ReconciledRevisionRecord,
    pub state: ChildRuntimeStateRecord,
}

impl From<EngineInstanceRecord> for EngineInstance {
    fn from(value: EngineInstanceRecord) -> Self {
        Self {
            engine_id: value.id.into(),
            owner_host_id: value.owner_host_id.into(),
            realm_id: value.realm_id.into(),
            revision: value.revision,
            target: value.target.into(),
            manifest_revision: value.manifest_revision.into(),
            state: value.state.into(),
            _unrecognized: None,
        }
    }
}
