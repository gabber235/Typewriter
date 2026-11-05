//! The commit convention, ported from the former commitlint configuration: a known type, a
//! subject, a header of at most 120 characters, comma separated scopes from `commit-scopes.json`,
//! and a scope for the types that list requires.

use std::collections::BTreeSet;
use std::fmt;
use std::fs;

use anyhow::{Context as _, Result, anyhow, bail, ensure};
use serde_json::Value;

use crate::{CommandExt, Context};

/// Headers git writes itself, which commitlint's default ignores let through.
const GIT_WRITTEN: &[&str] = &[
    "Merge ",
    "Revert \"",
    "fixup! ",
    "squash! ",
    "amend! ",
    "Automatic merge",
    "Auto-merged ",
];

/// Commits that belong squashed into another before a pull request merges.
const FIXUPS: &[&str] = &["fixup! ", "squash! ", "amend! "];

const TYPES: &[&str] = &[
    "feat", "fix", "docs", "style", "refactor", "perf", "test", "build", "ci", "chore", "revert",
];

const MAX_HEADER: usize = 120;

/// `commit-scopes.json`, the only list of scopes. Entries are normalized as commitlint normalized
/// them: trimmed, lowercased, whitespace runs to dashes, duplicates refused.
pub struct Scopes {
    scopes: BTreeSet<String>,
    scope_required_for_types: BTreeSet<String>,
}

impl Scopes {
    pub fn load(ctx: &Context) -> Result<Self> {
        let path = ctx.root.join("commit-scopes.json");
        let text =
            fs::read_to_string(&path).with_context(|| format!("cannot read {}", path.display()))?;
        let json: Value = serde_json::from_str(&text)
            .with_context(|| format!("{} is not JSON", path.display()))?;
        Ok(Self {
            scopes: normalized_list(&json, "scopes")?,
            scope_required_for_types: normalized_list(&json, "scopeRequiredForTypes")?,
        })
    }
}

fn normalized_list(json: &Value, field: &str) -> Result<BTreeSet<String>> {
    let values = json[field]
        .as_array()
        .ok_or_else(|| anyhow!("commit-scopes.json must contain a {field} array"))?;
    let mut set = BTreeSet::new();
    let mut duplicates = BTreeSet::new();
    for value in values {
        let raw = value
            .as_str()
            .ok_or_else(|| anyhow!("commit-scopes.json {field} must contain only strings"))?;
        let normalized = raw
            .split_whitespace()
            .collect::<Vec<_>>()
            .join("-")
            .to_lowercase();
        if normalized.is_empty() {
            continue;
        }
        if !set.insert(normalized.clone()) {
            duplicates.insert(normalized);
        }
    }
    ensure!(
        duplicates.is_empty(),
        "commit-scopes.json {field} contains duplicates: {}",
        duplicates.into_iter().collect::<Vec<_>>().join(", ")
    );
    Ok(set)
}

/// `type(scope, scope)!: subject`
struct ConventionalHeader<'a> {
    kind: &'a str,
    scopes: Vec<&'a str>,
    subject: &'a str,
}

impl<'a> ConventionalHeader<'a> {
    fn parse(header: &'a str) -> Result<Self, CommitError> {
        let (prefix, subject) = header
            .split_once(": ")
            .ok_or(CommitError::NotConventional)?;
        let prefix = prefix.strip_suffix('!').unwrap_or(prefix);
        let (kind, scopes) = match prefix.split_once('(') {
            Some((kind, rest)) => (
                kind,
                rest.strip_suffix(')')
                    .ok_or(CommitError::NotConventional)?
                    .split(',')
                    .map(str::trim)
                    .filter(|scope| !scope.is_empty())
                    .collect(),
            ),
            None => (prefix, Vec::new()),
        };
        if kind.is_empty() || kind.contains(char::is_whitespace) {
            return Err(CommitError::NotConventional);
        }
        Ok(Self {
            kind,
            scopes,
            subject: subject.trim(),
        })
    }
}

enum CommitError {
    NotConventional,
    TooLong(usize),
    UnknownType(String),
    EmptySubject,
    UnknownScopes {
        unknown: Vec<String>,
        allowed: String,
    },
    ScopeRequired(String),
}

impl fmt::Display for CommitError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::NotConventional => write!(f, "not `type(scope): subject`"),
            Self::TooLong(length) => {
                write!(f, "header is {length} characters, at most {MAX_HEADER}")
            }
            Self::UnknownType(kind) => {
                write!(f, "unknown type: {kind}. Allowed: {}", TYPES.join(", "))
            }
            Self::EmptySubject => write!(f, "subject is empty"),
            Self::UnknownScopes { unknown, allowed } => write!(
                f,
                "unknown scope: {}. Allowed: {allowed}",
                unknown.join(", ")
            ),
            Self::ScopeRequired(kind) => write!(f, "scope is required for type {kind}"),
        }
    }
}

/// The hook: the first line that is neither a comment nor blank is the header. Comment lines,
/// including the verbose diff below git's scissors line, are skipped.
pub fn check(scopes: &Scopes, message: &str) -> Result<()> {
    let header = message
        .lines()
        .find(|line| !line.starts_with('#') && !line.trim().is_empty())
        .unwrap_or("");
    if GIT_WRITTEN.iter().any(|prefix| header.starts_with(prefix)) {
        return Ok(());
    }
    let problems = problems(scopes, header);
    if problems.is_empty() {
        return Ok(());
    }
    bail!(
        "{header}\n{}",
        problems
            .iter()
            .map(|problem| format!("  {problem}"))
            .collect::<Vec<_>>()
            .join("\n")
    )
}

fn problems(scopes: &Scopes, header: &str) -> Vec<CommitError> {
    let parsed = match ConventionalHeader::parse(header) {
        Ok(parsed) => parsed,
        Err(error) => return vec![error],
    };
    let mut problems = Vec::new();
    let length = header.chars().count();
    if length > MAX_HEADER {
        problems.push(CommitError::TooLong(length));
    }
    if !TYPES.contains(&parsed.kind) {
        problems.push(CommitError::UnknownType(parsed.kind.into()));
    }
    if parsed.subject.is_empty() {
        problems.push(CommitError::EmptySubject);
    }
    let unknown = parsed
        .scopes
        .iter()
        .filter(|scope| !scopes.scopes.contains(**scope))
        .map(|scope| scope.to_string())
        .collect::<Vec<_>>();
    if !unknown.is_empty() {
        let allowed = scopes.scopes.iter().cloned().collect::<Vec<_>>().join(", ");
        problems.push(CommitError::UnknownScopes { unknown, allowed });
    }
    if parsed.scopes.is_empty() && scopes.scope_required_for_types.contains(parsed.kind) {
        problems.push(CommitError::ScopeRequired(parsed.kind.into()));
    }
    problems
}

/// CI: every commit in the pull request, reported together. Fixup style commits are refused here
/// because they should have been squashed before merging.
pub fn check_range(ctx: &Context, range: &str) -> Result<()> {
    let scopes = Scopes::load(ctx)?;
    let log = ctx
        .tool(".", "git", &["log", "--format=%H%x00%B%x1e", range, "--"])
        .output_text()?;
    let failures = log
        .split('\x1e')
        .filter_map(|record| record.trim_start().split_once('\0'))
        .filter_map(|(sha, message)| {
            let result = if FIXUPS.iter().any(|prefix| message.starts_with(prefix)) {
                Err(anyhow!("squash this commit before merging"))
            } else {
                check(&scopes, message)
            };
            result.err().map(|error| format!("{}: {error}", &sha[..7]))
        })
        .collect::<Vec<_>>();
    ensure!(failures.is_empty(), "{}", failures.join("\n"));
    Ok(())
}
