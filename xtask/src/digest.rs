//! Digests of input files, which decide whether a generator or a build can reuse what it wrote
//! last time: the same digest means the same inputs.

use std::collections::BTreeMap;
use std::ffi::{OsStr, OsString};
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result};
use sha2::{Digest as _, Sha256};

use crate::{CommandExt as _, Context};

/// FNV-1a over 64 bits: stable across Rust releases and machines, and enough to notice an edit.
#[derive(Clone)]
pub struct Digest(u64);

impl Digest {
    pub fn new() -> Self {
        Self(0xcbf2_9ce4_8422_2325)
    }

    pub fn update(&mut self, bytes: &[u8]) {
        for byte in bytes {
            self.0 ^= u64::from(*byte);
            self.0 = self.0.wrapping_mul(0x0000_0100_0000_01b3);
        }
    }

    /// Adds the root relative path `file` and its contents, so a rename changes the digest too.
    pub fn update_file(&mut self, root: &Path, file: &str) -> Result<()> {
        let path = root.join(file);
        let contents =
            fs::read(&path).with_context(|| format!("cannot read {}", path.display()))?;
        self.update(file.as_bytes());
        self.update(&[0]);
        self.update(&(contents.len() as u64).to_le_bytes());
        self.update(&contents);
        Ok(())
    }

    pub fn hex(&self) -> String {
        format!("{:016x}", self.0)
    }
}

/// Which of the files below some paths [`listed`] names.
#[derive(Clone, Copy)]
pub enum Listing {
    /// Every file Git does not ignore, tracked or untracked: what generators and builds read,
    /// a new module counted before it is added.
    Inputs,
    /// Every untracked file Git ignores: generated sources and build output.
    Ignored,
}

/// The root relative files Git lists, by `listing`, at or below each of `paths`, sorted. A path is
/// root relative and names a file or a folder (`.` the whole repository); a `*` in it matches
/// within one path component. One listing serves generators and Cargo builds alike, so both count
/// the same files as inputs.
pub fn listed(ctx: &Context, paths: &[&str], listing: Listing) -> Result<Vec<String>> {
    if paths.is_empty() {
        return Ok(Vec::new());
    }
    let mut args = vec!["-c", "core.quotePath=false", "ls-files", "-z", "--others"];
    args.extend(match listing {
        Listing::Inputs => ["--cached", "--exclude-standard"].as_slice(),
        Listing::Ignored => ["--ignored", "--exclude-standard"].as_slice(),
    });
    args.push("--");
    // A glob path names no folder's contents on its own; the `/**` form does.
    let pathspecs: Vec<String> = paths
        .iter()
        .flat_map(|path| [format!(":(glob){path}"), format!(":(glob){path}/**")])
        .collect();
    let listing = ctx.tool(".", "git", &args).args(&pathspecs).output_text()?;
    let mut files: Vec<String> = listing
        .split('\0')
        .filter(|file| !file.is_empty())
        .map(str::to_owned)
        .collect();
    files.sort();
    files.dedup();
    Ok(files)
}

/// The environment variables a step runs with, which its caller passes in: the process's own in
/// production, chosen values in a test.
#[derive(Clone)]
pub struct Environment(BTreeMap<String, OsString>);

impl Environment {
    /// No variables at all.
    #[cfg(test)]
    pub const EMPTY: Self = Self(BTreeMap::new());

    /// This process's variables; one whose name is not Unicode is left out, as no step names it.
    pub fn process() -> Self {
        Self(
            std::env::vars_os()
                .filter_map(|(name, value)| Some((name.into_string().ok()?, value)))
                .collect(),
        )
    }

    /// This environment with `name` set to `value`.
    #[cfg(test)]
    pub fn with(mut self, name: &str, value: &str) -> Self {
        self.0.insert(name.to_owned(), value.into());
        self
    }

    pub fn get(&self, name: &str) -> Option<&OsStr> {
        self.0.get(name).map(OsString::as_os_str)
    }

    /// Every variable, by name.
    pub fn iter(&self) -> impl Iterator<Item = (&str, &OsStr)> {
        self.0
            .iter()
            .map(|(name, value)| (name.as_str(), value.as_os_str()))
    }
}

/// One thing a stamp vouches for.
#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum Entry {
    /// A file, relative to the root or absolute: its contents, or that it is absent.
    File(String),
    /// An environment variable: its value, or that it is unset.
    Variable(String),
}

/// An entry with the sha256 of what it named when it was hashed, which a stamp records.
pub struct Sum {
    entry: Entry,
    sum: String,
}

impl Entry {
    /// The entry with the sha256 of what it names now in `env`. A build hashes its inputs before
    /// it starts, so an edit while it runs differs from what its stamp records.
    pub fn sum(self, root: &Path, env: &Environment) -> Result<Sum> {
        let sum = self.fingerprint(root, env)?;
        Ok(Sum { entry: self, sum })
    }

    /// The sha256 of what the entry names in `env`: a file's contents (`absent` for a missing
    /// file), or a variable's value, told apart from an unset one.
    fn fingerprint(&self, root: &Path, env: &Environment) -> Result<String> {
        match self {
            Self::Variable(name) => {
                let value = match env.get(name) {
                    Some(value) => [b"set ", value.as_encoded_bytes()].concat(),
                    None => b"unset".to_vec(),
                };
                Ok(hex(&Sha256::digest(value)))
            }
            // A file that is not there yet, such as a configuration file nobody wrote, is recorded
            // as absent, so writing it later makes the stamp stale.
            Self::File(file) => match fs::metadata(root.join(file)) {
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
                    Ok("absent".to_owned())
                }
                _ => sha256(&root.join(file)),
            },
        }
    }

    /// The entry as a stamp line holds it after its sum: its kind, a space, its name.
    fn line(&self) -> String {
        match self {
            Self::File(file) => format!("file {file}"),
            Self::Variable(name) => format!("variable {name}"),
        }
    }

    fn parse(line: &str) -> Option<Self> {
        match line.split_once(' ')? {
            ("file", file) => Some(Self::File(file.to_owned())),
            ("variable", name) => Some(Self::Variable(name.to_owned())),
            _ => None,
        }
    }
}

/// What a generator or a build left last time: the digest of what it ran on and the sha256 of each
/// entry it vouches for (a generator's outputs; a build's artifacts and the files and environment
/// variables it read).
pub struct Stamp {
    pub path: PathBuf,
}

impl Stamp {
    pub fn at(path: PathBuf) -> Self {
        Self { path }
    }

    /// Whether the stamp records `digest` and every entry it lists still has the recorded
    /// contents in `env`, so an output that was deleted or edited by hand is stale.
    pub fn is_current(&self, root: &Path, digest: &Digest, env: &Environment) -> bool {
        self.entries(root, digest, env).is_some()
    }

    /// The entries the stamp lists when it is current for `digest` in `env`.
    pub fn entries(&self, root: &Path, digest: &Digest, env: &Environment) -> Option<Vec<Entry>> {
        let record = fs::read_to_string(&self.path).ok()?;
        let mut lines = record.lines();
        if lines.next()? != digest.hex() {
            return None;
        }
        lines
            .map(|line| {
                let (sum, entry) = line.split_once(' ')?;
                let entry = Entry::parse(entry)?;
                (entry.fingerprint(root, env).ok()? == sum).then_some(entry)
            })
            .collect()
    }

    /// Removes the stamp, so a run that fails leaves nothing to reuse.
    pub fn clear(&self) -> Result<()> {
        match fs::remove_file(&self.path) {
            Err(error) if error.kind() != std::io::ErrorKind::NotFound => {
                Err(error).with_context(|| format!("cannot remove {}", self.path.display()))
            }
            _ => Ok(()),
        }
    }

    /// Records `digest` and the sums `sums`, each taken when its entry held what the stamp vouches
    /// for: an input before the run, an output after it.
    pub fn record(&self, digest: &Digest, sums: &[Sum]) -> Result<()> {
        if let Some(dir) = self.path.parent() {
            fs::create_dir_all(dir).with_context(|| format!("cannot create {}", dir.display()))?;
        }
        let mut record = format!("{}\n", digest.hex());
        for Sum { entry, sum } in sums {
            record.push_str(&format!("{sum} {}\n", entry.line()));
        }
        fs::write(&self.path, record)
            .with_context(|| format!("cannot write {}", self.path.display()))
    }
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|byte| format!("{byte:02x}")).collect()
}

pub fn sha256(path: &Path) -> Result<String> {
    let bytes = fs::read(path).with_context(|| format!("cannot read {}", path.display()))?;
    Ok(hex(&Sha256::digest(bytes)))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::TempRoot;

    const OUTPUT: &str = "panel/lib/model.g.dart";

    #[test]
    fn unchanged_inputs_with_every_output_unchanged_are_current() {
        let root = TempRoot::new();
        root.write(OUTPUT, "generated");
        let stamp = root.stamp("panel.stamp", &Digest::new(), &[OUTPUT]);
        assert!(stamp.is_current(&root.ctx.root, &Digest::new(), &Environment::EMPTY));
    }

    #[test]
    fn changed_inputs_are_stale() {
        let root = TempRoot::new();
        root.write(OUTPUT, "generated");
        let stamp = root.stamp("panel.stamp", &Digest::new(), &[OUTPUT]);
        let mut edited = Digest::new();
        edited.update(b"edited inputs");
        assert!(!stamp.is_current(&root.ctx.root, &edited, &Environment::EMPTY));
    }

    #[test]
    fn a_deleted_output_is_stale() {
        let root = TempRoot::new();
        root.write(OUTPUT, "generated");
        let stamp = root.stamp("panel.stamp", &Digest::new(), &[OUTPUT]);
        fs::remove_file(root.path(OUTPUT)).unwrap();
        assert!(!stamp.is_current(&root.ctx.root, &Digest::new(), &Environment::EMPTY));
    }

    #[test]
    fn an_output_edited_by_hand_is_stale() {
        let root = TempRoot::new();
        root.write(OUTPUT, "generated");
        let stamp = root.stamp("panel.stamp", &Digest::new(), &[OUTPUT]);
        root.write(OUTPUT, "edited by hand");
        assert!(!stamp.is_current(&root.ctx.root, &Digest::new(), &Environment::EMPTY));
    }

    #[test]
    fn a_file_whose_name_starts_with_a_dollar_is_stamped_as_a_file() {
        let root = TempRoot::new();
        root.write("$HOME", "generated");
        let stamp = root.stamp("panel.stamp", &Digest::new(), &["$HOME"]);
        root.write("$HOME", "edited by hand");
        assert!(!stamp.is_current(&root.ctx.root, &Digest::new(), &Environment::EMPTY));
    }

    #[test]
    fn a_step_that_never_ran_is_stale() {
        let root = TempRoot::new();
        root.write(OUTPUT, "generated");
        root.stamp("panel.stamp", &Digest::new(), &[OUTPUT]);
        assert!(!Stamp::at(root.path("protocol.stamp")).is_current(
            &root.ctx.root,
            &Digest::new(),
            &Environment::EMPTY
        ));
    }
}
