//! The results contract every runner writes (`skir-src/harness/v1/test_run.skir`) and the one
//! attempt policy for every suite. [`attempts`] records every attempt of a case; [`verdict`]
//! reads them under the run's policy. Under `RerunFailures` a failed case runs again until it
//! passes, and passing after a failure makes it flaky, which gates like a failure: the rerun tells
//! a test that fails sometimes from one that always fails, and only a test that always passes is
//! trusted. Under `Exactly` any failed attempt fails the case. A case listed in [`QUARANTINE`] still runs and is reported but
//! does not gate; each entry names a case by its id or by its requirement, a reason and an issue,
//! and every report lists the quarantined cases so they cannot be forgotten.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, bail};
use serde::Deserialize;

use crate::Context;
use crate::skirout::base::harness::v1::test_run::Runner;
pub use crate::skirout::base::harness::v1::test_run::{
    Artifact, ArtifactKind, Attempt, AttemptPolicy, Conclusion, Failure, LossCause, MemoryKill,
    Outcome, Pacing, Part, PartEnd, PartKind, PartLoss, RunEnd, RunLost, TestCase, TestRun,
};

/// The quarantine file, relative to the repository root.
const QUARANTINE: &str = "harness/quarantine.toml";

/// The cases that run and report but do not gate.
#[derive(Default, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Quarantine {
    #[serde(default, rename = "case")]
    cases: Vec<QuarantinedCase>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct QuarantinedCase {
    /// `<runner>/<case id>`, for example `components/service::service_identity::rotates_keys`.
    id: String,
    reason: String,
    issue: u32,
}

impl Quarantine {
    pub fn load(ctx: &Context) -> Result<Self> {
        let path = ctx.root.join(QUARANTINE);
        let text =
            fs::read_to_string(&path).with_context(|| format!("cannot read {}", path.display()))?;
        toml::from_str(&text).with_context(|| format!("{} is invalid", path.display()))
    }

    /// The cases of `runner` the quarantine holds, as their entries name them: a case id or a
    /// requirement. A runner that retries inside its own run, such as the game pool, gets these.
    pub fn held(&self, runner: &Runner) -> Vec<&str> {
        let prefix = format!("{}/", runner_name(runner));
        self.cases
            .iter()
            .filter_map(|entry| entry.id.strip_prefix(&prefix))
            .collect()
    }

    /// The entry that holds `case` of `runner`: one naming its id, or the requirement it
    /// demonstrates, which holds every case of that requirement.
    fn entry(&self, runner: &Runner, case: &TestCase) -> Option<&QuarantinedCase> {
        let prefix = format!("{}/", runner_name(runner));
        self.cases.iter().find(|entry| {
            entry
                .id
                .strip_prefix(&prefix)
                .is_some_and(|name| name == case.id || case.requirement.as_deref() == Some(name))
        })
    }
}

/// What a case's attempts prove under its run's attempt policy and the quarantine.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Verdict {
    Passed,
    /// Failed, then passed when run again under `RerunFailures`: gates like a failure, and says the
    /// test fails only sometimes.
    Flaky,
    Failed,
    /// Listed in the quarantine: reported, not gating.
    Quarantined,
    /// Its last attempt was interrupted: a lost part stopped the run while it ran.
    Interrupted,
    /// A window held at another tick in another passing run of the case.
    Unsteady,
}

/// The one policy every reader applies to a case of `run`. An attempt whose outcome this build
/// does not know proves nothing, so it counts as a failure. An interrupted attempt counts neither
/// way, and a case whose last attempt was interrupted has no verdict of its own: the run's trouble
/// names the part whose loss interrupted it. A case its runner concluded has that conclusion
/// ([`concluded`]); the game runner's test JVM alone compares the ticks its windows held at.
pub fn verdict(run: &TestRun, case: &TestCase, quarantine: &Quarantine) -> Result<Verdict> {
    let Some(last) = case.attempts.last() else {
        bail!("{} has no attempts", case.id);
    };
    if matches!(last.outcome, Outcome::Interrupted(_)) {
        return Ok(Verdict::Interrupted);
    }
    if let Some(conclusion) = &case.conclusion {
        return Ok(concluded(case, conclusion));
    }
    let failed = failed_attempts(case).count();
    let passed_last = matches!(last.outcome, Outcome::Passed);
    Ok(
        match (
            failed,
            quarantine.entry(&run.runner, case),
            &run.attempt_policy,
        ) {
            (0, _, _) => Verdict::Passed,
            (_, Some(_), _) => Verdict::Quarantined,
            (_, None, AttemptPolicy::RerunFailures(_)) if passed_last => Verdict::Flaky,
            _ => Verdict::Failed,
        },
    )
}

/// The verdict of a case its runner `conclusion` judged: an unsteady case blocks unless its pacing
/// only reports, so a pacing this build does not know blocks too, and a conclusion this build does
/// not know proves nothing.
fn concluded(case: &TestCase, conclusion: &Conclusion) -> Verdict {
    match conclusion {
        Conclusion::Passed => Verdict::Passed,
        Conclusion::Flaky => Verdict::Flaky,
        Conclusion::Failed => Verdict::Failed,
        Conclusion::Quarantined => Verdict::Quarantined,
        Conclusion::Unsteady(_) if matches!(case.pacing, Pacing::Reports) => Verdict::Passed,
        Conclusion::Unsteady(_) => Verdict::Unsteady,
        Conclusion::Unknown(_) => Verdict::Failed,
    }
}

/// How the windows of an unsteady `case` held in each of its passing runs, as its runner described
/// them; `None` unless its runner concluded it unsteady.
pub fn unsteady(case: &TestCase) -> Option<&str> {
    match &case.conclusion {
        Some(Conclusion::Unsteady(runs)) => Some(runs),
        _ => None,
    }
}

/// Why `run` as a whole proves less than its cases say, judged once for every suite and the pull
/// request's evidence: it could not run at all, it stopped before it was over, or a part every case
/// depended on was lost, so cases it never reached are missing from it. An end this xtask does not
/// know proves nothing either.
pub fn run_trouble(run: &TestRun) -> Option<String> {
    match &run.end {
        RunEnd::Completed => None,
        RunEnd::CouldNotRun(why) => Some(format!("could not run: {why}")),
        RunEnd::CutShort => Some(format!(
            "was cut short after {} cases, so the cases after them never ran",
            run.cases.len()
        )),
        RunEnd::Lost(stopped) => Some(lost_part(run, stopped)),
        RunEnd::Unknown(_) => Some("ended in a way this xtask does not know".to_owned()),
    }
}

/// The one verdict of a run that `stopped` when a part was lost: the part, why it was lost, the
/// attempts its loss interrupted and the cases that never ran.
fn lost_part(run: &TestRun, stopped: &RunLost) -> String {
    let part = run.parts.iter().find(|part| part.name == stopped.part);
    let kind = match part.map(|part| &part.kind) {
        Some(PartKind::SharedPaper) => "the shared Paper",
        Some(PartKind::OwnPaper) => "the own Paper",
        Some(PartKind::Client) => "the client",
        Some(PartKind::Display) => "the display",
        Some(PartKind::Pool) => "the pool",
        Some(PartKind::StackService) => "the stack service",
        Some(PartKind::Gradle) => "Gradle",
        _ => "the part",
    };
    let cause = match part.map(|part| &part.end) {
        Some(PartEnd::Lost(loss)) => format!(", {}", loss_cause(&loss.cause)),
        _ => String::new(),
    };
    let interrupted: Vec<&str> = run
        .cases
        .iter()
        .filter(|case| {
            case.attempts.iter().any(|attempt| {
                matches!(&attempt.outcome, Outcome::Interrupted(by) if by.part == stopped.part)
            })
        })
        .map(|case| case.id.as_str())
        .collect();
    let attempts = run
        .cases
        .iter()
        .flat_map(|case| &case.attempts)
        .filter(|attempt| {
            matches!(&attempt.outcome, Outcome::Interrupted(by) if by.part == stopped.part)
        })
        .count();
    let mut text = format!("stopped: {kind} {} was lost{cause}", stopped.part);
    let interrupted = match attempts {
        0 => None,
        1 => Some(format!(
            "1 attempt was interrupted ({})",
            interrupted.join(", ")
        )),
        n => Some(format!(
            "{n} attempts were interrupted ({})",
            interrupted.join(", ")
        )),
    };
    let never_ran = match stopped.not_run.len() {
        0 => None,
        1 => Some(format!("1 case never ran ({})", stopped.not_run.join(", "))),
        n => Some(format!(
            "{n} cases never ran ({})",
            stopped.not_run.join(", ")
        )),
    };
    match (interrupted, never_ran) {
        (Some(interrupted), Some(never_ran)) => {
            text.push_str(&format!("; {interrupted} and {never_ran}"));
        }
        (Some(one), None) | (None, Some(one)) => text.push_str(&format!("; {one}")),
        (None, None) => {}
    }
    text
}

/// What happened to a part lost for `cause`, as a clause.
pub fn loss_cause(cause: &LossCause) -> String {
    match cause {
        LossCause::Exited(status) if *status > 128 => {
            format!("it exited with status {status} (signal {})", status - 128)
        }
        LossCause::Exited(status) => format!("it exited with status {status}"),
        LossCause::Left(reason) => format!("it left: {reason}"),
        LossCause::LeftPaper(reason) => format!("its player left Paper: {reason}"),
        LossCause::Dropped(reason) => {
            format!("it lost its Paper without being told to leave: {reason}")
        }
        LossCause::Stalled => "it stopped answering".to_owned(),
        LossCause::NeverReady => "it never became ready".to_owned(),
        LossCause::Broke(reason) => format!("it could no longer serve attempts: {reason}"),
        LossCause::KilledForMemory(kill) => match kill.as_ref() {
            MemoryKill::MachineOutOfMemory => {
                "the kernel killed it, as the machine ran out of memory".to_owned()
            }
            MemoryKill::OwnLimit => {
                "the kernel killed it for taking all the memory its cgroup allows".to_owned()
            }
            MemoryKill::GameBudget => {
                "the kernel killed it, as the game's parts together took all the game's budget"
                    .to_owned()
            }
            MemoryKill::Unknown(_) => {
                "the kernel killed it for memory, for a reason this xtask does not know".to_owned()
            }
        },
        LossCause::Unknown(_) => "for a reason this xtask does not know".to_owned(),
    }
}

/// Where the logs that explain `run`'s trouble lie below `evidence`: the lost part's own log when
/// the run stopped for a lost part that keeps one, else the run's logs folder.
fn trouble_logs(run: &TestRun, evidence: Option<&Path>) -> String {
    let Some(evidence) = evidence else {
        return String::new();
    };
    if run.logs.is_empty() {
        return String::new();
    }
    let logs = evidence.join(&run.logs);
    let lost_log = match &run.end {
        RunEnd::Lost(stopped) => run
            .parts
            .iter()
            .find(|part| part.name == stopped.part && !part.log.is_empty())
            .map(|part| logs.join(&part.log)),
        _ => None,
    };
    match lost_log {
        Some(log) => format!("; its log is {}", log.display()),
        None => format!("; logs in {}/", logs.display()),
    }
}

/// The failure of `case`'s last failed attempt, when that attempt says how it failed.
pub fn last_failure(case: &TestCase) -> Option<&Failure> {
    case.attempts
        .iter()
        .rev()
        .find_map(|attempt| match &attempt.outcome {
            Outcome::Failed(failure) => Some(&**failure),
            _ => None,
        })
}

/// Every artifact of every attempt of `case`, in attempt order, with its path relative to the
/// run file's folder (the attempt's folder joined with the artifact's path).
pub fn artifacts(case: &TestCase) -> impl Iterator<Item = (PathBuf, &Artifact)> {
    case.attempts.iter().flat_map(|attempt| {
        attempt.artifacts.iter().map(move |artifact| {
            let path = match attempt_folder(attempt) {
                Some(folder) => folder.join(&artifact.path),
                None => PathBuf::from(&artifact.path),
            };
            (path, artifact)
        })
    })
}

/// Where `attempt`'s evidence lies below the run file's folder; `None` when it lies in that
/// folder itself, which the `TestRun` field states as an empty string.
pub fn attempt_folder(attempt: &Attempt) -> Option<&Path> {
    (!attempt.folder.is_empty()).then(|| Path::new(&attempt.folder))
}

impl ArtifactKind {
    /// Whether an artifact of this kind is proof for review that `cargo xtask evidence stage`
    /// makes public. Logs and spans stay on the machine, so no token they print can leak through a
    /// scrub rule that missed it.
    pub fn published(&self) -> bool {
        matches!(self, Self::Clip | Self::Screenshot)
    }
}

/// The 1 based numbers of `case`'s attempts that failed; an interrupted attempt neither passed nor
/// failed.
fn failed_attempts(case: &TestCase) -> impl Iterator<Item = usize> + '_ {
    case.attempts
        .iter()
        .enumerate()
        .filter(|(_, attempt)| {
            !matches!(attempt.outcome, Outcome::Passed | Outcome::Interrupted(_))
        })
        .map(|(index, _)| index + 1)
}

/// Runs attempt 1 of `selection`, then further attempts per `policy`, and folds every attempt
/// into one `TestRun` carrying the policy. `run(n, ids)` runs attempt n of `ids` (an empty list
/// runs everything) and reports one attempt per case. Under `RerunFailures` only failed, non
/// quarantined cases run again, and only until they pass; under `Exactly` the whole selection
/// runs every time. A case a later attempt does not report gets a failed attempt saying so. Fails
/// when a selected id matched no case's id or requirement.
pub fn attempts(
    policy: AttemptPolicy,
    selection: &[String],
    quarantine: &Quarantine,
    mut run: impl FnMut(u32, &[String]) -> Result<TestRun>,
) -> Result<TestRun> {
    let limit = match policy {
        AttemptPolicy::RerunFailures(limit) | AttemptPolicy::Exactly(limit) => limit,
        AttemptPolicy::Unknown(_) => bail!("an unknown attempt policy cannot be run"),
    };
    let limit = u32::try_from(limit)
        .ok()
        .filter(|limit| *limit > 0)
        .context("an attempt policy needs at least one attempt")?;
    let first = run(1, selection)?;
    selection_matches(&first, selection)?;
    let mut folded = TestRun {
        attempt_policy: policy.clone(),
        ..first
    };
    for n in 2..=limit {
        let again: Vec<String> = match policy {
            AttemptPolicy::Exactly(_) => folded.cases.iter().map(|case| case.id.clone()).collect(),
            _ => folded
                .cases
                .iter()
                .filter(|case| {
                    case.attempts
                        .last()
                        .is_some_and(|last| !matches!(last.outcome, Outcome::Passed))
                        && quarantine.entry(&folded.runner, case).is_none()
                })
                .map(|case| case.id.clone())
                .collect(),
        };
        if again.is_empty() {
            break;
        }
        let ids = match policy {
            AttemptPolicy::Exactly(_) => selection,
            _ => &again,
        };
        let mut next = run(n, ids)?;
        for case in folded
            .cases
            .iter_mut()
            .filter(|case| again.contains(&case.id))
        {
            let reported = next
                .cases
                .iter()
                .position(|reported| reported.id == case.id)
                .map(|index| next.cases.swap_remove(index));
            match reported {
                Some(reported) => case.attempts.extend(reported.attempts),
                None => case.attempts.push(Attempt {
                    outcome: Outcome::Failed(Box::new(Failure {
                        message: format!("attempt {n} reported no result for this case"),
                        ..Failure::default()
                    })),
                    ..Attempt::default()
                }),
            }
        }
    }
    Ok(folded)
}

/// Fails when an id of `selection`, the run's `--only`, names no case of `run`.
pub fn selection_matches(run: &TestRun, selection: &[String]) -> Result<()> {
    let unmatched: Vec<&str> = selection
        .iter()
        .filter(|id| {
            !run.cases
                .iter()
                .any(|case| case.id == **id || case.requirement.as_ref() == Some(*id))
        })
        .map(String::as_str)
        .collect();
    if !unmatched.is_empty() {
        bail!(
            "--only {} matched nothing: no requirement or case has that id",
            unmatched.join(", ")
        );
    }
    Ok(())
}

/// Reads the `TestRun` at `path`.
pub fn read(path: &Path) -> Result<TestRun> {
    let text =
        fs::read_to_string(path).with_context(|| format!("cannot read {}", path.display()))?;
    TestRun::serializer()
        .from_json(&text, skir_client::UnrecognizedValues::Drop)
        .map_err(|error| anyhow::anyhow!("{} is not a TestRun: {error:?}", path.display()))
}

/// The folder of a run's attempts, one `attempts/<n>/` each, below the run file's folder.
pub const ATTEMPTS: &str = "attempts";

/// Folders inside a run's folder that hold its evidence, never another run, so a drive's own
/// `test_run.json` below `attempts/` is read only through the suite's run.
pub const RUN_EVIDENCE: [&str; 4] = [ATTEMPTS, "failures", "screenshots", LOGS];

/// The folder of a run's logs below the run file's folder; the game runner keeps one `logs/<n>/`
/// per run.
pub const LOGS: &str = "logs";

/// The log the game pool writes in a run's logs folder: the framework's own lines (attempts, boots,
/// lost clients), never Paper's or a client's output.
pub const POOL_LOG: &str = "pool.log";

/// Whether `name`, a file in a run's logs folder, is a log `cargo xtask evidence stage` makes public
/// for a run that did not pass: the pool's own ([`POOL_LOG`]) and each Paper's, with the engine's
/// lines in it (`paper.log` for the shared Paper, `paper-a<n>.log` for a restart attempt's own, as
/// services/playtest/pool Game.kt names them). The clients' and displays' logs stay on the machine.
pub fn public_log(name: &str) -> bool {
    name == POOL_LOG
        || name
            .strip_prefix("paper")
            .and_then(|rest| rest.strip_suffix(".log"))
            .is_some_and(|attempt| attempt.is_empty() || attempt.starts_with("-a"))
}

/// Every `TestRun` under `dir`, at any depth, with the path it was read from, skipping run
/// evidence folders.
pub fn read_all(dir: &Path) -> Result<Vec<(PathBuf, TestRun)>> {
    let mut runs = Vec::new();
    let mut pending = vec![dir.to_path_buf()];
    while let Some(dir) = pending.pop() {
        let Ok(entries) = fs::read_dir(&dir) else {
            continue;
        };
        for entry in entries {
            let path = entry?.path();
            if path.is_dir() {
                if !RUN_EVIDENCE.iter().any(|name| path.ends_with(name)) {
                    pending.push(path);
                }
            } else if path
                .extension()
                .is_some_and(|extension| extension == "json")
            {
                let run = read(&path)?;
                runs.push((path, run));
            }
        }
    }
    runs.sort_by(|a, b| a.0.cmp(&b.0));
    Ok(runs)
}

/// Writes `run` as readable JSON.
pub fn write(run: &TestRun, path: &Path) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("cannot create {}", parent.display()))?;
    }
    let json = TestRun::serializer().to_json(run, skir_client::JsonFlavor::Readable);
    fs::write(path, json).with_context(|| format!("cannot write {}", path.display()))
}

/// Lists every case whose verdict is not a plain pass, every unsteady case, and every case when the
/// run repeated each case, then fails when the run proves less than its cases ([`run_trouble`]),
/// or any case failed, is flaky or is unsteady where its pacing gates. A case a lost part
/// interrupted prints nothing of its own: the run's trouble names it. `evidence`, the run's folder,
/// points each failing case at the evidence of its first failed attempt and at the run's logs.
pub fn report(
    run: &TestRun,
    quarantine: &Quarantine,
    evidence: Option<&Path>,
    out: &mut dyn Write,
) -> Result<()> {
    let repeated = matches!(run.attempt_policy, AttemptPolicy::Exactly(n) if n > 1);
    let mut failed = Vec::new();
    let mut flaky = Vec::new();
    let mut unsteady_cases = Vec::new();
    for case in &run.cases {
        let Ok(verdict) = verdict(run, case, quarantine) else {
            writeln!(out, "{}: failed, no attempts recorded", case.id)?;
            failed.push(case.id.as_str());
            continue;
        };
        let failures: Vec<usize> = failed_attempts(case).collect();
        let attempts = format!(
            "{} of {} attempts ({})",
            failures.len(),
            case.attempts.len(),
            failures
                .iter()
                .map(usize::to_string)
                .collect::<Vec<_>>()
                .join(", ")
        );
        let see_of = |attempt: Option<&Attempt>| match (evidence, attempt) {
            (Some(evidence), Some(attempt)) => match attempt_folder(attempt) {
                Some(folder) => format!("; see {}/", evidence.join(folder).display()),
                None => format!("; see {}/", evidence.display()),
            },
            _ => String::new(),
        };
        let logs = match evidence {
            Some(evidence) if !run.logs.is_empty() => {
                format!("; logs in {}/", evidence.join(&run.logs).display())
            }
            _ => String::new(),
        };
        let see = see_of(failures.first().map(|first| &case.attempts[first - 1])) + &logs;
        match verdict {
            Verdict::Passed if repeated => writeln!(
                out,
                "{}: passed {} of {} attempts",
                case.id,
                case.attempts.len(),
                case.attempts.len()
            )?,
            Verdict::Passed => {
                if let Some(runs) = unsteady(case) {
                    writeln!(
                        out,
                        "{}: unsteady, {UNSTEADY}: {runs} (reported, not blocking)",
                        case.id
                    )?;
                }
            }
            Verdict::Unsteady => {
                match unsteady(case) {
                    Some(runs) => writeln!(out, "{}: unsteady, {UNSTEADY}: {runs}", case.id)?,
                    None => writeln!(out, "{}: unsteady, {UNSTEADY}", case.id)?,
                }
                unsteady_cases.push(case.id.as_str());
            }
            Verdict::Failed => {
                writeln!(out, "{}: failed {attempts}{see}", case.id)?;
                failed.push(case.id.as_str());
            }
            Verdict::Flaky => {
                writeln!(out, "{}: flaky, failed {attempts}{see}", case.id)?;
                flaky.push(case.id.as_str());
            }
            Verdict::Interrupted => {}
            Verdict::Quarantined => match quarantine.entry(&run.runner, case) {
                Some(entry) => writeln!(
                    out,
                    "{}: quarantined ({}, issue #{}), failed {attempts}{see}",
                    case.id, entry.reason, entry.issue
                )?,
                None => writeln!(out, "{}: quarantined, failed {attempts}{see}", case.id)?,
            },
        }
    }
    if let Some(trouble) = run_trouble(run) {
        bail!("the run {trouble}{}", trouble_logs(run, evidence));
    }
    if !failed.is_empty() {
        bail!(
            "{} of {} cases failed: {}",
            failed.len(),
            run.cases.len(),
            failed.join(", ")
        );
    }
    if !flaky.is_empty() {
        bail!(
            "{} of {} cases are flaky: {}",
            flaky.len(),
            run.cases.len(),
            flaky.join(", ")
        );
    }
    if !unsteady_cases.is_empty() {
        bail!(
            "{} of {} cases are unsteady: {}",
            unsteady_cases.len(),
            run.cases.len(),
            unsteady_cases.join(", ")
        );
    }
    Ok(())
}

/// What an unsteady case's report line says before it lists how each run held its windows.
const UNSTEADY: &str = "a window holds at another tick at another pace";

/// The name a quarantine entry and the evidence section use for `runner`.
pub fn runner_name(runner: &Runner) -> &'static str {
    match runner {
        Runner::Components => "components",
        Runner::Schema => "schema",
        Runner::Panel => "panel",
        Runner::PanelWeb => "panel-web",
        Runner::Step => "step",
        Runner::Junit => "junit",
        Runner::Game => "game",
        Runner::Unknown(_) => "unknown",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{
        attempted, case, failed, game_run, interrupted, lost, once, outcomes, part, quarantining,
        report_text, requirement_run, run, unknown,
    };

    #[test]
    fn the_verdict_follows_the_attempt_policy_and_the_quarantine() {
        use AttemptPolicy::{Exactly, RerunFailures};
        use Outcome::Passed;
        let table = [
            (
                RerunFailures(2),
                vec![Passed],
                Quarantine::default(),
                Verdict::Passed,
            ),
            (
                RerunFailures(2),
                vec![failed("x"), Passed],
                Quarantine::default(),
                Verdict::Flaky,
            ),
            (
                RerunFailures(2),
                vec![failed("x"), failed("y")],
                Quarantine::default(),
                Verdict::Failed,
            ),
            (
                Exactly(2),
                vec![failed("x"), Passed],
                Quarantine::default(),
                Verdict::Failed,
            ),
            (
                Exactly(2),
                vec![Passed, Passed],
                Quarantine::default(),
                Verdict::Passed,
            ),
            (
                Exactly(3),
                vec![Passed, failed("x"), Passed],
                Quarantine::default(),
                Verdict::Failed,
            ),
            (
                RerunFailures(2),
                vec![unknown()],
                Quarantine::default(),
                Verdict::Failed,
            ),
            (
                RerunFailures(2),
                vec![unknown(), Passed],
                Quarantine::default(),
                Verdict::Flaky,
            ),
            (
                Exactly(1),
                vec![unknown()],
                Quarantine::default(),
                Verdict::Failed,
            ),
            (
                RerunFailures(2),
                vec![failed("x")],
                quarantining("components/a"),
                Verdict::Quarantined,
            ),
            (
                Exactly(3),
                vec![Passed, failed("x"), Passed],
                quarantining("components/a"),
                Verdict::Quarantined,
            ),
            (
                RerunFailures(2),
                vec![failed("x")],
                quarantining("panel/a"),
                Verdict::Failed,
            ),
            (
                Exactly(2),
                vec![Passed, Passed],
                quarantining("components/a"),
                Verdict::Passed,
            ),
        ];
        for (row, (policy, attempts, quarantine, expected)) in table.into_iter().enumerate() {
            let run = attempted(policy, &attempts);
            let verdict = verdict(&run, &run.cases[0], &quarantine).unwrap();
            assert_eq!(verdict, expected, "row {row}");
        }
    }

    #[test]
    fn a_case_without_attempts_has_no_verdict() {
        let run = attempted(AttemptPolicy::RerunFailures(2), &[]);
        let error = verdict(&run, &run.cases[0], &Quarantine::default()).unwrap_err();
        assert!(error.to_string().contains("a has no attempts"), "{error}");
        let (result, out) = report_text(&run, &Quarantine::default());
        assert!(result.is_err());
        assert!(out.contains("a: failed, no attempts recorded"), "{out}");
    }

    #[test]
    fn a_failed_case_runs_again_and_passing_then_makes_it_flaky() {
        let folded = attempts(
            AttemptPolicy::RerunFailures(2),
            &[],
            &Quarantine::default(),
            |n, ids| {
                let mut reported = match n {
                    1 => run(&[("a", failed("boom")), ("b", Outcome::Passed)]),
                    _ => {
                        assert_eq!(ids, ["a"]);
                        run(&[("a", Outcome::Passed)])
                    }
                };
                for case in &mut reported.cases {
                    case.attempts[0].folder = format!("attempts/{n}");
                }
                Ok(reported)
            },
        )
        .unwrap();
        assert_eq!(folded.attempt_policy, AttemptPolicy::RerunFailures(2));
        assert_eq!(outcomes(&folded, "a"), [failed("boom"), Outcome::Passed]);
        assert_eq!(outcomes(&folded, "b"), [Outcome::Passed]);
        let (result, out) = report_text(&folded, &Quarantine::default());
        assert!(
            result
                .unwrap_err()
                .to_string()
                .contains("1 of 2 cases are flaky: a")
        );
        assert_eq!(
            out,
            "a: flaky, failed 1 of 2 attempts (1); see results/panel/attempts/1/\n"
        );
    }

    #[test]
    fn a_case_that_fails_every_attempt_gates() {
        let folded = attempts(
            AttemptPolicy::RerunFailures(3),
            &[],
            &Quarantine::default(),
            |_, _| Ok(run(&[("a", failed("boom"))])),
        )
        .unwrap();
        assert_eq!(outcomes(&folded, "a").len(), 3);
        let (result, out) = report_text(&folded, &Quarantine::default());
        assert_eq!(result.unwrap_err().to_string(), "1 of 1 cases failed: a");
        assert!(out.contains("a: failed 3 of 3 attempts (1, 2, 3)"), "{out}");
    }

    #[test]
    fn a_quarantined_failure_is_not_attempted_again_and_does_not_gate() {
        let quarantine = quarantining("components/a");
        let folded = attempts(
            AttemptPolicy::RerunFailures(2),
            &[],
            &quarantine,
            once(run(&[("a", failed("boom"))])),
        )
        .unwrap();
        let (result, out) = report_text(&folded, &quarantine);
        assert!(result.is_ok());
        assert!(
            out.contains("a: quarantined (times out on CI, issue #7), failed 1 of 1 attempts (1)"),
            "{out}"
        );
    }

    #[test]
    fn a_quarantine_entry_of_another_runner_does_not_apply() {
        let quarantine = quarantining("panel/a");
        let folded = attempts(AttemptPolicy::RerunFailures(2), &[], &quarantine, |_, _| {
            Ok(run(&[("a", failed("boom"))]))
        })
        .unwrap();
        assert!(report(&folded, &quarantine, None, &mut Vec::new()).is_err());
    }

    #[test]
    fn a_repeated_selection_runs_every_attempt_and_names_the_failed_ones() {
        let selection = ["CONN-1".to_owned()];
        let mut asked = Vec::new();
        let folded = attempts(
            AttemptPolicy::Exactly(3),
            &selection,
            &Quarantine::default(),
            |n, ids| {
                asked.push((n, ids.to_vec()));
                let outcome = if n == 2 {
                    failed("boom")
                } else {
                    Outcome::Passed
                };
                let mut reported = run(&[("[CONN-1] Reconnects", outcome)]);
                reported.cases[0].requirement = Some("CONN-1".to_owned());
                reported.cases[0].attempts[0].folder = format!("attempts/{n}");
                Ok(reported)
            },
        )
        .unwrap();
        assert_eq!(asked, [1, 2, 3].map(|n| (n, selection.to_vec())).to_vec());
        let (result, out) = report_text(&folded, &Quarantine::default());
        assert!(result.is_err());
        assert_eq!(
            out,
            "[CONN-1] Reconnects: failed 1 of 3 attempts (2); see results/panel/attempts/2/\n"
        );
    }

    #[test]
    fn a_repeated_selection_that_always_passes_reports_every_case() {
        let folded = attempts(
            AttemptPolicy::Exactly(2),
            &[],
            &Quarantine::default(),
            |_, _| Ok(run(&[("a", Outcome::Passed)])),
        )
        .unwrap();
        let (result, out) = report_text(&folded, &Quarantine::default());
        assert!(result.is_ok());
        assert_eq!(out, "a: passed 2 of 2 attempts\n");
    }

    #[test]
    fn a_case_a_later_attempt_does_not_report_fails_that_attempt() {
        let folded = attempts(
            AttemptPolicy::Exactly(2),
            &[],
            &Quarantine::default(),
            |n, _| match n {
                1 => Ok(run(&[("a", Outcome::Passed), ("b", Outcome::Passed)])),
                _ => Ok(run(&[("a", Outcome::Passed)])),
            },
        )
        .unwrap();
        let reported = outcomes(&folded, "b");
        assert_eq!(reported.len(), 2);
        assert!(
            matches!(&reported[1], Outcome::Failed(failure) if failure.message.contains("attempt 2 reported no result"))
        );
    }

    #[test]
    fn a_selection_that_matches_no_case_fails() {
        let error = attempts(
            AttemptPolicy::Exactly(2),
            &["CONN-9".to_owned()],
            &Quarantine::default(),
            once(run(&[("a", Outcome::Passed)])),
        )
        .unwrap_err();
        assert_eq!(
            error.to_string(),
            "--only CONN-9 matched nothing: no requirement or case has that id"
        );
    }

    #[test]
    fn an_interrupted_attempt_counts_neither_way_and_a_case_left_interrupted_has_no_verdict() {
        use AttemptPolicy::RerunFailures;
        use Outcome::Passed;
        let table = [
            (vec![interrupted("paper")], Verdict::Interrupted),
            (
                vec![failed("x"), interrupted("paper")],
                Verdict::Interrupted,
            ),
            (vec![interrupted("client-gv-1"), Passed], Verdict::Passed),
            (
                vec![interrupted("client-gv-1"), failed("x"), Passed],
                Verdict::Flaky,
            ),
            (
                vec![interrupted("client-gv-1"), failed("x")],
                Verdict::Failed,
            ),
        ];
        for (attempts, expected) in table {
            let run = attempted(RerunFailures(4), &attempts);
            let verdict = verdict(&run, &run.cases[0], &Quarantine::default()).unwrap();
            assert_eq!(verdict, expected, "{attempts:?}");
        }
    }

    #[test]
    fn a_failed_case_names_the_folder_of_its_run_s_logs() {
        let mut run = attempted(AttemptPolicy::RerunFailures(1), &[failed("lost")]);
        run.logs = "logs/7".to_owned();

        let (_, out) = report_text(&run, &Quarantine::default());

        assert_eq!(
            out,
            "a: failed 1 of 1 attempts (1); see results/panel/; logs in results/panel/logs/7/\n"
        );
    }

    #[test]
    fn a_run_cut_short_fails_after_naming_its_finished_cases_and_where_its_logs_are() {
        let mut run = attempted(AttemptPolicy::RerunFailures(1), &[failed("lost")]);
        run.end = RunEnd::CutShort;
        run.logs = "logs/7".to_owned();

        let (result, out) = report_text(&run, &Quarantine::default());

        assert_eq!(
            result.unwrap_err().to_string(),
            "the run was cut short after 1 cases, so the cases after them never ran; logs in results/panel/logs/7/"
        );
        assert!(out.starts_with("a: failed 1 of 1 attempts"), "{out}");
    }

    #[test]
    fn a_run_that_could_not_run_fails_with_why_even_when_its_cases_passed() {
        let mut run = attempted(AttemptPolicy::RerunFailures(1), &[Outcome::Passed]);
        run.end = RunEnd::CouldNotRun("the game was not ready within 300 s".to_owned());

        let (result, _) = report_text(&run, &Quarantine::default());

        assert_eq!(
            result.unwrap_err().to_string(),
            "the run could not run: the game was not ready within 300 s"
        );
    }

    #[test]
    fn a_run_whose_end_this_xtask_does_not_know_fails_even_when_its_cases_passed() {
        let mut run = attempted(AttemptPolicy::RerunFailures(1), &[Outcome::Passed]);
        run.end = RunEnd::default();

        let (result, _) = report_text(&run, &Quarantine::default());

        assert_eq!(
            result.unwrap_err().to_string(),
            "the run ended in a way this xtask does not know"
        );
    }

    #[test]
    fn a_run_a_lost_part_stopped_fails_once_naming_the_part_its_cause_and_the_cases_it_took() {
        let mut run = game_run(
            AttemptPolicy::RerunFailures(4),
            &[
                ("A-1", &[interrupted("paper")]),
                ("B-1", &[Outcome::Passed]),
                ("C-1", &[failed("x"), interrupted("paper")]),
            ],
        );
        run.logs = "logs/7".to_owned();
        run.parts = vec![
            part(
                "paper",
                PartKind::SharedPaper,
                "paper.log",
                lost(LossCause::Exited(137)),
            ),
            part(
                "client-gv-1",
                PartKind::Client,
                "client-gv-1.log",
                PartEnd::RanToEnd,
            ),
        ];
        run.end = RunEnd::Lost(Box::new(RunLost {
            part: "paper".to_owned(),
            not_run: vec![
                "D-1 the requirement".to_owned(),
                "E-1 the requirement".to_owned(),
            ],
            ..RunLost::default()
        }));

        let (result, out) = report_text(&run, &Quarantine::default());

        assert_eq!(
            result.unwrap_err().to_string(),
            "the run stopped: the shared Paper paper was lost, it exited with status 137 (signal 9); \
             2 attempts were interrupted (A-1 the requirement, C-1 the requirement) and 2 cases never ran \
             (D-1 the requirement, E-1 the requirement); its log is results/panel/logs/7/paper.log"
        );
        assert_eq!(out, "", "an interrupted case prints no failure of its own");
    }

    #[test]
    fn each_cause_of_a_lost_part_reads_as_what_happened() {
        let table = [
            (LossCause::Exited(1), "it exited with status 1"),
            (
                LossCause::Exited(143),
                "it exited with status 143 (signal 15)",
            ),
            (
                LossCause::Left("paper closed its pool connection".to_owned()),
                "it left: paper closed its pool connection",
            ),
            (
                LossCause::LeftPaper("Disconnected".to_owned()),
                "its player left Paper: Disconnected",
            ),
            (
                LossCause::Dropped("it could not join paper-gv-1".to_owned()),
                "it lost its Paper without being told to leave: it could not join paper-gv-1",
            ),
            (LossCause::Stalled, "it stopped answering"),
            (LossCause::NeverReady, "it never became ready"),
            (
                LossCause::KilledForMemory(Box::new(MemoryKill::MachineOutOfMemory)),
                "the kernel killed it, as the machine ran out of memory",
            ),
            (
                LossCause::KilledForMemory(Box::new(MemoryKill::OwnLimit)),
                "the kernel killed it for taking all the memory its cgroup allows",
            ),
            (
                LossCause::KilledForMemory(Box::new(MemoryKill::GameBudget)),
                "the kernel killed it, as the game's parts together took all the game's budget",
            ),
            (
                LossCause::Broke("it could not claim gv-1".to_owned()),
                "it could no longer serve attempts: it could not claim gv-1",
            ),
            (
                LossCause::default(),
                "for a reason this xtask does not know",
            ),
        ];
        for (cause, expected) in table {
            assert_eq!(loss_cause(&cause), expected);
        }
    }

    #[test]
    fn a_case_its_runner_concluded_has_that_verdict_and_an_unsteady_one_blocks_only_where_its_pacing_gates()
     {
        let ticks = "attempt 1 at 0 ms held A.kt:10 at tick 5; at 50 ms held A.kt:10 at tick 3";
        let table = [
            (
                "passed",
                Outcome::Passed,
                Pacing::Gates,
                Some(Conclusion::Passed),
                Verdict::Passed,
            ),
            (
                "flaky",
                Outcome::Passed,
                Pacing::Gates,
                Some(Conclusion::Flaky),
                Verdict::Flaky,
            ),
            (
                "failed",
                failed("x"),
                Pacing::Gates,
                Some(Conclusion::Failed),
                Verdict::Failed,
            ),
            (
                "quarantined",
                failed("x"),
                Pacing::Gates,
                Some(Conclusion::Quarantined),
                Verdict::Quarantined,
            ),
            (
                "unsteady where pacing gates",
                Outcome::Passed,
                Pacing::Gates,
                Some(Conclusion::Unsteady(ticks.to_owned())),
                Verdict::Unsteady,
            ),
            (
                "unsteady where pacing reports",
                Outcome::Passed,
                Pacing::Reports,
                Some(Conclusion::Unsteady(ticks.to_owned())),
                Verdict::Passed,
            ),
            (
                "a lost part interrupted its last attempt",
                interrupted("paper"),
                Pacing::Gates,
                Some(Conclusion::Failed),
                Verdict::Interrupted,
            ),
            (
                "judged by its attempts",
                Outcome::Passed,
                Pacing::Gates,
                None,
                Verdict::Passed,
            ),
        ];
        for (row, outcome, pacing, conclusion, expected) in table {
            let mut run = attempted(AttemptPolicy::RerunFailures(4), &[outcome]);
            run.cases[0].pacing = pacing;
            run.cases[0].conclusion = conclusion;
            let verdict = verdict(&run, &run.cases[0], &Quarantine::default()).unwrap();
            assert_eq!(verdict, expected, "{row}");
        }
    }

    #[test]
    fn an_unsteady_case_names_the_tick_of_each_window_in_each_run_its_runner_described() {
        let mut run = attempted(AttemptPolicy::RerunFailures(4), &[Outcome::Passed]);
        let ticks = "attempt 1 at 0 ms held A.kt:10 at tick 13; at 5 ms held A.kt:10 at tick 13; \
                     at 50 ms missed A.kt:10 (failed: missed)";
        run.cases[0].conclusion = Some(Conclusion::Unsteady(ticks.to_owned()));
        let unsteady =
            format!("a: unsteady, a window holds at another tick at another pace: {ticks}");

        run.cases[0].pacing = Pacing::Gates;
        let (result, out) = report_text(&run, &Quarantine::default());
        assert_eq!(
            result.unwrap_err().to_string(),
            "1 of 1 cases are unsteady: a"
        );
        assert_eq!(out, format!("{unsteady}\n"));

        run.cases[0].pacing = Pacing::Reports;
        let (result, out) = report_text(&run, &Quarantine::default());
        assert!(result.is_ok(), "{result:?}");
        assert_eq!(out, format!("{unsteady} (reported, not blocking)\n"));
    }

    #[test]
    fn a_quarantine_entry_names_a_case_by_its_id_or_by_its_requirement() {
        let mut held = attempted(AttemptPolicy::RerunFailures(4), &[failed("x")]);
        held.runner = Runner::Game;
        held.cases[0].id = "WINDOW-1 a check that never holds fails".to_owned();
        held.cases[0].requirement = Some("WINDOW-1".to_owned());
        for entry in [
            "game/WINDOW-1",
            "game/WINDOW-1 a check that never holds fails",
        ] {
            let verdict = verdict(&held, &held.cases[0], &quarantining(entry)).unwrap();
            assert_eq!(verdict, Verdict::Quarantined, "{entry}");
        }
        let verdict = verdict(&held, &held.cases[0], &quarantining("game/WINDOW-2")).unwrap();
        assert_eq!(verdict, Verdict::Failed);
    }

    #[test]
    fn a_quarantine_lists_the_cases_it_holds_for_one_runner() {
        let quarantine: Quarantine = toml::from_str(
            "[[case]]\nid = \"game/WINDOW-1\"\nreason = \"r\"\nissue = 1\n\
             [[case]]\nid = \"panel/CONN-1\"\nreason = \"r\"\nissue = 2\n\
             [[case]]\nid = \"game/HUNG-1\"\nreason = \"r\"\nissue = 3\n",
        )
        .unwrap();
        assert_eq!(quarantine.held(&Runner::Game), ["WINDOW-1", "HUNG-1"]);
    }

    #[test]
    fn a_selection_names_each_case_by_its_id_or_its_requirement() {
        let reported = requirement_run("CONN-1", "[CONN-1] Reconnects", Outcome::Passed);
        let selected = ["CONN-1".to_owned(), "[CONN-1] Reconnects".to_owned()];
        assert!(selection_matches(&reported, &selected).is_ok());
        let error =
            selection_matches(&reported, &["CONN-2".to_owned(), "AUTH-1".to_owned()]).unwrap_err();
        assert_eq!(
            error.to_string(),
            "--only CONN-2, AUTH-1 matched nothing: no requirement or case has that id"
        );
    }

    #[test]
    fn a_run_survives_writing_and_reading() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("nested/run.json");
        let mut written = run(&[("a", failed("boom")), ("b", Outcome::Passed)]);
        written
            .cases
            .push(case("c", &[failed("first"), Outcome::Passed]));
        written.attempt_policy = AttemptPolicy::RerunFailures(2);
        write(&written, &path).unwrap();
        assert_eq!(read_all(dir.path()).unwrap(), vec![(path, written)]);
    }

    #[test]
    fn every_run_of_the_ci_layout_is_read_once_and_evidence_folders_are_skipped() {
        let dir = tempfile::tempdir().unwrap();
        let ci = [
            "components.json",
            "inputs/results-check-xtask/steps/test-xtask.json",
            "inputs/results-e2e-panel/test_run.json",
            "panel/test_run.json",
            "full-panel-web/test_run.json",
        ];
        let evidence = [
            // The sign in drive's own run, whose case the suite's run already holds.
            "full-panel-web/attempts/1/sign-in/test_run.json",
            "inputs/results-e2e-panel/attempts/1/test_run.json",
            "inputs/results-e2e-panel/attempts/2/test_run.json",
            "inputs/results-e2e-panel/failures/1/test_run.json",
            "panel/attempts/1/test_run.json",
            "panel/screenshots/run.json",
            "panel/logs/run.json",
        ];
        for file in ci.iter().chain(&evidence) {
            write(&run(&[("a", Outcome::Passed)]), &dir.path().join(file)).unwrap();
        }
        let mut read: Vec<PathBuf> = read_all(dir.path())
            .unwrap()
            .into_iter()
            .map(|(path, _)| path.strip_prefix(dir.path()).unwrap().to_owned())
            .collect();
        read.sort();
        let mut expected: Vec<PathBuf> = ci.iter().map(PathBuf::from).collect();
        expected.sort();
        assert_eq!(read, expected);
    }
}
