use std::collections::HashMap;
use std::sync::Arc;

use anyhow::Context as _;
use surrealdb::engine::any::Any;
use surrealdb::opt::auth::{Database, Namespace, Root};
use surrealdb::{Surreal, Value};
use tokio::sync::RwLock;
use tracing::{debug, info};
use wasmcloud_provider_sdk::initialize_observability;
use wasmcloud_provider_sdk::{
    run_provider, serve_provider_exports, Context, LinkConfig, LinkDeleteInfo, Provider,
    ProviderInitConfig,
};

use crate::config::{Auth, ProviderConfig};

pub(crate) mod bindings {
    wit_bindgen_wrpc::generate!();
}

use bindings::exports::seamlezz::surrealdb::call;

#[derive(Clone)]
/// Your provider struct is where you can store any state or configuration that your provider needs to keep track of.
pub struct SurrealDBProvider {
    config: Arc<RwLock<ProviderConfig>>,

    /// SurrealDB connection
    db: Arc<RwLock<Surreal<Any>>>,

    /// All components linked to this provider and their config.
    linked_from: Arc<RwLock<HashMap<String, HashMap<String, String>>>>,
    /// All components this provider is linked to and their config
    linked_to: Arc<RwLock<HashMap<String, HashMap<String, String>>>>,
}

impl Default for SurrealDBProvider {
    fn default() -> Self {
        SurrealDBProvider {
            config: Arc::new(RwLock::new(Default::default())),
            db: Arc::new(RwLock::new(Surreal::init())),
            linked_from: Arc::new(RwLock::new(Default::default())),
            linked_to: Arc::new(RwLock::new(Default::default())),
        }
    }
}

impl SurrealDBProvider {
    fn name() -> &'static str {
        "surrealdb-provider"
    }

    /// Execute the provider, loading [`HostData`] from the host which includes the provider's configuration and
    /// information about the host. Once you use the passed configuration to construct a [`CustomTemplateProvider`],
    /// you can run the provider by calling `run_provider` and then serving the provider's exports on the proper
    /// RPC topics via `wrpc::serve`.
    ///
    /// This step is essentially the same for every provider, and you shouldn't need to modify this function.
    pub async fn run() -> anyhow::Result<()> {
        initialize_observability!(
            Self::name(),
            std::env::var_os("PROVIDER_SURREALDB_FLAMEGRAPH_PATH")
        );
        let provider = Self::default();
        let shutdown = run_provider(provider.clone(), SurrealDBProvider::name())
            .await
            .context("failed to run provider")?;

        // The [`serve`] function will set up RPC topics for your provider's exports and await invocations.
        // This is a generated function based on the contents in your `wit/world.wit` file.
        let connection = wasmcloud_provider_sdk::get_connection();
        serve_provider_exports(
            &connection
                .get_wrpc_client(connection.provider_key())
                .await
                .context("failed to get wrpc client")?,
            provider,
            shutdown,
            bindings::serve,
        )
        .await

        // If your provider has no exports, simply await the shutdown to keep the provider running
        // shutdown.await;
        // Ok(())
    }
}

impl call::Handler<Option<Context>> for SurrealDBProvider {
    async fn query(
        &self,
        _ctx: Option<Context>,
        query: String,
        _params: Vec<(String, wit_bindgen_wrpc::bytes::Bytes)>,
    ) -> anyhow::Result<Vec<Result<wit_bindgen_wrpc::bytes::Bytes, String>>> {
        let db = self.db.read().await;
        let mut query = db.query(query);
        for (key, value) in _params {
            let value: serde_cbor::Value = serde_cbor::from_slice(&value)?;
            query = query.bind((key, value));
        }
        let mut result = query.await?;
        let mut res = Vec::new();
        for i in 0..result.num_statements() {
            match result.take::<surrealdb::Value>(i) {
                Ok(response) => {
                    info!("Response: {:?}", response);
                    let bytes = serde_cbor::to_vec(&response)?;
                    res.push(Ok(bytes.into()));
                }
                Err(e) => {
                    info!("Error: {:?}", e);
                    res.push(Err(e.to_string()));
                }
            };
        }
        Ok(res)
    }

    // /// Request information about the system the provider is running on
    // async fn request_info(&self, ctx: Option<Context>, kind: Kind) -> anyhow::Result<String> {
    //     // The `ctx` contains information about the component that invoked the request. You can use
    //     // this information to look up the configuration of the component that invoked the request.
    //     let requesting_component = ctx
    //         .and_then(|c| c.component)
    //         .unwrap_or_else(|| "UNKNOWN".to_string());
    //     let component_config = self
    //         .linked_from
    //         .read()
    //         .await
    //         .get(&requesting_component)
    //         .cloned()
    //         .unwrap_or_default();
    //
    //     info!(
    //         requesting_component,
    //         ?kind,
    //         ?component_config,
    //         "received request for system information"
    //     );
    //
    //     let info = match kind {
    //         Kind::Os => std::env::consts::OS,
    //         Kind::Arch => std::env::consts::ARCH,
    //     };
    //     Ok(info.into())
    // }
    //
    // /// Request the provider to send some data to all linked components
    // ///
    // /// This function is easy to invoke with `wash call`,
    // async fn call(&self, _ctx: Option<Context>) -> anyhow::Result<String> {
    //     info!("received call to send data to linked components");
    //     let mut last_response = None;
    //     for (component_id, config) in self.linked_to.read().await.iter() {
    //         debug!(component_id, ?config, "sending data to component");
    //         let sample_data = Data {
    //             name: "sup".to_string(),
    //             count: 3,
    //         };
    //         let client = wasmcloud_provider_sdk::get_connection()
    //             .get_wrpc_client(component_id)
    //             .await
    //             .context("failed to get wrpc client")?;
    //         match process_data::process(&client, None, &sample_data).await {
    //             Ok(response) => {
    //                 last_response = Some(response);
    //                 info!(
    //                     component_id,
    //                     ?config,
    //                     ?last_response,
    //                     "successfully sent data to component"
    //                 );
    //             }
    //             Err(e) => {
    //                 error!(
    //                     component_id,
    //                     ?config,
    //                     ?e,
    //                     "failed to send data to component"
    //                 );
    //             }
    //         }
    //     }
    //
    //     Ok(last_response.unwrap_or_else(|| "No components responded to request".to_string()))
    // }
}

/// Implementing the [`Provider`] trait is optional. Implementing the methods in the trait allow you to set up
/// custom logic for handling links, deletions, and shutdowns. This is useful to set up any connections, state,
/// resources, or cleanup that your provider needs to do when it is linked to or unlinked from a component.
impl Provider for SurrealDBProvider {
    async fn init(&self, config: impl ProviderInitConfig) -> anyhow::Result<()> {
        let provider_id = config.get_provider_id();
        let initial_config = config.get_config();
        info!(provider_id, ?initial_config, "initializing provider");

        let config = ProviderConfig::try_from(initial_config)?;
        let namespace = &config.namespace;
        let database = &config.database;
        let url = &config.url;

        let db = self.db.write().await;

        db.connect(url).await?;

        match &config.auth {
            Auth::Root { username, password } => {
                db.signin(Root { username, password }).await?;
            }
            Auth::Namespace { username, password } => {
                db.signin(Namespace {
                    username,
                    password,
                    namespace,
                })
                .await?;
            }
            Auth::Database { username, password } => {
                db.signin(Database {
                    username,
                    password,
                    namespace,
                    database,
                })
                .await?;
            }
        }

        db.use_ns(namespace).use_db(database).await?;

        *self.config.write().await = config;

        Ok(())
    }

    /// When your provider is linked to a component, this method will be called with the [`LinkConfig`] that
    /// is passed in as source configuration. You can store this configuration in your provider's state to
    /// keep track of the components your provider is linked to.
    ///
    /// A concrete use case for this can be seen in our HTTP server provider, where we are given configuration
    /// for a port or an address to listen on, and we can use that configuration to start a webserver and forward
    /// any incoming requests to the linked component.
    async fn receive_link_config_as_source(
        &self,
        LinkConfig {
            target_id, config, ..
        }: LinkConfig<'_>,
    ) -> anyhow::Result<()> {
        // We're storing the configuration as an example of how to keep track of linked components, but
        // the provider SDK does not require you to store this information.
        self.linked_to
            .write()
            .await
            .insert(target_id.to_string(), config.to_owned());

        debug!(
            "finished processing link from provider to component [{}]",
            target_id
        );
        Ok(())
    }

    /// When a component links to your provider, this method will be called with the [`LinkConfig`] that
    /// is passed in as target configuration. You can store this configuration in your provider's state to
    /// keep track of the components linked to your provider.
    ///
    /// A concrete use case for this can be seen in our key-value Redis provider, where we are given configuration
    /// for a Redis connection, and we can use that configuration to store and retrieve data from Redis. When an
    /// invocation is received from a component, we can look up the configuration for that component and use it
    /// to interact with the correct Redis instance.
    async fn receive_link_config_as_target(
        &self,
        LinkConfig {
            source_id, config, ..
        }: LinkConfig<'_>,
    ) -> anyhow::Result<()> {
        self.linked_from
            .write()
            .await
            .insert(source_id.to_string(), config.to_owned());

        debug!(
            "finished processing link from component [{}] to provider",
            source_id
        );
        Ok(())
    }

    /// When a link is deleted from your provider to a component, this method will be called with the target ID
    /// of the component that was unlinked. You can use this method to clean up any state or resources that were
    /// associated with the linked component.
    async fn delete_link_as_source(&self, link: impl LinkDeleteInfo) -> anyhow::Result<()> {
        let target = link.get_target_id();
        self.linked_to.write().await.remove(target);

        debug!(
            "finished processing delete link from provider to component [{}]",
            target
        );
        Ok(())
    }

    /// When a link is deleted from a component to your provider, this method will be called with the source ID
    /// of the component that was unlinked. You can use this method to clean up any state or resources that were
    /// associated with the linked component.
    async fn delete_link_as_target(&self, link: impl LinkDeleteInfo) -> anyhow::Result<()> {
        let source_id = link.get_source_id();
        self.linked_from.write().await.remove(source_id);

        debug!(
            "finished processing delete link from component [{}] to provider",
            source_id
        );
        Ok(())
    }

    /// Handle shutdown request by cleaning out all linked components. This is a good place to clean up any
    /// resources or connections your provider has established.
    async fn shutdown(&self) -> anyhow::Result<()> {
        self.linked_from.write().await.clear();
        self.linked_to.write().await.clear();

        Ok(())
    }
}
