use std::fmt::Display;

use otel_wasi::wasi_error;
use serde::{Deserialize, Serialize};
use surrealdb_component_sdk::{Datetime, RecordId};

use crate::{
    skir::base::service::v1::service::{
        Service, ServiceRegistration, ServiceRole, ServiceRole_Custom, ServiceRole_Host,
        ServiceState, ServiceStatus,
    },
    skir_variant,
};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServiceRegistrationRecord {
    pub token: String,
    pub expires_at: Datetime,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum ServiceRoleTypeRecord {
    Host,
    Custom,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct ServiceRoleRecord {
    #[serde(rename = "type")]
    pub role_type: ServiceRoleTypeRecord,
    pub version: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "UPPERCASE")]
pub enum ServiceStatusRecord {
    Online,
    Offline,
}

impl Display for ServiceStatusRecord {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter.write_str(match self {
            Self::Online => "ONLINE",
            Self::Offline => "OFFLINE",
        })
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServiceStateRecord {
    pub status: ServiceStatusRecord,
    pub last_seen: Datetime,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServiceRecord {
    pub id: RecordId,
    pub revision: i64,
    pub name: String,
    pub role: ServiceRoleRecord,
    pub created_at: Datetime,
    pub organization: Option<RecordId>,
    pub registration: Option<ServiceRegistrationRecord>,
    pub state: Option<ServiceStateRecord>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct UnknownServiceRoleError;

impl TryFrom<ServiceRoleRecord> for ServiceRole {
    type Error = otel_wasi::Error;
    fn try_from(value: ServiceRoleRecord) -> Result<Self, Self::Error> {
        Ok(match value.role_type {
            ServiceRoleTypeRecord::Host => skir_variant!(ServiceRole::Host {
                version: value.version
            }),
            ServiceRoleTypeRecord::Custom => skir_variant!(ServiceRole::Custom {
                name: value.name.ok_or_else(|| wasi_error!(
                    "service-role-custom-name-missing",
                    "custom service role is missing name"
                ))?,
                version: value.version,
            }),
        })
    }
}

impl TryFrom<ServiceRole> for ServiceRoleRecord {
    type Error = UnknownServiceRoleError;
    fn try_from(value: ServiceRole) -> Result<Self, Self::Error> {
        match value {
            ServiceRole::Host(role) => Ok(Self {
                role_type: ServiceRoleTypeRecord::Host,
                version: role.version,
                name: None,
            }),
            ServiceRole::Custom(role) => Ok(Self {
                role_type: ServiceRoleTypeRecord::Custom,
                version: role.version,
                name: Some(role.name),
            }),
            ServiceRole::Unknown(_) => Err(UnknownServiceRoleError),
        }
    }
}

impl From<ServiceRegistrationRecord> for ServiceRegistration {
    fn from(value: ServiceRegistrationRecord) -> Self {
        Self {
            token: value.token,
            expires_at: value.expires_at.into(),
            _unrecognized: None,
        }
    }
}
impl From<ServiceStateRecord> for ServiceState {
    fn from(value: ServiceStateRecord) -> Self {
        Self {
            status: match value.status {
                ServiceStatusRecord::Online => ServiceStatus::Online,
                ServiceStatusRecord::Offline => ServiceStatus::Offline,
            },
            last_seen: value.last_seen.into(),
            _unrecognized: None,
        }
    }
}
impl TryFrom<ServiceRecord> for Service {
    type Error = otel_wasi::Error;
    fn try_from(value: ServiceRecord) -> Result<Self, Self::Error> {
        Ok(Self {
            service_id: value.id.into(),
            revision: value.revision,
            name: value.name,
            role: value.role.try_into()?,
            created_at: value.created_at.into(),
            organization: value.organization.map(Into::into),
            registration: value.registration.map(Into::into),
            state: value.state.map(Into::into),
            _unrecognized: None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::skir::base::service::v1::service::{ServiceRole_Custom, ServiceRole_Host};

    #[test]
    fn maps_all_known_roles_in_both_directions() {
        let roles = [
            ServiceRoleRecord {
                role_type: ServiceRoleTypeRecord::Host,
                version: "1".into(),
                name: None,
            },
            ServiceRoleRecord {
                role_type: ServiceRoleTypeRecord::Custom,
                version: "2".into(),
                name: Some("voice".into()),
            },
        ];
        assert!(matches!(
            ServiceRole::try_from(roles[0].clone()).unwrap(),
            ServiceRole::Host(_)
        ));
        assert!(matches!(
            ServiceRole::try_from(roles[1].clone()).unwrap(),
            ServiceRole::Custom(_)
        ));

        let skir_roles = [
            ServiceRole::Host(Box::new(ServiceRole_Host {
                version: "1".into(),
                _unrecognized: None,
            })),
            ServiceRole::Custom(Box::new(ServiceRole_Custom {
                name: "voice".into(),
                version: "2".into(),
                _unrecognized: None,
            })),
        ];
        let records = skir_roles
            .into_iter()
            .map(ServiceRoleRecord::try_from)
            .collect::<Result<Vec<_>, _>>()
            .unwrap();
        assert_eq!(
            records,
            vec![
                ServiceRoleRecord {
                    role_type: ServiceRoleTypeRecord::Host,
                    version: "1".into(),
                    name: None,
                },
                ServiceRoleRecord {
                    role_type: ServiceRoleTypeRecord::Custom,
                    version: "2".into(),
                    name: Some("voice".into()),
                },
            ]
        );
    }

    #[test]
    fn rejects_invalid_role() {
        let unnamed = ServiceRoleRecord {
            role_type: ServiceRoleTypeRecord::Custom,
            version: "1".into(),
            name: None,
        };
        assert!(
            format!("{:?}", ServiceRole::try_from(unnamed).unwrap_err())
                .contains("service-role-custom-name-missing")
        );
        assert_eq!(
            ServiceRoleRecord::try_from(ServiceRole::Unknown(None)),
            Err(UnknownServiceRoleError)
        );
    }

    #[test]
    fn serializes_role_and_status_database_shapes() {
        let host = ServiceRoleRecord {
            role_type: ServiceRoleTypeRecord::Host,
            version: "1".into(),
            name: None,
        };
        assert_eq!(
            serde_json::to_value(host).unwrap(),
            serde_json::json!({ "type": "host", "version": "1" })
        );

        let custom = ServiceRoleRecord {
            role_type: ServiceRoleTypeRecord::Custom,
            version: "2".into(),
            name: Some("voice".into()),
        };
        assert_eq!(
            serde_json::to_value(custom).unwrap(),
            serde_json::json!({ "type": "custom", "version": "2", "name": "voice" })
        );

        assert_eq!(
            serde_json::to_value(ServiceStatusRecord::Online).unwrap(),
            serde_json::json!("ONLINE")
        );
        assert_eq!(
            serde_json::to_value(ServiceStatusRecord::Offline).unwrap(),
            serde_json::json!("OFFLINE")
        );
        assert_eq!(ServiceStatusRecord::Online.to_string(), "ONLINE");
        assert_eq!(ServiceStatusRecord::Offline.to_string(), "OFFLINE");
    }
}
