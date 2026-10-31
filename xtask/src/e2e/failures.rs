//! The local folder a failed attempt leaves: `failures/<case>/` inside the attempt's folder of
//! the suite's evidence folder (`attempts/<n>/` for a scenario, `journey/` for the sign in
//! journey), holding what the screen showed (screenshots), what the panel, the drive and
//! every stack service logged during the attempt, and every span of the traces the panel started
//! in it. None of it is published: [`ArtifactKind::published`] keeps logs and spans off the
//! evidence branch, and CI leaves the failure folders out of its upload.
//!
//! Log lines and panel root spans are matched to an attempt by time, which works because
//! scenarios run one at a time. Log windows widen by [`LOG_SLACK_MILLIS`] on each side, since
//! toxiproxy stamps whole seconds; span windows do not.

use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result};
use serde_json::Value;

use super::attempt_folder;
use crate::evidence::file_name;
use crate::results::{Artifact, ArtifactKind, Outcome, TestRun};

/// How far a log window reaches past the attempt's span on each side.
const LOG_SLACK_MILLIS: i64 = 1_000;
/// The service whose root spans start an attempt's traces.
const PANEL_SERVICE: &str = "typewriter-panel";
/// The spans file in a failure folder.
const SPANS: &str = "spans.otlp.jsonl";
/// The drive's stamped output in an attempt's folder.
pub const DRIVE_LOG: &str = "drive.log";

/// What the run's stack leaves for failure folders, copied out before the stack state is reset.
/// On the CI cluster target that stack is the organization and Realm host on top of the cluster.
pub struct StackEvidence {
    /// Every service log.
    pub logs: Vec<PathBuf>,
    /// The collector's `traces.jsonl`, complete once the stack stopped.
    pub traces: PathBuf,
}

/// For each failed attempt in `run`, whose evidence lies under `evidence` (the suite folder),
/// fills `failures/<case>/` in the attempt's folder ([`attempt_folder`]): copies of its screenshots and panel log, the attempt
/// folder's drive log and every service log of `stack` cut to the attempt's span, and every span
/// of the traces whose panel root started inside that span. The cut logs and the spans join the
/// attempt's artifacts, with paths relative to `evidence` like every other artifact. A passing
/// attempt, or one without a span, gets no folder.
pub fn collect(evidence: &Path, run: &mut TestRun, stack: &StackEvidence) -> Result<()> {
    let traces = Traces::read(&stack.traces)?;
    for case in &mut run.cases {
        let folders: Vec<PathBuf> = (1..=case.attempts.len())
            .map(|n| attempt_folder(case, u32::try_from(n).unwrap_or(u32::MAX)))
            .collect();
        for (attempt, folder) in case.attempts.iter_mut().zip(&folders) {
            let (Outcome::Failed(_), Some(span)) = (&attempt.outcome, &attempt.span) else {
                continue;
            };
            let window = (span.start_millis, span.end_millis);
            let dir = folder.join("failures").join(file_name(&case.id));
            let absolute = evidence.join(&dir);
            fs::create_dir_all(&absolute)
                .with_context(|| format!("cannot create {}", absolute.display()))?;
            for artifact in &attempt.artifacts {
                if matches!(
                    artifact.kind,
                    ArtifactKind::Screenshot | ArtifactKind::LogExcerpt
                ) {
                    copy_into(&evidence.join(&artifact.path), &absolute)?;
                }
            }
            let logs = (window.0 - LOG_SLACK_MILLIS, window.1 + LOG_SLACK_MILLIS);
            let drive = evidence.join(folder).join(DRIVE_LOG);
            for log in stack.logs.iter().cloned().chain([drive]) {
                let file = dir.join(log.file_name().context("a log without a file name")?);
                let text = fs::read_to_string(&log)
                    .with_context(|| format!("cannot read {}", log.display()))?;
                fs::write(evidence.join(&file), cut_lines(&text, logs))?;
                attempt
                    .artifacts
                    .push(artifact(ArtifactKind::LogExcerpt, &file));
            }
            let file = dir.join(SPANS);
            let spans = traces.rooted_in(PANEL_SERVICE, window).to_jsonl();
            fs::write(evidence.join(&file), spans)?;
            attempt.artifacts.push(artifact(ArtifactKind::Spans, &file));
        }
    }
    Ok(())
}

fn artifact(kind: ArtifactKind, path: &Path) -> Artifact {
    Artifact {
        kind,
        path: path.display().to_string(),
        _unrecognized: None,
    }
}

/// Copies `file` into `dir` under its own name.
fn copy_into(file: &Path, dir: &Path) -> Result<()> {
    let name = file
        .file_name()
        .context("an artifact without a file name")?;
    fs::copy(file, dir.join(name))
        .with_context(|| format!("cannot copy {} into {}", file.display(), dir.display()))?;
    Ok(())
}

/// Keeps the lines whose time falls in `window`, both ends included. A line without its own time
/// (a continuation, a stack trace, pretty printed JSON) takes the previous line's; lines before
/// the first timed line are dropped.
fn cut_lines(text: &str, window: (i64, i64)) -> String {
    let mut time = None;
    let mut kept = String::new();
    for line in text.lines() {
        time = line_millis(line).or(time);
        if time.is_some_and(|time| window.0 <= time && time <= window.1) {
            kept.push_str(line);
            kept.push('\n');
        }
    }
    kept
}

/// The time of a log line in Unix milliseconds: an RFC 3339 prefix after any ANSI codes
/// (tracing, the Realm, the drive log), or the `time` field of a JSON line (toxiproxy, second
/// precision).
fn line_millis(line: &str) -> Option<i64> {
    let line = without_ansi(line);
    let line = line.trim_start();
    if line.starts_with('{') {
        let value: Value = serde_json::from_str(line).ok()?;
        return rfc3339_millis(value.get("time")?.as_str()?);
    }
    rfc3339_millis(line)
}

/// `line` without its ANSI escape sequences (`ESC [ ... letter`).
fn without_ansi(line: &str) -> String {
    let mut plain = String::with_capacity(line.len());
    let mut chars = line.chars();
    while let Some(c) = chars.next() {
        if c == '\u{1b}' {
            if chars.next() == Some('[') {
                for c in chars.by_ref() {
                    if c.is_ascii_alphabetic() {
                        break;
                    }
                }
            }
        } else {
            plain.push(c);
        }
    }
    plain
}

/// The Unix milliseconds of the RFC 3339 time `text` starts with
/// (`2026-10-31T07:26:26.946521Z`, `2026-10-31T16:26:21.160+0900`), ignoring what follows.
fn rfc3339_millis(text: &str) -> Option<i64> {
    let bytes = text.as_bytes();
    let number = |from: usize, to: usize| -> Option<i64> {
        let digits = std::str::from_utf8(bytes.get(from..to)?).ok()?;
        digits
            .bytes()
            .all(|byte| byte.is_ascii_digit())
            .then(|| digits.parse().ok())
            .flatten()
    };
    let separators = [(4, b'-'), (7, b'-'), (10, b'T'), (13, b':'), (16, b':')];
    if separators
        .iter()
        .any(|(at, separator)| bytes.get(*at) != Some(separator))
    {
        return None;
    }
    let days = days_from_civil(number(0, 4)?, number(5, 7)?, number(8, 10)?);
    let seconds = number(11, 13)? * 3600 + number(14, 16)? * 60 + number(17, 19)?;
    let mut at = 19;
    let mut millis = 0;
    if bytes.get(at) == Some(&b'.') {
        let digits = bytes[at + 1..]
            .iter()
            .take_while(|byte| byte.is_ascii_digit())
            .count();
        let fraction = &text[at + 1..at + 1 + digits];
        millis = format!("{fraction:0<3}")[..3].parse().ok()?;
        at += 1 + digits;
    }
    let offset = match bytes.get(at)? {
        b'Z' | b'z' => 0,
        sign @ (b'+' | b'-') => {
            let minutes = number(at + 1, at + 3)? * 60
                + match bytes.get(at + 3) {
                    Some(b':') => number(at + 4, at + 6)?,
                    _ => number(at + 3, at + 5)?,
                };
            if *sign == b'+' { minutes } else { -minutes }
        }
        _ => return None,
    };
    Some((days * 86_400 + seconds - offset * 60) * 1000 + millis)
}

/// `millis` as an RFC 3339 UTC time with milliseconds, the stamp [`line_millis`] reads back.
pub fn rfc3339(millis: i64) -> String {
    let (days, rest) = (millis.div_euclid(86_400_000), millis.rem_euclid(86_400_000));
    let (year, month, day) = civil_from_days(days);
    format!(
        "{year:04}-{month:02}-{day:02}T{:02}:{:02}:{:02}.{:03}Z",
        rest / 3_600_000,
        rest / 60_000 % 60,
        rest / 1000 % 60,
        rest % 1000
    )
}

/// Days since 1970-01-01 of a proleptic Gregorian date (Howard Hinnant's `days_from_civil`).
fn days_from_civil(year: i64, month: i64, day: i64) -> i64 {
    let year = if month <= 2 { year - 1 } else { year };
    let era = year.div_euclid(400);
    let year_of_era = year - era * 400;
    let day_of_year = (153 * ((month + 9) % 12) + 2) / 5 + day - 1;
    let day_of_era = year_of_era * 365 + year_of_era / 4 - year_of_era / 100 + day_of_year;
    era * 146_097 + day_of_era - 719_468
}

/// The date `days` after 1970-01-01, the inverse of [`days_from_civil`].
fn civil_from_days(days: i64) -> (i64, i64, i64) {
    let days = days + 719_468;
    let era = days.div_euclid(146_097);
    let day_of_era = days - era * 146_097;
    let year_of_era =
        (day_of_era - day_of_era / 1460 + day_of_era / 36_524 - day_of_era / 146_096) / 365;
    let day_of_year = day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    let shifted_month = (5 * day_of_year + 2) / 153;
    let day = day_of_year - (153 * shifted_month + 2) / 5 + 1;
    let month = if shifted_month < 10 {
        shifted_month + 3
    } else {
        shifted_month - 9
    };
    let year = year_of_era + era * 400 + i64::from(month <= 2);
    (year, month, day)
}

/// The collector's file exporter output: one OTLP JSON export request per line.
struct Traces(Vec<Value>);

impl Traces {
    fn read(path: &Path) -> Result<Self> {
        // A stack whose collector received nothing never created the file.
        let text = match fs::read_to_string(path) {
            Ok(text) => text,
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => String::new(),
            Err(error) => {
                return Err(error).with_context(|| format!("cannot read {}", path.display()));
            }
        };
        let requests = text
            .lines()
            .filter(|line| !line.trim().is_empty())
            .map(serde_json::from_str)
            .collect::<Result<_, _>>()
            .with_context(|| format!("{} is not OTLP JSON", path.display()))?;
        Ok(Self(requests))
    }

    /// Every span of the traces whose root span from `service` started in `window` (Unix
    /// milliseconds, both ends included), in the requests' shape. Spans of other services come
    /// along through the trace id the root propagated.
    fn rooted_in(&self, service: &str, window: (i64, i64)) -> Self {
        let mut traces = BTreeSet::new();
        for request in &self.0 {
            for resource in array(request, "resourceSpans") {
                if service_name(resource) != Some(service) {
                    continue;
                }
                for scope in array(resource, "scopeSpans") {
                    for span in array(scope, "spans") {
                        let root = span
                            .get("parentSpanId")
                            .and_then(Value::as_str)
                            .is_none_or(str::is_empty);
                        let started = nanos(span.get("startTimeUnixNano")).map(|n| n / 1_000_000);
                        if root && started.is_some_and(|at| window.0 <= at && at <= window.1) {
                            traces.extend(span.get("traceId").and_then(Value::as_str));
                        }
                    }
                }
            }
        }
        let mut kept = Vec::new();
        for request in &self.0 {
            let mut request = request.clone();
            retain(&mut request, "resourceSpans", |resource| {
                retain(resource, "scopeSpans", |scope| {
                    retain(scope, "spans", |span| {
                        span.get("traceId")
                            .and_then(Value::as_str)
                            .is_some_and(|id| traces.contains(id))
                    })
                })
            });
            if !array(&request, "resourceSpans").is_empty() {
                kept.push(request);
            }
        }
        Self(kept)
    }

    fn to_jsonl(&self) -> String {
        self.0
            .iter()
            .map(|request| format!("{request}\n"))
            .collect()
    }
}

fn array<'a>(value: &'a Value, key: &str) -> &'a [Value] {
    value
        .get(key)
        .and_then(Value::as_array)
        .map_or(&[], Vec::as_slice)
}

/// Keeps the items of `value[key]` that `keep` accepts; returns whether any are left.
fn retain(value: &mut Value, key: &str, mut keep: impl FnMut(&mut Value) -> bool) -> bool {
    let Some(items) = value.get_mut(key).and_then(Value::as_array_mut) else {
        return false;
    };
    items.retain_mut(|item| keep(item));
    !items.is_empty()
}

fn service_name(resource: &Value) -> Option<&str> {
    array(resource.get("resource")?, "attributes")
        .iter()
        .find(|attribute| attribute.get("key").and_then(Value::as_str) == Some("service.name"))?
        .get("value")?
        .get("stringValue")?
        .as_str()
}

/// OTLP JSON writes 64 bit integers as strings; numbers are read too.
fn nanos(value: Option<&Value>) -> Option<i64> {
    match value? {
        Value::String(text) => text.parse().ok(),
        value => value.as_i64(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{
        TempRoot, failed_attempt, file_names, otlp_request, otlp_spans, passed_attempt, run_of,
    };

    const ATTEMPT: (i64, i64) = (1_793_431_600_000, 1_793_431_610_000);

    #[test]
    fn a_tracing_line_after_ansi_codes_has_its_rfc3339_time() {
        let line = "\u{1b}[2m2026-10-31T07:26:26.946521Z\u{1b}[0m \u{1b}[32m INFO\u{1b}[0m ready";
        assert_eq!(line_millis(line), Some(1_793_431_586_946));
    }

    #[test]
    fn a_line_with_an_offset_is_read_as_utc() {
        assert_eq!(
            line_millis("2026-10-31T16:26:26.946+0900\tinfo\tstarted"),
            line_millis("2026-10-31T07:26:26.946Z")
        );
        assert_eq!(
            line_millis("2026-10-31T16:26:26.946+09:00 started"),
            Some(1_793_431_586_946)
        );
    }

    #[test]
    fn a_json_line_has_the_time_of_its_time_field() {
        let line =
            r#"{"level":"info","time":"2026-10-31T07:26:21Z","message":"Starting Toxiproxy"}"#;
        assert_eq!(line_millis(line), Some(1_793_431_581_000));
    }

    #[test]
    fn a_line_without_a_leading_time_has_none() {
        assert_eq!(line_millis("    at com.example.Main.run(Main.kt:12)"), None);
        assert_eq!(line_millis("16:26:59.187 [main] DEBUG connection"), None);
        assert_eq!(line_millis(r#"{"message":"no time"}"#), None);
    }

    #[test]
    fn an_arrival_stamp_reads_back_as_the_same_millisecond() {
        let stamp = rfc3339(1_793_431_586_946);
        assert_eq!(stamp, "2026-10-31T07:26:26.946Z");
        assert_eq!(
            line_millis(&format!("{stamp} 00:01 +1: CONN-1")),
            Some(1_793_431_586_946)
        );
        assert_eq!(rfc3339(951_782_400_000), "2000-02-29T00:00:00.000Z");
    }

    #[test]
    fn a_cut_keeps_the_lines_inside_the_window_with_their_continuations() {
        let log = "\
WARNING: before any time
2026-10-31T07:26:39.999Z INFO before
2026-10-31T07:26:40.000Z ERROR inside
    at Main.run(Main.kt:12)
2026-10-31T07:26:50.000Z INFO last inside
2026-10-31T07:26:50.001Z INFO after
    at Main.after(Main.kt:20)
";
        assert_eq!(
            cut_lines(log, ATTEMPT),
            "\
2026-10-31T07:26:40.000Z ERROR inside
    at Main.run(Main.kt:12)
2026-10-31T07:26:50.000Z INFO last inside
"
        );
    }

    #[test]
    fn spans_are_the_whole_traces_whose_panel_root_started_in_the_window() {
        let inside = (ATTEMPT.0 + 5) * 1_000_000;
        let before = (ATTEMPT.0 - 5) * 1_000_000;
        let traces = Traces(vec![
            otlp_request(
                "typewriter-panel",
                &[("a", "1", "", inside), ("b", "2", "", before)],
            ),
            otlp_request(
                "typewriter-backend",
                &[("a", "3", "1", before), ("b", "4", "2", inside)],
            ),
            // A backend root inside the window starts no attempt trace.
            otlp_request("typewriter-backend", &[("c", "5", "", inside)]),
        ]);

        let kept = traces.rooted_in("typewriter-panel", ATTEMPT);

        assert_eq!(
            otlp_spans(&kept.to_jsonl()),
            ["typewriter-panel/1", "typewriter-backend/3"]
        );
    }

    #[test]
    fn a_failed_attempt_leaves_its_screenshots_cut_logs_and_spans_in_one_folder() {
        let root = TempRoot::new();
        let evidence = root.dir("panel");
        root.write("panel/attempts/1/screenshots/CONN-1/failure.png", "png");
        root.write("panel/attempts/1/logs/CONN-1/panel.log", "panel");
        root.write(
            "panel/attempts/1/drive.log",
            "2026-10-31T07:26:30.000Z build\n2026-10-31T07:26:45.000Z CONN-1 failed\n",
        );
        root.write(
            "stack/logs/backend.log",
            "2026-10-31T07:26:30.000Z early\n2026-10-31T07:26:41.000Z handled\n",
        );
        root.write(
            "stack/traces.jsonl",
            &format!(
                "{}\n",
                otlp_request(
                    "typewriter-panel",
                    &[("a", "1", "", (ATTEMPT.0 + 1) * 1_000_000)]
                )
            ),
        );
        let stack = StackEvidence {
            logs: vec![root.path("stack/logs/backend.log")],
            traces: root.path("stack/traces.jsonl"),
        };
        let mut run = run_of(
            "[CONN-1] Reconnects",
            vec![failed_attempt(
                ATTEMPT,
                &[
                    (
                        ArtifactKind::Screenshot,
                        "attempts/1/screenshots/CONN-1/failure.png",
                    ),
                    (ArtifactKind::LogExcerpt, "attempts/1/logs/CONN-1/panel.log"),
                ],
            )],
        );

        collect(&evidence, &mut run, &stack).unwrap();

        let folder = "attempts/1/failures/_CONN-1__Reconnects";
        let files = file_names(&evidence.join(folder));
        assert_eq!(
            files,
            [
                "backend.log",
                "drive.log",
                "failure.png",
                "panel.log",
                "spans.otlp.jsonl"
            ]
        );
        let read = |file: &str| fs::read_to_string(evidence.join(folder).join(file)).unwrap();
        assert_eq!(read("backend.log"), "2026-10-31T07:26:41.000Z handled\n");
        assert_eq!(
            read("drive.log"),
            "2026-10-31T07:26:45.000Z CONN-1 failed\n"
        );
        assert_eq!(
            otlp_spans(&read("spans.otlp.jsonl")),
            ["typewriter-panel/1"]
        );
        let added: Vec<(ArtifactKind, String)> = run.cases[0].attempts[0].artifacts[2..]
            .iter()
            .map(|artifact| (artifact.kind.clone(), artifact.path.clone()))
            .collect();
        assert_eq!(
            added,
            [
                (ArtifactKind::LogExcerpt, format!("{folder}/backend.log")),
                (ArtifactKind::LogExcerpt, format!("{folder}/drive.log")),
                (ArtifactKind::Spans, format!("{folder}/spans.otlp.jsonl")),
            ]
        );
    }

    #[test]
    fn a_failed_journey_leaves_its_failure_folder_and_its_own_drive_log_in_the_journey_folder() {
        let root = TempRoot::new();
        let evidence = root.dir("full-panel-web");
        root.write(
            "full-panel-web/attempts/1/drive.log",
            "2026-10-31T07:26:45.000Z a scenario's drive\n",
        );
        root.write(
            "full-panel-web/journey/drive.log",
            "2026-10-31T07:26:45.000Z the journey's drive\n",
        );
        root.write(
            "full-panel-web/journey/screenshots/AUTH-2/failure.png",
            "png",
        );
        let stack = StackEvidence {
            logs: Vec::new(),
            traces: root.path("stack/traces.jsonl"),
        };
        let mut run = run_of(
            "[AUTH-2] Signs in",
            vec![failed_attempt(
                ATTEMPT,
                &[(
                    ArtifactKind::Screenshot,
                    "journey/screenshots/AUTH-2/failure.png",
                )],
            )],
        );
        run.cases[0].requirement = Some(super::super::JOURNEY.to_owned());

        collect(&evidence, &mut run, &stack).unwrap();

        let folder = evidence.join("journey/failures/_AUTH-2__Signs_in");
        assert_eq!(
            file_names(&folder),
            ["drive.log", "failure.png", "spans.otlp.jsonl"]
        );
        assert_eq!(
            fs::read_to_string(folder.join("drive.log")).unwrap(),
            "2026-10-31T07:26:45.000Z the journey's drive\n"
        );
        assert!(!evidence.join("attempts/1/failures").exists());
    }

    #[test]
    fn a_passing_attempt_gets_no_failure_folder() {
        let root = TempRoot::new();
        let evidence = root.dir("panel");
        root.write("panel/attempts/1/drive.log", "");
        root.write("panel/attempts/2/drive.log", "");
        let stack = StackEvidence {
            logs: Vec::new(),
            traces: root.path("stack/traces.jsonl"),
        };
        let mut run = run_of(
            "[CONN-1] Reconnects",
            vec![failed_attempt(ATTEMPT, &[]), passed_attempt(ATTEMPT)],
        );

        collect(&evidence, &mut run, &stack).unwrap();

        assert!(evidence.join("attempts/1/failures").exists());
        assert!(!evidence.join("attempts/2/failures").exists());
        assert!(run.cases[0].attempts[1].artifacts.is_empty());
    }
}
