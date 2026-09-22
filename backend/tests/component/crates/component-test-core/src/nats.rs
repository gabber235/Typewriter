//! One real NATS process per fixture. The driver owns broker and observer lifetime.

use std::{process::Stdio, sync::Arc, time::Duration};

use anyhow::{Context, Result, bail};
use futures_util::StreamExt;
use tokio::{
    io::{AsyncBufReadExt, BufReader},
    process::{Child, Command},
    sync::{Mutex, mpsc, oneshot},
};
use wash_runtime::plugin::wasmcloud_nats::WasmcloudNats;

use crate::MessagingMock;

pub(crate) struct HostMessage {
    pub subject: String,
    pub reply_to: Option<String>,
    pub body: Vec<u8>,
}

pub(crate) struct ResponderRequest {
    pub message: HostMessage,
    client: async_nats::Client,
}

impl ResponderRequest {
    pub async fn reply(self, message: HostMessage) -> Result<()> {
        self.client
            .publish_with_headers(message.subject, input_headers(), message.body.into())
            .await?;
        Ok(())
    }
}

struct Broker {
    _storage: tempfile::TempDir,
    child: Mutex<Child>,
    stderr: tokio::task::JoinHandle<()>,
}

impl Drop for Broker {
    fn drop(&mut self) {
        self.stderr.abort();
    }
}

#[derive(Clone)]
pub(crate) struct NatsDriver {
    pub endpoint: String,
    pub plugin: Arc<WasmcloudNats>,
    client: async_nats::Client,
    workload_id: String,
    broker: Arc<Broker>,
    observer: Arc<Mutex<Option<Observer>>>,
}

struct Observer {
    fences: mpsc::Sender<oneshot::Sender<()>>,
    task: tokio::task::JoinHandle<Result<()>>,
}

impl Drop for Observer {
    fn drop(&mut self) {
        self.task.abort();
    }
}

impl NatsDriver {
    pub async fn start(workload_id: &str) -> Result<Self> {
        let binary = std::env::var_os("NATS_SERVER_BIN").unwrap_or_else(|| "nats-server".into());
        let storage = tempfile::tempdir()?;
        let mut child = Command::new(binary)
            .args([
                "--addr",
                "127.0.0.1",
                "--port",
                "-1",
                "--jetstream",
                "--store_dir",
            ])
            .arg(storage.path())
            .stdout(Stdio::null())
            .stderr(Stdio::piped())
            .kill_on_drop(true)
            .spawn()
            .context("starting isolated NATS server; install nats-server or set NATS_SERVER_BIN")?;
        let mut lines =
            BufReader::new(child.stderr.take().context("NATS stderr unavailable")?).lines();
        let endpoint = tokio::time::timeout(Duration::from_secs(10), async {
            let mut endpoint = None;
            while let Some(line) = lines.next_line().await? {
                if let Some((_, address)) = line.split_once("Listening for client connections on ")
                {
                    endpoint = Some(format!("nats://{}", address.trim()));
                }
                if line.contains("Server is ready") {
                    return endpoint.context("NATS announced readiness without a client address");
                }
            }
            bail!("NATS exited before readiness")
        })
        .await
        .context("NATS startup timed out")??;
        let stderr =
            tokio::spawn(async move { while let Ok(Some(_)) = lines.next_line().await {} });
        let broker = Arc::new(Broker {
            _storage: storage,
            child: Mutex::new(child),
            stderr,
        });
        let client = async_nats::connect(&endpoint)
            .await
            .context("connecting fixture client")?;
        async_nats::jetstream::new(client.clone())
            .create_stream(async_nats::jetstream::stream::Config {
                name: "TYPEWRITER_MEMBERSHIP".into(),
                subjects: vec![
                    "typewriter.to.organization.*.members.changed".into(),
                    "typewriter.to.organization.*.join_requests.changed".into(),
                    "typewriter.to.organization.*.join_codes.changed".into(),
                    "typewriter.to.user.*.join_requests.changed".into(),
                    "typewriter.to.user.*.organizations.changed".into(),
                ],
                storage: async_nats::jetstream::stream::StorageType::Memory,
                ..Default::default()
            })
            .await?;
        Ok(Self {
            endpoint,
            client,
            broker,
            workload_id: workload_id.into(),
            plugin: Arc::new(WasmcloudNats::new()),
            observer: Arc::new(Mutex::new(None)),
        })
    }

    pub async fn publish(&self, message: HostMessage) -> Result<()> {
        self.client
            .publish_with_headers(message.subject, input_headers(), message.body.into())
            .await?;
        wash_runtime::plugin::wasmcloud_nats::synchronize(&self.client).await?;
        Ok(())
    }

    pub async fn request(&self, message: HostMessage, timeout: Duration) -> Result<HostMessage> {
        let response = tokio::time::timeout(
            timeout,
            self.client
                .request_with_headers(message.subject, input_headers(), message.body.into()),
        )
        .await??;
        Ok(HostMessage {
            subject: response.subject.to_string(),
            reply_to: response.reply.map(|s| s.to_string()),
            body: response.payload.to_vec(),
        })
    }

    pub async fn observe(&self, mock: MessagingMock) -> Result<()> {
        let mut messages = self.client.subscribe(">".to_string()).await?;
        wash_runtime::plugin::wasmcloud_nats::synchronize(&self.client).await?;
        let (fences, mut receiver) = mpsc::channel::<oneshot::Sender<()>>(1);
        let client = self.client.clone();
        let task = tokio::spawn(async move {
            let mut replies = tokio::task::JoinSet::new();
            loop {
                tokio::select! {
                    biased;
                    result = replies.join_next(), if !replies.is_empty() => { result.context("reply task missing")???; },
                    message = messages.next() => {
                        let Some(message) = message else { bail!("NATS observer disconnected"); };
                        if message.subject.starts_with("$JS.") || message.subject.starts_with("_INBOX.") || message.headers.as_ref().is_some_and(|h| h.get("Typewriter-Test-Input").is_some()) { continue; }
                        let message = HostMessage {
                            subject: message.subject.to_string(), reply_to: message.reply.map(|s| s.to_string()),
                            body: message.payload.to_vec(),
                        };
                        if message.reply_to.is_some() {
                            let request = ResponderRequest { message, client: client.clone() };
                            if let Some(response) = mock.record_request(&request) {
                                replies.spawn(async move { response.send(request).await });
                            }
                        } else { mock.record_publish(&message); }
                    },
                    fence = receiver.recv(), if replies.is_empty() => {
                        match fence { Some(fence) => { let _ = fence.send(()); }, None => return Ok(()) }
                    },
                }
            }
        });
        *self.observer.lock().await = Some(Observer { fences, task });
        Ok(())
    }

    pub async fn wait_idle(&self) -> Result<()> {
        wash_runtime::plugin::wasmcloud_nats::synchronize(&self.client).await?;
        self.plugin.wait_core_idle(&self.workload_id).await?;
        wash_runtime::plugin::wasmcloud_nats::synchronize(&self.client).await?;
        let observer = self.observer.lock().await;
        if let Some(observer) = &*observer {
            let (tx, rx) = oneshot::channel();
            observer
                .fences
                .send(tx)
                .await
                .context("NATS observer stopped")?;
            rx.await.context("NATS observation fence cancelled")?;
        }
        Ok(())
    }

    pub async fn stop_observer(&self) -> Result<()> {
        self.wait_idle().await?;
        self.observer.lock().await.take();
        Ok(())
    }

    pub async fn close(&self) -> Result<()> {
        self.observer.lock().await.take();
        self.broker.child.lock().await.kill().await?;
        Ok(())
    }
}

fn input_headers() -> async_nats::HeaderMap {
    let mut headers = async_nats::HeaderMap::new();
    headers.insert("Typewriter-Test-Input", "true");
    headers
}
