//! The schema files the backend owns and the presets that select them.
//!
//! `backend/database/capabilities.toml` is the one source: it groups the files into capabilities
//! with their dependencies and names the presets. The build embeds every file in manifest order,
//! so any SurrealDB connection, embedded or remote, can receive a preset without reading the
//! repository at run time.

mod manifest;

use std::sync::OnceLock;

use anyhow::{Context, Result};
use surrealdb::{Connection, Surreal};

use crate::manifest::Manifest;

/// One schema file, embedded at build time.
#[derive(Clone, Copy, Debug)]
pub struct SchemaFile {
    /// The path below `backend/database/schema`, as `capabilities.toml` names it.
    pub name: &'static str,
    pub sql: &'static str,
}

const CAPABILITY_MANIFEST: &str = include_str!("../../capabilities.toml");
include!(concat!(env!("OUT_DIR"), "/schema_files.rs"));

/// A named selection of capabilities from `capabilities.toml`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Preset {
    Service,
    Organization,
    Registration,
    /// Everything production deploys; resolves to the same files as `deployment`.
    Full,
}

impl Preset {
    fn manifest_name(self) -> &'static str {
        match self {
            Self::Service => "service",
            Self::Organization => "organization",
            Self::Registration => "registration",
            Self::Full => "full",
        }
    }

    /// The files this preset needs, dependencies first.
    pub fn files(self) -> Result<Vec<&'static SchemaFile>> {
        manifest()?
            .preset_files(self.manifest_name())
            .map_err(anyhow::Error::msg)?
            .into_iter()
            .map(|name| {
                EMBEDDED_SCHEMA_FILES
                    .iter()
                    .find(|file| file.name == name)
                    .with_context(|| format!("schema file {name:?} was not embedded"))
            })
            .collect()
    }

    /// Applies the preset's files to `database` in order, stopping at the first failure.
    pub async fn apply<C: Connection>(self, database: &Surreal<C>) -> Result<()> {
        for (index, file) in self.files()?.into_iter().enumerate() {
            database
                .query(file.sql)
                .await
                .and_then(|response| response.check())
                .with_context(|| {
                    format!(
                        "applying schema preset {self:?}, file {} `{}`",
                        index + 1,
                        file.name
                    )
                })?;
        }
        Ok(())
    }
}

fn manifest() -> Result<&'static Manifest> {
    static MANIFEST: OnceLock<Result<Manifest, String>> = OnceLock::new();
    MANIFEST
        .get_or_init(|| {
            let manifest = Manifest::parse(CAPABILITY_MANIFEST, |_| true)?;
            if manifest.declared_files().len() != EMBEDDED_SCHEMA_FILES.len() {
                return Err("embedded schema files do not match the capability manifest".into());
            }
            Ok(manifest)
        })
        .as_ref()
        .map_err(|error| anyhow::anyhow!(error.clone()))
}
