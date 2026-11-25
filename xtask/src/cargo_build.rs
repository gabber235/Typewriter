//! Cargo builds reused while the digest of their inputs is unchanged. Cargo itself judges local
//! crates by file times, so a fresh checkout recompiles every one of them even when a cached
//! target holds what they would produce; a stamp beside the artifacts records the digest they were
//! built from and the artifacts' own digests, and while both match, Cargo does not run at all.
//!
//! The inputs are folders and files the caller names. After each build the dependency files Cargo
//! writes beside the artifacts are checked against them, so a crate that starts reading a file
//! outside its inputs fails the build that introduced it instead of being reused after that file
//! changes.

use std::collections::BTreeSet;
use std::fs;
use std::path::{Component, Path, PathBuf};
use std::process::Command;

use anyhow::{Context as _, Result, bail};

use crate::digest::{Digest, Stamp, walk};
use crate::{CommandExt as _, Context};

/// One Cargo invocation and what it produces.
pub struct CargoBuild<'a> {
    /// Names the stamp, which lies beside the first artifact as `<name>.xtask-stamp`.
    pub name: &'a str,
    /// Root relative files and folders the artifacts are built from, generated sources included.
    /// Folders are walked, skipping build output and hidden directories.
    pub inputs: &'a [&'a str],
    /// Root relative folders below `inputs` the artifacts never read, left out of the digest.
    pub excluded: &'a [&'a str],
    /// The Cargo target directory the build writes into. Reads below it are a build script's
    /// generated sources, which derive from the inputs.
    pub target: PathBuf,
    /// The absolute paths of what the build produces.
    pub artifacts: Vec<PathBuf>,
}

/// The target directory of the Cargo workspace whose manifest is `manifest`, root relative.
pub fn target_directory(ctx: &Context, manifest: &str) -> Result<PathBuf> {
    let metadata: serde_json::Value = serde_json::from_str(
        &ctx.tool(
            ".",
            "cargo",
            &[
                "metadata",
                "--format-version",
                "1",
                "--no-deps",
                "--locked",
                "--manifest-path",
                manifest,
            ],
        )
        .output_text()?,
    )?;
    let target = metadata["target_directory"]
        .as_str()
        .context("cargo metadata printed no target_directory")?;
    Ok(PathBuf::from(target))
}

/// Whether [`CargoBuild::run`] ran Cargo.
#[derive(Debug, PartialEq, Eq)]
pub enum Outcome {
    /// The artifacts on disk were built from the same inputs; Cargo did not run.
    Reused,
    /// Cargo ran and the artifacts are stamped with the digest of their inputs.
    Compiled,
}

impl CargoBuild<'_> {
    /// Runs `cargo` unless the artifacts were built from the same inputs, the same toolchain and
    /// the same command, then stamps them.
    pub fn run(&self, ctx: &Context, cargo: &mut Command) -> Result<Outcome> {
        let (digest, hashed) = self.digest(ctx, cargo)?;
        let stamp = self.stamp()?;
        let artifacts = self.artifact_names();
        if stamp.outputs(&ctx.root, &digest).as_ref() == Some(&artifacts) {
            return Ok(Outcome::Reused);
        }
        // A build that fails, or reads outside its inputs, leaves nothing to reuse.
        stamp.clear()?;
        cargo.run()?;
        self.check_inputs(ctx, &hashed)?;
        stamp.record(&ctx.root, &digest, &artifacts)?;
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

    /// The digest of every input file, the command line with the variables it sets, the flags
    /// the environment passes to rustc, and the toolchain's version, with the root relative
    /// files it hashed.
    fn digest(&self, ctx: &Context, cargo: &Command) -> Result<(Digest, BTreeSet<PathBuf>)> {
        let mut files = BTreeSet::new();
        for input in self.inputs {
            walk(&ctx.root, &ctx.root.join(input), &mut |relative| {
                if !self.is_excluded(Path::new(relative)) {
                    files.insert(relative.to_owned());
                }
            })?;
        }
        let mut digest = Digest::new();
        for file in &files {
            digest.update_file(&ctx.root, file)?;
        }
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
        Ok((digest, files.into_iter().map(PathBuf::from).collect()))
    }

    fn is_excluded(&self, relative: &Path) -> bool {
        self.excluded
            .iter()
            .any(|excluded| relative.starts_with(excluded))
    }

    /// Fails when Cargo's dependency file of an artifact names a repository file the digest did
    /// not hash (`hashed`): one outside the inputs, excluded, or in a folder the walk skips such as
    /// a hidden folder or another tool's build output. Files below the build's own target
    /// directory (a build script's generated sources) derive from the inputs, and files outside
    /// the repository come from the toolchain or from dependencies `Cargo.lock` pins.
    fn check_inputs(&self, ctx: &Context, hashed: &BTreeSet<PathBuf>) -> Result<()> {
        let mut outside = Vec::new();
        for artifact in &self.artifacts {
            let dep_info = artifact.with_extension("d");
            let text = fs::read_to_string(&dep_info)
                .with_context(|| format!("cannot read {}", dep_info.display()))?;
            for file in dep_info_files(&text) {
                let file = normalize(&file);
                if file.starts_with(&self.target) {
                    continue;
                }
                let Ok(relative) = file.strip_prefix(&ctx.root).map(Path::to_owned) else {
                    continue;
                };
                if !hashed.contains(&relative) {
                    outside.push(relative.display().to_string());
                }
            }
        }
        outside.sort();
        outside.dedup();
        if !outside.is_empty() {
            bail!(
                "the build {} read {}, which its inputs ({}) leave out, so it would be reused after \
                 they change; add them to its inputs",
                self.name,
                outside.join(", "),
                self.inputs.join(", ")
            );
        }
        Ok(())
    }
}

/// The files a Makefile style dependency file names after each rule's colon. A space inside a
/// path is escaped with a backslash.
fn dep_info_files(text: &str) -> Vec<PathBuf> {
    let mut files = Vec::new();
    for line in text.lines() {
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
    use crate::test_support::{FakeCargo, TempRoot};

    /// The build every case runs: `backend` and `Cargo.lock` without `backend/tests`.
    const INPUTS: &[&str] = &["backend", "Cargo.lock"];
    const EXCLUDED: &[&str] = &["backend/tests"];
    const READS: &[&str] = &["backend/src/lib.rs"];

    #[test]
    fn a_build_whose_inputs_are_unchanged_is_reused_without_running_cargo() {
        let root = TempRoot::new();
        root.write("backend/src/lib.rs", "fn main() {}");
        root.write("Cargo.lock", "version = 4");
        let cargo = FakeCargo { root: &root };
        let build = cargo.build(INPUTS, EXCLUDED);

        let first = build.run(&root.ctx, &mut cargo.command("one", READS));
        let second = build.run(&root.ctx, &mut cargo.command("one", READS));

        assert_eq!(first.unwrap(), Outcome::Compiled);
        assert_eq!(second.unwrap(), Outcome::Reused);
        assert_eq!(cargo.runs(), 1);
        assert_eq!(fs::read_to_string(cargo.artifact()).unwrap(), "one");
    }

    #[test]
    fn an_edited_or_added_input_builds_again() {
        let root = TempRoot::new();
        root.write("backend/src/lib.rs", "fn main() {}");
        root.write("Cargo.lock", "version = 4");
        let cargo = FakeCargo { root: &root };
        let build = cargo.build(INPUTS, EXCLUDED);
        build
            .run(&root.ctx, &mut cargo.command("one", READS))
            .unwrap();

        for (file, contents) in [
            ("backend/src/lib.rs", "fn main() { edited() }"),
            ("Cargo.lock", "version = 4\n[[package]]"),
            ("backend/src/new.rs", ""),
        ] {
            root.write(file, contents);
            let outcome = build.run(&root.ctx, &mut cargo.command("one", READS));
            assert_eq!(outcome.unwrap(), Outcome::Compiled, "after writing {file}");
        }
        assert_eq!(cargo.runs(), 4);
    }

    #[test]
    fn a_different_command_builds_again() {
        let root = TempRoot::new();
        root.write("backend/src/lib.rs", "fn main() {}");
        let cargo = FakeCargo { root: &root };
        let build = cargo.build(INPUTS, EXCLUDED);
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
        let root = TempRoot::new();
        root.write("backend/src/lib.rs", "fn main() {}");
        let cargo = FakeCargo { root: &root };
        let build = cargo.build(INPUTS, EXCLUDED);
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
    fn a_change_to_an_excluded_folder_or_to_build_output_reuses_the_build() {
        let root = TempRoot::new();
        root.write("backend/src/lib.rs", "fn main() {}");
        root.write("backend/tests/case.rs", "#[test] fn case() {}");
        let cargo = FakeCargo { root: &root };
        let build = cargo.build(INPUTS, EXCLUDED);
        build
            .run(&root.ctx, &mut cargo.command("one", READS))
            .unwrap();

        root.write("backend/tests/case.rs", "#[test] fn edited() {}");
        root.write("backend/target/release/libdep.rlib", "rebuilt");
        let outcome = build.run(&root.ctx, &mut cargo.command("one", READS));
        assert_eq!(outcome.unwrap(), Outcome::Reused);
    }

    #[test]
    fn a_build_that_read_a_repository_file_outside_its_inputs_is_refused_and_not_reused() {
        let root = TempRoot::new();
        root.write("backend/src/lib.rs", "fn main() {}");
        root.write("backend/tests/case.rs", "#[test] fn case() {}");
        root.write("skir-src/fixture.json", "{}");
        let cargo = FakeCargo { root: &root };
        let build = cargo.build(INPUTS, EXCLUDED);
        root.write("services/sdk/build/fixtures/corpus.json", "[]");
        root.write("backend/access/auth-callout/.wash/config.yaml", "");
        let reads = [
            "backend/src/lib.rs",
            "skir-src/fixture.json",
            "backend/tests/case.rs",
            "services/sdk/build/fixtures/corpus.json",
            "backend/access/auth-callout/.wash/config.yaml",
        ];

        let error = build
            .run(&root.ctx, &mut cargo.command("one", &reads))
            .unwrap_err()
            .to_string();
        assert!(error.contains("skir-src/fixture.json"), "{error}");
        assert!(error.contains("backend/tests/case.rs"), "{error}");
        // Another tool's build output, which the digest never holds.
        assert!(
            error.contains("services/sdk/build/fixtures/corpus.json"),
            "{error}"
        );
        // Below an input folder, but in a hidden folder the digest skips.
        assert!(
            error.contains("backend/access/auth-callout/.wash/config.yaml"),
            "{error}"
        );
        assert!(!error.contains("backend/src/lib.rs"), "{error}");

        let again = build.run(&root.ctx, &mut cargo.command("one", &reads));
        assert!(again.unwrap_err().to_string().contains("skir-src"));
        assert_eq!(cargo.runs(), 2);
    }

    #[test]
    fn generated_sources_in_its_own_target_and_files_outside_the_repository_are_not_inputs() {
        let root = TempRoot::new();
        root.write("backend/src/lib.rs", "fn main() {}");
        let cargo = FakeCargo { root: &root };
        let build = cargo.build(INPUTS, EXCLUDED);
        let reads = [
            "backend/src/../src/lib.rs",
            "target/debug/build/schema/out/files.rs",
            "../rustlib/src/lib.rs",
        ];

        let outcome = build.run(&root.ctx, &mut cargo.command("one", &reads));
        assert_eq!(outcome.unwrap(), Outcome::Compiled);
    }

    #[test]
    fn dependency_files_name_every_file_after_each_colon_with_escaped_spaces() {
        assert_eq!(
            dep_info_files(
                "/t/stack: /a/lib.rs /my\\ docs/x.rs\n/t/other.d: /b/mod.rs\n\n/a/lib.rs:\n"
            ),
            [
                PathBuf::from("/a/lib.rs"),
                PathBuf::from("/my docs/x.rs"),
                PathBuf::from("/b/mod.rs"),
            ]
        );
    }
}
