//! `cargo xtask evidence stage`: the one public projection of a results folder. Actions artifacts
//! of this public repository are downloadable and the evidence branch is public, so every upload
//! and every publish reads only what this writes to [`PUBLIC`]: each `TestRun` with only its
//! published artifacts ([`ArtifactKind::published`]: clips and screenshots), their files with a
//! clip's preview, the coverage files, and the widgetbook story images below [`STORIES`]. An
//! artifact whose file is missing is left out with a warning instead of failing the step. Nothing
//! is written while any public text holds a known secret.

use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result};

use super::RESULTS;
use super::publish::{known_secrets, scrub};
use crate::Context;
use crate::results::{self, TestRun};
use crate::review::{self, COVERAGE_DIR};
use crate::skirout::base::harness::v1::test_run::ArtifactKind;

/// Where the public projection is written, relative to the repository root.
pub const PUBLIC: &str = ".xtask/public";
/// Where the widgetbook writes an image of every story variant for the pull request evidence,
/// relative to the results folder.
const STORIES: &str = "stories";

/// `cargo xtask evidence stage`: stages the results folder.
pub fn stage(ctx: &Context) -> Result<()> {
    let runs = staged(&ctx.root, Path::new(RESULTS), &known_secrets())?;
    println!("staged {} runs into {PUBLIC}", runs.len());
    Ok(())
}

/// Stages `results` (relative to `root`) into [`PUBLIC`] and returns the staged runs, read back
/// from there; the only way publish and summary read runs.
pub(super) fn staged(
    root: &Path,
    results: &Path,
    secrets: &[String],
) -> Result<Vec<(PathBuf, TestRun)>> {
    let public = root.join(PUBLIC);
    stage_into(&root.join(results), &public, secrets)?;
    results::read_all(&public)
}

/// Replaces `public` with the projection of `results`. A refusal leaves `public` absent, so an
/// upload after it finds nothing.
fn stage_into(results: &Path, public: &Path, secrets: &[String]) -> Result<()> {
    if public.exists() {
        fs::remove_dir_all(public).with_context(|| format!("cannot clear {}", public.display()))?;
    }
    // Each projected run with its path below `public`, and each file with its source and its path
    // below `public`.
    let mut runs = Vec::new();
    let mut files = Vec::new();
    for (path, mut run) in results::read_all(results)? {
        let at = path.strip_prefix(results)?.to_path_buf();
        let folder = path.parent().context("a run file without a folder")?;
        for case in &mut run.cases {
            for attempt in &mut case.attempts {
                let below = folder.join(&attempt.folder);
                attempt.artifacts.retain(|artifact| {
                    artifact.kind.published() && on_disk(&below.join(&artifact.path), &case.id)
                });
            }
        }
        let below = at.parent().unwrap_or(Path::new(""));
        for file in published_files(folder, &run) {
            files.push((folder.join(&file), below.join(&file).display().to_string()));
        }
        runs.push((at, run));
    }
    // Coverage is the check jobs' public output besides their runs.
    let coverage = Path::new(COVERAGE_DIR).strip_prefix(RESULTS)?;
    for entry in fs::read_dir(results.join(coverage)).into_iter().flatten() {
        let source = entry?.path();
        let name = source
            .file_name()
            .context("a coverage file without a name")?;
        files.push((source.clone(), coverage.join(name).display().to_string()));
    }
    // Story images keep their layout below the stories folder.
    for source in review::files_in(&results.join(STORIES))? {
        let at = source.strip_prefix(results)?.display().to_string();
        files.push((source, at));
    }
    let texts: Vec<String> = runs
        .iter()
        .map(|(_, run)| TestRun::serializer().to_json(run, skir_client::JsonFlavor::Readable))
        .collect();
    // Before anything is written: the run texts and every text file.
    scrub(&texts.join("\n"), &files, secrets)?;
    for ((at, _), text) in runs.iter().zip(&texts) {
        write_file(&public.join(at), text.as_bytes())?;
    }
    for (source, at) in &files {
        let target = public.join(at);
        create_parent(&target)?;
        fs::copy(source, &target)
            .with_context(|| format!("cannot copy {} to {}", source.display(), target.display()))?;
    }
    Ok(())
}

/// Whether the artifact file at `path` exists. A driver interrupted between writing its run file
/// and its captures can list a file it never wrote; the projection leaves that artifact out and
/// says so, so the rest of the run still reaches the public folder.
fn on_disk(path: &Path, case: &str) -> bool {
    let exists = path.exists();
    if !exists {
        eprintln!(
            "{case}: {} is listed but missing; it is left out of the public folder",
            path.display()
        );
    }
    exists
}

/// The files of `run`'s artifacts relative to its `folder` (each attempt's folder joined by
/// `results::artifacts`), each clip followed by its preview when the recorder wrote one. The one
/// place that knows a preview travels with its clip; `publish::media` reads it too.
pub(super) fn published_files(folder: &Path, run: &TestRun) -> Vec<PathBuf> {
    let mut files = Vec::new();
    for (path, artifact) in run.cases.iter().flat_map(results::artifacts) {
        if artifact.kind == ArtifactKind::Clip {
            let preview = path.with_extension("webp");
            files.push(path);
            if folder.join(&preview).exists() {
                files.push(preview);
            }
        } else {
            files.push(path);
        }
    }
    files
}

fn write_file(path: &Path, bytes: &[u8]) -> Result<()> {
    create_parent(path)?;
    fs::write(path, bytes).with_context(|| format!("cannot write {}", path.display()))
}

fn create_parent(path: &Path) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("cannot create {}", parent.display()))?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{
        TempRoot, failed, failed_attempt, files_below, raw_failed_run, run_of,
    };

    const SECRET: &str = "ghp_0123456789abcdefghij";

    #[test]
    fn a_failed_run_stages_only_its_clips_screenshots_coverage_and_run() {
        let root = TempRoot::new();
        raw_failed_run(&root, "results/panel");

        let runs = staged(&root.path(""), Path::new("results"), &[]).unwrap();

        assert_eq!(
            files_below(&root.path(PUBLIC)),
            [
                "coverage/panel.lcov",
                "coverage/panel.lcov.commit",
                "panel/attempts/1/clips/conn.mp4",
                "panel/attempts/1/clips/conn.webp",
                "panel/attempts/1/screenshots/CONN-1/failure.png",
                "panel/test_run.json",
            ]
        );
        let kinds: Vec<ArtifactKind> = runs[0].1.cases[0].attempts[0]
            .artifacts
            .iter()
            .map(|artifact| artifact.kind.clone())
            .collect();
        assert_eq!(kinds, [ArtifactKind::Clip, ArtifactKind::Screenshot]);
    }

    #[test]
    fn a_listed_screenshot_missing_on_disk_is_left_out_and_the_rest_is_staged() {
        let root = TempRoot::new();
        raw_failed_run(&root, "results/panel");
        fs::remove_file(root.path("results/panel/attempts/1/screenshots/CONN-1/failure.png"))
            .unwrap();

        let runs = staged(&root.path(""), Path::new("results"), &[]).unwrap();

        assert_eq!(
            files_below(&root.path(PUBLIC)),
            [
                "coverage/panel.lcov",
                "coverage/panel.lcov.commit",
                "panel/attempts/1/clips/conn.mp4",
                "panel/attempts/1/clips/conn.webp",
                "panel/test_run.json",
            ]
        );
        let kinds: Vec<ArtifactKind> = runs[0].1.cases[0].attempts[0]
            .artifacts
            .iter()
            .map(|artifact| artifact.kind.clone())
            .collect();
        assert_eq!(kinds, [ArtifactKind::Clip]);
    }

    #[test]
    fn story_images_reach_the_public_folder_in_their_layout() {
        let root = TempRoot::new();
        root.write("results/stories/shared/editors/text_field/dark.png", "png");
        root.write("results/stories/shared/editors/text_field/light.png", "png");

        staged(&root.path(""), Path::new("results"), &[]).unwrap();

        assert_eq!(
            files_below(&root.path(PUBLIC)),
            [
                "stories/shared/editors/text_field/dark.png",
                "stories/shared/editors/text_field/light.png",
            ]
        );
    }

    #[test]
    fn a_run_whose_failure_message_holds_a_known_secret_is_not_staged() {
        let root = TempRoot::new();
        let mut run = run_of("[CONN-1] Reconnects", vec![failed_attempt((0, 1), &[])]);
        run.cases[0].attempts[0].outcome = failed(&format!("authorization: {SECRET}"));
        results::write(&run, &root.path("results/panel/test_run.json")).unwrap();

        let error = staged(&root.path(""), Path::new("results"), &[SECRET.to_owned()]).unwrap_err();

        assert!(error.to_string().contains("contains a secret"), "{error}");
        assert!(!root.path(PUBLIC).exists());
    }

    #[test]
    fn a_crashed_suite_without_a_run_file_stages_nothing() {
        let root = TempRoot::new();
        root.write("results/panel/attempts/1/drive.log", "build failed");
        root.write("results/panel/attempts/1/run.mp4", "video");

        assert!(
            staged(&root.path(""), Path::new("results"), &[])
                .unwrap()
                .is_empty()
        );
        assert!(files_below(&root.path(PUBLIC)).is_empty());
    }
}
