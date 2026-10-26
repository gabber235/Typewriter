//! The managed section of the pull request description. Everything between [`START`] and [`END`]
//! is rendered from the `TestRun`s and the change report and replaced on every push; text outside
//! the markers (the agent's summary, notes) is left alone. Media goes to the evidence branch
//! first, and nothing leaves the runner while it contains a secret the run knew.

use std::fmt::Write as _;
use std::fs;
use std::io::Write as _;
use std::path::{Path, PathBuf};
use std::process::Stdio;

use anyhow::{Context as _, Result, anyhow, bail};
use serde::Deserialize;
use serde::de::IgnoredAny;

use super::{ATTEMPTS, EvidenceRepository, Inputs, REPOSITORY, media_url, pr_folder};
use crate::results::{self, Outcome, TestRun, runner_name};
use crate::review::verdict::{
    COMMIT as VERDICT_COMMIT, END as VERDICT_END, START as VERDICT_START,
};
use crate::skirout::base::harness::v1::test_run::{ArtifactKind, Demonstrates, TestCase};
use crate::{CommandExt, Context};

const START: &str = "<!-- evidence:start -->";
const END: &str = "<!-- evidence:end -->";
/// Marks a verdict whose commit is no longer the head.
const STALE: &str = "**Stale**: ";
/// Environment variables whose values must never appear in published text or media.
const SECRETS: [&str; 3] = ["GH_TOKEN", "GITHUB_TOKEN", "CI_AGE_KEY"];
/// Change map entries shown before the rest are counted.
const CHANGE_MAP_LIMIT: usize = 50;

/// Uploads the media of every run under the results folder to `pr/<pr>/<sha>/` on the evidence
/// branch and rewrites the managed section of pull request `pr`.
pub fn publish(ctx: &Context, pr: u64, sha: &str, inputs: &Inputs) -> Result<()> {
    let runs = results::read_all(&ctx.root.join(&inputs.results))?;
    let report = ChangeReport::read(&ctx.root.join(&inputs.report))?;
    let media = media(&runs);
    let prefix = pr_folder(pr, Some(sha));
    let secrets = known_secrets();
    let section = |verdict: Option<&Verdict>| {
        render_section(&Section {
            sha,
            pr: Some(pr),
            runs: &runs,
            report: &report,
            verdict,
            media_url: Some(&media_url(&prefix)),
        })
    };
    // Media is uploaded before the description is read, so the read modify write stays short.
    // The verdict comes from the description, so the final section is scrubbed again there.
    scrub(&section(None), &media, &secrets)?;
    if !media.is_empty() {
        let repository = EvidenceRepository::clone_shallow(ctx)?;
        for (source, target) in &media {
            let destination = repository.path(&format!("{prefix}/{target}"));
            if let Some(parent) = destination.parent() {
                fs::create_dir_all(parent)?;
            }
            fs::copy(source, &destination)
                .with_context(|| format!("cannot copy {}", source.display()))?;
        }
        repository.commit_and_push(ctx, &format!("pr {pr} at {}", &sha[..sha.len().min(7)]))?;
    }
    edit_pull_body(ctx, pr, |body| {
        let (body, verdict) = take_verdict(body);
        let section = section(verdict.as_ref());
        scrub(&section, &[], &secrets)?;
        Ok(replace_between(&body, START, END, &section))
    })?;
    println!("evidence for {sha} published to #{pr}");
    Ok(())
}

/// The section without media links, for fork pull requests, whose workflow token cannot push.
pub fn summary(ctx: &Context, sha: &str, inputs: &Inputs) -> Result<String> {
    let runs = results::read_all(&ctx.root.join(&inputs.results))?;
    let report = ChangeReport::read(&ctx.root.join(&inputs.report))?;
    let section = render_section(&Section {
        sha,
        pr: None,
        runs: &runs,
        report: &report,
        verdict: None,
        media_url: None,
    });
    scrub(&section, &[], &known_secrets())?;
    Ok(section)
}

/// The parts of `cargo xtask review report --json` the section shows.
#[derive(Deserialize)]
struct ChangeReport {
    findings: Vec<Finding>,
    tests: TestChanges,
    change_map: Vec<EntityChange>,
}

#[derive(Deserialize)]
struct Finding {
    severity: String,
}

#[derive(Deserialize)]
struct TestChanges {
    added: Vec<IgnoredAny>,
    deleted: Vec<IgnoredAny>,
    weakened: Vec<IgnoredAny>,
    disabled: Vec<IgnoredAny>,
    expectations_rewritten: Vec<IgnoredAny>,
    harness_edits: Vec<IgnoredAny>,
}

#[derive(Deserialize)]
struct EntityChange {
    change: String,
    qualified: String,
    file: PathBuf,
    line: u32,
}

impl ChangeReport {
    fn read(path: &Path) -> Result<Self> {
        let text = fs::read_to_string(path).with_context(|| {
            format!(
                "cannot read {}; write it with `cargo xtask review report --json`",
                path.display()
            )
        })?;
        serde_json::from_str(&text)
            .with_context(|| format!("{} is not a change report", path.display()))
    }
}

/// The reviewer's verdict as found in the description.
struct Verdict {
    commit: String,
    text: String,
}

/// Removes the verdict block from `body`, wherever it is, so the section can carry it.
fn take_verdict(body: &str) -> (String, Option<Verdict>) {
    let (Some(from), Some(to)) = (body.find(VERDICT_START), body.find(VERDICT_END)) else {
        return (body.to_string(), None);
    };
    if to < from {
        return (body.to_string(), None);
    }
    let inner = body[from + VERDICT_START.len()..to].trim();
    let rest = format!("{}{}", &body[..from], &body[to + VERDICT_END.len()..]);
    let verdict = inner
        .strip_prefix(VERDICT_COMMIT)
        .and_then(|line| line.split_once("-->"))
        .map(|(commit, text)| Verdict {
            commit: commit.trim().to_string(),
            text: text
                .trim()
                .lines()
                .filter(|line| !line.starts_with(STALE))
                .collect::<Vec<_>>()
                .join("\n"),
        });
    (rest, verdict)
}

struct Section<'a> {
    sha: &'a str,
    pr: Option<u64>,
    runs: &'a [(PathBuf, TestRun)],
    report: &'a ChangeReport,
    verdict: Option<&'a Verdict>,
    /// Where the media folder is served; `None` when the media was not uploaded.
    media_url: Option<&'a str>,
}

fn render_section(section: &Section) -> String {
    let mut out = String::new();
    let short = &section.sha[..section.sha.len().min(7)];

    let _ = writeln!(out, "### Recordings");
    let scenarios: Vec<(&TestRun, &TestCase)> = cases(section.runs)
        .filter(|(_, case)| case.requirement.is_some() || !case.artifacts.is_empty())
        .collect();
    if scenarios.is_empty() {
        let _ = writeln!(out, "No requirement scenarios ran.");
    } else {
        let _ = writeln!(
            out,
            "| | Requirement | Result | Recording |\n|---|---|---|---|"
        );
        for (run, case) in scenarios {
            let _ = writeln!(
                out,
                "| {} | {} | {} | {} |",
                kind(&case.demonstrates),
                match &case.requirement {
                    Some(requirement) => format!("{requirement} `{}`", case.id),
                    None => format!("`{}`", case.id),
                },
                result(&case.outcome),
                recording(run, case, section.media_url),
            );
        }
    }

    let _ = writeln!(out, "\n### Broken and unreliable");
    let mut troubled = 0;
    for (run, case) in cases(section.runs) {
        let (word, failure) = match &case.outcome {
            Outcome::Failed(failure) => ("**broken**", failure),
            Outcome::Flaky(failure) => ("**unreliable**", failure),
            _ => continue,
        };
        troubled += 1;
        let _ = writeln!(
            out,
            "- {word} {}/{}: {}{}",
            runner_name(&run.runner),
            case.id,
            cell(&failure.message),
            failure
                .first_broken
                .as_ref()
                .map(|step| format!(" (first broken: {})", cell(step)))
                .unwrap_or_default()
        );
    }
    if troubled == 0 {
        let _ = writeln!(out, "None.");
    }

    let _ = writeln!(out, "\n### Review");
    match section.verdict {
        Some(verdict) => {
            let fresh =
                section.sha.starts_with(&verdict.commit) || verdict.commit.starts_with(section.sha);
            let stale = if fresh {
                String::new()
            } else {
                format!(
                    "{STALE}reviewed {}, the head is now {short}.\n",
                    &verdict.commit[..verdict.commit.len().min(7)]
                )
            };
            let _ = writeln!(
                out,
                "{VERDICT_START}\n{VERDICT_COMMIT}{} -->\n{stale}{}\n{VERDICT_END}",
                verdict.commit, verdict.text
            );
        }
        None => {
            let _ = writeln!(out, "{VERDICT_START}\nNo verdict yet.\n{VERDICT_END}");
        }
    }
    let gates = section
        .report
        .findings
        .iter()
        .filter(|finding| finding.severity == "gate")
        .count();
    let flags = section.report.findings.len() - gates;
    let _ = writeln!(
        out,
        "Findings inline: {gates} gating, {flags} flags{}.",
        section
            .pr
            .map(|pr| format!(
                " ([code scanning](https://github.com/{REPOSITORY}/pull/{pr}/checks))"
            ))
            .unwrap_or_default()
    );

    let _ = writeln!(out, "\n### Run health");
    let mut flaky = Vec::new();
    let mut quarantined = Vec::new();
    let mut over_budget = Vec::new();
    for (run, case) in cases(section.runs) {
        let id = format!("{}/{}", runner_name(&run.runner), case.id);
        match &case.outcome {
            Outcome::Flaky(_) => flaky.push(format!("{id} (passed on rerun)")),
            Outcome::Quarantined(_) => quarantined.push(id),
            Outcome::OverBudget(millis) => over_budget.push(format!("{id} by {millis} ms")),
            _ => {}
        }
    }
    let _ = writeln!(
        out,
        "Flaky {}{}. Quarantined {}{}. Over budget {}{}.",
        flaky.len(),
        listed(&flaky),
        quarantined.len(),
        listed(&quarantined),
        over_budget.len(),
        listed(&over_budget)
    );
    for (_, run) in section.runs {
        let passed = run
            .cases
            .iter()
            .filter(|case| matches!(case.outcome, Outcome::Passed | Outcome::OverBudget(_)))
            .count();
        let _ = writeln!(
            out,
            "- {}: {passed} of {} passed",
            runner_name(&run.runner),
            run.cases.len()
        );
    }

    let tests = &section.report.tests;
    let _ = writeln!(
        out,
        "\n### Test changes\nAdded {}. Deleted {}. Weakened {}. Disabled {}. Expectations rewritten {}. Harness edits {}.",
        tests.added.len(),
        tests.deleted.len(),
        tests.weakened.len(),
        tests.disabled.len(),
        tests.expectations_rewritten.len(),
        tests.harness_edits.len()
    );

    let map = &section.report.change_map;
    let _ = writeln!(
        out,
        "\n<details><summary>Change map ({} entities)</summary>\n",
        map.len()
    );
    for entity in map.iter().take(CHANGE_MAP_LIMIT) {
        let sign = match entity.change.as_str() {
            "added" => '+',
            "removed" => '-',
            _ => '~',
        };
        let _ = writeln!(
            out,
            "- {sign} `{}` {}:{}",
            entity.qualified,
            entity.file.display(),
            entity.line
        );
    }
    if map.len() > CHANGE_MAP_LIMIT {
        let _ = writeln!(out, "- and {} more", map.len() - CHANGE_MAP_LIMIT);
    }
    let _ = writeln!(out, "\n</details>\n");
    let _ = write!(
        out,
        "<sub>Commit {short}. Rewritten by CI on every push.</sub>"
    );
    out
}

fn cases(runs: &[(PathBuf, TestRun)]) -> impl Iterator<Item = (&TestRun, &TestCase)> {
    runs.iter()
        .flat_map(|(_, run)| run.cases.iter().map(move |case| (run, case)))
}

fn kind(demonstrates: &Demonstrates) -> &'static str {
    match demonstrates {
        Demonstrates::HappyPath => "happy path",
        Demonstrates::Failure => "failure",
        Demonstrates::EdgeCase => "edge case",
        Demonstrates::Unknown(_) => "scenario",
    }
}

fn result(outcome: &Outcome) -> String {
    match outcome {
        Outcome::Passed => "proven".to_string(),
        Outcome::OverBudget(millis) => format!("proven, {millis} ms over budget"),
        Outcome::Failed(_) => "**broken**".to_string(),
        Outcome::Flaky(_) => "**unreliable**".to_string(),
        Outcome::Quarantined(_) => "**quarantined**".to_string(),
        Outcome::Unknown(_) => "unknown".to_string(),
    }
}

/// The previews and links of a case's artifacts, then what broke, as one table cell.
fn recording(run: &TestRun, case: &TestCase, media_url: Option<&str>) -> String {
    let runner = runner_name(&run.runner);
    let mut parts = Vec::new();
    for artifact in &case.artifacts {
        let Some(base) = media_url else {
            parts.push(format!("`{runner}/{}` in the run artifacts", artifact.path));
            continue;
        };
        let url = format!("{base}/{runner}/{}", artifact.path);
        parts.push(match artifact.kind {
            ArtifactKind::Clip => {
                let preview = Path::new(&artifact.path).with_extension("webp");
                format!(
                    "![]({base}/{runner}/{}) [full video]({url})",
                    preview.display()
                )
            }
            ArtifactKind::Screenshot => format!("![]({url})"),
            ArtifactKind::LogExcerpt | ArtifactKind::Unknown(_) => format!("[log]({url})"),
        });
    }
    if let Outcome::Failed(failure) | Outcome::Flaky(failure) | Outcome::Quarantined(failure) =
        &case.outcome
    {
        parts.push(cell(&failure.message));
    }
    parts.join(" ")
}

/// Text safe inside a table cell or a list item: one line, no column breaks, bounded length.
fn cell(text: &str) -> String {
    let line = text
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
        .replace('|', "\\|");
    match line.char_indices().nth(200) {
        Some((at, _)) => format!("{}...", &line[..at]),
        None => line,
    }
}

/// `: a, b` or nothing.
pub(crate) fn listed(items: &[String]) -> String {
    if items.is_empty() {
        String::new()
    } else {
        format!(": {}", items.join(", "))
    }
}

/// Every artifact file of every run with its path in the commit folder, `<runner>/<path>`.
/// Artifact paths are relative to the folder of the run file; a clip's preview travels with it.
fn media(runs: &[(PathBuf, TestRun)]) -> Vec<(PathBuf, String)> {
    let mut media = Vec::new();
    for (path, run) in runs {
        let folder = path.parent().unwrap_or(Path::new("."));
        let runner = runner_name(&run.runner);
        for artifact in run.cases.iter().flat_map(|case| &case.artifacts) {
            media.push((
                folder.join(&artifact.path),
                format!("{runner}/{}", artifact.path),
            ));
            if artifact.kind == ArtifactKind::Clip {
                let preview = Path::new(&artifact.path).with_extension("webp");
                if folder.join(&preview).exists() {
                    media.push((
                        folder.join(&preview),
                        format!("{runner}/{}", preview.display()),
                    ));
                }
            }
        }
    }
    media
}

/// The values of [`SECRETS`] that are set, and each long line of them, so a log that printed
/// part of a key is caught too.
fn known_secrets() -> Vec<String> {
    let mut secrets = Vec::new();
    for value in SECRETS.iter().filter_map(|name| std::env::var(name).ok()) {
        let value = value.trim().to_string();
        if value.len() < 8 {
            continue;
        }
        secrets.extend(
            value
                .lines()
                .map(str::trim)
                .filter(|line| line.len() >= 16 && !line.starts_with("-----"))
                .map(String::from),
        );
        secrets.push(value);
    }
    secrets
}

/// Refuses to publish when the section or a text artifact contains a secret.
fn scrub(section: &str, media: &[(PathBuf, String)], secrets: &[String]) -> Result<()> {
    let leaked = |bytes: &[u8]| {
        secrets.iter().any(|secret| {
            bytes
                .windows(secret.len())
                .any(|window| window == secret.as_bytes())
        })
    };
    if leaked(section.as_bytes()) {
        bail!("the evidence section contains a secret; nothing was published");
    }
    // Recordings and screenshots are pixels; logs and other text are what can carry a secret.
    let pixels = |path: &Path| {
        path.extension().is_some_and(|extension| {
            ["mp4", "webp", "png"]
                .iter()
                .any(|pixel| extension == *pixel)
        })
    };
    for (source, _) in media.iter().filter(|(source, _)| !pixels(source)) {
        let bytes =
            fs::read(source).with_context(|| format!("cannot read {}", source.display()))?;
        if leaked(&bytes) {
            bail!(
                "{} contains a secret; nothing was published",
                source.display()
            );
        }
    }
    Ok(())
}

/// Replaces the text between `start` and `end`, or appends both markers when missing.
pub(crate) fn replace_between(body: &str, start: &str, end: &str, section: &str) -> String {
    match (body.find(start), body.find(end)) {
        (Some(from), Some(to)) if to > from => format!(
            "{}\n{section}\n{}",
            &body[..from + start.len()],
            &body[to..]
        ),
        _ => format!("{}\n\n{start}\n{section}\n{end}\n", body.trim_end()),
    }
}

/// Rewrites the description of `pr` through `edit`. Other jobs edit it too (a publish of a newer
/// push, the reviewer's verdict), so the description is read again right before the write and
/// the edit starts over when it changed meanwhile.
pub(crate) fn edit_pull_body(
    ctx: &Context,
    pr: u64,
    edit: impl Fn(&str) -> Result<String>,
) -> Result<()> {
    let mut body = pull_body(ctx, pr)?;
    for _ in 0..ATTEMPTS {
        let edited = edit(&body)?;
        let current = pull_body(ctx, pr)?;
        if current == body {
            return set_pull_body(ctx, pr, &edited);
        }
        body = current;
    }
    bail!("the description of #{pr} kept changing; gave up after {ATTEMPTS} attempts")
}

fn pull_body(ctx: &Context, pr: u64) -> Result<String> {
    #[derive(Deserialize)]
    struct Pull {
        body: String,
    }
    let view = ctx
        .tool(
            ".",
            "gh",
            &[
                "pr",
                "view",
                &pr.to_string(),
                "--repo",
                REPOSITORY,
                "--json",
                "body",
            ],
        )
        .output_text()?;
    let pull: Pull =
        serde_json::from_str(&view).context("gh printed an unexpected pull request")?;
    Ok(pull.body)
}

fn set_pull_body(ctx: &Context, pr: u64, body: &str) -> Result<()> {
    let mut edit = ctx
        .tool(
            ".",
            "gh",
            &[
                "pr",
                "edit",
                &pr.to_string(),
                "--repo",
                REPOSITORY,
                "--body-file",
                "-",
            ],
        )
        .stdin(Stdio::piped())
        .spawn()
        .context("cannot start gh")?;
    edit.stdin
        .take()
        .ok_or_else(|| anyhow!("gh has no stdin"))?
        .write_all(body.as_bytes())?;
    if !edit.wait()?.success() {
        bail!("gh pr edit failed");
    }
    Ok(())
}
