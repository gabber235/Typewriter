//! Every deployable backend component in one wash host, wired the way the cluster wires them:
//! NATS through the stack broker's WASMCLOUD account, one in memory SurrealDB with the full
//! schema, the two public HTTP routes on one address, and outgoing HTTP only to the identity
//! stand in. The host also creates the faults link the panel's NATS traffic goes through.
//!
//! The broker and identity stand in are their own processes; the host only connects to them.
//! xtask builds the components and passes each artifact as `--component <package>=<path>`.

use std::collections::{BTreeMap, HashMap};
use std::net::{Ipv4Addr, SocketAddr};
use std::path::PathBuf;
use std::sync::Arc;

use anyhow::{Context as _, Result, bail, ensure};
use bytes::Bytes;
use serde_json::json;
use wash_runtime::engine::Engine;
use wash_runtime::host::allowed_hosts::AllowedHost;
use wash_runtime::host::http::{
    Ingress, OutgoingHandler, RequestIoFuture, RouteError, Router, SendFuture, check_allowed_hosts,
};
use wash_runtime::host::{HostApi as _, HostBuilder};
use wash_runtime::plugin::wasi_config::DynamicConfig;
use wash_runtime::plugin::wasi_logging::TracingLogger;
use wash_runtime::plugin::wasi_otel::{WasiOtel, WasiOtelConfig};
use wash_runtime::plugin::wasmcloud_nats::WasmcloudNats;
use wash_runtime::plugin::{HostPlugin, PluginBindingSet, PluginBindings, WorkloadConfigPolicy};
use wash_runtime::types::{
    Component, LocalResources, Workload, WorkloadStartRequest, WorkloadState,
};
use wash_runtime::wit::WitInterface;
use wasmcloud_plugin_surrealdb::{ConnectionKey, WasmcloudSurrealdb};
use wasmcloud_utils::transport_routes;
use wasmtime_wasi_http::{Error as HttpError, RequestOptions, WasiBody};

use component_test_core::{buffered, wasi_response};

use crate::authentik::API_TOKEN;
use crate::broker::BrokerConnection;

#[derive(clap::Args)]
pub struct HostArgs {
    /// The stack's state directory.
    #[arg(long)]
    state: PathBuf,
    /// The public HTTP routes (`API_BASE_URL`).
    #[arg(long)]
    http: u16,
    /// Where the panel connects to NATS, through the faults link.
    #[arg(long = "nats-proxy")]
    nats_proxy: u16,
    /// The toxiproxy server's API.
    #[arg(long)]
    faults: u16,
    /// The identity stand in.
    #[arg(long)]
    identity: u16,
    /// A built component, as `<package>=<artifact path>`.
    #[arg(long = "component", value_parser = parse_component)]
    components: Vec<(String, PathBuf)>,
}

fn parse_component(value: &str) -> Result<(String, PathBuf), String> {
    value
        .split_once('=')
        .map(|(package, path)| (package.to_owned(), PathBuf::from(path)))
        .ok_or_else(|| format!("`{value}` is not <package>=<path>"))
}

/// How the cluster wires one component (`backend/*/*/deploy/base/workloaddeployment.yaml`).
struct Wiring {
    package: &'static str,
    /// NATS core subscriptions, `subject` or `subject:queue`.
    subscriptions: &'static [&'static str],
    /// The exact public path the component's ingress serves.
    http_path: Option<&'static str>,
    database: bool,
    /// Calls the identity stand in over HTTP.
    identity: bool,
}

const AUTH_CALLOUT_SUBSCRIPTIONS: &[&str] = &["$SYS.REQ.USER.AUTH:typewriter.auth-auth-callout"];

const WIRING: &[Wiring] = &[
    Wiring {
        package: "auth-callout",
        subscriptions: AUTH_CALLOUT_SUBSCRIPTIONS,
        http_path: None,
        database: false,
        identity: true,
    },
    Wiring {
        package: "auth-sentinel",
        subscriptions: &[],
        http_path: Some("/auth/sentinel"),
        database: false,
        identity: false,
    },
    Wiring {
        package: "auth-typewriter-permissions",
        subscriptions: transport_routes::auth_typewriter_permissions::SUBSCRIPTIONS,
        http_path: None,
        database: true,
        identity: false,
    },
    Wiring {
        package: "organization-members",
        subscriptions: transport_routes::organization_members::SUBSCRIPTIONS,
        http_path: None,
        database: true,
        identity: false,
    },
    Wiring {
        package: "organization-roles",
        subscriptions: transport_routes::organization_roles::SUBSCRIPTIONS,
        http_path: None,
        database: true,
        identity: false,
    },
    Wiring {
        package: "user-organization",
        subscriptions: transport_routes::user_organization::SUBSCRIPTIONS,
        http_path: None,
        database: true,
        identity: false,
    },
    Wiring {
        package: "service-identity",
        subscriptions: &[],
        http_path: Some("/service/identity/issue"),
        database: true,
        identity: true,
    },
    Wiring {
        package: "service-registration",
        subscriptions: transport_routes::service_registration::SUBSCRIPTIONS,
        http_path: None,
        database: true,
        identity: false,
    },
];

pub async fn run(args: HostArgs) -> Result<()> {
    let broker = BrokerConnection::read(&crate::broker_connection_file(&args.state))?;
    let identity = format!("http://127.0.0.1:{}", args.identity);
    let ready_file = args.state.join("backend/ready");
    std::fs::create_dir_all(ready_file.parent().context("ready file has a parent")?)?;

    create_faults_link(&args, &broker).await?;

    let database = Arc::new(WasmcloudSurrealdb::new());
    let database_key = ConnectionKey::from_config(&HashMap::from([
        ("url".into(), "memory".into()),
        ("namespace".into(), "typewriter".into()),
        ("database".into(), "typewriter".into()),
    ]))?;
    let connection = database.get_or_create_connection(&database_key).await?;
    database_schema::Preset::Full
        .apply(&*connection.read().await)
        .await
        .context("applying the database schema")?;

    let routes: BTreeMap<&'static str, String> = WIRING
        .iter()
        .filter_map(|wiring| Some((wiring.http_path?, wiring.package.to_owned())))
        .collect();
    let ingress = Arc::new(
        Ingress::builder(
            PathRouter { routes },
            SocketAddr::new(Ipv4Addr::LOCALHOST.into(), args.http),
        )
        .outgoing_handler(IdentityForwarder {
            authority: format!("127.0.0.1:{}", args.identity),
            client: reqwest::Client::new(),
        })
        .build()
        .await
        .context("binding the HTTP routes")?,
    );
    let nats = Arc::new(WasmcloudNats::new());
    let plugins: Vec<Arc<dyn HostPlugin>> = vec![
        Arc::new(DynamicConfig::default()),
        Arc::new(TracingLogger::default()),
        Arc::new(WasiOtel::new(WasiOtelConfig::builder().build())),
        nats,
        database,
    ];
    let bindings = PluginBindings::new().with_plugin(
        PluginBindingSet::new("wasmcloud-nats")
            .with_workload_config(WorkloadConfigPolicy::Deny)
            .with_base(HashMap::from([
                ("servers".into(), broker.endpoint.clone()),
                ("jwt".into(), broker.host_jwt.clone()),
                ("nkey-seed".into(), broker.host_seed.clone()),
                ("subject-allow".into(), ">".into()),
                ("stream-allow".into(), "TYPEWRITER_MEMBERSHIP".into()),
            ])),
    );
    let mut builder = HostBuilder::new()
        .with_engine(Engine::builder().build()?)
        .with_plugin_bindings(bindings)
        .with_friendly_name("typewriter-stack")
        .with_http_handler(ingress);
    for plugin in plugins {
        builder = builder.with_plugin(plugin)?;
    }
    let host = builder
        .build()?
        .start()
        .await
        .context("starting the host")?;

    let artifacts: HashMap<String, PathBuf> = args.components.into_iter().collect();
    for wiring in WIRING {
        let artifact = artifacts
            .get(wiring.package)
            .with_context(|| format!("xtask passed no artifact for `{}`", wiring.package))?;
        let workload = workload(wiring, artifact, &broker, &identity, &database_key)?;
        let response = host
            .workload_start(WorkloadStartRequest {
                workload_id: wiring.package.to_owned(),
                workload,
            })
            .await
            .with_context(|| format!("starting {}", wiring.package))?;
        let status = response.workload_status;
        ensure!(
            status.workload_state == WorkloadState::Running,
            "{} did not reach Running: {:?}: {}",
            wiring.package,
            status.workload_state,
            status.message
        );
        tracing::info!(component = wiring.package, "running");
    }
    let unwired: Vec<&String> = artifacts
        .keys()
        .filter(|package| !WIRING.iter().any(|wiring| wiring.package == *package))
        .collect();
    if !unwired.is_empty() {
        bail!("the stack does not know how to wire {unwired:?}; add them to WIRING");
    }

    std::fs::write(&ready_file, "")?;
    crate::shutdown_signal().await;
    host.stop().await
}

fn workload(
    wiring: &Wiring,
    artifact: &PathBuf,
    broker: &BrokerConnection,
    identity: &str,
    database: &ConnectionKey,
) -> Result<Workload> {
    let name = wiring.package.replace('-', "_");
    let mut interfaces = vec![WitInterface::from("wasi:otel/tracing@0.2.0-rc.2")];
    if !wiring.subscriptions.is_empty() {
        let mut nats = WitInterface::from("wasmcloud:nats/core-handler,core,jetstream@0.1.0");
        nats.config.insert("component".into(), name.clone());
        nats.config
            .insert("core-subscriptions".into(), wiring.subscriptions.join(","));
        interfaces.push(nats);
    }
    if wiring.http_path.is_some() {
        interfaces.push(WitInterface::from("wasi:http/incoming-handler@0.3.0"));
    }
    if wiring.database {
        let mut surrealdb = WitInterface::from("seamlezz:surrealdb/call@0.4.0");
        surrealdb.config.insert("url".into(), database.url.clone());
        surrealdb
            .config
            .insert("namespace".into(), database.namespace.clone());
        surrealdb
            .config
            .insert("database".into(), database.database.clone());
        interfaces.push(surrealdb);
    }
    let allowed_hosts: Vec<AllowedHost> = if wiring.identity {
        vec![identity.parse()?]
    } else {
        Vec::new()
    };
    let bytes =
        std::fs::read(artifact).with_context(|| format!("cannot read {}", artifact.display()))?;
    Ok(Workload {
        namespace: "typewriter".into(),
        name: wiring.package.into(),
        annotations: HashMap::new(),
        service: None,
        components: vec![Component {
            name,
            bytes: Bytes::from(bytes),
            local_resources: LocalResources {
                environment: environment(wiring.package, broker, identity),
                allowed_hosts: allowed_hosts.into(),
                ..Default::default()
            },
            pool_size: 1,
            max_invocations: -1,
            max_concurrency: 1,
            ..Default::default()
        }],
        host_interfaces: interfaces,
        volumes: Vec::new(),
    })
}

/// The secrets and settings each component reads, from the stack's broker keys and the identity
/// stand in instead of the cluster's secret store.
fn environment(
    package: &str,
    broker: &BrokerConnection,
    identity: &str,
) -> HashMap<String, String> {
    let issuers: Vec<_> = ["typewriter-panel", "typewriter-services"]
        .into_iter()
        .map(|app| {
            json!({
                "id": app,
                "issuer_url": format!("{identity}/application/o/{app}/"),
                "jwks_url": format!("{identity}/application/o/{app}/jwks/"),
                "audiences": [app],
                "require_expiration": true,
                "clock_skew_seconds": 30,
                "nats_account_key": broker.typewriter_account,
            })
        })
        .collect();
    match package {
        "auth-callout" => HashMap::from([
            (
                "NATS_ISSUER_SEED".into(),
                broker.callout_issuer_seed.clone(),
            ),
            (
                "ISSUERS".into(),
                serde_json::Value::from(issuers).to_string(),
            ),
            (
                "NATS_SIGNING_KEYS".into(),
                json!({
                    "typewriter-panel": broker.typewriter_signing_seed,
                    "typewriter-services": broker.typewriter_signing_seed,
                })
                .to_string(),
            ),
        ]),
        "auth-sentinel" => {
            HashMap::from([("NATS_SENTINEL_CREDS".into(), broker.sentinel_creds.clone())])
        }
        "service-identity" => HashMap::from([
            ("AUTHENTIK_URL".into(), identity.to_owned()),
            ("AUTHENTIK_TOKEN".into(), API_TOKEN.into()),
        ]),
        _ => HashMap::new(),
    }
}

/// The toxiproxy link `nats-proxy` → broker, so scenarios can cut the panel's connection.
async fn create_faults_link(args: &HostArgs, broker: &BrokerConnection) -> Result<()> {
    let upstream = broker
        .endpoint
        .strip_prefix("nats://")
        .unwrap_or(&broker.endpoint);
    let response = reqwest::Client::new()
        .post(format!("http://127.0.0.1:{}/proxies", args.faults))
        .json(&json!({
            "name": "nats",
            "listen": format!("127.0.0.1:{}", args.nats_proxy),
            "upstream": upstream,
            "enabled": true,
        }))
        .send()
        .await
        .context("creating the faults link")?;
    ensure!(
        response.status().is_success(),
        "toxiproxy refused the faults link: {}",
        response.text().await.unwrap_or_default()
    );
    Ok(())
}

/// Routes the cluster's exact public paths to their workloads on one address.
struct PathRouter {
    routes: BTreeMap<&'static str, String>,
}

#[async_trait::async_trait]
impl Router for PathRouter {
    async fn on_workload_resolved(
        &self,
        _: &wash_runtime::engine::workload::ResolvedWorkload,
        _: &str,
    ) -> Result<()> {
        Ok(())
    }

    async fn on_workload_unbind(&self, _: &str) -> Result<()> {
        Ok(())
    }

    fn allow_outgoing_request(
        &self,
        _: &str,
        request: &hyper::Request<WasiBody>,
        _: Option<RequestOptions>,
        allowed_hosts: &[AllowedHost],
    ) -> Result<()> {
        check_allowed_hosts(request, allowed_hosts)
    }

    fn route_incoming_request(
        &self,
        request: &hyper::Request<hyper::body::Incoming>,
    ) -> Result<String, RouteError> {
        let path = request.uri().path();
        self.routes
            .get(path)
            .cloned()
            .ok_or_else(|| RouteError::NoWorkloadForPath {
                host: String::new(),
                path: path.to_owned(),
            })
    }
}

/// Sends component HTTP calls to the identity stand in and refuses every other destination.
#[derive(Clone)]
struct IdentityForwarder {
    authority: String,
    client: reqwest::Client,
}

impl OutgoingHandler for IdentityForwarder {
    fn send_request(
        &self,
        _: &str,
        request: hyper::Request<WasiBody>,
        _: Option<RequestOptions>,
        _: RequestIoFuture,
    ) -> SendFuture {
        let this = self.clone();
        Box::new(async move {
            let failed = |error: String| HttpError::InternalError(Some(error));
            let (parts, body) = buffered(request).await?;
            let authority = parts.uri.authority().map(|authority| authority.as_str());
            if authority != Some(this.authority.as_str()) {
                return Err(failed(format!(
                    "the stack only allows HTTP to the identity stand in, not {authority:?}"
                )));
            }
            let response = this
                .client
                .request(parts.method, parts.uri.to_string())
                .headers(parts.headers)
                .body(body)
                .send()
                .await
                .map_err(|error| failed(error.to_string()))?;
            let (status, headers) = (response.status(), response.headers().clone());
            let body = response
                .bytes()
                .await
                .map_err(|error| failed(error.to_string()))?;
            wasi_response(status, headers, body)
        })
    }
}
