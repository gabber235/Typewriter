use crate::config::{Config, IGNORED_PATTERNS, WATCHED_EXTENSIONS};
use crate::pipeline::rebuild_and_redeploy_all;
use crate::project::Project;
use anyhow::{Context, Result};
use itertools::Itertools;
use notify::{EventKind, RecursiveMode, event::ModifyKind, event::RenameMode};
use notify_debouncer_full::{Debouncer, new_debouncer};
use std::path::PathBuf;
use std::sync::mpsc as std_mpsc;
use std::time::Duration;
use tracing::{error, info};

fn is_relevant_change(event: &notify::Event) -> bool {
    if !matches!(
        event.kind,
        EventKind::Create(_)
            | EventKind::Modify(
                ModifyKind::Data(_)
                    | ModifyKind::Name(RenameMode::Both)
                    | ModifyKind::Name(RenameMode::To)
            )
            | EventKind::Remove(_)
    ) {
        return false;
    }

    event.paths.iter().all(|p| {
        if p.components().any(|comp| {
            let comp_str = comp.as_os_str().to_string_lossy();
            IGNORED_PATTERNS.contains(&comp_str.as_ref())
        }) {
            return false;
        }

        if let Some(ext) = p.extension() {
            let ext_str = ext.to_string_lossy();
            WATCHED_EXTENSIONS.contains(&ext_str.as_ref())
        } else {
            false
        }
    })
}

pub async fn watch_projects(
    projects: Vec<Project>,
    manifests: Vec<PathBuf>,
    config: &Config,
) -> Result<()> {
    let (tx, rx) = std_mpsc::channel();
    let mut debouncer: Debouncer<notify::RecommendedWatcher, _> =
        new_debouncer(Duration::from_millis(config.debounce_ms), None, tx)
            .context("Failed to create file watcher")?;

    for project in &projects {
        debouncer
            .watch(project.directory(), RecursiveMode::Recursive)
            .with_context(|| format!("Failed to watch project directory: {}", project))?;
    }

    info!("Watching {} projects for changes", projects.len());

    while let Ok(result) = rx.recv() {
        match result {
            Ok(events) => {
                let changed_projects = events
                    .iter()
                    .filter(|event| is_relevant_change(&event))
                    .filter_map(|event| {
                        projects.iter().find(|p| {
                            event
                                .paths
                                .iter()
                                .any(|path| path.starts_with(p.directory()))
                        })
                    })
                    .dedup()
                    .collect::<Vec<_>>();

                if changed_projects.is_empty() {
                    continue;
                }

                info!(
                    "Detected changes in files: {:?}",
                    events
                        .iter()
                        .flat_map(|e| e.paths.iter())
                        .collect::<Vec<_>>()
                );
                let changed_projects_vec: Vec<_> =
                    changed_projects.iter().map(|p| (*p).clone()).collect();

                info!(
                    "Rebuilding and redeploying {} changed project(s)",
                    changed_projects_vec.len()
                );
                if let Err(e) =
                    rebuild_and_redeploy_all(&changed_projects_vec, &manifests, config).await
                {
                    error!("Failed to rebuild and redeploy projects: {:?}", e);
                }
            }
            Err(e) => error!("Error watching files: {:?}", e),
        }
    }

    Ok(())
}
