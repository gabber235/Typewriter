//! What the change did to tests and to the harness that judges them. Test tampering hides every
//! other failure, so each weakening is listed by name, never summarized away.

use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::Result;
use serde::Serialize;

use super::change::Status;
use super::index::{EntityKind, Language};
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
    "rule-tests/",
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
    /// Removed tests whose assertions the change's other tests all make now: a move, a rename or a
    /// split. Named so a reviewer can look, but not suspect like [`Self::deleted`].
    pub moved: Vec<TestRef>,
    /// Removed tests with at least one assertion no other test took over, and removed tests with
    /// no assertions to compare.
    pub deleted: Vec<TestRef>,
    /// Assertions that left tests still there and that the change's other tests make now.
    pub assertions_moved: usize,
    /// Tests that still exist with fewer assertions than before, and whose lost assertions no test
    /// the change touched makes now.
    pub weakened: Vec<Weakened>,
    /// Tests that still exist with as many assertions as before, some in different words. Text
    /// cannot tell whether a rewrite is weaker, so a reviewer reads these.
    pub rewritten: Vec<Weakened>,
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
    let mut gained = GainedAssertions::default();
    for test in change.added().filter(|e| tests(e.kind)) {
        gained.add(test.language, &test.assertions);
    }
    let mut lost = Vec::new();
    for (before, after) in change.modified().filter(|(_, after)| tests(after.kind)) {
        let (removed, new) = difference(&before.assertions, &after.assertions);
        gained.add(after.language, &new);
        if !removed.is_empty() {
            lost.push((before, after, removed));
        }
    }
    let mut weakened = Vec::new();
    let mut rewritten = Vec::new();
    let mut assertions_moved = 0;
    for (before, after, removed) in lost {
        let total = removed.len();
        let removed: Vec<String> = removed
            .into_iter()
            .filter(|assertion| !gained.take(after.language, assertion))
            .collect();
        assertions_moved += total - removed.len();
        if removed.is_empty() {
            continue;
        }
        let list = if after.assertions.len() < before.assertions.len() {
            &mut weakened
        } else {
            &mut rewritten
        };
        list.push(Weakened {
            test: reference(after),
            removed,
        });
    }
    let (moved, deleted) = change
        .removed()
        .filter(|e| tests(e.kind))
        .partition::<Vec<_>, _>(|test| gained.take_all(test.language, &test.assertions));
    let moved = moved.into_iter().map(reference).collect();
    let deleted = deleted.into_iter().map(reference).collect();
    let mut disabled = Vec::new();
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
        moved,
        deleted,
        assertions_moved,
        weakened,
        rewritten,
        disabled,
        expectations_rewritten,
        harness_edits,
    })
}

/// What `before` has that `after` lacks and what `after` has that `before` lacks, counting copies.
fn difference(before: &[String], after: &[String]) -> (Vec<String>, Vec<String>) {
    let mut new = after.to_vec();
    let removed = before
        .iter()
        .filter(
            |assertion| match new.iter().position(|kept| kept == *assertion) {
                Some(position) => {
                    new.swap_remove(position);
                    false
                }
                None => true,
            },
        )
        .cloned()
        .collect();
    (removed, new)
}

/// The assertions tests gained in the change, as written, each copy usable once. A test review
/// renames and splits tests, so an assertion that left one test often lives on in another.
#[derive(Default)]
struct GainedAssertions(HashMap<(Language, String), usize>);

impl GainedAssertions {
    fn add(&mut self, language: Language, assertions: &[String]) {
        for assertion in assertions {
            *self.0.entry((language, assertion.clone())).or_default() += 1;
        }
    }

    /// Uses one gained copy of `assertion`, if one is left.
    fn take(&mut self, language: Language, assertion: &str) -> bool {
        match self.0.get_mut(&(language, assertion.to_owned())) {
            Some(count) if *count > 0 => {
                *count -= 1;
                true
            }
            _ => false,
        }
    }

    /// Uses one gained copy of every one of `assertions` if all are left, and none otherwise. A
    /// test without assertions shows nothing to carry over, so it never counts as taken.
    fn take_all(&mut self, language: Language, assertions: &[String]) -> bool {
        let mut needed: HashMap<String, usize> = HashMap::new();
        for assertion in assertions {
            *needed.entry(assertion.clone()).or_default() += 1;
        }
        let enough = needed.into_iter().all(|(assertion, count)| {
            self.0
                .get(&(language, assertion))
                .is_some_and(|gained| *gained >= count)
        });
        if assertions.is_empty() || !enough {
            return false;
        }
        for assertion in assertions {
            self.take(language, assertion);
        }
        true
    }
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

#[cfg(test)]
mod carried_over {
    use super::*;

    #[test]
    fn a_removed_test_whose_assertions_all_live_on_counts_as_moved() {
        let mut gained = GainedAssertions::default();
        gained.add(Language::Rust, &["a", "b", "c"].map(String::from));
        assert!(gained.take_all(Language::Rust, &["a", "b"].map(String::from)));
    }

    #[test]
    fn a_removed_test_with_one_assertion_gone_keeps_every_assertion_available() {
        let mut gained = GainedAssertions::default();
        gained.add(Language::Rust, &["a"].map(String::from));
        assert!(!gained.take_all(Language::Rust, &["a", "b"].map(String::from)));
        assert!(gained.take(Language::Rust, "a"));
    }

    #[test]
    fn a_gained_assertion_carries_over_only_one_lost_copy() {
        let mut gained = GainedAssertions::default();
        gained.add(Language::Rust, &["a"].map(String::from));
        assert!(gained.take(Language::Rust, "a"));
        assert!(!gained.take(Language::Rust, "a"));
    }

    #[test]
    fn two_lost_copies_need_two_gained_copies() {
        let mut gained = GainedAssertions::default();
        gained.add(Language::Rust, &["a"].map(String::from));
        assert!(!gained.take_all(Language::Rust, &["a", "a"].map(String::from)));
    }

    #[test]
    fn a_removed_test_without_assertions_never_counts_as_moved() {
        let mut gained = GainedAssertions::default();
        gained.add(Language::Rust, &["a"].map(String::from));
        assert!(!gained.take_all(Language::Rust, &[]));
    }

    #[test]
    fn an_assertion_in_another_language_carries_nothing_over() {
        let mut gained = GainedAssertions::default();
        gained.add(Language::Rust, &["a"].map(String::from));
        assert!(!gained.take(Language::Dart, "a"));
    }

    #[test]
    fn difference_counts_copies_on_both_sides() {
        let (removed, new) = difference(
            &["a", "a", "b"].map(String::from),
            &["a", "c"].map(String::from),
        );
        assert_eq!(removed, ["a", "b"]);
        assert_eq!(new, ["c"]);
    }
}
