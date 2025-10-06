use crate::config::{DEVELOP_WADM_YAML, PROJECT_CARGO, PROJECT_MARKER};
use crate::project::Project;
use anyhow::{Context, Result, anyhow};
use std::fs;
use std::path::{Path, PathBuf};
use tracing::{info, warn};
use walkdir::WalkDir;

pub fn find_projects(base_dir: &Path) -> Result<Vec<Project>> {
    let mut projects = Vec::new();
    for entry in WalkDir::new(base_dir).min_depth(1).max_depth(4) {
        let entry = entry.context("Failed to read directory entry")?;
        if entry.file_type().is_dir() {
            let marker_path = entry.path().join(PROJECT_MARKER);
            let cargo_path = entry.path().join(PROJECT_CARGO);

            if !marker_path.is_file() || !cargo_path.is_file() {
                continue;
            }

            let marker_content =
                fs::read_to_string(&marker_path).context("Failed to read project marker file")?;
            let marker: toml::Value =
                toml::from_str(&marker_content).context("Failed to parse wasmcloud.toml")?;

            let project_type = marker
                .get("type")
                .and_then(|t| t.as_str())
                .ok_or_else(|| anyhow!("Missing or invalid type in wasmcloud.toml"))?;
            let project_name = marker
                .get("name")
                .and_then(|n| n.as_str())
                .ok_or_else(|| anyhow!("Missing or invalid name in wasmcloud.toml"))?;

            let cargo_content =
                fs::read_to_string(&cargo_path).context("Failed to read Cargo.toml")?;
            let cargo_toml: toml::Value =
                toml::from_str(&cargo_content).context("Failed to parse Cargo.toml")?;
            let version = cargo_toml
                .get("package")
                .and_then(|p| p.get("version"))
                .and_then(|v| v.as_str())
                .unwrap_or("unknown")
                .to_string();

            let project = match project_type.to_lowercase().as_str() {
                "component" => Project::Component {
                    name: project_name.to_string(),
                    version: version.clone(),
                    directory: entry.path().to_path_buf(),
                },
                "provider" => Project::Provider {
                    name: project_name.to_string(),
                    version: version.clone(),
                    directory: entry.path().to_path_buf(),
                },
                _ => {
                    warn!(
                        "Unknown project type '{}' in {}",
                        project_type,
                        marker_path.display()
                    );
                    continue;
                }
            };

            info!("Found {}", project);
            projects.push(project);
        }
    }
    projects.sort();
    projects.dedup();
    Ok(projects)
}

pub fn find_all_deployment_manifests(base_dir: &Path) -> Vec<PathBuf> {
    let mut manifests = Vec::new();

    for entry in WalkDir::new(base_dir).min_depth(1).max_depth(10) {
        let Ok(entry) = entry else { continue };

        if !entry.file_type().is_file() {
            continue;
        }

        if entry.file_name() == DEVELOP_WADM_YAML {
            manifests.push(entry.path().to_path_buf());
        }
    }

    manifests.sort_by_key(|path| path.components().count());
    manifests
}
