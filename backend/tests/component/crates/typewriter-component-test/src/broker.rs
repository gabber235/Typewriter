//! Broker users for component cases: a NATS connection that holds exactly the grants a permission
//! reply gives, so a case checks what the broker enforces rather than what the grants say.

use std::time::Duration;

use anyhow::Context as _;
use async_nats::{Client, Event, Subscriber};
use futures_util::StreamExt;
use nats_broker::{Account, Broker, Credentials};
use tokio::sync::mpsc;
use wasmcloud_utils::skir::base::access::v1::permission::Permissions;

/// How long a message the broker must deliver may take. Generous because the whole suite shares
/// one broker and one machine; a passing case never waits it out.
pub const WAIT: Duration = Duration::from_secs(10);
/// How long a message the broker refused is given to arrive anyway.
pub const SILENCE: Duration = Duration::from_millis(300);

/// A broker connection that reports the errors the broker sends it.
pub struct Connection {
    account: Account,
    client: Client,
    errors: mpsc::UnboundedReceiver<String>,
}

impl Connection {
    /// Connects with `credentials` to `account`'s broker endpoint.
    pub async fn open(account: &Account, credentials: &Credentials) -> anyhow::Result<Self> {
        let (sender, errors) = mpsc::unbounded_channel();
        let key = nkeys::KeyPair::from_seed(credentials.seed())?;
        let client =
            async_nats::ConnectOptions::with_jwt(credentials.jwt().to_owned(), move |nonce| {
                let key = key.clone();
                async move { key.sign(&nonce).map_err(async_nats::AuthError::new) }
            })
            .event_callback(move |event| {
                let sender = sender.clone();
                async move {
                    if let Event::ServerError(error) = event {
                        // The receiver lives as long as the case; a closed one has nothing to tell.
                        drop(sender.send(error.to_string()));
                    }
                }
            })
            .connect(account.endpoint())
            .await?;
        Ok(Self {
            account: account.clone(),
            client,
            errors,
        })
    }

    /// A broker user holding exactly what the component granted.
    pub async fn granted(account: &Account, permissions: Permissions) -> anyhow::Result<Self> {
        let credentials = account.user(&nats_permissions::convert_permissions(permissions))?;
        Self::open(account, &credentials).await
    }

    /// Subscribes and waits until the broker has registered the subscription.
    pub async fn subscribe(&self, subject: &str) -> anyhow::Result<Subscriber> {
        let subscriber = self.client.subscribe(subject.to_owned()).await?;
        self.client.flush().await?;
        self.account
            .subscription_registered(&self.client, subject)
            .await?;
        Ok(subscriber)
    }

    /// Publishes `body` on `subject`, naming `reply` as the reply subject when given.
    pub async fn publish(
        &self,
        subject: &str,
        reply: Option<&str>,
        body: &str,
    ) -> anyhow::Result<()> {
        match reply {
            Some(reply) => {
                self.client
                    .publish_with_reply(
                        subject.to_owned(),
                        reply.to_owned(),
                        body.to_owned().into(),
                    )
                    .await?
            }
            None => {
                self.client
                    .publish(subject.to_owned(), body.to_owned().into())
                    .await?
            }
        }
        self.client.flush().await?;
        Ok(())
    }

    /// Whether the broker refused one of this connection's publishes.
    pub async fn publish_was_refused(&mut self) -> bool {
        tokio::time::timeout(WAIT, async {
            while let Some(error) = self.errors.recv().await {
                if error.contains("Permissions Violation for Publish") {
                    return true;
                }
            }
            false
        })
        .await
        .unwrap_or(false)
    }

    /// Publishes `presence` with `secret` as its reply, receives the echo the broker delivers to
    /// this connection and answers the echoed reply with `self answer`.
    pub async fn answer_own_echo(&self, presence: &str, secret: &str) -> anyhow::Result<()> {
        let mut echoes = self.subscribe(presence).await?;
        self.publish(presence, Some(secret), "presence").await?;
        let echo = receive(&mut echoes).await?;
        let reply = echo.reply.context("the echo carries the named reply")?;
        assert_eq!(reply.as_str(), secret);
        self.publish(&reply, None, "self answer").await
    }
}

/// The next message on `subscriber` within `wait`, if one arrives.
pub async fn next_within(
    subscriber: &mut Subscriber,
    wait: Duration,
) -> Option<async_nats::Message> {
    tokio::time::timeout(wait, subscriber.next())
        .await
        .ok()
        .flatten()
}

/// The next message on `subscriber` within [`WAIT`].
pub async fn receive(subscriber: &mut Subscriber) -> anyhow::Result<async_nats::Message> {
    next_within(subscriber, WAIT)
        .await
        .context("no message arrived")
}

/// Runs `case` on a fresh broker account and deletes the account afterwards.
pub async fn on_broker<T>(
    case: impl AsyncFnOnce(&Account) -> anyhow::Result<T>,
) -> anyhow::Result<T> {
    let broker = Broker::shared().await?;
    let account = broker.account().await?;
    let result = case(&account).await;
    broker.delete(&account).await?;
    result
}
