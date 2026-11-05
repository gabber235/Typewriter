//! Generated sources are build output: Git ignores them and this module writes them. Each
//! generator declares its inputs and where its output lands; it runs only when the digest of its
//! inputs changed or one of its recorded outputs is missing, so a second run is a fast no op.
//!
//! Generators run in dependency order and each digest includes the one before it: the panel
//! compiles against the Skir output, and the testkit and the widgetbook build on the panel.

use std::fs::{self, File};
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result};

use crate::lock::HeavyLock;
use crate::{CommandExt, Context};

pub const DESCRIBE: &str = "cargo xtask generate: bun services/protocol/generate.ts, then \
                            dart run build_runner build in panel, panel/testkit and panel/widgetbook, \
                            each only when its inputs changed or its output is missing";

/// One program that writes generated sources.
struct Generator {
    name: &'static str,
    /// Files and directories relative to the repository root; `*` matches one path component.
    /// Directories are walked, skipping generated files, build output and hidden directories.
    inputs: &'static [&'static str],
    /// Directories the generated files land in. The generated files found there after a run are
    /// recorded, so deleting any of them reruns the generator.
    outputs: &'static [&'static str],
    tool: Tool,
}

enum Tool {
    /// Skir generation, its transport and operation generators and the subscription ConfigMaps.
    Protocol,
    /// `build_runner` in the Dart package at this path.
    BuildRunner(&'static str),
}

impl Tool {
    /// The command printing the exact version of the toolchain that generates the output.
    fn version(&self) -> (&'static str, &'static [&'static str]) {
        match self {
            Tool::Protocol => ("bun", &["--revision"]),
            Tool::BuildRunner(_) => ("dart", &["--version"]),
        }
    }
}

const GENERATORS: &[Generator] = &[
    Generator {
        name: "protocol",
        inputs: &[
            "skir-src",
            "skir.yml",
            "package.json",
            "bun.lock",
            "services/protocol/generate.ts",
            "services/protocol/transport-routes.yaml",
            "services/protocol/unicode",
            "services/protocol/skir-gen",
            // The subscription ConfigMaps are checked against each component's deployment.
            "backend/*/*/deploy/base",
        ],
        outputs: &[
            "backend/wasmcloud-utils/src/skirout",
            "backend/wasmcloud-utils/src/transport_routes/skirout",
            "panel/lib/infrastructure/protocols/skir/skirout",
            "panel/lib/infrastructure/messaging/generated/skirout",
            "panel/lib/infrastructure/protocols/operations/skirout",
            "services/protocol/src/main/kotlin/skirout",
            "services/protocol/transport-adapters/kotlin/skirout",
            "services/sdk/typewriter-api/src/main/skirout",
        ],
        tool: Tool::Protocol,
    },
    build_runner(
        "panel",
        &[
            "panel/lib",
            "panel/build.yaml",
            "panel/pubspec.yaml",
            "panel/pubspec.lock",
        ],
    ),
    build_runner(
        "panel/testkit",
        &[
            "panel/testkit/lib",
            "panel/testkit/pubspec.yaml",
            "panel/testkit/pubspec.lock",
        ],
    ),
    build_runner(
        "panel/widgetbook",
        &[
            "panel/widgetbook/lib",
            "panel/widgetbook/pubspec.yaml",
            "panel/widgetbook/pubspec.lock",
        ],
    ),
];

const fn build_runner(package: &'static str, inputs: &'static [&'static str]) -> Generator {
    Generator {
        name: package,
        inputs,
        outputs: inputs,
        tool: Tool::BuildRunner(package),
    }
}

/// Brings every generated source up to date. Program output goes to `log`, or to the terminal.
pub fn generate(ctx: &Context, log: Option<&File>) -> Result<()> {
    let state = ctx.root.join(".xtask/generate");
    fs::create_dir_all(&state).with_context(|| format!("cannot create {}", state.display()))?;
    let mut upstream = Digest::new();
    for generator in GENERATORS {
        let stamp = state.join(format!("{}.stamp", generator.name.replace('/', "-")));
        let before = generator.digest(ctx, &upstream)?;
        if is_current(ctx, &stamp, &before) {
            upstream = before;
            continue;
        }
        say(log, &format!("generate {}", generator.name))?;
        generator.run(ctx, log)?;
        // Digested again: the protocol generator rewrites stale Skir numbers in its inputs.
        let after = generator.digest(ctx, &upstream)?;
        let outputs = generator.output_files(ctx)?;
        let mut record = format!("{}\n", after.hex());
        for output in &outputs {
            record.push_str(output);
            record.push('\n');
        }
        fs::write(&stamp, record).with_context(|| format!("cannot write {}", stamp.display()))?;
        upstream = after;
    }
    Ok(())
}

/// The graph step: [`generate`] with its output in the step's log.
pub fn step(ctx: &Context, log: &File) -> Result<()> {
    generate(ctx, Some(log))
}

impl Generator {
    fn run(&self, ctx: &Context, log: Option<&File>) -> Result<()> {
        match self.tool {
            Tool::Protocol => {
                // Scripts stay off: no dependency needs an install script.
                let mut install = ctx.tool(
                    ".",
                    "bun",
                    &["install", "--frozen-lockfile", "--ignore-scripts"],
                );
                install.log_output(log)?.run()?;
                let mut generate = ctx.tool(".", "bun", &["services/protocol/generate.ts"]);
                generate.log_output(log)?.run()
            }
            Tool::BuildRunner(package) => {
                let _lock = HeavyLock::acquire(&format!("generate {package}"))?;
                let mut build = ctx.tool(package, "dart", &["run", "build_runner", "build"]);
                build.log_output(log)?.run()
            }
        }
    }

    /// The digest of `upstream`, the toolchain's version and every input file's path and contents.
    fn digest(&self, ctx: &Context, upstream: &Digest) -> Result<Digest> {
        let mut files = Vec::new();
        for input in self.inputs {
            for path in expand(&ctx.root, input)? {
                walk(&ctx.root, &path, &mut |relative| {
                    if !is_generated(relative) {
                        files.push(relative.to_owned());
                    }
                })?;
            }
        }
        files.sort();
        files.dedup();
        let mut digest = upstream.clone();
        // Output differs between toolchain versions, and switching one in place keeps its path.
        let (program, args) = self.tool.version();
        digest.update(ctx.tool(".", program, args).output_text()?.as_bytes());
        for file in files {
            let path = ctx.root.join(&file);
            let contents =
                fs::read(&path).with_context(|| format!("cannot read {}", path.display()))?;
            digest.update(file.as_bytes());
            digest.update(&[0]);
            digest.update(&(contents.len() as u64).to_le_bytes());
            digest.update(&contents);
        }
        Ok(digest)
    }

    /// The generated files below the output directories, relative to the repository root.
    fn output_files(&self, ctx: &Context) -> Result<Vec<String>> {
        let mut files = Vec::new();
        for output in self.outputs {
            walk(&ctx.root, &ctx.root.join(output), &mut |relative| {
                if is_generated(relative) {
                    files.push(relative.to_owned());
                }
            })?;
        }
        files.sort();
        files.dedup();
        Ok(files)
    }
}

/// Whether `stamp` records `digest` and every output it lists still exists.
fn is_current(ctx: &Context, stamp: &Path, digest: &Digest) -> bool {
    let Ok(record) = fs::read_to_string(stamp) else {
        return false;
    };
    let mut lines = record.lines();
    lines.next() == Some(digest.hex().as_str())
        && lines.all(|output| ctx.root.join(output).is_file())
}

/// Generator output by convention: Skir writes into `skirout` directories, build_runner writes
/// `.g.dart`, `.freezed.dart` and `.gr.dart` parts.
fn is_generated(relative: &str) -> bool {
    relative.split('/').any(|component| component == "skirout")
        || [".g.dart", ".freezed.dart", ".gr.dart"]
            .iter()
            .any(|suffix| relative.ends_with(suffix))
}

/// The existing paths `pattern` names, where a `*` component matches any one entry.
fn expand(root: &Path, pattern: &str) -> Result<Vec<PathBuf>> {
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
fn walk(root: &Path, path: &Path, visit: &mut dyn FnMut(&str)) -> Result<()> {
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

/// Build output, dependencies and tool state, never generator input.
fn skipped(name: &str) -> bool {
    name.starts_with('.') || matches!(name, "node_modules" | "build" | "target")
}

fn say(log: Option<&File>, line: &str) -> Result<()> {
    use std::io::Write as _;
    match log {
        Some(mut log) => writeln!(log, "$ {line}")?,
        None => eprintln!("{line}"),
    }
    Ok(())
}

/// FNV-1a over 64 bits: stable across Rust releases and machines, and enough to notice an edit.
#[derive(Clone)]
struct Digest(u64);

impl Digest {
    fn new() -> Self {
        Self(0xcbf2_9ce4_8422_2325)
    }

    fn update(&mut self, bytes: &[u8]) {
        for byte in bytes {
            self.0 ^= u64::from(*byte);
            self.0 = self.0.wrapping_mul(0x0000_0100_0000_01b3);
        }
    }

    fn hex(&self) -> String {
        format!("{:016x}", self.0)
    }
}
