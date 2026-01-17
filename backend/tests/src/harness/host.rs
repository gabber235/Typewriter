//! wash-runtime host setup for running WASM components.
//!
//! Creates a host with all required plugins (NATS messaging, SurrealDB, config, logging)
//! and deploys all components in a single workload.

use std::collections::HashMap;
use std::sync::Arc;

use anyhow::{Context, Result};
use bytes::Bytes;
use futures::future::join_all;

use wash_runtime::engine::Engine;
use wash_runtime::host::{Host, HostApi, HostBuilder};
use wash_runtime::plugin::wasi_config::WasiConfig;
use wash_runtime::plugin::wasi_logging::WasiLogging;
use wash_runtime::types::{Component, LocalResources, Workload, WorkloadStartRequest};
use wash_runtime::washlet::plugins::surrealdb::{Auth, SurrealdbConfig, WasiSurrealdb};
use wash_runtime::washlet::plugins::wasmcloud_messaging::WasmcloudMessaging;
use wash_runtime::wit::WitInterface;

use super::components::{ComponentRegistry, DiscoveredComponent};

/// Result of deploying components, tracking all workload IDs.
#[derive(Debug, Clone, Default)]
pub struct DeploymentResult {
    /// All workload IDs for cleanup.
    pub workload_ids: Vec<String>,
    /// Map from component name to workload ID for targeted operations.
    pub component_workloads: HashMap<String, String>,
}

impl DeploymentResult {
    /// Get all workload IDs for cleanup.
    pub fn all_ids(&self) -> &[String] {
        &self.workload_ids
    }

    /// Get workload ID for a specific component.
    pub fn get(&self, component_name: &str) -> Option<&str> {
        self.component_workloads
            .get(component_name)
            .map(|s| s.as_str())
    }
}

/// Test host that runs WASM components with all required plugins.
#[derive(Clone)]
pub struct TestHost {
    host: Arc<Host>,
}

impl TestHost {
    /// Create a new test host connected to NATS and SurrealDB.
    pub async fn new(nats_client: &async_nats::Client, surrealdb_url: &str) -> Result<Self> {
        tracing::info!(surrealdb = %surrealdb_url, "Creating test host...");

        let surrealdb_config = SurrealdbConfig {
            url: surrealdb_url.to_string(),
            namespace: "typewriter".to_string(),
            database: "test".to_string(),
            auth: Auth::Root {
                username: "root".to_string(),
                password: "root".to_string(),
            },
        };
        let surrealdb_plugin = WasiSurrealdb::new(surrealdb_config)
            .await
            .context("Failed to create SurrealDB plugin")?;
        tracing::info!("Created SurrealDB plugin");

        let messaging_plugin = WasmcloudMessaging::new(Arc::new(nats_client.clone()));
        tracing::info!("Created NATS messaging plugin");

        let engine = Engine::builder()
            .build()
            .context("Failed to create engine")?;

        let host = HostBuilder::new()
            .with_engine(engine)
            .with_plugin(Arc::new(messaging_plugin))
            .context("Failed to add messaging plugin")?
            .with_plugin(Arc::new(surrealdb_plugin))
            .context("Failed to add SurrealDB plugin")?
            .with_plugin(Arc::new(WasiConfig::default()))
            .context("Failed to add config plugin")?
            .with_plugin(Arc::new(WasiLogging))
            .context("Failed to add logging plugin")?
            .build()
            .context("Failed to build host")?
            .start()
            .await
            .context("Failed to start host")?;

        tracing::info!("Test host created successfully");

        Ok(Self { host })
    }

    /// Deploy all components that don't require environment configuration.
    ///
    /// Each component is deployed as a separate workload with its own host interfaces.
    /// Components requiring environment configuration (auth-callout, service-identity)
    /// are skipped and must be deployed explicitly via `deploy_component()`.
    ///
    /// Components are deployed concurrently for faster startup.
    pub async fn deploy_all_components(
        &self,
        registry: &ComponentRegistry,
    ) -> Result<DeploymentResult> {
        // Collect components to deploy (skip those requiring environment configuration)
        let components_to_deploy: Vec<_> = registry
            .all()
            .filter(|d| {
                if d.requires_environment() {
                    tracing::info!(
                        name = %d.name,
                        config_refs = ?d.config_refs,
                        secret_refs = ?d.secret_refs,
                        "Skipping component (requires environment configuration)"
                    );
                    false
                } else {
                    true
                }
            })
            .cloned()
            .collect();

        tracing::info!(
            count = components_to_deploy.len(),
            "Deploying components concurrently..."
        );

        // Spawn each deployment as a separate task for true concurrency
        let mut handles = Vec::new();
        for discovered in components_to_deploy {
            let host = self.clone();
            let handle = tokio::spawn(async move {
                let name = discovered.name.clone();
                let workload_id = host
                    .deploy_component_internal(&discovered, HashMap::new())
                    .await?;
                Ok::<(String, String), anyhow::Error>((name, workload_id))
            });
            handles.push(handle);
        }

        // Wait for all deployments to complete
        let results = join_all(handles).await;

        // Collect results, fail fast on any error
        let mut result = DeploymentResult::default();
        for join_result in results {
            let (name, workload_id) = join_result
                .context("Task panicked")?
                .context("Deployment failed")?;
            result.workload_ids.push(workload_id.clone());
            result.component_workloads.insert(name, workload_id);
        }

        tracing::info!(
            deployed = result.workload_ids.len(),
            "All components deployed concurrently"
        );

        Ok(result)
    }

    /// Deploy a specific component with its environment variables.
    ///
    /// Use this for components that require environment configuration,
    /// such as auth-callout or service-identity.
    pub async fn deploy_component(
        &self,
        registry: &ComponentRegistry,
        name: &str,
        environment: HashMap<String, String>,
    ) -> Result<String> {
        let discovered = registry
            .get(name)
            .ok_or_else(|| anyhow::anyhow!("Component {} not found", name))?;

        self.deploy_component_internal(discovered, environment).await
    }

    /// Internal helper that deploys a single component as its own workload.
    async fn deploy_component_internal(
        &self,
        discovered: &DiscoveredComponent,
        environment: HashMap<String, String>,
    ) -> Result<String> {
        let bytes = discovered
            .bytes
            .as_ref()
            .ok_or_else(|| anyhow::anyhow!("Component {} not built", discovered.name))?;

        let workload_id = uuid::Uuid::new_v4().to_string();

        let component = Component {
            bytes: Bytes::from(bytes.clone()),
            local_resources: LocalResources {
                environment,
                ..Default::default()
            },
            pool_size: 10,
            max_invocations: 1000,
        };

        let host_interfaces: Vec<WitInterface> = discovered
            .host_interfaces
            .iter()
            .map(|hi| WitInterface {
                namespace: hi.namespace.clone(),
                package: hi.package.clone(),
                interfaces: hi.interfaces.iter().cloned().collect(),
                version: None,
                config: hi.config.clone(),
            })
            .collect();

        let req = WorkloadStartRequest {
            workload_id: workload_id.clone(),
            workload: Workload {
                namespace: "test".into(),
                name: discovered.name.clone(),
                annotations: HashMap::new(),
                service: None,
                components: vec![component],
                host_interfaces,
                volumes: Vec::new(),
            },
        };

        self.host
            .workload_start(req)
            .await
            .with_context(|| format!("Failed to start workload for {}", discovered.name))?;

        tracing::info!(
            workload_id = %workload_id,
            component = %discovered.name,
            "Component deployed as separate workload"
        );

        Ok(workload_id)
    }
}
