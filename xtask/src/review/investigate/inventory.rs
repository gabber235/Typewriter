//! The replacement inventory: where a replaced concept still lives, in any file type, whether the
//! change touched that file or not. The diff only shows what the change did; these answers show
//! what it left behind.

use std::collections::{BTreeMap, BTreeSet};
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, bail};
use serde::Serialize;

use super::super::change::{self, Change, Status, git};
use crate::Context;

/// Characters of a matching line `leftovers` keeps.
const SNIPPET: usize = 120;

/// Every hit of one term, at base and at head.
#[derive(Serialize)]
pub struct TermHits {
    pub term: String,
    pub base_hits: usize,
    pub base_files: usize,
    pub head_hits: usize,
    pub head_files: usize,
    /// Files that matched at base and match no more: what the change removed.
    pub cleared: Vec<PathBuf>,
}

#[derive(Serialize)]
pub struct Hit {
    pub term: String,
    pub line: u32,
    pub snippet: String,
}

/// A file at head that still names a term.
#[derive(Serialize)]
pub struct FileHits {
    pub path: PathBuf,
    /// Whether the change added, modified or moved this file.
    pub touched: bool,
    pub hits: Vec<Hit>,
}

#[derive(Serialize)]
pub struct Leftovers {
    pub base: String,
    pub terms: Vec<TermHits>,
    /// Untouched files first: those are the ones the change never looked at.
    pub files: Vec<FileHits>,
}

#[derive(Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum SiblingState {
    Untouched,
    Added,
    Modified,
    Deleted,
}

#[derive(Serialize)]
pub struct Sibling {
    pub path: PathBuf,
    pub state: SiblingState,
}

#[derive(Serialize)]
pub struct Siblings {
    pub base: String,
    pub path: PathBuf,
    pub directory: PathBuf,
    pub extension: Option<String>,
    /// Files of this directory and extension at base.
    pub at_base: usize,
    /// Untouched files first, then changed ones; deleted files included.
    pub files: Vec<Sibling>,
}

/// Searches the whole repository (legacy references aside) for each term, case insensitive and in
/// every text file, at head and at base.
pub fn leftovers(ctx: &Context, terms: &[String], base: Option<&str>) -> Result<Leftovers> {
    let change = Change::load(ctx, base)?;
    let mut files: BTreeMap<PathBuf, Vec<Hit>> = BTreeMap::new();
    let mut counts = Vec::new();
    for term in terms {
        let at_base = grep_counts(ctx, term, &change.base)?;
        let mut at_head: BTreeMap<PathBuf, usize> = BTreeMap::new();
        for (path, line, text) in grep_lines(ctx, term)? {
            *at_head.entry(path.clone()).or_default() += 1;
            files.entry(path).or_default().push(Hit {
                term: term.clone(),
                line,
                snippet: snippet(&text),
            });
        }
        counts.push(TermHits {
            term: term.clone(),
            base_hits: at_base.values().sum(),
            base_files: at_base.len(),
            head_hits: at_head.values().sum(),
            head_files: at_head.len(),
            cleared: at_base
                .keys()
                .filter(|path| !at_head.contains_key(*path))
                .cloned()
                .collect(),
        });
    }
    let mut files: Vec<FileHits> = files
        .into_iter()
        .map(|(path, mut hits)| {
            hits.sort_by_key(|hit| hit.line);
            FileHits {
                touched: change.file(&path).is_some(),
                path,
                hits,
            }
        })
        .collect();
    files.sort_by(|a, b| (a.touched, &a.path).cmp(&(b.touched, &b.path)));
    Ok(Leftovers {
        base: change.short_base().to_string(),
        terms: counts,
        files,
    })
}

/// The files beside `path` with its extension, at head and deleted by the change, each with what
/// the change did to it.
pub fn siblings(ctx: &Context, path: &Path, base: Option<&str>) -> Result<Siblings> {
    let change = Change::load(ctx, base)?;
    let directory = path.parent().unwrap_or(Path::new("")).to_path_buf();
    let extension = path
        .extension()
        .map(|extension| extension.to_string_lossy().into_owned());
    let alike = |candidate: &Path| {
        candidate.parent().unwrap_or(Path::new("")) == directory
            && candidate
                .extension()
                .map(|e| e.to_string_lossy().into_owned())
                == extension
    };
    let at_base = change::paths_at(ctx, &change.base)?
        .into_iter()
        .filter(|candidate| alike(candidate))
        .count();
    let paths: BTreeSet<PathBuf> = change::working_paths(ctx)?
        .into_iter()
        .chain(change.files.iter().map(|file| file.path.clone()))
        .filter(|candidate| alike(candidate))
        .collect();
    let mut files: Vec<Sibling> = paths
        .into_iter()
        .map(|path| {
            let state = match change.file(&path).map(|file| file.status) {
                None => SiblingState::Untouched,
                Some(Status::Added) => SiblingState::Added,
                Some(Status::Modified) => SiblingState::Modified,
                Some(Status::Deleted) => SiblingState::Deleted,
            };
            Sibling { path, state }
        })
        .collect();
    files.sort_by_key(|sibling| sibling.state != SiblingState::Untouched);
    Ok(Siblings {
        base: change.short_base().to_string(),
        path: path.to_path_buf(),
        directory,
        extension,
        at_base,
        files,
    })
}

/// `git grep` for `term` as a fixed string, case insensitive, text files only, legacy references
/// excluded, at `revision` or (when `None`) in the working tree including untracked files.
fn grep(ctx: &Context, term: &str, revision: Option<&str>, extra: &[&str]) -> Result<String> {
    let mut command = git(ctx, &["grep", "-I", "-i", "-F", "-z"]);
    command.args(extra);
    if revision.is_none() {
        command.arg("--untracked");
    }
    command.arg("-e").arg(term);
    command.args(revision);
    command.arg("--").arg(".").args(change::legacy_excludes());
    let output = command.output().context("cannot start git grep")?;
    // Exit status 1 means no match.
    if !matches!(output.status.code(), Some(0 | 1)) {
        bail!(
            "git grep {term:?} failed with {}: {}",
            output.status,
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }
    Ok(String::from_utf8_lossy(&output.stdout).into_owned())
}

/// Matching lines per file at `commit`.
fn grep_counts(ctx: &Context, term: &str, commit: &str) -> Result<BTreeMap<PathBuf, usize>> {
    let output = grep(ctx, term, Some(commit), &["-c"])?;
    // `<commit>:<path>\0<count>` per line.
    Ok(output
        .lines()
        .filter_map(|line| {
            let (path, count) = line.split_once('\0')?;
            let path = path.strip_prefix(commit)?.strip_prefix(':')?;
            Some((PathBuf::from(path), count.parse().ok()?))
        })
        .collect())
}

/// Every matching line of the working tree as path, line number and text.
fn grep_lines(ctx: &Context, term: &str) -> Result<Vec<(PathBuf, u32, String)>> {
    let output = grep(ctx, term, None, &["-n"])?;
    // `<path>\0<line>\0<text>` per line.
    Ok(output
        .lines()
        .filter_map(|line| {
            let mut fields = line.splitn(3, '\0');
            let path = fields.next()?;
            let number = fields.next()?.parse().ok()?;
            Some((PathBuf::from(path), number, fields.next()?.to_string()))
        })
        .collect())
}

/// The trimmed line, cut at [`SNIPPET`] characters.
fn snippet(text: &str) -> String {
    let text = text.trim();
    match text.char_indices().nth(SNIPPET) {
        Some((end, _)) => format!("{}...", &text[..end]),
        None => text.to_string(),
    }
}
