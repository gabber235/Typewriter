//! The change under review: the working tree against a base commit, read through git. The working
//! tree, not `HEAD`, so an agent can review before committing and CI reviews its checkout.

use std::collections::{BTreeMap, HashSet};
use std::fs;
use std::io::{BufRead, BufReader, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::thread;

use anyhow::{Context as _, Result, anyhow, bail};
use serde::Serialize;

use crate::{CommandExt, Context};

/// The ref a change is compared with when no `--base` is given: the repository's default branch.
const DEFAULT_BASE: &str = "origin/HEAD";

/// Legacy references that are read, never changed (AGENTS.md), so neither indexed nor reviewed.
const LEGACY: &[&str] = &["engine/", "extensions/", "module-plugin/", "app/"];

#[derive(Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Status {
    Added,
    Modified,
    Deleted,
}

impl Status {
    pub fn sign(self) -> char {
        match self {
            Self::Added => '+',
            Self::Modified => '~',
            Self::Deleted => '-',
        }
    }
}

pub struct FileChange {
    pub path: PathBuf,
    /// The base path of a moved file, which is compared with that path.
    pub from: Option<PathBuf>,
    pub status: Status,
    /// Working tree lines the change added or rewrote, 1 based and ascending.
    pub added: Vec<u32>,
}

pub struct Change {
    /// The full commit hash the working tree is compared with.
    pub base: String,
    pub files: Vec<FileChange>,
}

impl Change {
    /// The change from the merge base of `HEAD` and `base` (default [`DEFAULT_BASE`]) to the
    /// working tree, including untracked files that are not ignored.
    pub fn load(ctx: &Context, base: Option<&str>) -> Result<Self> {
        let base = self::base(ctx, base)?;
        let output = git(
            ctx,
            &[
                "diff",
                "--no-color",
                "--no-ext-diff",
                "--find-renames",
                "-U0",
            ],
        )
        .arg(&base)
        .output()
        .context("cannot start git diff")?;
        if !output.status.success() {
            bail!("git diff {base} failed with {}", output.status);
        }
        // Only paths and hunk headers are read; content lines may be in any encoding, and a
        // binary file is a changed file without hunks.
        let diff = String::from_utf8_lossy(&output.stdout);
        let mut files = parse_diff(&diff);
        let untracked =
            git(ctx, &["ls-files", "-z", "--others", "--exclude-standard"]).output_text()?;
        for path in untracked.split('\0').filter(|path| !path.is_empty()) {
            let lines =
                fs::read_to_string(ctx.root.join(path)).map_or(0, |text| text.lines().count());
            files.push(FileChange {
                path: PathBuf::from(path),
                from: None,
                status: Status::Added,
                added: (1..=lines as u32).collect(),
            });
        }
        // A deleted file that Git now ignores is generated output that left version control,
        // not removed code.
        let ignored = ignored(
            ctx,
            files
                .iter()
                .filter(|file| file.status == Status::Deleted)
                .map(|file| &file.path),
        )?;
        files.retain(|file| reviewed(&file.path) && !ignored.contains(&file.path));
        files.sort_by(|a, b| a.path.cmp(&b.path));
        Ok(Self { base, files })
    }

    pub fn file(&self, path: &Path) -> Option<&FileChange> {
        self.files.iter().find(|file| file.path == path)
    }

    /// The base path of the working tree file `path`: where it was before a move.
    pub fn base_path<'a>(&'a self, path: &'a Path) -> &'a Path {
        self.file(path)
            .and_then(|file| file.from.as_deref())
            .unwrap_or(path)
    }

    /// Whether the change added or rewrote `line` of the working tree file `path`.
    pub fn touches(&self, path: &Path, line: u32) -> bool {
        self.file(path)
            .is_some_and(|file| file.added.binary_search(&line).is_ok())
    }

    /// Whether the change added or rewrote any working tree line of `path` in `from..=to`.
    pub fn touches_range(&self, path: &Path, from: u32, to: u32) -> bool {
        self.file(path)
            .is_some_and(|file| file.added.iter().any(|line| (from..=to).contains(line)))
    }

    /// The short form of the base commit, for output.
    pub fn short_base(&self) -> &str {
        &self.base[..self.base.len().min(9)]
    }
}

/// Whether `path` is project code rather than a legacy reference.
pub fn reviewed(path: &Path) -> bool {
    let path = path.to_string_lossy();
    !LEGACY.iter().any(|prefix| path.starts_with(prefix))
}

/// Which of `paths` Git ignores.
fn ignored<'a>(
    ctx: &Context,
    paths: impl Iterator<Item = &'a PathBuf>,
) -> Result<HashSet<PathBuf>> {
    let input: String = paths.map(|path| format!("{}\0", path.display())).collect();
    if input.is_empty() {
        return Ok(HashSet::new());
    }
    let mut child = git(ctx, &["check-ignore", "--no-index", "-z", "--stdin"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .context("cannot start git check-ignore")?;
    let mut stdin = child
        .stdin
        .take()
        .ok_or_else(|| anyhow!("git check-ignore has no stdin"))?;
    let writer = thread::spawn(move || stdin.write_all(input.as_bytes()));
    let output = child.wait_with_output()?;
    writer
        .join()
        .map_err(|_| anyhow!("the git check-ignore writer panicked"))??;
    // Exit status 1 means none is ignored.
    if !matches!(output.status.code(), Some(0 | 1)) {
        bail!("git check-ignore failed with {}", output.status);
    }
    Ok(String::from_utf8_lossy(&output.stdout)
        .split('\0')
        .filter(|path| !path.is_empty())
        .map(PathBuf::from)
        .collect())
}

/// `git args` in the repository root.
pub fn git(ctx: &Context, args: &[&str]) -> Command {
    let mut command = ctx.tool(".", "git", &["-c", "core.quotePath=false"]);
    command.args(args);
    command
}

/// The commit a change is compared with: the merge base of `HEAD` and `base`, by default
/// [`DEFAULT_BASE`].
pub fn base(ctx: &Context, base: Option<&str>) -> Result<String> {
    merge_base(ctx, base.unwrap_or(DEFAULT_BASE))
}

/// The full hash of the merge base of `HEAD` and `reference`.
fn merge_base(ctx: &Context, reference: &str) -> Result<String> {
    let base = git(ctx, &["merge-base", "HEAD", reference])
        .output_text()
        .with_context(|| {
            format!("cannot find the merge base of HEAD and {reference}; pass --base")
        })?;
    Ok(base.trim().to_string())
}

/// The full hash of `reference`.
pub fn commit(ctx: &Context, reference: &str) -> Result<String> {
    let hash = git(
        ctx,
        &["rev-parse", "--verify", &format!("{reference}^{{commit}}")],
    )
    .output_text()?;
    Ok(hash.trim().to_string())
}

/// Every reviewed file at `commit` whose path passes `wanted`, with its contents.
pub fn files_at(
    ctx: &Context,
    commit: &str,
    wanted: impl Fn(&Path) -> bool,
) -> Result<BTreeMap<PathBuf, String>> {
    let listing = git(ctx, &["ls-tree", "-r", "-z", "--full-tree", commit]).output_text()?;
    let mut paths = Vec::new();
    let mut objects = String::new();
    for entry in listing.split('\0').filter(|entry| !entry.is_empty()) {
        let Some((meta, path)) = entry.split_once('\t') else {
            continue;
        };
        let mut fields = meta.split(' ');
        let (Some(_mode), Some("blob"), Some(object)) =
            (fields.next(), fields.next(), fields.next())
        else {
            continue;
        };
        let path = PathBuf::from(path);
        if reviewed(&path) && wanted(&path) {
            objects.push_str(object);
            objects.push('\n');
            paths.push(path);
        }
    }
    let blobs = cat_blobs(ctx, objects)?;
    Ok(paths
        .into_iter()
        .zip(blobs)
        .filter_map(|(path, blob)| Some((path, String::from_utf8(blob).ok()?)))
        .collect())
}

/// The path of every reviewed file at `commit`, of any type.
pub fn paths_at(ctx: &Context, commit: &str) -> Result<Vec<PathBuf>> {
    let listing = git(
        ctx,
        &["ls-tree", "-r", "-z", "--name-only", "--full-tree", commit],
    )
    .output_text()?;
    Ok(listing
        .split('\0')
        .map(PathBuf::from)
        .filter(|path| !path.as_os_str().is_empty() && reviewed(path))
        .collect())
}

/// The path of every reviewed file of the working tree, of any type: tracked or untracked, not
/// ignored, and present on disk (a deletion not yet staged is gone).
pub fn working_paths(ctx: &Context) -> Result<Vec<PathBuf>> {
    let listing = git(
        ctx,
        &[
            "ls-files",
            "-z",
            "--cached",
            "--others",
            "--exclude-standard",
        ],
    )
    .output_text()?;
    let mut paths: Vec<PathBuf> = listing
        .split('\0')
        .map(PathBuf::from)
        .filter(|path| {
            !path.as_os_str().is_empty() && reviewed(path) && ctx.root.join(path).exists()
        })
        .collect();
    paths.sort();
    paths.dedup();
    Ok(paths)
}

/// The legacy reference prefixes as Git pathspecs that exclude them.
pub fn legacy_excludes() -> impl Iterator<Item = String> {
    LEGACY.iter().map(|prefix| format!(":(exclude){prefix}"))
}

/// Every reviewed file of the working tree (tracked or untracked, not ignored, plus the generated
/// sources `.ignore` re-includes) whose path passes `wanted`, with its contents. Generated code
/// calls handwritten code, so references from it count.
pub fn working_files(
    ctx: &Context,
    wanted: impl Fn(&Path) -> bool,
) -> Result<BTreeMap<PathBuf, String>> {
    let mut listing = git(
        ctx,
        &[
            "ls-files",
            "-z",
            "--cached",
            "--others",
            "--exclude-standard",
        ],
    )
    .output_text()?;
    let generated = generated_pathspecs(ctx)?;
    if !generated.is_empty() {
        let mut command = git(
            ctx,
            &[
                "ls-files",
                "-z",
                "--others",
                "--ignored",
                "--exclude-standard",
                "--",
            ],
        );
        listing.push_str(&command.args(&generated).output_text()?);
    }
    Ok(listing
        .split('\0')
        .map(PathBuf::from)
        .filter(|path| !path.as_os_str().is_empty() && reviewed(path) && wanted(path))
        .filter_map(|path| {
            let text = fs::read_to_string(ctx.root.join(&path)).ok()?;
            Some((path, text))
        })
        .collect())
}

/// The generated source paths `.ignore` re-includes for search (`!pattern` lines), as Git glob
/// pathspecs.
fn generated_pathspecs(ctx: &Context) -> Result<Vec<String>> {
    let path = ctx.root.join(".ignore");
    let text = match fs::read_to_string(&path) {
        Ok(text) => text,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(Vec::new()),
        Err(error) => return Err(error).with_context(|| format!("cannot read {}", path.display())),
    };
    Ok(text
        .lines()
        .filter_map(|line| line.trim().strip_prefix('!'))
        .map(|pattern| {
            let pattern = pattern.trim_start_matches('/');
            match pattern.strip_suffix('/') {
                Some(directory) => format!(":(glob){directory}/**"),
                None => format!(":(glob){pattern}"),
            }
        })
        .collect())
}

/// The contents of `path` at `commit`, or `None` when it did not exist there.
pub fn file_at(ctx: &Context, commit: &str, path: &Path) -> Result<Option<String>> {
    let output = git(ctx, &["show"])
        .arg(format!("{commit}:{}", path.display()))
        .stderr(Stdio::null())
        .output()
        .context("cannot start git")?;
    Ok(output
        .status
        .success()
        .then(|| String::from_utf8_lossy(&output.stdout).into_owned()))
}

/// Reads the blobs named one per line in `objects` through a single `git cat-file --batch`.
fn cat_blobs(ctx: &Context, objects: String) -> Result<Vec<Vec<u8>>> {
    let mut child = git(ctx, &["cat-file", "--batch"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .context("cannot start git cat-file")?;
    let mut stdin = child
        .stdin
        .take()
        .ok_or_else(|| anyhow!("git cat-file has no stdin"))?;
    let count = objects.lines().count();
    // Written from its own thread: git blocks on a full stdout while we would block on stdin.
    let writer = thread::spawn(move || stdin.write_all(objects.as_bytes()));
    let mut reader = BufReader::new(
        child
            .stdout
            .take()
            .ok_or_else(|| anyhow!("git cat-file has no stdout"))?,
    );
    let mut blobs = Vec::with_capacity(count);
    let mut header = String::new();
    for _ in 0..count {
        header.clear();
        reader.read_line(&mut header)?;
        let size = header
            .trim_end()
            .rsplit(' ')
            .next()
            .and_then(|size| size.parse::<usize>().ok())
            .ok_or_else(|| anyhow!("git cat-file printed {header:?}"))?;
        let mut blob = vec![0; size + 1];
        reader.read_exact(&mut blob)?;
        blob.pop();
        blobs.push(blob);
    }
    writer
        .join()
        .map_err(|_| anyhow!("the git cat-file writer panicked"))??;
    if !child.wait()?.success() {
        bail!("git cat-file failed");
    }
    Ok(blobs)
}

/// The files and line numbers of a `git diff -U0`.
fn parse_diff(diff: &str) -> Vec<FileChange> {
    let mut files: Vec<FileChange> = Vec::new();
    for line in diff.lines() {
        if let Some(paths) = line.strip_prefix("diff --git ") {
            // `a/<path> b/<path>` with the same path twice; a move names both paths on its
            // `rename from` and `rename to` lines instead.
            let path = paths.get(2..paths.len().div_ceil(2) - 1).unwrap_or(paths);
            files.push(FileChange {
                path: PathBuf::from(path),
                from: None,
                status: Status::Modified,
                added: Vec::new(),
            });
            continue;
        }
        let Some(file) = files.last_mut() else {
            continue;
        };
        if let Some(from) = line.strip_prefix("rename from ") {
            file.from = Some(PathBuf::from(from));
        } else if let Some(to) = line.strip_prefix("rename to ") {
            file.path = PathBuf::from(to);
        } else if line.starts_with("new file mode") {
            file.status = Status::Added;
        } else if line.starts_with("deleted file mode") {
            file.status = Status::Deleted;
        } else if let Some(hunk) = line.strip_prefix("@@ -") {
            // `@@ -<base range> +<working tree range> @@`
            let added = hunk
                .split(' ')
                .nth(1)
                .and_then(|range| range.strip_prefix('+'))
                .map(parse_range);
            if let Some((start, count)) = added {
                file.added.extend(start..start + count);
            }
        }
    }
    files
}

/// `start,count` or `start` (count 1) from a hunk header.
fn parse_range(range: &str) -> (u32, u32) {
    let (start, count) = range.split_once(',').unwrap_or((range, "1"));
    (start.parse().unwrap_or(0), count.parse().unwrap_or(0))
}
