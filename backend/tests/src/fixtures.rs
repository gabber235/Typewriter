//! Shared test fixtures initialized once for all tests.
//!
//! Uses a dedicated tokio runtime for shared infrastructure to avoid
//! channel closure issues when individual test runtimes complete.

use std::path::Path;
use std::sync::Arc;

use ctor::dtor;
use tokio::runtime::Runtime;
use tokio::sync::OnceCell;
#[cfg(feature = "profiling")]
use tracing_subscriber::layer::SubscriberExt;
#[cfg(feature = "profiling")]
use tracing_subscriber::prelude::*;

use crate::harness::{ComponentRegistry, DeploymentResult, SharedInfra, TestHost, TestInfra};

/// Shared fixtures that persist across all tests.
/// These are initialized once in a dedicated runtime.
pub struct SharedFixtures {
    pub infra: Arc<SharedInfra>,
    pub host: TestHost,
    pub registry: Arc<ComponentRegistry>,
    pub deployment: DeploymentResult,
}

/// Per-test fixtures with fresh client connections.
pub struct TestFixtures {
    pub infra: TestInfra,
    pub host: TestHost,
    pub registry: Arc<ComponentRegistry>,
    pub deployment: DeploymentResult,
}

/// Dedicated runtime for shared infrastructure.
/// This runtime persists for the entire test process lifetime,
/// ensuring that background tasks (NATS, wash-runtime Host) don't get
/// killed when individual test runtimes complete.
static SHARED_RUNTIME: std::sync::LazyLock<Runtime> = std::sync::LazyLock::new(|| {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .thread_name("test-shared-runtime")
        .build()
        .expect("Failed to create shared runtime")
});

/// Global tracing guard - must persist for the entire test process to flush the trace file.
/// We use a Mutex because FlushGuard is not Sync.
#[cfg(feature = "profiling")]
static TRACING_GUARD: std::sync::OnceLock<std::sync::Mutex<Option<tracing_chrome::FlushGuard>>> =
    std::sync::OnceLock::new();

/// Global shared fixture storage.
static SHARED_FIXTURES: OnceCell<Arc<SharedFixtures>> = OnceCell::const_new();

/// Initialize tracing for profiling (with Chrome trace output).
#[cfg(feature = "profiling")]
fn init_tracing() {
    TRACING_GUARD.get_or_init(|| {
        let (chrome_layer, guard) = tracing_chrome::ChromeLayerBuilder::new()
            .file("test-startup-trace.json")
            .include_args(true)
            .build();

        tracing_subscriber::registry()
            .with(chrome_layer)
            .with(
                tracing_subscriber::fmt::layer()
                    .with_test_writer()
                    .with_filter(
                        tracing_subscriber::EnvFilter::from_default_env()
                            .add_directive(tracing::Level::INFO.into()),
                    ),
            )
            .init();

        std::sync::Mutex::new(Some(guard))
    });
}

/// Initialize tracing for normal test runs (console output only).
#[cfg(not(feature = "profiling"))]
fn init_tracing() {
    use tracing_subscriber::prelude::*;

    static TRACING_INIT: std::sync::OnceLock<()> = std::sync::OnceLock::new();
    TRACING_INIT.get_or_init(|| {
        tracing_subscriber::registry()
            .with(
                tracing_subscriber::fmt::layer()
                    .with_test_writer()
                    .with_filter(
                        tracing_subscriber::EnvFilter::from_default_env()
                            .add_directive(tracing::Level::INFO.into()),
                    ),
            )
            .init();
    });
}

/// Get or initialize shared fixtures.
/// Called internally by get_fixtures().
async fn get_shared_fixtures() -> Arc<SharedFixtures> {
    SHARED_FIXTURES
        .get_or_init(|| async {
            init_tracing();

            tracing::info!("Initializing shared test fixtures...");

            let backend_path = Path::new(env!("CARGO_MANIFEST_DIR"))
                .parent()
                .expect("Failed to get backend path");

            tracing::info!(path = ?backend_path, "Backend path determined");

            let registry =
                ComponentRegistry::discover(backend_path).expect("Failed to discover components");
            let registry = Arc::new(registry);

            let infra = SharedInfra::start(backend_path)
                .await
                .expect("Failed to start infrastructure");

            let nats_client = async_nats::connect(&infra.nats_url)
                .await
                .expect("Failed to connect to NATS for host");

            let host = TestHost::new(&nats_client, &infra.surrealdb_url)
                .await
                .expect("Failed to create host");
            let deployment = host
                .deploy_all_components(&registry)
                .await
                .expect("Failed to deploy components");

            tracing::info!(
                deployed = deployment.workload_ids.len(),
                "Shared test fixtures initialized successfully"
            );

            Arc::new(SharedFixtures {
                infra,
                host,
                registry,
                deployment,
            })
        })
        .await
        .clone()
}

/// Initialize fixtures for a test.
///
/// This function:
/// 1. Ensures shared infrastructure is started (containers, host, components)
/// 2. Creates fresh NATS and SurrealDB client connections for this test
///
/// Each test gets its own client connections, avoiding channel closure issues
/// when other tests complete.
pub async fn get_fixtures() -> TestFixtures {
    let shared = SHARED_RUNTIME
        .spawn(get_shared_fixtures())
        .await
        .expect("Failed to initialize shared fixtures");

    let infra = TestInfra::connect(&shared.infra)
        .await
        .expect("Failed to create per-test infrastructure");

    TestFixtures {
        infra,
        host: shared.host.clone(),
        registry: shared.registry.clone(),
        deployment: shared.deployment.clone(),
    }
}

/// Cleanup handler called when the test process exits.
/// Stops and removes all containers.
#[dtor]
fn cleanup_fixtures() {
    if let Some(shared) = SHARED_FIXTURES.get() {
        SHARED_RUNTIME.block_on(async {
            shared.infra.stop().await;
        });
    }
}
