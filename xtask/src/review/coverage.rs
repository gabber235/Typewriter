//! Changed lines no test ran. Every pull request reports them; they never gate.
//!
//! Coverage is a byproduct of the check steps, which measure while they test and write one file
//! per [`SOURCES`] entry into [`COVERAGE_DIR`]. Each file carries the commit it measured, so a
//! report never reads numbers of other code. CI downloads every job's results below
//! `.xtask/results`, so coverage is searched at any depth there, by file name.

use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result};
use serde::Serialize;

use super::change::{Change, Status, git};
use super::report::{Finding, Severity};
use crate::{CommandExt, Context};

/// Where the check steps write coverage, relative to the repository root.
pub const COVERAGE_DIR: &str = ".xtask/results/coverage";
/// Searched at any depth for coverage files.
const RESULTS: &str = ".xtask/results";
/// Next to every coverage file: the commit it measured.
const COMMIT_SUFFIX: &str = ".commit";

/// One coverage file a check step writes.
struct Source {
    file: &'static str,
    area: &'static str,
    format: Format,
    /// The folder relative source paths in the file start from.
    root: &'static str,
}

enum Format {
    Lcov,
    /// JaCoCo XML, which Kover writes: source files by package, not by path.
    Jacoco,
}

const SOURCES: &[Source] = &[
    Source {
        file: "backend.lcov",
        area: "backend",
        format: Format::Lcov,
        root: "backend",
    },
    Source {
        file: "backend-support.lcov",
        area: "backend",
        format: Format::Lcov,
        root: "backend",
    },
    Source {
        file: "panel.lcov",
        area: "panel",
        format: Format::Lcov,
        root: "panel",
    },
    Source {
        file: "panel-testkit.lcov",
        area: "panel",
        format: Format::Lcov,
        root: "panel/testkit",
    },
    Source {
        file: "panel-widgetbook.lcov",
        area: "panel",
        format: Format::Lcov,
        root: "panel/widgetbook",
    },
    Source {
        file: "services.xml",
        area: "services",
        format: Format::Jacoco,
        root: "services",
    },
];

/// The code each measured area owns: a path prefix and the source extension its tool measures.
const AREAS: &[(&str, &str, &str)] = &[
    ("backend", "backend/", "rs"),
    ("panel", "panel/", "dart"),
    ("services", "services/", "kt"),
];

#[derive(Serialize)]
pub struct Uncovered {
    pub file: PathBuf,
    pub from: u32,
    pub to: u32,
}

/// The numbers of one area the change touched.
#[derive(Serialize)]
pub struct AreaCoverage {
    pub area: String,
    /// Changed lines the coverage tool can instrument, and how many of them a test ran; absent
    /// when the area was not measured at this commit.
    pub instrumented: Option<usize>,
    pub covered: Option<usize>,
    /// Why a number is missing.
    pub notes: Vec<String>,
}

#[derive(Serialize)]
pub struct Coverage {
    pub areas: Vec<AreaCoverage>,
    pub uncovered: Vec<Uncovered>,
}

impl Coverage {
    /// Reads the coverage of the current commit for the areas `change` touches.
    pub fn read(ctx: &Context, change: &Change) -> Result<Self> {
        let head = head(ctx)?;
        let mut areas = Vec::new();
        let mut uncovered = Vec::new();
        for &(area, prefix, extension) in AREAS {
            let files: Vec<_> = change
                .files
                .iter()
                .filter(|file| {
                    file.status != Status::Deleted
                        && file.path.starts_with(prefix)
                        && file.path.extension().is_some_and(|e| e == extension)
                })
                .collect();
            if files.is_empty() {
                continue;
            }
            let mut notes = Vec::new();
            let mut hits: BTreeMap<PathBuf, BTreeMap<u32, u64>> = BTreeMap::new();
            let mut measured = false;
            let mut absent = Vec::new();
            for source in SOURCES.iter().filter(|source| source.area == area) {
                match find(ctx, source.file, &head)? {
                    Found::Fresh(path) => {
                        measured = true;
                        match source.format {
                            Format::Lcov => read_lcov(ctx, &path, source.root, &mut hits)?,
                            Format::Jacoco => read_jacoco(&path, change, source.root, &mut hits)?,
                        }
                    }
                    Found::Stale => absent.push(format!("{} is from another commit", source.file)),
                    Found::Missing => absent.push(format!("no {}", source.file)),
                }
            }
            if !absent.is_empty() {
                notes.push(format!(
                    "coverage needs `cargo xtask check {area}` at this commit ({})",
                    absent.join(", ")
                ));
            }
            let (mut instrumented, mut covered) = (0, 0);
            for file in &files {
                let Some(lines) = hits.get(&file.path) else {
                    continue;
                };
                let mut missed = Vec::new();
                for line in &file.added {
                    match lines.get(line) {
                        Some(0) => {
                            instrumented += 1;
                            missed.push(*line);
                        }
                        Some(_) => {
                            instrumented += 1;
                            covered += 1;
                        }
                        None => {}
                    }
                }
                group(&file.path, &missed, &mut uncovered);
            }
            areas.push(AreaCoverage {
                area: area.to_string(),
                instrumented: measured.then_some(instrumented),
                covered: measured.then_some(covered),
                notes,
            });
        }
        Ok(Self { areas, uncovered })
    }

    pub fn findings(&self) -> Vec<Finding> {
        self.uncovered
            .iter()
            .map(|range| Finding {
                detector: "coverage",
                file: range.file.clone(),
                line: range.from,
                message: format!(
                    "lines {}-{} of changed code ran in no test",
                    range.from, range.to
                ),
                fix:
                    "Add a test that reaches this code through its requirement, or delete the code."
                        .to_string(),
                severity: Severity::Flag,
            })
            .collect()
    }

    /// One line per area, for the report.
    pub fn summary(&self) -> String {
        self.areas
            .iter()
            .map(|area| {
                let coverage = match (area.covered, area.instrumented) {
                    (Some(covered), Some(instrumented)) => {
                        format!("{covered} of {instrumented} changed lines covered")
                    }
                    _ => "coverage not measured".to_string(),
                };
                let notes = if area.notes.is_empty() {
                    String::new()
                } else {
                    format!(" ({})", area.notes.join("; "))
                };
                format!("- {}: {coverage}{notes}\n", area.area)
            })
            .collect()
    }
}

/// Merges missed lines less than four apart into ranges.
fn group(path: &Path, missed: &[u32], uncovered: &mut Vec<Uncovered>) {
    for &line in missed {
        match uncovered.last_mut() {
            Some(Uncovered { file, to, .. }) if file == path && line - *to <= 3 => *to = line,
            _ => uncovered.push(Uncovered {
                file: path.to_path_buf(),
                from: line,
                to: line,
            }),
        }
    }
}

fn head(ctx: &Context) -> Result<String> {
    Ok(git(ctx, &["rev-parse", "HEAD"])
        .output_text()?
        .trim()
        .to_string())
}

enum Found {
    Fresh(PathBuf),
    Stale,
    Missing,
}

/// The coverage file `name` that measured `head`, below [`RESULTS`] at any depth.
fn find(ctx: &Context, name: &str, head: &str) -> Result<Found> {
    let mut found = Found::Missing;
    for path in walk(&ctx.root.join(RESULTS))? {
        if path.file_name().is_some_and(|file| file == name)
            && path
                .parent()
                .and_then(Path::file_name)
                .is_some_and(|dir| dir == "coverage")
        {
            let stamp = PathBuf::from(format!("{}{COMMIT_SUFFIX}", path.display()));
            if fs::read_to_string(&stamp).is_ok_and(|commit| commit.trim() == head) {
                return Ok(Found::Fresh(path));
            }
            found = Found::Stale;
        }
    }
    Ok(found)
}

/// Records which commit the coverage file `name` measured, after its check step. The file is
/// current when the step wrote it in this run, or when the step passed without writing it: Gradle
/// skips a report whose inputs did not change, so the file still describes this code. A file a
/// failed step left over loses its stamp, so no report reads it as current.
pub fn stamp(
    ctx: &Context,
    name: &str,
    since: std::time::SystemTime,
    passed: bool,
    commit: &str,
) -> Result<()> {
    let path = ctx.root.join(COVERAGE_DIR).join(name);
    let stamp = PathBuf::from(format!("{}{COMMIT_SUFFIX}", path.display()));
    let modified = fs::metadata(&path).and_then(|metadata| metadata.modified());
    let current = match modified {
        Ok(modified) => passed || modified >= since,
        Err(_) => false,
    };
    if current {
        fs::write(&stamp, commit).with_context(|| format!("cannot write {}", stamp.display()))
    } else {
        let _ = fs::remove_file(&stamp);
        Ok(())
    }
}

fn walk(dir: &Path) -> Result<Vec<PathBuf>> {
    let mut files = Vec::new();
    let Ok(entries) = fs::read_dir(dir) else {
        return Ok(files);
    };
    for entry in entries {
        let path = entry?.path();
        if path.is_dir() {
            files.extend(walk(&path)?);
        } else {
            files.push(path);
        }
    }
    Ok(files)
}

/// The changed Kotlin files below `root`, by `package/path/File.kt`: how JaCoCo names them.
fn kotlin_sources(change: &Change, root: &str) -> BTreeMap<String, PathBuf> {
    let mut sources = BTreeMap::new();
    for file in &change.files {
        if !file.path.starts_with(root) || file.path.extension().is_none_or(|e| e != "kt") {
            continue;
        }
        let text = file.path.to_string_lossy();
        if let Some((_, package_path)) = text.split_once("/kotlin/") {
            sources.insert(package_path.to_string(), file.path.clone());
        }
    }
    sources
}

/// Adds the line hit counts of an lcov file to `hits`, keyed by repository relative path.
/// Relative source paths start at `root`; absolute ones may come from another checkout (a CI job),
/// so they are cut at their first `root` folder.
fn read_lcov(
    ctx: &Context,
    lcov: &Path,
    root: &str,
    hits: &mut BTreeMap<PathBuf, BTreeMap<u32, u64>>,
) -> Result<()> {
    let text =
        fs::read_to_string(lcov).with_context(|| format!("cannot read {}", lcov.display()))?;
    let marker = format!("/{root}/");
    let mut current: Option<PathBuf> = None;
    for line in text.lines() {
        if let Some(path) = line.strip_prefix("SF:") {
            let source = Path::new(path);
            current = Some(match source.strip_prefix(&ctx.root) {
                Ok(relative) => relative.to_path_buf(),
                Err(_) if source.is_absolute() => match path.find(&marker) {
                    Some(at) => PathBuf::from(&path[at + 1..]),
                    None => source.to_path_buf(),
                },
                Err(_) => Path::new(root).join(source),
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

/// Adds the line hits of a JaCoCo XML report to `hits` for the changed Kotlin files below `root`.
/// A line counts as run when any of its instructions ran.
fn read_jacoco(
    path: &Path,
    change: &Change,
    root: &str,
    hits: &mut BTreeMap<PathBuf, BTreeMap<u32, u64>>,
) -> Result<()> {
    let text =
        fs::read_to_string(path).with_context(|| format!("cannot read {}", path.display()))?;
    let document = roxmltree::Document::parse(&text)
        .with_context(|| format!("{} is not JaCoCo XML", path.display()))?;
    let sources = kotlin_sources(change, root);
    let seen: BTreeSet<&str> = sources.keys().map(String::as_str).collect();
    for package in document
        .descendants()
        .filter(|node| node.has_tag_name("package"))
    {
        // JaCoCo requires both names; a node without one names no source file.
        let Some(name) = package.attribute("name") else {
            continue;
        };
        for source in package
            .children()
            .filter(|node| node.has_tag_name("sourcefile"))
        {
            let Some(file) = source.attribute("name") else {
                continue;
            };
            let key = format!("{name}/{file}");
            if !seen.contains(key.as_str()) {
                continue;
            }
            let lines = hits.entry(sources[&key].clone()).or_default();
            for line in source.children().filter(|node| node.has_tag_name("line")) {
                let number = line.attribute("nr").and_then(|nr| nr.parse::<u32>().ok());
                let ran = line.attribute("ci").and_then(|ci| ci.parse::<u64>().ok());
                if let (Some(number), Some(ran)) = (number, ran) {
                    *lines.entry(number).or_default() += ran;
                }
            }
        }
    }
    Ok(())
}
