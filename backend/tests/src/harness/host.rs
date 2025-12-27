//! wash-runtime host setup for running WASM components.
//!
//! Creates a host with all required plugins (NATS messaging, SurrealDB, config, logging)
//! and deploys all components in a single workload.

use std::collections::HashMap;
use std::sync::Arc;

use anyhow::{Context, Result};
use bytes::Bytes;

use wash_runtime::engine::Engine;
use wash_runtime::host::{Host, HostApi, HostBuilder};
use wash_runtime::types::{Component, LocalResources, Workload, WorkloadStartRequest};
use wash_runtime::wit::WitInterface;
use wash_runtime::washlet::plugins::wasmcloud_messaging::WasmcloudMessaging;
use wash_runtime::washlet::plugins::surrealdb::{Auth, SurrealdbConfig, WasiSurrealdb};
use wash_runtime::plugin::wasi_config::WasiConfig;
use wash_runtime::plugin::wasi_logging::WasiLogging;

use super::components::ComponentRegistry;

/// Test host that runs WASM components with all required plugins.
pub struct TestHost {
    host: Arc<Host>,
    nats_client: async_nats::Client,
}

impl TestHost {
    /// Create a new test host connected to NATS and SurrealDB.
    pub async fn new(nats_url: &str, surrealdb_url: &str) -> Result<Self> {
        tracing::info!(nats = %nats_url, surrealdb = %surrealdb_url, "Creating test host...");

        // Connect to NATS
        let nats_client = async_nats::connect(nats_url)
            .await
            .context("Failed to connect to NATS")?;
        tracing::info!("Connected to NATS");

        // Configure SurrealDB plugin
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

        // Create NATS messaging plugin
        let messaging_plugin = WasmcloudMessaging::new(Arc::new(nats_client.clone()));
        tracing::info!("Created NATS messaging plugin");

        // Build the host with all required plugins
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

        Ok(Self { host, nats_client })
    }

    /// Deploy ALL components as a SINGLE workload.
    ///
    /// This is critical: multiple components must be in the same workload
    /// to enable proper inter-component communication.
    pub async fn deploy_all_components(&self, registry: &ComponentRegistry) -> Result<String> {
        let workload_id = uuid::Uuid::new_v4().to_string();
        tracing::info!(workload_id = %workload_id, "Deploying all components...");

        // Collect all components into a single workload
        let mut components = Vec::new();
        let mut all_host_interfaces: Vec<WitInterface> = Vec::new();

        for discovered in registry.all() {
            let bytes = discovered
                .bytes
                .as_ref()
                .ok_or_else(|| anyhow::anyhow!("Component {} not built", discovered.name))?;

            components.push(Component {
                bytes: Bytes::from(bytes.clone()),
                local_resources: LocalResources::default(),
                pool_size: 1,
                max_invocations: 1000,
            });

            // Convert host_interfaces from workloaddeployment.yaml to WitInterface
            for hi in &discovered.host_interfaces {
                all_host_interfaces.push(WitInterface {
                    namespace: hi.namespace.clone(),
                    package: hi.package.clone(),
                    interfaces: hi.interfaces.iter().cloned().collect(),
                    version: None,
                    config: hi.config.clone(),
                });
            }

            tracing::debug!(
                name = %discovered.name,
                interfaces = discovered.host_interfaces.len(),
                "Added component to workload"
            );
        }

        // Merge host_interfaces - combine subscriptions for messaging
        let merged_interfaces = merge_host_interfaces(all_host_interfaces);

        let req = WorkloadStartRequest {
            workload_id: workload_id.clone(),
            workload: Workload {
                namespace: "test".into(),
                name: "integration-test".into(),
                annotations: HashMap::new(),
                service: None,
                components,
                host_interfaces: merged_interfaces,
                volumes: Vec::new(),
            },
        };

        self.host
            .workload_start(req)
            .await
            .context("Failed to start workload")?;

        tracing::info!(
            workload_id = %workload_id,
            components = registry.names().len(),
            "Workload deployed successfully"
        );

        Ok(workload_id)
    }

    /// Get the NATS client for test assertions.
    pub fn nats_client(&self) -> &async_nats::Client {
        &self.nats_client
    }
}

/// Merge host interfaces, combining subscriptions for messaging interfaces.
fn merge_host_interfaces(interfaces: Vec<WitInterface>) -> Vec<WitInterface> {
    let mut result: HashMap<(String, String), WitInterface> = HashMap::new();
    let mut messaging_subscriptions: Vec<String> = Vec::new();

    for hi in interfaces {
        let key = (hi.namespace.clone(), hi.package.clone());

        // Special handling for messaging - collect all subscriptions
        if hi.namespace == "wasmcloud" && hi.package == "messaging" {
            if let Some(subs) = hi.config.get("subscriptions") {
                messaging_subscriptions.push(subs.clone());
            }
            // Merge interfaces
            if let Some(existing) = result.get_mut(&key) {
                existing.interfaces.extend(hi.interfaces);
            } else {
                result.insert(key, WitInterface {
                    namespace: hi.namespace,
                    package: hi.package,
                    interfaces: hi.interfaces,
                    version: hi.version,
                    config: HashMap::new(), // Config will be added later
                });
            }
        } else {
            // For non-messaging interfaces, just merge
            if let Some(existing) = result.get_mut(&key) {
                existing.interfaces.extend(hi.interfaces);
                existing.config.extend(hi.config);
            } else {
                result.insert(key, hi);
            }
        }
    }

    // Add merged subscriptions to messaging interface
    if !messaging_subscriptions.is_empty() {
        let key = ("wasmcloud".to_string(), "messaging".to_string());
        if let Some(messaging) = result.get_mut(&key) {
            messaging.config.insert(
                "subscriptions".to_string(),
                messaging_subscriptions.join(","),
            );
        }
    }

    result.into_values().collect()
}
