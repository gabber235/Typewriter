mod config;
mod conversion;
mod provider;

use provider::SurrealDBProvider;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    SurrealDBProvider::run().await?;
    eprintln!("SurrealDB provider exiting");
    Ok(())
}
