//! Component discovery and loading.
//!
//! Discovers WASM components by scanning for `.wash` directories,
//! reads configuration from `manifests/workloaddeployment.yaml`,
//! and loads component bytes (preferring pre-compiled .cwasm when available).

use std::collections::HashMap;
use std::path::{Path, PathBuf};

use anyhow::{bail, Context, Result};
use serde::Deserialize;

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

/// Distinguishes between raw WASM and pre-compiled CWASM bytes.
#[derive(Clone)]
pub enum ComponentBytes {
    /// Raw WASM bytes that need JIT compilation
    Wasm(Vec<u8>),
    /// Pre-compiled CWASM bytes (faster to load, skips JIT)
    Precompiled(Vec<u8>),
}

impl ComponentBytes {
    pub fn into_inner(self) -> Vec<u8> {
        match self {
            Self::Wasm(b) | Self::Precompiled(b) => b,
        }
    }

    pub fn as_bytes(&self) -> &[u8] {
        match self {
            Self::Wasm(b) | Self::Precompiled(b) => b,
        }
    }

    pub fn is_precompiled(&self) -> bool {
        matches!(self, Self::Precompiled(_))
    }

    pub fn len(&self) -> usize {
        self.as_bytes().len()
    }
}

/// A discovered component with its configuration and loaded bytes.
#[derive(Clone)]
pub struct DiscoveredComponent {
    /// Component name from workloaddeployment.yaml
    pub name: String,
    /// Path to the component source directory
    pub path: PathBuf,
    /// Host interfaces from workloaddeployment.yaml
    pub host_interfaces: Vec<HostInterface>,
    /// Component bytes (always loaded during discovery)
    pub bytes: ComponentBytes,
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
    /// Discover all components from the backend directory.
    ///
    /// Scans for `.wash` directories, parses their manifests, and loads
    /// component bytes. Prefers pre-compiled `.cwasm` files when available.
    pub fn discover(backend_path: &Path) -> Result<Self> {
        let wash_dirs = find_wash_directories(backend_path)?;
        let mut components = HashMap::new();

        tracing::info!(count = wash_dirs.len(), "Discovering components...");

        for component_dir in wash_dirs {
            match discover_component(&component_dir) {
                Ok(Some(component)) => {
                    let source = if component.bytes.is_precompiled() {
                        "cwasm"
                    } else {
                        "wasm"
                    };
                    tracing::info!(
                        name = %component.name,
                        source = source,
                        size = component.bytes.len(),
                        requires_env = component.requires_environment(),
                        "Discovered component"
                    );
                    components.insert(component.name.clone(), component);
                }
                Ok(None) => {
                    tracing::warn!(path = ?component_dir, "No workloaddeployment.yaml found, skipping");
                }
                Err(e) => {
                    tracing::error!(path = ?component_dir, error = ?e, "Failed to discover component");
                    return Err(e);
                }
            }
        }

        tracing::info!(count = components.len(), "Component discovery complete");
        Ok(Self { components })
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

fn find_wash_directories(backend_path: &Path) -> Result<Vec<PathBuf>> {
    let pattern = format!("{}/**/.wash", backend_path.display());

    glob::glob(&pattern)
        .context("Invalid glob pattern")?
        .filter_map(|entry| entry.ok())
        .filter_map(|wash_dir| wash_dir.parent().map(|p| p.to_path_buf()))
        .map(Ok)
        .collect()
}

fn discover_component(component_dir: &Path) -> Result<Option<DiscoveredComponent>> {
    let deployment = match parse_manifest(component_dir)? {
        Some(d) => d,
        None => return Ok(None),
    };

    let (config_refs, secret_refs) = extract_resource_refs(&deployment);
    let wasm_path = get_wasm_path(component_dir)?;
    let bytes = load_component_bytes(&wasm_path)?;

    Ok(Some(DiscoveredComponent {
        name: deployment.metadata.name,
        path: component_dir.to_path_buf(),
        host_interfaces: deployment.spec.template.spec.host_interfaces,
        bytes,
        config_refs,
        secret_refs,
    }))
}

fn parse_manifest(component_dir: &Path) -> Result<Option<WorkloadDeployment>> {
    let manifest_path = component_dir.join("manifests/workloaddeployment.yaml");

    if !manifest_path.exists() {
        return Ok(None);
    }

    let content = std::fs::read_to_string(&manifest_path)
        .with_context(|| format!("Failed to read {:?}", manifest_path))?;

    let deployment = serde_yaml::from_str(&content)
        .with_context(|| format!("Failed to parse {:?}", manifest_path))?;

    Ok(Some(deployment))
}

fn extract_resource_refs(deployment: &WorkloadDeployment) -> (Vec<String>, Vec<String>) {
    deployment
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
        .unwrap_or_default()
}

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

fn load_component_bytes(wasm_path: &Path) -> Result<ComponentBytes> {
    let cwasm_path = wasm_path.with_extension("cwasm");

    if cwasm_path.exists() {
        let bytes = std::fs::read(&cwasm_path)
            .with_context(|| format!("Failed to read {:?}", cwasm_path))?;
        return Ok(ComponentBytes::Precompiled(bytes));
    }

    if wasm_path.exists() {
        let bytes =
            std::fs::read(wasm_path).with_context(|| format!("Failed to read {:?}", wasm_path))?;
        return Ok(ComponentBytes::Wasm(bytes));
    }

    bail!("No .wasm or .cwasm found at {}", wasm_path.display())
}
