//! `cargo xtask heavy -- <command>`: the machine wide heavy lock for a command xtask has no
//! command for, such as a focused `flutter test` or `./gradlew` run.

use std::os::unix::process::ExitStatusExt as _;
use std::path::Path;
use std::process::{Command, ExitStatus};

use anyhow::{Result, bail};

use crate::lock::{self, HeavyLock};
use crate::process::{self, Group};

/// Runs `command` under the heavy lock with inherited stdio and returns its exit code, so
/// `heavy` exits with the command's code.
pub fn run(command: &[String]) -> Result<u8> {
    if is_xtask(command) {
        bail!("xtask commands take the heavy lock for each heavy step; run them directly");
    }
    process::install_interrupt_handler();
    let _lock = HeavyLock::acquire(&command.join(" "))?;
    run_holding(command)
}

/// Runs `command` while this process holds the heavy lock. A Group, so an interrupt stops the
/// child instead of leaving it running; the marker turns a nested xtask (for example inside
/// `sh -c`) into an error instead of a wait on this lock.
fn run_holding(command: &[String]) -> Result<u8> {
    let mut group = Group::spawn(
        Command::new(&command[0])
            .args(&command[1..])
            .env(lock::HELD_BY_PARENT, "1"),
    )?;
    Ok(exit_code(group.wait(None)?))
}

/// The command's own code, or 128 plus the signal that ended it, as a shell reports it.
fn exit_code(status: ExitStatus) -> u8 {
    match (status.code(), status.signal()) {
        (Some(code), _) => u8::try_from(code).unwrap_or(1),
        (None, Some(signal)) => u8::try_from(128 + signal).unwrap_or(1),
        (None, None) => 1,
    }
}

/// `cargo xtask ...`, `cargo run -p xtask ...` or the xtask binary itself.
fn is_xtask(command: &[String]) -> bool {
    let program = Path::new(&command[0])
        .file_name()
        .map(|name| name.to_string_lossy());
    match program.as_deref() {
        Some("xtask") => true,
        Some("cargo") => {
            let mut args = command[1..]
                .iter()
                .map(String::as_str)
                .filter(|arg| !arg.starts_with('+'));
            match args.next() {
                Some("xtask") => true,
                Some("run") => {
                    let rest: Vec<&str> = args.collect();
                    rest.windows(2)
                        .any(|pair| matches!(pair[0], "-p" | "--package") && pair[1] == "xtask")
                        || rest
                            .iter()
                            .any(|arg| matches!(*arg, "-pxtask" | "--package=xtask"))
                }
                _ => false,
            }
        }
        _ => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::refusal;

    #[test]
    fn heavy_refuses_xtask_commands_and_runs_others() {
        let xtask: [&[&str]; 5] = [
            &["cargo", "xtask", "check", "panel"],
            &["cargo", "+nightly", "xtask", "generate"],
            &["cargo", "run", "-p", "xtask", "--", "check"],
            &["cargo", "run", "--package=xtask"],
            &["xtask/target/debug/xtask", "check"],
        ];
        for command in xtask {
            assert!(
                is_xtask(
                    &command
                        .iter()
                        .map(|word| word.to_string())
                        .collect::<Vec<_>>()
                ),
                "{command:?}"
            );
        }
        let others: [&[&str]; 3] = [
            &["flutter", "test", "test/editor_test.dart"],
            &["cargo", "test", "-p", "xtask"],
            &["./gradlew", "build"],
        ];
        for command in others {
            assert!(
                !is_xtask(
                    &command
                        .iter()
                        .map(|word| word.to_string())
                        .collect::<Vec<_>>()
                ),
                "{command:?}"
            );
        }
        let message = refusal(run(&["cargo", "xtask", "check"].map(String::from)));
        assert!(message.contains("run them directly"), "{message}");
    }

    #[test]
    fn heavy_exits_with_the_command_code() {
        for (script, code) in [("true", 0), ("exit 3", 3), ("kill -TERM $$", 128 + 15)] {
            let command = ["sh", "-c", script].map(String::from);
            assert_eq!(run_holding(&command).unwrap(), code, "{script}");
        }
    }

    /// Runs twice: as a normal test it runs itself under `heavy` through `sh -c`, the way an
    /// agent might nest `cargo xtask` inside a heavy command; that nested copy sees the marker
    /// and checks that taking the heavy lock fails instead of waiting on its parent forever.
    #[test]
    fn a_heavy_lock_taken_inside_heavy_fails_instead_of_waiting() {
        if std::env::var_os(lock::HELD_BY_PARENT).is_some() {
            // Refused before the machine's lock file is opened, so the test never touches it.
            let message = refusal(HeavyLock::acquire("check"));
            assert!(
                message.contains("already holds the heavy lock"),
                "{message}"
            );
            return;
        }
        let dir = tempfile::tempdir().unwrap();
        let _held = HeavyLock::acquire_at(&dir.path().join("heavy.lock"), "heavy").unwrap();
        let test = std::env::current_exe().unwrap();
        let nested = [
            "sh".into(),
            "-c".into(),
            "\"$0\" heavy::tests::a_heavy_lock_taken_inside_heavy_fails_instead_of_waiting --exact --quiet".into(),
            test.display().to_string(),
        ];

        assert_eq!(run_holding(&nested).unwrap(), 0);
    }
}
