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
        http::{DynamicRouter, HttpServer},
    },
    plugin::{
        HostPlugin,
        wasi_config::DynamicConfig,
        wasi_logging::TracingLogger,
        wasi_otel::WasiOtel,
        wasmcloud_messaging::{InMemoryMessaging, InMemoryMessagingDriver},
    },
    types::{Component, LocalResources, Workload, WorkloadStartRequest, WorkloadState},
    wit::WitInterface,
};

use crate::{
    FixtureDeclaration, MessagingMock, TestContext,
    builder::{FixtureBuilder, ProvisionContext},
    manifest::Artifact,
    outgoing::DispatchOutgoingHandler,
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
    pub messaging: Option<InMemoryMessagingDriver>,
    pub messaging_mock: Option<MessagingMock>,
    messaging_monitors: Vec<tokio::task::JoinHandle<Result<()>>>,
    messaging_monitor_stop: Option<tokio::sync::watch::Sender<bool>>,
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
    let mut plugins: Vec<Arc<dyn HostPlugin>> = vec![
        Arc::new(DynamicConfig::default()),
        Arc::new(TracingLogger::with_sink(diagnostics.sink())),
        Arc::new(WasiOtel::default()),
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
            HttpServer::builder(
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
    if builder.messaging {
        let plugin = InMemoryMessaging::new();
        let driver = plugin
            .reserve_workload(&workload_id)
            .await
            .context("reserving messaging workload")?;
        plugins.push(Arc::new(plugin));
        let mut interface = WitInterface::from("wasmcloud:messaging/handler,consumer@0.4.0");
        interface.config.insert(
            "subscriptions".into(),
            builder
                .components
                .values()
                .flat_map(|c| c.subscriptions.iter().cloned())
                .collect::<Vec<_>>()
                .join(","),
        );
        merge_interface(&mut interfaces, interface)?;
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
            local_config.insert("subscriptions".into(), config.subscriptions.join(","));
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
    let (messaging_monitors, messaging_monitor_stop) =
        if let (Some(driver), Some(mock)) = (&messaging, &messaging_mock) {
            match start_messaging_monitors(driver, mock).await {
                Ok(monitors) => monitors,
                Err(error) => {
                    cleanup_failed_start(&host, &workload_id, builder.stop_timeout).await;
                    return Err(error);
                }
            }
        } else {
            (Vec::new(), None)
        };
    Ok(RunningFixture {
        host,
        workload_id,
        http,
        messaging,
        messaging_mock,
        messaging_monitors,
        messaging_monitor_stop,
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

async fn start_messaging_monitors(
    driver: &InMemoryMessagingDriver,
    mock: &MessagingMock,
) -> Result<(
    Vec<tokio::task::JoinHandle<Result<()>>>,
    Option<tokio::sync::watch::Sender<bool>>,
)> {
    let mut observations = driver
        .observe(128)
        .await
        .context("creating messaging observer")?;
    let single_responder = driver
        .register_responder("*", 128)
        .await
        .context("creating messaging responder")?;
    let nested_responder = driver
        .register_responder(">", 128)
        .await
        .context("creating nested messaging responder")?;
    let (stop, stop_receiver) = tokio::sync::watch::channel(false);
    let observation_mock = mock.clone();
    let mut observation_stop = stop_receiver.clone();
    let observation = tokio::spawn(async move {
        loop {
            tokio::select! {
                changed = observation_stop.changed() => if changed.is_err() || *observation_stop.borrow() { return Ok(()); },
                event = observations.recv() => match event {
                    Some(event) if event.operation == wash_runtime::plugin::wasmcloud_messaging::ObservedOperation::Publish => observation_mock.record_publish(&event.message),
                    Some(_) => {},
                    None => return Ok(()),
                }
            }
        }
    });
    fn responder(
        mut receiver: wash_runtime::plugin::wasmcloud_messaging::ResponderReceiver,
        request_mock: MessagingMock,
        mut request_stop: tokio::sync::watch::Receiver<bool>,
    ) -> tokio::task::JoinHandle<Result<()>> {
        tokio::spawn(async move {
            loop {
                tokio::select! {
                    changed = request_stop.changed() => if changed.is_err() || *request_stop.borrow() { return Ok(()); },
                    request = receiver.recv() => match request {
                        Some(request) => if let Some(response) = request_mock.record_request(&request) { response.send(request).await?; },
                        None => return Ok(()),
                    }
                }
            }
        })
    }
    Ok((
        vec![
            observation,
            responder(single_responder, mock.clone(), stop_receiver.clone()),
            responder(nested_responder, mock.clone(), stop_receiver),
        ],
        Some(stop),
    ))
}

impl<F> RunningFixture<F> {
    pub(crate) async fn stop_messaging_monitors(
        &mut self,
        timeout: std::time::Duration,
    ) -> Result<()> {
        if let Some(stop) = self.messaging_monitor_stop.take() {
            let _ = stop.send(true);
        }
        let deadline = tokio::time::Instant::now() + timeout;
        let mut failures = Vec::new();
        for mut monitor in self.messaging_monitors.drain(..) {
            match tokio::time::timeout_at(deadline, &mut monitor).await {
                Ok(Ok(Ok(()))) => {}
                Ok(Ok(Err(error))) => failures.push(format!("{error:#}")),
                Ok(Err(error)) => failures.push(format!("monitor task: {error}")),
                Err(_) => {
                    monitor.abort();
                    let _ = monitor.await;
                    failures.push(format!("monitor shutdown timed out after {timeout:?}"));
                }
            }
        }
        if !failures.is_empty() {
            bail!(failures.join("; "));
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
