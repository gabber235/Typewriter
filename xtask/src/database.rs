//! Runs the surrealkit database suites (backend/database/tests) against the SurrealDB server
//! release production runs: an in memory server on a free loopback port, started for the step and
//! stopped with it.

use std::fs::File;
use std::io::Write as _;
use std::net::{Ipv4Addr, TcpListener};
use std::process::Child;
use std::thread;
use std::time::{Duration, Instant};

use anyhow::{Context as _, Result, bail};

use crate::process::POLL;
use crate::{CommandExt as _, Context, display, stack};

pub const DESCRIBE: &str =
    "surreal start memory on a free port; cd backend && surrealkit test against it";

/// The folder surrealkit runs in; it reads `database/` below it.
const PROJECT: &str = "backend";
/// The root login of the throwaway server, which listens on loopback for the step only.
const ROOT: &str = "root";
/// How long the server may take to answer its health check.
const STARTUP: Duration = Duration::from_secs(30);

/// The server, killed when the step ends. It stays in the step's process group, so the graph
/// stops it with the step on an interrupt or a budget overrun.
struct Server(Child);

impl Drop for Server {
    fn drop(&mut self) {
        let _ = self.0.kill();
        let _ = self.0.wait();
    }
}

pub fn step(ctx: &Context, log: &File) -> Result<()> {
    let port = TcpListener::bind((Ipv4Addr::LOCALHOST, 0))?
        .local_addr()?
        .port();
    let address = format!("127.0.0.1:{port}");
    let mut start = ctx.tool(
        PROJECT,
        "surreal",
        &[
            "start", "--bind", &address, "--user", ROOT, "--pass", ROOT, "memory",
        ],
    );
    writeln!(&*log, "$ {}", display(&start))?;
    let mut server = Server(
        start
            .log_output(Some(log))?
            .spawn()
            .context("cannot start surreal")?,
    );
    let deadline = Instant::now() + STARTUP;
    while !stack::http_ok(port, "/health") {
        if let Some(status) = server.0.try_wait()? {
            bail!("the SurrealDB server exited with {status} before it answered");
        }
        if Instant::now() > deadline {
            bail!(
                "the SurrealDB server did not answer within {} s",
                STARTUP.as_secs()
            );
        }
        thread::sleep(POLL);
    }
    let host = format!("http://{address}");
    let mut suites = ctx.tool(
        PROJECT,
        "surrealkit",
        &[
            "test", "--host", &host, "--ns", "suites", "--db", "suites", "--user", ROOT, "--pass",
            ROOT,
        ],
    );
    writeln!(&*log, "$ {}", display(&suites))?;
    suites
        .log_output(Some(log))?
        .run()
        .context("the database suites failed")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::TempRoot;

    #[test]
    fn the_database_step_fails_exactly_when_a_suite_case_fails() {
        let root = TempRoot::new();
        root.write(
            "backend/database/schema/note.surql",
            "DEFINE TABLE OVERWRITE note SCHEMAFULL;\n\
             DEFINE FIELD OVERWRITE text ON note TYPE string ASSERT string::len($value) > 0;\n",
        );
        root.write("backend/database/seed.surql", "-- nothing to seed\n");
        let suite = |allow: bool| {
            format!(
                "name = \"note\"\n\n[[cases]]\nname = \"an_empty_note\"\nkind = \"sql_expect\"\n\
                 actor = \"root\"\nsql = \"CREATE note SET text = '';\"\nallow = {allow}\n"
            )
        };
        let log = tempfile::tempfile().unwrap();

        root.write("backend/database/tests/suites/note.toml", &suite(false));
        step(&root.ctx, &log).expect("the schema refuses an empty note, as the case expects");

        root.write("backend/database/tests/suites/note.toml", &suite(true));
        let error =
            step(&root.ctx, &log).expect_err("the case expects the refused note to be kept");
        assert!(
            format!("{error:#}").contains("the database suites failed"),
            "{error:#}"
        );
    }
}
