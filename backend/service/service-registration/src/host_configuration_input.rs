//! Database input for one desired host execution configuration.

use wasmcloud_utils::{
    database::{RecordId, topology::EngineTargetRecord},
    skir::base::service::v1::topology::{
        ConfigureServiceHostResponse, ConfigureServiceHostResponse_InvalidConfigurationError,
        EngineRealmSelection, HostExecutionConfiguration,
    },
    skir_variant,
};

#[derive(serde::Serialize)]
pub(crate) struct HostConfigurationInput {
    realm: Option<HostedRealmInput>,
    primary_engine: Option<HostedEngineInput>,
}

#[derive(serde::Serialize)]
struct HostedRealmInput {
    primary_engine: EngineTargetRecord,
}

#[derive(serde::Serialize)]
struct HostedEngineInput {
    target: EngineTargetRecord,
    realm: RealmSelectionInput,
}

#[derive(serde::Serialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
enum RealmSelectionInput {
    HostedRealm,
    ExistingRealm { realm_id: RecordId },
}

pub(crate) struct UnknownRealmSelection;

impl UnknownRealmSelection {
    pub(crate) fn into_configuration_response(self) -> ConfigureServiceHostResponse {
        skir_variant!(ConfigureServiceHostResponse::InvalidConfigurationError {
            message: "Engine Realm selection is unknown".to_owned(),
        })
    }
}

impl TryFrom<HostExecutionConfiguration> for HostConfigurationInput {
    type Error = UnknownRealmSelection;

    fn try_from(value: HostExecutionConfiguration) -> Result<Self, Self::Error> {
        let realm = value.realm.map(|value| HostedRealmInput {
            primary_engine: EngineTargetRecord::from(&value.primary_engine),
        });
        let primary_engine = value
            .primary_engine
            .map(|value| {
                let realm = match value.realm {
                    EngineRealmSelection::HostedRealm => RealmSelectionInput::HostedRealm,
                    EngineRealmSelection::ExistingRealm(value) => {
                        RealmSelectionInput::ExistingRealm {
                            realm_id: RecordId::from(&value.realm_id),
                        }
                    }
                    EngineRealmSelection::Unknown(_) => return Err(UnknownRealmSelection),
                };
                Ok(HostedEngineInput {
                    target: EngineTargetRecord::from(&value.target),
                    realm,
                })
            })
            .transpose()?;
        Ok(Self {
            realm,
            primary_engine,
        })
    }
}
