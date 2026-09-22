use std::{
    collections::{HashMap, HashSet, VecDeque},
    marker::PhantomData,
    net::{IpAddr, Ipv4Addr, SocketAddr},
    sync::{Arc, Mutex},
};

use anyhow::{Context, Result, bail};
use bytes::Bytes;
use wash_runtime::{
    engine::Engine,
    host::{
        Host, HostApi, HostBuilder,
        http::{DynamicRouter, Ingress},
    },
    plugin::{
        HostPlugin, PluginBindingSet, PluginBindings, WorkloadConfigPolicy,
        wasi_config::DynamicConfig,
        wasi_logging::TracingLogger,
        wasi_otel::{WasiOtel, WasiOtelConfig},
    },
    types::{Component, LocalResources, Workload, WorkloadStartRequest, WorkloadState},
    wit::WitInterface,
};

use crate::{
    FixtureDeclaration, MessagingMock, TestContext,
    builder::{FixtureBuilder, ProvisionContext},
    manifest::Artifact,
    outgoing::DispatchOutgoingHandler,
    telemetry::TelemetryCapture,
};

pub(crate) struct Diagnostics {
    logs: Arc<Mutex<VecDeque<String>>>,
    redactions: Vec<String>,
}
impl Diagnostics {
    fn new(redactions: Vec<String>) -> Self {
        Self {
            logs: Arc::new(Mutex::new(VecDeque::new())),
            redactions,
        }
    }
    fn sink(
        &self,
    ) -> impl Fn(wash_runtime::plugin::wasi_logging::LogRecord) + Send + Sync + 'static {
        let logs = Arc::clone(&self.logs);
        let redactions = self.redactions.clone();
        move |record| {
            let mut line = format!(
                "{:?} {}: {}",
                record.level, record.component_id, record.message
            );
            for secret in &redactions {
                if !secret.is_empty() {
                    line = line.replace(secret, "[REDACTED]");
                }
            }
            if let Ok(mut logs) = logs.lock() {
                if logs.len() == 256 {
                    logs.pop_front();
                }
                logs.push_back(line);
            }
        }
    }
    pub(crate) fn lines(&self) -> Vec<String> {
        self.logs
            .lock()
            .map(|v| v.iter().cloned().collect())
            .unwrap_or_else(|_| vec!["log sink lock poisoned".into()])
    }
}

pub(crate) struct RunningFixture<F> {
    pub host: Arc<Host>,
    pub workload_id: String,
    pub http: Option<(SocketAddr, String)>,
    pub messaging: Option<crate::nats::NatsDriver>,
    pub messaging_mock: Option<MessagingMock>,
    pub diagnostics: Diagnostics,
    marker: PhantomData<F>,
}

fn merge_interface(interfaces: &mut Vec<WitInterface>, interface: WitInterface) -> Result<()> {
    if let Some(existing) = interfaces
        .iter_mut()
        .find(|item| item.instance() == interface.instance())
    {
        for (key, value) in &interface.config {
            if existing.config.get(key).is_some_and(|old| old != value) {
                bail!(
                    "conflicting interface config for `{}` key `{key}`",
                    interface.instance()
                );
            }
        }
        existing.merge(&interface);
        return Ok(());
    }
    interfaces.push(interface);
    Ok(())
}

pub(crate) async fn start<F: FixtureDeclaration>(
    engine: Engine,
    builder: &mut FixtureBuilder<F>,
    artifacts: &HashMap<String, Artifact>,
    provision: ProvisionContext,
    workload_id: String,
    telemetry: TelemetryCapture,
) -> Result<RunningFixture<F>> {
    for (name, config) in provision.components {
        builder.components.insert(name, config);
    }
    builder.plugins.extend(provision.plugins);
    for interface in provision.interfaces {
        merge_interface(&mut builder.interfaces, interface)?;
    }
    let mut redactions = provision.redactions;
    for configuration in builder.components.values() {
        redactions.extend(
            configuration
                .secret_environment
                .iter()
                .filter_map(|name| configuration.environment.get(name).cloned()),
        );
    }
    let diagnostics = Diagnostics::new(redactions);
    let otel = WasiOtel::new(
        WasiOtelConfig::builder()
            .span_processor_factory(Arc::new(telemetry))
            .build(),
    );
    let mut plugins: Vec<Arc<dyn HostPlugin>> = vec![
        Arc::new(DynamicConfig::default()),
        Arc::new(TracingLogger::with_sink(diagnostics.sink())),
        Arc::new(otel),
    ];
    plugins.append(&mut builder.plugins);
    let mut interfaces = builder.interfaces.clone();
    let mut http = None;
    let mut server = None;
    if builder.http_host.is_some() || !builder.mock_handles.is_empty() {
        if let Some(host) = &builder.http_host {
            let mut interface = WitInterface::from("wasi:http/incoming-handler@0.3.0");
            interface.config.insert("host".into(), host.clone());
            merge_interface(&mut interfaces, interface)?;
        }
        let value = Arc::new(
            Ingress::builder(
                DynamicRouter::default(),
                SocketAddr::new(IpAddr::V4(Ipv4Addr::LOCALHOST), 0),
            )
            .outgoing_handler(DispatchOutgoingHandler::new(Arc::new(
                builder.http_mocks.clone(),
            )))
            .build()
            .await
            .context("binding HTTP server")?,
        );
        if let Some(host) = &builder.http_host {
            http = Some((value.addr(), host.clone()));
        }
        server = Some(value);
    }
    let mut messaging = None;
    let mut plugin_bindings = PluginBindings::new();
    if builder.messaging {
        let driver = crate::nats::NatsDriver::start(&workload_id).await?;
        plugins.push(driver.plugin.clone());
        plugin_bindings = plugin_bindings.with_plugin(
            PluginBindingSet::new("wasmcloud-nats")
                .with_workload_config(WorkloadConfigPolicy::Deny)
                .with_base(HashMap::from([
                    ("servers".into(), driver.endpoint.clone()),
                    ("subject-allow".into(), ">".into()),
                    ("stream-allow".into(), "TYPEWRITER_MEMBERSHIP".into()),
                ])),
        );
        for descriptor in F::DESCRIPTOR.components() {
            let config = &builder.components[descriptor.package];
            let mut interface =
                WitInterface::from("wasmcloud:nats/core-handler,core,jetstream@0.1.0");
            interface
                .config
                .insert("component".into(), descriptor.target.into());
            interface
                .config
                .insert("core-subscriptions".into(), config.subscriptions.join(","));
            interfaces.push(interface);
        }
        messaging = Some(driver);
    }
    let mut ids = HashSet::new();
    for plugin in &plugins {
        if !ids.insert(plugin.id()) {
            bail!("duplicate host plugin id `{}`", plugin.id());
        }
    }
    let mut host_builder = HostBuilder::new()
        .with_engine(engine)
        .with_plugin_bindings(plugin_bindings)
        .with_friendly_name(format!("component-test-{workload_id}"));
    if let Some(server) = server {
        host_builder = host_builder.with_http_handler(server);
    }
    for plugin in plugins {
        host_builder = host_builder.with_plugin(plugin)?;
    }
    // The pinned wash-runtime Host::start future owns a transactional rollback
    // guard, so cancellation by this timeout stops partially started services.
    let host = tokio::time::timeout(
        builder.start_timeout,
        host_builder.build().context("building host")?.start(),
    )
    .await
    .map_err(|_| anyhow::anyhow!("starting host timed out after {:?}", builder.start_timeout))?
    .context("starting host")?;
    let mut components = Vec::new();
    for descriptor in F::DESCRIPTOR.components() {
        let artifact = artifacts
            .get(descriptor.package)
            .with_context(|| format!("missing verified artifact `{}`", descriptor.package))?;
        let config = builder
            .components
            .get(descriptor.package)
            .with_context(|| format!("missing component configuration `{}`", descriptor.package))?;
        let mut local_config = config.config.clone();
        if builder.messaging {
            local_config.insert("core-subscriptions".into(), config.subscriptions.join(","));
        }
        components.push(Component {
            name: descriptor.target.to_string(),
            bytes: Bytes::copy_from_slice(&artifact.bytes),
            digest: Some(artifact.digest.clone()),
            local_resources: LocalResources {
                config: local_config,
                environment: config.environment.clone(),
                volume_mounts: config.volume_mounts.clone(),
                allowed_hosts: config.allowed_hosts.clone().into(),
                ..Default::default()
            },
            pool_size: 1,
            max_invocations: -1,
            max_concurrency: 1,
            ..Default::default()
        });
    }
    let workload = Workload {
        namespace: "component-test".into(),
        name: F::DESCRIPTOR.id.into(),
        annotations: HashMap::new(),
        service: None,
        components,
        host_interfaces: interfaces,
        volumes: builder.volumes.clone(),
    };
    let response = match tokio::time::timeout(
        builder.start_timeout,
        host.workload_start(WorkloadStartRequest {
            workload_id: workload_id.clone(),
            workload,
        }),
    )
    .await
    {
        Ok(Ok(response)) => response,
        Ok(Err(error)) => {
            cleanup_failed_start(&host, &workload_id, builder.stop_timeout).await;
            return Err(error).context("starting workload");
        }
        Err(_) => {
            cleanup_failed_start(&host, &workload_id, builder.stop_timeout).await;
            bail!(
                "starting workload timed out after {:?}",
                builder.start_timeout
            );
        }
    };
    if response.workload_status.workload_state != WorkloadState::Running {
        let state = response.workload_status.workload_state;
        let message = response.workload_status.message;
        cleanup_failed_start(&host, &workload_id, builder.stop_timeout).await;
        bail!("workload did not reach Running: {state:?}: {message}");
    }
    let messaging_mock = messaging.as_ref().map(|_| builder.messaging_mock.clone());
    if let (Some(driver), Some(mock)) = (&messaging, &messaging_mock) {
        if let Err(error) = driver.observe(mock.clone()).await {
            cleanup_failed_start(&host, &workload_id, builder.stop_timeout).await;
            return Err(error);
        }
    }
    Ok(RunningFixture {
        host,
        workload_id,
        http,
        messaging,
        messaging_mock,
        diagnostics,
        marker: PhantomData,
    })
}

async fn cleanup_failed_start(
    host: &Arc<wash_runtime::host::Host>,
    workload_id: &str,
    timeout: std::time::Duration,
) {
    let _ = tokio::time::timeout(
        timeout,
        host.workload_stop(wash_runtime::types::WorkloadStopRequest {
            workload_id: workload_id.to_string(),
        }),
    )
    .await;
    let _ = tokio::time::timeout(timeout, Arc::clone(host).stop()).await;
}

impl<F> RunningFixture<F> {
    pub(crate) async fn stop_messaging_monitors(
        &mut self,
        timeout: std::time::Duration,
    ) -> Result<()> {
        if let Some(driver) = &self.messaging {
            tokio::time::timeout(timeout, driver.stop_observer()).await??;
        }
        Ok(())
    }

    pub(crate) fn context(
        &self,
        descriptor: &'static component_test_model::TestDescriptor,
        handles: HashMap<std::any::TypeId, Arc<dyn std::any::Any + Send + Sync>>,
        transcript: VecDeque<String>,
    ) -> TestContext<F> {
        TestContext {
            descriptor,
            http: self.http.clone(),
            messaging: self.messaging.clone(),
            messaging_mock: self.messaging_mock.clone(),
            handles,
            transcript,
            marker: PhantomData,
        }
    }
}
