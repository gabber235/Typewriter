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

use crate::graph::{Area, Run, Step};
use crate::hooks::commit_msg::Scopes;
use crate::results::{Failure, Outcome, Quarantine, TestCase, TestRun};
use crate::skirout::base::harness::v1::test_run::Runner;
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

/// A components run with `cases`.
pub fn run(cases: &[(&str, Outcome)]) -> TestRun {
    TestRun {
        runner: Runner::Components,
        cases: cases
            .iter()
            .map(|(id, outcome)| TestCase {
                id: (*id).to_owned(),
                outcome: outcome.clone(),
                ..TestCase::default()
            })
            .collect(),
        ..TestRun::default()
    }
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

/// A rerun that must never happen: it fails the test when called.
pub fn never_rerun(_: &[&str]) -> Result<TestRun> {
    panic!("nothing should be rerun")
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
