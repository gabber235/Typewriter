//! One account per fixture on the test process's shared NATS broker. The driver owns the account
//! and observer lifetime.

use std::{sync::Arc, time::Duration};

use anyhow::{Context, Result, bail};
use futures_util::StreamExt;
use nats_broker::{Account, Broker, Credentials};
use tokio::sync::{Mutex, mpsc, oneshot};
use wash_runtime::plugin::wasmcloud_nats::WasmcloudNats;

use crate::{MessagingMock, Stream};

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

#[derive(Clone)]
pub(crate) struct NatsDriver {
    /// The case's own account on the shared broker; deleted in [`NatsDriver::close`].
    pub account: Account,
    /// What the host's NATS plugin signs in with.
    pub credentials: Credentials,
    pub plugin: Arc<WasmcloudNats>,
    client: async_nats::Client,
    workload_id: String,
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
    pub async fn start(workload_id: &str, streams: &[Stream]) -> Result<Self> {
        let account = Broker::shared().await?.account().await?;
        let credentials = account.admin()?;
        let client = credentials
            .connect(account.endpoint())
            .await
            .context("connecting fixture client")?;
        let jetstream = async_nats::jetstream::new(client.clone());
        for stream in streams {
            jetstream
                .create_stream(async_nats::jetstream::stream::Config {
                    name: stream.name.clone(),
                    subjects: stream.subjects.clone(),
                    storage: async_nats::jetstream::stream::StorageType::Memory,
                    ..Default::default()
                })
                .await
                .with_context(|| format!("creating stream `{}`", stream.name))?;
        }
        Ok(Self {
            account,
            credentials,
            client,
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

    /// Sends `message` and waits up to `timeout` for the reply. The client's own request
    /// timeout (ten seconds by default) is bypassed so that `timeout` is the only bound.
    pub async fn request(&self, message: HostMessage, timeout: Duration) -> Result<HostMessage> {
        let response = tokio::time::timeout(
            timeout,
            self.client.send_request(
                message.subject,
                async_nats::Request::new()
                    .headers(input_headers())
                    .payload(message.body.into())
                    .timeout(None),
            ),
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
                        if message.subject.starts_with("$JS.") || message.subject.starts_with("_INBOX.") || message.subject.starts_with("_INBOX_") || message.headers.as_ref().is_some_and(|h| h.get(INPUT_HEADER).is_some()) { continue; }
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
        Broker::shared().await?.delete(&self.account).await
    }
}

/// Marks a message the test injected, so the observer never records it as component output.
const INPUT_HEADER: &str = "Component-Test-Input";

fn input_headers() -> async_nats::HeaderMap {
    let mut headers = async_nats::HeaderMap::new();
    headers.insert(INPUT_HEADER, "true");
    headers
}
