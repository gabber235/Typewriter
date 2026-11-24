//! Digests of input files, which decide whether a generator or a build can reuse what it wrote
//! last time: the same digest means the same inputs.

use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result};

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
