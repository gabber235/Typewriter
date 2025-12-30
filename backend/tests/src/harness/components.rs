//! Component discovery, building, and manifest parsing.
//!
//! Discovers WASM components by scanning for `.wash` directories,
//! reads configuration from `manifests/workloaddeployment.yaml`,
//! and builds components programmatically using cargo.

use std::collections::HashMap;
use std::ffi::OsStr;
use std::path::{Path, PathBuf};
use std::process::Stdio;

use anyhow::{Context, Result, bail};
use serde::Deserialize;
use tokio::process::Command;
use walkdir::WalkDir;

/// Parsed from manifests/workloaddeployment.yaml
#[derive(Debug, Deserialize)]
struct WorkloadDeployment {
    metadata: Metadata,
    spec: Spec,
}

#[derive(Debug, Deserialize)]
struct Metadata {
    name: String,
}

#[derive(Debug, Deserialize)]
struct Spec {
    template: Template,
}

#[derive(Debug, Deserialize)]
struct Template {
    spec: TemplateSpec,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct TemplateSpec {
    host_interfaces: Vec<HostInterface>,
    #[serde(default)]
    components: Vec<YamlComponent>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
struct YamlComponent {
    #[allow(dead_code)]
    name: String,
    #[serde(default)]
    local_resources: Option<YamlLocalResources>,
}

#[derive(Debug, Clone, Deserialize)]
struct YamlLocalResources {
    #[serde(default)]
    environment: Option<YamlEnvironment>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
struct YamlEnvironment {
    #[serde(default)]
    config_from: Vec<ResourceRef>,
    #[serde(default)]
    secret_from: Vec<ResourceRef>,
}

#[derive(Debug, Clone, Deserialize)]
struct ResourceRef {
    name: String,
}

/// Host interface configuration from workloaddeployment.yaml
#[derive(Debug, Clone, Deserialize)]
pub struct HostInterface {
    pub namespace: String,
    pub package: String,
    pub interfaces: Vec<String>,
    #[serde(default)]
    pub config: HashMap<String, String>,
}

/// A discovered component with its configuration.
pub struct DiscoveredComponent {
    /// Component name from workloaddeployment.yaml
    pub name: String,
    /// Path to the component source directory
    pub path: PathBuf,
    /// Host interfaces from workloaddeployment.yaml
    pub host_interfaces: Vec<HostInterface>,
    /// Built WASM bytes (populated after build)
    pub bytes: Option<Vec<u8>>,
    /// Config references from localResources.environment.configFrom
    pub config_refs: Vec<String>,
    /// Secret references from localResources.environment.secretFrom
    pub secret_refs: Vec<String>,
}

impl DiscoveredComponent {
    /// Returns true if this component requires environment configuration.
    /// Components with config or secret references need explicit deployment
    /// with their environment variables provided.
    pub fn requires_environment(&self) -> bool {
        !self.config_refs.is_empty() || !self.secret_refs.is_empty()
    }
}

/// Registry of discovered components.
pub struct ComponentRegistry {
    components: HashMap<String, DiscoveredComponent>,
}

impl ComponentRegistry {
    /// Discover all components from the backend directory by scanning for .wash directories.
    pub fn discover(backend_path: &Path) -> Result<Self> {
        let mut components = HashMap::new();

        let pattern = format!("{}/**/.wash", backend_path.display());
        tracing::info!(pattern = %pattern, "Discovering components...");

        for entry in glob::glob(&pattern).context("Invalid glob pattern")? {
            let wash_dir = entry.context("Failed to read glob entry")?;
            let component_dir = wash_dir
                .parent()
                .context("Failed to get parent of .wash dir")?;

            let manifest_path = component_dir.join("manifests/workloaddeployment.yaml");
            if !manifest_path.exists() {
                tracing::warn!(path = ?component_dir, "No workloaddeployment.yaml found, skipping");
                continue;
            }

            let manifest_content = std::fs::read_to_string(&manifest_path)
                .with_context(|| format!("Failed to read {:?}", manifest_path))?;
            let deployment: WorkloadDeployment = serde_yaml::from_str(&manifest_content)
                .with_context(|| format!("Failed to parse {:?}", manifest_path))?;

            // Extract config/secret refs from the first component's localResources
            let (config_refs, secret_refs) = deployment
                .spec
                .template
                .spec
                .components
                .first()
                .and_then(|c| c.local_resources.as_ref())
                .and_then(|lr| lr.environment.as_ref())
                .map(|env| {
                    (
                        env.config_from.iter().map(|r| r.name.clone()).collect(),
                        env.secret_from.iter().map(|r| r.name.clone()).collect(),
                    )
                })
                .unwrap_or_default();

            let component = DiscoveredComponent {
                name: deployment.metadata.name.clone(),
                path: component_dir.to_path_buf(),
                host_interfaces: deployment.spec.template.spec.host_interfaces,
                bytes: None,
                config_refs,
                secret_refs,
            };

            tracing::info!(
                name = %component.name,
                path = ?component.path,
                interfaces = component.host_interfaces.len(),
                requires_env = component.requires_environment(),
                "Discovered component"
            );

            components.insert(deployment.metadata.name, component);
        }

        tracing::info!(count = components.len(), "Component discovery complete");
        Ok(Self { components })
    }

    /// Build all components, skipping those that are already up-to-date.
    ///
    /// Runs `cargo build --target wasm32-wasip2 --release` for each component
    /// only if the source files have changed since the last build.
    pub async fn build_all(&mut self) -> Result<()> {
        tracing::info!(count = self.components.len(), "Preparing components...");

        for (name, component) in &mut self.components {
            let wasm_path = get_wasm_path(&component.path)?;

            if needs_rebuild(&component.path, &wasm_path)? {
                tracing::info!(name = %name, "Building component (source changed)...");
                build_component(name, &component.path).await?;
            } else {
                tracing::info!(name = %name, "Skipping build (up-to-date)");
            }

            let bytes = std::fs::read(&wasm_path)
                .with_context(|| format!("Failed to read {:?}", wasm_path))?;

            tracing::info!(name = %name, size = bytes.len(), "Component ready");
            component.bytes = Some(bytes);
        }

        tracing::info!("All components ready");
        Ok(())
    }

    /// Get an iterator over all components.
    pub fn all(&self) -> impl Iterator<Item = &DiscoveredComponent> {
        self.components.values()
    }

    /// Get a component by name.
    pub fn get(&self, name: &str) -> Option<&DiscoveredComponent> {
        self.components.get(name)
    }

    /// Get all component names.
    pub fn names(&self) -> Vec<&str> {
        self.components.keys().map(|s| s.as_str()).collect()
    }
}

/// Find the target directory for a component.
///
/// If the component is part of a Cargo workspace, the target directory
/// is in the workspace root, not the component directory.
fn find_target_dir(component_path: &Path) -> Result<PathBuf> {
    let mut current = component_path.to_path_buf();
    while let Some(parent) = current.parent() {
        let cargo_toml = parent.join("Cargo.toml");
        if cargo_toml.exists() {
            let content = std::fs::read_to_string(&cargo_toml)?;
            if content.contains("[workspace]") {
                let workspace_target = parent.join("target");
                if workspace_target.join("wasm32-wasip2").exists() {
                    return Ok(workspace_target);
                }
            }
        }
        current = parent.to_path_buf();
    }

    Ok(component_path.join("target"))
}

/// Get the expected WASM path for a component.
fn get_wasm_path(component_path: &Path) -> Result<PathBuf> {
    let cargo_toml_path = component_path.join("Cargo.toml");
    let cargo_toml = std::fs::read_to_string(&cargo_toml_path)
        .with_context(|| format!("Failed to read {:?}", cargo_toml_path))?;

    let crate_name = cargo_toml
        .lines()
        .find(|line| line.starts_with("name"))
        .and_then(|line| {
            line.split('=')
                .nth(1)
                .map(|s| s.trim().trim_matches('"').to_string())
        })
        .context("Failed to find crate name in Cargo.toml")?;

    let binary_name = crate_name.replace('-', "_");
    let target_dir = find_target_dir(component_path)?;

    Ok(target_dir
        .join("wasm32-wasip2/release")
        .join(format!("{}.wasm", binary_name)))
}

/// Check if component needs to be rebuilt.
///
/// Returns true if:
/// - The WASM file doesn't exist
/// - Any .rs file in src/ is newer than the WASM
/// - Cargo.toml is newer than the WASM
fn needs_rebuild(source_dir: &Path, wasm_path: &Path) -> Result<bool> {
    if !wasm_path.exists() {
        return Ok(true);
    }

    let wasm_mtime = std::fs::metadata(wasm_path)?.modified()?;

    for entry in WalkDir::new(source_dir.join("src"))
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if entry.path().extension() == Some(OsStr::new("rs")) {
            if let Ok(meta) = entry.metadata() {
                if let Ok(src_mtime) = meta.modified() {
                    if src_mtime > wasm_mtime {
                        return Ok(true);
                    }
                }
            }
        }
    }

    let cargo_toml = source_dir.join("Cargo.toml");
    if cargo_toml.exists() {
        if let Ok(meta) = std::fs::metadata(&cargo_toml) {
            if let Ok(toml_mtime) = meta.modified() {
                if toml_mtime > wasm_mtime {
                    return Ok(true);
                }
            }
        }
    }

    Ok(false)
}

/// Build a single component.
async fn build_component(name: &str, component_path: &Path) -> Result<()> {
    let output = Command::new("cargo")
        .arg("build")
        .arg("--target")
        .arg("wasm32-wasip2")
        .arg("--release")
        .current_dir(component_path)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .await
        .with_context(|| format!("Failed to run cargo build for {}", name))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("Failed to build component {}: {}", name, stderr);
    }

    Ok(())
}
