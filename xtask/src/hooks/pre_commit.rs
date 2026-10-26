//! Fast checks on what is about to be committed. Only staged files are inspected, and their staged
//! contents rather than the working tree, so a partly staged file is judged by what goes in.

use std::env;
use std::fs;
use std::io::Write as _;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::Mutex;
use std::thread;

use anyhow::{Context as _, Result, anyhow, ensure};

use crate::{CommandExt, Context, display};

pub fn check(ctx: &Context) -> Result<()> {
    let staged = staged_files(ctx, "ACMR")?;
    if staged.is_empty() {
        return Ok(());
    }

    // Generated output is ignored by Git, so a newly added ignored file was forced in. Tracked
    // files that happen to match an ignore rule were committed on purpose and stay allowed.
    let ignored = ignored_files(ctx, &staged_files(ctx, "A")?)?;
    ensure!(
        ignored.is_empty(),
        "ignored files are staged (generated output is build output), unstage them: {}",
        ignored.join(", ")
    );

    let unformatted = Mutex::new(Vec::new());
    let failures = Mutex::new(Vec::new());
    let next = Mutex::new(staged.iter().filter(|path| formatter(ctx, path).is_some()));
    let workers = thread::available_parallelism().map_or(4, usize::from);
    thread::scope(|scope| {
        for _ in 0..workers {
            scope.spawn(|| {
                loop {
                    let Some(path) = next.lock().unwrap().next() else {
                        break;
                    };
                    match is_formatted(ctx, path) {
                        Ok(true) => {}
                        Ok(false) => unformatted.lock().unwrap().push(path.clone()),
                        Err(error) => failures.lock().unwrap().push(format!("{path}: {error:#}")),
                    }
                }
            });
        }
    });
    let failures = failures.into_inner().unwrap();
    ensure!(failures.is_empty(), "{}", failures.join("\n"));
    let mut unformatted = unformatted.into_inner().unwrap();
    unformatted.sort();
    ensure!(
        unformatted.is_empty(),
        "not formatted (run rustfmt or dart format, then stage again): {}",
        unformatted.join(", ")
    );
    Ok(())
}

/// The paths in the index whose change against HEAD is one of `statuses` (`git diff
/// --diff-filter` letters), relative to the repository root. Renames count as a deletion and an
/// addition, so a file moved to a new path is added there.
fn staged_files(ctx: &Context, statuses: &str) -> Result<Vec<String>> {
    let filter = format!("--diff-filter={statuses}");
    let names = ctx
        .tool(
            ".",
            "git",
            &[
                "diff",
                "--cached",
                "--name-only",
                "--no-renames",
                &filter,
                "-z",
            ],
        )
        .output_text()?;
    Ok(names
        .split('\0')
        .filter(|name| !name.is_empty())
        .map(str::to_owned)
        .collect())
}

fn ignored_files(ctx: &Context, paths: &[String]) -> Result<Vec<String>> {
    if paths.is_empty() {
        return Ok(Vec::new());
    }
    // `--no-index`: the added paths are in the index, which would otherwise exempt them.
    let mut command = ctx.tool(".", "git", &["check-ignore", "--no-index", "-z", "--stdin"]);
    let input = paths
        .iter()
        .map(|path| format!("{path}\0"))
        .collect::<String>();
    let output = piped(&mut command, input.into_bytes())?;
    // Exit 1 means nothing is ignored.
    ensure!(
        matches!(output.status.code(), Some(0 | 1)),
        "{} failed with {}: {}",
        display(&command),
        output.status,
        String::from_utf8_lossy(&output.stderr).trim()
    );
    Ok(String::from_utf8_lossy(&output.stdout)
        .split('\0')
        .filter(|name| !name.is_empty())
        .map(str::to_owned)
        .collect())
}

/// The formatter for a path that reads source on standard input and prints it formatted.
fn formatter(ctx: &Context, path: &str) -> Option<Command> {
    match Path::new(path).extension()?.to_str()? {
        "rs" => {
            // The toolchain's rustfmt sits next to the cargo running this hook, so commits from an
            // IDE outside the shell use the pinned formatter too.
            let rustfmt = env::var_os("CARGO")
                .map(PathBuf::from)
                .and_then(|cargo| cargo.parent().map(|bin| bin.join("rustfmt")))
                .filter(|rustfmt| rustfmt.is_file())
                .unwrap_or_else(|| PathBuf::from("rustfmt"));
            let file = ctx.root.join(path);
            let mut command = Command::new(rustfmt);
            command.args(["--emit", "stdout"]);
            if let Some(edition) = crate_edition(&file) {
                command.args(["--edition", &edition]);
            }
            // rustfmt finds `rustfmt.toml` from its working directory when reading stdin.
            command.current_dir(file.parent()?);
            Some(command)
        }
        "dart" => {
            // `--stdin-name` lets dart find the package's language version and page width.
            let mut command = ctx.tool(".", "dart", &["format", "--output=show"]);
            command.arg(format!("--stdin-name={path}"));
            Some(command)
        }
        _ => None,
    }
}

fn is_formatted(ctx: &Context, path: &str) -> Result<bool> {
    let staged = ctx
        .tool(".", "git", &["cat-file", "blob", &format!(":{path}")])
        .output_text()?;
    let mut command = formatter(ctx, path).expect("only formattable paths are queued");
    let output = piped(&mut command, staged.clone().into_bytes())?;
    ensure!(
        output.status.success(),
        "{} failed with {}: {}",
        display(&command),
        output.status,
        String::from_utf8_lossy(&output.stderr).trim()
    );
    Ok(output.stdout == staged.as_bytes())
}

/// The edition of the crate owning `file`: the first `edition = "..."` in the nearest Cargo.toml
/// upward, which reaches the workspace manifest for crates that inherit it.
fn crate_edition(file: &Path) -> Option<String> {
    file.ancestors().skip(1).find_map(|dir| {
        let manifest = fs::read_to_string(dir.join("Cargo.toml")).ok()?;
        manifest.lines().find_map(|line| {
            let value = line.trim().strip_prefix("edition")?.trim_start();
            Some(value.strip_prefix('=')?.trim().trim_matches('"').to_owned())
        })
    })
}

/// Runs `command` with `input` on standard input, capturing its output. The input is written from
/// a thread so a child that prints before it finishes reading cannot deadlock.
fn piped(command: &mut Command, input: Vec<u8>) -> Result<std::process::Output> {
    let mut child = command
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .with_context(|| format!("cannot start {}; enter `devenv shell`", display(command)))?;
    let mut stdin = child
        .stdin
        .take()
        .ok_or_else(|| anyhow!("no stdin for {}", display(command)))?;
    let writer = thread::spawn(move || stdin.write_all(&input));
    let output = child.wait_with_output()?;
    writer
        .join()
        .map_err(|_| anyhow!("stdin writer panicked"))?
        .with_context(|| format!("cannot write to {}", display(command)))?;
    Ok(output)
}
