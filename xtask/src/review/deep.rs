//! Deep analysis of a change: changed lines no test executed, and mutants of changed code that no
//! test noticed. Instrumented runs are slow, so `review deep` runs nightly and on pull requests
//! with the `deep` label, never in the gate.

use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, bail};
use serde::Serialize;

use super::change::{Change, Status, git};
use super::report::{Finding, Severity};
use crate::lock::HeavyLock;
use crate::{CommandExt, Context};

/// Where coverage and mutation outputs land, relative to the repository root.
const OUTPUT: &str = ".xtask/review";

/// The Flutter packages whose tests produce coverage, relative to the repository root.
const FLUTTER_PACKAGES: &[&str] = &["panel/testkit", "panel/widgetbook", "panel"];

#[derive(Serialize)]
pub struct Uncovered {
    pub file: PathBuf,
    pub from: u32,
    pub to: u32,
}

#[derive(Serialize)]
pub struct Survivor {
    pub file: PathBuf,
    pub line: u32,
    pub mutation: String,
}

#[derive(Serialize)]
pub struct Deep {
    pub uncovered: Vec<Uncovered>,
    pub survivors: Vec<Survivor>,
    /// Changed areas no instrument measures, with the reason.
    pub unmeasured: Vec<String>,
}

impl Deep {
    pub fn findings(&self) -> Vec<Finding> {
        let uncovered = self.uncovered.iter().map(|range| Finding {
            detector: "deep",
            file: range.file.clone(),
            line: range.from,
            message: format!(
                "lines {}-{} of changed code ran in no test",
                range.from, range.to
            ),
            fix: "Add a test that reaches this code through its requirement, or delete the code."
                .to_string(),
            severity: Severity::Flag,
        });
        let survivors = self.survivors.iter().map(|survivor| Finding {
            detector: "deep",
            file: survivor.file.clone(),
            line: survivor.line,
            message: format!("mutant survived: {}", survivor.mutation),
            fix: "A test should fail when this code changes; assert the outcome it produces."
                .to_string(),
            severity: Severity::Flag,
        });
        uncovered.chain(survivors).collect()
    }

    pub fn summary(&self) -> String {
        let files: BTreeSet<_> = self.uncovered.iter().map(|range| &range.file).collect();
        let mut summary = format!(
            "{} uncovered ranges of changed code in {} files; {} surviving mutants.",
            self.uncovered.len(),
            files.len(),
            self.survivors.len()
        );
        for reason in &self.unmeasured {
            summary.push_str(&format!(" Not measured: {reason}."));
        }
        summary
    }
}

/// Measures diff coverage of the backend (cargo llvm-cov) and the Flutter packages
/// (`flutter test --coverage`), and runs `cargo mutants --in-diff` on the backend.
pub fn analyse(ctx: &Context, change: &Change) -> Result<Deep> {
    let output = ctx.root.join(OUTPUT);
    fs::create_dir_all(&output).with_context(|| format!("cannot create {}", output.display()))?;
    let changed = |prefix: &str, extension: &str| {
        change.files.iter().any(|file| {
            file.status != Status::Deleted
                && file.path.starts_with(prefix)
                && file.path.extension().is_some_and(|e| e == extension)
        })
    };
    let _lock = HeavyLock::acquire("review deep")?;
    let mut hits = BTreeMap::new();
    let mut survivors = Vec::new();
    let mut unmeasured = Vec::new();

    if changed("backend", "rs") {
        let lcov = output.join("backend.lcov");
        ctx.tool(
            "backend",
            "cargo",
            &[
                "llvm-cov",
                "--locked",
                "--workspace",
                "--lcov",
                "--output-path",
            ],
        )
        .arg(&lcov)
        .run()?;
        read_lcov(ctx, &lcov, Path::new(""), &mut hits)?;
        survivors = mutants(ctx, change, &output)?;
    }
    for package in FLUTTER_PACKAGES {
        let claimed = |path: &Path| {
            path.starts_with(package)
                && !FLUTTER_PACKAGES.iter().any(|other| {
                    other != package && other.starts_with(package) && path.starts_with(other)
                })
        };
        if !change
            .files
            .iter()
            .any(|file| file.status != Status::Deleted && claimed(&file.path))
        {
            continue;
        }
        let lcov = output.join(format!("{}.lcov", package.replace('/', "-")));
        ctx.tool(
            package,
            "flutter",
            &["test", "--coverage", "--coverage-path"],
        )
        .arg(&lcov)
        .run()?;
        read_lcov(ctx, &lcov, Path::new(package), &mut hits)?;
    }
    if changed("services", "kt") {
        unmeasured.push("Kotlin services (Kover is not wired into the services build)".to_string());
    }

    let mut uncovered = Vec::new();
    for file in &change.files {
        let Some(lines) = hits.get(&file.path) else {
            continue;
        };
        let missed: Vec<u32> = file
            .added
            .iter()
            .copied()
            .filter(|line| lines.get(line) == Some(&0))
            .collect();
        for line in missed {
            match uncovered.last_mut() {
                Some(Uncovered { file: path, to, .. }) if *path == file.path && line - *to <= 3 => {
                    *to = line
                }
                _ => uncovered.push(Uncovered {
                    file: file.path.clone(),
                    from: line,
                    to: line,
                }),
            }
        }
    }
    Ok(Deep {
        uncovered,
        survivors,
        unmeasured,
    })
}

/// `cargo mutants` on the backend lines of the change; returns the mutants no test caught.
fn mutants(ctx: &Context, change: &Change, output: &Path) -> Result<Vec<Survivor>> {
    let diff = git(ctx, &["diff", "--relative=backend"])
        .arg(&change.base)
        .args(["--", "*.rs"])
        .output_text()?;
    let diff_file = output.join("backend.diff");
    fs::write(&diff_file, diff).with_context(|| format!("cannot write {}", diff_file.display()))?;
    let status = ctx
        .tool("backend", "cargo", &["mutants", "--in-diff"])
        .arg(&diff_file)
        .arg("--output")
        .arg(output)
        .status()
        .context("cannot start cargo mutants; is the devenv shell active?")?;
    // 2: some mutants survived; 3: some timed out. Both are results, not failures.
    if !matches!(status.code(), Some(0 | 2 | 3)) {
        bail!("cargo mutants failed with {status}");
    }
    let missed = output.join("mutants.out/missed.txt");
    let text = fs::read_to_string(&missed)
        .with_context(|| format!("cargo mutants wrote no {}", missed.display()))?;
    Ok(text
        .lines()
        .filter_map(|line| {
            // `src/lib.rs:12:5: replace foo -> bool with true`
            let (file, rest) = line.split_once(':')?;
            let (number, rest) = rest.split_once(':')?;
            let mutation = rest.split_once(": ").map_or(rest, |(_, mutation)| mutation);
            Some(Survivor {
                file: Path::new("backend").join(file),
                line: number.parse().ok()?,
                mutation: mutation.trim().to_string(),
            })
        })
        .collect())
}

/// Adds the line hit counts of an lcov file to `hits`, keyed by repository relative path.
/// Relative source paths are relative to `package`.
fn read_lcov(
    ctx: &Context,
    lcov: &Path,
    package: &Path,
    hits: &mut BTreeMap<PathBuf, BTreeMap<u32, u64>>,
) -> Result<()> {
    let text =
        fs::read_to_string(lcov).with_context(|| format!("cannot read {}", lcov.display()))?;
    let mut current: Option<PathBuf> = None;
    for line in text.lines() {
        if let Some(path) = line.strip_prefix("SF:") {
            let path = Path::new(path);
            current = Some(match path.strip_prefix(&ctx.root) {
                Ok(relative) => relative.to_path_buf(),
                Err(_) if path.is_absolute() => path.to_path_buf(),
                Err(_) => package.join(path),
            });
        } else if let (Some(file), Some(entry)) = (&current, line.strip_prefix("DA:")) {
            let mut fields = entry.split(',');
            if let (Some(Ok(number)), Some(Ok(count))) = (
                fields.next().map(str::parse::<u32>),
                fields.next().map(str::parse::<u64>),
            ) {
                *hits
                    .entry(file.clone())
                    .or_default()
                    .entry(number)
                    .or_default() += count;
            }
        } else if line == "end_of_record" {
            current = None;
        }
    }
    Ok(())
}
