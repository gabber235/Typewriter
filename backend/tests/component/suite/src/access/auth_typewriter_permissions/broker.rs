//! The component's own grants, enforced by a real broker. Each case turns a permission reply into
//! a broker user with the auth callout's conversion, so neither the grants nor their conversion is
//! rebuilt here.

use std::time::Duration;

use anyhow::Context as _;
use async_nats::{Client, Event, Subscriber};
use futures_util::StreamExt;
use nats_broker::{Account, Broker, Credentials};
use tokio::sync::mpsc;
use typewriter_component_test::prelude::*;
use wasmcloud_utils::{
    skir::base::access::v1::permission::Permissions, transport_routes::SERVICE_RESPONSE_LIMIT,
};

use super::{
    AuthTypewriterPermissions, Context, Realm, panel::SESSION, panel::member_grants,
    service::service_grants,
};

/// How long a message the broker must deliver may take. Generous because the whole suite shares
/// one broker and one machine; a passing case never waits it out.
const WAIT: Duration = Duration::from_secs(10);
/// How long a message the broker refused is given to arrive anyway.
const SILENCE: Duration = Duration::from_millis(300);

/// A route of Acme's realm `quests` that a panel member calls and the realm host serves.
const OWN_REALM: &str = "service.to.quests.organization.acme.realm.editor.catalog.fetch";
/// The same route in another organization.
const FOREIGN_REALM: &str = "service.to.quests.organization.globex.realm.editor.catalog.fetch";

/// A broker connection that reports the errors the broker sends it.
struct Connection {
    client: Client,
    errors: mpsc::UnboundedReceiver<String>,
}

impl Connection {
    async fn open(account: &Account, credentials: &Credentials) -> anyhow::Result<Self> {
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
        Ok(Self { client, errors })
    }

    /// A broker user holding exactly what the component granted.
    async fn granted(account: &Account, permissions: Permissions) -> anyhow::Result<Self> {
        let credentials = account.user(&auth_callout::convert_permissions(permissions))?;
        Self::open(account, &credentials).await
    }

    /// Subscribes and waits until the broker has registered the subscription.
    async fn subscribe(&self, subject: &str) -> anyhow::Result<Subscriber> {
        let subscriber = self.client.subscribe(subject.to_owned()).await?;
        self.client.flush().await?;
        Ok(subscriber)
    }

    async fn publish(&self, subject: &str, reply: Option<&str>, body: &str) -> anyhow::Result<()> {
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
    async fn publish_was_refused(&mut self) -> bool {
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
}

async fn next_within(subscriber: &mut Subscriber, wait: Duration) -> Option<async_nats::Message> {
    tokio::time::timeout(wait, subscriber.next())
        .await
        .ok()
        .flatten()
}

async fn receive(subscriber: &mut Subscriber) -> anyhow::Result<async_nats::Message> {
    next_within(subscriber, WAIT)
        .await
        .context("no message arrived")
}

/// Runs `case` on a fresh broker account and deletes the account afterwards.
async fn on_broker<T>(case: impl AsyncFnOnce(&Account) -> anyhow::Result<T>) -> anyhow::Result<T> {
    let broker = Broker::shared().await?;
    let account = broker.account().await?;
    let result = case(&account).await;
    broker.delete(&account).await?;
    result
}

/// Ada's reply inbox for this connection session.
fn inbox(name: &str) -> String {
    format!("_INBOX.{}.{SESSION}.{name}", ada().token())
}

#[component_test(AuthTypewriterPermissions)]
async fn panel_grants_are_enforced_by_the_broker(context: &mut Context) -> TestResult {
    let granted = member_grants(context).await?;

    on_broker(async |account| {
        let mut panel = Connection::granted(account, granted).await?;
        let service = Connection::open(account, &account.admin()?).await?;

        let mut own = service.subscribe(OWN_REALM).await?;
        panel.publish(OWN_REALM, None, "fetch").await?;
        assert!(next_within(&mut own, WAIT).await.is_some());

        // Another organization's realm never sees the message, and the broker says why.
        let mut foreign = service.subscribe(FOREIGN_REALM).await?;
        panel.publish(FOREIGN_REALM, None, "fetch").await?;
        assert!(panel.publish_was_refused().await);
        assert!(next_within(&mut foreign, SILENCE).await.is_none());
        Ok(())
    })
    .await
}

#[component_test(AuthTypewriterPermissions)]
async fn a_panel_user_cannot_answer_its_own_message_to_reach_another_subject(
    context: &mut Context,
) -> TestResult {
    let granted = member_grants(context).await?;
    // The same grants with a response permission show that the self answer is a real attack.
    let escalating = Permissions {
        response: Some(Default::default()),
        ..granted.clone()
    };
    let secret = "secret.outside.panel.grants";
    let presence = format!(
        "typewriter.presence.organization.acme.user.{}",
        ada().token()
    );

    on_broker(async |account| {
        let watcher = Connection::open(account, &account.admin()?).await?;
        let mut secrets = watcher.subscribe(secret).await?;

        let mut panel = Connection::granted(account, granted).await?;
        self_answer(&panel, &presence, secret).await?;
        assert!(panel.publish_was_refused().await);
        assert!(next_within(&mut secrets, SILENCE).await.is_none());

        let escalating = Connection::granted(account, escalating).await?;
        self_answer(&escalating, &presence, secret).await?;
        assert_eq!(receive(&mut secrets).await?.payload, "self answer");
        Ok(())
    })
    .await
}

/// Publishes on the presence subject naming `secret` as the reply, receives the echo and answers
/// it.
async fn self_answer(client: &Connection, presence: &str, secret: &str) -> anyhow::Result<()> {
    let mut echoes = client.subscribe(presence).await?;
    client.publish(presence, Some(secret), "presence").await?;
    let echo = receive(&mut echoes).await?;
    let reply = echo.reply.context("the echo carries the named reply")?;
    assert_eq!(reply.as_str(), secret);
    client.publish(&reply, None, "self answer").await
}

#[component_test(AuthTypewriterPermissions)]
async fn a_service_reply_reaches_the_panel_up_to_its_limit(context: &mut Context) -> TestResult {
    let panel_grants = member_grants(context).await?;
    let host_grants = service_grants(context, "realm_host", Realm::Owned("quests")).await?;
    let limit = SERVICE_RESPONSE_LIMIT.context("services answer requests")?;

    on_broker(async |account| {
        let panel = Connection::granted(account, panel_grants).await?;
        let mut host = Connection::granted(account, host_grants.clone()).await?;
        let replica = Connection::granted(account, host_grants).await?;
        let mut requests = host.subscribe(OWN_REALM).await?;
        let mut replica_requests = replica.subscribe(OWN_REALM).await?;
        let reply_to = inbox("fetch");
        let mut replies = panel.subscribe(&reply_to).await?;

        panel.publish(OWN_REALM, Some(&reply_to), "fetch").await?;
        let request = receive(&mut requests)
            .await
            .context("the host receives the request")?;
        let reply = request.reply.context("the request names the panel inbox")?;
        assert_eq!(reply.as_str(), reply_to);
        for frame in 0..limit {
            host.publish(&reply, None, &format!("frame {frame}"))
                .await?;
        }
        for frame in 0..limit {
            assert_eq!(
                receive(&mut replies)
                    .await
                    .with_context(|| format!("frame {frame} reaches the panel"))?
                    .payload,
                format!("frame {frame}")
            );
        }

        host.publish(&reply, None, "one too many").await?;
        assert!(host.publish_was_refused().await);
        assert!(next_within(&mut replies, SILENCE).await.is_none());

        // The limit belongs to each responder: another one that received the request may still answer.
        receive(&mut replica_requests)
            .await
            .context("the replica receives the request")?;
        replica.publish(&reply, None, "replica").await?;
        assert_eq!(
            receive(&mut replies)
                .await
                .context("the replica's answer reaches the panel")?
                .payload,
            "replica"
        );
        Ok(())
    })
    .await
}

#[component_test(AuthTypewriterPermissions)]
async fn a_service_cannot_reply_to_an_inbox_that_asked_nothing(
    context: &mut Context,
) -> TestResult {
    let panel_grants = member_grants(context).await?;
    let host_grants = service_grants(context, "realm_host", Realm::Owned("quests")).await?;

    on_broker(async |account| {
        let panel = Connection::granted(account, panel_grants).await?;
        let mut host = Connection::granted(account, host_grants).await?;
        let mut requests = host.subscribe(OWN_REALM).await?;
        let asked = inbox("asked");
        let unasked = inbox("unasked");
        let mut unasked_replies = panel.subscribe(&unasked).await?;
        let mut asked_replies = panel.subscribe(&asked).await?;

        panel.publish(OWN_REALM, Some(&asked), "fetch").await?;
        receive(&mut requests).await?;
        host.publish(&unasked, None, "uninvited").await?;
        assert!(host.publish_was_refused().await);
        assert!(next_within(&mut unasked_replies, SILENCE).await.is_none());

        host.publish(&asked, None, "invited").await?;
        assert_eq!(receive(&mut asked_replies).await?.payload, "invited");
        Ok(())
    })
    .await
}

#[component_test(AuthTypewriterPermissions)]
async fn a_service_cannot_reply_after_its_reply_permission_expires(
    context: &mut Context,
) -> TestResult {
    let panel_grants = member_grants(context).await?;
    let mut host_grants = service_grants(context, "realm_host", Realm::Owned("quests")).await?;
    // The granted expiry is minutes long; a short one lets the case observe it pass.
    host_grants
        .response
        .as_mut()
        .and_then(|response| response.ttl.as_mut())
        .context("a service reply permission expires")?
        .milliseconds = 500;

    on_broker(async |account| {
        let panel = Connection::granted(account, panel_grants).await?;
        let mut host = Connection::granted(account, host_grants).await?;
        let mut requests = host.subscribe(OWN_REALM).await?;
        let reply_to = inbox("late");
        let mut replies = panel.subscribe(&reply_to).await?;

        panel.publish(OWN_REALM, Some(&reply_to), "fetch").await?;
        let request = receive(&mut requests).await?;
        let reply = request.reply.context("the request names the panel inbox")?;
        tokio::time::sleep(Duration::from_millis(700)).await;
        host.publish(&reply, None, "late").await?;

        assert!(host.publish_was_refused().await);
        assert!(next_within(&mut replies, SILENCE).await.is_none());
        Ok(())
    })
    .await
}
