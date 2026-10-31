//! `cargo xtask e2e`: the end to end suites. Each suite starts the worktree's panel stack, drives
//! the panel's `integration_test` scenarios through `flutter drive` inside the evidence recorder
//! and writes their `TestRun`, every attempt included, to `.xtask/results/<suite>`, where the
//! change report and the evidence section read it. Each attempt keeps its clips and screenshots
//! under `attempts/<n>/` beside it. `--only` selects scenarios and `--repeat` runs each of them an
//! exact number of times, to hunt a flaky scenario. The full suite runs the panel web
//! scenarios against a fresh CI cluster instead (`cargo xtask cluster ci`, `cargo xtask deploy ci`).
//!
//! `flutter drive` rather than `flutter test integration_test`: only the host driver
//! (`panel/test_driver/integration_test.dart`) can write files on desktop and on web, and it is
//! what receives the scenarios' results and screenshots.

use std::io::Write;
use std::net::{Ipv4Addr, TcpListener};
use std::num::NonZeroU32;
use std::path::Path;
use std::process::ExitStatus;
use std::time::Duration;

use anyhow::{Context as _, Result, bail};

use crate::deploy::{self, Cluster};
use crate::evidence::{self, Recorded};
use crate::lock::HeavyLock;
use crate::process::{Supervisor, Unsupervised};
use crate::results::{self, AttemptPolicy, Outcome, Quarantine, TestRun};
use crate::stack::{self, typewriter};
use crate::{CommandExt, Context, cluster, generate, secrets};

/// Where the stack writes the panel's compile time defines (it publishes the same path as
/// `STACK_PANEL_DEFINES`), relative to the repository root.
const PANEL_DEFINES: &str = ".xtask/state/stack/panel.json";

/// Xcode build settings (Flutter passes `FLUTTER_XCODE_<setting>` variables to xcodebuild) that
/// sign the macOS app ad hoc without the keychain entitlement, so the build needs no provisioning
/// profile or developer account; scenarios keep tokens in memory. Linux ignores them.
const UNSIGNED_MACOS: [(&str, &str); 4] = [
    ("CODE_SIGN_IDENTITY", "-"),
    ("CODE_SIGN_STYLE", "Manual"),
    ("DEVELOPMENT_TEAM", ""),
    ("PROVISIONING_PROFILE_SPECIFIER", ""),
];

/// Relative to the repository root. Xcode applies command line settings to every target,
/// including the plugins' package targets, so the path passed is absolute.
const UNSIGNED_ENTITLEMENTS: &str = "panel/macos/Runner/EndToEnd.entitlements";

/// The devenv shell's Nix C toolchain. xcodebuild reads environment variables as build settings,
/// and these would replace Xcode's compiler and linker with the Nix wrappers, which cannot link a
/// macOS app.
const NIX_TOOLCHAIN: [&str; 3] = ["CC", "CXX", "LD"];

/// What `cargo xtask e2e` runs.
#[derive(clap::Args)]
pub struct E2eArgs {
    suite: Suite,
    /// Requirement ids (CONN-1) or full scenario ids; empty runs every scenario.
    #[arg(long, value_delimiter = ',')]
    only: Vec<String>,
    /// Attempts per selected scenario, instead of one attempt plus a rerun of failures.
    #[arg(long, default_value_t = NonZeroU32::MIN)]
    repeat: NonZeroU32,
}

impl E2eArgs {
    /// One attempt and a rerun of failures, or exactly `--repeat` attempts.
    fn policy(&self) -> AttemptPolicy {
        match self.repeat.get() {
            1 => AttemptPolicy::RerunFailures(2),
            n => AttemptPolicy::Exactly(i32::try_from(n).unwrap_or(i32::MAX)),
        }
    }
}

/// An end to end suite.
#[derive(Clone, Copy, PartialEq, Eq, clap::ValueEnum)]
pub enum Suite {
    /// The panel as a desktop app on this machine, over native NATS.
    Panel,
    /// The panel in Chrome through chromedriver, over NATS websockets.
    PanelWeb,
    /// A fresh CI cluster with this commit's backend deployed, and the panel web scenarios
    /// against its real Authentik, operator mode NATS and runtime operator.
    Full,
}

impl Suite {
    fn name(self) -> &'static str {
        match self {
            Self::Panel => "panel",
            Self::PanelWeb => "panel-web",
            Self::Full => "full",
        }
    }

    /// The whole run of one attempt once the stack is up: the app build, the scenarios and
    /// one rerun.
    fn budget(self) -> Duration {
        Duration::from_secs(30 * 60)
    }
}

/// Runs the selected scenarios of the suite and reports them.
pub fn run(ctx: &Context, args: &E2eArgs) -> Result<()> {
    match args.suite {
        Suite::Full => {
            cluster::create_ci(ctx, &secrets::Ci::load()?)?;
            deploy::deploy(ctx, Cluster::Ci)?;
            scenarios(ctx, args, Suite::PanelWeb, Target::Cluster)
        }
        suite => scenarios(ctx, args, suite, Target::Stack),
    }
}

/// What the scenarios run against.
#[derive(Clone, Copy)]
enum Target {
    /// A fresh worktree stack, up for the run only.
    Stack,
    /// The CI cluster `cargo xtask deploy ci` deployed to.
    Cluster,
}

/// Runs `suite`'s selected scenarios against `target`.
fn scenarios(ctx: &Context, args: &E2eArgs, suite: Suite, target: Target) -> Result<()> {
    // The panel compiles against the generated Skir and build_runner sources.
    generate::generate(ctx, None)?;
    let name = match target {
        Target::Stack => suite.name().to_owned(),
        Target::Cluster => format!("{}-{}", Suite::Full.name(), suite.name()),
    };
    let shown = Path::new(evidence::RESULTS).join(&name);
    let evidence = ctx.root.join(&shown);
    if evidence.exists() {
        std::fs::remove_dir_all(&evidence)
            .with_context(|| format!("cannot clear {}", evidence.display()))?;
    }
    let commit = ctx
        .tool(".", "git", &["rev-parse", "HEAD"])
        .output_text()?
        .trim()
        .to_owned();
    let quarantine = Quarantine::load(ctx)?;
    // Flutter builds the app inside `flutter drive`, so the whole run is one heavy build.
    let lock = || HeavyLock::acquire(&format!("e2e {name}"));
    let attempts = |defines: &Path, supervisor: &mut dyn Supervisor| {
        results::attempts(args.policy(), &args.only, &quarantine, |n, ids| {
            drive(ctx, supervisor, suite, defines, &evidence, n, ids)
        })
    };
    let run = match target {
        Target::Stack => {
            let budget = suite.budget() * args.repeat.get();
            stack::run(ctx, &typewriter::panel(), budget, |stack| {
                let _lock = lock()?;
                attempts(&ctx.root.join(PANEL_DEFINES), stack)
            })?
        }
        Target::Cluster => {
            let _lock = lock()?;
            attempts(
                &ctx.root.join(cluster::STATE).join("panel.json"),
                &mut Unsupervised::with_interrupts(),
            )?
        }
    };
    let run = TestRun { commit, ..run };
    let file = evidence.join("test_run.json");
    results::write(&run, &file)?;
    verdict(
        &name,
        &file,
        &run,
        &quarantine,
        &shown,
        &mut std::io::stderr(),
    )?;
    println!(
        "{name}: {} scenarios passed ({})",
        run.cases.len(),
        file.display()
    );
    Ok(())
}

/// Attempt `n` of the scenarios `only` selects (every scenario when empty): one `flutter drive`
/// writing its evidence to `attempts/<n>/` of the suite's `evidence` folder. Its artifact paths
/// are made relative to `evidence`, where the folded run is written.
fn drive(
    ctx: &Context,
    supervisor: &mut dyn Supervisor,
    suite: Suite,
    defines_file: &Path,
    evidence: &Path,
    n: u32,
    only: &[String],
) -> Result<TestRun> {
    let folder = Path::new("attempts").join(n.to_string());
    let mut run = drive_once(
        ctx,
        supervisor,
        suite,
        defines_file,
        &evidence.join(&folder),
        only,
    )?;
    for artifact in run
        .cases
        .iter_mut()
        .flat_map(|case| &mut case.attempts)
        .flat_map(|attempt| &mut attempt.artifacts)
    {
        artifact.path = folder.join(&artifact.path).display().to_string();
    }
    Ok(run)
}

/// One `flutter drive` run writing its `TestRun` to `out`; a non empty `only` limits it to those
/// scenario or requirement ids. A failing scenario is a result, not an error; a drive that fails
/// without reporting a failing scenario is one.
fn drive_once(
    ctx: &Context,
    supervisor: &mut dyn Supervisor,
    suite: Suite,
    defines_file: &Path,
    out: &Path,
    only: &[String],
) -> Result<TestRun> {
    let mut command: Vec<String> = [
        "flutter",
        "drive",
        "--driver=test_driver/integration_test.dart",
        "--target=integration_test/all_test.dart",
    ]
    .map(String::from)
    .into();
    command.push(defines(defines_file));
    if !only.is_empty() {
        command.push(format!(
            "--dart-define=SCENARIOS={}",
            serde_json::to_string(only)?
        ));
    }
    let recorded = match suite {
        Suite::Panel => {
            command.extend(["-d".into(), desktop_device()?.into()]);
            let recorded = UNSIGNED_MACOS.iter().fold(
                Recorded::video(command).env(
                    "FLUTTER_XCODE_CODE_SIGN_ENTITLEMENTS",
                    ctx.root.join(UNSIGNED_ENTITLEMENTS).display().to_string(),
                ),
                |recorded, (setting, value)| {
                    recorded.env(&format!("FLUTTER_XCODE_{setting}"), *value)
                },
            );
            NIX_TOOLCHAIN
                .iter()
                .fold(recorded, |recorded, key| recorded.env_remove(key))
        }
        Suite::PanelWeb => {
            // A free port rather than chromedriver's 4444, so worktrees can run this at once.
            let port = TcpListener::bind((Ipv4Addr::LOCALHOST, 0))?
                .local_addr()?
                .port();
            command.extend([
                "-d".into(),
                "web-server".into(),
                "--browser-name=chrome".into(),
                format!("--driver-port={port}"),
                // Linux records Chrome's window on the virtual display; elsewhere nothing is
                // recorded and no window should open.
                if cfg!(target_os = "linux") {
                    "--no-headless".into()
                } else {
                    "--headless".into()
                },
            ]);
            Recorded::video(command).with(vec!["chromedriver".into(), format!("--port={port}")])
        }
        Suite::Full => unreachable!("the full suite drives the panel web scenarios"),
    }
    .in_dir("panel")
    .env("EVIDENCE_DIR", out.display().to_string());
    // Without a results file the scenarios never ran (the build or the launch failed), and
    // recording fails.
    let (run, exit) = evidence::record_with(ctx, out, recorded, supervisor)?;
    driven(exit, run)
}

/// The results of one drive that exited with `exit`. A drive that exits non zero without a
/// failing scenario crashed (the build, the launch or the driver failed), so its results prove
/// nothing; a failing scenario explains the exit and is a result.
fn driven(exit: ExitStatus, run: TestRun) -> Result<TestRun> {
    let failed = run
        .cases
        .iter()
        .flat_map(|case| &case.attempts)
        .any(|attempt| matches!(attempt.outcome, Outcome::Failed(_)));
    if !exit.success() && !failed {
        bail!(
            "flutter drive failed with {exit} without a failing scenario; its output above says why"
        );
    }
    Ok(run)
}

/// The suite's verdict on its `run`, written to `file` in the `evidence` folder: every case that
/// did not plainly pass goes to `out`, pointing at its evidence, and the run fails when a
/// scenario failed or none was reported.
fn verdict(
    name: &str,
    file: &Path,
    run: &TestRun,
    quarantine: &Quarantine,
    evidence: &Path,
    out: &mut dyn Write,
) -> Result<()> {
    // Every suite drives the same registered scenarios, so a drive reporting none is broken.
    if run.cases.is_empty() {
        bail!(
            "{name}: the drive reported no scenarios ({})",
            file.display()
        );
    }
    results::report(run, quarantine, Some(evidence), out)
}

fn defines(file: &Path) -> String {
    format!("--dart-define-from-file={}", file.display())
}

/// The Flutter desktop device of this machine.
fn desktop_device() -> Result<&'static str> {
    if cfg!(target_os = "macos") {
        Ok("macos")
    } else if cfg!(target_os = "linux") {
        Ok("linux")
    } else {
        bail!("the panel suite runs on macOS and Linux")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{e2e_args as parsed, exited, failed, refusal, run};

    #[test]
    fn a_plain_run_attempts_every_scenario_once_and_reruns_failures() {
        let args = parsed(&["panel"]).unwrap();
        assert!(args.only.is_empty());
        assert_eq!(args.policy(), AttemptPolicy::RerunFailures(2));
    }

    #[test]
    fn a_repeated_selection_attempts_each_selected_scenario_exactly_that_often() {
        let args = parsed(&[
            "panel",
            "--only",
            "CONN-1,[REALM-2] Opens",
            "--repeat",
            "20",
        ])
        .unwrap();
        assert_eq!(args.only, ["CONN-1", "[REALM-2] Opens"]);
        assert_eq!(args.policy(), AttemptPolicy::Exactly(20));
    }

    #[test]
    fn a_repeat_of_zero_is_refused() {
        assert!(parsed(&["panel", "--repeat", "0"]).is_err());
    }

    #[test]
    fn a_drive_that_crashes_without_results_fails_the_run_and_says_so() {
        let error = driven(exited(1), run(&[])).unwrap_err().to_string();
        assert!(error.contains("without a failing scenario"), "{error}");
    }

    #[test]
    fn a_drive_that_crashes_after_passing_scenarios_fails_the_run() {
        assert!(driven(exited(1), run(&[("a", Outcome::Passed)])).is_err());
    }

    #[test]
    fn a_drive_that_exits_non_zero_for_a_failing_scenario_reports_it() {
        let reported = driven(exited(1), run(&[("a", failed("boom"))])).unwrap();
        assert!(matches!(
            reported.cases[0].attempts[0].outcome,
            Outcome::Failed(_)
        ));
    }

    #[test]
    fn a_run_that_reports_no_scenarios_fails() {
        let error = refusal(verdict(
            "panel",
            Path::new("test_run.json"),
            &run(&[]),
            &Quarantine::default(),
            Path::new("results/panel"),
            &mut Vec::new(),
        ));
        assert!(error.contains("no scenarios"), "{error}");
    }

    #[test]
    fn a_run_whose_scenarios_pass_passes() {
        let passing = run(&[("a", Outcome::Passed), ("b", Outcome::Passed)]);
        assert!(driven(exited(0), passing.clone()).is_ok());
        assert!(
            verdict(
                "panel",
                Path::new("test_run.json"),
                &passing,
                &Quarantine::default(),
                Path::new("results/panel"),
                &mut Vec::new()
            )
            .is_ok()
        );
    }

    #[test]
    fn a_run_with_one_failing_scenario_fails_and_names_it() {
        let failing = run(&[("a", Outcome::Passed), ("b", failed("boom"))]);
        let error = refusal(verdict(
            "panel",
            Path::new("test_run.json"),
            &failing,
            &Quarantine::default(),
            Path::new("results/panel"),
            &mut Vec::new(),
        ));
        assert!(error.contains("1 of 2 cases failed: b"), "{error}");
    }
}
