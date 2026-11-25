//! Cargo builds reused while what they read is unchanged. Cargo itself judges local crates by
//! file times, so a fresh checkout recompiles every one of them even when a cached target holds
//! what they would produce. A stamp beside the artifacts records the command, the toolchain and
//! the sha256 of each artifact and of everything the build read: the repository files the
//! dependency files Cargo writes beside each artifact name (a build script's `rerun-if-changed`
//! inputs included), the environment variables its crates read at compile time (`env!`,
//! `option_env!`), and the workspace's manifests, lock file and Cargo configuration. While all of
//! them match, Cargo does not run at all.
//!
//! Files outside the repository are not listed: the toolchain's sources change with `rustc -vV`
//! and dependency sources with `Cargo.lock`.
//!
//! Known issue: a build script that prints no `rerun-if-changed` names none of the files it reads,
//! so an edit only such a script reads reuses the build. The backend's one build script
//! (`backend/database/schema/build.rs`) names every file it reads.

use std::collections::BTreeSet;
use std::fs;
use std::path::{Component, Path, PathBuf};
use std::process::Command;

use anyhow::{Context as _, Result, bail};
use serde_json::Value;

use crate::digest::{Digest, Stamp, expand};
use crate::{CommandExt as _, Context};

/// One Cargo invocation and what it produces.
pub struct CargoBuild<'a> {
    /// Names the stamp, which lies beside the first artifact as `<name>.xtask-stamp`.
    pub name: &'a str,
    /// Root relative files every build depends on although no dependency file names them: the
    /// workspace's manifests, lock file and Cargo configuration ([`workspace_files`]).
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
/// outside the workspace included), the workspace's own manifest and lock file, and each
/// `.cargo/config.toml` from the workspace up to the repository root.
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
    for dir in workspace.ancestors() {
        files.push(dir.join(".cargo/config.toml"));
        if dir == ctx.root {
            break;
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
    pub fn run(&self, ctx: &Context, cargo: &mut Command) -> Result<Outcome> {
        let digest = self.digest(ctx, cargo)?;
        let stamp = self.stamp()?;
        let artifacts = self.artifact_names();
        if let Some(listed) = stamp.files(&ctx.root, &digest)
            && artifacts
                .iter()
                .chain(&self.workspace)
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
            files.extend(reads);
            files.sort();
            files.dedup();
            stamp.record(&ctx.root, &digest, &files)
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

    /// The digest of the command line with the variables it sets, the flags the environment
    /// passes to rustc, and the toolchain's version.
    fn digest(&self, ctx: &Context, cargo: &Command) -> Result<Digest> {
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
        for flags in ["RUSTFLAGS", "CARGO_ENCODED_RUSTFLAGS"] {
            digest.update(&[0]);
            match std::env::var_os(flags) {
                Some(value) => digest.update(value.as_encoded_bytes()),
                None => digest.update(b"unset"),
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
        reads.extend(self.env_reads()?.iter().map(|name| format!("${name}")));
        Ok(reads)
    }

    /// The environment variables the crates in the build's target directory read at compile time.
    /// Cargo's copy of the dependency file beside an artifact leaves out rustc's `# env-dep:`
    /// lines and names only the sources of path packages, so the variables come from every unit's
    /// own dependency file in the target directory's build folders. That may include units of
    /// another build in the same target, which costs a rebuild when their variables change, never
    /// a stale artifact. The variables Cargo sets for every crate itself are left out: they follow
    /// from the command and the workspace.
    fn env_reads(&self) -> Result<BTreeSet<String>> {
        let first = self
            .artifacts
            .first()
            .with_context(|| format!("the build {} names no artifact", self.name))?;
        let target = first
            .ancestors()
            .find(|dir| dir.join("CACHEDIR.TAG").is_file())
            .with_context(|| format!("{} lies in no Cargo target directory", first.display()))?;
        let mut names = BTreeSet::new();
        for pattern in ["*/build/*/*/out", "*/*/build/*/*/out", "*/deps", "*/*/deps"] {
            for dir in expand(target, pattern)? {
                for entry in fs::read_dir(&dir)? {
                    let path = entry?.path();
                    if path.extension().is_some_and(|extension| extension == "d") {
                        let text = fs::read_to_string(&path)
                            .with_context(|| format!("cannot read {}", path.display()))?;
                        names.extend(env_deps(&text));
                    }
                }
            }
        }
        Ok(names)
    }
}

/// The variables a dependency file's `# env-dep:NAME=value` (or `# env-dep:NAME` for an unset
/// one) lines name, without those Cargo sets for every crate.
fn env_deps(text: &str) -> Vec<String> {
    text.lines()
        .filter_map(|line| line.strip_prefix("# env-dep:"))
        .map(|dep| dep.split_once('=').map_or(dep, |(name, _)| name).to_owned())
        .filter(|name| name != "CARGO" && !name.starts_with("CARGO_") && name != "OUT_DIR")
        .collect()
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

    const READS: &[&str] = &["backend/src/lib.rs"];

    #[test]
    fn a_build_whose_reads_are_unchanged_is_reused_without_running_cargo() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);

        let first = build.run(&root.ctx, &mut cargo.command("one", READS));
        let second = build.run(&root.ctx, &mut cargo.command("one", READS));

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
            .run(&root.ctx, &mut cargo.command("one", READS))
            .unwrap();

        root.write("backend/tests/case.rs", "#[test] fn edited() {}");
        root.write("backend/src/unused.rs", "");
        let outcome = build.run(&root.ctx, &mut cargo.command("one", READS));
        assert_eq!(outcome.unwrap(), Outcome::Reused);
    }

    #[test]
    fn editing_a_file_the_build_read_or_a_workspace_file_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        build
            .run(&root.ctx, &mut cargo.command("one", READS))
            .unwrap();

        for (file, contents) in [
            ("backend/src/lib.rs", "fn main() { edited() }"),
            ("Cargo.lock", "version = 4\n[[package]]"),
            ("backend/Cargo.toml", "[package]\nname = \"edited\""),
        ] {
            root.write(file, contents);
            let outcome = build.run(&root.ctx, &mut cargo.command("one", READS));
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
            .run(&root.ctx, &mut cargo.command("one", READS))
            .unwrap();

        root.write("backend/src/new.rs", "pub fn new() {}");
        root.write("backend/src/lib.rs", "mod new;\nfn main() {}");
        let with_module = ["backend/src/lib.rs", "backend/src/new.rs"];
        let added = build.run(&root.ctx, &mut cargo.command("one", &with_module));
        assert_eq!(added.unwrap(), Outcome::Compiled);

        root.write("backend/src/new.rs", "pub fn new() { edited() }");
        let edited = build.run(&root.ctx, &mut cargo.command("one", &with_module));
        assert_eq!(edited.unwrap(), Outcome::Compiled);
    }

    #[test]
    fn a_build_without_a_dependency_file_is_not_reused() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        let mut silent = cargo.command("one", READS);
        silent.env("DEP_INFO", "/dev/null");
        build.run(&root.ctx, &mut silent).unwrap();

        let mut again = cargo.command("one", READS);
        again.env("DEP_INFO", "/dev/null");
        assert_eq!(build.run(&root.ctx, &mut again).unwrap(), Outcome::Compiled);
    }

    #[test]
    fn a_different_command_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        build
            .run(&root.ctx, &mut cargo.command("one", READS))
            .unwrap();

        let mut release = cargo.command("one", READS);
        release.arg("--release");
        assert_eq!(
            build.run(&root.ctx, &mut release).unwrap(),
            Outcome::Compiled
        );
        let mut profile = cargo.command("one", READS);
        profile.env("CARGO_PROFILE_DEV_DEBUG", "0");
        assert_eq!(
            build.run(&root.ctx, &mut profile).unwrap(),
            Outcome::Compiled
        );
    }

    #[test]
    fn an_artifact_changed_or_removed_since_its_build_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        build
            .run(&root.ctx, &mut cargo.command("one", READS))
            .unwrap();

        fs::write(cargo.artifact(), "built by hand").unwrap();
        let changed = build.run(&root.ctx, &mut cargo.command("one", READS));
        assert_eq!(changed.unwrap(), Outcome::Compiled);
        fs::remove_file(cargo.artifact()).unwrap();
        let removed = build.run(&root.ctx, &mut cargo.command("one", READS));
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

        let error = refusal(build.run(&root.ctx, &mut cargo.command("one", READS)));
        assert!(error.contains("target/renamed.wasm"), "{error}");
        assert!(!root.path("target/renamed.wasm").exists());
    }

    /// Set when the test below runs as its own child: the root of the parent's build.
    const ENV_DEP_ROOT: &str = "XTASK_TEST_ENV_DEP_ROOT";

    /// Runs twice: as a normal test it runs itself as a child process once per build, each with
    /// its own value of the variable the build read, since a test may not change its own
    /// environment while other tests run; each child runs one build in the parent's root.
    #[test]
    fn a_changed_value_of_a_variable_the_build_read_builds_again() {
        if let Some(root) = std::env::var_os(ENV_DEP_ROOT) {
            let ctx = Context {
                root: PathBuf::from(root),
            };
            let cargo = FakeCargo { ctx: &ctx };
            let outcome = cargo
                .build(WORKSPACE)
                .run(&ctx, &mut cargo.command("one", READS))
                .unwrap();
            fs::write(ctx.root.join("outcome"), format!("{outcome:?}")).unwrap();
            return;
        }
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
        let build = |greeting: &str| {
            let status = Command::new(std::env::current_exe().unwrap())
                .args([
                    "cargo_build::tests::a_changed_value_of_a_variable_the_build_read_builds_again",
                    "--exact",
                    "--quiet",
                ])
                .env(ENV_DEP_ROOT, &root.ctx.root)
                .env("XTASK_TEST_GREETING", greeting)
                .status()
                .unwrap();
            assert!(status.success());
            fs::read_to_string(root.path("outcome")).unwrap()
        };

        assert_eq!(build("hello"), "Compiled");
        assert_eq!(build("hello"), "Reused");
        assert_eq!(build("goodbye"), "Compiled");
    }

    #[test]
    fn reads_are_normalized_and_files_outside_the_repository_are_not_listed() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(WORKSPACE);
        let reads = ["backend/src/../src/lib.rs", "../rustlib/src/lib.rs"];
        build
            .run(&root.ctx, &mut cargo.command("one", &reads))
            .unwrap();

        root.write("backend/src/lib.rs", "fn main() { edited() }");
        let outcome = build.run(&root.ctx, &mut cargo.command("one", &reads));
        assert_eq!(outcome.unwrap(), Outcome::Compiled);
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
