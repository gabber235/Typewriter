//! Shared test fixtures initialized once for all tests.
//!
//! Uses tokio's OnceCell to ensure fixtures are only initialized once,
//! even when tests run in parallel.

use std::path::Path;
use std::sync::Arc;

use tokio::sync::OnceCell;

use crate::harness::{ComponentRegistry, DeploymentResult, TestHost, TestInfra};

/// Shared test fixtures - built once, used by all tests.
pub struct TestFixtures {
    /// Infrastructure (containers + database connection)
    pub infra: TestInfra,
    /// wash-runtime host with all plugins
    pub host: TestHost,
    /// Registry of discovered and built components
    pub registry: ComponentRegistry,
    /// Deployed workloads tracking
    pub deployment: DeploymentResult,
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
/// 5. Deploys each component as a separate workload
///
/// Components requiring environment configuration (auth-callout, service-identity)
/// are skipped and must be deployed explicitly in tests that need them.
///
/// Subsequent calls return the same fixtures.
pub async fn get_fixtures() -> Arc<TestFixtures> {
    FIXTURES
        .get_or_init(|| async {
            tracing_subscriber::fmt()
                .with_env_filter(
                    tracing_subscriber::EnvFilter::from_default_env()
                        .add_directive(tracing::Level::INFO.into()),
                )
                .with_test_writer()
                .try_init()
                .ok();

            tracing::info!("Initializing test fixtures...");

            let backend_path = Path::new(env!("CARGO_MANIFEST_DIR"))
                .parent()
                .expect("Failed to get backend path");

            tracing::info!(path = ?backend_path, "Backend path determined");

            let mut registry =
                ComponentRegistry::discover(backend_path).expect("Failed to discover components");
            registry
                .build_all()
                .await
                .expect("Failed to build components");

            let infra = TestInfra::start(backend_path)
                .await
                .expect("Failed to start infrastructure");

            let host = TestHost::new(infra.nats_client(), &infra.surrealdb_url)
                .await
                .expect("Failed to create host");
            let deployment = host
                .deploy_all_components(&registry)
                .await
                .expect("Failed to deploy components");

            tracing::info!(
                deployed = deployment.workload_ids.len(),
                "Test fixtures initialized successfully"
            );

            Arc::new(TestFixtures {
                infra,
                host,
                registry,
                deployment,
            })
        })
        .await
        .clone()
}
