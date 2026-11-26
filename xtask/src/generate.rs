//! Generated sources are build output: Git ignores them and this module writes them. Each
//! generator declares its inputs and where its output lands; it runs only when the digest of its
//! inputs changed or one of its recorded outputs is missing, so a second run is a fast no op.
//!
//! Generators run in dependency order and each digest includes the one before it: the panel
//! compiles against the Skir output, and the testkit and the widgetbook build on the panel.

use std::fs::File;

use anyhow::Result;

use crate::digest::{Digest, Environment, Stamp, expand, walk};
use crate::lock::HeavyLock;
use crate::{CommandExt, Context};

pub const DESCRIBE: &str = "cargo xtask generate: bun services/protocol/generate.ts, \
                            ./gradlew :typewriter-api:writeSdkFixtures, dart run build_runner \
                            build in panel and panel/testkit, flutter test \
                            tool/write_creation_fixtures.dart in panel/testkit, then build_runner \
                            in panel/widgetbook, then the write_frame_vectors example in \
                            backend/wasmcloud-utils, each only when its inputs changed or its \
                            output is missing";

/// One program that writes generated sources.
struct Generator {
    name: &'static str,
    /// Files and directories relative to the repository root; `*` matches one path component.
    /// Directories are walked, skipping generated files, build output and hidden directories.
    inputs: &'static [&'static str],
    /// Directories the generated files land in. The generated files found there after a run are
    /// recorded, so deleting any of them reruns the generator.
    outputs: &'static [&'static str],
    /// Files written outside the generated source convention (build output, committed fixtures),
    /// recorded like generated files.
    files: &'static [&'static str],
    tool: Tool,
}

enum Tool {
    /// Skir generation, its transport and operation generators and the subscription ConfigMaps.
    Protocol,
    /// `build_runner` in the Dart package at this path.
    BuildRunner(&'static str),
    /// The fixtures other hosts read from the Kotlin SDK: the canonical read schema, the compiled
    /// control fixtures the panel embeds, and the expression differential corpus.
    SdkFixtures,
    /// The panel's creation edit and the catalog and seed it applies to, which the Realm commits
    /// in `PanelCreationCommitTest`; written by a testkit tool that needs the Flutter engine.
    CreationFixtures,
    /// The frame vectors every transport's assembler reads, planned by the backend framer.
    FrameVectors,
}

impl Tool {
    /// The command printing the exact version of the toolchain that generates the output.
    fn version(&self) -> (&'static str, &'static [&'static str]) {
        match self {
            Tool::Protocol => ("bun", &["--revision"]),
            Tool::BuildRunner(_) => ("dart", &["--version"]),
            Tool::SdkFixtures => ("java", &["-version"]),
            Tool::CreationFixtures => ("dart", &["--version"]),
            Tool::FrameVectors => ("rustc", &["--version"]),
        }
    }
}

/// The generated expressions and the results Kotlin computed, which the panel evaluates too.
/// Where the creation fixtures land, as resources of the Realm's tests.
const CREATION_FIXTURES: &str = "services/runtime/realm/src/test/resources/creation";

/// Where the frame vectors land, beside the transport contracts every host implements.
const FRAME_VECTORS: &str = "skir-src/transport/v1/fixtures/frames.json";

/// The frame vector writer's own Cargo target. The backend's shared target grows to tens of GB,
/// while this one holds only the writer's dependencies, built without debug info: under a GB, so
/// CI can cache it (`frame-vectors` in .github/actions/devenv).
const FRAME_VECTORS_TARGET: &str = ".xtask/frame-vectors-target";

pub const SDK_EXPRESSION_CORPUS: &str =
    "services/sdk/typewriter-api/build/fixtures/expression_corpus.json";

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
        files: &[],
        tool: Tool::Protocol,
    },
    Generator {
        name: "sdk-fixtures",
        inputs: &[
            "services/sdk/typewriter-api",
            "services/testing/typewriter-test-kit",
            "services/libs.versions.toml",
            "panel/testkit/tool/update_compiled_sdk_control_fixture.py",
        ],
        outputs: &[],
        files: &[
            SDK_EXPRESSION_CORPUS,
            "skir-src/editor/v1/fixtures/canonical_read_models.json",
            "panel/testkit/lib/src/shared/editors/presentation/compiled_sdk_control_fixture.dart",
        ],
        tool: Tool::SdkFixtures,
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
    Generator {
        name: "creation-fixtures",
        inputs: &[
            "panel/lib",
            "panel/pubspec.yaml",
            "panel/pubspec.lock",
            "panel/testkit/lib",
            "panel/testkit/tool/write_creation_fixtures.dart",
            "panel/testkit/pubspec.yaml",
            "panel/testkit/pubspec.lock",
        ],
        outputs: &[],
        files: &[
            "services/runtime/realm/src/test/resources/creation/catalog.skir",
            "services/runtime/realm/src/test/resources/creation/seed.skir",
            "services/runtime/realm/src/test/resources/creation/edit.skir",
        ],
        tool: Tool::CreationFixtures,
    },
    build_runner(
        "panel/widgetbook",
        &[
            "panel/widgetbook/lib",
            "panel/widgetbook/pubspec.yaml",
            "panel/widgetbook/pubspec.lock",
        ],
    ),
    // Last, so a framing change reruns no other generator.
    Generator {
        name: "frame-vectors",
        inputs: &[
            "backend/Cargo.toml",
            "backend/Cargo.lock",
            "backend/wasmcloud-utils/Cargo.toml",
            "backend/wasmcloud-utils/src/transport",
            "backend/wasmcloud-utils/examples/write_frame_vectors.rs",
        ],
        outputs: &[],
        files: &[FRAME_VECTORS],
        tool: Tool::FrameVectors,
    },
];

const fn build_runner(package: &'static str, inputs: &'static [&'static str]) -> Generator {
    Generator {
        name: package,
        inputs,
        outputs: inputs,
        files: &[],
        tool: Tool::BuildRunner(package),
    }
}

/// Brings every generated source up to date. Program output goes to `log`, or to the terminal.
/// Takes the heavy lock before the first generator that has to run, so a run with nothing stale
/// never queues behind another build.
pub fn generate(ctx: &Context, log: Option<&File>) -> Result<()> {
    bring_up_to_date(ctx, log, GENERATORS, Lock::BeforeFirstRun)
}

/// Brings only the protocol's generated sources up to date: the Skir types the services and the
/// backend compile against, all the game suite and a stack's builds need. Takes the heavy lock as
/// [`generate`] does.
pub fn protocol(ctx: &Context) -> Result<()> {
    bring_up_to_date(ctx, None, through("protocol"), Lock::BeforeFirstRun)
}

/// The protocol's generated sources, root relative, which the backend's Cargo builds compile
/// against although Git ignores them.
pub fn protocol_files(ctx: &Context) -> Result<Vec<String>> {
    let protocol = through("protocol");
    protocol[protocol.len() - 1].output_files(ctx)
}

/// [`protocol`] for a caller that already holds the heavy lock.
pub fn protocol_holding_lock(ctx: &Context) -> Result<()> {
    bring_up_to_date(ctx, None, through("protocol"), Lock::Held)
}

/// The graph step: [`generate`] with its output in the step's log, run as a heavy step that
/// already holds the lock.
pub fn step(ctx: &Context, log: &File) -> Result<()> {
    bring_up_to_date(ctx, Some(log), GENERATORS, Lock::Held)
}

/// Whether every generator is current, so [`generate`] would run nothing.
pub fn is_up_to_date(ctx: &Context) -> Result<bool> {
    is_up_to_date_over(ctx, GENERATORS)
}

/// The generators up to and including the one named `last`, in order. Each builds on the ones
/// before it, so only a leading part of the list can run on its own.
fn through(last: &str) -> &'static [Generator] {
    let end = GENERATORS
        .iter()
        .position(|it| it.name == last)
        .unwrap_or_else(|| panic!("no generator is named {last}"));
    &GENERATORS[..=end]
}

/// Who holds the heavy lock while generators run.
enum Lock {
    /// The caller does: the graph's heavy step.
    Held,
    /// Taken before the first generator that has to run.
    BeforeFirstRun,
}

fn bring_up_to_date(
    ctx: &Context,
    log: Option<&File>,
    generators: &[Generator],
    lock: Lock,
) -> Result<()> {
    let mut upstream = Digest::new();
    let mut held = None;
    for generator in generators {
        let before = generator.digest(ctx, &upstream)?;
        if stamp(ctx, generator).is_current(&ctx.root, &before, &Environment::process()) {
            upstream = before;
            continue;
        }
        if matches!(lock, Lock::BeforeFirstRun) && held.is_none() {
            held = Some(HeavyLock::acquire("generate")?);
        }
        say(log, &format!("generate {}", generator.name))?;
        generator.run(ctx, log)?;
        // Digested again: the protocol generator rewrites stale Skir numbers in its inputs.
        let after = generator.digest(ctx, &upstream)?;
        record(ctx, generator, &after)?;
        upstream = after;
    }
    Ok(())
}

/// Whether each of `generators`, digested in order on the one before it, matches its stamp.
fn is_up_to_date_over(ctx: &Context, generators: &[Generator]) -> Result<bool> {
    let mut upstream = Digest::new();
    for generator in generators {
        let digest = generator.digest(ctx, &upstream)?;
        if !stamp(ctx, generator).is_current(&ctx.root, &digest, &Environment::process()) {
            return Ok(false);
        }
        upstream = digest;
    }
    Ok(true)
}

/// Writes `generator`'s stamp: the `digest` it ran on and the outputs it left.
fn record(ctx: &Context, generator: &Generator, digest: &Digest) -> Result<()> {
    stamp(ctx, generator).record(
        &ctx.root,
        digest,
        &generator.output_files(ctx)?,
        &Environment::process(),
    )
}

fn stamp(ctx: &Context, generator: &Generator) -> Stamp {
    Stamp::at(ctx.root.join(format!(
        ".xtask/generate/{}.stamp",
        generator.name.replace('/', "-")
    )))
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
                let mut build = ctx.tool(package, "dart", &["run", "build_runner", "build"]);
                build.log_output(log)?.run()
            }
            Tool::SdkFixtures => {
                let mut write = ctx.tool(
                    "services",
                    "./gradlew",
                    &[":typewriter-api:writeSdkFixtures"],
                );
                write.log_output(log)?.run()?;
                let mut embed = ctx.tool(
                    ".",
                    "python3",
                    &[
                        "panel/testkit/tool/update_compiled_sdk_control_fixture.py",
                        "services/sdk/typewriter-api/build/fixtures/controls",
                    ],
                );
                embed.log_output(log)?.run()
            }
            Tool::CreationFixtures => {
                let directory = ctx.root.join(CREATION_FIXTURES);
                let define = format!("--dart-define=CREATION_FIXTURE_DIR={}", directory.display());
                let mut write = ctx.tool(
                    "panel/testkit",
                    "flutter",
                    &["test", "tool/write_creation_fixtures.dart", &define],
                );
                write.log_output(log)?.run()
            }
            Tool::FrameVectors => {
                let output = ctx.root.join(FRAME_VECTORS);
                let output = output.to_string_lossy();
                let mut write = ctx.tool(
                    "backend",
                    "cargo",
                    &[
                        "run",
                        "--locked",
                        "--quiet",
                        "--package",
                        "wasmcloud-utils",
                        "--features",
                        "frame-vectors",
                        "--example",
                        "write_frame_vectors",
                        "--",
                        &output,
                    ],
                );
                write
                    .env("CARGO_TARGET_DIR", ctx.root.join(FRAME_VECTORS_TARGET))
                    .env("CARGO_PROFILE_DEV_DEBUG", "0");
                write.log_output(log)?.run()
            }
        }
    }

    /// The digest of `upstream`, the toolchain's version and every input file's path and contents.
    fn digest(&self, ctx: &Context, upstream: &Digest) -> Result<Digest> {
        let mut files = Vec::new();
        for input in self.inputs {
            for path in expand(&ctx.root, input)? {
                walk(&ctx.root, &path, &mut |relative| {
                    if !is_generated(relative) && !is_generator_file(relative) {
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
            digest.update_file(&ctx.root, &file)?;
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
        files.extend(
            self.files
                .iter()
                .filter(|file| ctx.root.join(file).is_file())
                .map(|file| (*file).to_owned()),
        );
        files.sort();
        files.dedup();
        Ok(files)
    }
}

/// Generator output by convention: Skir writes into `skirout` directories, build_runner writes
/// `.g.dart`, `.freezed.dart` and `.gr.dart` parts.
fn is_generated(relative: &str) -> bool {
    relative.split('/').any(|component| component == "skirout")
        || [".g.dart", ".freezed.dart", ".gr.dart"]
            .iter()
            .any(|suffix| relative.ends_with(suffix))
}

/// Whether a generator writes `relative` as one of its `files`. Such a file is output, never an
/// input: digesting it would rerun an earlier generator whose inputs contain it, such as the
/// protocol generator reading `skir-src`, after every later generator writes there.
fn is_generator_file(relative: &str) -> bool {
    GENERATORS
        .iter()
        .any(|generator| generator.files.contains(&relative))
}

fn say(log: Option<&File>, line: &str) -> Result<()> {
    use std::io::Write as _;
    match log {
        Some(mut log) => writeln!(log, "$ {line}")?,
        None => eprintln!("{line}"),
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use std::fs;

    use super::*;

    use crate::test_support::TempRoot;

    #[test]
    fn the_protocol_alone_runs_without_the_panel_and_fixture_generators_after_it() {
        let names =
            |generators: &[Generator]| generators.iter().map(|it| it.name).collect::<Vec<_>>();

        assert_eq!(names(through("protocol")), ["protocol"]);
        assert_eq!(names(through("frame-vectors")), names(GENERATORS));
    }

    #[test]
    fn generate_is_up_to_date_only_while_every_generator_in_the_chain_is_current() {
        const CHAIN: &[Generator] = &[
            Generator {
                name: "first",
                inputs: &["first"],
                outputs: &[],
                files: &[],
                tool: Tool::FrameVectors,
            },
            Generator {
                name: "second",
                inputs: &["second"],
                outputs: &[],
                files: &[],
                tool: Tool::FrameVectors,
            },
        ];
        let root = TempRoot::new();
        root.write("first/input.txt", "one");
        root.write("second/input.txt", "two");
        assert!(!is_up_to_date_over(&root.ctx, CHAIN).unwrap());

        let first = CHAIN[0].digest(&root.ctx, &Digest::new()).unwrap();
        record(&root.ctx, &CHAIN[0], &first).unwrap();
        let second = CHAIN[1].digest(&root.ctx, &first).unwrap();
        record(&root.ctx, &CHAIN[1], &second).unwrap();
        assert!(is_up_to_date_over(&root.ctx, CHAIN).unwrap());

        root.write("second/input.txt", "edited");
        assert!(!is_up_to_date_over(&root.ctx, CHAIN).unwrap());
    }

    #[test]
    fn generated_outputs_and_hand_written_inputs_are_told_apart() {
        let dir = tempfile::tempdir().unwrap();
        let ctx = Context {
            root: dir.path().to_owned(),
        };
        for file in [
            "panel/lib/model.dart",
            "panel/lib/model.g.dart",
            "panel/lib/skirout/types.dart",
            "panel/build/cache.g.dart",
        ] {
            let path = dir.path().join(file);
            fs::create_dir_all(path.parent().unwrap()).unwrap();
            fs::write(path, "").unwrap();
        }
        let generator = build_runner("panel", &["panel/lib"]);
        assert_eq!(
            generator.output_files(&ctx).unwrap(),
            ["panel/lib/model.g.dart", "panel/lib/skirout/types.dart"]
        );
    }
}
