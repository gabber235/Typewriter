//! Shared test fixtures initialized once for all tests.
//!
//! Uses tokio's OnceCell to ensure fixtures are only initialized once,
//! even when tests run in parallel.

use std::path::Path;
use std::sync::Arc;

use tokio::sync::OnceCell;

use crate::harness::{ComponentRegistry, TestHost, TestInfra};

/// Shared test fixtures - built once, used by all tests.
pub struct TestFixtures {
    /// Infrastructure (containers + database connection)
    pub infra: TestInfra,
    /// wash-runtime host with all plugins
    pub host: TestHost,
    /// Registry of discovered and built components
    pub registry: ComponentRegistry,
}

/// Global fixture storage.
static FIXTURES: OnceCell<Arc<TestFixtures>> = OnceCell::const_new();

/// Initialize fixtures once before all tests run.
///
/// This function:
/// 1. Discovers and builds all WASM components
/// 2. Starts NATS and SurrealDB containers
/// 3. Imports the database schema
/// 4. Creates the wash-runtime host
/// 5. Deploys all components in a single workload
///
/// Subsequent calls return the same fixtures.
pub async fn get_fixtures() -> Arc<TestFixtures> {
    FIXTURES
        .get_or_init(|| async {
            // Initialize tracing for test output
            tracing_subscriber::fmt()
                .with_env_filter(
                    tracing_subscriber::EnvFilter::from_default_env()
                        .add_directive(tracing::Level::INFO.into()),
                )
                .with_test_writer()
                .try_init()
                .ok();

            tracing::info!("Initializing test fixtures...");

            // Determine backend path (tests crate is at backend/tests)
            let backend_path = Path::new(env!("CARGO_MANIFEST_DIR"))
                .parent()
                .expect("Failed to get backend path");

            tracing::info!(path = ?backend_path, "Backend path determined");

            // 1. Discover and BUILD all components (programmatic, no CLI!)
            let mut registry = ComponentRegistry::discover(backend_path)
                .expect("Failed to discover components");
            registry
                .build_all()
                .await
                .expect("Failed to build components");

            // 2. Start infrastructure (containers + schema import)
            let infra = TestInfra::start(backend_path)
                .await
                .expect("Failed to start infrastructure");

            // 3. Create host and deploy ALL components in single workload
            let host = TestHost::new(&infra.nats_url, &infra.surrealdb_url)
                .await
                .expect("Failed to create host");
            host.deploy_all_components(&registry)
                .await
                .expect("Failed to deploy components");

            tracing::info!("Test fixtures initialized successfully");

            Arc::new(TestFixtures {
                infra,
                host,
                registry,
            })
        })
        .await
        .clone()
}
