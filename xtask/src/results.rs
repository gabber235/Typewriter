//! The results contract every runner writes (`skir-src/harness/v1/test_run.skir`) and the one
//! attempt policy for every suite. [`attempts`] records every attempt of a case; [`verdict`]
//! reads them under the run's policy. Under `RerunFailures` a failed case runs again until it
//! passes, and passing after a failure makes it flaky, which gates like a failure: the rerun tells
//! a test that fails sometimes from one that always fails, and only a test that always passes is
//! trusted. Under `Exactly` any failed attempt fails the case. A case listed in [`QUARANTINE`] still runs and is reported but
//! does not gate; each entry names a reason and an issue, and every report lists the quarantined
//! cases so they cannot be forgotten.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, bail};
use serde::Deserialize;

use crate::Context;
use crate::skirout::base::harness::v1::test_run::Runner;
pub use crate::skirout::base::harness::v1::test_run::{
    Artifact, ArtifactKind, Attempt, AttemptPolicy, Failure, Outcome, TestCase, TestRun,
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

    fn entry(&self, runner: &Runner, case: &str) -> Option<&QuarantinedCase> {
        let id = format!("{}/{case}", runner_name(runner));
        self.cases.iter().find(|entry| entry.id == id)
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
}

/// The one policy every reader applies to a case of `run`. An attempt whose outcome this build
/// does not know proves nothing, so it counts as a failure.
pub fn verdict(run: &TestRun, case: &TestCase, quarantine: &Quarantine) -> Result<Verdict> {
    let Some(last) = case.attempts.last() else {
        bail!("{} has no attempts", case.id);
    };
    let failed = failed_attempts(case).count();
    let passed_last = matches!(last.outcome, Outcome::Passed);
    Ok(
        match (
            failed,
            quarantine.entry(&run.runner, &case.id),
            &run.attempt_policy,
        ) {
            (0, _, _) => Verdict::Passed,
            (_, Some(_), _) => Verdict::Quarantined,
            (_, None, AttemptPolicy::RerunFailures(_)) if passed_last => Verdict::Flaky,
            _ => Verdict::Failed,
        },
    )
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
    /// makes public. Logs and spans stay on the machine, so no token they print can leak
    /// through a scrub rule that missed it.
    pub fn published(&self) -> bool {
        matches!(self, Self::Clip | Self::Screenshot)
    }
}

/// The 1 based numbers of `case`'s attempts that did not pass.
fn failed_attempts(case: &TestCase) -> impl Iterator<Item = usize> + '_ {
    case.attempts
        .iter()
        .enumerate()
        .filter(|(_, attempt)| !matches!(attempt.outcome, Outcome::Passed))
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
    let unmatched: Vec<&str> = selection
        .iter()
        .filter(|id| {
            !first
                .cases
                .iter()
                .any(|case| case.id == **id || case.requirement.as_ref() == Some(*id))
        })
        .map(String::as_str)
        .collect();
    if !unmatched.is_empty() {
        bail!("no case matches {}", unmatched.join(", "));
    }
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
                        && quarantine.entry(&folded.runner, &case.id).is_none()
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
pub const RUN_EVIDENCE: [&str; 4] = [ATTEMPTS, "failures", "screenshots", "logs"];

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

/// Lists every case whose verdict is not a plain pass, and every case when the run repeated
/// each case, then fails when any case failed. `evidence`, the run's folder,
/// points each failing case at the evidence of its first failed attempt.
pub fn report(
    run: &TestRun,
    quarantine: &Quarantine,
    evidence: Option<&Path>,
    out: &mut dyn Write,
) -> Result<()> {
    let repeated = matches!(run.attempt_policy, AttemptPolicy::Exactly(n) if n > 1);
    let mut failed = Vec::new();
    let mut flaky = Vec::new();
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
        let first = failures.first().map(|first| &case.attempts[first - 1]);
        let see = match (evidence, first) {
            (Some(evidence), Some(attempt)) => match attempt_folder(attempt) {
                Some(folder) => format!("; see {}/", evidence.join(folder).display()),
                None => format!("; see {}/", evidence.display()),
            },
            _ => String::new(),
        };
        match verdict {
            Verdict::Passed if repeated => writeln!(
                out,
                "{}: passed {} of {} attempts",
                case.id,
                case.attempts.len(),
                case.attempts.len()
            )?,
            Verdict::Passed => {}
            Verdict::Failed => {
                writeln!(out, "{}: failed {attempts}{see}", case.id)?;
                failed.push(case.id.as_str());
            }
            Verdict::Flaky => {
                writeln!(out, "{}: flaky, failed {attempts}{see}", case.id)?;
                flaky.push(case.id.as_str());
            }
            Verdict::Quarantined => match quarantine.entry(&run.runner, &case.id) {
                Some(entry) => writeln!(
                    out,
                    "{}: quarantined ({}, issue #{}), failed {attempts}{see}",
                    case.id, entry.reason, entry.issue
                )?,
                None => writeln!(out, "{}: quarantined, failed {attempts}{see}", case.id)?,
            },
        }
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
    Ok(())
}

/// The name a quarantine entry and the evidence section use for `runner`.
pub fn runner_name(runner: &Runner) -> &'static str {
    match runner {
        Runner::Components => "components",
        Runner::Schema => "schema",
        Runner::Panel => "panel",
        Runner::PanelWeb => "panel-web",
        Runner::Step => "step",
        Runner::Junit => "junit",
        Runner::Unknown(_) => "unknown",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{
        attempted, case, failed, once, outcomes, quarantining, report_text, run, unknown,
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
        assert_eq!(error.to_string(), "no case matches CONN-9");
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
