//! Cargo builds reused while their declared inputs are unchanged. Cargo itself judges local
//! crates by file times, so a fresh checkout recompiles every one of them even when a cached target
//! holds what they would produce. Cargo's own content based check (`-Z checksum-freshness`) is
//! refused on the stable toolchain the repository pins (1.100), so this module decides instead.
//! Once checksum freshness is stable, delete the declared trees and their checks: keep only the
//! cached target and the removal of each artifact before Cargo runs, and let Cargo decide.
//!
//! A build declares the files and folders it reads, its trees: its workspace's manifest and lock
//! file, the folder of every repository package reachable from the selected packages (those its
//! command names with `-p`, or every member, followed through normal and build dependencies, and
//! through the selected packages' dev dependencies when it builds their tests), and the files or
//! folders outside its own folder such a package declares it embeds, in its manifest:
//!
//! ```toml
//! [package.metadata.typewriter]
//! inputs = ["../capabilities.toml"]
//! ```
//!
//! A stamp beside the artifacts records:
//!
//! - the command, with the variables it sets but the job count, which changes no output;
//! - the toolchain: `rustc -vV`, and the path and `--version` of the C compiler (`CC`, or `cc`) and
//!   of each linker a `CARGO_TARGET_<TRIPLE>_LINKER` names, which build scripts and the final link
//!   run;
//! - Cargo's whole configuration surface: every inherited `CARGO*` and `RUST*` variable but those
//!   Cargo sets for each crate itself, and every configuration file Cargo loads (`.cargo/config.toml`
//!   and `.cargo/config` from the directory it runs in up to the file system root, then those in
//!   Cargo's home), each recorded absent while it does not exist;
//! - the sha256 of every file in the trees that Git does not ignore (tracked, or untracked but not
//!   ignored, so a new module counts before it is added; the listing generators use too) and of
//!   the generated protocol sources inside them, each taken before Cargo starts, so an edit while it
//!   runs builds again next time;
//! - the sha256 of each artifact and of each variable outside `CARGO*` and `RUST*` a build script
//!   watches (`rerun-if-env-changed`), taken after it ran.
//!
//! While all of them match, Cargo does not run at all. Files outside the repository are not
//! listed: the toolchain's sources change with `rustc -vV`, and a dependency from a registry or Git
//! with `Cargo.lock`. A package with no source outside the repository (a local `[patch]`) fails the
//! build, as neither would notice an edit to it.
//!
//! So that no input goes unseen, a build that read a repository file its stamp does not hash
//! fails, naming it. The dependency file Cargo writes beside each artifact names what the crates
//! read (an `include_str!` of a file elsewhere) and what the build scripts of the repository's
//! packages watch (`rerun-if-changed`); each such file must be one the stamp lists, or lie in a
//! folder inside the trees a build script watches; what Cargo writes to its target or build
//! directory is output, never input. One outside the trees is declared by the crate
//! that reads it; one Git ignores is no input at all. A registry or Git dependency may read and
//! watch what it likes outside the repository: its sources change with `Cargo.lock`, and the
//! system files it watches are the toolchain's. A build script's output is read only for the
//! variables it watches.
//!
//! Each crate declares its own embeds rather than every build counting its workspace's folder or
//! all of `backend`: a build then rebuilds only for what it compiles, so the release components do
//! not rebuild for an edit to a component test case or `backend/AGENTS.md`, nor the stack binary
//! for a component it never embeds.
//!
//! Known issues: a variable a crate reads at compile time (`env!`, `option_env!`) outside `CARGO*`
//! and `RUST*` is not an input unless a build script watches it, since Cargo's dependency file
//! beside an artifact leaves those out; a procedural macro that reads a file no dependency file
//! names is trusted, as Cargo trusts it; and a file Git ignores inside a folder a build script
//! watches is not hashed. Where a build script's output lies is found from the `out_dir` Cargo's
//! JSON messages name; a toolchain that moves it fails the build loudly.

use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::{Component, Path, PathBuf};
use std::process::Command;

use anyhow::{Context as _, Result, bail};
use serde::Deserialize;

use crate::digest::{Digest, Entry, Environment, Listing, Stamp, listed};
use crate::{CommandExt as _, Context, generate};

/// One Cargo invocation, the files and folders it reads and what it produces.
pub struct CargoBuild<'a> {
    /// Names the stamp, which lies beside the first artifact as `<name>.xtask-stamp`.
    pub name: &'a str,
    /// The root relative folders and files that are the build's inputs (`.` for the whole
    /// repository).
    pub trees: Vec<String>,
    /// The absolute paths of what the build produces.
    pub artifacts: Vec<PathBuf>,
    /// The Cargo target directory the build writes to, as `cargo metadata` names it; what a build
    /// script generates there is output, never input.
    pub target: PathBuf,
    /// Where Cargo keeps its intermediate output, the target directory unless configured apart
    /// (`build.build-dir`); output, never input, as well.
    pub build_directory: PathBuf,
}

impl<'a> CargoBuild<'a> {
    /// The build `name` that `cargo` runs in the Cargo workspace of `manifest`, root relative, of
    /// the artifacts `artifacts` names below the workspace's target directory. Its trees are the
    /// workspace's manifest and lock file, the folder of every repository package reachable from
    /// the packages `cargo` selects, and what each of those declares it embeds from outside its
    /// folder. Fails on such a package with no source outside the repository, such as a local
    /// `[patch]`, which neither the stamp nor `Cargo.lock` follows.
    pub fn in_workspace(
        ctx: &Context,
        name: &'a str,
        manifest: &str,
        cargo: &Command,
        artifacts: impl FnOnce(&Path) -> Vec<PathBuf>,
    ) -> Result<Self> {
        let metadata = metadata(ctx, manifest, Packages::All)?;
        let repository = Repository::of(ctx)?;
        let compiled = metadata.compiled_by(cargo)?;
        // Not the workspace's whole folder: anything else in it a crate reads, it declares.
        let mut dirs = vec![
            metadata.workspace_root.join("Cargo.toml"),
            metadata.workspace_root.join("Cargo.lock"),
        ];
        for package in metadata
            .packages
            .iter()
            .filter(|package| package.source.is_none() && compiled.contains(package.id.as_str()))
        {
            let Some(dir) = package.manifest_path.parent() else {
                continue;
            };
            if repository.relative(dir).is_none() {
                bail!(
                    "the build {name} compiles the package {} from {}, a folder outside the \
                     repository: neither the stamp nor Cargo.lock notices an edit there; move it \
                     into the repository or depend on a released version",
                    package.name,
                    dir.display()
                );
            }
            dirs.push(dir.to_owned());
            dirs.extend(
                package
                    .declared_inputs()
                    .map(|input| normalize(&dir.join(input))),
            );
        }
        let mut trees = Vec::new();
        for dir in &dirs {
            if let Some(relative) = repository.relative(dir) {
                trees.push(tree(relative));
            }
        }
        trees.sort();
        trees.dedup();
        // A tree inside another adds nothing: a member's manifest beside the workspace's, say.
        let held = trees.clone();
        trees.retain(|tree| {
            !held
                .iter()
                .any(|other| other != tree && (other == "." || Path::new(tree).starts_with(other)))
        });
        Ok(Self {
            name,
            trees,
            artifacts: artifacts(&metadata.target_directory),
            build_directory: metadata
                .build_directory
                .clone()
                .unwrap_or_else(|| metadata.target_directory.clone()),
            target: metadata.target_directory,
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
    /// Where Cargo keeps intermediate output, when its version names it.
    #[serde(default)]
    build_directory: Option<PathBuf>,
    pub workspace_root: PathBuf,
    pub packages: Vec<Package>,
    workspace_members: Vec<String>,
    /// The dependency graph; absent from a [`Packages::Members`] read.
    resolve: Option<Resolve>,
}

impl Metadata {
    /// The ids of every package `cargo` compiles: the packages it selects (each `-p` or
    /// `--package`, or every member when it names none or passes `--workspace`) and every package
    /// reachable from them through normal and build dependencies, and through the selected
    /// packages' development dependencies when it builds their tests, benches or examples.
    fn compiled_by(&self, cargo: &Command) -> Result<BTreeSet<&str>> {
        let args: Vec<&str> = cargo.get_args().filter_map(|arg| arg.to_str()).collect();
        let mut specs = Vec::new();
        let mut whole = false;
        let mut dev = false;
        let mut args_iter = args.iter();
        while let Some(arg) = args_iter.next() {
            match *arg {
                "-p" | "--package" => specs.extend(args_iter.next().copied()),
                "--workspace" | "--all" => whole = true,
                "--all-targets" | "--tests" | "--test" | "--benches" | "--bench" | "--examples"
                | "--example" => dev = true,
                other => {
                    if let Some(spec) = other.strip_prefix("--package=") {
                        specs.push(spec);
                    } else if let Some(spec) = other.strip_prefix("-p").filter(|s| !s.is_empty()) {
                        specs.push(spec);
                    }
                }
            }
        }
        let mut selected = BTreeSet::new();
        if whole || specs.is_empty() {
            selected.extend(self.workspace_members.iter().map(String::as_str));
        }
        for spec in specs {
            let name = spec.split('@').next().unwrap_or(spec);
            let package = self
                .packages
                .iter()
                .filter(|package| package.name == name)
                .min_by_key(|package| !self.workspace_members.contains(&package.id))
                .with_context(|| format!("Cargo's metadata lists no package {name} to build"))?;
            selected.insert(package.id.as_str());
        }
        let resolve = self
            .resolve
            .as_ref()
            .context("Cargo's metadata holds no dependency graph")?;
        let nodes: BTreeMap<&str, &Node> = resolve
            .nodes
            .iter()
            .map(|node| (node.id.as_str(), node))
            .collect();
        let mut compiled = BTreeSet::new();
        let mut pending: Vec<(&str, bool)> = selected.iter().map(|id| (*id, dev)).collect();
        while let Some((id, with_dev)) = pending.pop() {
            if !compiled.insert(id) {
                continue;
            }
            let Some(node) = nodes.get(id) else {
                continue;
            };
            for dep in &node.deps {
                let follows = dep
                    .dep_kinds
                    .iter()
                    .any(|kind| kind.kind.as_deref() != Some("dev") || with_dev);
                if follows {
                    pending.push((dep.pkg.as_str(), false));
                }
            }
        }
        Ok(compiled)
    }
}

/// The resolved dependency graph of `cargo metadata`.
#[derive(Deserialize)]
struct Resolve {
    nodes: Vec<Node>,
}

#[derive(Deserialize)]
struct Node {
    id: String,
    deps: Vec<NodeDep>,
}

#[derive(Deserialize)]
struct NodeDep {
    pkg: String,
    dep_kinds: Vec<DepKind>,
}

#[derive(Deserialize)]
struct DepKind {
    /// `dev`, `build`, or none for a normal dependency.
    kind: Option<String>,
}

#[derive(Deserialize)]
pub struct Package {
    /// Cargo's opaque id, which the component suite's artifact manifest names the package by.
    pub id: String,
    pub name: String,
    pub manifest_path: PathBuf,
    /// Where a dependency comes from; none for a package in the repository.
    pub source: Option<String>,
    pub targets: Vec<Target>,
    /// The manifest's `[package.metadata]` table.
    #[serde(default)]
    metadata: Option<PackageMetadata>,
}

impl Package {
    /// What the package declares it embeds from outside its own folder, relative to its folder
    /// (`[package.metadata.typewriter] inputs`).
    fn declared_inputs(&self) -> impl Iterator<Item = &PathBuf> {
        self.metadata
            .iter()
            .flat_map(|metadata| &metadata.typewriter)
            .flat_map(|typewriter| &typewriter.inputs)
    }
}

#[derive(Deserialize)]
struct PackageMetadata {
    #[serde(default)]
    typewriter: Option<TypewriterMetadata>,
}

#[derive(Deserialize)]
struct TypewriterMetadata {
    #[serde(default)]
    inputs: Vec<PathBuf>,
}

#[derive(Deserialize)]
pub struct Target {
    /// The target's name, which names its artifact (a library's crate name).
    pub name: String,
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
    out_dir: Option<PathBuf>,
}

impl CargoBuild<'_> {
    /// Runs `cargo` unless its stamp records the same command and toolchain and every input still
    /// has the same contents, checks that it read no repository file the stamp does not hash,
    /// then stamps the artifacts with the inputs it ran on. Cargo prints its messages as JSON,
    /// which the check reads; its diagnostics stay as they are.
    pub fn run(&self, ctx: &Context, cargo: &mut Command, env: &Environment) -> Result<Outcome> {
        cargo.arg("--message-format=json-render-diagnostics");
        let digest = self.digest(ctx, cargo, env)?;
        let stamp = self.stamp()?;
        let files = self.files(ctx)?;
        let mut inputs: Vec<Entry> = files.iter().cloned().map(Entry::File).collect();
        inputs.extend(configs(ctx, cargo, env).into_iter().map(Entry::File));
        inputs.sort();
        inputs.dedup();
        if let Some(recorded) = stamp.entries(&ctx.root, &digest, env)
            && self
                .artifact_entries()
                .iter()
                .chain(&inputs)
                .all(|entry| recorded.contains(entry))
        {
            return Ok(Outcome::Reused);
        }
        // What the build starts from, hashed before Cargo runs: an input edited while it runs then
        // differs from its stamp, and the next run builds again.
        let mut sums = inputs
            .into_iter()
            .map(|input| input.sum(&ctx.root, env))
            .collect::<Result<Vec<_>>>()?;
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
        // What it produced, and the variables its scripts watch, which no run changes.
        for entry in self
            .artifact_entries()
            .into_iter()
            .chain(self.check(ctx, &messages, &files)?)
        {
            sums.push(entry.sum(&ctx.root, env)?);
        }
        stamp
            .record(&digest, &sums)
            .with_context(|| format!("cannot stamp the build {}", self.name))?;
        Ok(Outcome::Compiled)
    }

    fn artifact_entries(&self) -> Vec<Entry> {
        self.artifacts
            .iter()
            .map(|artifact| Entry::File(artifact.display().to_string()))
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
        let trees: Vec<&str> = self.trees.iter().map(String::as_str).collect();
        let mut files = listed(ctx, &trees, Listing::Inputs)?;
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
        // How many jobs Cargo runs changes no output, so builds asking for different counts share
        // one stamp.
        let mut args = cargo.get_args();
        while let Some(arg) = args.next() {
            match arg.to_str() {
                Some("--jobs" | "-j") => {
                    args.next();
                    continue;
                }
                Some(text)
                    if text.starts_with("--jobs=")
                        || (text.starts_with("-j") && text.len() > 2) =>
                {
                    continue;
                }
                _ => {}
            }
            digest.update(&[0]);
            digest.update(arg.as_encoded_bytes());
        }
        for (key, value) in cargo.get_envs() {
            if key == "CARGO_BUILD_JOBS" {
                continue;
            }
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
            if (name.starts_with("CARGO") || name.starts_with("RUST"))
                && !cargo_sets(name)
                && name != "CARGO_BUILD_JOBS"
            {
                digest.update(&[0]);
                digest.update(name.as_bytes());
                digest.update(&[1]);
                digest.update(value.as_encoded_bytes());
            }
        }
        let toolchain = ctx.tool(".", "rustc", &["-vV"]).output_text()?;
        digest.update(toolchain.as_bytes());
        for program in native_tools(env) {
            digest.update(&[0]);
            digest.update(program.as_bytes());
            digest.update(&[1]);
            match find_program(&program, env) {
                Some(path) => {
                    digest.update(path.as_os_str().as_encoded_bytes());
                    match Command::new(&path).arg("--version").output() {
                        Ok(output) => {
                            digest.update(&output.stdout);
                            digest.update(&output.stderr);
                        }
                        Err(error) => digest.update(format!("cannot run: {error}").as_bytes()),
                    }
                }
                None => digest.update(b"absent"),
            }
        }
        Ok(digest)
    }

    /// Fails, naming each, when the build read a repository file that is not among `hashed`, the
    /// root relative files its stamp holds: one the dependency file beside an artifact names
    /// outside its trees, or one Git ignores inside them. Cargo names there what the crates read
    /// and what the build scripts of the repository's packages watch; a watched folder inside the
    /// trees counts through the files Git lists in it. Returns each variable outside `CARGO*` and
    /// `RUST*` a build script watches, which the stamp records with its value.
    fn check(&self, ctx: &Context, messages: &str, hashed: &[String]) -> Result<Vec<Entry>> {
        let repository = Repository::of(ctx)?;
        let hashed: BTreeSet<&str> = hashed.iter().map(String::as_str).collect();
        let mut outside = BTreeSet::new();
        let mut ignored = BTreeSet::new();
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
                let Some(relative) = repository.relative(&file) else {
                    continue;
                };
                let name = relative.display().to_string();
                if file.starts_with(&self.target)
                    || file.starts_with(&self.build_directory)
                    || hashed.contains(name.as_str())
                {
                    continue;
                }
                if !self.holds(relative) {
                    outside.insert(name);
                } else if !file.is_dir() {
                    ignored.insert(name);
                }
            }
        }
        let mut refusals = Vec::new();
        if !outside.is_empty() {
            refusals.push(format!(
                "the build {} read {}, outside the files and folders it declares ({}); the crate \
                 that reads each declares it in its manifest's [package.metadata.typewriter] \
                 inputs",
                self.name,
                outside.into_iter().collect::<Vec<_>>().join(", "),
                self.trees.join(", ")
            ));
        }
        if !ignored.is_empty() {
            refusals.push(format!(
                "the build {} read {}, which Git ignores, so its stamp cannot notice an edit; let \
                 Git list each or read it at run time instead",
                self.name,
                ignored.into_iter().collect::<Vec<_>>().join(", ")
            ));
        }
        if !refusals.is_empty() {
            bail!("{}", refusals.join("\n"));
        }
        let mut watched = BTreeSet::new();
        for line in messages.lines().filter(|line| !line.trim().is_empty()) {
            let message: Message = serde_json::from_str(line)
                .with_context(|| format!("Cargo printed an unexpected message: {line}"))?;
            if message.reason != "build-script-executed" {
                continue;
            }
            let out_dir = message.out_dir.with_context(|| {
                format!(
                    "Cargo named no output folder for a build script of the build {}",
                    self.name
                )
            })?;
            for name in watched_variables(&build_script_output(&out_dir)?) {
                if !(name.starts_with("CARGO") || name.starts_with("RUST")) {
                    watched.insert(Entry::Variable(name.to_owned()));
                }
            }
        }
        Ok(watched.into_iter().collect())
    }
}

/// The variables a build script asks Cargo to watch (`rerun-if-env-changed`), in either syntax
/// (`cargo::` or the older `cargo:`). The files it watches need no reading here: Cargo names those
/// of the repository's packages in the dependency file beside each artifact.
fn watched_variables(printed: &str) -> impl Iterator<Item = &str> {
    printed
        .lines()
        .filter_map(|line| {
            line.strip_prefix("cargo::")
                .or_else(|| line.strip_prefix("cargo:"))
        })
        .filter_map(|directive| directive.strip_prefix("rerun-if-env-changed="))
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

/// The C compiler and linkers a build may run, as `env` names them: the compiler `CC` names, or
/// `cc`, which build scripts compile C with (through the `cc` crate) and Cargo links with on Unix
/// unless told otherwise, and the linker each `CARGO_TARGET_<TRIPLE>_LINKER` names. A linker a
/// configuration file names is hashed as that file.
fn native_tools(env: &Environment) -> BTreeSet<String> {
    let mut tools = BTreeSet::from(["cc".to_owned()]);
    let first_word = |value: &std::ffi::OsStr| {
        value
            .to_str()
            .and_then(|value| value.split_whitespace().next())
            .map(str::to_owned)
    };
    tools.extend(env.get("CC").and_then(first_word));
    for (name, value) in env.iter() {
        if name.starts_with("CARGO_TARGET_") && name.ends_with("_LINKER") {
            tools.extend(first_word(value));
        }
    }
    tools
}

/// Where `program` lies: itself when it names a path, else the first executable of that name on
/// `env`'s `PATH`.
fn find_program(program: &str, env: &Environment) -> Option<PathBuf> {
    use std::os::unix::fs::PermissionsExt as _;
    let executable = |path: &Path| {
        fs::metadata(path)
            .is_ok_and(|meta| meta.is_file() && meta.permissions().mode() & 0o111 != 0)
    };
    if program.contains('/') {
        let path = PathBuf::from(program);
        return executable(&path).then_some(path);
    }
    std::env::split_paths(env.get("PATH")?)
        .map(|dir| dir.join(program))
        .find(|path| executable(path))
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
        CARGO_TREES as TREES, FakeCargo, RealCargo, cargo_workspace, refusal,
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
    fn an_input_edited_while_cargo_runs_builds_again() {
        // The stamp records what the build started from, not what lies there when it ends.
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
        cargo.during("printf %s 'fn main() { edited_mid_build() }' > src/lib.rs");

        assert_eq!(cargo.run(&build), Outcome::Compiled);
        assert_eq!(cargo.run(&build), Outcome::Compiled);
        assert_eq!(cargo.run(&build), Outcome::Reused);
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
    fn a_build_counts_every_repository_package_it_builds_and_what_each_declares_it_embeds() {
        let root = RealCargo::workspace();
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
            "[package]\nname = \"schema\"\nversion = \"0.1.0\"\nedition = \"2024\"\n\n\
             [package.metadata.typewriter]\ninputs = [\"../capabilities.toml\"]\n",
        );
        let schema = "pub const CAPABILITIES: &str = include_str!(\"../../capabilities.toml\");\n";
        root.write("backend/database/schema/src/lib.rs", schema);
        root.write("backend/database/capabilities.toml", "read = true");
        root.write("backend/database/notes.md", "not read");
        root.write("backend/tests/component/AGENTS.md", "not read");
        let cargo = RealCargo::new(&root, "backend/tests/component/Cargo.toml", "suite").unwrap();

        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Compiled);
        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Reused);
        for (file, contents) in [
            (
                "backend/database/schema/src/lib.rs",
                &*format!("{schema}pub fn edited() {{}}\n"),
            ),
            ("backend/database/capabilities.toml", "read = false"),
        ] {
            root.write(file, contents);
            assert_eq!(
                cargo.run(&NONE).unwrap(),
                Outcome::Compiled,
                "after writing {file}"
            );
        }
        root.write(
            "backend/tests/component/Cargo.toml",
            "[workspace]\nmembers = [\"suite\"]\nresolver = \"3\"\n\n[workspace.package]\n\
             edition = \"2024\"\n",
        );
        assert_eq!(
            cargo.run(&NONE).unwrap(),
            Outcome::Compiled,
            "after the workspace manifest changed"
        );
        // Neither a package's folder nor a declared embed, though the first lies in the
        // workspace's folder.
        for file in [
            "backend/tests/component/AGENTS.md",
            "backend/database/notes.md",
        ] {
            root.write(file, "edited, still not read");
            assert_eq!(
                cargo.run(&NONE).unwrap(),
                Outcome::Reused,
                "after writing {file}"
            );
        }
    }

    #[test]
    fn an_edit_to_a_workspace_member_the_build_does_not_compile_reuses_it() {
        // `cargo build -p probe` compiles probe and what it depends on, not its dev dependencies
        // nor the workspace's other members.
        let root = RealCargo::workspace();
        root.write(
            "ws/Cargo.toml",
            "[workspace]\nmembers = [\"probe\", \"base\", \"tested\", \"sibling\"]\n\
             resolver = \"3\"\n",
        );
        root.write(
            "ws/probe/Cargo.toml",
            "[package]\nname = \"probe\"\nversion = \"0.1.0\"\nedition = \"2024\"\n\n\
             [dependencies]\nbase = { path = \"../base\" }\n\n\
             [dev-dependencies]\ntested = { path = \"../tested\" }\n",
        );
        root.write("ws/probe/src/lib.rs", "pub use base::*;\n");
        for member in ["base", "tested", "sibling"] {
            root.write(
                &format!("ws/{member}/Cargo.toml"),
                &format!(
                    "[package]\nname = \"{member}\"\nversion = \"0.1.0\"\nedition = \"2024\"\n"
                ),
            );
            root.write(&format!("ws/{member}/src/lib.rs"), "");
        }
        let cargo = RealCargo::new(&root, "ws/Cargo.toml", "probe").unwrap();

        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Compiled);
        for member in ["sibling", "tested"] {
            root.write(&format!("ws/{member}/src/lib.rs"), "pub fn edited() {}\n");
            assert_eq!(
                cargo.run(&NONE).unwrap(),
                Outcome::Reused,
                "after editing {member}"
            );
        }
        root.write("ws/base/src/lib.rs", "pub fn edited() {}\n");
        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Compiled);
    }

    #[test]
    fn a_build_that_differs_only_in_its_parallelism_is_reused() {
        // The components check and the stack build the same components with different job
        // counts; neither may undo the other's stamp.
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
        let run = |args: &[&str], env: &Environment| {
            let mut command = cargo.command("one", READS);
            command.args(args);
            build.run(&root.ctx, &mut command, env).unwrap()
        };

        assert_eq!(run(&["--jobs", "2"], &NONE), Outcome::Compiled);
        assert_eq!(run(&[], &NONE), Outcome::Reused);
        assert_eq!(run(&["--jobs=8"], &NONE), Outcome::Reused);
        assert_eq!(run(&["-j", "3"], &NONE), Outcome::Reused);
        assert_eq!(
            run(&[], &NONE.with("CARGO_BUILD_JOBS", "4")),
            Outcome::Reused
        );
        assert_eq!(run(&["--release"], &NONE), Outcome::Compiled);
    }

    #[test]
    fn a_different_c_compiler_or_linker_builds_again() {
        // Build scripts compile C with it, and the final link runs through one.
        use std::os::unix::fs::PermissionsExt as _;
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
        let tools = root.dir("tools");
        let tool = |name: &str, version: &str| {
            let path = tools.join(name);
            fs::write(&path, format!("#!/bin/sh\necho '{version}'\n")).unwrap();
            fs::set_permissions(&path, fs::Permissions::from_mode(0o755)).unwrap();
        };
        tool("cc", "clang version 21");
        tool("gcc-13", "gcc 13.1");
        tool("wasm-ld", "wasm-ld 19");
        let path = NONE.with("PATH", &tools.display().to_string());
        let run = |env: &Environment| {
            build
                .run(&root.ctx, &mut cargo.command("one", READS), env)
                .unwrap()
        };

        assert_eq!(run(&path), Outcome::Compiled);
        assert_eq!(run(&path), Outcome::Reused);
        tool("cc", "clang version 22");
        assert_eq!(run(&path), Outcome::Compiled, "after cc changed");
        let gcc = path.clone().with("CC", "gcc-13");
        assert_eq!(
            run(&gcc),
            Outcome::Compiled,
            "after CC named another compiler"
        );
        assert_eq!(run(&gcc), Outcome::Reused);
        tool("gcc-13", "gcc 13.2");
        assert_eq!(run(&gcc), Outcome::Compiled, "after that compiler changed");
        let linked = gcc.with("CARGO_TARGET_WASM32_WASIP2_LINKER", "wasm-ld");
        assert_eq!(run(&linked), Outcome::Compiled);
        assert_eq!(run(&linked), Outcome::Reused);
        tool("wasm-ld", "wasm-ld 20");
        assert_eq!(run(&linked), Outcome::Compiled, "after the linker changed");
    }

    #[test]
    fn what_cargo_writes_to_a_separate_build_directory_is_no_input() {
        let root = RealCargo::workspace();
        root.write(".gitignore", "target/\nbuild-out/\n");
        root.write(".cargo/config.toml", "[build]\nbuild-dir = \"build-out\"\n");
        root.write(
            "probe/build.rs",
            "fn main() {\n    let out = std::env::var(\"OUT_DIR\").unwrap();\n    \
             std::fs::write(format!(\"{out}/generated.rs\"), \"pub fn generated() {}\").unwrap();\n    \
             println!(\"cargo::rerun-if-changed=build.rs\");\n}\n",
        );
        root.write(
            "probe/src/lib.rs",
            "include!(concat!(env!(\"OUT_DIR\"), \"/generated.rs\"));\n",
        );
        let cargo = RealCargo::new(&root, "probe/Cargo.toml", "probe").unwrap();

        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Compiled);
        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Reused);
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
            "the build stack read skir-src/protocol.skir, outside the files and folders it \
             declares (backend); the crate that reads each declares it in its manifest's \
             [package.metadata.typewriter] inputs"
        );
        let declared = cargo.build(&["backend", "skir-src"]);
        let outcome = declared.run(&root.ctx, &mut cargo.command("one", &reads), &NONE);
        assert_eq!(outcome.unwrap(), Outcome::Compiled);
    }

    #[test]
    fn a_build_that_read_a_file_git_ignores_inside_its_trees_fails_naming_it() {
        // Its stamp could not notice an edit to it.
        let root = cargo_workspace();
        root.write(".gitignore", "target/\nruns\n*.zip\n");
        root.write("backend/src/fixture.zip", "zipped");
        let cargo = FakeCargo { ctx: &root.ctx };

        let error = refusal(cargo.build(TREES).run(
            &root.ctx,
            &mut cargo.command("one", &["backend/src/lib.rs", "backend/src/fixture.zip"]),
            &NONE,
        ));
        assert_eq!(
            error,
            "the build stack read backend/src/fixture.zip, which Git ignores, so its stamp \
             cannot notice an edit; let Git list each or read it at run time instead"
        );
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
    fn a_repository_build_script_that_watches_a_file_outside_the_trees_fails_the_build_naming_it() {
        let root = RealCargo::workspace();
        root.write("skir-src/x.skir", "struct X {}");
        root.write(
            "probe/build.rs",
            "fn main() {\n    println!(\"cargo::rerun-if-changed=build.rs\");\n    \
             println!(\"cargo::rerun-if-changed=../skir-src/x.skir\");\n}\n",
        );
        let cargo = RealCargo::new(&root, "probe/Cargo.toml", "probe").unwrap();

        assert_eq!(
            refusal(cargo.run(&NONE)),
            "the build probe read skir-src/x.skir, outside the files and folders it declares \
             (probe); the crate that reads each declares it in its manifest's \
             [package.metadata.typewriter] inputs"
        );
    }

    #[test]
    fn a_build_script_of_a_registry_crate_may_watch_any_file_outside_the_repository() {
        // As a registry crate's script watches the system's headers.
        let root = RealCargo::workspace();
        let elsewhere = tempfile::tempdir().unwrap();
        let header = elsewhere.path().join("include/x.h");
        fs::create_dir_all(header.parent().unwrap()).unwrap();
        fs::write(&header, "int x;").unwrap();
        RealCargo::vendor(
            &root,
            &elsewhere.path().join("registry"),
            "ring",
            &format!(
                "fn main() {{\n    println!(\"cargo::rerun-if-changed={}\");\n}}\n",
                header.display()
            ),
        );
        root.write(
            "probe/Cargo.toml",
            "[package]\nname = \"probe\"\nversion = \"0.1.0\"\nedition = \"2024\"\n\n\
             [dependencies]\nring = \"0.1.0\"\n",
        );
        let cargo = RealCargo::new(&root, "probe/Cargo.toml", "probe").unwrap();

        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Compiled);
        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Reused);
    }

    #[test]
    fn a_path_package_outside_the_repository_fails_the_build_naming_it() {
        // Neither the stamp nor Cargo.lock would notice an edit to it, as to a local [patch].
        let root = RealCargo::workspace();
        let elsewhere = tempfile::tempdir().unwrap();
        let patched = elsewhere.path().join("patched");
        fs::create_dir_all(patched.join("src")).unwrap();
        fs::write(
            patched.join("Cargo.toml"),
            "[package]\nname = \"patched\"\nversion = \"0.1.0\"\nedition = \"2024\"\n",
        )
        .unwrap();
        fs::write(patched.join("src/lib.rs"), "").unwrap();
        root.write(
            "probe/Cargo.toml",
            &format!(
                "[package]\nname = \"probe\"\nversion = \"0.1.0\"\nedition = \"2024\"\n\n\
                 [dependencies]\npatched = {{ path = \"{}\" }}\n",
                patched.display()
            ),
        );

        let error = refusal(RealCargo::new(&root, "probe/Cargo.toml", "probe"));
        assert!(
            error.starts_with("the build probe compiles the package patched from "),
            "{error}"
        );
        assert!(
            error.ends_with(
                "patched, a folder outside the repository: neither the stamp nor Cargo.lock \
                 notices an edit there; move it into the repository or depend on a released \
                 version"
            ),
            "{error}"
        );
    }

    #[test]
    fn a_build_script_that_watches_a_folder_inside_the_trees_builds_again_when_a_file_in_it_changes()
     {
        let root = RealCargo::workspace();
        root.write("probe/migrations/1.surql", "DEFINE TABLE one;");
        root.write(
            "probe/build.rs",
            "fn main() {\n    println!(\"cargo::rerun-if-changed=migrations\");\n}\n",
        );
        let cargo = RealCargo::new(&root, "probe/Cargo.toml", "probe").unwrap();

        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Compiled);
        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Reused);
        root.write("probe/migrations/1.surql", "DEFINE TABLE two;");
        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Compiled);
    }

    #[test]
    fn a_changed_value_of_a_variable_a_build_script_watches_builds_again() {
        let root = cargo_workspace();
        let cargo = FakeCargo { ctx: &root.ctx };
        let build = cargo.build(TREES);
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
        let build = cargo.build(TREES);
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
        let root = RealCargo::workspace();
        root.write(
            "probe/build.rs",
            "fn main() {\n    println!(\"cargo::rerun-if-env-changed=PROBE_WATCHED\");\n    \
             println!(\"cargo::rerun-if-changed=build.rs\");\n}\n",
        );
        let cargo = RealCargo::new(&root, "probe/Cargo.toml", "probe").unwrap();
        let run = |watched: &str| cargo.run(&NONE.with("PROBE_WATCHED", watched)).unwrap();

        assert_eq!(run("one"), Outcome::Compiled);
        assert_eq!(run("one"), Outcome::Reused);
        assert_eq!(run("two"), Outcome::Compiled, "after PROBE_WATCHED changed");
    }

    #[test]
    fn a_crate_that_embeds_a_file_of_another_crate_declares_it_in_its_manifest() {
        // The component suite races a component's own transaction, which it embeds from the
        // component's folder although it does not build the component.
        let root = RealCargo::workspace();
        root.write("component/src/query.surql", "SELECT 1;");
        root.write(
            "tests/suite/Cargo.toml",
            "[package]\nname = \"suite\"\nversion = \"0.1.0\"\nedition = \"2024\"\n\n\
             [package.metadata.typewriter]\ninputs = [\"../../component/src/query.surql\"]\n",
        );
        root.write(
            "tests/suite/src/lib.rs",
            "pub const QUERY: &str = include_str!(\"../../../component/src/query.surql\");\n",
        );
        let cargo = RealCargo::new(&root, "tests/suite/Cargo.toml", "suite").unwrap();

        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Compiled);
        assert_eq!(cargo.run(&NONE).unwrap(), Outcome::Reused);
        root.write("component/src/query.surql", "SELECT 2;");
        assert_eq!(
            cargo.run(&NONE).unwrap(),
            Outcome::Compiled,
            "after the embedded file changed"
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
