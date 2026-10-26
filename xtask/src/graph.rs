//! The pull request gate as data. Each step is one program invocation (or one native function),
//! so `--print` can show the plain command and anyone can run it by hand.
//!
//! [`GENERATE`] runs first whenever a selected step needs generated sources; the other steps then
//! run in parallel and heavy steps queue on the machine wide [`HeavyLock`]. Every step runs as a
//! process in its own group, native steps as `xtask step <name>`, so an interrupt or a budget
//! overrun stops everything the step started. Every step writes its output to
//! `.xtask/logs/<step>.log` and its `TestRun` to `.xtask/results/steps/<step>.json`, and has a time
//! budget that fails it when exceeded and becomes the CI job timeout (`--list`). On failure the
//! terminal shows only the step, why it failed and the last lines of its log.

use std::fs::{self, File};
use std::io::Write;
use std::os::fd::AsFd as _;
use std::path::Path;
use std::process::{Command, Stdio};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result, anyhow, bail};
use clap::ValueEnum;

use crate::lock::HeavyLock;
use crate::process::{self, Group};
use crate::results::{self, Failure, Outcome, TestCase, TestRun};
use crate::skirout::base::harness::v1::test_run::Runner;
use crate::{CommandExt as _, Context, components, display, docs, generate, gitops, review};

/// How many trailing log lines a failure prints.
const FAILURE_TAIL: usize = 20;

/// A part of the gate that CI runs as one job.
#[derive(Clone, Copy, PartialEq, Eq, ValueEnum)]
pub enum Area {
    /// Kotlin services, including the imprint build, tests and ktlint.
    Services,
    /// Backend clippy, unit tests and the component test support crates.
    Backend,
    /// The embedded component test suite, every fixture.
    Components,
    /// Skir formatting and the protocol generator's typecheck and tests.
    Protocol,
    /// Flutter analysis and tests of the panel, its testkit and its widgetbook.
    Panel,
    /// Renders and validates every cluster in backend/_clusters.
    Gitops,
    /// Biome, `astro check` and the build of the documentation site.
    Docs,
    /// Project rules and new clones on the lines a change added (`cargo xtask review gate`).
    Quality,
    /// The harness itself: clippy and rustfmt.
    Xtask,
}

impl Area {
    fn name(self) -> &'static str {
        match self {
            Self::Services => "services",
            Self::Backend => "backend",
            Self::Components => "components",
            Self::Protocol => "protocol",
            Self::Panel => "panel",
            Self::Gitops => "gitops",
            Self::Docs => "docs",
            Self::Quality => "quality",
            Self::Xtask => "xtask",
        }
    }

    /// The path prefixes whose changes this area checks, beyond [`EVERY_AREA`].
    fn paths(self) -> &'static [&'static str] {
        match self {
            Self::Services => &["services/"],
            Self::Backend | Self::Components | Self::Gitops => &["backend/"],
            Self::Panel => &["panel/"],
            Self::Docs => &[DOCS_SITE],
            // The project rules scan every source the other areas check.
            Self::Quality => &["services/", "backend/", "panel/", "rules/", "sgconfig.yml"],
            // Their inputs are all in EVERY_AREA.
            Self::Protocol | Self::Xtask => &[],
        }
    }
}

/// The documentation site, whose Markdown is its source rather than documentation of the code.
const DOCS_SITE: &str = "documentation/";

/// Path prefixes whose changes affect every area: the harness, the toolchain, CI, and the
/// protocol and generator whose output every area compiles.
const EVERY_AREA: &[&str] = &[
    "xtask/",
    ".cargo/",
    ".github/",
    "devenv.",
    "nix/",
    "skir-src/",
    "skir.yml",
    "package.json",
    "bun.lock",
    "services/protocol/",
];

/// One program invocation in the graph.
pub struct Step {
    pub name: &'static str,
    pub area: Area,
    pub run: Run,
    pub heavy: bool,
    pub budget: Duration,
    /// Reads generated sources, so [`GENERATE`] runs before it.
    pub needs_generate: bool,
}

pub enum Run {
    /// `program args` in `cwd`, relative to the repository root.
    Program {
        cwd: &'static str,
        program: &'static str,
        args: &'static [&'static str],
    },
    /// Harness code; `describe` is what `--print` shows. Output goes to the step's log.
    Native {
        describe: &'static str,
        run: fn(&Context, &File) -> Result<()>,
    },
}

const fn program(
    name: &'static str,
    area: Area,
    minutes: u64,
    cwd: &'static str,
    program: &'static str,
    args: &'static [&'static str],
) -> Step {
    Step {
        name,
        area,
        run: Run::Program { cwd, program, args },
        heavy: false,
        budget: mins(minutes),
        needs_generate: true,
    }
}

const fn mins(minutes: u64) -> Duration {
    Duration::from_secs(minutes * 60)
}

impl Step {
    /// Compiles or otherwise saturates the machine, so it waits for the heavy lock.
    const fn heavy(self) -> Self {
        Self {
            heavy: true,
            ..self
        }
    }
}

/// Brings the generated sources up to date. Not heavy itself: it takes the heavy lock only around
/// build_runner, the one generator that saturates the machine.
pub const GENERATE: Step = Step {
    name: "generate",
    area: Area::Protocol,
    run: Run::Native {
        describe: generate::DESCRIBE,
        run: generate::step,
    },
    heavy: false,
    budget: mins(10),
    needs_generate: false,
};

pub const CHECKS: &[Step] = &[
    // The root `check` includes the imprint build and every project's ktlintCheck.
    program(
        "services",
        Area::Services,
        15,
        "services",
        "./gradlew",
        &["check"],
    )
    .heavy(),
    program(
        "backend:lint",
        Area::Backend,
        10,
        "backend",
        "cargo",
        &[
            "clippy",
            "--locked",
            "--workspace",
            "--all-targets",
            "--",
            "-D",
            "warnings",
        ],
    )
    .heavy(),
    program(
        "backend:test",
        Area::Backend,
        12,
        "backend",
        "cargo",
        &["test", "--locked", "--workspace", "--no-fail-fast"],
    )
    .heavy(),
    // The component test framework is its own workspace; its suite crate is the `components` area.
    // Its wasmtime host takes most of the budget on a cold build.
    program(
        "backend:support",
        Area::Backend,
        25,
        "backend",
        "cargo",
        &[
            "test",
            "--locked",
            "--manifest-path",
            "tests/component/Cargo.toml",
            "--workspace",
            "--exclude",
            "typewriter-component-tests",
            "--no-fail-fast",
        ],
    )
    .heavy(),
    Step {
        name: "components",
        area: Area::Components,
        run: Run::Native {
            describe: components::DESCRIBE,
            run: components::step,
        },
        heavy: true,
        budget: mins(30),
        needs_generate: true,
    },
    program(
        "protocol",
        Area::Protocol,
        5,
        ".",
        "bun",
        &["run", "check:protocol"],
    ),
    // `flutter analyze`, not `dart analyze`: the panel lints need the Flutter SDK. Analysis is heavy
    // too, so no two Flutter commands resolve the same package's dependencies at once.
    program(
        "panel:analyze",
        Area::Panel,
        5,
        "panel",
        "flutter",
        &["analyze"],
    )
    .heavy(),
    program(
        "panel:testkit:analyze",
        Area::Panel,
        3,
        "panel/testkit",
        "flutter",
        &["analyze"],
    )
    .heavy(),
    program(
        "panel:widgetbook:analyze",
        Area::Panel,
        3,
        "panel/widgetbook",
        "flutter",
        &["analyze"],
    )
    .heavy(),
    program(
        "panel:app",
        Area::Panel,
        10,
        "panel",
        "flutter",
        &["test", "--concurrency=2"],
    )
    .heavy(),
    program(
        "panel:testkit",
        Area::Panel,
        5,
        "panel/testkit",
        "flutter",
        &["test", "--concurrency=2"],
    )
    .heavy(),
    program(
        "panel:widgetbook",
        Area::Panel,
        5,
        "panel/widgetbook",
        "flutter",
        &["test", "--concurrency=2"],
    )
    .heavy(),
    Step {
        name: "gitops",
        area: Area::Gitops,
        run: Run::Native {
            describe: gitops::DESCRIBE,
            run: gitops::gitops,
        },
        heavy: false,
        budget: mins(3),
        // The subscription ConfigMaps it validates are tracked deployment manifests.
        needs_generate: false,
    },
    // One native step: the install must finish before validate and build, and steps run in
    // parallel.
    Step {
        name: "docs",
        area: Area::Docs,
        run: Run::Native {
            describe: docs::DESCRIBE,
            run: docs::check,
        },
        heavy: false,
        budget: mins(10),
        // The site reads only its own sources.
        needs_generate: false,
    },
    Step {
        name: "quality",
        area: Area::Quality,
        run: Run::Native {
            describe: review::DESCRIBE,
            run: review::gate,
        },
        heavy: false,
        budget: mins(5),
        // The detectors read tracked sources only; generated output is ignored.
        needs_generate: false,
    },
    // Building the harness already needs its own generated types, so these never wait for
    // generate.
    Step {
        needs_generate: false,
        ..program(
            "xtask:lint",
            Area::Xtask,
            5,
            ".",
            "cargo",
            &[
                "clippy",
                "--locked",
                "--manifest-path",
                "xtask/Cargo.toml",
                "--all-targets",
                "--",
                "-D",
                "warnings",
            ],
        )
        .heavy()
    },
    Step {
        needs_generate: false,
        ..program(
            "xtask:format",
            Area::Xtask,
            1,
            ".",
            "cargo",
            &["fmt", "--check", "--manifest-path", "xtask/Cargo.toml"],
        )
    },
];

/// The steps of `area`, or every step.
pub fn select(area: Option<Area>) -> Vec<&'static Step> {
    CHECKS
        .iter()
        .filter(|step| area.is_none_or(|area| step.area == area))
        .collect()
}

/// The `steps` whose area a change to `paths` affects, by path prefix. Markdown outside the
/// documentation site documents the code and affects no area, so a change of only such Markdown
/// selects nothing.
pub fn affected<'a>(steps: Vec<&'a Step>, paths: &[std::path::PathBuf]) -> Vec<&'a Step> {
    let paths: Vec<String> = paths
        .iter()
        .filter(|path| {
            path.starts_with(DOCS_SITE)
                || path.extension().is_none_or(|extension| extension != "md")
        })
        .map(|path| path.to_string_lossy().into_owned())
        .collect();
    steps
        .into_iter()
        .filter(|step| {
            paths.iter().any(|path| {
                EVERY_AREA
                    .iter()
                    .chain(step.area.paths())
                    .any(|prefix| path.starts_with(prefix))
            })
        })
        .collect()
}

/// Whether any of `steps` reads generated sources.
fn needs_generate(steps: &[&Step]) -> bool {
    steps.iter().any(|step| step.needs_generate)
}

/// Prints each area of `steps` with its budget as JSON: the sum of its steps' budgets, plus
/// [`GENERATE`] when the area needs it, since each CI job generates for itself.
pub fn list(steps: &[&Step]) {
    let mut areas: Vec<(Area, Duration, bool)> = Vec::new();
    for step in steps {
        match areas.iter_mut().find(|(area, ..)| *area == step.area) {
            Some((_, budget, generates)) => {
                *budget += step.budget;
                *generates |= step.needs_generate;
            }
            None => areas.push((step.area, step.budget, step.needs_generate)),
        }
    }
    let areas = areas.into_iter().map(|(area, budget, generates)| {
        (
            area,
            if generates {
                budget + GENERATE.budget
            } else {
                budget
            },
        )
    });
    let areas = areas
        .map(|(area, budget)| serde_json::json!({ "area": area.name(), "budget_minutes": budget.as_secs() / 60 }))
        .collect::<Vec<_>>();
    println!("{}", serde_json::Value::Array(areas));
}

/// Prints the command each step runs, one per line.
pub fn print(ctx: &Context, steps: &[&Step]) {
    let generate = needs_generate(steps).then_some(&GENERATE);
    for step in generate.into_iter().chain(steps.iter().copied()) {
        match &step.run {
            Run::Program { cwd, program, args } => {
                let command = display(&ctx.tool(cwd, program, args));
                match *cwd {
                    "." => println!("{}: {command}", step.name),
                    cwd => println!("{}: cd {cwd} && {command}", step.name),
                }
            }
            Run::Native { describe, .. } => println!("{}: {describe}", step.name),
        }
    }
}

/// Runs `steps`, printing one line per finished step and a short summary for each failure. An
/// interrupt stops every running step and every step still waiting for the heavy lock.
pub fn run(ctx: &Context, steps: &[&'static Step]) -> Result<()> {
    process::install_interrupt_handler();
    let logs = ctx.root.join(".xtask/logs");
    fs::create_dir_all(&logs).with_context(|| format!("cannot create {}", logs.display()))?;
    let commit = ctx
        .tool(".", "git", &["rev-parse", "HEAD"])
        .output_text()?
        .trim()
        .to_owned();
    let run = |step: &Step| run_step(ctx, step, &logs, &commit);
    if needs_generate(steps) && !run(&GENERATE) {
        bail!("generate failed, so no step ran");
    }
    let failed = thread::scope(|scope| {
        let running = steps
            .iter()
            .map(|step| (step, scope.spawn(|| run(step))))
            .collect::<Vec<_>>();
        running
            .into_iter()
            .filter_map(|(step, handle)| {
                let passed = handle.join().unwrap_or_else(|_| {
                    eprintln!("{:<26} FAILED: the harness panicked", step.name);
                    false
                });
                (!passed).then_some(step.name)
            })
            .collect::<Vec<_>>()
    });
    if !failed.is_empty() {
        bail!(
            "{} of {} steps failed: {}",
            failed.len(),
            steps.len(),
            failed.join(", ")
        );
    }
    Ok(())
}

/// Runs one step, records its `TestRun` and reports it; returns whether it passed.
fn run_step(ctx: &Context, step: &Step, logs: &Path, commit: &str) -> bool {
    let name = step.name.replace(':', "-");
    let log = logs.join(format!("{name}.log"));
    let lock = step
        .heavy
        .then(|| HeavyLock::acquire(step.name))
        .transpose();
    let started_at = SystemTime::now();
    let started = Instant::now();
    let outcome = lock.and_then(|_lock| execute(ctx, step, &log));
    let elapsed = started.elapsed();
    let run = TestRun {
        runner: Runner::Step,
        commit: commit.to_owned(),
        started_at_millis: millis(started_at),
        cases: vec![TestCase {
            id: step.name.to_owned(),
            outcome: match &outcome {
                Ok(()) => Outcome::Passed,
                Err(error) => Outcome::Failed(Box::new(Failure {
                    message: format!("{error:#}"),
                    ..Failure::default()
                })),
            },
            duration_millis: i64::try_from(elapsed.as_millis()).unwrap_or(i64::MAX),
            ..TestCase::default()
        }],
        _unrecognized: None,
    };
    let path = ctx.root.join(format!(".xtask/results/steps/{name}.json"));
    let written = results::write(&run, &path);
    let outcome = outcome.and(written);
    report(step, outcome, elapsed, &log)
}

/// Runs the step as a process in its own group and stops the whole group when the step exits,
/// exceeds its budget or the harness is interrupted.
fn execute(ctx: &Context, step: &Step, log: &Path) -> Result<()> {
    let mut file = File::create(log).with_context(|| format!("cannot create {}", log.display()))?;
    let mut command = match &step.run {
        Run::Program { cwd, program, args } => {
            let command = ctx.tool(cwd, program, args);
            writeln!(file, "$ cd {cwd} && {}", display(&command))?;
            command
        }
        Run::Native { .. } => {
            let mut command = Command::new(std::env::current_exe()?);
            command.args(["step", step.name]).current_dir(&ctx.root);
            command
        }
    };
    command
        .stdin(Stdio::null())
        .stdout(file.try_clone()?)
        .stderr(file);
    let mut group = Group::spawn(&mut command)
        .with_context(|| format!("{} did not start; is the devenv shell active?", step.name))?;
    let status = group
        .wait(Some(Instant::now() + step.budget))
        .map_err(|error| {
            if process::interrupted() {
                error
            } else {
                anyhow!("exceeded its {} minute budget", step.budget.as_secs() / 60)
            }
        })?;
    if !status.success() {
        bail!("exited with {status}");
    }
    Ok(())
}

/// Runs the native step `name` in this process, writing to the log the graph opened as standard
/// output. `xtask step <name>` calls this.
pub fn run_native(ctx: &Context, name: &str) -> Result<()> {
    let Some(Run::Native { run, .. }) = std::iter::once(&GENERATE)
        .chain(CHECKS)
        .find(|step| step.name == name)
        .map(|step| &step.run)
    else {
        bail!("{name} is not a native step");
    };
    let log = File::from(std::io::stdout().as_fd().try_clone_to_owned()?);
    run(ctx, &log)
}

fn report(step: &Step, outcome: Result<()>, elapsed: Duration, log: &Path) -> bool {
    let seconds = elapsed.as_secs_f32();
    match outcome {
        Ok(()) => {
            println!("{:<26} ok     {seconds:>6.1} s", step.name);
            true
        }
        Err(error) => {
            let mut summary = format!("{:<26} FAILED after {seconds:.1} s: {error:#}\n", step.name);
            for line in process::log_tail(log, FAILURE_TAIL) {
                summary.push_str(&format!("  {line}\n"));
            }
            summary.push_str(&format!("  full log: {}", log.display()));
            eprintln!("{summary}");
            false
        }
    }
}

fn millis(time: SystemTime) -> i64 {
    time.duration_since(UNIX_EPOCH).map_or(0, |since| {
        i64::try_from(since.as_millis()).unwrap_or(i64::MAX)
    })
}
