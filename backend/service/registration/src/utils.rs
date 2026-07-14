use otel_wasi::wasi_error;
use wasmcloud_utils::{
    skir::base::service::v1::service::{
        Service, ServiceRegistration, ServiceRole, ServiceRole_Custom, ServiceRole_Engine,
        ServiceRole_Realm, ServiceState, ServiceStatus,
    },
    skir_variant,
};

use crate::{
    ServiceRecord, ServiceRegistrationRecord, ServiceRoleRecord, ServiceRoleTypeRecord,
    ServiceStateRecord, ServiceStatusRecord,
};

impl TryFrom<ServiceRoleRecord> for ServiceRole {
    type Error = otel_wasi::Error;

    fn try_from(value: ServiceRoleRecord) -> Result<Self, Self::Error> {
        let role = match value.role_type {
            ServiceRoleTypeRecord::Engine => skir_variant!(ServiceRole::Engine {
                version: value.version,
            }),
            ServiceRoleTypeRecord::Realm => skir_variant!(ServiceRole::Realm {
                version: value.version,
            }),
            ServiceRoleTypeRecord::Custom => {
                let name = value.name.ok_or_else(|| {
                    wasi_error!(
                        "service-role-custom-name-missing",
                        "custom service role is missing name"
                    )
                })?;
                skir_variant!(ServiceRole::Custom {
                    name,
                    version: value.version,
                })
            }
        };
        Ok(role)
    }
}

impl From<ServiceRegistrationRecord> for ServiceRegistration {
    fn from(value: ServiceRegistrationRecord) -> Self {
        ServiceRegistration {
            token: value.token,
            expires_at: value.expires_at.into(),
            _unrecognized: None,
        }
    }
}

impl From<ServiceStateRecord> for ServiceState {
    fn from(value: ServiceStateRecord) -> Self {
        ServiceState {
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
        Ok(Service {
            service_id: value.id.into(),
            name: value.name,
            roles: value
                .roles
                .into_iter()
                .map(TryInto::try_into)
                .collect::<Result<Vec<_>, _>>()?,
            created_at: value.created_at.into(),
            organization: value.organization.map(Into::into),
            registration: value.registration.map(|registration| registration.into()),
            state: value.state.map(|state| state.into()),
            runs_in: value.runs_in.map(Into::into),
            _unrecognized: None,
        })
    }
}

pub fn generate_registration_token() -> String {
    const CHARSET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let uuid = uuid::Uuid::new_v4();

    uuid.as_bytes()
        .iter()
        .take(10)
        .map(|byte| CHARSET[*byte as usize % CHARSET.len()] as char)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_all_service_roles() {
        let roles = vec![
            ServiceRoleRecord {
                role_type: ServiceRoleTypeRecord::Engine,
                version: "1.0.0".into(),
                name: None,
            },
            ServiceRoleRecord {
                role_type: ServiceRoleTypeRecord::Realm,
                version: "2.0.0".into(),
                name: None,
            },
            ServiceRoleRecord {
                role_type: ServiceRoleTypeRecord::Custom,
                version: "3.0.0".into(),
                name: Some("voice".into()),
            },
        ];

        let mapped = roles
            .into_iter()
            .map(ServiceRole::try_from)
            .collect::<Result<Vec<_>, _>>()
            .unwrap();

        assert!(matches!(mapped[0], ServiceRole::Engine(_)));
        assert!(matches!(mapped[1], ServiceRole::Realm(_)));
        assert!(matches!(mapped[2], ServiceRole::Custom(_)));
    }

    #[test]
    fn rejects_unnamed_custom_role() {
        let role = ServiceRoleRecord {
            role_type: ServiceRoleTypeRecord::Custom,
            version: "1.0.0".into(),
            name: None,
        };

        assert!(ServiceRole::try_from(role).is_err());
    }

    #[test]
    fn registration_token_matches_schema() {
        for _ in 0..32 {
            let token = generate_registration_token();
            assert_eq!(token.len(), 10);
            assert!(
                token
                    .chars()
                    .all(|character| character.is_ascii_uppercase() || character.is_ascii_digit())
            );
        }
    }
}
