//! `cargo xtask e2e game` and `cargo xtask e2e playtest`: the game requirements against real
//! Minecraft clients on a stepped Paper, which the game pool boots on this machine. The `game` suite
//! runs the product's requirements inside the stack, whose services their Papers' Typewriter talks
//! to; the `playtest` suite runs the framework's own, whose Papers need no stack. Paper, the clients
//! and the Gradle build that starts them all run here, so the whole run is one heavy build. A Gradle
//! of its own builds the suite first and exits, so no compiler is alive while the suite runs. Every
//! `gameTest` task of the suite runs at once, so their test JVMs share the one pool, which retries
//! failed requirements on its warm clients, runs each touched requirement again at other paces, and
//! writes the run file. That file is the gate: Gradle's exit only adds a failure the file cannot show.
//!
//! `--demos` is the suite's demo run, after its verdict: each requirement the verdict run's file
//! shows failed, flaky, quarantined or touched runs once more with clips, into a run file of its own
//! that never gates.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result, anyhow, bail};

use super::{E2eArgs, take_turn};
use crate::cgroup;
use crate::lock::{self, HeavyLock};
use crate::process::{self, Group};
use crate::results::{self, Quarantine, TestRun, Verdict};
use crate::review::change::Change;
use crate::skirout::base::harness::v1::test_run::Runner;
use crate::stack::{self, typewriter};
use crate::{CommandExt as _, Context, evidence, generate, goldens};

/// A game suite: whose requirements it runs, and whether their Papers need the stack.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub(crate) enum GameSuite {
    /// The product's requirements, inside the stack.
    Game,
    /// The framework's own requirements, without the stack.
    Playtest,
}

impl GameSuite {
    /// Its name: the `gameTest` tasks' `playtest.suite` and its results folder.
    pub(crate) fn name(self) -> &'static str {
        match self {
            Self::Game => "game",
            Self::Playtest => "playtest",
        }
    }
}

/// The paces, in milliseconds between ticks, a touched requirement whose attempts passed runs at
/// once more each: 5 ms runs ticks as fast as clients follow, 50 ms is a real server's pace. Every
/// window must hold at the same tick at each.
const PACES: &str = "5,50";

/// Runs the selected requirements of `suite`, or its demo run with `--demos`, and reports the run
/// the game pool wrote.
pub(super) fn run(ctx: &Context, args: &E2eArgs, suite: GameSuite) -> Result<()> {
    // The suite compiles against the generated Skir types, and the pool writes its run with them.
    generate::protocol(ctx)?;
    goldens::fetch_missing(ctx)?;
    let verdict_shown = Path::new(evidence::RESULTS).join(suite.name());
    let quarantine = Quarantine::load(ctx)?;
    if args.demos {
        return demos(ctx, args, suite, &verdict_shown, &quarantine);
    }
    let evidence = ctx.root.join(&verdict_shown);
    // A requirement the change touched runs again at other paces, and in the demo run.
    let touched = touched_lines(&Change::load(ctx, args.base.as_deref())?);
    let asked = Asked {
        args,
        suite,
        touched: Some(&touched),
        demos: None,
        quarantine: &quarantine,
    };
    let ran = gradle_run(ctx, &asked, &evidence)?;
    let run = report_run(ctx, &ran, false)?;
    judge(
        &run,
        ran.gradle,
        &args.only,
        &quarantine,
        &verdict_shown,
        &mut std::io::stderr(),
    )?;
    println!(
        "{}: {} requirements passed ({})",
        suite.name(),
        run.cases.len(),
        ran.file.display()
    );
    Ok(())
}

/// The demo run of `suite`: reruns once, with clips, each requirement the verdict run in
/// `verdict_shown` failed, flaky, quarantined or touched, into `<suite>-demos`. It never gates: a
/// demo that fails or a run that breaks is reported, and the run passes.
fn demos(
    ctx: &Context,
    args: &E2eArgs,
    suite: GameSuite,
    verdict_shown: &Path,
    quarantine: &Quarantine,
) -> Result<()> {
    let verdict_file = ctx.root.join(verdict_shown).join("test_run.json");
    if !verdict_file.exists() {
        println!(
            "{}: no demos, since the verdict run wrote no run file at {}",
            suite.name(),
            verdict_file.display()
        );
        return Ok(());
    }
    let selected = demo_selection(&results::read(&verdict_file)?, quarantine)?;
    if selected.is_empty() {
        println!(
            "{}: no demos, since every requirement passed untouched",
            suite.name()
        );
        return Ok(());
    }
    let shown = PathBuf::from(format!("{}-demos", verdict_shown.display()));
    let evidence = ctx.root.join(&shown);
    let asked = Asked {
        args,
        suite,
        touched: None,
        demos: Some(&selected),
        quarantine,
    };
    let demoed = gradle_run(ctx, &asked, &evidence).and_then(|ran| report_run(ctx, &ran, true));
    match demoed {
        Ok(run) => {
            results::report(&run, quarantine, Some(&shown), &mut std::io::stderr())
                .unwrap_or_else(|failed| eprintln!("{}: the demos show: {failed:#}", suite.name()));
            println!(
                "{}: demo run of {} ({})",
                suite.name(),
                selected.join(", "),
                shown.display()
            );
        }
        Err(broken) => eprintln!("{}: the demo run proved nothing: {broken:#}", suite.name()),
    }
    Ok(())
}

/// The requirements a demo run reruns, once each: those whose case in the verdict `run` failed, was
/// flaky, is quarantined, or the change touched. An interrupted case has no verdict to show.
pub(crate) fn demo_selection(run: &TestRun, quarantine: &Quarantine) -> Result<Vec<String>> {
    let mut selected: Vec<String> = Vec::new();
    for case in &run.cases {
        let shown = match results::verdict(run, case, quarantine)? {
            Verdict::Failed | Verdict::Flaky | Verdict::Quarantined | Verdict::Unsteady => true,
            Verdict::Passed => case.touched,
            Verdict::Interrupted => false,
        };
        let requirement = case.requirement.clone().unwrap_or_else(|| case.id.clone());
        if shown && !selected.contains(&requirement) {
            selected.push(requirement);
        }
    }
    Ok(selected)
}

/// The run file `ran` wrote, with its commit, written back; a demo run's says it is `evidence_only`.
fn report_run(ctx: &Context, ran: &Ran, evidence_only: bool) -> Result<TestRun> {
    let commit = ctx
        .tool(".", "git", &["rev-parse", "HEAD"])
        .output_text()?
        .trim()
        .to_owned();
    // The pool names the run's logs folder itself, so a run cut short points at its pool log too.
    let run = TestRun {
        commit,
        evidence_only,
        ..own_run(ran)?
    };
    results::write(&run, &ran.file)?;
    Ok(run)
}

/// How long the stack lets the suite run, its build included; a suite without the stack gets as long.
const GAME_BUDGET: Duration = Duration::from_secs(50 * 60);

/// What a run of a game suite was asked for: the command line, the suite, the file of lines the
/// change touched (none for a demo run, which reruns each requirement once whatever it touched), the
/// requirements a demo run reruns (none for the verdict run) and the quarantine.
struct Asked<'a> {
    args: &'a E2eArgs,
    suite: GameSuite,
    touched: Option<&'a str>,
    demos: Option<&'a [String]>,
    quarantine: &'a Quarantine,
}

/// Runs what was `asked` in Gradle, writing into `evidence`: the product's suite inside the stack,
/// with the stack's environment, the framework's without one.
fn gradle_run(ctx: &Context, asked: &Asked, evidence: &Path) -> Result<Ran> {
    // The run's cgroup tree lives as long as its Gradle; the stack places its services in it.
    let id = format!("{}-{}", now_millis(), std::process::id());
    let stack_bytes = match asked.suite {
        GameSuite::Game => typewriter::game().memory_bytes(),
        GameSuite::Playtest => 0,
    };
    let parts = cgroup::install(cgroup::Tree::delegated(&id, stack_bytes)?);
    if parts.tree().is_none() {
        println!(
            "{}: no part's memory is held to its limit or measured, since no cgroup is delegated ({})",
            asked.suite.name(),
            cgroup::DELEGATED
        );
    }
    let ran = suite_run(ctx, asked, evidence);
    if let Some(tree) = parts.tree() {
        // Peaks are reported, never part of the verdict: a run whose peaks cannot be added keeps
        // its verdict. A run that wrote no file has nothing to add them to.
        if let Ok(ran) = &ran
            && ran.file.exists()
            && let Err(error) = tree.record(&ran.file)
        {
            eprintln!("cannot add the stack's and Gradle's peaks to the run file: {error:#}");
        }
        tree.remove();
    }
    ran
}

/// Runs what was `asked` of the suite: the game suite against the stack, the playtest suite alone.
fn suite_run(ctx: &Context, asked: &Asked, evidence: &Path) -> Result<Ran> {
    match asked.suite {
        GameSuite::Game => {
            let keep = ctx
                .root
                .join(super::STACK_EVIDENCE)
                .join(asked.suite.name());
            let (ran, _) = stack::run_keeping_evidence(
                ctx,
                &typewriter::game(),
                GAME_BUDGET,
                &keep,
                |stack| {
                    in_turn(ctx, asked, evidence, |command| {
                        stack
                            .run_command(command)
                            .context("cannot run Gradle for the game suite")
                    })
                },
            )?;
            Ok(ran)
        }
        GameSuite::Playtest => {
            process::install_interrupt_handler();
            let deadline = Instant::now() + GAME_BUDGET;
            in_turn(ctx, asked, evidence, |command| {
                Group::spawn(command)
                    .context("cannot run Gradle for the playtest suite")?
                    .wait(Some(deadline))
            })
        }
    }
}

/// Builds and runs what was `asked` under the heavy lock, writing into `evidence`, each Gradle
/// through `gradle`, and returns how it ran.
fn in_turn(
    ctx: &Context,
    asked: &Asked,
    evidence: &Path,
    mut gradle: impl FnMut(&mut Command) -> Result<ExitStatus>,
) -> Result<Ran> {
    let turn = begin_turn(
        Path::new(lock::HEAVY_LOCK),
        &format!("e2e {}", asked.suite.name()),
        evidence,
        asked.touched,
    )?;
    // The run's pool writes this id into the run file, and its test JVMs connect only to a pool of
    // it, so a file or pool an earlier run left never passes for this one.
    let run_id = format!("{}-{}", now_millis(), std::process::id());
    let planned = Planned {
        suite: asked.suite,
        demos: asked.demos,
        run_id: &run_id,
        file: &turn.file,
        touched: turn.touched.as_deref(),
        logs: &turn.logs,
    };
    Ok(Ran {
        file: turn.file.clone(),
        run_id: run_id.clone(),
        gradle: build_then_run(
            |step, arguments| {
                let mut command = ctx.tool(
                    "services",
                    "./gradlew",
                    &arguments.iter().map(String::as_str).collect::<Vec<_>>(),
                );
                // The build runs in the build's leaf with the stack's builds. The test run starts
                // once the daemons they left are gone, in a leaf held to its limit; the pool it
                // starts goes into the game's cgroup.
                if let Some(tree) = cgroup::installed() {
                    match step {
                        Step::Build => tree.gradle_build().place(&mut command)?,
                        Step::Test => {
                            tree.end_build()?;
                            tree.gradle_test().place(&mut command)?;
                            command.env(cgroup::GAME, tree.game());
                        }
                    }
                }
                gradle(&mut command)
            },
            asked.suite,
            &gradle_args(asked.args, asked.quarantine, &planned),
        )?,
        pool_log: turn.logs.join(results::POOL_LOG),
    })
}

/// A game run's turn under the heavy lock, its results folder cleared of the last run's: where its
/// run file goes, the folder of its logs and the file of lines the change touched, if it reads any.
struct Turn {
    _lock: HeavyLock,
    file: PathBuf,
    logs: PathBuf,
    touched: Option<PathBuf>,
}

/// Takes the heavy lock at `lock` for `holder`, clears the last run's results in `evidence` and
/// lays out this run's: a new folder for its logs and, when it reads them, the `touched` lines.
/// Whatever the run reads is written after the clear, so it never reads what the last run left.
fn begin_turn(lock: &Path, holder: &str, evidence: &Path, touched: Option<&str>) -> Result<Turn> {
    // The folders of the last runs' logs outlive the clear; `next_run_folder` keeps the newest.
    let held = take_turn(lock, holder, evidence, &[results::LOGS])?;
    fs::create_dir_all(evidence)?;
    let touched = touched
        .map(|lines| {
            let file = evidence.join("touched.txt");
            fs::write(&file, lines)
                .with_context(|| format!("cannot write {}", file.display()))
                .map(|()| file)
        })
        .transpose()?;
    Ok(Turn {
        _lock: held,
        file: evidence.join("test_run.json"),
        // The pool, Paper and every client log into a folder of this run's own.
        logs: next_run_folder(&evidence.join(results::LOGS))?,
        touched,
    })
}

/// One Gradle run of the game suite: where its run file belongs, how Gradle exited and where the
/// pool logs (in the run's own logs folder).
pub(crate) struct Ran {
    pub file: PathBuf,
    pub run_id: String,
    pub gradle: ExitStatus,
    pub pool_log: PathBuf,
}

/// Which Gradle of a game run: the one that builds the suite, or the one that runs it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum Step {
    Build,
    Test,
}

/// Builds the modules of `suite` in a Gradle of its own, then runs `run` with `gradle`. The build's
/// Gradle exits before the suite starts; where the run has a cgroup tree, the Kotlin daemon it
/// started ends with the build's leaf, and the test run compiles in its own Gradle, so no compiler
/// holds memory while the clients and Paper run. It never stops other daemons (`--stop`): another
/// worktree's build may share them.
pub(crate) fn build_then_run(
    mut gradle: impl FnMut(Step, &[String]) -> Result<ExitStatus>,
    suite: GameSuite,
    run: &[String],
) -> Result<ExitStatus> {
    let build = [
        "--console=plain".to_owned(),
        "--parallel".to_owned(),
        "--no-daemon".to_owned(),
        "gameTestBuild".to_owned(),
        format!("-Pplaytest.suite={}", suite.name()),
    ];
    let built = gradle(Step::Build, &build)?;
    if !built.success() {
        bail!(
            "game: building the game suite failed with {built}, so no requirement ran; Gradle's output above says why"
        );
    }
    let mut run = run.to_vec();
    run.push("-Pkotlin.compiler.execution.strategy=in-process".to_owned());
    gradle(Step::Test, &run)
}

/// One Gradle run of a game suite as xtask plans it: the suite, the requirements a demo run reruns
/// (none for the verdict run), its run id, where its run file and logs go, and the file of lines the
/// change touched (none for a demo run).
pub(crate) struct Planned<'a> {
    pub suite: GameSuite,
    pub demos: Option<&'a [String]>,
    pub run_id: &'a str,
    pub file: &'a Path,
    pub touched: Option<&'a Path>,
    pub logs: &'a Path,
}

/// What Gradle runs: every `gameTest` task of the planned suite, writing the run file and its logs
/// where `planned` says, with the file of lines the change touched. The verdict run takes the
/// selection, the repeat count and the quarantined requirements, which the test JVMs need since they
/// retry inside the run, and the paces a touched requirement runs at again; a demo run takes the
/// requirements it reruns, once each with clips.
pub(crate) fn gradle_args(
    args: &E2eArgs,
    quarantine: &Quarantine,
    planned: &Planned,
) -> Vec<String> {
    let mut gradle = vec![
        "--console=plain".to_owned(),
        "--parallel".to_owned(),
        "gameTest".to_owned(),
        format!("-Pplaytest.suite={}", planned.suite.name()),
        format!("-Pplaytest.runId={}", planned.run_id),
        format!("-Pplaytest.testRun={}", planned.file.display()),
        format!("-Pplaytest.logs={}", planned.logs.display()),
    ];
    if let Some(touched) = planned.touched {
        gradle.push(format!("-Pplaytest.touched={}", touched.display()));
    }
    let selection = planned.demos.unwrap_or(&args.only);
    for selected in selection {
        gradle.push("--tests".to_owned());
        gradle.push(test_pattern(selected));
    }
    if let Some(clients) = args.clients {
        gradle.push(format!("-Pplaytest.clients={clients}"));
    }
    if planned.demos.is_some() {
        gradle.push("-Pplaytest.demo=true".to_owned());
        return gradle;
    }
    gradle.push(format!("-Pplaytest.paces={PACES}"));
    if args.repeat.get() > 1 {
        gradle.push(format!("-Pplaytest.repeat={}", args.repeat));
    }
    let held = quarantine.held(&Runner::Game);
    if !held.is_empty() {
        gradle.push(format!("-Pplaytest.quarantine={}", held.join(",")));
    }
    gradle
}

/// The lines `change` added to services' Kotlin and Java sources, as the game requirements read
/// them (`playtest.touched`): one source per line, named as JaCoCo names it (`package/File.kt`),
/// then its added lines, separated by spaces.
pub(crate) fn touched_lines(change: &Change) -> String {
    change
        .files
        .iter()
        .filter(|file| file.path.starts_with("services") && !file.added.is_empty())
        .filter(|file| {
            file.path
                .extension()
                .is_some_and(|extension| extension == "kt" || extension == "java")
        })
        .filter_map(|file| {
            let path = file.path.to_string_lossy();
            let (_, source) = path
                .split_once("/kotlin/")
                .or_else(|| path.split_once("/java/"))?;
            let lines: Vec<String> = file.added.iter().map(u32::to_string).collect();
            Some(format!("{source} {}\n", lines.join(" ")))
        })
        .collect()
}

/// The testBalloon pattern that selects the test `selected` names: a test id (the requirement id
/// and its sentence) as it is, a requirement id with any sentence. `/` sets the pattern's element
/// separator, so the test's own name starts with the id.
fn test_pattern(selected: &str) -> String {
    if selected.contains(' ') {
        format!("/*/{selected}")
    } else {
        format!("/*/{selected} *")
    }
}

/// The run `ran` wrote. The build starts the run's pool before its first game test, and the pool
/// writes the run file as it takes up the run, so a run with no file never reached its pool. Fails,
/// pointing at the pool's log, when there is no run file, or the file holds another run.
pub(crate) fn own_run(ran: &Ran) -> Result<TestRun> {
    let log = ran.pool_log.display();
    if !ran.file.exists() {
        bail!(
            "game: the run wrote no run file at {}, so it proved nothing: no game test ran, so the build never started the pool, or the pool wrote nothing (Gradle exited with {}); see {log}",
            ran.file.display(),
            ran.gradle,
        );
    }
    let run = results::read(&ran.file)?;
    if run.run_id != ran.run_id {
        bail!(
            "game: {} holds the run {}, not this run {}, which wrote none (Gradle exited with {}); see {log}",
            ran.file.display(),
            run.run_id,
            ran.run_id,
            ran.gradle,
        );
    }
    Ok(run)
}

/// How many run folders `cargo xtask e2e game` keeps, the new one included.
const KEPT_RUNS: usize = 3;

/// A new, empty folder below `runs` for this run's logs, numbered one past the newest run folder
/// there; run folders beyond the last [`KEPT_RUNS`] go.
pub(crate) fn next_run_folder(runs: &Path) -> Result<PathBuf> {
    fs::create_dir_all(runs).with_context(|| format!("cannot create {}", runs.display()))?;
    let mut numbers: Vec<u64> = fs::read_dir(runs)?
        .filter_map(|entry| entry.ok()?.file_name().to_str()?.parse().ok())
        .collect();
    numbers.sort_unstable();
    let next = runs.join((numbers.last().copied().unwrap_or(0) + 1).to_string());
    let gone = numbers.len().saturating_sub(KEPT_RUNS - 1);
    for number in &numbers[..gone] {
        let old = runs.join(number.to_string());
        fs::remove_dir_all(&old).with_context(|| format!("cannot remove {}", old.display()))?;
    }
    fs::create_dir(&next).with_context(|| format!("cannot create {}", next.display()))?;
    Ok(next)
}

/// The suite's verdict on its `run`: whether it ran and ran to the end, each case under the run's
/// attempt policy and the quarantine, the selection, a run that ran no requirement, and a Gradle
/// failure that no failing case explains, such as a test JVM that ended before it ran its
/// requirements.
pub(crate) fn judge(
    run: &TestRun,
    gradle: ExitStatus,
    only: &[String],
    quarantine: &Quarantine,
    shown: &Path,
    out: &mut dyn Write,
) -> Result<()> {
    // A run cut short still lists the cases that finished, whose evidence stages.
    results::report(run, quarantine, Some(shown), out)?;
    results::selection_matches(run, only).map_err(|unmatched| anyhow!("game: {unmatched}"))?;
    if run.cases.is_empty() {
        bail!(
            "game: no requirements ran ({})",
            shown.join("test_run.json").display()
        );
    }
    if !gradle.success() {
        bail!(
            "game: every reported requirement passed, but Gradle failed with {gradle}; its output above says why"
        );
    }
    Ok(())
}

fn now_millis() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(0, |since| {
            i64::try_from(since.as_millis()).unwrap_or(i64::MAX)
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::results::TestCase;
    use crate::results::{AttemptPolicy, Outcome, RunEnd};
    use crate::test_support::{
        TempRoot, changed, e2e_args as parsed, exited, failed, files_below, game_run,
        gradle_selection as selection, interrupted, quarantining, refusal,
    };

    #[test]
    fn a_game_run_gets_a_folder_of_its_own_and_only_the_last_three_runs_keep_theirs() {
        let root = TempRoot::new();
        for run in [1, 9, 10] {
            root.write(&format!("logs/{run}/pool.log"), "log");
        }

        let folder = next_run_folder(&root.path("logs")).unwrap();

        assert_eq!(folder, root.path("logs/11"));
        assert!(folder.is_dir());
        assert_eq!(
            files_below(&root.path("logs")),
            ["10/pool.log", "9/pool.log"]
        );
    }

    #[test]
    fn a_run_with_no_run_file_fails_and_points_at_the_pool_s_log_even_when_gradle_passed() {
        let root = TempRoot::new();
        let error = refusal(own_run(&Ran {
            file: root.path("results/game/test_run.json"),
            run_id: "run-2".to_owned(),
            gradle: exited(0),
            pool_log: root.path("pool.log"),
        }));
        assert!(error.contains("wrote no run file"), "{error}");
        assert!(error.contains("no game test ran"), "{error}");
        assert!(error.contains("the pool wrote nothing"), "{error}");
        assert!(
            error.contains(&root.path("pool.log").display().to_string()),
            "{error}"
        );
    }

    #[test]
    fn a_run_whose_selection_matched_no_requirement_fails_by_the_selection() {
        let run = TestRun {
            run_id: "run-2".to_owned(),
            runner: Runner::Game,
            end: RunEnd::Completed,
            ..TestRun::default()
        };
        for (only, says) in [
            (
                vec!["NOPE-1".to_owned()],
                "game: --only NOPE-1 matched nothing",
            ),
            (vec![], "no requirements ran"),
        ] {
            let error = refusal(judge(
                &run,
                exited(0),
                &only,
                &Quarantine::default(),
                Path::new("results/game"),
                &mut Vec::new(),
            ));
            assert!(error.contains(says), "{only:?}: {error}");
        }
    }

    #[test]
    fn a_run_file_another_run_wrote_fails_the_game_run_even_when_it_started_later() {
        let root = TempRoot::new();
        let file = root.path("results/game/test_run.json");
        let other = TestRun {
            run_id: "run-1".to_owned(),
            started_at_millis: 9_000,
            ..game_run(
                AttemptPolicy::RerunFailures(4),
                &[("PROBE-1", &[Outcome::Passed])],
            )
        };
        results::write(&other, &file).unwrap();
        let error = refusal(own_run(&Ran {
            file: file.clone(),
            run_id: "run-2".to_owned(),
            gradle: exited(0),
            pool_log: root.path("pool.log"),
        }));
        assert!(error.contains("run run-1, not this run run-2"), "{error}");
        assert!(error.contains(&file.display().to_string()), "{error}");
        assert!(
            error.contains(&root.path("pool.log").display().to_string()),
            "{error}"
        );
    }

    #[test]
    fn the_run_file_of_this_run_s_id_is_its_run_even_when_a_pool_began_it_before_xtask_counted() {
        let root = TempRoot::new();
        let file = root.path("results/game/test_run.json");
        let written = TestRun {
            run_id: "run-2".to_owned(),
            started_at_millis: 1_000,
            ..game_run(
                AttemptPolicy::RerunFailures(4),
                &[("PROBE-1", &[Outcome::Passed])],
            )
        };
        results::write(&written, &file).unwrap();
        let read = own_run(&Ran {
            file,
            run_id: "run-2".to_owned(),
            gradle: exited(0),
            pool_log: root.path("pool.log"),
        })
        .unwrap();
        assert_eq!(read, written);
    }

    #[test]
    fn a_run_the_game_could_not_run_fails_with_why_rather_than_as_a_run_of_nothing() {
        let unable = TestRun {
            end: RunEnd::CouldNotRun(
                "the game was not ready within 300 s; see paper.log".to_owned(),
            ),
            ..game_run(AttemptPolicy::RerunFailures(4), &[])
        };

        let error = refusal(judge(
            &unable,
            exited(1),
            &["PROBE-1".to_owned()],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));

        assert_eq!(
            error,
            "the run could not run: the game was not ready within 300 s; see paper.log"
        );
    }

    #[test]
    fn a_game_requirement_that_passed_on_a_retry_is_flaky_and_gates() {
        let flaky = game_run(
            AttemptPolicy::RerunFailures(4),
            &[
                ("PROBE-1", &[Outcome::Passed]),
                ("FLAKY-1", &[failed("missed"), Outcome::Passed]),
            ],
        );
        let error = refusal(judge(
            &flaky,
            exited(1),
            &[],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));
        assert!(
            error.contains("1 of 2 cases are flaky: FLAKY-1 the requirement"),
            "{error}"
        );
    }

    #[test]
    fn a_quarantined_game_requirement_that_failed_does_not_gate() {
        let held = game_run(
            AttemptPolicy::RerunFailures(4),
            &[
                ("PROBE-1", &[Outcome::Passed]),
                ("LEAK-1", &[failed("leaked")]),
            ],
        );
        let mut out = Vec::new();
        let judged = judge(
            &held,
            exited(0),
            &[],
            &quarantining("game/LEAK-1"),
            Path::new("results/game"),
            &mut out,
        );
        assert!(judged.is_ok(), "{judged:?}");
        let out = String::from_utf8(out).unwrap();
        assert!(out.contains("LEAK-1 the requirement: quarantined"), "{out}");
    }

    #[test]
    fn a_game_run_whose_cases_pass_while_gradle_failed_fails() {
        let passing = game_run(
            AttemptPolicy::RerunFailures(4),
            &[("PROBE-1", &[Outcome::Passed])],
        );
        let error = refusal(judge(
            &passing,
            exited(1),
            &[],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));
        assert!(error.contains("Gradle failed"), "{error}");
    }

    #[test]
    fn a_run_the_pool_never_ended_fails_as_cut_short_after_its_finished_cases() {
        let finished = TestRun {
            end: RunEnd::CutShort,
            logs: "logs/4".to_owned(),
            ..game_run(
                AttemptPolicy::RerunFailures(4),
                &[
                    ("PROBE-1", &[Outcome::Passed]),
                    ("WINDOW-1", &[Outcome::Passed]),
                ],
            )
        };

        let error = refusal(judge(
            &finished,
            exited(1),
            &[],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));

        assert!(error.contains("cut short after 2 cases"), "{error}");
        assert!(error.contains("logs in results/game/logs/4/"), "{error}");
    }

    #[test]
    fn a_game_selection_that_names_no_requirement_fails() {
        let passing = game_run(
            AttemptPolicy::Exactly(2),
            &[("PROBE-1", &[Outcome::Passed, Outcome::Passed])],
        );
        let error = refusal(judge(
            &passing,
            exited(0),
            &["PROBE-1".to_owned(), "PROBE-9".to_owned()],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));
        assert_eq!(
            error,
            "game: --only PROBE-9 matched nothing: no requirement or case has that id"
        );
    }

    #[test]
    fn gradle_gets_the_suite_the_run_id_the_run_file_the_logs_folder_the_selection_the_repeat_the_quarantine_the_paces_and_the_clients()
     {
        let file = Path::new("/repo/.xtask/results/game/test_run.json");
        let args = parsed(&[
            "game",
            "--only",
            "WINDOW-1,HUNG-1 work still running fails",
            "--repeat",
            "3",
            "--clients",
            "1",
        ])
        .unwrap();
        let touched = Path::new("/repo/.xtask/results/game/touched.txt");
        let logs = Path::new("/repo/.xtask/results/game/logs/4");
        let verdict = |args: &E2eArgs, quarantine: &Quarantine| {
            gradle_args(
                args,
                quarantine,
                &Planned {
                    suite: GameSuite::Game,
                    demos: None,
                    run_id: "run-7",
                    file,
                    touched: Some(touched),
                    logs,
                },
            )
        };
        let gradle = verdict(&args, &quarantining("game/LEAK-1"));
        for expected in [
            "gameTest",
            "-Pplaytest.suite=game",
            "-Pplaytest.runId=run-7",
            "-Pplaytest.testRun=/repo/.xtask/results/game/test_run.json",
            "-Pplaytest.touched=/repo/.xtask/results/game/touched.txt",
            "-Pplaytest.logs=/repo/.xtask/results/game/logs/4",
            "-Pplaytest.repeat=3",
            "-Pplaytest.quarantine=LEAK-1",
            "-Pplaytest.paces=5,50",
            "-Pplaytest.clients=1",
        ] {
            assert!(
                gradle.contains(&expected.to_owned()),
                "{expected} in {gradle:?}"
            );
        }
        assert!(
            !gradle.iter().any(|arg| arg.starts_with("-Pplaytest.demo")),
            "{gradle:?}"
        );
        // testBalloon selects a test whose name is the id and its sentence, or the whole test id.
        assert_eq!(
            selection(&gradle),
            ["/*/WINDOW-1 *", "/*/HUNG-1 work still running fails"]
        );
        let plain = verdict(&parsed(&["game"]).unwrap(), &Quarantine::default());
        assert!(
            !plain.iter().any(|arg| arg == "--tests"
                || ["repeat", "quarantine", "clients"]
                    .iter()
                    .any(|name| arg.starts_with(&format!("-Pplaytest.{name}=")))),
            "{plain:?}"
        );
    }

    #[test]
    fn a_demo_run_reruns_only_the_requirements_it_names_once_with_clips_at_no_pace() {
        let args = parsed(&["playtest", "--demos", "--only", "WINDOW-1", "--repeat", "3"]).unwrap();
        let demos = ["TOAST-1".to_owned(), "QUIT-2".to_owned()];

        let gradle = gradle_args(
            &args,
            &quarantining("game/LEAK-1"),
            &Planned {
                suite: GameSuite::Playtest,
                demos: Some(&demos),
                run_id: "run-8",
                file: Path::new("/repo/.xtask/results/playtest-demos/test_run.json"),
                touched: None,
                logs: Path::new("/repo/.xtask/results/playtest-demos/logs/1"),
            },
        );

        assert!(
            gradle.contains(&"-Pplaytest.suite=playtest".to_owned()),
            "{gradle:?}"
        );
        assert!(
            gradle.contains(&"-Pplaytest.demo=true".to_owned()),
            "{gradle:?}"
        );
        assert_eq!(selection(&gradle), ["/*/TOAST-1 *", "/*/QUIT-2 *"]);
        assert!(
            !gradle
                .iter()
                .any(|arg| ["repeat", "quarantine", "paces", "touched"]
                    .iter()
                    .any(|name| arg.starts_with(&format!("-Pplaytest.{name}=")))),
            "{gradle:?}"
        );
    }

    #[test]
    fn a_demo_run_reruns_each_requirement_that_failed_was_flaky_quarantined_or_touched_once() {
        let mut run = game_run(
            AttemptPolicy::RerunFailures(4),
            &[
                ("PASS-1", &[Outcome::Passed]),
                ("FAIL-1", &[failed("missed"), failed("missed")]),
                ("FLAKY-1", &[failed("missed"), Outcome::Passed]),
                ("HELD-1", &[failed("missed")]),
                ("TOUCHED-1", &[Outcome::Passed]),
                ("LOST-1", &[interrupted("paper")]),
            ],
        );
        run.cases[4].touched = true;
        let side_by_side = TestCase {
            id: "FAIL-1 the requirement (attempt 2 of 2)".to_owned(),
            ..run.cases[1].clone()
        };
        run.cases.push(side_by_side);

        assert_eq!(
            demo_selection(&run, &quarantining("game/HELD-1")).unwrap(),
            ["FAIL-1", "FLAKY-1", "HELD-1", "TOUCHED-1"]
        );
    }

    #[test]
    fn the_framework_suite_and_a_demo_run_parse_beside_the_product_suite() {
        assert!(parsed(&["playtest"]).is_ok());
        assert!(parsed(&["playtest", "--demos"]).unwrap().demos);
        assert!(!parsed(&["game"]).unwrap().demos);
    }

    #[test]
    fn the_touched_lines_count_from_the_base_the_run_names_or_else_the_nearest_one() {
        assert_eq!(
            parsed(&["game", "--base", "4e61bf097"])
                .unwrap()
                .base
                .as_deref(),
            Some("4e61bf097")
        );
        assert_eq!(parsed(&["game"]).unwrap().base, None);
    }

    #[test]
    fn a_game_run_clears_the_last_results_but_keeps_the_log_folders_of_earlier_runs() {
        let root = TempRoot::new();
        let (lock, evidence) = (root.path("heavy.lock"), root.path("results/game"));

        for _ in 0..2 {
            let turn = take_turn(&lock, "e2e game", &evidence, &[results::LOGS]).unwrap();
            fs::create_dir_all(&evidence).unwrap();
            fs::write(evidence.join("test_run.json"), "{}").unwrap();
            next_run_folder(&evidence.join(results::LOGS)).unwrap();
            drop(turn);
        }
        take_turn(&lock, "e2e game", &evidence, &[results::LOGS])
            .map(drop)
            .unwrap();

        assert!(evidence.join("logs/1").is_dir() && evidence.join("logs/2").is_dir());
        assert_eq!(
            files_below(&evidence),
            Vec::<String>::new(),
            "only the log folders survive"
        );
    }

    #[test]
    fn a_verdict_run_reads_the_lines_this_change_touched_not_the_last_runs_and_a_demo_run_reads_none()
     {
        let root = TempRoot::new();
        let (lock, evidence) = (root.path("heavy.lock"), root.path("results/playtest"));
        fs::create_dir_all(&evidence).unwrap();
        fs::write(evidence.join("touched.txt"), "Old.kt 1\n").unwrap();

        let verdict = begin_turn(&lock, "e2e playtest", &evidence, Some("New.kt 7\n")).unwrap();
        let touched = verdict
            .touched
            .clone()
            .expect("a verdict run reads touched lines");
        drop(verdict);
        let demo = begin_turn(
            &lock,
            "e2e playtest",
            &root.path("results/playtest-demos"),
            None,
        )
        .unwrap();

        assert_eq!(fs::read_to_string(touched).unwrap(), "New.kt 7\n");
        assert_eq!(demo.touched, None);
    }

    #[test]
    fn the_suite_is_built_in_a_gradle_of_its_own_that_ends_before_the_suite_starts() {
        let suite = vec!["gameTest".to_owned()];
        let mut calls = Vec::new();

        let status = build_then_run(
            |step: Step, gradle: &[String]| {
                calls.push((step, gradle.to_vec()));
                Ok(exited(0))
            },
            GameSuite::Playtest,
            &suite,
        )
        .unwrap();

        assert!(status.success());
        let steps: Vec<_> = calls.iter().map(|(step, _)| *step).collect();
        assert_eq!(steps, [Step::Build, Step::Test]);
        let (build, run) = (&calls[0].1, &calls[1].1);
        assert!(build.contains(&"gameTestBuild".to_owned()), "{build:?}");
        // The build builds only the suite's modules: the product's need the stack to configure.
        assert!(
            build.contains(&"-Pplaytest.suite=playtest".to_owned()),
            "{build:?}"
        );
        assert!(build.contains(&"--no-daemon".to_owned()), "{build:?}");
        // Another worktree's Gradle may share the daemons, so the build never stops them.
        assert!(!build.contains(&"--stop".to_owned()), "{build:?}");
        // Whatever the test run still compiles, it compiles in its own Gradle, starting no Kotlin
        // daemon beside the game.
        assert_eq!(
            run,
            &[
                "gameTest".to_owned(),
                "-Pkotlin.compiler.execution.strategy=in-process".to_owned()
            ]
        );
    }

    #[test]
    fn a_suite_that_fails_to_build_runs_no_requirement() {
        let mut steps = Vec::new();

        let error = build_then_run(
            |step: Step, _: &[String]| {
                steps.push(step);
                Ok(exited(1))
            },
            GameSuite::Game,
            &["gameTest".to_owned()],
        )
        .unwrap_err()
        .to_string();

        assert_eq!(steps, [Step::Build]);
        assert!(error.contains("building the game suite failed"), "{error}");
        assert!(error.contains("no requirement ran"), "{error}");
    }

    #[test]
    fn touched_lines_name_each_changed_services_source_as_jacoco_does_with_its_added_lines() {
        let change = Change {
            base: "0".repeat(40),
            files: vec![
                changed(
                    "services/playtest/plugin/src/main/java/com/typewritermc/playtest/plugin/Probes.java",
                    &[12, 40],
                ),
                changed(
                    "services/playtest/framework/src/main/kotlin/com/typewritermc/playtest/Window.kt",
                    &[3],
                ),
                changed("services/playtest/plugin/build.gradle.kts", &[5]),
                changed("panel/lib/main.dart", &[1]),
                changed(
                    "services/playtest/plugin/src/main/java/com/typewritermc/playtest/plugin/Gone.java",
                    &[],
                ),
            ],
        };

        assert_eq!(
            touched_lines(&change),
            "com/typewritermc/playtest/plugin/Probes.java 12 40\n\
             com/typewritermc/playtest/Window.kt 3\n"
        );
    }
}
