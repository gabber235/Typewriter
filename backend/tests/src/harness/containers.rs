//! Container infrastructure for integration tests.
//!
//! Provides testcontainer management for NATS and SurrealDB.

use std::path::Path;
use anyhow::{Context, Result};
use testcontainers::runners::AsyncRunner;
use testcontainers_modules::nats::Nats;
use testcontainers_modules::surrealdb::SurrealDb;
use surrealdb::engine::remote::ws::{Client, Ws};
use surrealdb::Surreal;

/// Test infrastructure holding all running containers and connections.
pub struct TestInfra {
    /// NATS container instance
    _nats_container: testcontainers::ContainerAsync<Nats>,
    /// SurrealDB container instance
    _surrealdb_container: testcontainers::ContainerAsync<SurrealDb>,
    /// NATS connection URL
    pub nats_url: String,
    /// SurrealDB connection URL
    pub surrealdb_url: String,
    /// SurrealDB client for direct database access
    pub db: Surreal<Client>,
}

impl TestInfra {
    /// Start test infrastructure (NATS + SurrealDB containers).
    ///
    /// This also imports the database schema from `database/database.surql`.
    pub async fn start(backend_path: &Path) -> Result<Self> {
        tracing::info!("Starting test infrastructure...");

        // Start NATS container
        tracing::info!("Starting NATS container...");
        let nats_container = Nats::default()
            .start()
            .await
            .context("Failed to start NATS container")?;
        let nats_port = nats_container
            .get_host_port_ipv4(4222)
            .await
            .context("Failed to get NATS port")?;
        let nats_url = format!("nats://127.0.0.1:{}", nats_port);
        tracing::info!(url = %nats_url, "NATS container started");

        // Start SurrealDB container
        tracing::info!("Starting SurrealDB container...");
        let surrealdb_container = SurrealDb::default()
            .start()
            .await
            .context("Failed to start SurrealDB container")?;
        let surreal_port = surrealdb_container
            .get_host_port_ipv4(8000)
            .await
            .context("Failed to get SurrealDB port")?;
        let surrealdb_url = format!("ws://127.0.0.1:{}", surreal_port);
        tracing::info!(url = %surrealdb_url, "SurrealDB container started");

        // Connect to SurrealDB with retry (container may need time to be ready)
        tracing::info!("Connecting to SurrealDB...");
        let db = connect_with_retry(&surrealdb_url, 10, std::time::Duration::from_millis(500))
            .await
            .context("Failed to connect to SurrealDB")?;

        // Sign in as root
        db.signin(surrealdb::opt::auth::Root {
            username: "root",
            password: "root",
        })
        .await
        .context("Failed to sign in to SurrealDB")?;

        // Use the test namespace and database
        db.use_ns("typewriter")
            .use_db("test")
            .await
            .context("Failed to select namespace/database")?;

        // Import schema from database.surql
        let schema_path = backend_path.join("database/database.surql");
        tracing::info!(path = ?schema_path, "Importing database schema...");
        let schema = std::fs::read_to_string(&schema_path)
            .with_context(|| format!("Failed to read schema from {:?}", schema_path))?;
        db.query(&schema)
            .await
            .context("Failed to import database schema")?;
        tracing::info!("Database schema imported successfully");

        Ok(Self {
            _nats_container: nats_container,
            _surrealdb_container: surrealdb_container,
            nats_url,
            surrealdb_url,
            db,
        })
    }
}

/// Connect to SurrealDB with retry.
///
/// SurrealDB container may report as started before the database is fully ready.
/// This function retries the connection with a delay between attempts.
async fn connect_with_retry(
    url: &str,
    max_attempts: u32,
    delay: std::time::Duration,
) -> Result<Surreal<Client>> {
    let mut last_error = None;

    for attempt in 1..=max_attempts {
        match Surreal::new::<Ws>(url).await {
            Ok(db) => {
                tracing::info!(attempt = attempt, "Connected to SurrealDB");
                return Ok(db);
            }
            Err(e) => {
                tracing::debug!(
                    attempt = attempt,
                    error = %e,
                    "Connection attempt failed, retrying..."
                );
                last_error = Some(e);
                tokio::time::sleep(delay).await;
            }
        }
    }

    Err(last_error
        .map(|e| anyhow::anyhow!(e))
        .unwrap_or_else(|| anyhow::anyhow!("No connection attempts made")))
}
