//! The processes of a worktree's Typewriter stack. `cargo xtask stack` starts each subcommand as
//! its own process, in dependency order, and stops them when the command under test ends. The
//! long running subcommands write no client files; the supervisor does. `provision` and `bind`
//! run once and record what they created in the stack's state directory.

mod authentik;
mod bind;
mod broker;
mod host;
mod provision;
mod session;

use std::path::PathBuf;

use anyhow::Result;
use clap::Parser;

#[derive(Parser)]
#[command(name = "typewriter-stack")]
enum Command {
    /// NATS with the TYPEWRITER account, auth callout and sentinel, plus the account service.
    Broker(broker::BrokerArgs),
    /// The Authentik surface Typewriter calls (identity stand in).
    Identity(authentik::IdentityArgs),
    /// Every backend component in one wash host, connected to the broker and identity stand in.
    Host(host::HostArgs),
    /// Creates the stack's organization as its owner, then exits.
    Provision(provision::ProvisionArgs),
    /// Binds a host to the stack's organization and assigns it a Realm, then exits.
    Bind(bind::BindArgs),
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .init();
    match Command::parse() {
        Command::Broker(args) => broker::run(args).await,
        Command::Identity(args) => authentik::run(args).await,
        Command::Host(args) => host::run(args).await,
        Command::Provision(args) => provision::run(args).await,
        Command::Bind(args) => bind::run(args).await,
    }
}

/// Resolves when the supervisor asks the process to stop.
async fn shutdown_signal() {
    use tokio::signal::unix::{SignalKind, signal};
    let mut terminate = signal(SignalKind::terminate()).expect("SIGTERM handler");
    tokio::select! {
        _ = terminate.recv() => {}
        _ = tokio::signal::ctrl_c() => {}
    }
}

/// Where the broker writes what the host connects with, under the stack's state directory.
fn broker_connection_file(state: &std::path::Path) -> PathBuf {
    state.join("broker/connection.json")
}
