//! Cargo builds reused while everything Cargo would consult is unchanged. Cargo itself judges
//! local crates by file times, so a fresh checkout recompiles every one of them even when a cached
//! target holds what they would produce. A stamp beside the artifacts records:
//!
//! - the command, with the variables it sets, and the toolchain (`rustc -vV`);
//! - Cargo's whole configuration surface: every inherited `CARGO*` and `RUST*` variable but those
//!   Cargo sets for each crate itself, and every configuration file Cargo loads (`.cargo/config.toml`
//!   and `.cargo/config` from the directory it runs in up to the file system root, then those in
//!   Cargo's home), each recorded absent while it does not exist;
//! - the workspace's manifests (path dependencies included) and lock file;
//! - the sha256 of each artifact and of everything the build read: the repository files the
//!   dependency files Cargo writes beside each artifact name (a build script's `rerun-if-changed`
//!   inputs included), the environment variables its crates read at compile time (`env!`,
//!   `option_env!`) and its build scripts watch (`rerun-if-env-changed`), and every file of a
//!   package whose build script watches nothing (Cargo runs such a script again when any of them
//!   changes).
//!
//! While all of them match, Cargo does not run at all. Files outside the repository are not
//! listed: the toolchain's sources change with `rustc -vV` and dependency sources with
//! `Cargo.lock`.
//!
//! Known issue, trusted on purpose as Cargo trusts it: a procedural macro that reads a file or a
//! variable no dependency file names (outside `include_str!`, `env!` and `proc_macro`'s tracked
//! paths) is not listed, so an edit only such a macro reads reuses the build, as Cargo would.

use std::collections::BTreeSet;
use std::fs;
use std::path::{Component, Path, PathBuf};
use std::process::Command;

use anyhow::{Context as _, Result, bail};
use serde_json::Value;

use crate::digest::{Digest, Environment, Stamp, expand};
use crate::{CommandExt as _, Context};

/// One Cargo invocation and what it produces.
pub struct CargoBuild<'a> {
    /// Names the stamp, which lies beside the first artifact as `<name>.xtask-stamp`.
    pub name: &'a str,
    /// Root relative files every build depends on although no dependency file names them: the
    /// workspace's manifests and lock file ([`workspace_files`]).
    pub workspace: Vec<String>,
    /// The absolute paths of what the build produces.
    pub artifacts: Vec<PathBuf>,
}

fn metadata(ctx: &Context, manifest: &str, deps: bool) -> Result<Value> {
    let mut args = vec!["metadata", "--format-version", "1", "--locked"];
    if !deps {
        args.push("--no-deps");
    }
    args.extend(["--manifest-path", manifest]);
    Ok(serde_json::from_str(
        &ctx.tool(".", "cargo", &args).output_text()?,
    )?)
}

/// The target directory of the Cargo workspace whose manifest is `manifest`, root relative.
pub fn target_directory(ctx: &Context, manifest: &str) -> Result<PathBuf> {
    let target = metadata(ctx, manifest, false)?["target_directory"]
        .as_str()
        .map(PathBuf::from)
        .context("cargo metadata printed no target_directory")?;
    Ok(target)
}

/// The root relative files a build in the workspace of `manifest` depends on that no dependency
/// file names: the manifest of every package in the repository it builds (path dependencies
/// outside the workspace included), and the workspace's own manifest and lock file.
pub fn workspace_files(ctx: &Context, manifest: &str) -> Result<Vec<String>> {
    let metadata = metadata(ctx, manifest, true)?;
    let workspace = metadata["workspace_root"]
        .as_str()
        .map(PathBuf::from)
        .context("cargo metadata printed no workspace_root")?;
    let mut files = vec![workspace.join("Cargo.toml"), workspace.join("Cargo.lock")];
    for package in metadata["packages"].as_array().into_iter().flatten() {
        if package["source"].is_null()
            && let Some(manifest) = package["manifest_path"].as_str()
        {
            files.push(PathBuf::from(manifest));
        }
    }
    let mut relative: Vec<String> = files
        .iter()
        .filter(|file| file.is_file())
        .filter_map(|file| file.strip_prefix(&ctx.root).ok())
        .map(|file| file.display().to_string())
        .collect();
    relative.sort();
    relative.dedup();
    Ok(relative)
}

/// Whether [`CargoBuild::run`] ran Cargo.
#[derive(Debug, PartialEq, Eq)]
pub enum Outcome {
    /// The artifacts on disk were built from what is there now; Cargo did not run.
    Reused,
    /// Cargo ran, and the artifacts are stamped with what it read unless a dependency file was
    /// missing.
    Compiled,
}

impl CargoBuild<'_> {
    /// Runs `cargo` unless its stamp records the same command and toolchain and every file it
    /// lists (the artifacts, what the last build read, the workspace files) still has the same
    /// contents, then stamps the artifacts again.
    pub fn run(&self, ctx: &Context, cargo: &mut Command, env: &Environment) -> Result<Outcome> {
        let digest = self.digest(ctx, cargo, env)?;
        let stamp = self.stamp()?;
        let artifacts = self.artifact_names();
        let configs = configs(ctx, cargo, env);
        if let Some(listed) = stamp.files(&ctx.root, &digest, env)
            && artifacts
                .iter()
                .chain(&self.workspace)
                .chain(&configs)
                .all(|file| listed.contains(file))
        {
            return Ok(Outcome::Reused);
        }
        // A build that fails leaves nothing to reuse, an artifact Cargo does not write again (a
        // renamed or dropped target) is not taken for one, and only this run's dependency files
        // say what it read.
        stamp.clear()?;
        for artifact in &self.artifacts {
            for file in [artifact.clone(), artifact.with_extension("d")] {
                match fs::remove_file(&file) {
                    Err(error) if error.kind() != std::io::ErrorKind::NotFound => {
                        return Err(error)
                            .with_context(|| format!("cannot remove {}", file.display()));
                    }
                    _ => {}
                }
            }
        }
        cargo.run()?;
        let missing: Vec<String> = self
            .artifacts
            .iter()
            .filter(|artifact| !artifact.is_file())
            .map(|artifact| artifact.display().to_string())
            .collect();
        if !missing.is_empty() {
            bail!(
                "the build {} wrote no {}; Cargo builds no target by that name",
                self.name,
                missing.join(", ")
            );
        }
        // Without a dependency file the build cannot say what it read, so it is not reused.
        let recorded = self.reads(ctx).and_then(|reads| {
            let mut files: Vec<String> = artifacts;
            files.extend(self.workspace.iter().cloned());
            files.extend(configs);
            files.extend(reads);
            files.sort();
            files.dedup();
            stamp.record(&ctx.root, &digest, &files, env)
        });
        if let Err(error) = recorded {
            eprintln!(
                "{}: no stamp, so the next run builds again: {error:#}",
                self.name
            );
        }
        Ok(Outcome::Compiled)
    }

    fn artifact_names(&self) -> Vec<String> {
        self.artifacts
            .iter()
            .map(|artifact| artifact.display().to_string())
            .collect()
    }

    fn stamp(&self) -> Result<Stamp> {
        let first = self
            .artifacts
            .first()
            .with_context(|| format!("the build {} names no artifact", self.name))?;
        let dir = first.parent().unwrap_or(Path::new("."));
        Ok(Stamp::at(dir.join(format!("{}.xtask-stamp", self.name))))
    }

    /// The digest of the command line with the variables it sets, every `CARGO*` and `RUST*`
    /// variable it inherits from `env` but those Cargo sets for each crate itself, and the
    /// toolchain's version.
    fn digest(&self, ctx: &Context, cargo: &Command, env: &Environment) -> Result<Digest> {
        let mut digest = Digest::new();
        digest.update(cargo.get_program().as_encoded_bytes());
        for arg in cargo.get_args() {
            digest.update(&[0]);
            digest.update(arg.as_encoded_bytes());
        }
        for (key, value) in cargo.get_envs() {
            digest.update(&[0]);
            digest.update(key.as_encoded_bytes());
            digest.update(&[1]);
            digest.update(
                value
                    .map(|value| value.as_encoded_bytes())
                    .unwrap_or(b"unset"),
            );
        }
        if let Some(dir) = cargo.get_current_dir() {
            digest.update(dir.as_os_str().as_encoded_bytes());
        }
        for (name, value) in env.iter() {
            if (name.starts_with("CARGO") || name.starts_with("RUST")) && !cargo_sets(name) {
                digest.update(&[0]);
                digest.update(name.as_bytes());
                digest.update(&[1]);
                digest.update(value.as_encoded_bytes());
            }
        }
        let toolchain = ctx.tool(".", "rustc", &["-vV"]).output_text()?;
        digest.update(toolchain.as_bytes());
        Ok(digest)
    }

    /// What the build read: the root relative repository files the dependency file beside each
    /// artifact names, and as `$NAME` each environment variable a crate of the build read at
    /// compile time (`env!`, `option_env!`).
    fn reads(&self, ctx: &Context) -> Result<BTreeSet<String>> {
        let mut reads = BTreeSet::new();
        for artifact in &self.artifacts {
            let dep_info = artifact.with_extension("d");
            let text = fs::read_to_string(&dep_info)
                .with_context(|| format!("cannot read {}", dep_info.display()))?;
            for file in dep_info_files(&text) {
                if let Ok(relative) = normalize(&file).strip_prefix(&ctx.root) {
                    reads.insert(relative.display().to_string());
                }
            }
        }
        let target = self.target_dir()?;
        reads.extend(env_reads(target)?.iter().map(|name| format!("${name}")));
        reads.extend(build_script_reads(ctx, target)?);
        Ok(reads)
    }

    /// The Cargo target directory the artifacts lie in, which Cargo marks with a CACHEDIR.TAG.
    fn target_dir(&self) -> Result<&Path> {
        let first = self
            .artifacts
            .first()
            .with_context(|| format!("the build {} names no artifact", self.name))?;
        first
            .ancestors()
            .find(|dir| dir.join("CACHEDIR.TAG").is_file())
            .with_context(|| format!("{} lies in no Cargo target directory", first.display()))
    }
}

/// The environment variables the crates in the Cargo target directory `target` read at compile
/// time. Cargo's copy of the dependency file beside an artifact leaves out rustc's `# env-dep:`
/// lines and names only the sources of path packages, so the variables come from every unit's own
/// dependency file in the target's build folders. That may include units of another build in the
/// same target, which costs a rebuild when their variables change, never a stale artifact. The
/// variables Cargo sets for every crate itself are left out: they follow from the command and the
/// workspace.
fn env_reads(target: &Path) -> Result<BTreeSet<String>> {
    let mut names = BTreeSet::new();
    for dir in unit_dirs(target, &["out", "deps"])? {
        for (path, name) in files_in(&dir)? {
            if name.ends_with(".d") {
                names.extend(env_deps(&read(&path)?));
            }
        }
    }
    Ok(names)
}

/// What the build scripts that ran in `target` read, decided the way Cargo decides to run one
/// again, from what each printed: `$NAME` for each `rerun-if-env-changed`, and for a script that
/// printed no `rerun-if-changed` or `rerun-if-env-changed` line, every file of its package.
/// (Its `rerun-if-changed` files are in the dependency files beside the artifacts already.)
fn build_script_reads(ctx: &Context, target: &Path) -> Result<BTreeSet<String>> {
    let mut reads = BTreeSet::new();
    for run in unit_dirs(target, &["run"])? {
        let mut watches = false;
        for line in read(&run.join("stdout"))?.lines() {
            let Some(directive) = line
                .strip_prefix("cargo::")
                .or_else(|| line.strip_prefix("cargo:"))
            else {
                continue;
            };
            if let Some(name) = directive.strip_prefix("rerun-if-env-changed=") {
                reads.insert(format!("${name}"));
                watches = true;
            } else if directive.starts_with("rerun-if-changed=") {
                watches = true;
            }
        }
        if !watches {
            for dir in script_packages(ctx, &run)? {
                package_files(ctx, &dir, &mut reads)?;
            }
        }
    }
    Ok(reads)
}

/// The repository folders of the packages whose build script ran in `run`
/// (`build/<package>/<hash>/run`): each holds a `Cargo.toml` above a build script source that a
/// compile unit of the same package, `build/<package>/<other hash>/out/build_script_build*.d`,
/// names.
fn script_packages(ctx: &Context, run: &Path) -> Result<BTreeSet<PathBuf>> {
    let mut packages = BTreeSet::new();
    let Some(package) = run.parent().and_then(Path::parent) else {
        return Ok(packages);
    };
    for unit in fs::read_dir(package)? {
        let out = unit?.path().join("out");
        if !out.is_dir() {
            continue;
        }
        for (path, name) in files_in(&out)? {
            if !(name.starts_with("build_script_build") && name.ends_with(".d")) {
                continue;
            }
            for source in dep_info_files(&read(&path)?) {
                let source = normalize(&source);
                let dir = source
                    .ancestors()
                    .skip(1)
                    .take_while(|dir| dir.starts_with(&ctx.root))
                    .find(|dir| dir.join("Cargo.toml").is_file());
                packages.extend(dir.map(Path::to_path_buf));
            }
        }
    }
    Ok(packages)
}

/// Adds every file of the package in `dir`, root relative, to `reads`: all of the folder but
/// build output (`target`), Git's folder and nested packages, as Cargo lists a package's files.
fn package_files(ctx: &Context, dir: &Path, reads: &mut BTreeSet<String>) -> Result<()> {
    for (path, name) in files_in(dir)? {
        if path.is_dir() {
            if name != "target" && name != ".git" && !path.join("Cargo.toml").is_file() {
                package_files(ctx, &path, reads)?;
            }
        } else if let Ok(relative) = path.strip_prefix(&ctx.root) {
            reads.insert(relative.display().to_string());
        }
    }
    Ok(())
}

/// The unit folders below `target`'s build folders (`<profile>/build/<package>/<hash>/<kind>`, also
/// below a target triple) for each of `kinds`, and Cargo's older flat `deps` folders.
fn unit_dirs(target: &Path, kinds: &[&str]) -> Result<Vec<PathBuf>> {
    let mut dirs = Vec::new();
    for kind in kinds {
        let patterns = if *kind == "deps" {
            ["*/deps".to_owned(), "*/*/deps".to_owned()]
        } else {
            [
                format!("*/build/*/*/{kind}"),
                format!("*/*/build/*/*/{kind}"),
            ]
        };
        for pattern in patterns {
            dirs.extend(expand(target, &pattern)?);
        }
    }
    Ok(dirs)
}

/// The entries of `dir` as (path, name), sorted.
fn files_in(dir: &Path) -> Result<Vec<(PathBuf, String)>> {
    let mut entries = fs::read_dir(dir)
        .with_context(|| format!("cannot read {}", dir.display()))?
        .map(|entry| {
            entry.map(|entry| {
                (
                    entry.path(),
                    entry.file_name().to_string_lossy().into_owned(),
                )
            })
        })
        .collect::<Result<Vec<_>, _>>()?;
    entries.sort();
    Ok(entries)
}

fn read(path: &Path) -> Result<String> {
    fs::read_to_string(path).with_context(|| format!("cannot read {}", path.display()))
}

/// The variables a dependency file's `# env-dep:NAME=value` (or `# env-dep:NAME` for an unset
/// one) lines name, without those Cargo sets for every crate.
fn env_deps(text: &str) -> Vec<String> {
    text.lines()
        .filter_map(|line| line.strip_prefix("# env-dep:"))
        .map(|dep| dep.split_once('=').map_or(dep, |(name, _)| name).to_owned())
        .filter(|name| !cargo_sets(name))
        .collect()
}

/// Whether Cargo sets the variable `name` itself, for each crate it compiles or runs or for each
/// build script, so its value follows from the command and the workspace.
fn cargo_sets(name: &str) -> bool {
    matches!(
        name,
        "CARGO"
            | "CARGO_MANIFEST_DIR"
            | "CARGO_MANIFEST_PATH"
            | "CARGO_MANIFEST_LINKS"
            | "CARGO_CRATE_NAME"
            | "CARGO_BIN_NAME"
            | "CARGO_PRIMARY_PACKAGE"
            | "CARGO_TARGET_TMPDIR"
            | "CARGO_RUSTC_CURRENT_DIR"
            | "CARGO_MAKEFLAGS"
            | "OUT_DIR"
    ) || [
        "CARGO_PKG_",
        "CARGO_BIN_EXE_",
        "CARGO_CFG_",
        "CARGO_FEATURE_",
    ]
    .iter()
    .any(|prefix| name.starts_with(prefix))
}

/// Every Cargo configuration file `cargo` loads, whether it exists yet or not: `.cargo/config.toml`
/// and `.cargo/config` in the directory it runs in and each one above, then `config.toml` and
/// `config` in Cargo's home (`CARGO_HOME`, or `.cargo` in `HOME`). Root relative inside the
/// repository, absolute outside it.
fn configs(ctx: &Context, cargo: &Command, env: &Environment) -> Vec<String> {
    let dir = cargo
        .get_current_dir()
        .map_or_else(|| ctx.root.clone(), |dir| ctx.root.join(dir));
    let mut files = Vec::new();
    for ancestor in dir.ancestors() {
        files.push(ancestor.join(".cargo/config.toml"));
        files.push(ancestor.join(".cargo/config"));
    }
    let home = env
        .get("CARGO_HOME")
        .map(PathBuf::from)
        .or_else(|| env.get("HOME").map(|home| Path::new(home).join(".cargo")));
    if let Some(home) = home {
        files.push(home.join("config.toml"));
        files.push(home.join("config"));
    }
    let mut entries: Vec<String> = files
        .iter()
        .map(|file| {
            file.strip_prefix(&ctx.root)
                .unwrap_or(file)
                .display()
                .to_string()
        })
        .collect();
    entries.sort();
    entries.dedup();
    entries
}

/// The files a Makefile style dependency file names after each rule's colon. A space inside a
/// path is escaped with a backslash; rustc's `#` comment lines name no file.
fn dep_info_files(text: &str) -> Vec<PathBuf> {
    let mut files = Vec::new();
    for line in text.lines().filter(|line| !line.starts_with('#')) {
        let Some((_, dependencies)) = line.split_once(": ") else {
            continue;
        };
        let mut current = String::new();
        let mut chars = dependencies.chars();
        while let Some(char) = chars.next() {
            match char {
                '\\' => current.extend(chars.next()),
                ' ' => {
                    if !current.is_empty() {
                        files.push(PathBuf::from(std::mem::take(&mut current)));
                    }
                }
                _ => current.push(char),
            }
        }
        if !current.is_empty() {
            files.push(PathBuf::from(current));
        }
    }
    files
}

/// `path` with every `..` applied to the component before it, as rustc's `../` includes need.
fn normalize(path: &Path) -> PathBuf {
    let mut normal = PathBuf::new();
    for component in path.components() {
        match component {
            Component::ParentDir => {
                normal.pop();
            }
            Component::CurDir => {}
            other => normal.push(other),
        }
    }
    normal
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{CARGO_WORKSPACE as WORKSPACE, FakeCargo, cargo_workspace, refusal};

    /// The environment of every case that does not vary one.
    const NONE: Environment = Environment::EMPTY;

    const READS: &[&str] = &["backend/src/lib.rs"];

    #[test]
    fn a_build_whose_reads_are_unchanged_is_reused_without_running_cargo() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);

        let first = build.run(&root.ctx, &mut cargo.command("one", READS), &NONE);
        let second = build.run(&root.ctx, &mut cargo.command("one", READS), &NONE);

        assert_eq!(first.unwrap(), Outcome::Compiled);
        assert_eq!(second.unwrap(), Outcome::Reused);
        assert_eq!(cargo.runs(), 1);
        assert_eq!(fs::read_to_string(cargo.artifact()).unwrap(), "one");
    }

    #[test]
    fn editing_a_file_the_build_did_not_read_reuses_it() {
        let root = cargo_workspace();
        root.write("backend/tests/case.rs", "#[test] fn case() {}");
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        build
            .run(&root.ctx, &mut cargo.command("one", READS), &NONE)
            .unwrap();

        root.write("backend/tests/case.rs", "#[test] fn edited() {}");
        root.write("backend/src/unused.rs", "");
        let outcome = build.run(&root.ctx, &mut cargo.command("one", READS), &NONE);
        assert_eq!(outcome.unwrap(), Outcome::Reused);
    }

    #[test]
    fn editing_a_file_the_build_read_or_a_workspace_file_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        build
            .run(&root.ctx, &mut cargo.command("one", READS), &NONE)
            .unwrap();

        for (file, contents) in [
            ("backend/src/lib.rs", "fn main() { edited() }"),
            ("Cargo.lock", "version = 4\n[[package]]"),
            ("backend/Cargo.toml", "[package]\nname = \"edited\""),
        ] {
            root.write(file, contents);
            let outcome = build.run(&root.ctx, &mut cargo.command("one", READS), &NONE);
            assert_eq!(outcome.unwrap(), Outcome::Compiled, "after writing {file}");
        }
        assert_eq!(cargo.runs(), 4);
    }

    #[test]
    fn adding_a_module_builds_again_and_the_new_module_is_read_from_then_on() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        build
            .run(&root.ctx, &mut cargo.command("one", READS), &NONE)
            .unwrap();

        root.write("backend/src/new.rs", "pub fn new() {}");
        root.write("backend/src/lib.rs", "mod new;\nfn main() {}");
        let with_module = ["backend/src/lib.rs", "backend/src/new.rs"];
        let added = build.run(&root.ctx, &mut cargo.command("one", &with_module), &NONE);
        assert_eq!(added.unwrap(), Outcome::Compiled);

        root.write("backend/src/new.rs", "pub fn new() { edited() }");
        let edited = build.run(&root.ctx, &mut cargo.command("one", &with_module), &NONE);
        assert_eq!(edited.unwrap(), Outcome::Compiled);
    }

    #[test]
    fn a_build_without_a_dependency_file_is_not_reused() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        let mut silent = cargo.command("one", READS);
        silent.env("DEP_INFO", "/dev/null");
        build.run(&root.ctx, &mut silent, &NONE).unwrap();

        let mut again = cargo.command("one", READS);
        again.env("DEP_INFO", "/dev/null");
        assert_eq!(
            build.run(&root.ctx, &mut again, &NONE).unwrap(),
            Outcome::Compiled
        );
    }

    #[test]
    fn a_different_command_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        build
            .run(&root.ctx, &mut cargo.command("one", READS), &NONE)
            .unwrap();

        let mut release = cargo.command("one", READS);
        release.arg("--release");
        assert_eq!(
            build.run(&root.ctx, &mut release, &NONE).unwrap(),
            Outcome::Compiled
        );
        let mut profile = cargo.command("one", READS);
        profile.env("CARGO_PROFILE_DEV_DEBUG", "0");
        assert_eq!(
            build.run(&root.ctx, &mut profile, &NONE).unwrap(),
            Outcome::Compiled
        );
    }

    #[test]
    fn an_artifact_changed_or_removed_since_its_build_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        build
            .run(&root.ctx, &mut cargo.command("one", READS), &NONE)
            .unwrap();

        fs::write(cargo.artifact(), "built by hand").unwrap();
        let changed = build.run(&root.ctx, &mut cargo.command("one", READS), &NONE);
        assert_eq!(changed.unwrap(), Outcome::Compiled);
        fs::remove_file(cargo.artifact()).unwrap();
        let removed = build.run(&root.ctx, &mut cargo.command("one", READS), &NONE);
        assert_eq!(removed.unwrap(), Outcome::Compiled);
        assert_eq!(fs::read_to_string(cargo.artifact()).unwrap(), "one");
    }

    #[test]
    fn an_artifact_the_build_no_longer_writes_fails_it_even_when_an_old_copy_remains() {
        let root = cargo_workspace();
        root.write("target/renamed.wasm", "built before its target was renamed");
        let cargo = FakeCargo { ctx: &root.ctx };
        let mut build = cargo.build(WORKSPACE);
        build.artifacts.push(root.path("target/renamed.wasm"));

        let error = refusal(build.run(&root.ctx, &mut cargo.command("one", READS), &NONE));
        assert!(error.contains("target/renamed.wasm"), "{error}");
        assert!(!root.path("target/renamed.wasm").exists());
    }

    #[test]
    fn an_inherited_cargo_or_rust_variable_builds_again_but_one_cargo_sets_per_crate_does_not() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        let run = |env: &Environment| {
            build
                .run(&root.ctx, &mut cargo.command("one", READS), env)
                .unwrap()
        };
        let optimized = NONE.with("CARGO_PROFILE_RELEASE_OPT_LEVEL", "3");

        assert_eq!(run(&optimized), Outcome::Compiled);
        assert_eq!(run(&optimized), Outcome::Reused);
        // As `cargo run` sets it for xtask itself, whose children inherit it.
        let per_crate = optimized.clone().with("CARGO_PKG_VERSION", "9.9.9");
        assert_eq!(run(&per_crate), Outcome::Reused);
        let smaller = NONE.with("CARGO_PROFILE_RELEASE_OPT_LEVEL", "s");
        assert_eq!(run(&smaller), Outcome::Compiled);
        let wrapped = smaller.with("RUSTC_WRAPPER", "sccache");
        assert_eq!(run(&wrapped), Outcome::Compiled);
    }

    #[test]
    fn editing_or_adding_a_cargo_configuration_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        let env = NONE.with("CARGO_HOME", &root.path("cargo-home").display().to_string());
        let run = || {
            build
                .run(&root.ctx, &mut cargo.command("one", READS), &env)
                .unwrap()
        };
        assert_eq!(run(), Outcome::Compiled);
        assert_eq!(run(), Outcome::Reused);

        // Above the directory Cargo runs in, and in Cargo's home, under either name.
        for (file, contents) in [
            (".cargo/config.toml", "[build]\njobs = 2"),
            (".cargo/config.toml", "[build]\njobs = 4"),
            ("cargo-home/config.toml", "[profile.release]\nopt-level = 3"),
            ("cargo-home/config", "[build]\nrustflags = [\"-Dwarnings\"]"),
        ] {
            root.write(file, contents);
            assert_eq!(run(), Outcome::Compiled, "after writing {file}");
            assert_eq!(run(), Outcome::Reused, "again after writing {file}");
        }
    }

    #[test]
    fn a_changed_value_of_a_variable_a_crate_read_builds_again() {
        let root = cargo_workspace();
        // The dependency file rustc writes for the crate itself, in the unit's own folder.
        root.write(
            "target/debug/build/backend/0123/out/backend.d",
            &format!(
                "{out}/backend.rmeta: {lib}\n\n# env-dep:XTASK_TEST_GREETING=hello\n\
                 # env-dep:CARGO_PKG_VERSION=0.1.0\n",
                out = root.path("target/debug/build/backend/0123/out").display(),
                lib = root.path("backend/src/lib.rs").display()
            ),
        );
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        let run = |greeting: &str| {
            let env = NONE.with("XTASK_TEST_GREETING", greeting);
            build
                .run(&root.ctx, &mut cargo.command("one", READS), &env)
                .unwrap()
        };

        assert_eq!(run("hello"), Outcome::Compiled);
        assert_eq!(run("hello"), Outcome::Reused);
        assert_eq!(run("goodbye"), Outcome::Compiled);
    }

    #[test]
    fn a_changed_value_of_a_variable_a_build_script_watches_builds_again() {
        let root = cargo_workspace();
        // What the build script printed, in its run's own folder.
        root.write(
            "target/debug/build/schema/4567/run/stdout",
            "cargo::rerun-if-env-changed=XTASK_TEST_SCHEMA\ncargo:rerun-if-changed=build.rs\n",
        );
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        let run = |schema: &str| {
            let env = NONE.with("XTASK_TEST_SCHEMA", schema);
            build
                .run(&root.ctx, &mut cargo.command("one", READS), &env)
                .unwrap()
        };

        assert_eq!(run("v1"), Outcome::Compiled);
        assert_eq!(run("v1"), Outcome::Reused);
        assert_eq!(run("v2"), Outcome::Compiled);
    }

    #[test]
    fn every_file_of_a_package_whose_build_script_watches_nothing_is_read() {
        let root = cargo_workspace();
        root.write("backend/schema/Cargo.toml", "[package]");
        root.write("backend/schema/build.rs", "fn main() {}");
        root.write("backend/schema/tables/user.sql", "DEFINE TABLE user;");
        root.write("backend/schema/target/scratch", "");
        root.write("backend/schema/nested/Cargo.toml", "[package]");
        root.write("backend/schema/nested/src/lib.rs", "");
        // The build script's own compile unit names its source; its run printed no rerun line.
        root.write(
            "target/debug/build/schema/0123/out/build_script_build.d",
            &format!(
                "{out}/build_script_build: {script}\n",
                out = root.path("target/debug/build/schema/0123/out").display(),
                script = root.path("backend/schema/build.rs").display()
            ),
        );
        root.write(
            "target/debug/build/schema/4567/run/stdout",
            "cargo:rustc-cfg=schema\n",
        );
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        build
            .run(&root.ctx, &mut cargo.command("one", READS), &NONE)
            .unwrap();

        // Build output and a nested package are not the package's files.
        root.write("backend/schema/target/scratch", "rebuilt");
        root.write("backend/schema/nested/src/lib.rs", "pub fn nested() {}");
        let outside = build.run(&root.ctx, &mut cargo.command("one", READS), &NONE);
        assert_eq!(outside.unwrap(), Outcome::Reused);
        root.write("backend/schema/tables/user.sql", "DEFINE TABLE person;");
        let edited = build.run(&root.ctx, &mut cargo.command("one", READS), &NONE);
        assert_eq!(edited.unwrap(), Outcome::Compiled);
    }

    #[test]
    fn a_read_inside_the_repository_once_normalized_is_listed_and_one_outside_it_is_not() {
        let root = cargo_workspace();
        let outside = tempfile::tempdir().unwrap();
        let toolchain = outside.path().join("rustlib/src/lib.rs");
        fs::create_dir_all(toolchain.parent().unwrap()).unwrap();
        fs::write(&toolchain, "pub fn std() {}").unwrap();
        // Lands inside the repository only once its `..` is applied.
        let name = root.ctx.root.file_name().unwrap().to_string_lossy();
        let roundabout = root
            .ctx
            .root
            .parent()
            .unwrap()
            .join(format!("sibling/../{name}/backend/src/lib.rs"));
        let reads = [
            roundabout.display().to_string(),
            toolchain.display().to_string(),
        ];
        let reads: Vec<&str> = reads.iter().map(String::as_str).collect();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        let run = || {
            build
                .run(&root.ctx, &mut cargo.command("one", &reads), &NONE)
                .unwrap()
        };
        assert_eq!(run(), Outcome::Compiled);
        assert_eq!(run(), Outcome::Reused);

        fs::write(&toolchain, "pub fn std() { edited() }").unwrap();
        assert_eq!(run(), Outcome::Reused, "after editing a file outside it");
        root.write("backend/src/lib.rs", "fn main() { edited() }");
        assert_eq!(
            run(),
            Outcome::Compiled,
            "after editing the file read roundabout"
        );
    }

    #[test]
    fn dependency_files_name_every_file_after_each_colon_with_escaped_spaces() {
        assert_eq!(
            dep_info_files(
                "/t/stack: /a/lib.rs /my\\ docs/x.rs\n/t/other.d: /b/mod.rs\n\n/a/lib.rs:\n\
                 # env-dep:CARGO_PKG_DESCRIPTION=a: b\n"
            ),
            [
                PathBuf::from("/a/lib.rs"),
                PathBuf::from("/my docs/x.rs"),
                PathBuf::from("/b/mod.rs"),
            ]
        );
    }
}
