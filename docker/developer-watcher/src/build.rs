use crate::config::Config;
use crate::project::Project;
use crate::wash::run_wash_command;
use anyhow::Result;
use tracing::{info, warn};

pub async fn build_project(project: &Project, config: &Config) -> Result<bool> {
    info!("Building {}", project);
    match run_wash_command(&["build"], Some(project.directory()), config).await {
        Ok(_) => {
            info!("Build successful for {}", project);
            Ok(true)
        }
        Err(e) => {
            warn!("Build failed for {}: {:?}", project, e);
            Ok(false)
        }
    }
}
