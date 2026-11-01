//! Builders, fakes and assertions the harness's unit tests share. Test modules hold only their
//! test cases; every piece of setup they need lives here.

use std::collections::BTreeSet;
use std::fs;
use std::io::{Read as _, Write as _};
use std::net::{Ipv4Addr, TcpListener};
use std::os::unix::process::ExitStatusExt as _;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus};
use std::thread;
use std::time::Duration;

use anyhow::Result;
use clap::ValueEnum as _;

use crate::e2e::E2eArgs;
use crate::graph::{Area, Run, Step};
use crate::hooks::commit_msg::Scopes;
use crate::results::{
    Artifact, ArtifactKind, Attempt, AttemptPolicy, Failure, Outcome, Quarantine, TestCase, TestRun,
};
use crate::skirout::base::harness::v1::test_run::{Runner, Span};
use crate::stack::StackRecord;
use crate::{CommandExt as _, Context};

/// A throwaway repository root: a temporary directory and the [`Context`] that resolves against
/// it. The directory is removed when the root is dropped.
pub struct TempRoot {
    dir: tempfile::TempDir,
    pub ctx: Context,
}

impl TempRoot {
    /// An empty root, not yet a Git repository.
    pub fn new() -> Self {
        let dir = tempfile::tempdir().unwrap();
        let ctx = Context {
            root: dir.path().to_owned(),
        };
        Self { dir, ctx }
    }

    /// The absolute path of `relative` inside the root.
    pub fn path(&self, relative: &str) -> PathBuf {
        self.dir.path().join(relative)
    }

    /// Creates the directory `relative`, with its parents, and returns its path.
    pub fn dir(&self, relative: &str) -> PathBuf {
        let path = self.path(relative);
        fs::create_dir_all(&path).unwrap();
        path
    }

    /// Writes `contents` to the file `relative`, creating its parent directories.
    pub fn write(&self, relative: &str, contents: &str) {
        let path = self.path(relative);
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(path, contents).unwrap();
    }

    /// Runs `git args` in the root under a fixed identity without signing, and returns its
    /// output. Panics when Git fails.
    pub fn git(&self, args: &[&str]) -> String {
        self.ctx
            .tool(
                ".",
                "git",
                &[
                    "-c",
                    "user.name=t",
                    "-c",
                    "user.email=t@t",
                    "-c",
                    "commit.gpgsign=false",
                ],
            )
            .args(args)
            .output_text()
            .unwrap()
    }

    /// Records an empty commit with `message` on the checked out branch.
    pub fn commit(&self, message: &str) {
        self.git(&["commit", "--quiet", "--allow-empty", "-m", message]);
    }
}

/// The message of `result`'s error. Panics when `result` succeeded.
pub fn refusal<T>(result: Result<T>) -> String {
    match result {
        Ok(_) => panic!("expected a refusal, but it succeeded"),
        Err(error) => error.to_string(),
    }
}

/// A components run with one attempt of each of `cases`, as a runner reports one attempt.
pub fn run(cases: &[(&str, Outcome)]) -> TestRun {
    TestRun {
        runner: Runner::Components,
        attempt_policy: AttemptPolicy::Exactly(1),
        cases: cases
            .iter()
            .map(|(id, outcome)| case(id, std::slice::from_ref(outcome)))
            .collect(),
        ..TestRun::default()
    }
}

/// A run reporting one attempt of the case `id`, which proves `requirement`, with `outcome`.
pub fn requirement_run(requirement: &str, id: &str, outcome: Outcome) -> TestRun {
    let mut reported = run(&[(id, outcome)]);
    reported.cases[0].requirement = Some(requirement.to_owned());
    reported
}

/// A components run under `policy` whose cases made `attempts`, in order.
pub fn attempted(policy: AttemptPolicy, attempts: &[Outcome]) -> TestRun {
    TestRun {
        runner: Runner::Components,
        attempt_policy: policy,
        cases: vec![case("a", attempts)],
        ..TestRun::default()
    }
}

/// The case `id` with one attempt per outcome, in order.
pub fn case(id: &str, outcomes: &[Outcome]) -> TestCase {
    TestCase {
        id: id.to_owned(),
        attempts: outcomes
            .iter()
            .map(|outcome| Attempt {
                outcome: outcome.clone(),
                ..Attempt::default()
            })
            .collect(),
        ..TestCase::default()
    }
}

/// The outcomes of the attempts of `run`'s case `id`. Panics when the run has no such case.
pub fn outcomes(run: &TestRun, id: &str) -> Vec<Outcome> {
    let case = run.cases.iter().find(|case| case.id == id).unwrap();
    case.attempts.iter().map(|a| a.outcome.clone()).collect()
}

/// An outcome a newer runner wrote that this build does not know.
pub fn unknown() -> Outcome {
    Outcome::Unknown(Default::default())
}

/// What [`report`](crate::results::report) writes for `run`, pointing at `results/panel`, and
/// whether it passed.
pub fn report_text(run: &TestRun, quarantine: &Quarantine) -> (Result<()>, String) {
    let mut out = Vec::new();
    let result =
        crate::results::report(run, quarantine, Some(Path::new("results/panel")), &mut out);
    (result, String::from_utf8(out).unwrap())
}

/// `cargo xtask e2e args` as the command line parses it.
pub fn e2e_args(args: &[&str]) -> Result<E2eArgs, clap::Error> {
    #[derive(clap::Parser)]
    struct Command {
        #[command(flatten)]
        args: E2eArgs,
    }
    let line = std::iter::once("e2e").chain(args.iter().copied());
    <Command as clap::Parser>::try_parse_from(line).map(|command| command.args)
}

/// A failure with `message`.
pub fn failed(message: &str) -> Outcome {
    Outcome::Failed(Box::new(Failure {
        message: message.to_owned(),
        ..Failure::default()
    }))
}

/// The message of a failed `outcome`. Panics on any other outcome.
pub fn failure_message(outcome: &Outcome) -> &str {
    match outcome {
        Outcome::Failed(failure) => &failure.message,
        _ => panic!("the case did not fail"),
    }
}

/// A quarantine holding the case `id`.
pub fn quarantining(id: &str) -> Quarantine {
    toml::from_str(&format!(
        "[[case]]\nid = \"{id}\"\nreason = \"times out on CI\"\nissue = 7\n"
    ))
    .unwrap()
}

/// A runner whose first attempt reports `first` and that must never run a second attempt.
pub fn once(first: TestRun) -> impl FnMut(u32, &[String]) -> Result<TestRun> {
    move |n, _| {
        assert_eq!(n, 1, "nothing should run again");
        Ok(first.clone())
    }
}

/// A run of the one case `id` with `attempts`.
pub fn run_of(id: &str, attempts: Vec<Attempt>) -> TestRun {
    TestRun {
        runner: Runner::Panel,
        cases: vec![TestCase {
            id: id.to_owned(),
            attempts,
            ..TestCase::default()
        }],
        ..TestRun::default()
    }
}

/// A failed attempt over `span` (Unix milliseconds) with `artifacts` of these kinds and paths.
pub fn failed_attempt(span: (i64, i64), artifacts: &[(ArtifactKind, &str)]) -> Attempt {
    Attempt {
        outcome: failed("boom"),
        span: Some(Span {
            start_millis: span.0,
            end_millis: span.1,
            ..Span::default()
        }),
        artifacts: artifacts
            .iter()
            .map(|(kind, path)| Artifact {
                kind: kind.clone(),
                path: (*path).to_owned(),
                ..Artifact::default()
            })
            .collect(),
        ..Attempt::default()
    }
}

/// A passing attempt over `span` (Unix milliseconds) without artifacts.
pub fn passed_attempt(span: (i64, i64)) -> Attempt {
    Attempt {
        outcome: Outcome::Passed,
        ..failed_attempt(span, &[])
    }
}

/// One OTLP JSON export request from `service` holding `spans`, each
/// `(trace id, span id, parent span id, start in Unix nanoseconds)`, in the collector's shape.
pub fn otlp_request(service: &str, spans: &[(&str, &str, &str, i64)]) -> serde_json::Value {
    let spans: Vec<_> = spans
        .iter()
        .map(|(trace, span, parent, start)| {
            serde_json::json!({
                "traceId": trace,
                "spanId": span,
                "parentSpanId": parent,
                "name": "work",
                "startTimeUnixNano": start.to_string(),
            })
        })
        .collect();
    serde_json::json!({ "resourceSpans": [{
        "resource": { "attributes": [
            { "key": "service.name", "value": { "stringValue": service } },
        ] },
        "scopeSpans": [{ "scope": { "name": "test" }, "spans": spans }],
    }] })
}

/// Every span in `jsonl` (OTLP JSON export requests, one per line) as `<service>/<span id>`, in
/// file order.
pub fn otlp_spans(jsonl: &str) -> Vec<String> {
    let mut spans = Vec::new();
    for line in jsonl.lines() {
        let request: serde_json::Value = serde_json::from_str(line).unwrap();
        for resource in request["resourceSpans"].as_array().unwrap() {
            let service = resource["resource"]["attributes"][0]["value"]["stringValue"]
                .as_str()
                .unwrap();
            for scope in resource["scopeSpans"].as_array().unwrap() {
                for span in scope["spans"].as_array().unwrap() {
                    spans.push(format!("{service}/{}", span["spanId"].as_str().unwrap()));
                }
            }
        }
    }
    spans
}

/// The names of the entries in `dir`, sorted.
pub fn file_names(dir: &Path) -> Vec<String> {
    let mut names: Vec<String> = fs::read_dir(dir)
        .unwrap()
        .map(|entry| entry.unwrap().file_name().to_string_lossy().into_owned())
        .collect();
    names.sort();
    names
}

/// The exit status of a process that exited with `code`.
pub fn exited(code: i32) -> ExitStatus {
    ExitStatus::from_raw(code << 8)
}

/// The pid of a process that has exited and been reaped.
pub fn dead_pid() -> u32 {
    let mut child = Command::new("true").spawn().unwrap();
    let pid = child.id();
    child.wait().unwrap();
    pid
}

/// The port of a local server answering every request with `status`.
pub fn answering(status: &'static str) -> u16 {
    let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, 0)).unwrap();
    let port = listener.local_addr().unwrap().port();
    thread::spawn(move || {
        for stream in listener.incoming() {
            let mut stream = stream.unwrap();
            // The whole request head, so closing never resets the connection under the reply.
            let mut request = Vec::new();
            let mut byte = [0];
            while !request.ends_with(b"\r\n\r\n") && stream.read(&mut byte).unwrap_or(0) == 1 {
                request.push(byte[0]);
            }
            let _ = write!(stream, "HTTP/1.1 {status}\r\nContent-Length: 0\r\n\r\n");
        }
    });
    port
}

/// The record of a stack `name` that `owner` supervises with process `groups`, written into
/// `registry` on port block 20000.
pub fn stack_record(registry: &Path, name: &str, owner: u32, groups: Vec<u32>) -> StackRecord {
    let record = StackRecord {
        path: registry.join(format!("{name}.json")),
        worktree: PathBuf::from(format!("/worktrees/{name}")),
        owner,
        base: 20000,
        groups,
    };
    record.write().unwrap();
    record
}

/// A step of the xtask area running `sh -c script` within `budget`.
pub fn shell(name: &'static str, script: &'static str, budget: Duration) -> Step {
    Step {
        name,
        area: Area::Xtask,
        run: Run::Program {
            cwd: ".",
            program: "sh",
            args: Box::leak(Box::new(["-c", script])),
        },
        heavy: false,
        budget,
        needs_generate: false,
        coverage: None,
    }
}

/// The command line names of the areas `steps` belong to.
pub fn area_names(steps: &[&Step]) -> BTreeSet<String> {
    steps
        .iter()
        .map(|step| step.area.to_possible_value().unwrap().get_name().to_owned())
        .collect()
}

/// Commit scopes allowing `scopes` and requiring one for `feat`, loaded from a
/// `commit-scopes.json` the way the hook loads it.
pub fn scopes(scopes: &[&str]) -> Scopes {
    let root = TempRoot::new();
    let json = serde_json::json!({ "scopes": scopes, "scopeRequiredForTypes": ["feat"] });
    root.write("commit-scopes.json", &json.to_string());
    Scopes::load(&root.ctx).unwrap()
}

/// Declares a fake stack service `$name` that only names the services it needs: its command does
/// nothing and it is ready once that command exits.
macro_rules! fake_service {
    ($name:ident, $($need:ident),*) => {
        pub struct $name;
        impl $crate::stack::spec::Service for $name {
            const ID: $crate::stack::spec::ServiceId =
                $crate::stack::spec::ServiceId(stringify!($name));
            fn needs(&self) -> &'static [$crate::stack::spec::ServiceId] {
                &[$(<$need as $crate::stack::spec::Service>::ID),*]
            }
            fn command(
                &self,
                _: &$crate::stack::spec::StackContext,
            ) -> ::anyhow::Result<::std::process::Command> {
                Ok(::std::process::Command::new("true"))
            }
            fn ready(&self, _: &$crate::stack::spec::StackContext) -> $crate::stack::spec::Probe {
                $crate::stack::spec::Probe::ExitSuccess
            }
        }
    };
}
pub(crate) use fake_service;
