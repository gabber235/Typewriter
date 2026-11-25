//! Digests of input files, which decide whether a generator or a build can reuse what it wrote
//! last time: the same digest means the same inputs.

use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result};
use sha2::{Digest as _, Sha256};

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

/// The existing paths `pattern` names, where a `*` component matches any one entry.
pub fn expand(root: &Path, pattern: &str) -> Result<Vec<PathBuf>> {
    let mut paths = vec![root.to_path_buf()];
    for component in pattern.split('/') {
        let mut next = Vec::new();
        for path in paths {
            if component == "*" {
                let Ok(entries) = fs::read_dir(&path) else {
                    continue;
                };
                for entry in entries {
                    let entry = entry?;
                    if entry.file_type()?.is_dir() && !skipped(&entry.file_name().to_string_lossy())
                    {
                        next.push(entry.path());
                    }
                }
            } else {
                let candidate = path.join(component);
                if candidate.exists() {
                    next.push(candidate);
                }
            }
        }
        paths = next;
    }
    paths.sort();
    Ok(paths)
}

/// Calls `visit` with the root relative path of every file at or below `path`.
pub fn walk(root: &Path, path: &Path, visit: &mut dyn FnMut(&str)) -> Result<()> {
    let Ok(metadata) = fs::metadata(path) else {
        return Ok(());
    };
    if metadata.is_file() {
        let relative = path.strip_prefix(root).unwrap_or(path);
        visit(&relative.to_string_lossy());
        return Ok(());
    }
    let mut entries = fs::read_dir(path)
        .with_context(|| format!("cannot read {}", path.display()))?
        .collect::<Result<Vec<_>, _>>()?;
    entries.sort_by_key(|entry| entry.file_name());
    for entry in entries {
        if !skipped(&entry.file_name().to_string_lossy()) {
            walk(root, &entry.path(), visit)?;
        }
    }
    Ok(())
}

/// Build output, dependencies and tool state, never input.
pub fn skipped(name: &str) -> bool {
    name.starts_with('.') || matches!(name, "node_modules" | "build" | "target")
}

/// What a generator or a build left last time: the digest of the inputs it ran on and the sha256
/// of each output it wrote. Output paths are relative to the root, or absolute.
pub struct Stamp {
    pub path: PathBuf,
}

impl Stamp {
    pub fn at(path: PathBuf) -> Self {
        Self { path }
    }

    /// Whether the stamp records `digest` and every output it lists still has the recorded
    /// contents, so an output that was deleted or edited by hand is stale.
    pub fn is_current(&self, root: &Path, digest: &Digest) -> bool {
        self.outputs(root, digest).is_some()
    }

    /// The outputs the stamp lists when it is current for `digest`.
    pub fn outputs(&self, root: &Path, digest: &Digest) -> Option<Vec<String>> {
        let record = fs::read_to_string(&self.path).ok()?;
        let mut lines = record.lines();
        if lines.next()? != digest.hex() {
            return None;
        }
        lines
            .map(|line| {
                let (sum, output) = line.split_once(' ')?;
                (sha256(&root.join(output)).ok()? == sum).then(|| output.to_owned())
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

    /// Records `digest` and the current contents of each of `outputs`.
    pub fn record(&self, root: &Path, digest: &Digest, outputs: &[String]) -> Result<()> {
        let dir = self.path.parent().unwrap_or(root);
        fs::create_dir_all(dir).with_context(|| format!("cannot create {}", dir.display()))?;
        let mut record = format!("{}\n", digest.hex());
        for output in outputs {
            record.push_str(&format!("{} {output}\n", sha256(&root.join(output))?));
        }
        fs::write(&self.path, record)
            .with_context(|| format!("cannot write {}", self.path.display()))
    }
}

pub fn sha256(path: &Path) -> Result<String> {
    let bytes = fs::read(path).with_context(|| format!("cannot read {}", path.display()))?;
    Ok(Sha256::digest(bytes)
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect())
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
        assert!(stamp.is_current(&root.ctx.root, &Digest::new()));
    }

    #[test]
    fn changed_inputs_are_stale() {
        let root = TempRoot::new();
        root.write(OUTPUT, "generated");
        let stamp = root.stamp("panel.stamp", &Digest::new(), &[OUTPUT]);
        let mut edited = Digest::new();
        edited.update(b"edited inputs");
        assert!(!stamp.is_current(&root.ctx.root, &edited));
    }

    #[test]
    fn a_deleted_output_is_stale() {
        let root = TempRoot::new();
        root.write(OUTPUT, "generated");
        let stamp = root.stamp("panel.stamp", &Digest::new(), &[OUTPUT]);
        fs::remove_file(root.path(OUTPUT)).unwrap();
        assert!(!stamp.is_current(&root.ctx.root, &Digest::new()));
    }

    #[test]
    fn an_output_edited_by_hand_is_stale() {
        let root = TempRoot::new();
        root.write(OUTPUT, "generated");
        let stamp = root.stamp("panel.stamp", &Digest::new(), &[OUTPUT]);
        root.write(OUTPUT, "edited by hand");
        assert!(!stamp.is_current(&root.ctx.root, &Digest::new()));
    }

    #[test]
    fn a_step_that_never_ran_is_stale() {
        let root = TempRoot::new();
        root.write(OUTPUT, "generated");
        root.stamp("panel.stamp", &Digest::new(), &[OUTPUT]);
        assert!(!Stamp::at(root.path("protocol.stamp")).is_current(&root.ctx.root, &Digest::new()));
    }
}
