use crate::build::build_project;
use crate::config::Config;
use crate::deploy::deploy_manifest;
use crate::project::Project;
use crate::publish::push_project;
use anyhow::Result;
use std::path::PathBuf;
use tracing::{error, info, warn};

pub async fn build_all_projects(projects: &[Project], config: &Config) -> Result<Vec<Project>> {
    info!("=== STAGE 1: Building all projects ===");
    let mut successful_builds = Vec::new();

    for project in projects {
        match build_project(project, config).await {
            Ok(true) => {
                successful_builds.push(project.clone());
            }
            Ok(false) => {
                warn!("Skipping {} due to build failure", project);
            }
            Err(e) => {
                error!("Failed to build {}: {:?}", project, e);
            }
        }
    }

    info!(
        "Successfully built {}/{} projects",
        successful_builds.len(),
        projects.len()
    );
    Ok(successful_builds)
}

pub async fn publish_all_projects(projects: &[Project], config: &Config) -> Result<()> {
    info!("=== STAGE 2: Publishing all projects ===");

    for project in projects {
        if let Err(e) = push_project(project, config).await {
            error!("Failed to publish {}: {:?}", project, e);
        }
    }

    info!("Finished publishing all projects");
    Ok(())
}

pub async fn deploy_all_manifests(manifests: &[PathBuf], config: &Config) -> Result<()> {
    info!("=== STAGE 3: Deploying all wadm manifests ===");

    for manifest_path in manifests {
        if let Err(e) = deploy_manifest(manifest_path, config).await {
            error!("Failed to deploy {}: {:?}", manifest_path.display(), e);
        }
    }

    info!("Finished deploying all manifests");
    Ok(())
}

pub async fn rebuild_and_redeploy_all(
    projects: &[Project],
    manifests: &[PathBuf],
    config: &Config,
) -> Result<()> {
    let successful_builds = build_all_projects(projects, config).await?;
    publish_all_projects(&successful_builds, config).await?;
    deploy_all_manifests(manifests, config).await?;
    Ok(())
}
