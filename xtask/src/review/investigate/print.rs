//! Compact output: a few lines with file:line per answer, so checking ten suspicions costs less
//! than reading two files. `--json` prints the same facts for other tools.

use std::fmt::Write as _;

use super::inventory::{Leftovers, SiblingState, Siblings};
use super::{Callers, Changes, Forwards, History, Hunk, Impact, Neighbours, Run, Similar, Site};

/// Lists the first entries of a long answer.
const LIMIT: usize = 15;

/// Files `leftovers` lists; every one is a place to decide on, so more than [`LIMIT`].
const LEFTOVER_FILES: usize = 40;

/// Hits `leftovers` lists per file.
const LEFTOVER_HITS: usize = 3;

fn site(site: &Site) -> String {
    format!("{}:{}", site.file.display(), site.line)
}

/// One `file:line  name` line per site, aligned, at most [`LIMIT`].
fn sites<'a>(out: &mut String, sites: impl ExactSizeIterator<Item = (&'a Site, String)>) {
    let total = sites.len();
    let rows: Vec<(String, String)> = sites.take(LIMIT).map(|(s, note)| (site(s), note)).collect();
    let width = rows
        .iter()
        .map(|(location, _)| location.len())
        .max()
        .unwrap_or(0);
    for (location, note) in rows {
        let _ = writeln!(out, "  {location:<width$}  {note}");
    }
    if total > LIMIT {
        let _ = writeln!(out, "  ... {} more (--json lists all)", total - LIMIT);
    }
}

pub fn changes(changes: &Changes) -> String {
    let mut out = String::new();
    let count: usize = changes.files.values().map(Vec::len).sum();
    let _ = writeln!(
        out,
        "{count} entities in {} files against {}",
        changes.files.len(),
        changes.base
    );
    for (file, entries) in &changes.files {
        let _ = writeln!(out, "{}", file.display());
        for entry in entries {
            let _ = writeln!(
                out,
                "  {} {:<4} {:<5} {}",
                entry.change.sign(),
                entry.kind.label(),
                entry.line,
                entry.qualified
            );
        }
    }
    out
}

pub fn callers(callers: &Callers) -> String {
    let mut out = String::new();
    let _ = writeln!(
        out,
        "{}  base: {} callers  head: {} callers ({})",
        callers.target.qualified,
        callers.at_base.len(),
        callers.at_head.len(),
        callers.resolution
    );
    sites(
        &mut out,
        callers.at_head.iter().map(|s| (s, s.qualified.clone())),
    );
    out
}

pub fn similar(similar: &Similar) -> String {
    let mut out = String::new();
    let _ = writeln!(
        out,
        "{} resembles {} entities",
        similar.target.qualified,
        similar.matches.len()
    );
    sites(
        &mut out,
        similar.matches.iter().map(|m| {
            (
                &m.entity,
                format!("{}  {} callers  {}", m.entity.qualified, m.callers, m.why),
            )
        }),
    );
    out
}

pub fn forwards(forwards: &Forwards) -> String {
    match &forwards.top {
        Some((target, calls, share)) => format!(
            "{} ({})  {:.0}% of {} statements call {target} ({calls} calls)\n",
            forwards.target.qualified,
            site(&forwards.target),
            share * 100.0,
            forwards.statements
        ),
        None => format!("{} calls nothing\n", forwards.target.qualified),
    }
}

pub fn neighbours(neighbours: &Neighbours) -> String {
    let mut out = String::new();
    let _ = writeln!(
        out,
        "{}  {} untouched neighbours ({}), most patched first",
        neighbours.target.qualified,
        neighbours.neighbours.len(),
        neighbours.resolution
    );
    sites(
        &mut out,
        neighbours.neighbours.iter().map(|n| {
            let mut note = format!(
                "{} {}  {} fix commits in 90 days",
                if n.calls_target { "caller" } else { "callee" },
                n.entity.qualified,
                n.recent_fixes
            );
            if !n.findings.is_empty() {
                note.push_str(&format!("  findings: {}", n.findings.join(", ")));
            }
            (&n.entity, note)
        }),
    );
    out
}

pub fn history(history: &History) -> String {
    let mut out = String::new();
    let _ = writeln!(
        out,
        "{}  {} fix commits of {} that touched it",
        history.target.qualified,
        history.fixes.len(),
        history.commits
    );
    for commit in history.fixes.iter().take(LIMIT) {
        let _ = writeln!(out, "  {} {} {}", commit.hash, commit.date, commit.subject);
    }
    out
}

pub fn hunk(hunk: &Hunk) -> String {
    let side = |site: &Option<Site>| {
        site.as_ref()
            .map_or_else(|| "absent".to_string(), self::site)
    };
    let mut out = format!(
        "{}  base: {}  head: {}\n",
        hunk.qualified,
        side(&hunk.base),
        side(&hunk.head)
    );
    if hunk.diff.is_empty() {
        out.push_str("  unchanged\n");
    } else {
        out.push_str(&hunk.diff);
        out.push('\n');
    }
    out
}

pub fn impact(impact: &Impact) -> String {
    let mut out = String::new();
    let _ = writeln!(
        out,
        "{}  reached by {} tests ({})",
        impact.target.qualified,
        impact.tests.len(),
        impact.resolution
    );
    sites(
        &mut out,
        impact.tests.iter().map(|reach| {
            let via = if reach.via.is_empty() {
                "directly".to_string()
            } else {
                format!("via {}", reach.via.join(" > "))
            };
            (&reach.test, format!("{}  {via}", reach.test.qualified))
        }),
    );
    out
}

pub fn run(run: &Run) -> String {
    let mut out = format!(
        "{} {} ({}) in {:.1} s\n  $ {}\n",
        if run.passed { "passed" } else { "FAILED" },
        run.test.qualified,
        site(&run.test),
        run.seconds,
        run.command
    );
    for line in &run.tail {
        let _ = writeln!(out, "  {line}");
    }
    out
}

pub fn leftovers(leftovers: &Leftovers) -> String {
    let mut out = String::new();
    let width = leftovers
        .terms
        .iter()
        .map(|term| term.term.len())
        .max()
        .unwrap_or(0);
    for term in &leftovers.terms {
        let _ = writeln!(
            out,
            "{:<width$}  base {}: {} hits in {} files  head: {} hits in {} files  cleared {} files",
            term.term,
            leftovers.base,
            term.base_hits,
            term.base_files,
            term.head_hits,
            term.head_files,
            term.cleared.len()
        );
    }
    for file in leftovers.files.iter().take(LEFTOVER_FILES) {
        let _ = writeln!(
            out,
            "{:<9}  {}",
            if file.touched { "changed" } else { "untouched" },
            file.path.display()
        );
        for hit in file.hits.iter().take(LEFTOVER_HITS) {
            let _ = writeln!(out, "  {:>5}  {}  {}", hit.line, hit.term, hit.snippet);
        }
        if file.hits.len() > LEFTOVER_HITS {
            let _ = writeln!(out, "  ... {} more hits", file.hits.len() - LEFTOVER_HITS);
        }
    }
    if leftovers.files.len() > LEFTOVER_FILES {
        let _ = writeln!(
            out,
            "... {} more files (--json lists all)",
            leftovers.files.len() - LEFTOVER_FILES
        );
    }
    out
}

pub fn siblings(siblings: &Siblings) -> String {
    let mut out = String::new();
    let count = |state: SiblingState| {
        siblings
            .files
            .iter()
            .filter(|sibling| sibling.state == state)
            .count()
    };
    let _ = writeln!(
        out,
        "{}/*{}  base {}: {} files  now: {} untouched, {} added, {} modified, {} deleted",
        siblings.directory.display(),
        siblings
            .extension
            .as_ref()
            .map_or_else(String::new, |extension| format!(".{extension}")),
        siblings.base,
        siblings.at_base,
        count(SiblingState::Untouched),
        count(SiblingState::Added),
        count(SiblingState::Modified),
        count(SiblingState::Deleted)
    );
    for sibling in &siblings.files {
        let _ = writeln!(
            out,
            "  {:<9}  {}",
            match sibling.state {
                SiblingState::Untouched => "untouched",
                SiblingState::Added => "added",
                SiblingState::Modified => "modified",
                SiblingState::Deleted => "deleted",
            },
            sibling.path.display()
        );
    }
    out
}
