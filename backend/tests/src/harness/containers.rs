//! Container infrastructure for integration tests.
//!
//! Provides testcontainer management for NATS and SurrealDB.

use anyhow::{Context, Result};
use std::path::Path;
use std::sync::Arc;
use surrealdb::Surreal;
use surrealdb::engine::any::Any;
use testcontainers::ContainerAsync;
use testcontainers::runners::AsyncRunner;
use testcontainers_modules::nats::Nats;
use testcontainers_modules::surrealdb::SurrealDb;
use tokio::sync::Mutex;

/// Shared infrastructure holding containers that persist across all tests.
/// The containers are wrapped in Mutex<Option> to allow cleanup on process exit.
pub struct SharedInfra {
    nats_container: Mutex<Option<ContainerAsync<Nats>>>,
    surrealdb_container: Mutex<Option<ContainerAsync<SurrealDb>>>,
    pub nats_url: String,
    pub surrealdb_url: String,
    pub surrealdb_http_url: String,
}

impl SharedInfra {
    /// Start shared infrastructure (NATS + SurrealDB containers).
    ///
    /// This also imports the database schema from `database/database.surql`.
    pub async fn start(backend_path: &Path) -> Result<Arc<Self>> {
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
        let surrealdb_http_url = format!("http://127.0.0.1:{}", surreal_port);
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

        Ok(Arc::new(Self {
            nats_container: Mutex::new(Some(nats_container)),
            surrealdb_container: Mutex::new(Some(surrealdb_container)),
            nats_url,
            surrealdb_url,
            surrealdb_http_url,
        }))
    }

    /// Stop and remove all containers.
    /// Called during process cleanup via ctor::dtor.
    pub async fn stop(&self) {
        tracing::info!("Stopping test containers...");
        if let Some(c) = self.nats_container.lock().await.take() {
            if let Err(e) = c.rm().await {
                tracing::warn!(error = %e, "Failed to remove NATS container");
            } else {
                tracing::info!("NATS container removed");
            }
        }
        if let Some(c) = self.surrealdb_container.lock().await.take() {
            if let Err(e) = c.rm().await {
                tracing::warn!(error = %e, "Failed to remove SurrealDB container");
            } else {
                tracing::info!("SurrealDB container removed");
            }
        }
    }
}

/// Per-test infrastructure with fresh client connections.
pub struct TestInfra {
    pub nats_url: String,
    pub surrealdb_url: String,
    pub surrealdb_http_url: String,
    pub db: Surreal<Any>,
    nats_client: async_nats::Client,
}

impl TestInfra {
    /// Create fresh client connections to the shared infrastructure.
    pub async fn connect(shared: &SharedInfra) -> Result<Self> {
        let nats_client = async_nats::connect(&shared.nats_url)
            .await
            .context("Failed to connect to NATS")?;

        let db: Surreal<Any> = Surreal::init();
        db.connect(&shared.surrealdb_url)
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

        Ok(Self {
            nats_url: shared.nats_url.clone(),
            surrealdb_url: shared.surrealdb_url.clone(),
            surrealdb_http_url: shared.surrealdb_http_url.clone(),
            db,
            nats_client,
        })
    }

    /// Get the NATS client for test messaging.
    pub fn nats_client(&self) -> &async_nats::Client {
        &self.nats_client
    }
}
