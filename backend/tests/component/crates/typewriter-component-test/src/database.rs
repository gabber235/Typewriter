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
use wasmcloud_plugin_surrealdb::{ConnectionKey, WasmcloudSurrealdb};
use wasmcloud_utils::database::{
    TRANSACTION_CONFLICT_INITIAL_DELAY, TRANSACTION_CONFLICT_MAX_ATTEMPTS,
    TRANSACTION_CONFLICT_MAXIMUM_DELAY,
};

const FAILED_TRANSACTION_MESSAGE: &str = "The query was not executed due to a failed transaction";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SchemaPreset {
    Service,
    Organization,
    Registration,
    Full,
}

#[derive(Clone, Copy)]
struct SchemaFile {
    name: &'static str,
    sql: &'static str,
}

const CAPABILITY_MANIFEST: &str = include_str!("../../../../../database/capabilities.toml");
include!(concat!(env!("OUT_DIR"), "/schema_files.rs"));

impl SchemaPreset {
    fn manifest_name(self) -> &'static str {
        match self {
            Self::Service => "service",
            Self::Organization => "organization",
            Self::Registration => "registration",
            Self::Full => "full",
        }
    }

    fn files(self) -> Result<Vec<SchemaFile>> {
        let manifest = crate::schema_manifest::Manifest::parse(CAPABILITY_MANIFEST, |_| true)
            .map_err(anyhow::Error::msg)?;
        if manifest.declared_files().len() != EMBEDDED_SCHEMA_FILES.len() {
            anyhow::bail!("embedded schema files do not match the capability manifest");
        }
        manifest
            .preset_files(self.manifest_name())
            .map_err(anyhow::Error::msg)?
            .into_iter()
            .map(|name| {
                EMBEDDED_SCHEMA_FILES
                    .iter()
                    .find(|file| file.name == name)
                    .copied()
                    .with_context(|| format!("schema file {name:?} was not embedded"))
            })
            .collect()
    }
}

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

    pub async fn query_json_retrying_conflicts(
        self,
        outcome_index: usize,
    ) -> Result<serde_json::Value> {
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
        for (index, file) in self.preset.files()?.iter().enumerate() {
            handle.execute(file.sql).await.with_context(|| {
                format!(
                    "applying schema preset {:?}, file {} `{}`, query index {index}",
                    self.preset,
                    index + 1,
                    file.name
                )
            })?;
        }
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

    #[test]
    fn manifest_presets_preserve_existing_schema_sets_and_order() {
        let names = |preset: SchemaPreset| {
            preset
                .files()
                .expect("schema preset must resolve")
                .iter()
                .map(|file| file.name)
                .collect::<Vec<_>>()
        };
        let service = vec![
            "kernel/id.surql",
            "service/functions.surql",
            "service/service.surql",
        ];
        let organization = vec![
            "kernel/id.surql",
            "kernel/color.surql",
            "kernel/url.surql",
            "user.surql",
            "organization/functions.surql",
            "organization/organization.surql",
            "organization/organization_role.surql",
            "organization/member_of.surql",
            "organization/organization_join_code.surql",
            "organization/request_to_join.surql",
        ];
        let combined = vec![
            "kernel/id.surql",
            "service/functions.surql",
            "service/service.surql",
            "kernel/color.surql",
            "kernel/url.surql",
            "user.surql",
            "organization/functions.surql",
            "organization/organization.surql",
            "organization/organization_role.surql",
            "organization/member_of.surql",
            "organization/organization_join_code.surql",
            "organization/request_to_join.surql",
        ];

        assert_eq!(names(SchemaPreset::Service), service);
        assert_eq!(names(SchemaPreset::Organization), organization);
        assert_eq!(names(SchemaPreset::Registration), combined);
        assert_eq!(names(SchemaPreset::Full), combined);
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

    #[tokio::test]
    async fn seed_bind_and_typed_query_preserve_values() -> Result<()> {
        #[derive(serde::Deserialize, PartialEq, Debug)]
        struct Row {
            amount: i64,
        }
        let database = database(SchemaPreset::Service).await?;
        database
            .seed("CREATE seed_test CONTENT { amount: $value, organization: organization:alpha }")
            .bind("value", 42_i64)?
            .execute()
            .await?;
        assert_eq!(
            database
                .query::<Row>("SELECT amount FROM seed_test")
                .await?,
            vec![Row { amount: 42 }]
        );
        assert_eq!(
            database
                .seed("RETURN count(SELECT id FROM seed_test WHERE organization = $organization)")
                .bind(
                    "organization",
                    surrealdb::types::RecordId::new("organization", "alpha"),
                )?
                .query_json()
                .await?,
            serde_json::json!(1)
        );
        Ok(())
    }
}
