//! Everything known about a change before anyone reads it: its shape over every file type, the
//! change map, detector findings on changed lines, test changes, run health and risk. Built by
//! `cargo xtask review report`; leaves as compact markdown for the reviewer and as SARIF for code
//! scanning.

use std::collections::{BTreeMap, HashSet};
use std::fmt::Write as _;
use std::path::{Path, PathBuf};

use anyhow::Result;
use serde::Serialize;

use super::SARIF;
use super::change::{self, Change, Status};
use super::coverage::Coverage;
use super::detectors::{self, DETECTORS};
use super::index::{Entity, EntityKind, Language, Snapshot};
use super::tests::{self, TestChanges};
use crate::Context;
use crate::evidence::RESULTS;
use crate::evidence::publish::listed;
use crate::results::{self, Outcome};

/// How many entities of the ranked change map the markdown lists.
const CHANGE_MAP_LINES: usize = 20;

/// How many files without entities (configuration, workflows, docs) the markdown lists.
const OTHER_FILE_LINES: usize = 40;

/// The area of files at the repository root.
const ROOT_AREA: &str = "(root)";

/// The change and both snapshots, which every detector reads.
pub struct ChangeContext {
    pub change: Change,
    pub base: Snapshot,
    pub head: Snapshot,
    pub change_map: Vec<EntityChange>,
    /// Head entity indexes the change map names.
    changed: HashSet<usize>,
}

impl ChangeContext {
    pub fn load(ctx: &Context, base: Option<&str>) -> Result<Self> {
        let change = Change::load(ctx, base)?;
        let base = Snapshot::at(ctx, &change.base)?;
        let head = Snapshot::head(ctx)?;
        let change_map = change_map(&change, &base, &head);
        let changed = change_map.iter().filter_map(|entry| entry.head).collect();
        Ok(Self {
            change,
            base,
            head,
            change_map,
            changed,
        })
    }

    pub fn modified(&self) -> impl Iterator<Item = (&Entity, &Entity)> {
        self.change_map
            .iter()
            .filter_map(|entry| match (entry.change, entry.base, entry.head) {
                (EntityChangeKind::Modified, Some(base), Some(head)) => {
                    Some((&self.base.entities[base], &self.head.entities[head]))
                }
                _ => None,
            })
    }

    pub fn added(&self) -> impl Iterator<Item = &Entity> {
        self.change_map
            .iter()
            .filter_map(|entry| match (entry.change, entry.head) {
                (EntityChangeKind::Added, Some(head)) => Some(&self.head.entities[head]),
                _ => None,
            })
    }

    pub fn removed(&self) -> impl Iterator<Item = &Entity> {
        self.change_map
            .iter()
            .filter_map(|entry| match (entry.change, entry.base) {
                (EntityChangeKind::Removed, Some(base)) => Some(&self.base.entities[base]),
                _ => None,
            })
    }

    /// Whether `entity` (of the head snapshot) is part of the change.
    pub fn is_changed(&self, entity: &Entity) -> bool {
        self.head
            .index_of(entity)
            .is_some_and(|index| self.changed.contains(&index))
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum EntityChangeKind {
    Added,
    Removed,
    Modified,
}

impl EntityChangeKind {
    pub fn sign(self) -> char {
        match self {
            Self::Added => '+',
            Self::Removed => '-',
            Self::Modified => '~',
        }
    }
}

/// One function, type or test the change added, removed or changed.
#[derive(Clone, Serialize)]
pub struct EntityChange {
    pub change: EntityChangeKind,
    pub qualified: String,
    pub kind: EntityKind,
    pub file: PathBuf,
    pub line: u32,
    /// Lines of the entity the change added, rewrote or removed.
    pub changed_lines: usize,
    #[serde(skip)]
    pub base: Option<usize>,
    #[serde(skip)]
    pub head: Option<usize>,
}

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Severity {
    Gate,
    Flag,
}

/// A detector hit on a changed line, with the hint that says what to do about it.
#[derive(Serialize)]
pub struct Finding {
    pub detector: &'static str,
    pub file: PathBuf,
    pub line: u32,
    pub message: String,
    pub fix: String,
    pub severity: Severity,
}

impl Finding {
    pub fn flag(detector: &'static str, entity: &Entity, message: String, fix: &str) -> Self {
        Self {
            detector,
            file: entity.file.clone(),
            line: entity.start,
            message,
            fix: fix.to_string(),
            severity: Severity::Flag,
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum RiskLevel {
    Low,
    Medium,
    High,
}

#[derive(Serialize)]
pub struct Risk {
    pub level: RiskLevel,
    pub because: Vec<String>,
}

/// Cases from every `TestRun` that passed only partly: reported, not gating.
#[derive(Default, Serialize)]
pub struct RunHealth {
    pub runs: usize,
    pub flaky: Vec<String>,
    pub quarantined: Vec<String>,
    /// Case and milliseconds over its budget.
    pub over_budget: Vec<(String, i64)>,
}

/// What the change did to one top level directory, counted in files of every type.
#[derive(Serialize)]
pub struct Area {
    pub area: String,
    pub added: usize,
    pub modified: usize,
    pub deleted: usize,
}

/// A directory that exists at only one end of the change: a system it removed or introduced.
#[derive(Serialize)]
pub struct System {
    pub path: PathBuf,
    pub files: usize,
}

/// One changed file of any type.
#[derive(Serialize)]
pub struct ShapeFile {
    pub path: PathBuf,
    pub from: Option<PathBuf>,
    pub status: Status,
    /// Whether the change map covers it with entities.
    pub code: bool,
}

/// The change over every file type: what a reviewer looks at before any entity.
#[derive(Serialize)]
pub struct ChangeShape {
    pub areas: Vec<Area>,
    /// Outermost directories present at base and gone at head.
    pub systems_deleted: Vec<System>,
    /// Outermost directories present at head and absent at base.
    pub systems_added: Vec<System>,
    pub files: Vec<ShapeFile>,
}

impl ChangeShape {
    fn build(ctx: &Context, change: &Change) -> Result<Self> {
        let mut areas: BTreeMap<String, Area> = BTreeMap::new();
        for file in &change.files {
            let name = area(&file.path);
            let area = areas.entry(name.clone()).or_insert_with(|| Area {
                area: name,
                added: 0,
                modified: 0,
                deleted: 0,
            });
            match file.status {
                Status::Added => area.added += 1,
                Status::Modified => area.modified += 1,
                Status::Deleted => area.deleted += 1,
            }
        }
        // Only paths the change removed or created can form a system; both ends of a move count.
        let removed: Vec<PathBuf> = change
            .files
            .iter()
            .filter_map(|file| match (file.status, &file.from) {
                (Status::Deleted, _) => Some(file.path.clone()),
                (_, Some(from)) => Some(from.clone()),
                _ => None,
            })
            .collect();
        let created: Vec<PathBuf> = change
            .files
            .iter()
            .filter(|file| file.status == Status::Added || file.from.is_some())
            .map(|file| file.path.clone())
            .collect();
        let base = change::paths_at(ctx, &change.base)?;
        let head = change::working_paths(ctx)?;
        Ok(Self {
            areas: areas.into_values().collect(),
            systems_deleted: systems(&removed, &head),
            systems_added: systems(&created, &base),
            files: change
                .files
                .iter()
                .map(|file| ShapeFile {
                    path: file.path.clone(),
                    from: file.from.clone(),
                    status: file.status,
                    code: Language::of(&file.path).is_some(),
                })
                .collect(),
        })
    }
}

/// The top level directory of `path`, or [`ROOT_AREA`].
fn area(path: &Path) -> String {
    let mut components = path.components();
    match (components.next(), components.next()) {
        (Some(first), Some(_)) => first.as_os_str().to_string_lossy().into_owned(),
        _ => ROOT_AREA.to_string(),
    }
}

/// The outermost directories of `changed` files that hold no file at the `other` end, with how
/// many of `changed` they hold.
fn systems(changed: &[PathBuf], other: &[PathBuf]) -> Vec<System> {
    let kept: HashSet<&Path> = other
        .iter()
        .flat_map(|path| path.ancestors().skip(1))
        .collect();
    let mut gone: BTreeMap<&Path, usize> = BTreeMap::new();
    for path in changed {
        let outermost = path
            .ancestors()
            .skip(1)
            .filter(|directory| !directory.as_os_str().is_empty() && !kept.contains(directory))
            .last();
        if let Some(directory) = outermost {
            *gone.entry(directory).or_default() += 1;
        }
    }
    gone.into_iter()
        .map(|(path, files)| System {
            path: path.to_path_buf(),
            files,
        })
        .collect()
}

/// Everything known about a change before anyone reads it. Built by `cargo xtask review report`.
#[derive(Serialize)]
pub struct ChangeReport {
    pub base: String,
    pub risk: Risk,
    /// Files of every type per area, and the systems the change deleted and added.
    pub shape: ChangeShape,
    /// Functions, types and tests added, removed or changed, riskiest first.
    pub change_map: Vec<EntityChange>,
    /// Detector hits on changed lines only; exported as SARIF.
    pub findings: Vec<Finding>,
    pub tests: TestChanges,
    /// Flaky, quarantined and over budget cases from every `TestRun`.
    pub health: RunHealth,
    /// Coverage of the changed lines, per area.
    pub coverage: Coverage,
}

impl ChangeReport {
    pub fn build(ctx: &Context, change: &ChangeContext) -> Result<Self> {
        let mut findings = Vec::new();
        for detector in DETECTORS {
            findings.extend((detector.run)(ctx, change)?);
        }
        let coverage = Coverage::read(ctx, &change.change)?;
        findings.extend(coverage.findings());
        findings.sort_by(|a, b| (a.severity, &a.file, a.line).cmp(&(b.severity, &b.file, b.line)));
        let tests = tests::changes(ctx, change)?;
        let health = health(ctx)?;
        let risk = risk(change, &findings, &tests);
        let mut ranked: Vec<(usize, EntityChange)> = change
            .change_map
            .iter()
            .map(|entry| (score(&change.head, entry, &findings), entry.clone()))
            .collect();
        ranked.sort_by_key(|(score, _)| std::cmp::Reverse(*score));
        Ok(Self {
            base: change.change.base.clone(),
            risk,
            shape: ChangeShape::build(ctx, &change.change)?,
            change_map: ranked.into_iter().map(|(_, entry)| entry).collect(),
            findings,
            tests,
            health,
            coverage,
        })
    }

    /// The report as compact markdown: risk, the change shape over every file type, the ranked
    /// change map, a count of detector findings, then test changes and run health.
    pub fn markdown(&self) -> String {
        let mut out = String::new();
        let _ = writeln!(
            out,
            "# Change report against {}\n\n{} files, {} entities. Risk **{}**{}",
            &self.base[..self.base.len().min(9)],
            self.shape.files.len(),
            self.change_map.len(),
            match self.risk.level {
                RiskLevel::Low => "low",
                RiskLevel::Medium => "medium",
                RiskLevel::High => "high",
            },
            if self.risk.because.is_empty() {
                String::new()
            } else {
                format!(": {}.", self.risk.because.join("; "))
            }
        );

        self.shape_markdown(&mut out);

        let _ = writeln!(out, "\n## Change map, riskiest first\n");
        if self.change_map.is_empty() {
            let _ = writeln!(out, "No functions, types or tests changed.");
        }
        for entry in self.change_map.iter().take(CHANGE_MAP_LINES) {
            let _ = writeln!(
                out,
                "- {} {} `{}` {}:{} ({} lines)",
                entry.change.sign(),
                entry.kind.label(),
                entry.qualified,
                entry.file.display(),
                entry.line,
                entry.changed_lines
            );
        }
        if self.change_map.len() > CHANGE_MAP_LINES {
            let _ = writeln!(
                out,
                "- {} more: `cargo xtask review changes`",
                self.change_map.len() - CHANGE_MAP_LINES
            );
        }

        // Detector findings belong to the gate and code scanning; the reviewer only needs to know
        // they exist and where to read them.
        let gates = self
            .findings
            .iter()
            .filter(|f| f.severity == Severity::Gate)
            .count();
        let mut detectors: BTreeMap<&str, usize> = BTreeMap::new();
        for finding in &self.findings {
            *detectors.entry(finding.detector).or_default() += 1;
        }
        let _ = writeln!(
            out,
            "\n## Detector findings\n\n{gates} gating, {} flags on changed lines{}. Listed in `{SARIF}`; `cargo xtask review gate` prints the gating ones.",
            self.findings.len() - gates,
            if detectors.is_empty() {
                String::new()
            } else {
                format!(
                    " ({})",
                    detectors
                        .iter()
                        .map(|(detector, count)| format!("{detector} {count}"))
                        .collect::<Vec<_>>()
                        .join(", ")
                )
            }
        );

        let tests = &self.tests;
        let _ = writeln!(
            out,
            "\n## Test changes\n\nAdded {}. Deleted {}. Weakened {}. Disabled {}. Expectations rewritten {}. Harness edits {}.",
            tests.added.len(),
            tests.deleted.len(),
            tests.weakened.len(),
            tests.disabled.len(),
            tests.expectations_rewritten.len(),
            tests.harness_edits.len()
        );
        for test in &tests.deleted {
            let _ = writeln!(
                out,
                "- deleted: {} ({}:{})",
                test.name,
                test.file.display(),
                test.line
            );
        }
        for weakened in &tests.weakened {
            let _ = writeln!(
                out,
                "- weakened: {} ({}:{}), removed {}",
                weakened.test.name,
                weakened.test.file.display(),
                weakened.test.line,
                weakened
                    .removed
                    .iter()
                    .map(|assertion| format!("`{assertion}`"))
                    .collect::<Vec<_>>()
                    .join(", ")
            );
        }
        for test in &tests.disabled {
            let _ = writeln!(
                out,
                "- disabled: {} ({}:{})",
                test.name,
                test.file.display(),
                test.line
            );
        }
        for path in &tests.expectations_rewritten {
            let _ = writeln!(out, "- expectation rewritten: {}", path.display());
        }
        if !tests.harness_edits.is_empty() {
            let paths: Vec<_> = tests
                .harness_edits
                .iter()
                .map(|path| path.display().to_string())
                .collect();
            let _ = writeln!(out, "- harness edits: {}", paths.join(", "));
        }

        let health = &self.health;
        let _ = writeln!(out, "\n## Run health\n");
        if health.runs == 0 {
            let _ = writeln!(out, "No test runs in {RESULTS}.");
        } else {
            let _ = writeln!(
                out,
                "{} runs. Flaky {}{}. Quarantined {}{}. Over budget {}{}.",
                health.runs,
                health.flaky.len(),
                listed(&health.flaky),
                health.quarantined.len(),
                listed(&health.quarantined),
                health.over_budget.len(),
                listed(
                    &health
                        .over_budget
                        .iter()
                        .map(|(case, millis)| format!("{case} by {millis} ms"))
                        .collect::<Vec<_>>()
                ),
            );
        }

        if !self.coverage.areas.is_empty() {
            let _ = writeln!(out, "\n## Coverage\n\n{}", self.coverage.summary());
        }

        out
    }

    /// Files per area, the systems deleted and added, and every changed file without entities.
    fn shape_markdown(&self, out: &mut String) {
        let shape = &self.shape;
        let _ = writeln!(
            out,
            "\n## Change shape\n\n| Area | Added | Modified | Deleted |\n| --- | --- | --- | --- |"
        );
        for area in &shape.areas {
            let _ = writeln!(
                out,
                "| {} | {} | {} | {} |",
                area.area, area.added, area.modified, area.deleted
            );
        }
        for (label, systems) in [
            ("Systems deleted", &shape.systems_deleted),
            ("Systems added", &shape.systems_added),
        ] {
            let listed: Vec<String> = systems
                .iter()
                .map(|system| {
                    format!(
                        "`{}/` ({} file{})",
                        system.path.display(),
                        system.files,
                        if system.files == 1 { "" } else { "s" }
                    )
                })
                .collect();
            let _ = writeln!(
                out,
                "\n{label}: {}.",
                if listed.is_empty() {
                    "none".to_string()
                } else {
                    listed.join(", ")
                }
            );
        }
        // Deleted first: what the change removed is where leftovers start.
        let mut other: Vec<&ShapeFile> = shape.files.iter().filter(|file| !file.code).collect();
        other.sort_by_key(|file| match file.status {
            Status::Deleted => 0,
            Status::Added => 1,
            Status::Modified => 2,
        });
        if other.is_empty() {
            return;
        }
        let _ = writeln!(out, "\nFiles without entities ({}):\n", other.len());
        for file in other.iter().take(OTHER_FILE_LINES) {
            let _ = writeln!(
                out,
                "- {} {}{}",
                file.status.sign(),
                file.path.display(),
                file.from
                    .as_ref()
                    .map_or_else(String::new, |from| format!(" (from {})", from.display()))
            );
        }
        if other.len() > OTHER_FILE_LINES {
            let _ = writeln!(
                out,
                "- {} more: `cargo xtask review report --json`",
                other.len() - OTHER_FILE_LINES
            );
        }
    }
}

/// Added, removed and modified entities of every changed source file.
fn change_map(change: &Change, base: &Snapshot, head: &Snapshot) -> Vec<EntityChange> {
    let mut map = Vec::new();
    for file in &change.files {
        if Language::of(&file.path).is_none() {
            continue;
        }
        let base_path = file.from.as_deref().unwrap_or(&file.path);
        if file.status != Status::Deleted {
            for index in head.file_range(&file.path) {
                let entity = &head.entities[index];
                let changed_lines = file
                    .added
                    .iter()
                    .filter(|line| (entity.start..=entity.end).contains(*line))
                    .count();
                let entry = match base.counterpart_in(base_path, entity) {
                    None => Some((EntityChangeKind::Added, None)),
                    Some(before) if before.fingerprint != entity.fingerprint => {
                        let position = base.index_of(before);
                        Some((EntityChangeKind::Modified, position))
                    }
                    Some(_) => None,
                };
                if let Some((kind, base_index)) = entry {
                    map.push(EntityChange {
                        change: kind,
                        qualified: entity.qualified.clone(),
                        kind: entity.kind,
                        file: entity.file.clone(),
                        line: entity.start,
                        changed_lines,
                        base: base_index,
                        head: Some(index),
                    });
                }
            }
        }
        if file.status != Status::Added {
            for index in base.file_range(base_path) {
                let entity = &base.entities[index];
                if head.counterpart_in(&file.path, entity).is_none() {
                    map.push(EntityChange {
                        change: EntityChangeKind::Removed,
                        qualified: entity.qualified.clone(),
                        kind: entity.kind,
                        file: entity.file.clone(),
                        line: entity.start,
                        changed_lines: (entity.end - entity.start + 1) as usize,
                        base: Some(index),
                        head: None,
                    });
                }
            }
        }
    }
    map
}

/// How much an entity deserves a reader: findings inside it, the size of its change, and how
/// many callers depend on it.
fn score(head: &Snapshot, entry: &EntityChange, findings: &[Finding]) -> usize {
    let mut score = entry.changed_lines.min(50);
    if let Some(index) = entry.head {
        let entity = &head.entities[index];
        for finding in findings
            .iter()
            .filter(|f| f.file == entity.file && (entity.start..=entity.end).contains(&f.line))
        {
            score += match finding.severity {
                Severity::Gate => 40,
                Severity::Flag => 20,
            };
        }
        score += 2 * head.callers_of(entity).len().min(15);
    }
    score
}

fn risk(change: &ChangeContext, findings: &[Finding], tests: &TestChanges) -> Risk {
    let mut high = Vec::new();
    let mut medium = Vec::new();
    let gates = findings
        .iter()
        .filter(|f| f.severity == Severity::Gate)
        .count();
    let flags = findings.len() - gates;
    if gates > 0 {
        high.push(format!("{gates} gating findings"));
    }
    for (count, what) in [
        (tests.weakened.len(), "weakened tests"),
        (tests.deleted.len(), "deleted tests"),
        (tests.disabled.len(), "disabled tests"),
        (tests.expectations_rewritten.len(), "rewritten expectations"),
    ] {
        if count > 0 {
            high.push(format!("{count} {what}"));
        }
    }
    if flags > 0 {
        medium.push(format!("{flags} flags"));
    }
    if !tests.harness_edits.is_empty() {
        medium.push(format!(
            "{} harness files edited",
            tests.harness_edits.len()
        ));
    }
    let api = findings
        .iter()
        .filter(|f| f.detector == detectors::API_SURFACE)
        .count();
    if api > 0 {
        medium.push(format!("{api} public API changes"));
    }
    if change.change_map.len() > 30 {
        medium.push(format!("{} entities changed", change.change_map.len()));
    }
    let level = if !high.is_empty() {
        RiskLevel::High
    } else if !medium.is_empty() {
        RiskLevel::Medium
    } else {
        RiskLevel::Low
    };
    high.extend(medium);
    Risk {
        level,
        because: high,
    }
}

/// Collects the cases of every `TestRun` under [`RESULTS`] that did not plainly pass or fail.
fn health(ctx: &Context) -> Result<RunHealth> {
    let mut health = RunHealth::default();
    for (_, run) in results::read_all(&ctx.root.join(RESULTS))? {
        health.runs += 1;
        for case in run.cases {
            match case.outcome {
                Outcome::Flaky(_) => health.flaky.push(case.id),
                Outcome::Quarantined(_) => health.quarantined.push(case.id),
                Outcome::OverBudget(millis) => health.over_budget.push((case.id, millis)),
                _ => {}
            }
        }
    }
    Ok(health)
}
