//! Component discovery, building, and manifest parsing.
//!
//! Discovers WASM components by scanning for `.wash` directories,
//! reads configuration from `manifests/workloaddeployment.yaml`,
//! and builds components programmatically using cargo.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::process::Stdio;

use anyhow::{Context, Result, bail};
use serde::Deserialize;
use tokio::process::Command;

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

            // Read workloaddeployment.yaml for component config
            let manifest_path = component_dir.join("manifests/workloaddeployment.yaml");
            if !manifest_path.exists() {
                tracing::warn!(path = ?component_dir, "No workloaddeployment.yaml found, skipping");
                continue;
            }

            let manifest_content = std::fs::read_to_string(&manifest_path)
                .with_context(|| format!("Failed to read {:?}", manifest_path))?;
            let deployment: WorkloadDeployment = serde_yaml::from_str(&manifest_content)
                .with_context(|| format!("Failed to parse {:?}", manifest_path))?;

            let component = DiscoveredComponent {
                name: deployment.metadata.name.clone(),
                path: component_dir.to_path_buf(),
                host_interfaces: deployment.spec.template.spec.host_interfaces,
                bytes: None,
            };

            tracing::info!(
                name = %component.name,
                path = ?component.path,
                interfaces = component.host_interfaces.len(),
                "Discovered component"
            );

            components.insert(deployment.metadata.name, component);
        }

        tracing::info!(count = components.len(), "Component discovery complete");
        Ok(Self { components })
    }

    /// Build ALL components programmatically.
    ///
    /// Runs `cargo build --target wasm32-wasip2 --release` for each component.
    /// This is called once before all tests.
    pub async fn build_all(&mut self) -> Result<()> {
        tracing::info!(count = self.components.len(), "Building all components...");

        for (name, component) in &mut self.components {
            tracing::info!(name = %name, path = ?component.path, "Building component...");

            // Run cargo build
            let output = Command::new("cargo")
                .arg("build")
                .arg("--target")
                .arg("wasm32-wasip2")
                .arg("--release")
                .current_dir(&component.path)
                .stdout(Stdio::piped())
                .stderr(Stdio::piped())
                .output()
                .await
                .with_context(|| format!("Failed to run cargo build for {}", name))?;

            if !output.status.success() {
                let stderr = String::from_utf8_lossy(&output.stderr);
                bail!("Failed to build component {}: {}", name, stderr);
            }

            // Find the built WASM file
            // The output is in target/wasm32-wasip2/release/<crate_name>.wasm
            // We need to find the crate name from Cargo.toml
            let cargo_toml_path = component.path.join("Cargo.toml");
            let cargo_toml = std::fs::read_to_string(&cargo_toml_path)
                .with_context(|| format!("Failed to read {:?}", cargo_toml_path))?;

            // Simple parsing to get package name
            let crate_name = cargo_toml
                .lines()
                .find(|line| line.starts_with("name"))
                .and_then(|line| {
                    line.split('=')
                        .nth(1)
                        .map(|s| s.trim().trim_matches('"').to_string())
                })
                .context("Failed to find crate name in Cargo.toml")?;

            // Replace dashes with underscores for the binary name
            let binary_name = crate_name.replace('-', "_");

            // Check if component is part of a workspace (target dir is in workspace root)
            let target_dir = find_target_dir(&component.path)?;
            let wasm_path = target_dir
                .join("wasm32-wasip2/release")
                .join(format!("{}.wasm", binary_name));

            if !wasm_path.exists() {
                bail!(
                    "Built WASM not found at {:?} for component {}",
                    wasm_path,
                    name
                );
            }

            // Read the built WASM bytes
            let bytes = std::fs::read(&wasm_path)
                .with_context(|| format!("Failed to read {:?}", wasm_path))?;

            tracing::info!(
                name = %name,
                size = bytes.len(),
                "Component built successfully"
            );

            component.bytes = Some(bytes);
        }

        tracing::info!("All components built successfully");
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
    // Walk up the directory tree looking for a workspace root first
    // (workspaces put all output in their root target directory)
    let mut current = component_path.to_path_buf();
    while let Some(parent) = current.parent() {
        let cargo_toml = parent.join("Cargo.toml");
        if cargo_toml.exists() {
            // Check if this Cargo.toml defines a workspace
            let content = std::fs::read_to_string(&cargo_toml)?;
            if content.contains("[workspace]") {
                let workspace_target = parent.join("target");
                // Check if workspace has the wasm target dir
                if workspace_target.join("wasm32-wasip2").exists() {
                    return Ok(workspace_target);
                }
            }
        }
        current = parent.to_path_buf();
    }

    // Fall back to local target dir
    Ok(component_path.join("target"))
}
