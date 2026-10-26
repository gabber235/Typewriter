use std::sync::Arc;

use anyhow::{Context, Result};
use component_test::{
    ComponentConfiguration, FixtureBuilder, FixtureDeclaration, FixtureExtension, ProvisionContext,
};
use serde::de::DeserializeOwned;
use surrealdb::{
    IndexedResults,
    types::{SurrealValue, Value},
};
use uuid::Uuid;
use wash_runtime::wit::WitInterface;
use wasmcloud_utils::skir::base::kernel::v1::record_id::RecordId;

use crate::{Organization, StackUser, database_record_key, skir_record_id};
use wasmcloud_plugin_surrealdb::{ConnectionKey, WasmcloudSurrealdb};
use wasmcloud_utils::database::{
    TRANSACTION_CONFLICT_INITIAL_DELAY, TRANSACTION_CONFLICT_MAX_ATTEMPTS,
    TRANSACTION_CONFLICT_MAXIMUM_DELAY,
};

/// How SurrealDB reports a transaction that lost a conflict and may be retried.
const FAILED_TRANSACTION_MESSAGE: &str = "The query was not executed due to a failed transaction";

/// The schema preset a fixture's database receives, as `capabilities.toml` names it.
pub use database_schema::Preset as SchemaPreset;

#[derive(Clone)]
pub struct DatabaseHandle {
    plugin: Arc<WasmcloudSurrealdb>,
    key: ConnectionKey,
}

impl DatabaseHandle {
    async fn response(&self, sql: &str, bindings: Vec<(String, Value)>) -> Result<IndexedResults> {
        let connection = self.plugin.get_or_create_connection(&self.key).await?;
        let database = connection.read().await;
        let mut query = database.query(sql);
        for (name, value) in bindings {
            query = query.bind((name, value));
        }
        query
            .await
            .context("executing database query")?
            .check()
            .context("database query statement failed")
    }

    pub fn seed(&self, sql: impl Into<String>) -> SeedQuery {
        SeedQuery {
            database: self.clone(),
            sql: sql.into(),
            bindings: Vec::new(),
        }
    }

    pub async fn execute(&self, sql: &str) -> Result<IndexedResults> {
        self.response(sql, Vec::new()).await
    }

    pub async fn query<T: DeserializeOwned>(&self, sql: &str) -> Result<Vec<T>> {
        let value = self.query_json(sql).await?;
        serde_json::from_value(value).context("decoding typed database query")
    }

    pub async fn query_json(&self, sql: &str) -> Result<serde_json::Value> {
        let mut response = self.response(sql, Vec::new()).await?;
        let value: surrealdb::types::Value = response.take(0)?;
        Ok(value.into_json_value())
    }

    pub(crate) async fn run(&self, sql: &str, bindings: Vec<(String, Value)>) -> Result<()> {
        self.response(sql, bindings).await.map(drop)
    }

    /// The record of the role `name` in `organization`, as the database created it.
    pub async fn role(&self, organization: &Organization, name: &str) -> Result<RecordId> {
        let value = self
            .seed("SELECT VALUE id FROM organization_role WHERE organization = $organization AND name = $name")
            .bind("organization", surrealdb::types::RecordId::from(organization.id()))?
            .bind("name", name.to_owned())?
            .query_json()
            .await?;
        Ok(skir_record_id(
            "organization_role",
            database_record_key(&value, "organization_role")?,
        ))
    }

    /// The record of `user`'s pending request to join `organization`.
    pub async fn join_request(
        &self,
        user: &StackUser,
        organization: &Organization,
    ) -> Result<RecordId> {
        let value = self
            .seed("SELECT VALUE id FROM request_to_join WHERE in = $user AND out = $organization")
            .bind("user", surrealdb::types::RecordId::from(user.id()))?
            .bind(
                "organization",
                surrealdb::types::RecordId::from(organization.id()),
            )?
            .query_json()
            .await?;
        Ok(skir_record_id(
            "request_to_join",
            database_record_key(&value, "request_to_join")?,
        ))
    }
}

pub struct SeedQuery {
    database: DatabaseHandle,
    sql: String,
    bindings: Vec<(String, Value)>,
}

impl SeedQuery {
    pub fn bind(mut self, name: impl Into<String>, value: impl SurrealValue) -> Result<Self> {
        self.bindings.push((name.into(), value.into_value()));
        Ok(self)
    }
    pub async fn execute(self) -> Result<IndexedResults> {
        self.database.response(&self.sql, self.bindings).await
    }

    pub async fn query_json(self) -> Result<serde_json::Value> {
        let mut response = self.database.response(&self.sql, self.bindings).await?;
        let value: surrealdb::types::Value = response.take(0)?;
        Ok(value.into_json_value())
    }

    /// Runs a component's transaction the way the component does: a conflict with a concurrent
    /// transaction is retried under the same bounded policy, and the statement at
    /// `outcome_index` is returned. Lets a case race a transaction against itself without the
    /// component, where the losing call of such a race currently never replies.
    pub async fn transaction_json(self, outcome_index: usize) -> Result<serde_json::Value> {
        for attempt in 1..=TRANSACTION_CONFLICT_MAX_ATTEMPTS {
            match self
                .database
                .response(&self.sql, self.bindings.clone())
                .await
            {
                Ok(mut response) => {
                    let value: surrealdb::types::Value = response.take(outcome_index)?;
                    return Ok(value.into_json_value());
                }
                Err(error)
                    if attempt < TRANSACTION_CONFLICT_MAX_ATTEMPTS
                        && error.chain().any(|cause| {
                            cause.to_string().contains(FAILED_TRANSACTION_MESSAGE)
                        }) =>
                {
                    let multiplier = 1_u32
                        .checked_shl(attempt.saturating_sub(1))
                        .unwrap_or(u32::MAX);
                    let delay = TRANSACTION_CONFLICT_INITIAL_DELAY
                        .saturating_mul(multiplier)
                        .min(TRANSACTION_CONFLICT_MAXIMUM_DELAY);
                    tokio::time::sleep(delay).await;
                }
                Err(error) => return Err(error),
            }
        }
        unreachable!("transaction conflict attempt count is nonzero")
    }
}

pub struct TypewriterDatabase {
    preset: SchemaPreset,
}

impl TypewriterDatabase {
    pub fn new(preset: SchemaPreset) -> Self {
        Self { preset }
    }
}

#[async_trait::async_trait]
impl FixtureExtension for TypewriterDatabase {
    type Handle = DatabaseHandle;

    async fn provision(&mut self, context: &mut ProvisionContext) -> Result<Self::Handle> {
        let unique = Uuid::new_v4().simple().to_string();
        let key = ConnectionKey::from_config(&std::collections::HashMap::from([
            ("url".into(), "memory".into()),
            ("namespace".into(), format!("component_test_{unique}")),
            ("database".into(), format!("fixture_{unique}")),
        ]))?;
        let plugin = Arc::new(WasmcloudSurrealdb::new());
        let handle = DatabaseHandle {
            plugin: plugin.clone(),
            key: key.clone(),
        };
        let connection = plugin.get_or_create_connection(&key).await?;
        self.preset.apply(&*connection.read().await).await?;
        context.plugin(plugin);
        let mut interface = WitInterface::from("seamlezz:surrealdb/call@0.4.0");
        interface.config.insert("url".into(), key.url.clone());
        interface
            .config
            .insert("namespace".into(), key.namespace.clone());
        interface
            .config
            .insert("database".into(), key.database.clone());
        context.interface(interface);
        Ok(handle)
    }
}

pub trait TypewriterFixtureBuilderExt<F>: Sized {
    fn typewriter_database(self, preset: SchemaPreset) -> Self;
    fn typewriter_database_for(self, component: impl Into<String>, preset: SchemaPreset) -> Self;
}

impl<F: FixtureDeclaration> TypewriterFixtureBuilderExt<F> for FixtureBuilder<F> {
    fn typewriter_database(self, preset: SchemaPreset) -> Self {
        let component = F::DESCRIPTOR.primary.package.to_string();
        self.typewriter_database_for(component, preset)
    }

    fn typewriter_database_for(self, component: impl Into<String>, preset: SchemaPreset) -> Self {
        self.dependency(component, |configuration: ComponentConfiguration| {
            configuration
        })
        .extension(TypewriterDatabase::new(preset))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    async fn database(preset: SchemaPreset) -> Result<DatabaseHandle> {
        let unique = Uuid::new_v4().simple().to_string();
        let key = ConnectionKey::from_config(&std::collections::HashMap::from([
            ("url".into(), "memory".into()),
            ("namespace".into(), format!("test_{unique}")),
            ("database".into(), "test".into()),
        ]))?;
        let handle = DatabaseHandle {
            plugin: Arc::new(WasmcloudSurrealdb::new()),
            key,
        };
        for file in preset.files()? {
            handle.execute(file.sql).await?;
        }
        Ok(handle)
    }

    #[tokio::test]
    async fn every_preset_applies_to_a_fresh_database() -> Result<()> {
        for preset in [
            SchemaPreset::Service,
            SchemaPreset::Organization,
            SchemaPreset::Registration,
            SchemaPreset::Full,
        ] {
            database(preset).await?;
        }
        Ok(())
    }
}
