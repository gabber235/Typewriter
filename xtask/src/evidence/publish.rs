//! The managed section of the pull request description. Everything between [`START`] and [`END`]
//! is rendered from the `TestRun`s and the change report and replaced on every push; text outside
//! the markers (the agent's summary, notes) is left alone. Media goes to its stores
//! first, and nothing leaves the runner while it contains a secret the run knew.

use std::fmt::Write as _;
use std::fs;
use std::io::Write as _;
use std::path::{Path, PathBuf};
use std::process::Stdio;

use anyhow::{Context as _, Result, anyhow, bail};
use serde::Deserialize;
use serde::de::IgnoredAny;

use super::stage::{self, published_files};
use super::{ATTEMPTS, Inputs, REPOSITORY, Store};
use crate::results::{self, Quarantine, TestRun, Verdict as CaseVerdict, runner_name};
use crate::review::verdict::{
    COMMIT as VERDICT_COMMIT, END as VERDICT_END, START as VERDICT_START, covers,
};
use crate::skirout::base::harness::v1::test_run::{ArtifactKind, Demonstrates, TestCase};
use crate::{CommandExt, Context};

const START: &str = "<!-- evidence:start -->";
const END: &str = "<!-- evidence:end -->";
/// Marks a verdict whose commit is no longer the head.
const STALE: &str = "**Stale**: ";
/// Environment variables whose values must never appear in published text or media.
/// Secrets resolved through `crate::secrets` never enter the environment.
const SECRETS: [&str; 3] = ["GH_TOKEN", "GITHUB_TOKEN", "OP_SERVICE_ACCOUNT_TOKEN"];
/// Change map entries shown before the rest are counted.
const CHANGE_MAP_LIMIT: usize = 50;

/// Uploads the media of every run under the results folder to `pr/<pr>/<sha>/` on the evidence
/// branch and rewrites the managed section of pull request `pr`.
pub fn publish(ctx: &Context, pr: u64, sha: &str, inputs: &Inputs) -> Result<()> {
    let secrets = known_secrets();
    // Raw results never reach a media store: only their staged projection is read.
    let runs = stage::staged(&ctx.root, &inputs.results, &secrets)?;
    let report = ChangeReport::read(&ctx.root.join(&inputs.report))?;
    let quarantine = Quarantine::load(ctx)?;
    let media = media(&runs);
    let provenance = provenance(ctx, sha)?;
    let section = |verdict: Option<&Verdict>, covered: bool| {
        render_section(&Section {
            sha,
            provenance: &provenance,
            pr: Some(pr),
            runs: &runs,
            quarantine: &quarantine,
            report: &report,
            verdict,
            covered,
            jobs_failed: inputs.jobs_failed,
        })
    };
    // Media is uploaded before the description is read, so the read modify write stays short.
    // The verdict comes from the description, so the final section is scrubbed again there.
    scrub(&section(None, false), &media, &secrets)?;
    for store in Store::ALL {
        let files: Vec<&(PathBuf, String)> = media
            .iter()
            .filter(|(_, target)| Store::of(Path::new(target)) == store)
            .collect();
        if files.is_empty() {
            continue;
        }
        let repository = store.checkout(ctx)?;
        replace_media(&repository.path(""), store, pr, sha, &files)?;
        repository.commit_and_push(ctx, &format!("pr {pr} at {}", &sha[..sha.len().min(7)]))?;
    }
    edit_pull_body(ctx, pr, |body| {
        let (body, verdict) = take_verdict(body);
        let covered = match &verdict {
            Some(verdict) => covers(ctx, &verdict.commit, sha, &report.base)?,
            None => false,
        };
        let section = section(verdict.as_ref(), covered);
        scrub(&section, &[], &secrets)?;
        Ok(replace_between(&body, START, END, &section))
    })?;
    println!("evidence for {sha} published to #{pr}");
    Ok(())
}

/// The section without media links, for fork pull requests, whose workflow token cannot push.
/// Makes `files` the only media of pull request `pr` in `store`'s checkout at `root`: only the
/// description's latest run is worth keeping.
fn replace_media(
    root: &Path,
    store: Store,
    pr: u64,
    sha: &str,
    files: &[&(PathBuf, String)],
) -> Result<()> {
    let folder = root.join(store.folder(pr, None));
    if folder.exists() {
        fs::remove_dir_all(&folder)
            .with_context(|| format!("cannot remove {}", folder.display()))?;
    }
    let commit = root.join(store.folder(pr, Some(sha)));
    for (source, target) in files {
        let destination = commit.join(target);
        if let Some(parent) = destination.parent() {
            fs::create_dir_all(parent)?;
        }
        fs::copy(source, &destination)
            .with_context(|| format!("cannot copy {}", source.display()))?;
    }
    Ok(())
}

/// The section's first line: which commit it shows, when it was written and which run wrote it, so
/// a reader can tell whether it is current.
fn provenance(ctx: &Context, sha: &str) -> Result<String> {
    let now = ctx
        .tool(".", "date", &["-u", "+%Y-%m-%d %H:%M"])
        .output_text()?;
    let run = std::env::var("GITHUB_RUN_ID").ok();
    Ok(provenance_line(sha, now.trim(), run.as_deref()))
}

fn provenance_line(sha: &str, now: &str, run: Option<&str>) -> String {
    let short = &sha[..sha.len().min(7)];
    let line = format!(
        "Evidence from [{short}](https://github.com/{REPOSITORY}/commit/{sha}), {now} UTC."
    );
    match run {
        Some(run) => {
            format!("{line} [CI run](https://github.com/{REPOSITORY}/actions/runs/{run}).")
        }
        None => line,
    }
}

pub fn summary(ctx: &Context, sha: &str, inputs: &Inputs) -> Result<String> {
    let runs = stage::staged(&ctx.root, &inputs.results, &known_secrets())?;
    let report = ChangeReport::read(&ctx.root.join(&inputs.report))?;
    let quarantine = Quarantine::load(ctx)?;
    let provenance = provenance(ctx, sha)?;
    let section = render_section(&Section {
        sha,
        provenance: &provenance,
        pr: None,
        runs: &runs,
        quarantine: &quarantine,
        report: &report,
        verdict: None,
        covered: false,
        jobs_failed: inputs.jobs_failed,
    });
    scrub(&section, &[], &known_secrets())?;
    Ok(section)
}

/// The parts of `cargo xtask review report --json` the section shows.
#[derive(Deserialize)]
struct ChangeReport {
    base: String,
    findings: Vec<Finding>,
    tests: TestChanges,
    change_map: Vec<EntityChange>,
    coverage: Coverage,
}

#[derive(Deserialize)]
struct Coverage {
    areas: Vec<AreaCoverage>,
}

#[derive(Deserialize)]
struct AreaCoverage {
    area: String,
    instrumented: Option<usize>,
    covered: Option<usize>,
    notes: Vec<String>,
}

#[derive(Deserialize)]
struct Finding {
    severity: String,
}

#[derive(Deserialize)]
struct TestChanges {
    added: Vec<IgnoredAny>,
    moved: Vec<IgnoredAny>,
    deleted: Vec<IgnoredAny>,
    weakened: Vec<IgnoredAny>,
    rewritten: Vec<IgnoredAny>,
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
    provenance: &'a str,
    /// The pull request the media was uploaded for; `None` when it was not uploaded.
    pr: Option<u64>,
    runs: &'a [(PathBuf, TestRun)],
    quarantine: &'a Quarantine,
    report: &'a ChangeReport,
    verdict: Option<&'a Verdict>,
    /// Whether the verdict read everything in this commit (`covers`).
    covered: bool,
    /// A check or suite job failed, so the results here may not be all of them.
    jobs_failed: bool,
}

/// One glance answers "can this merge?": the headline says it, what needs a person stays open, and
/// everything that only backs the headline up is collapsed.
fn render_section(section: &Section) -> String {
    let mut out = String::new();
    let _ = writeln!(out, "{}\n\n{}\n", headline(section), section.provenance);
    render_attention(&mut out, section);
    render_review(&mut out, section);
    render_recordings(&mut out, section);
    render_coverage(&mut out, &section.report.coverage);
    render_test_changes(&mut out, section);
    render_change_map(&mut out, section);
    out
}

/// The cases that hold the pull request back, each with its verdict.
fn troubled<'a>(section: &'a Section) -> Vec<(&'a TestRun, &'a TestCase, CaseVerdict)> {
    cases(section.runs)
        .map(|(run, case)| (run, case, verdict(section, run, case)))
        .filter(|(_, _, verdict)| *verdict != CaseVerdict::Passed)
        .collect()
}

fn gating_findings(section: &Section) -> usize {
    section
        .report
        .findings
        .iter()
        .filter(|finding| finding.severity == "gate")
        .count()
}

fn headline(section: &Section) -> String {
    let trouble = troubled(section).len();
    let gating = gating_findings(section);
    let passed = cases(section.runs).count() - trouble;
    let total = passed + trouble;
    let state = if total == 0 {
        "**No tests reported**"
    } else if trouble > 0 || gating > 0 || section.jobs_failed {
        "**Not ready**"
    } else if section.covered {
        "**Ready for a maintainer**"
    } else {
        "**Proven, not reviewed**"
    };
    let review = match (section.verdict, section.covered) {
        (None, _) => "no review yet",
        (Some(_), true) => "review covers this commit",
        (Some(_), false) => "review is stale",
    };
    format!("{state}: {passed} of {total} tests proven, {gating} findings to fix, {review}.")
}

/// Everything that is not proven, with its message and recording open.
fn render_attention(out: &mut String, section: &Section) {
    let troubled = troubled(section);
    let gating: Vec<&Finding> = section
        .report
        .findings
        .iter()
        .filter(|finding| finding.severity == "gate")
        .collect();
    if troubled.is_empty() && gating.is_empty() && !section.jobs_failed {
        return;
    }
    let _ = writeln!(out, "### Needs attention");
    if section.jobs_failed {
        let _ = writeln!(
            out,
            "- **A check or suite job failed**, so the results below may be missing some tests. \
             The CI run says which job.\n"
        );
    }
    for (run, case, verdict) in troubled {
        let explained = results::last_failure(case).map_or_else(
            || "no failure message".to_owned(),
            |failure| {
                format!(
                    "{}{}",
                    cell(&failure.message),
                    failure
                        .first_broken
                        .as_ref()
                        .map(|step| format!(" (first broken: {})", cell(step)))
                        .unwrap_or_default()
                )
            },
        );
        let name = match &case.requirement {
            Some(requirement) => format!("{requirement} `{}`", case.id),
            None => format!("`{}`", case.id),
        };
        let _ = writeln!(
            out,
            "- {} {}, {name}: {explained}\n\n  {}\n",
            result(verdict),
            runner_name(&run.runner),
            recording(section, run, case),
        );
    }
    if !gating.is_empty() {
        let _ = writeln!(
            out,
            "- **{} findings to fix**, inline on the changed lines{}.",
            gating.len(),
            section
                .pr
                .map(|pr| format!(
                    " ([code scanning](https://github.com/{REPOSITORY}/pull/{pr}/checks))"
                ))
                .unwrap_or_default()
        );
    }
    out.push('\n');
}

fn render_review(out: &mut String, section: &Section) {
    let short = &section.sha[..section.sha.len().min(7)];
    let _ = writeln!(out, "### Review");
    match section.verdict {
        Some(verdict) => {
            let stale = if section.covered {
                String::new()
            } else {
                format!(
                    "{STALE}reviewed {}, the head is now {short} with other changes.\n",
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
}

/// Every scenario's recording, collapsed: the failing ones are already open above.
fn render_recordings(out: &mut String, section: &Section) {
    let scenarios: Vec<(&TestRun, &TestCase)> = cases(section.runs)
        .filter(|(_, case)| case.requirement.is_some() || results::artifacts(case).next().is_some())
        .collect();
    // A step's own run, one test each, counts under one name with its siblings.
    let mut per_runner: Vec<(String, usize, usize)> = Vec::new();
    for (_, run) in section.runs {
        let name = runner_name(&run.runner);
        let passed = run
            .cases
            .iter()
            .filter(|case| verdict(section, run, case) == CaseVerdict::Passed)
            .count();
        match per_runner.iter_mut().find(|(known, ..)| *known == name) {
            Some((_, proven, total)) => {
                *proven += passed;
                *total += run.cases.len();
            }
            None => per_runner.push((name.to_owned(), passed, run.cases.len())),
        }
    }
    let per_runner: Vec<String> = per_runner
        .into_iter()
        .map(|(name, proven, total)| format!("{name}: {proven} of {total}"))
        .collect();
    let _ = writeln!(
        out,
        "\n<details><summary>Recordings ({} scenarios). Tests proven per suite: {}</summary>\n",
        scenarios.len(),
        per_runner.join(", "),
    );
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
                result(verdict(section, run, case)),
                recording(section, run, case),
            );
        }
    }
    let _ = writeln!(out, "\n</details>");
}

/// Test changes, open when a test lost strength, since that is what a reader must judge.
fn render_test_changes(out: &mut String, section: &Section) {
    let tests = &section.report.tests;
    let suspect = tests.weakened.len() + tests.disabled.len() + tests.deleted.len();
    let _ = writeln!(
        out,
        "\n<details{}><summary>Test changes: {} added, {} moved, {} deleted, {} weakened, {} rewritten, {} disabled</summary>\n\nExpectations rewritten {}. Harness edits {}.\n\n</details>",
        if suspect > 0 { " open" } else { "" },
        tests.added.len(),
        tests.moved.len(),
        tests.deleted.len(),
        tests.weakened.len(),
        tests.rewritten.len(),
        tests.disabled.len(),
        tests.expectations_rewritten.len(),
        tests.harness_edits.len()
    );
}

fn render_change_map(out: &mut String, section: &Section) {
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
    let _ = writeln!(out, "\n</details>");
}

/// How much of the changed code the tests ran, one row per area the change touched. Reported,
/// never gating; the uncovered lines are in the reviewer's report.
fn render_coverage(out: &mut String, coverage: &Coverage) {
    if coverage.areas.is_empty() {
        return;
    }
    let _ = writeln!(
        out,
        "\n<details><summary>Coverage of changed lines</summary>\n\n| Area | Changed lines covered |\n|---|---|"
    );
    let mut notes = Vec::new();
    for area in &coverage.areas {
        let coverage = match (area.covered, area.instrumented) {
            (Some(_), Some(0)) => "no instrumented lines".to_string(),
            (Some(covered), Some(instrumented)) => format!(
                "{covered} of {instrumented} ({}%)",
                covered * 100 / instrumented
            ),
            _ => "not measured".to_string(),
        };
        let _ = writeln!(out, "| {} | {coverage} |", area.area);
        notes.extend(
            area.notes
                .iter()
                .map(|note| format!("{}: {note}", area.area)),
        );
    }
    if !notes.is_empty() {
        let _ = writeln!(out, "\n<sub>{}</sub>", notes.join(". "));
    }
    let _ = writeln!(out, "\n</details>");
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

/// The case's verdict under its run's attempt policy; a case without attempts proves nothing.
fn verdict(section: &Section, run: &TestRun, case: &TestCase) -> CaseVerdict {
    results::verdict(run, case, section.quarantine).unwrap_or(CaseVerdict::Failed)
}

fn result(verdict: CaseVerdict) -> &'static str {
    match verdict {
        CaseVerdict::Passed => "proven",
        CaseVerdict::Failed => "**broken**",
        CaseVerdict::Flaky => "**unreliable**",
        CaseVerdict::Quarantined => "**quarantined**",
    }
}

/// The previews and links of a case's published artifacts, every attempt's, then what broke, as
/// one table cell.
fn recording(section: &Section, run: &TestRun, case: &TestCase) -> String {
    let runner = runner_name(&run.runner);
    let mut parts = Vec::new();
    for (path, artifact) in results::artifacts(case) {
        let Some(pr) = section.pr else {
            parts.push(format!(
                "`{runner}/{}` in the run artifacts",
                path.display()
            ));
            continue;
        };
        let url = |file: &Path| {
            let file = Path::new(runner).join(file);
            Store::of(&file).url(pr, section.sha, &file)
        };
        parts.push(match artifact.kind {
            ArtifactKind::Clip => {
                format!(
                    "![]({}) [full video]({})",
                    url(&stage::preview(&path)),
                    url(&path)
                )
            }
            ArtifactKind::Screenshot => format!("![]({})", url(&path)),
            ArtifactKind::LogExcerpt | ArtifactKind::Spans | ArtifactKind::Unknown(_) => {
                continue;
            }
        });
    }
    if verdict(section, run, case) != CaseVerdict::Passed
        && let Some(failure) = results::last_failure(case)
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

/// Every artifact file of every staged run with its path in the commit folder,
/// `<runner>/<path>`, relative to the folder of the run file.
fn media(runs: &[(PathBuf, TestRun)]) -> Vec<(PathBuf, String)> {
    let mut media = Vec::new();
    for (path, run) in runs {
        let folder = path.parent().unwrap_or(Path::new("."));
        let runner = runner_name(&run.runner);
        for file in published_files(folder, run) {
            media.push((folder.join(&file), format!("{runner}/{}", file.display())));
        }
    }
    media
}

/// The values of [`SECRETS`] that are set, and each long line of them, so a log that printed
/// part of a key is caught too.
pub(super) fn known_secrets() -> Vec<String> {
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

/// Refuses when `text` or a text file of `media` contains a secret.
pub(super) fn scrub(text: &str, media: &[(PathBuf, String)], secrets: &[String]) -> Result<()> {
    let leaked = |bytes: &[u8]| {
        secrets.iter().any(|secret| {
            bytes
                .windows(secret.len())
                .any(|window| window == secret.as_bytes())
        })
    };
    if leaked(text.as_bytes()) {
        bail!("the evidence text contains a secret; nothing leaves the runner");
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
                "{} contains a secret; nothing leaves the runner",
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

pub(crate) fn pull_body(ctx: &Context, pr: u64) -> Result<String> {
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::results::Outcome;
    use crate::test_support::{
        TempRoot, empty_change_report, failed, raw_failed_run, requirement_run,
    };

    const SECRET: &str = "ghp_0123456789abcdefghij";

    #[test]
    fn only_the_managed_section_is_replaced() {
        let body = format!("A{START}old{END}B");
        assert_eq!(
            replace_between(&body, START, END, "new"),
            format!("A{START}\nnew\n{END}B")
        );
    }

    #[test]
    fn publishing_again_does_not_grow_the_description() {
        let once = replace_between("Summary", START, END, "new");
        assert_eq!(replace_between(&once, START, END, "new"), once);
    }

    #[test]
    fn a_description_without_the_section_gets_it_appended() {
        assert_eq!(
            replace_between("Summary\n\n", START, END, "new"),
            format!("Summary\n\n{START}\nnew\n{END}\n")
        );
    }

    #[test]
    fn a_section_holding_a_secret_is_refused() {
        let section = format!("| case | log: token {SECRET} |");
        let error = scrub(&section, &[], &[SECRET.to_owned()]).unwrap_err();
        assert!(error.to_string().contains("contains a secret"));
    }

    #[test]
    fn a_text_artifact_holding_a_secret_is_refused() {
        let dir = tempfile::tempdir().unwrap();
        let log = dir.path().join("case.log");
        fs::write(&log, format!("authorization: {SECRET}\n")).unwrap();
        let media = [(log, "case.log".to_owned())];
        let error = scrub("clean", &media, &[SECRET.to_owned()]).unwrap_err();
        assert!(error.to_string().contains("case.log contains a secret"));
    }

    #[test]
    fn a_publish_of_raw_results_uploads_only_the_staged_clips_and_screenshots() {
        let root = TempRoot::new();
        raw_failed_run(&root, ".xtask/results/panel");

        let runs = stage::staged(&root.path(""), Path::new(".xtask/results"), &[]).unwrap();
        let uploaded = media(&runs);

        assert_eq!(
            uploaded
                .iter()
                .map(|(_, target)| target.as_str())
                .collect::<Vec<_>>(),
            [
                "panel/attempts/1/clips/conn.mp4",
                "panel/attempts/1/clips/conn.webp",
                "panel/attempts/1/screenshots/CONN-1/failure.png",
            ]
        );
        assert!(
            uploaded
                .iter()
                .all(|(source, _)| source.starts_with(root.path(".xtask/public")))
        );
    }

    #[test]
    fn a_clip_plays_from_the_site_and_its_preview_shows_from_the_branch() {
        let clip = Path::new("panel/attempts/1/clips/conn.mp4");
        let preview = stage::preview(clip);

        assert_eq!(
            Store::of(clip).url(546, "8f93ae1abc", clip),
            "https://docs.typewritermc.com/evidence/pr/546/8f93ae1/panel/attempts/1/clips/conn.mp4"
        );
        assert_eq!(
            Store::of(&preview).url(546, "8f93ae1abc", &preview),
            format!(
                "https://raw.githubusercontent.com/{REPOSITORY}/evidence/pr/546/8f93ae1/panel/attempts/1/clips/conn.webp"
            )
        );
    }

    #[test]
    fn a_new_run_replaces_the_pull_requests_older_media_and_no_other() {
        let root = TempRoot::new();
        root.write("site/evidence/pr/546/old/panel/old.mp4", "old");
        root.write("site/evidence/pr/7/keep/panel/other.mp4", "other");
        root.write("site/branches/pr-546/index.html", "docs preview");
        root.write("new.mp4", "new");
        let file = (root.path("new.mp4"), "panel/new.mp4".to_owned());

        replace_media(&root.path("site"), Store::Videos, 546, "abc1234", &[&file]).unwrap();

        assert!(!root.path("site/evidence/pr/546/old").exists());
        assert!(
            root.path("site/evidence/pr/546/abc1234/panel/new.mp4")
                .exists()
        );
        assert!(
            root.path("site/evidence/pr/7/keep/panel/other.mp4")
                .exists()
        );
        assert!(root.path("site/branches/pr-546/index.html").exists());
    }

    #[test]
    fn the_section_says_which_commit_and_run_it_shows_and_when() {
        assert_eq!(
            provenance_line("8f93ae1abc", "2026-11-02 10:14", Some("41415929881")),
            format!(
                "Evidence from [8f93ae1](https://github.com/{REPOSITORY}/commit/8f93ae1abc), 2026-11-02 10:14 UTC. [CI run](https://github.com/{REPOSITORY}/actions/runs/41415929881)."
            )
        );
    }

    #[test]
    fn a_proven_and_reviewed_change_leads_with_ready_and_hides_its_recordings() {
        let runs = [(
            PathBuf::from("panel"),
            requirement_run("a user joins", "JOIN-1", Outcome::Passed),
        )];
        let verdict = Verdict {
            commit: "abcdef1234".to_owned(),
            text: "Looks right.".to_owned(),
        };
        let section = render_section(&Section {
            sha: "abcdef1234",
            provenance: "Evidence from abcdef1.",
            pr: None,
            runs: &runs,
            quarantine: &Quarantine::default(),
            report: &serde_json::from_value(empty_change_report()).unwrap(),
            verdict: Some(&verdict),
            covered: true,
            jobs_failed: false,
        });
        assert!(section.starts_with("**Ready for a maintainer**: 1 of 1 tests proven"));
        assert!(!section.contains("Needs attention"));
        assert!(section.contains("<details><summary>Recordings (1 scenarios)"));
    }

    #[test]
    fn a_failed_job_is_not_ready_even_when_every_reported_test_passed() {
        let runs = [(
            PathBuf::from("panel"),
            requirement_run("a user joins", "JOIN-1", Outcome::Passed),
        )];
        let section = render_section(&Section {
            sha: "1111111",
            provenance: "Evidence from a run that lost a suite.",
            pr: None,
            runs: &runs,
            quarantine: &Quarantine::default(),
            report: &serde_json::from_value(empty_change_report()).unwrap(),
            verdict: None,
            covered: false,
            jobs_failed: true,
        });

        assert!(section.starts_with("**Not ready**"), "{section}");
        assert!(section.contains("A check or suite job failed"), "{section}");
    }

    #[test]
    fn a_broken_scenario_leads_with_not_ready_and_shows_above_every_fold() {
        let runs = [(
            PathBuf::from("panel"),
            requirement_run("a user joins", "JOIN-1", failed("the realm never appeared")),
        )];
        let section = render_section(&Section {
            sha: "1111111",
            provenance: "Evidence from a broken run.",
            pr: None,
            runs: &runs,
            quarantine: &Quarantine::default(),
            report: &serde_json::from_value(empty_change_report()).unwrap(),
            verdict: None,
            covered: false,
            jobs_failed: false,
        });
        assert!(section.starts_with("**Not ready**: 0 of 1 tests proven"));
        let attention = section.find("### Needs attention").unwrap();
        let first_fold = section.find("<details>").unwrap();
        let message = section.find("the realm never appeared").unwrap();
        assert!(attention < message && message < first_fold);
    }

    #[test]
    fn a_verdict_on_other_changes_is_marked_stale() {
        let runs = [(
            PathBuf::from("panel"),
            requirement_run("a user joins", "JOIN-1", Outcome::Passed),
        )];
        let verdict = Verdict {
            commit: "1234567".to_owned(),
            text: "Looks right.".to_owned(),
        };
        let section = render_section(&Section {
            sha: "2222222",
            provenance: "Evidence from a later push.",
            pr: None,
            runs: &runs,
            quarantine: &Quarantine::default(),
            report: &serde_json::from_value(empty_change_report()).unwrap(),
            verdict: Some(&verdict),
            covered: false,
            jobs_failed: false,
        });
        assert!(section.starts_with("**Proven, not reviewed**"));
        assert!(section.contains("review is stale"));
        assert!(section.contains("**Stale**: reviewed 1234567"));
    }

    #[test]
    fn clean_text_is_published() {
        let dir = tempfile::tempdir().unwrap();
        let log = dir.path().join("case.log");
        fs::write(&log, "all good\n").unwrap();
        let media = [(log, "case.log".to_owned())];
        assert!(scrub("clean", &media, &[SECRET.to_owned()]).is_ok());
    }
}
