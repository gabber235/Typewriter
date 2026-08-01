use std::{collections::HashSet, sync::Arc};

use anyhow::{Context, Result};
use component_test::{
    ComponentConfiguration, FixtureBuilder, FixtureDeclaration, FixtureExtension, ProvisionContext,
};
use serde::{Serialize, de::DeserializeOwned};
use surrealdb::IndexedResults;
use uuid::Uuid;
use wash_runtime::wit::WitInterface;
use wasmcloud_plugin_surrealdb::{ConnectionKey, WasmcloudSurrealdb};

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

const ID: SchemaFile = SchemaFile {
    name: "kernel/id.surql",
    sql: include_str!("../../../../../database/schema/kernel/id.surql"),
};
const COLOR: SchemaFile = SchemaFile {
    name: "kernel/color.surql",
    sql: include_str!("../../../../../database/schema/kernel/color.surql"),
};
const URL: SchemaFile = SchemaFile {
    name: "kernel/url.surql",
    sql: include_str!("../../../../../database/schema/kernel/url.surql"),
};
const USER: SchemaFile = SchemaFile {
    name: "user.surql",
    sql: include_str!("../../../../../database/schema/user.surql"),
};
const SERVICE_FUNCTIONS: SchemaFile = SchemaFile {
    name: "service/functions.surql",
    sql: include_str!("../../../../../database/schema/service/functions.surql"),
};
const SERVICE: SchemaFile = SchemaFile {
    name: "service/service.surql",
    sql: include_str!("../../../../../database/schema/service/service.surql"),
};
const ORG_FUNCTIONS: SchemaFile = SchemaFile {
    name: "organization/functions.surql",
    sql: include_str!("../../../../../database/schema/organization/functions.surql"),
};
const ORGANIZATION: SchemaFile = SchemaFile {
    name: "organization/organization.surql",
    sql: include_str!("../../../../../database/schema/organization/organization.surql"),
};
const ORG_ROLE: SchemaFile = SchemaFile {
    name: "organization/organization_role.surql",
    sql: include_str!("../../../../../database/schema/organization/organization_role.surql"),
};
const MEMBER_OF: SchemaFile = SchemaFile {
    name: "organization/member_of.surql",
    sql: include_str!("../../../../../database/schema/organization/member_of.surql"),
};
const JOIN_CODE: SchemaFile = SchemaFile {
    name: "organization/organization_join_code.surql",
    sql: include_str!("../../../../../database/schema/organization/organization_join_code.surql"),
};
const JOIN_REQUEST: SchemaFile = SchemaFile {
    name: "organization/request_to_join.surql",
    sql: include_str!("../../../../../database/schema/organization/request_to_join.surql"),
};

impl SchemaPreset {
    fn files(self) -> Vec<SchemaFile> {
        let groups: &[&[SchemaFile]] = match self {
            Self::Service => &[&[ID, SERVICE_FUNCTIONS, SERVICE]],
            Self::Organization => &[&[
                ID,
                COLOR,
                URL,
                USER,
                ORG_FUNCTIONS,
                ORGANIZATION,
                ORG_ROLE,
                MEMBER_OF,
                JOIN_CODE,
                JOIN_REQUEST,
            ]],
            Self::Registration | Self::Full => &[
                &[ID, SERVICE_FUNCTIONS, SERVICE],
                &[
                    ID,
                    COLOR,
                    URL,
                    USER,
                    ORG_FUNCTIONS,
                    ORGANIZATION,
                    ORG_ROLE,
                    MEMBER_OF,
                    JOIN_CODE,
                    JOIN_REQUEST,
                ],
            ],
        };
        let mut seen = HashSet::new();
        groups
            .iter()
            .flat_map(|group| *group)
            .copied()
            .filter(|file| seen.insert(file.name))
            .collect()
    }
}

#[derive(Clone)]
pub struct DatabaseHandle {
    plugin: Arc<WasmcloudSurrealdb>,
    key: ConnectionKey,
}

impl DatabaseHandle {
    async fn response(
        &self,
        sql: &str,
        bindings: Vec<(String, serde_json::Value)>,
    ) -> Result<IndexedResults> {
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
    bindings: Vec<(String, serde_json::Value)>,
}

impl SeedQuery {
    pub fn bind(mut self, name: impl Into<String>, value: impl Serialize) -> Result<Self> {
        self.bindings
            .push((name.into(), serde_json::to_value(value)?));
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
        for (index, file) in self.preset.files().iter().enumerate() {
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
        let mut interface = WitInterface::from("seamlezz:surrealdb/call@0.3.0");
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
        for file in preset.files() {
            handle.execute(file.sql).await?;
        }
        Ok(handle)
    }

    #[test]
    fn full_preset_preserves_order_without_duplicates() {
        let names = SchemaPreset::Full
            .files()
            .iter()
            .map(|file| file.name)
            .collect::<Vec<_>>();
        assert_eq!(names.first(), Some(&"kernel/id.surql"));
        assert_eq!(
            names
                .iter()
                .filter(|name| **name == "kernel/id.surql")
                .count(),
            1
        );
        assert!(
            names
                .iter()
                .position(|name| *name == "organization/functions.surql")
                < names
                    .iter()
                    .position(|name| *name == "organization/organization.surql")
        );
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
            .seed("CREATE seed_test CONTENT { amount: $value }")
            .bind("value", 42_i64)?
            .execute()
            .await?;
        assert_eq!(
            database
                .query::<Row>("SELECT amount FROM seed_test")
                .await?,
            vec![Row { amount: 42 }]
        );
        Ok(())
    }
}
