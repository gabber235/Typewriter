use anyhow::{Context, Result};
use std::path::Path;
use surrealdb::engine::remote::http::{Client, Http};
use surrealdb::opt::auth::Root;
use surrealdb::Surreal;

pub async fn export_db_state(http_url: &str, output_path: impl AsRef<Path>) -> Result<()> {
    let path = output_path.as_ref();
    tracing::info!(url = %http_url, path = ?path, "Exporting database state...");

    // Strip the http:// prefix if present, as the SDK adds it automatically
    let host = http_url
        .strip_prefix("http://")
        .unwrap_or(http_url);

    let db: Surreal<Client> = Surreal::init();

    db.connect::<Http>(host)
        .await
        .context("Failed to connect to SurrealDB via HTTP")?;

    let _ = db
        .signin(Root {
            username: "root",
            password: "root",
        })
        .await
        .context("Failed to sign in to SurrealDB")?;

    let _: () = db
        .use_ns("typewriter")
        .use_db("test")
        .await
        .context("Failed to select namespace/database")?;

    db.export(path)
        .await
        .context("Failed to export database")?;

    tracing::info!(path = ?path, "Database state exported successfully");
    Ok(())
}
