//! Container infrastructure for integration tests.
//!
//! Provides testcontainer management for NATS and SurrealDB.

use anyhow::{Context, Result};
use std::path::Path;
use surrealdb::Surreal;
use surrealdb::engine::any::Any;
use testcontainers::runners::AsyncRunner;
use testcontainers_modules::nats::Nats;
use testcontainers_modules::surrealdb::SurrealDb;

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
    pub db: Surreal<Any>,
    /// NATS client for messaging
    nats_client: async_nats::Client,
}

impl TestInfra {
    /// Start test infrastructure (NATS + SurrealDB containers).
    ///
    /// This also imports the database schema from `database/database.surql`.
    pub async fn start(backend_path: &Path) -> Result<Self> {
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

        let nats_client = async_nats::connect(&nats_url)
            .await
            .context("Failed to connect to NATS")?;
        tracing::info!("Connected to NATS");

        let surrealdb_container = SurrealDb::default()
            .with_user("root")
            .with_password("root")
            .start()
            .await
            .context("Failed to start SurrealDB container")?;
        let surreal_port = surrealdb_container
            .get_host_port_ipv4(testcontainers_modules::surrealdb::SURREALDB_PORT)
            .await
            .context("Failed to get SurrealDB port")?;
        let surrealdb_url = format!("ws://127.0.0.1:{}", surreal_port);
        tracing::info!(url = %surrealdb_url, "SurrealDB container started");

        let db: Surreal<Any> = Surreal::init();
        db.connect(&surrealdb_url)
            .await
            .context("Failed to connect to SurrealDB")?;

        db.signin(surrealdb::opt::auth::Root {
            username: "root",
            password: "root",
        })
        .await
        .context("Failed to sign in to SurrealDB")?;

        db.use_ns("typewriter")
            .use_db("test")
            .await
            .context("Failed to select namespace/database")?;

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
            nats_client,
        })
    }

    /// Get the NATS client for test messaging.
    pub fn nats_client(&self) -> &async_nats::Client {
        &self.nats_client
    }
}
