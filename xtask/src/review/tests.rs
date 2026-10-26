//! What the change did to tests and to the harness that judges them. Test tampering hides every
//! other failure, so each weakening is listed by name, never summarized away.

use std::fs;
use std::path::{Path, PathBuf};

use anyhow::Result;
use serde::Serialize;

use super::change::Status;
use super::index::EntityKind;
use super::report::ChangeContext;
use crate::Context;

/// The quarantine file, relative to the repository root (see `results.rs`).
const QUARANTINE: &str = "harness/quarantine.toml";

/// Paths whose edits change what the gate accepts: CI, the harness, lint and detector
/// configuration, baselines and budgets.
const HARNESS: &[&str] = &[
    ".github/",
    "xtask/",
    "harness/",
    "rules/",
    "sgconfig.yml",
    "devenv.nix",
    "devenv.yaml",
    "services/config/",
    "services/build-logic/",
    "backend/clippy.toml",
    "backend/Cargo.toml",
    "panel/analysis_options.yaml",
    "panel/testkit/analysis_options.yaml",
    "panel/widgetbook/analysis_options.yaml",
];

/// Path parts that hold expected values: snapshots, goldens and fixture outputs.
const EXPECTATIONS: &[&str] = &[
    "/goldens/",
    "/__snapshots__/",
    "/snapshots/",
    "/fixtures/",
    "/testdata/",
];

#[derive(Clone, Serialize)]
pub struct TestRef {
    pub name: String,
    pub file: PathBuf,
    pub line: u32,
}

#[derive(Serialize)]
pub struct Weakened {
    pub test: TestRef,
    /// The assertions the test lost, as written at the base.
    pub removed: Vec<String>,
}

#[derive(Serialize)]
pub struct TestChanges {
    pub added: Vec<TestRef>,
    pub deleted: Vec<TestRef>,
    /// Assertions removed from tests that still exist.
    pub weakened: Vec<Weakened>,
    /// `#[ignore]`, skipped and disabled tests, and new entries in harness/quarantine.toml.
    pub disabled: Vec<TestRef>,
    /// Expected values rewritten: snapshots, goldens, fixture outputs.
    pub expectations_rewritten: Vec<PathBuf>,
    /// CI, lint, budget or test configuration edits (timeouts, retries, excludes, baselines).
    pub harness_edits: Vec<PathBuf>,
}

pub fn changes(ctx: &Context, change: &ChangeContext) -> Result<TestChanges> {
    let reference = |entity: &super::index::Entity| TestRef {
        name: entity.qualified.clone(),
        file: entity.file.clone(),
        line: entity.start,
    };
    let tests = |kind: EntityKind| kind == EntityKind::Test;
    let added = change
        .added()
        .filter(|e| tests(e.kind))
        .map(reference)
        .collect();
    let deleted = change
        .removed()
        .filter(|e| tests(e.kind))
        .map(reference)
        .collect();
    let mut weakened = Vec::new();
    let mut disabled = Vec::new();
    for (before, after) in change.modified().filter(|(_, after)| tests(after.kind)) {
        let mut remaining = after.assertions.clone();
        let removed: Vec<String> = before
            .assertions
            .iter()
            .filter(
                |assertion| match remaining.iter().position(|kept| kept == *assertion) {
                    Some(position) => {
                        remaining.swap_remove(position);
                        false
                    }
                    None => true,
                },
            )
            .cloned()
            .collect();
        if !removed.is_empty() {
            weakened.push(Weakened {
                test: reference(after),
                removed,
            });
        }
    }
    // Every test of a changed file: a Rust `#[ignore]` sits outside the function it disables.
    for after in change
        .head
        .entities
        .iter()
        .filter(|e| tests(e.kind) && e.disabled && change.change.file(&e.file).is_some())
    {
        if change
            .base
            .counterpart_in(change.change.base_path(&after.file), after)
            .is_none_or(|before| !before.disabled)
        {
            disabled.push(reference(after));
        }
    }
    disabled.extend(quarantined(ctx, change)?);

    let mut expectations_rewritten = Vec::new();
    let mut harness_edits = Vec::new();
    for file in &change.change.files {
        let path = file.path.to_string_lossy();
        if HARNESS.iter().any(|prefix| path.starts_with(prefix)) {
            harness_edits.push(file.path.clone());
        } else if file.status != Status::Added
            && !(file.from.is_some() && file.added.is_empty())
            && is_expectation(&file.path)
        {
            expectations_rewritten.push(file.path.clone());
        }
    }
    Ok(TestChanges {
        added,
        deleted,
        weakened,
        disabled,
        expectations_rewritten,
        harness_edits,
    })
}

/// The quarantine entries the change added, named by their case id.
fn quarantined(ctx: &Context, change: &ChangeContext) -> Result<Vec<TestRef>> {
    let Some(file) = change.change.file(Path::new(QUARANTINE)) else {
        return Ok(Vec::new());
    };
    let Ok(text) = fs::read_to_string(ctx.root.join(QUARANTINE)) else {
        return Ok(Vec::new());
    };
    Ok(text
        .lines()
        .zip(1u32..)
        .filter(|(_, number)| file.added.binary_search(number).is_ok())
        .filter_map(|(line, number)| {
            let (key, value) = line.split_once('=')?;
            (key.trim() == "id").then(|| TestRef {
                name: value.trim().trim_matches('"').to_string(),
                file: PathBuf::from(QUARANTINE),
                line: number,
            })
        })
        .collect())
}

fn is_expectation(path: &Path) -> bool {
    let text = format!("/{}", path.to_string_lossy());
    EXPECTATIONS.iter().any(|part| text.contains(part))
        || path
            .extension()
            .is_some_and(|extension| extension == "snap" || extension == "golden")
}
