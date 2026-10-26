//! Questions an agent asks about its change and the code around it: who still calls the old thing,
//! what already resembles the new thing, which neighbours keep being patched, what a test reaches.
//! Each command answers one question with facts and file:line, read from the code at base and
//! head and from history. Judgment stays with the agent; nothing here decides what is a gap.

mod print;

use std::collections::{BTreeMap, HashMap, VecDeque};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Stdio;
use std::time::Instant;

use anyhow::{Context as _, Result, anyhow, bail};
use clap::Subcommand;
use serde::Serialize;

use super::change::{self, git};
use super::detectors::{concept, scan_rules, words};
use super::index::{Entity, EntityKind, Language, Snapshot};
use super::report::{ChangeContext, EntityChange};
use crate::lock::HeavyLock;
use crate::{CommandExt, Context, Scratch, display};

/// Fix commits newer than this make a neighbour "keep being patched".
const RECENT_DAYS: u32 = 90;

/// How far `impact` follows callers before giving up on reaching a test.
const IMPACT_DEPTH: usize = 6;

/// Trailing output lines `run` prints when a test fails.
const RUN_TAIL: usize = 25;

/// Name resolution is by name, narrowed by imports; every caller list says so.
const RESOLUTION: &str = "name and imports";

#[derive(Subcommand)]
pub enum InvestigateCommand {
    /// Entities added, removed and changed, per file. The starting point.
    Changes,
    /// Who calls this at head, and who called it at base: an old concept that kept callers is still alive.
    Callers { file: PathBuf, symbol: String },
    /// Existing entities that resemble this one by name and shape, with their callers: a parallel abstraction.
    Similar { file: PathBuf, symbol: String },
    /// How much of this body is a call into one other entity: a new surface over the old model.
    Forwards { file: PathBuf, symbol: String },
    /// Untouched code the change calls or is called by, with recent fix commits and existing findings.
    Neighbours { file: PathBuf, symbol: String },
    /// Fix commits that touched this entity, newest first, with one line messages.
    History { file: PathBuf, symbol: String },
    /// One entity before and after.
    Hunk { file: PathBuf, symbol: String },
    /// Which tests reach this entity.
    Impact { file: PathBuf, symbol: String },
    /// Runs one test and prints its outcome, to check a claim instead of guessing.
    Run { test: String },
}

/// An entity as the tools print it.
#[derive(Clone, Serialize)]
pub struct Site {
    pub qualified: String,
    pub kind: EntityKind,
    pub file: PathBuf,
    pub line: u32,
}

impl Site {
    fn of(entity: &Entity) -> Self {
        Self {
            qualified: entity.qualified.clone(),
            kind: entity.kind,
            file: entity.file.clone(),
            line: entity.start,
        }
    }

    fn at(entity: &Entity, line: u32) -> Self {
        Self {
            line,
            ..Self::of(entity)
        }
    }
}

#[derive(Serialize)]
pub struct Changes {
    pub base: String,
    pub files: BTreeMap<PathBuf, Vec<EntityChange>>,
}

#[derive(Serialize)]
pub struct Callers {
    pub target: Site,
    pub resolution: &'static str,
    pub at_head: Vec<Site>,
    pub at_base: Vec<Site>,
}

#[derive(Serialize)]
pub struct Resemblance {
    pub entity: Site,
    pub callers: usize,
    /// 0 to 1: shared name words and similar size.
    pub score: f32,
    pub why: String,
}

#[derive(Serialize)]
pub struct Similar {
    pub target: Site,
    pub matches: Vec<Resemblance>,
}

#[derive(Serialize)]
pub struct Forwards {
    pub target: Site,
    pub statements: usize,
    /// The most called entity, its call count and the share of statements that call it.
    pub top: Option<(String, usize, f32)>,
}

#[derive(Serialize)]
pub struct Neighbour {
    pub entity: Site,
    /// Calls the target, or is called by it.
    pub calls_target: bool,
    pub recent_fixes: usize,
    pub findings: Vec<String>,
}

#[derive(Serialize)]
pub struct Neighbours {
    pub target: Site,
    pub resolution: &'static str,
    pub neighbours: Vec<Neighbour>,
}

#[derive(Serialize)]
pub struct Commit {
    pub hash: String,
    pub date: String,
    pub subject: String,
}

#[derive(Serialize)]
pub struct History {
    pub target: Site,
    pub commits: usize,
    pub fixes: Vec<Commit>,
}

#[derive(Serialize)]
pub struct Hunk {
    pub qualified: String,
    pub base: Option<Site>,
    pub head: Option<Site>,
    pub diff: String,
}

#[derive(Serialize)]
pub struct Reach {
    pub test: Site,
    /// Entities between the target and the test, nearest the target first.
    pub via: Vec<String>,
}

#[derive(Serialize)]
pub struct Impact {
    pub target: Site,
    pub resolution: &'static str,
    pub tests: Vec<Reach>,
}

#[derive(Serialize)]
pub struct Run {
    pub test: Site,
    pub command: String,
    pub passed: bool,
    pub seconds: f32,
    pub tail: Vec<String>,
}

/// Runs one question and prints its answer, as JSON when `json`.
pub fn run(
    ctx: &Context,
    command: InvestigateCommand,
    base: Option<&str>,
    json: bool,
) -> Result<()> {
    match command {
        InvestigateCommand::Changes => emit(json, &changes(ctx, base)?, print::changes),
        InvestigateCommand::Callers { file, symbol } => {
            emit(json, &callers(ctx, &file, &symbol, base)?, print::callers)
        }
        InvestigateCommand::Similar { file, symbol } => {
            emit(json, &similar(ctx, &file, &symbol)?, print::similar)
        }
        InvestigateCommand::Forwards { file, symbol } => {
            emit(json, &forwards(ctx, &file, &symbol)?, print::forwards)
        }
        InvestigateCommand::Neighbours { file, symbol } => emit(
            json,
            &neighbours(ctx, &file, &symbol, base)?,
            print::neighbours,
        ),
        InvestigateCommand::History { file, symbol } => {
            emit(json, &history(ctx, &file, &symbol)?, print::history)
        }
        InvestigateCommand::Hunk { file, symbol } => {
            emit(json, &hunk(ctx, &file, &symbol, base)?, print::hunk)
        }
        InvestigateCommand::Impact { file, symbol } => {
            emit(json, &impact(ctx, &file, &symbol)?, print::impact)
        }
        InvestigateCommand::Run { test } => {
            let outcome = run_test(ctx, &test)?;
            emit(json, &outcome, print::run)?;
            if !outcome.passed {
                bail!("{} failed", outcome.test.qualified);
            }
            Ok(())
        }
    }
}

fn emit<T: Serialize>(json: bool, facts: &T, print: fn(&T) -> String) -> Result<()> {
    if json {
        println!("{}", serde_json::to_string_pretty(facts)?);
    } else {
        print!("{}", print(facts));
    }
    Ok(())
}

pub fn changes(ctx: &Context, base: Option<&str>) -> Result<Changes> {
    let change = ChangeContext::load(ctx, base)?;
    let mut files: BTreeMap<PathBuf, Vec<EntityChange>> = BTreeMap::new();
    for entry in change.change_map {
        files.entry(entry.file.clone()).or_default().push(entry);
    }
    for entries in files.values_mut() {
        entries.sort_by_key(|entry| entry.line);
    }
    Ok(Changes {
        base: change.change.short_base().to_string(),
        files,
    })
}

pub fn callers(ctx: &Context, file: &Path, symbol: &str, base: Option<&str>) -> Result<Callers> {
    let base_commit = change::base(ctx, base)?;
    let head = Snapshot::head(ctx)?;
    let before = Snapshot::at(ctx, &base_commit)?;
    // The old concept may be gone at head; then its base definition names it.
    let target = head
        .find(file, symbol)
        .or_else(|| before.find(file, symbol))
        .ok_or_else(|| missing(&head, file, symbol))?;
    let sites = |snapshot: &Snapshot| {
        let mut sites: Vec<Site> = snapshot
            .callers_of(target)
            .into_iter()
            .map(|(caller, line)| Site::at(caller, line))
            .collect();
        sites.sort_by(|a, b| (&a.file, a.line).cmp(&(&b.file, b.line)));
        sites
    };
    Ok(Callers {
        target: Site::of(target),
        resolution: RESOLUTION,
        at_head: sites(&head),
        at_base: sites(&before),
    })
}

pub fn similar(ctx: &Context, file: &Path, symbol: &str) -> Result<Similar> {
    let head = Snapshot::head(ctx)?;
    let target = head
        .find(file, symbol)
        .ok_or_else(|| missing(&head, file, symbol))?;
    let target_words = words(&target.name);
    let target_concept = concept(&target.name);
    let mut matches: Vec<Resemblance> = head
        .entities
        .iter()
        .filter(|other| {
            other.language == target.language
                && other.kind == target.kind
                && !std::ptr::eq(*other, target)
                && other.qualified != target.qualified
        })
        .filter_map(|other| {
            let name = if concept(&other.name) == target_concept {
                1.0
            } else {
                jaccard(&target_words, &words(&other.name))
            };
            if name < 0.5 {
                return None;
            }
            let size = |entity: &Entity| (entity.end - entity.start + 1) as f32;
            let shape = size(target).min(size(other)) / size(target).max(size(other));
            let score = 0.7 * name + 0.3 * shape;
            (score >= 0.6).then(|| Resemblance {
                callers: head.callers_of(other).len(),
                score,
                why: format!("name {:.0}%, size {:.0}%", name * 100.0, shape * 100.0),
                entity: Site::of(other),
            })
        })
        .collect();
    matches.sort_by(|a, b| b.score.total_cmp(&a.score));
    matches.truncate(8);
    Ok(Similar {
        target: Site::of(target),
        matches,
    })
}

fn jaccard(a: &[String], b: &[String]) -> f32 {
    let shared = a.iter().filter(|word| b.contains(word)).count();
    let all = a.len() + b.len() - shared;
    if all == 0 {
        0.0
    } else {
        shared as f32 / all as f32
    }
}

pub fn forwards(ctx: &Context, file: &Path, symbol: &str) -> Result<Forwards> {
    let head = Snapshot::head(ctx)?;
    let target = head
        .find(file, symbol)
        .ok_or_else(|| missing(&head, file, symbol))?;
    // Only calls into project code: forwarding to the standard library is not a parallel model.
    let mut counts: HashMap<&str, usize> = HashMap::new();
    for call in &target.calls {
        if !head.resolve(target, call).is_empty() {
            *counts.entry(call.as_str()).or_default() += 1;
        }
    }
    let top = counts
        .into_iter()
        .max_by(|a, b| a.1.cmp(&b.1).then_with(|| b.0.cmp(a.0)))
        .map(|(name, calls)| {
            let resolved = head.resolve(target, name);
            let shown = match resolved.as_slice() {
                [only] => only.qualified.clone(),
                _ => name.to_string(),
            };
            let share = (calls as f32 / target.statements.max(1) as f32).min(1.0);
            (shown, calls, share)
        });
    Ok(Forwards {
        target: Site::of(target),
        statements: target.statements,
        top,
    })
}

pub fn neighbours(
    ctx: &Context,
    file: &Path,
    symbol: &str,
    base: Option<&str>,
) -> Result<Neighbours> {
    let change = ChangeContext::load(ctx, base)?;
    let head = &change.head;
    let target = head
        .find(file, symbol)
        .ok_or_else(|| missing(head, file, symbol))?;
    let mut found: Vec<(&Entity, bool)> = Vec::new();
    for callee in head.callees_of(target) {
        found.push((callee, false));
    }
    for (caller, _) in head.callers_of(target) {
        if !found.iter().any(|(seen, _)| std::ptr::eq(*seen, caller)) {
            found.push((caller, true));
        }
    }
    found.retain(|(entity, _)| !change.is_changed(entity));
    let files: Vec<&Path> = found
        .iter()
        .map(|(entity, _)| entity.file.as_path())
        .collect();
    let mut unique = files.clone();
    unique.sort();
    unique.dedup();
    let hits = scan_rules(ctx, &unique)?;
    let mut neighbours = Vec::new();
    for (entity, calls_target) in found {
        let findings = hits
            .iter()
            .filter(|hit| {
                hit.file == entity.file
                    && (entity.start..=entity.end).contains(&(hit.range.start.line + 1))
            })
            .map(|hit| {
                format!(
                    "{}:{} {}",
                    hit.file.display(),
                    hit.range.start.line + 1,
                    hit.rule
                )
            })
            .collect();
        let recent_fixes = fix_commits(ctx, &entity.file, entity, Some(RECENT_DAYS))?.len();
        neighbours.push(Neighbour {
            entity: Site::of(entity),
            calls_target,
            recent_fixes,
            findings,
        });
    }
    neighbours.sort_by(|a, b| {
        (b.recent_fixes, b.findings.len()).cmp(&(a.recent_fixes, a.findings.len()))
    });
    Ok(Neighbours {
        target: Site::of(target),
        resolution: RESOLUTION,
        neighbours,
    })
}

pub fn history(ctx: &Context, file: &Path, symbol: &str) -> Result<History> {
    let committed = committed_snapshot(ctx, file)?;
    // History follows committed code, so the entity is looked up as committed at HEAD.
    let target = committed
        .find(file, symbol)
        .ok_or_else(|| missing(&committed, file, symbol))?;
    let all = log_range(ctx, file, target, None)?;
    let commits = all.len();
    let fixes = all.into_iter().filter(is_fix).collect();
    Ok(History {
        target: Site::of(target),
        commits,
        fixes,
    })
}

pub fn hunk(ctx: &Context, file: &Path, symbol: &str, base: Option<&str>) -> Result<Hunk> {
    let base_commit = change::base(ctx, base)?;
    let single = |text: Option<String>| {
        Snapshot::build(
            text.map(|text| (file.to_path_buf(), text))
                .into_iter()
                .collect(),
        )
    };
    let before = single(change::file_at(ctx, &base_commit, file)?);
    let after = single(fs::read_to_string(ctx.root.join(file)).ok());
    let old = before.find(file, symbol);
    let new = after.find(file, symbol);
    let Some(either) = new.or(old) else {
        return Err(missing(&after, file, symbol));
    };
    let scratch = Scratch::new("review-hunk")?;
    let write = |name: &str, snapshot: &Snapshot, entity: Option<&Entity>| -> Result<PathBuf> {
        let path = scratch.0.join(name);
        fs::write(&path, entity.map_or("", |entity| snapshot.text(entity)))?;
        Ok(path)
    };
    let base_file = write("base", &before, old)?;
    let head_file = write("head", &after, new)?;
    // Exit status 1 means "differs"; only the text matters.
    let output = git(ctx, &["diff", "--no-index", "--no-color", "-U3"])
        .arg(&base_file)
        .arg(&head_file)
        .output()
        .context("cannot start git diff")?;
    let diff = String::from_utf8_lossy(&output.stdout)
        .lines()
        .skip_while(|line| !line.starts_with("@@"))
        .collect::<Vec<_>>()
        .join("\n");
    Ok(Hunk {
        qualified: either.qualified.clone(),
        base: old.map(Site::of),
        head: new.map(Site::of),
        diff,
    })
}

pub fn impact(ctx: &Context, file: &Path, symbol: &str) -> Result<Impact> {
    let head = Snapshot::head(ctx)?;
    let target = head
        .find(file, symbol)
        .ok_or_else(|| missing(&head, file, symbol))?;
    let start = head
        .index_of(target)
        .ok_or_else(|| anyhow!("the target is not in the index"))?;
    let mut parent: HashMap<usize, usize> = HashMap::from([(start, start)]);
    let mut queue = VecDeque::from([(start, 0)]);
    let mut tests = Vec::new();
    while let Some((current, depth)) = queue.pop_front() {
        let entity = &head.entities[current];
        if entity.kind == EntityKind::Test && current != start {
            let mut via = Vec::new();
            let mut step = parent[&current];
            while step != start {
                via.push(head.entities[step].qualified.clone());
                step = parent[&step];
            }
            via.reverse();
            tests.push(Reach {
                test: Site::of(entity),
                via,
            });
            continue;
        }
        if depth == IMPACT_DEPTH {
            continue;
        }
        for (caller, _) in head.callers_of(entity) {
            if let Some(index) = head.index_of(caller)
                && let std::collections::hash_map::Entry::Vacant(slot) = parent.entry(index)
            {
                slot.insert(current);
                queue.push_back((index, depth + 1));
            }
        }
    }
    Ok(Impact {
        target: Site::of(target),
        resolution: RESOLUTION,
        tests,
    })
}

/// Finds the test named `test` (its name or qualified name) and runs only it with its suite's
/// runner: cargo for Rust, Gradle for Kotlin, Flutter for Dart.
pub fn run_test(ctx: &Context, test: &str) -> Result<Run> {
    let head = Snapshot::head(ctx)?;
    let candidates: Vec<&Entity> = head
        .entities
        .iter()
        .filter(|e| e.kind == EntityKind::Test && (e.qualified == test || e.name == test))
        .collect();
    let entity = match candidates.as_slice() {
        [only] => *only,
        [] => bail!(
            "no test named `{test}`; `cargo xtask review impact` lists tests that reach an entity"
        ),
        many => bail!(
            "`{test}` names {} tests, pass the qualified name: {}",
            many.len(),
            many.iter()
                .map(|e| e.qualified.as_str())
                .collect::<Vec<_>>()
                .join(", ")
        ),
    };
    let mut command = test_command(ctx, entity)?;
    let shown = display(&command);
    let _lock = HeavyLock::acquire("review run")?;
    let started = Instant::now();
    let output = command
        .stdin(Stdio::null())
        .output()
        .with_context(|| format!("cannot start {shown}; is the devenv shell active?"))?;
    let text = format!(
        "{}{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    let lines: Vec<String> = text.lines().map(str::to_string).collect();
    let passed = output.status.success();
    Ok(Run {
        test: Site::of(entity),
        command: shown,
        passed,
        seconds: started.elapsed().as_secs_f32(),
        tail: if passed {
            Vec::new()
        } else {
            lines[lines.len().saturating_sub(RUN_TAIL)..].to_vec()
        },
    })
}

fn test_command(ctx: &Context, test: &Entity) -> Result<std::process::Command> {
    let package = |marker: &str| {
        test.file
            .ancestors()
            .skip(1)
            .find(|dir| ctx.root.join(dir).join(marker).is_file())
            .map(Path::to_path_buf)
            .ok_or_else(|| anyhow!("{} is in no {marker} package", test.file.display()))
    };
    Ok(match test.language {
        Language::Rust => {
            let manifest = package("Cargo.toml")?.join("Cargo.toml");
            let mut command = ctx.tool(".", "cargo", &["test", "--locked", "--manifest-path"]);
            command.arg(manifest).arg(&test.name);
            command
        }
        Language::Kotlin => {
            let project = gradle_project(ctx, &test.file)?;
            let mut command = ctx.tool(
                "services",
                "./gradlew",
                &[&format!("{project}:test"), "--quiet"],
            );
            // TestBalloon selects tests by element path; `*` matches any part of it.
            let suite = test
                .qualified
                .rsplit_once('.')
                .map_or("", |(suite, _)| suite);
            command.env(
                "TESTBALLOON_INCLUDE_PATTERNS",
                format!("*{suite}*{}", test.name),
            );
            command
        }
        Language::Dart => {
            let dir = package("pubspec.yaml")?;
            let relative = test.file.strip_prefix(&dir).unwrap_or(&test.file);
            let mut command = ctx.tool(".", "flutter", &["test", "--plain-name", &test.name]);
            command.current_dir(ctx.root.join(&dir)).arg(relative);
            command
        }
    })
}

/// The Gradle project path (`:engine-core`) whose directory holds `file`.
fn gradle_project(ctx: &Context, file: &Path) -> Result<String> {
    let settings = fs::read_to_string(ctx.root.join("services/settings.gradle.kts"))
        .context("cannot read services/settings.gradle.kts")?;
    let relative = file
        .strip_prefix("services")
        .map_err(|_| anyhow!("{} is not in services/", file.display()))?;
    settings
        .lines()
        .filter_map(|line| {
            // includeProject("engine-core", "runtime/engine/core")
            let arguments = line
                .trim()
                .strip_prefix("includeProject(")?
                .strip_suffix(')')?;
            let (name, directory) = arguments.split_once(',')?;
            Some((
                name.trim().trim_matches('"'),
                directory.trim().trim_matches('"'),
            ))
        })
        .filter(|(_, directory)| relative.starts_with(directory))
        .max_by_key(|(_, directory)| directory.len())
        .map(|(name, _)| format!(":{name}"))
        .ok_or_else(|| anyhow!("no Gradle project holds {}", file.display()))
}

/// `file` as committed at `HEAD`, indexed on its own.
fn committed_snapshot(ctx: &Context, file: &Path) -> Result<Snapshot> {
    let text = change::file_at(ctx, "HEAD", file)?
        .ok_or_else(|| anyhow!("{} is not committed", file.display()))?;
    Ok(Snapshot::build(
        [(file.to_path_buf(), text)].into_iter().collect(),
    ))
}

/// Commits that touched the lines of `entity` as committed at `HEAD`, newest first.
fn log_range(
    ctx: &Context,
    file: &Path,
    entity: &Entity,
    days: Option<u32>,
) -> Result<Vec<Commit>> {
    let mut command = git(ctx, &["log", "--no-patch", "--format=%h%x09%as%x09%s"]);
    if let Some(days) = days {
        command.arg(format!("--since={days}.days"));
    }
    let output = command
        .arg(format!(
            "-L{},{}:{}",
            entity.start,
            entity.end,
            file.display()
        ))
        .arg("HEAD")
        .output_text()?;
    Ok(output
        .lines()
        .filter_map(|line| {
            let mut fields = line.splitn(3, '\t');
            Some(Commit {
                hash: fields.next()?.to_string(),
                date: fields.next()?.to_string(),
                subject: fields.next()?.to_string(),
            })
        })
        .collect())
}

/// Fix commits within `days` that touched the committed version of `entity`; none when the
/// entity is not committed yet.
fn fix_commits(
    ctx: &Context,
    file: &Path,
    entity: &Entity,
    days: Option<u32>,
) -> Result<Vec<Commit>> {
    let committed = committed_snapshot(ctx, file).ok();
    let Some(committed) = committed
        .as_ref()
        .and_then(|snapshot| snapshot.counterpart(entity))
    else {
        return Ok(Vec::new());
    };
    Ok(log_range(ctx, file, committed, days)?
        .into_iter()
        .filter(is_fix)
        .collect())
}

/// A conventional `fix` commit, or a revert.
fn is_fix(commit: &Commit) -> bool {
    let subject = commit.subject.to_lowercase();
    subject.starts_with("fix") || subject.starts_with("revert")
}

/// The error for an unknown symbol, listing what the file does define.
fn missing(snapshot: &Snapshot, file: &Path, symbol: &str) -> anyhow::Error {
    let names: Vec<&str> = snapshot
        .entities
        .iter()
        .filter(|entity| entity.file == file)
        .map(|entity| entity.qualified.as_str())
        .take(15)
        .collect();
    if names.is_empty() {
        anyhow!(
            "{} defines no indexed entities (Rust, Kotlin and Dart are indexed)",
            file.display()
        )
    } else {
        anyhow!(
            "no `{symbol}` in {}; it defines: {}",
            file.display(),
            names.join(", ")
        )
    }
}
