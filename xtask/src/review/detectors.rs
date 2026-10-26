//! Each detector maps one way agent written code goes wrong to findings on changed lines. Entities
//! and their structure come from the shared index; project rules come from ast-grep. Cheap and
//! unambiguous detectors gate (`review gate`, the `quality` step); the rest flag lines for the
//! reviewer.

use std::collections::HashMap;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, anyhow, bail};
use serde::Deserialize;

use super::change::Status;
use super::index::{Entity, EntityKind};
use super::report::{ChangeContext, Finding, Severity};
use crate::Context;

pub const API_SURFACE: &str = "api-surface";

/// Shortest copy that counts as a clone, in meaningful lines.
const CLONE_LINES: usize = 8;

/// Name parts that mark a second version of a concept rather than a new one.
const VERSION_MARKERS: &[&str] = &[
    "new", "old", "legacy", "next", "alt", "better", "improved", "fixed", "temp", "tmp",
];

/// Shortest concept a version marker comparison considers, so `copyOf` and `of` do not pair.
const CONCEPT_LENGTH: usize = 4;

pub struct Detector {
    pub name: &'static str,
    pub run: fn(&Context, &ChangeContext) -> Result<Vec<Finding>>,
    /// Part of `review gate`, the `quality` step of `cargo xtask check`.
    pub gate: bool,
}

pub const DETECTORS: &[Detector] = &[
    // Swallowed errors, silent fallbacks, disabled tests: project rules (ast-grep).
    Detector {
        name: "rules",
        run: rules,
        gate: true,
    },
    // Copy and paste: any new clone of 8 or more lines.
    Detector {
        name: "duplication",
        run: new_clones,
        gate: true,
    },
    // Patch stacking: existing functions that gained branches.
    Detector {
        name: "branch-growth",
        run: branch_growth,
        gate: false,
    },
    // Parallel abstractions: a new type or function named like an existing one (FooV2, NewFoo, LegacyFoo).
    Detector {
        name: "parallel-concept",
        run: similar_names,
        gate: false,
    },
    // Dead additions: new entities nothing references.
    Detector {
        name: "unreferenced",
        run: without_dependents,
        gate: false,
    },
    // Contract changes: public declarations removed or with a changed signature.
    Detector {
        name: API_SURFACE,
        run: public_api_diff,
        gate: false,
    },
];

/// One ast-grep match.
#[derive(Deserialize)]
pub struct RuleMatch {
    pub file: PathBuf,
    pub range: RuleRange,
    #[serde(rename = "ruleId")]
    pub rule: String,
    pub severity: String,
    pub message: String,
    pub note: Option<String>,
}

#[derive(Deserialize)]
pub struct RuleRange {
    pub start: RulePosition,
    pub end: RulePosition,
}

#[derive(Deserialize)]
pub struct RulePosition {
    /// 0 based.
    pub line: u32,
}

/// The project rules (sgconfig.yml) over `files`.
pub fn scan_rules(ctx: &Context, files: &[&Path]) -> Result<Vec<RuleMatch>> {
    if files.is_empty() {
        return Ok(Vec::new());
    }
    let output = ctx
        .tool(".", "ast-grep", &["scan", "--json=stream"])
        .args(files)
        .output()
        .context("cannot start ast-grep; it is part of the devenv shell")?;
    // ast-grep exits with 1 when a rule of error severity matched; the matches are the result.
    if !matches!(output.status.code(), Some(0 | 1)) {
        bail!(
            "ast-grep scan failed with {}: {}",
            output.status,
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }
    let output = String::from_utf8_lossy(&output.stdout);
    output
        .lines()
        .filter(|line| !line.is_empty())
        .map(|line| {
            serde_json::from_str(line).map_err(|error| anyhow!("ast-grep printed {line}: {error}"))
        })
        .collect()
}

fn rules(ctx: &Context, change: &ChangeContext) -> Result<Vec<Finding>> {
    let files: Vec<&Path> = change
        .change
        .files
        .iter()
        .filter(|file| file.status != Status::Deleted)
        .map(|file| file.path.as_path())
        .collect();
    Ok(scan_rules(ctx, &files)?
        .into_iter()
        .filter(|hit| {
            change
                .change
                .touches_range(&hit.file, hit.range.start.line + 1, hit.range.end.line + 1)
        })
        .map(|hit| Finding {
            detector: "rules",
            line: hit.range.start.line + 1,
            message: format!("{}: {}", hit.rule, hit.message),
            fix: hit
                .note
                .unwrap_or_else(|| "Follow the rule's message.".to_string()),
            severity: if hit.severity == "error" {
                Severity::Gate
            } else {
                Severity::Flag
            },
            file: hit.file,
        })
        .collect())
}

/// Windows of [`CLONE_LINES`] meaningful lines in added code that also occur elsewhere at head.
fn new_clones(_: &Context, change: &ChangeContext) -> Result<Vec<Finding>> {
    let mut seen: HashMap<u64, Vec<(&Path, u32)>> = HashMap::new();
    let mut windows_of = HashMap::new();
    for (path, source) in &change.head.files {
        let windows = windows(&source.text, change.head.in_file(path));
        for &(hash, line) in &windows {
            seen.entry(hash).or_default().push((path, line));
        }
        windows_of.insert(path.as_path(), windows);
    }
    let mut findings: Vec<Finding> = Vec::new();
    for file in &change.change.files {
        let Some(windows) = windows_of.get(file.path.as_path()) else {
            continue;
        };
        for &(hash, line) in windows {
            if !change.change.touches(&file.path, line) {
                continue;
            }
            let Some(other) = seen[&hash].iter().find(|(path, other)| {
                *path != file.path || other.abs_diff(line) >= CLONE_LINES as u32
            }) else {
                continue;
            };
            // One finding per copied block: windows that continue the previous one extend it.
            if findings.last().is_some_and(|last| {
                last.file == file.path && line.saturating_sub(last.line) < 2 * CLONE_LINES as u32
            }) {
                continue;
            }
            findings.push(Finding {
                detector: "duplication",
                file: file.path.clone(),
                line,
                message: format!(
                    "{CLONE_LINES} or more lines repeat {}:{}",
                    other.0.display(),
                    other.1
                ),
                fix: "Reuse or extract the shared code instead of copying it.".to_string(),
                severity: Severity::Gate,
            });
        }
    }
    Ok(findings)
}

/// Hashes of every run of [`CLONE_LINES`] meaningful lines, with the line each starts at.
/// Signatures of trait and interface method implementations are left out: every implementation
/// repeats the signature the contract dictates, which nobody copied.
fn windows(text: &str, entities: &[Entity]) -> Vec<(u64, u32)> {
    use std::hash::{Hash, Hasher};
    let signature = |number: u32| {
        entities.iter().any(|entity| {
            entity.kind == EntityKind::Function
                && entity.overrides
                && (entity.start..=entity.signature_end).contains(&number)
        })
    };
    let lines: Vec<(u32, &str)> = text
        .lines()
        .zip(1u32..)
        .map(|(line, number)| (number, line.trim()))
        .filter(|&(number, line)| meaningful(line) && !signature(number))
        .collect();
    lines
        .windows(CLONE_LINES)
        .map(|window| {
            let mut hasher = std::collections::hash_map::DefaultHasher::new();
            for (_, line) in window {
                line.hash(&mut hasher);
            }
            (hasher.finish(), window[0].0)
        })
        .collect()
}

/// A line that carries code: not blank, punctuation, a comment or an import.
fn meaningful(line: &str) -> bool {
    line.chars().filter(|c| c.is_alphanumeric()).count() >= 3
        && ![
            "//", "/*", "*", "#", "import ", "use ", "package ", "export ",
        ]
        .iter()
        .any(|prefix| line.starts_with(prefix))
}

/// New conditional arms inside functions that already existed at the base.
fn branch_growth(_: &Context, change: &ChangeContext) -> Result<Vec<Finding>> {
    Ok(change
        .modified()
        .filter(|(_, after)| after.kind == EntityKind::Function)
        .filter(|(before, after)| after.branches > before.branches)
        .map(|(before, after)| {
            Finding::flag(
                "branch-growth",
                after,
                format!("{} gained {} branch(es)", after.qualified, after.branches - before.branches),
                "Is this a new case of the model, or a patch on a patch? Prefer changing the model.",
            )
        })
        .collect())
}

/// New entities whose name is an existing one plus a version marker.
fn similar_names(_: &Context, change: &ChangeContext) -> Result<Vec<Finding>> {
    let mut by_concept: HashMap<String, Vec<&Entity>> = HashMap::new();
    for entity in &change.head.entities {
        if entity.kind != EntityKind::Test && !change.is_changed(entity) {
            by_concept
                .entry(concept(&entity.name))
                .or_default()
                .push(entity);
        }
    }
    let mut findings = Vec::new();
    for added in change.added().filter(|e| e.kind != EntityKind::Test) {
        let name = concept(&added.name);
        if name.len() < CONCEPT_LENGTH {
            continue;
        }
        let existing = by_concept.get(&name).into_iter().flatten().find(|other| {
            other.kind == added.kind && other.language == added.language && other.name != added.name
        });
        if let Some(existing) = existing {
            findings.push(Finding::flag(
                "parallel-concept",
                added,
                format!(
                    "{} resembles {} ({})",
                    added.qualified,
                    existing.qualified,
                    existing.location()
                ),
                "Change the existing concept and move its callers instead of adding a second one.",
            ));
        }
    }
    Ok(findings)
}

/// A name without its version markers (`FooV2`, `NewFoo`, `legacy_foo` all give `foo`); compared
/// case and separator insensitively.
pub fn concept(name: &str) -> String {
    let words = words(name);
    let marker = |word: &String| {
        VERSION_MARKERS.contains(&word.as_str())
            || word.chars().all(|c| c.is_ascii_digit())
            || (word.len() > 1
                && word.starts_with('v')
                && word[1..].chars().all(|c| c.is_ascii_digit()))
    };
    let mut kept: &[String] = &words;
    while kept.len() > 1 && marker(&kept[0]) {
        kept = &kept[1..];
    }
    while kept.len() > 1 && marker(&kept[kept.len() - 1]) {
        kept = &kept[..kept.len() - 1];
    }
    kept.concat()
}

/// The lowercase words of a camel case or snake case name; a version suffix like `V2` is a word.
pub fn words(name: &str) -> Vec<String> {
    let mut words: Vec<String> = Vec::new();
    let mut previous: Option<char> = None;
    for c in name.chars() {
        let boundary = match previous {
            None => true,
            Some(previous) => {
                c == '_'
                    || previous == '_'
                    || (c.is_uppercase() && !previous.is_uppercase())
                    || (c.is_ascii_digit()
                        && !previous.is_ascii_digit()
                        && previous != 'V'
                        && previous != 'v')
            }
        };
        if c != '_' {
            if boundary || words.is_empty() {
                words.push(String::new());
            }
            if let Some(word) = words.last_mut() {
                word.extend(c.to_lowercase());
            }
        }
        previous = Some(c);
    }
    words.retain(|word| !word.is_empty());
    words
}

/// New functions and types that nothing references, apart from entry points and overrides.
fn without_dependents(_: &Context, change: &ChangeContext) -> Result<Vec<Finding>> {
    Ok(change
        .added()
        .filter(|e| e.kind != EntityKind::Test && !e.overrides && e.name != "main")
        .filter(|e| change.head.callers_of(e).is_empty() && !change.head.is_mentioned(&e.name))
        .map(|e| {
            Finding::flag(
                "unreferenced",
                e,
                format!("nothing references {}", e.qualified),
                "Delete it, or wire it in within this change.",
            )
        })
        .collect())
}

/// Public declarations the change removed or whose signature it changed.
fn public_api_diff(_: &Context, change: &ChangeContext) -> Result<Vec<Finding>> {
    let mut findings: Vec<Finding> = change
        .modified()
        .filter(|(before, after)| {
            before.public && after.kind != EntityKind::Test && before.signature != after.signature
        })
        .map(|(before, after)| {
            Finding::flag(
                API_SURFACE,
                after,
                format!(
                    "public signature changed: `{}` was `{}`",
                    after.signature, before.signature
                ),
                "Update every consumer in this change; contracts stay on v1 before release.",
            )
        })
        .collect();
    findings.extend(
        change
            .removed()
            .filter(|e| e.public && e.kind != EntityKind::Test)
            .map(|e| {
                Finding::flag(
                    API_SURFACE,
                    e,
                    format!("public {} removed", e.qualified),
                    "Check that no consumer outside this change still needs it.",
                )
            }),
    );
    Ok(findings)
}
