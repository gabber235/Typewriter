use crate::config::{BUILD_DIR, Config};
use crate::project::Project;
use crate::wash::run_wash_command;
use anyhow::{Context, Result};
use tracing::{info, warn};
use walkdir::WalkDir;

pub async fn push_project(project: &Project, config: &Config) -> Result<()> {
    let build_output_dir = project.directory().join(BUILD_DIR);
    if !build_output_dir.is_dir() {
        warn!(
            "Build directory {} not found for project {}",
            build_output_dir.display(),
            project.directory().display()
        );
        return Ok(());
    }

    let mut artifacts_pushed = 0;
    for entry in WalkDir::new(&build_output_dir).max_depth(1).min_depth(1) {
        let entry = entry.context("Failed to read build directory entry")?;
        let path = entry.path();

        if !path.is_file() {
            continue;
        }

        let file_name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
        let Some(image_ref) = project.get_image_reference(&config.registry_url, file_name) else {
            continue;
        };

        let artifact_path_str = path.to_string_lossy().to_string();
        info!(
            "Found artifact: {}. Pushing to {}",
            artifact_path_str, image_ref
        );

        let mut push_args = vec!["push", &image_ref, &artifact_path_str];
        if config.registry_insecure {
            push_args.push("--insecure");
        }

        run_wash_command(&push_args, Some(project.directory()), config)
            .await
            .with_context(|| format!("Failed to push artifact: {}", artifact_path_str))?;
        artifacts_pushed += 1;
    }

    if artifacts_pushed == 0 {
        warn!(
            "No component/provider artifacts found in {} for {}",
            build_output_dir.display(),
            project.directory().display()
        );
    }

    info!("Finished pushing artifacts for project: {}", project);
    Ok(())
}
