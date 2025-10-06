use crate::config::Config;
use crate::wash::run_wash_command;
use anyhow::{Context, Result};
use std::path::Path;
use tracing::info;

pub async fn deploy_manifest(manifest_path: &Path, config: &Config) -> Result<()> {
    info!("Deploying manifest: {}", manifest_path.display());
    let manifest_path_str = manifest_path.to_string_lossy();
    run_wash_command(
        &["app", "deploy", "--replace", &manifest_path_str],
        None,
        config,
    )
    .await
    .context("Wash app deploy command failed")
}
