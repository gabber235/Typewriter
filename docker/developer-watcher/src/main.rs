mod build;
mod config;
mod deploy;
mod discovery;
mod pipeline;
mod project;
mod publish;
mod wash;
mod watcher;

use anyhow::{Result, anyhow};
use clap::Parser;
use config::Config;
use discovery::{find_all_deployment_manifests, find_projects};
use pipeline::rebuild_and_redeploy_all;
use tracing::{error, info};
use tracing_subscriber::{filter::EnvFilter, fmt, layer::SubscriberExt, util::SubscriberInitExt};
use watcher::watch_projects;

#[tokio::main]
async fn main() -> Result<()> {
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("warn,developer_watcher=info"));

    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(filter)
        .init();

    info!("Starting wasmCloud Developer Watcher...");

    let config = Config::parse();

    if !config.projects_base_dir.is_dir() {
        error!(
            "Projects base directory not found or not a directory: {}",
            config.projects_base_dir.display()
        );
        return Err(anyhow!("Invalid projects_base_dir"));
    }

    info!("=== STAGE 0: Collecting projects and manifests ===");
    let projects = find_projects(&config.projects_base_dir)?;
    info!("Found {} projects", projects.len());

    let manifests = find_all_deployment_manifests(&config.projects_base_dir);
    info!("Found {} develop.wadm.yaml files", manifests.len());
    for manifest in &manifests {
        info!("  - {}", manifest.display());
    }

    info!("Performing initial build, publish, and deploy of all projects...");
    if let Err(e) = rebuild_and_redeploy_all(&projects, &manifests, &config).await {
        error!("Initial build/deploy failed: {:?}", e);
    }

    watch_projects(projects, manifests, &config).await?;

    info!("wasmCloud Developer Watcher finished.");
    Ok(())
}
