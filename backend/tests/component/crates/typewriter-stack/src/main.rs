//! The processes of a worktree's Typewriter stack. `cargo xtask stack` starts each subcommand as
//! its own process, in dependency order, and stops them when the command under test ends. The
//! long running subcommands write no client files; the supervisor does. `provision` and `bind`
//! run once and record what they created in the stack's state directory.

mod authentik;
mod bind;
mod broker;
mod front;
mod host;
mod observer;
mod provision;
mod session;
#[cfg(test)]
mod test_support;

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
    /// A browser facing front for one of the stack's HTTP services.
    Front(front::FrontArgs),
    /// Every backend component in one wash host, connected to the broker and identity stand in.
    Host(host::HostArgs),
    /// Creates the stack's organization as its owner, then exits.
    Provision(provision::ProvisionArgs),
    /// Binds a host to the stack's organization and assigns it a Realm, then exits; with
    /// `--as-engine`, binds each game Paper slot as the Realm's Paper engine and keeps running.
    Bind(bind::BindArgs),
    /// Mints read only observer credentials for the game requirements, then exits.
    Observer(observer::ObserverArgs),
}

fn main() -> Result<()> {
    // Dependencies enable both of rustls's backends, and then rustls refuses to pick one. A client
    // that takes the process default (`async-nats` on a `tls://` URL) would panic without this.
    rustls::crypto::aws_lc_rs::default_provider()
        .install_default()
        .map_err(|_| anyhow::anyhow!("a rustls crypto provider was installed before main"))?;
    // The host subcommand embeds SurrealDB, whose engine needs deeper stacks than tokio's default.
    // Its schema setup runs in the command's future, so that runs on a worker thread of the
    // plugin's runtime rather than on this thread.
    let runtime = wasmcloud_plugin_surrealdb::runtime_builder().build()?;
    let _context = runtime.enter();

    // The wash runtime's own setup, as the `wash` host has it: console logs, and with an
    // `OTEL_EXPORTER_OTLP_ENDPOINT` the OpenTelemetry layer that joins the trace context arriving
    // on NATS messages and exports the host's and the components' spans.
    let flush =
        wash_runtime::observability::initialize_observability(tracing::Level::INFO, false, false)?;
    let result = runtime.block_on(async { tokio::spawn(run(Command::parse())).await? });
    flush();
    result
}

async fn run(command: Command) -> Result<()> {
    match command {
        Command::Broker(args) => broker::run(args).await,
        Command::Identity(args) => authentik::run(args).await,
        Command::Front(args) => front::run(args).await,
        Command::Host(args) => host::run(args).await,
        Command::Provision(args) => provision::run(args).await,
        Command::Bind(args) => bind::run(args).await,
        Command::Observer(args) => observer::run(args).await,
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
