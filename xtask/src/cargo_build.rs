//! Cargo builds reused while their declared inputs are unchanged. Cargo itself judges local
//! crates by file times, so a fresh checkout recompiles every one of them even when a cached target
//! holds what they would produce. Cargo's own content based check (`-Z checksum-freshness`) is
//! refused on the stable toolchain the repository pins (1.100), so this module decides instead.
//! Once checksum freshness is stable, delete the declared trees and their checks: keep only the
//! cached target and the removal of each artifact before Cargo runs, and let Cargo decide.
//!
//! A build declares the folders it reads, its trees: its workspace's folder, the folder of every
//! package in the repository it builds, and any folder its caller adds. A stamp beside the
//! artifacts records:
//!
//! - the command, with the variables it sets, and the toolchain (`rustc -vV`);
//! - Cargo's whole configuration surface: every inherited `CARGO*` and `RUST*` variable but those
//!   Cargo sets for each crate itself, and every configuration file Cargo loads (`.cargo/config.toml`
//!   and `.cargo/config` from the directory it runs in up to the file system root, then those in
//!   Cargo's home), each recorded absent while it does not exist;
//! - the sha256 of each artifact, of every file in the trees that Git does not ignore (tracked, or
//!   untracked but not ignored, so a new module counts before it is added), of the generated
//!   protocol sources inside them, and of each variable outside `CARGO*` and `RUST*` a build script
//!   watches (`rerun-if-env-changed`).
//!
//! While all of them match, Cargo does not run at all. Files outside the repository are not
//! listed: the toolchain's sources change with `rustc -vV` and dependency sources with
//! `Cargo.lock`.
//!
//! So that no input goes unseen, a build that read a repository file outside its trees fails,
//! naming it: one the dependency file Cargo writes beside each artifact names (an `include_str!`
//! of a file elsewhere), or one a build script watches (`rerun-if-changed`) outside its trees, or
//! outside its own folder for a package from elsewhere. Its caller then declares the folder.
//!
//! Known issues: a variable a crate reads at compile time (`env!`, `option_env!`) outside `CARGO*`
//! and `RUST*` is not an input unless a build script watches it, since Cargo's dependency file
//! beside an artifact leaves those out; and a procedural macro that reads a file no dependency file
//! names is trusted, as Cargo trusts it. Where a build script's output lies is found from the
//! `out_dir` Cargo's JSON messages name; a toolchain that moves it fails the build loudly.

use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::{Component, Path, PathBuf};
use std::process::Command;

use anyhow::{Context as _, Result, bail};
use serde::Deserialize;

use crate::digest::{Digest, Environment, Stamp};
use crate::{CommandExt as _, Context, generate};

/// One Cargo invocation, the folders it reads and what it produces.
pub struct CargoBuild<'a> {
    /// Names the stamp, which lies beside the first artifact as `<name>.xtask-stamp`.
    pub name: &'a str,
    /// The root relative folders whose files are the build's inputs (`.` for the whole
    /// repository).
    pub trees: Vec<String>,
    /// The absolute paths of what the build produces.
    pub artifacts: Vec<PathBuf>,
    /// The Cargo target directory the build writes to, as `cargo metadata` names it; what a build
    /// script generates there is output, never input.
    pub target: PathBuf,
    /// The folder of each package the build compiles, by Cargo's package id, which its JSON
    /// messages name the package by.
    pub packages: BTreeMap<String, PathBuf>,
}

impl<'a> CargoBuild<'a> {
    /// The build `name` in the Cargo workspace of `manifest`, root relative, of the artifacts
    /// `artifacts` names below the workspace's target directory. Its trees are the workspace's
    /// folder, the folder of every package in the repository it builds, and `declared`.
    pub fn in_workspace(
        ctx: &Context,
        name: &'a str,
        manifest: &str,
        declared: &[&str],
        artifacts: impl FnOnce(&Path) -> Vec<PathBuf>,
    ) -> Result<Self> {
        let metadata = metadata(ctx, manifest, Packages::All)?;
        let repository = Repository::of(ctx)?;
        let local = metadata
            .packages
            .iter()
            .filter(|package| package.source.is_none())
            .filter_map(|package| package.manifest_path.parent());
        let mut trees: Vec<String> = declared.iter().map(|tree| (*tree).to_owned()).collect();
        for dir in std::iter::once(metadata.workspace_root.as_path()).chain(local) {
            if let Some(relative) = repository.relative(dir) {
                trees.push(tree(relative));
            }
        }
        trees.sort();
        trees.dedup();
        let packages = metadata
            .packages
            .iter()
            .filter_map(|package| {
                Some((
                    package.id.clone(),
                    package.manifest_path.parent()?.to_owned(),
                ))
            })
            .collect();
        Ok(Self {
            name,
            trees,
            artifacts: artifacts(&metadata.target_directory),
            target: metadata.target_directory,
            packages,
        })
    }
}

/// A root relative folder as a tree: `.` for the root itself.
fn tree(relative: &Path) -> String {
    if relative.as_os_str().is_empty() {
        ".".to_owned()
    } else {
        relative.display().to_string()
    }
}

/// What `cargo metadata` says about a workspace, as far as xtask reads it.
#[derive(Deserialize)]
pub struct Metadata {
    pub target_directory: PathBuf,
    pub workspace_root: PathBuf,
    pub packages: Vec<Package>,
}

#[derive(Deserialize)]
pub struct Package {
    /// Cargo's opaque id, which build messages name the package by.
    pub id: String,
    pub name: String,
    pub manifest_path: PathBuf,
    /// Where a dependency comes from; none for a package in the repository.
    pub source: Option<String>,
    pub targets: Vec<Target>,
}

#[derive(Deserialize)]
pub struct Target {
    pub crate_types: Vec<String>,
}

/// Which packages [`metadata`] lists.
#[derive(Clone, Copy)]
pub enum Packages {
    /// The workspace's members.
    Members,
    /// Every package a build of the workspace compiles, dependencies included.
    All,
}

/// `cargo metadata` of the workspace whose manifest is `manifest`, root relative.
pub fn metadata(ctx: &Context, manifest: &str, packages: Packages) -> Result<Metadata> {
    let mut args = vec!["metadata", "--format-version", "1", "--locked"];
    if let Packages::Members = packages {
        args.push("--no-deps");
    }
    args.extend(["--manifest-path", manifest]);
    serde_json::from_str(&ctx.tool(".", "cargo", &args).output_text()?)
        .with_context(|| format!("cargo metadata printed an unexpected description of {manifest}"))
}

/// The repository root in both spellings a path inside it may take: as xtask was handed it, and
/// physical, as Cargo spells the paths it reports. Cargo starts from the physical working
/// directory, so it resolves a root reached through a symbolic link (macOS's `/var`, for one).
struct Repository {
    given: PathBuf,
    physical: PathBuf,
}

impl Repository {
    fn of(ctx: &Context) -> Result<Self> {
        let physical = fs::canonicalize(&ctx.root)
            .with_context(|| format!("cannot resolve {}", ctx.root.display()))?;
        Ok(Self {
            given: ctx.root.clone(),
            physical,
        })
    }

    /// `path` relative to the root, when it lies inside it.
    fn relative<'p>(&self, path: &'p Path) -> Option<&'p Path> {
        path.strip_prefix(&self.physical)
            .or_else(|_| path.strip_prefix(&self.given))
            .ok()
    }
}

/// Whether [`CargoBuild::run`] ran Cargo.
#[derive(Debug, PartialEq, Eq)]
pub enum Outcome {
    /// The artifacts on disk were built from what is there now; Cargo did not run.
    Reused,
    /// Cargo ran, and the artifacts are stamped with the inputs it ran on.
    Compiled,
}

/// One JSON message Cargo prints, as far as the build reads it.
#[derive(Deserialize)]
struct Message {
    reason: String,
    #[serde(default)]
    package_id: String,
    out_dir: Option<PathBuf>,
}

impl CargoBuild<'_> {
    /// Runs `cargo` unless its stamp records the same command and toolchain and every input still
    /// has the same contents, checks that it read nothing outside its trees, then stamps the
    /// artifacts with the inputs it ran on. Cargo prints its messages as JSON, which the check
    /// reads; its diagnostics stay as they are.
    pub fn run(&self, ctx: &Context, cargo: &mut Command, env: &Environment) -> Result<Outcome> {
        cargo.arg("--message-format=json-render-diagnostics");
        let digest = self.digest(ctx, cargo, env)?;
        let stamp = self.stamp()?;
        let mut inputs = self.artifact_names();
        inputs.extend(self.files(ctx)?);
        inputs.extend(configs(ctx, cargo, env));
        if let Some(listed) = stamp.files(&ctx.root, &digest, env)
            && inputs.iter().all(|file| listed.contains(file))
        {
            return Ok(Outcome::Reused);
        }
        // A build that fails leaves nothing to reuse, and an artifact Cargo does not write again
        // (a renamed or dropped target) is not taken for one.
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
        let messages = cargo.output_text()?;
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
        inputs.extend(self.check(ctx, &messages)?);
        inputs.sort();
        inputs.dedup();
        stamp
            .record(&ctx.root, &digest, &inputs, env)
            .with_context(|| format!("cannot stamp the build {}", self.name))?;
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

    /// The root relative files of the trees: every one Git lists there, tracked or untracked but
    /// not ignored, and the generated protocol sources inside them, which Git ignores.
    fn files(&self, ctx: &Context) -> Result<Vec<String>> {
        let listing = ctx
            .tool(
                ".",
                "git",
                &[
                    "-c",
                    "core.quotePath=false",
                    "ls-files",
                    "-z",
                    "--cached",
                    "--others",
                    "--exclude-standard",
                    "--",
                ],
            )
            .args(&self.trees)
            .output_text()?;
        let mut files: Vec<String> = listing
            .split('\0')
            .filter(|file| !file.is_empty())
            .map(str::to_owned)
            .collect();
        files.extend(
            generate::protocol_files(ctx)?
                .into_iter()
                .filter(|file| self.holds(Path::new(file))),
        );
        Ok(files)
    }

    /// Whether the root relative `path` lies in one of the trees.
    fn holds(&self, path: &Path) -> bool {
        self.trees
            .iter()
            .any(|tree| tree == "." || path.starts_with(tree))
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

    /// Fails, naming each, when the build read a repository file outside its trees: one the
    /// dependency file beside an artifact names, or one a build script watches. Returns, as
    /// `$NAME`, each variable outside `CARGO*` and `RUST*` its build scripts watch, which the
    /// stamp records with its value.
    fn check(&self, ctx: &Context, messages: &str) -> Result<BTreeSet<String>> {
        let repository = Repository::of(ctx)?;
        let mut outside = BTreeSet::new();
        for artifact in &self.artifacts {
            let dep_info = artifact.with_extension("d");
            let text = fs::read_to_string(&dep_info).with_context(|| {
                format!(
                    "cannot read {}, which names what the build {} read",
                    dep_info.display(),
                    self.name
                )
            })?;
            for file in dep_info_files(&text) {
                let file = normalize(&file);
                if let Some(relative) = repository.relative(&file)
                    && !file.starts_with(&self.target)
                    && !self.holds(relative)
                {
                    outside.insert(relative.display().to_string());
                }
            }
        }
        let mut watched = BTreeSet::new();
        for line in messages.lines().filter(|line| !line.trim().is_empty()) {
            let message: Message = serde_json::from_str(line)
                .with_context(|| format!("Cargo printed an unexpected message: {line}"))?;
            if message.reason != "build-script-executed" {
                continue;
            }
            let package = self.packages.get(&message.package_id).with_context(|| {
                format!(
                    "the build {} compiles no package {}",
                    self.name, message.package_id
                )
            })?;
            let out_dir = message.out_dir.with_context(|| {
                format!(
                    "Cargo named no output folder for the build script of {}",
                    message.package_id
                )
            })?;
            for directive in directives(&build_script_output(&out_dir)?) {
                match directive {
                    Watch::Variable(name) => {
                        if !(name.starts_with("CARGO") || name.starts_with("RUST")) {
                            watched.insert(format!("${name}"));
                        }
                    }
                    Watch::File(path) => {
                        let path = normalize(&package.join(path));
                        let declared = match repository.relative(&path) {
                            Some(relative) => self.holds(relative),
                            None => {
                                repository.relative(package).is_none() && path.starts_with(package)
                            }
                        };
                        if !declared {
                            outside.insert(
                                repository
                                    .relative(&path)
                                    .unwrap_or(&path)
                                    .display()
                                    .to_string(),
                            );
                        }
                    }
                }
            }
        }
        if !outside.is_empty() {
            bail!(
                "the build {} read {}, outside the folders it declares ({}); declare the folder \
                 that holds each",
                self.name,
                outside.into_iter().collect::<Vec<_>>().join(", "),
                self.trees.join(", ")
            );
        }
        Ok(watched)
    }
}

/// What a build script asks Cargo to watch.
enum Watch<'a> {
    Variable(&'a str),
    File(&'a str),
}

/// The `rerun-if-env-changed` and `rerun-if-changed` lines a build script printed, in either
/// syntax (`cargo::` or the older `cargo:`).
fn directives(printed: &str) -> Vec<Watch<'_>> {
    printed
        .lines()
        .filter_map(|line| {
            line.strip_prefix("cargo::")
                .or_else(|| line.strip_prefix("cargo:"))
        })
        .filter_map(|directive| {
            if let Some(name) = directive.strip_prefix("rerun-if-env-changed=") {
                Some(Watch::Variable(name))
            } else {
                directive.strip_prefix("rerun-if-changed=").map(Watch::File)
            }
        })
        .collect()
}

/// What the build script whose output folder is `out_dir` printed, which Cargo keeps beside it:
/// `run/stdout` in its current layout, `output` in the older one.
fn build_script_output(out_dir: &Path) -> Result<String> {
    let unit = out_dir.parent().unwrap_or(out_dir);
    for printed in [unit.join("run/stdout"), unit.join("output")] {
        match fs::read_to_string(&printed) {
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            text => return text.with_context(|| format!("cannot read {}", printed.display())),
        }
    }
    bail!(
        "Cargo keeps what the build script with the output folder {} printed in neither {} nor {}; \
         its layout changed",
        out_dir.display(),
        unit.join("run/stdout").display(),
        unit.join("output").display()
    )
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
    use crate::test_support::{
        CARGO_TREES as TREES, FakeCargo, TempRoot, cargo_workspace, refusal,
    };

    /// The environment of every case that does not vary one.
    const NONE: Environment = Environment::EMPTY;

    const READS: &[&str] = &["backend/src/lib.rs"];

    #[test]
    fn a_build_whose_inputs_are_unchanged_is_reused_without_running_cargo() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);

        assert_eq!(cargo.run(&build), Outcome::Compiled);
        assert_eq!(cargo.run(&build), Outcome::Reused);
        assert_eq!(cargo.runs(), 1);
        assert_eq!(fs::read_to_string(cargo.artifact()).unwrap(), "one");
    }

    #[test]
    fn editing_any_tracked_file_in_the_trees_builds_again_even_one_the_build_never_read() {
        let root = cargo_workspace();
        root.write("backend/tests/case.rs", "#[test] fn case() {}");
        root.git(&["add", "."]);
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
        cargo.run(&build);

        for (file, contents) in [
            ("backend/src/lib.rs", "fn main() { edited() }"),
            ("backend/Cargo.lock", "version = 4\n[[package]]"),
            ("backend/Cargo.toml", "[package]\nname = \"edited\""),
            ("backend/tests/case.rs", "#[test] fn edited() {}"),
        ] {
            root.write(file, contents);
            assert_eq!(cargo.run(&build), Outcome::Compiled, "after writing {file}");
            assert_eq!(
                cargo.run(&build),
                Outcome::Reused,
                "again after writing {file}"
            );
        }
        fs::remove_file(root.path("backend/tests/case.rs")).unwrap();
        assert_eq!(
            cargo.run(&build),
            Outcome::Compiled,
            "after deleting a file"
        );
    }

    #[test]
    fn editing_a_file_outside_the_trees_reuses_the_build() {
        let root = cargo_workspace();
        root.write("services/build.gradle.kts", "plugins {}");
        root.git(&["add", "."]);
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
        cargo.run(&build);

        root.write("services/build.gradle.kts", "plugins { kotlin }");
        root.write("README.md", "new");
        assert_eq!(cargo.run(&build), Outcome::Reused);
    }

    #[test]
    fn an_untracked_file_in_the_trees_builds_again_but_an_ignored_one_does_not() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
        cargo.run(&build);

        // A module written but not yet added counts at once, and from then on.
        root.write("backend/src/new.rs", "pub fn new() {}");
        assert_eq!(cargo.run(&build), Outcome::Compiled);
        root.write("backend/src/new.rs", "pub fn new() { edited() }");
        assert_eq!(cargo.run(&build), Outcome::Compiled);
        root.write("backend/target/scratch", "build output");
        assert_eq!(cargo.run(&build), Outcome::Reused);
    }

    #[test]
    fn editing_a_generated_protocol_source_inside_the_trees_builds_again() {
        let root = cargo_workspace();
        let generated = "backend/wasmcloud-utils/src/skirout/protocol.rs";
        root.write(".gitignore", "target/\nruns\nskirout/\n");
        root.write(generated, "pub struct Old;");
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
        cargo.run(&build);

        root.write(generated, "pub struct New;");
        assert_eq!(cargo.run(&build), Outcome::Compiled);
    }

    #[test]
    fn a_build_names_its_workspace_and_every_repository_package_it_builds_as_trees() {
        let root = TempRoot::new();
        root.write(
            "backend/tests/component/Cargo.toml",
            "[workspace]\nmembers = [\"suite\"]\nresolver = \"3\"\n",
        );
        root.write(
            "backend/tests/component/suite/Cargo.toml",
            "[package]\nname = \"suite\"\nversion = \"0.1.0\"\nedition = \"2024\"\n\n\
             [dependencies]\nschema = { path = \"../../../database/schema\" }\n",
        );
        root.write("backend/tests/component/suite/src/lib.rs", "");
        root.write(
            "backend/database/schema/Cargo.toml",
            "[package]\nname = \"schema\"\nversion = \"0.1.0\"\nedition = \"2024\"\n",
        );
        root.write("backend/database/schema/src/lib.rs", "");
        root.ctx
            .tool(
                ".",
                "cargo",
                &[
                    "generate-lockfile",
                    "--offline",
                    "--quiet",
                    "--manifest-path",
                    "backend/tests/component/Cargo.toml",
                ],
            )
            .run()
            .unwrap();

        let build = CargoBuild::in_workspace(
            &root.ctx,
            "suite",
            "backend/tests/component/Cargo.toml",
            &["backend/database"],
            |target| vec![target.join("debug/libsuite.rlib")],
        )
        .unwrap();
        assert_eq!(
            build.trees,
            [
                "backend/database",
                "backend/database/schema",
                "backend/tests/component",
                "backend/tests/component/suite"
            ]
        );
    }

    #[test]
    fn a_file_that_cannot_be_hashed_fails_the_build_with_its_cause() {
        use std::os::unix::fs::PermissionsExt as _;
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let read = root.path("backend/src/lib.rs");
        fs::set_permissions(&read, fs::Permissions::from_mode(0o000)).unwrap();
        let result = cargo
            .build(TREES)
            .run(&root.ctx, &mut cargo.command("one", READS), &NONE);
        fs::set_permissions(&read, fs::Permissions::from_mode(0o644)).unwrap();

        let error = format!("{:#}", result.unwrap_err());
        assert!(
            error.contains(&format!("cannot read {}", read.display())),
            "{error}"
        );
        assert!(error.contains("Permission denied"), "{error}");
    }

    #[test]
    fn a_different_command_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
        cargo.run(&build);

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
        let build = cargo.build(TREES);
        cargo.run(&build);

        fs::write(cargo.artifact(), "built by hand").unwrap();
        assert_eq!(cargo.run(&build), Outcome::Compiled);
        fs::remove_file(cargo.artifact()).unwrap();
        assert_eq!(cargo.run(&build), Outcome::Compiled);
        assert_eq!(fs::read_to_string(cargo.artifact()).unwrap(), "one");
    }

    #[test]
    fn an_artifact_the_build_no_longer_writes_fails_it_even_when_an_old_copy_remains() {
        let root = cargo_workspace();
        root.write("target/renamed.wasm", "built before its target was renamed");
        let cargo = FakeCargo { ctx: &root.ctx };
        let mut build = cargo.build(TREES);
        build.artifacts.push(root.path("target/renamed.wasm"));

        let error = refusal(build.run(&root.ctx, &mut cargo.command("one", READS), &NONE));
        assert!(error.contains("target/renamed.wasm"), "{error}");
        assert!(!root.path("target/renamed.wasm").exists());
    }

    #[test]
    fn an_inherited_cargo_or_rust_variable_builds_again_but_one_cargo_sets_per_crate_does_not() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
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
        let build = cargo.build(TREES);
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
    fn a_build_that_read_a_repository_file_outside_its_trees_fails_naming_it() {
        let root = cargo_workspace();
        root.write("skir-src/protocol.skir", "struct Old {}");
        let outside = tempfile::tempdir().unwrap();
        let toolchain = outside.path().join("rustlib/src/lib.rs");
        fs::create_dir_all(toolchain.parent().unwrap()).unwrap();
        fs::write(&toolchain, "pub fn std() {}").unwrap();
        // Lands outside the trees only once its `..` is applied.
        let roundabout = root.path("backend/../skir-src/protocol.skir");
        let generated = root.path("target/debug/build/schema/out/files.rs");
        let reads = [
            "backend/src/lib.rs".to_owned(),
            roundabout.display().to_string(),
            toolchain.display().to_string(),
            generated.display().to_string(),
        ];
        let reads: Vec<&str> = reads.iter().map(String::as_str).collect();
        let cargo = FakeCargo { ctx: &root.ctx };

        let error = refusal(cargo.build(TREES).run(
            &root.ctx,
            &mut cargo.command("one", &reads),
            &NONE,
        ));
        assert_eq!(
            error,
            "the build stack read skir-src/protocol.skir, outside the folders it declares \
             (backend); declare the folder that holds each"
        );
        let declared = cargo.build(&["backend", "skir-src"]);
        let outcome = declared.run(&root.ctx, &mut cargo.command("one", &reads), &NONE);
        assert_eq!(outcome.unwrap(), Outcome::Compiled);
    }

    #[test]
    fn a_build_without_a_dependency_file_beside_an_artifact_fails() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let mut silent = cargo.command("one", READS);
        silent.env("DEP_INFO", "/dev/null");
        let error = refusal(cargo.build(TREES).run(&root.ctx, &mut silent, &NONE));
        assert!(error.starts_with("cannot read "), "{error}");
        assert!(
            error.ends_with("stack.d, which names what the build stack read"),
            "{error}"
        );
    }

    #[test]
    fn a_build_script_that_watches_a_file_outside_the_trees_fails_the_build_naming_it() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let registry = tempfile::tempdir().unwrap();
        let mut build = cargo.build(TREES);
        build
            .packages
            .insert("schema".to_owned(), root.path("backend/database/schema"));
        build
            .packages
            .insert("ring".to_owned(), registry.path().join("ring-0.17.0"));
        let messages = cargo.build_script(
            "schema",
            "cargo:rerun-if-changed=build.rs\ncargo::rerun-if-changed=../../../skir-src/x.skir\n",
        ) + &cargo.build_script(
            "ring",
            "cargo:rerun-if-changed=crypto/curve25519.c\ncargo:rerun-if-changed=/usr/include/x.h\n",
        );
        let mut command = cargo.command("one", READS);
        command.env("MESSAGES", messages);

        let error = refusal(build.run(&root.ctx, &mut command, &NONE));
        assert_eq!(
            error,
            "the build stack read /usr/include/x.h, skir-src/x.skir, outside the folders it \
             declares (backend); declare the folder that holds each"
        );
    }

    #[test]
    fn a_changed_value_of_a_variable_a_build_script_watches_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let mut build = cargo.build(TREES);
        build
            .packages
            .insert("cc".to_owned(), root.path("backend/cc"));
        let messages = cargo.build_script(
            "cc",
            "cargo:rerun-if-env-changed=CC\ncargo::rerun-if-env-changed=CARGO_CFG_TARGET_OS\n",
        );
        let run = |cc: &str| {
            let mut command = cargo.command("one", READS);
            command.env("MESSAGES", &messages);
            build
                .run(&root.ctx, &mut command, &NONE.with("CC", cc))
                .unwrap()
        };

        assert_eq!(run("clang"), Outcome::Compiled);
        assert_eq!(run("clang"), Outcome::Reused);
        assert_eq!(run("gcc"), Outcome::Compiled);
    }

    #[test]
    fn a_build_script_whose_output_cargo_keeps_elsewhere_fails_the_build_loudly() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let mut build = cargo.build(TREES);
        build
            .packages
            .insert("schema".to_owned(), root.path("backend/schema"));
        let messages = cargo.build_script("schema", "");
        fs::remove_file(root.path("target/debug/build/schema/0123/run/stdout")).unwrap();
        let mut command = cargo.command("one", READS);
        command.env("MESSAGES", messages);

        let error = refusal(build.run(&root.ctx, &mut command, &NONE));
        assert!(error.ends_with("its layout changed"), "{error}");
    }

    #[test]
    fn real_cargo_tells_which_build_script_output_to_read_through_its_json_messages() {
        // Where Cargo keeps a build script's output is its own layout; a toolchain that moves it
        // must fail here, and in every build, instead of missing what the script watches.
        let root = TempRoot::new();
        root.git(&["init", "--quiet"]);
        root.write(".gitignore", "target/\n");
        root.write(
            "probe/Cargo.toml",
            "[package]\nname = \"probe\"\nversion = \"0.1.0\"\nedition = \"2024\"\n",
        );
        root.write(
            "probe/build.rs",
            "fn main() {\n    println!(\"cargo::rerun-if-env-changed=PROBE_WATCHED\");\n    \
             println!(\"cargo::rerun-if-changed=build.rs\");\n}\n",
        );
        root.write("probe/src/lib.rs", "");
        root.ctx
            .tool(
                ".",
                "cargo",
                &[
                    "generate-lockfile",
                    "--offline",
                    "--quiet",
                    "--manifest-path",
                    "probe/Cargo.toml",
                ],
            )
            .run()
            .unwrap();
        let build =
            CargoBuild::in_workspace(&root.ctx, "probe", "probe/Cargo.toml", &[], |target| {
                vec![target.join("debug/libprobe.rlib")]
            })
            .unwrap();
        let run = |watched: &str| {
            let mut cargo = root.ctx.tool(
                ".",
                "cargo",
                &[
                    "build",
                    "--quiet",
                    "--offline",
                    "--manifest-path",
                    "probe/Cargo.toml",
                ],
            );
            // The test's own Cargo must not move the probe's target elsewhere.
            for name in [
                "CARGO_TARGET_DIR",
                "CARGO_BUILD_TARGET_DIR",
                "CARGO_BUILD_BUILD_DIR",
            ] {
                cargo.env_remove(name);
            }
            build
                .run(&root.ctx, &mut cargo, &NONE.with("PROBE_WATCHED", watched))
                .unwrap()
        };

        assert_eq!(run("one"), Outcome::Compiled);
        assert_eq!(run("one"), Outcome::Reused);
        assert_eq!(run("two"), Outcome::Compiled, "after PROBE_WATCHED changed");
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
