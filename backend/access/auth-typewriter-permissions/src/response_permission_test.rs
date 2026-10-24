//! Response permissions enforced by a real NATS broker, as the auth callout hands them out.

use std::{collections::BTreeSet, process::Stdio, time::Duration};

use anyhow::{Context, Result, bail};
use async_nats::{Client, ConnectOptions, Event, Subscriber};
use futures_util::StreamExt;
use tokio::{
    io::{AsyncBufReadExt, BufReader},
    process::{Child, Command},
    sync::mpsc,
};
use wasmcloud_utils::skir::base::access::v1::permission::{Permissions, ResponsePermission};
use wasmcloud_utils::transport::{
    CHUNK_HEADER, ConnectionSession, GrantSet, OrganizationActorScope, PAYLOAD_HEADER, RealmScope,
    SubjectToken, UserScope,
};
use wasmcloud_utils::transport_routes::{
    OrganizationActorRole, REPLY_TTL_MS, RealmRole, SERVICE_RESPONSE_LIMIT, UserRole,
    WINDOW_FRAMES, panel_reply_inbox_prefix,
};

use crate::common::response_permission;
use crate::users::panel_permissions;

const REQUEST_SUBJECT: &str = "service.from.quests.organization.writers.realm.rollout.probe";
const READINESS_SUBJECT: &str = "fixture.ready";
const PASSWORD: &str = "fixture-secret";
const FIRST_REPLY: &str = "_INBOX.requester.first";
const ARBITRARY_REPLY: &str = "_INBOX.requester.arbitrary";
const ARBITRARY_VALID_REPLY: &str = "_INBOX.requester.arbitrary_valid";
const EXPIRED_REPLY: &str = "_INBOX.requester.expired";
/// A subject outside every panel grant, which a self answer must never reach.
const SECRET_SUBJECT: &str = "secret.outside.panel.grants";
const PANEL_USER: &str = "alice";
const PANEL_ORGANIZATION: &str = "writers";
const PANEL_SESSION: &str = "0123456789abcdef0123456789abcdef";

struct Broker {
    _directory: tempfile::TempDir,
    child: Child,
    stderr: tokio::task::JoinHandle<()>,
    endpoint: String,
}

impl Broker {
    async fn close(mut self) -> Result<()> {
        self.child.kill().await?;
        self.stderr.abort();
        Ok(())
    }
}

impl Drop for Broker {
    fn drop(&mut self) {
        let _ = self.child.start_kill();
        self.stderr.abort();
    }
}

/// One broker user: its publish and subscribe allow lists and its optional response permission.
struct FixtureUser<'a> {
    name: &'a str,
    publish: BTreeSet<String>,
    subscribe: BTreeSet<String>,
    response: Option<(i32, i64)>,
}

impl<'a> FixtureUser<'a> {
    fn new(name: &'a str, publish: &[&str], subscribe: &[&str]) -> Self {
        let subjects = |subjects: &[&str]| {
            subjects
                .iter()
                .map(|subject| (*subject).to_owned())
                .collect()
        };
        Self {
            name,
            publish: subjects(publish),
            subscribe: subjects(subscribe),
            response: None,
        }
    }

    /// A broker user holding exactly the policy the auth callout hands out.
    fn granted(name: &'a str, permissions: &Permissions) -> Result<Self> {
        let user = Self {
            name,
            publish: permissions.publish.allow.iter().cloned().collect(),
            subscribe: permissions.subscribe.allow.iter().cloned().collect(),
            response: None,
        };
        match &permissions.response {
            Some(response) => user.responding(response),
            None => Ok(user),
        }
    }

    fn responding(mut self, response: &ResponsePermission) -> Result<Self> {
        self.response = Some((
            response.max_messages.context("response maximum missing")?,
            response
                .ttl
                .as_ref()
                .context("response expiration missing")?
                .milliseconds,
        ));
        Ok(self)
    }
}

#[tokio::test]
async fn a_service_sends_at_most_its_reply_limit_to_each_requester() -> Result<()> {
    let mut grants = GrantSet::default();
    RealmScope {
        organization: SubjectToken::try_from("writers")
            .map_err(|error| anyhow::anyhow!(error.to_string()))?,
        realm: SubjectToken::try_from("quests")
            .map_err(|error| anyhow::anyhow!(error.to_string()))?,
    }
    .grant(RealmRole::RealmParticipant, &mut grants);
    assert!(grants.subscribe.contains(REQUEST_SUBJECT));

    let limit = SERVICE_RESPONSE_LIMIT.context("services must answer requests")?;
    let mut response = response_permission(limit);
    assert_eq!(
        response.ttl.as_ref().map(|duration| duration.milliseconds),
        Some(REPLY_TTL_MS)
    );
    // A short expiry lets the test observe a late reply being refused.
    response
        .ttl
        .as_mut()
        .context("response expiration missing")?
        .milliseconds = 1_000;

    let responder = |name| {
        FixtureUser {
            name,
            publish: grants.publish.clone(),
            subscribe: grants.subscribe.clone(),
            response: None,
        }
        .responding(&response)
    };
    let users = [
        FixtureUser::new("requester", &[REQUEST_SUBJECT], &["_INBOX.requester.*"]),
        responder("responder_one")?,
        responder("responder_two")?,
    ];
    let broker = start_broker(&server_config(&users)).await?;
    let result = exercise_service_responses(&broker.endpoint, limit).await;
    let cleanup = broker.close().await;
    result?;
    cleanup
}

fn token(value: &str) -> Result<SubjectToken> {
    SubjectToken::try_from(value).map_err(|error| anyhow::anyhow!(error.to_string()))
}

/// The grants a panel user of [`PANEL_ORGANIZATION`] receives, as `users::handle_panel_user`
/// derives them.
fn panel_grants() -> Result<GrantSet> {
    let session = ConnectionSession::try_from(PANEL_SESSION)
        .map_err(|error| anyhow::anyhow!(error.to_string()))?;
    let mut grants = GrantSet::default();
    UserScope {
        user: token(PANEL_USER)?,
    }
    .grant(UserRole::AuthenticatedUser, &session, &mut grants);
    grants.subscribe.insert(format!(
        "{}.*",
        panel_reply_inbox_prefix(&token(PANEL_USER)?, &session)
    ));
    OrganizationActorScope {
        user: token(PANEL_USER)?,
        organization: token(PANEL_ORGANIZATION)?,
    }
    .grant(
        OrganizationActorRole::OrganizationMember,
        &session,
        &mut grants,
    );
    Ok(grants)
}

/// The panel's own presence subject, which it both publishes and subscribes to.
fn panel_presence() -> String {
    format!("typewriter.presence.organization.{PANEL_ORGANIZATION}.user.{PANEL_USER}")
}

#[tokio::test]
async fn a_panel_user_cannot_answer_its_own_message_to_reach_another_subject() -> Result<()> {
    let permissions = panel_permissions(panel_grants()?);
    assert!(permissions.response.is_none());
    let presence = panel_presence();
    assert!(permissions.publish.allow.contains(&presence));
    assert!(
        !permissions
            .publish
            .allow
            .iter()
            .any(|subject| subject == SECRET_SUBJECT)
    );

    // The same grants with a response permission show that the self loop is real.
    let escalating = Permissions {
        response: Some(response_permission(1)),
        ..permissions.clone()
    };
    let users = [
        FixtureUser::granted("panel", &permissions)?,
        FixtureUser::granted("escalating", &escalating)?,
        FixtureUser::new("watcher", &[], &[SECRET_SUBJECT]),
    ];
    let broker = start_broker(&server_config(&users)).await?;
    let result = exercise_self_answers(&broker.endpoint, &presence).await;
    let cleanup = broker.close().await;
    result?;
    cleanup
}

/// Publishes on the presence subject with the secret subject as reply, receives the echo and
/// answers it: the panel is refused while a connection with a response permission gets through.
async fn exercise_self_answers(endpoint: &str, presence: &str) -> Result<()> {
    let watcher = connect(endpoint, "watcher", None).await?;
    let mut secrets = watcher.subscribe(SECRET_SUBJECT).await?;
    confirm_subscriptions(&watcher).await?;

    let (panel_events, mut panel_violations) = mpsc::unbounded_channel();
    let panel = connect(endpoint, "panel", Some(panel_events)).await?;
    self_answer(&panel, presence).await?;
    assert_publish_violation(&mut panel_violations).await?;
    assert_no_message(&mut secrets).await?;

    let escalating = connect(endpoint, "escalating", None).await?;
    self_answer(&escalating, presence).await?;
    assert_eq!(receive(&mut secrets).await?.payload, "self answer");
    Ok(())
}

async fn self_answer(client: &Client, presence: &str) -> Result<()> {
    let wildcard = presence
        .rsplit_once('.')
        .map(|(prefix, _)| format!("{prefix}.*"))
        .context("presence subject has a user token")?;
    let mut echoes = client.subscribe(wildcard).await?;
    confirm_subscriptions(client).await?;
    client
        .publish_with_reply(presence.to_owned(), SECRET_SUBJECT, "presence".into())
        .await?;
    client.flush().await?;
    let echo = receive(&mut echoes).await?;
    let reply = echo
        .reply
        .context("the echo carries the named reply subject")?;
    assert_eq!(reply.as_str(), SECRET_SUBJECT);
    client.publish(reply, "self answer".into()).await?;
    client.flush().await?;
    Ok(())
}

#[tokio::test]
async fn a_panel_user_receives_every_frame_of_a_streamed_reply() -> Result<()> {
    let permissions = panel_permissions(panel_grants()?);
    let request =
        format!("service.to.quests.organization.{PANEL_ORGANIZATION}.realm.editor.catalog.fetch");
    let inbox_prefix = permissions
        .subscribe
        .allow
        .iter()
        .find(|subject| subject.starts_with("_INBOX."))
        .context("the panel holds a reply inbox")?
        .trim_end_matches('*')
        .to_owned();
    let limit = SERVICE_RESPONSE_LIMIT.context("services must answer requests")?;
    let users = [
        FixtureUser::granted("panel", &permissions)?,
        FixtureUser::new("service", &[], &[&request]).responding(&response_permission(limit))?,
    ];
    let broker = start_broker(&server_config(&users)).await?;
    let result = exercise_streamed_reply(&broker.endpoint, &request, &inbox_prefix).await;
    let cleanup = broker.close().await;
    result?;
    cleanup
}

/// The service streams more than one window of frames without waiting for any credit, and the
/// panel's inbox receives every one of them in order.
async fn exercise_streamed_reply(endpoint: &str, request: &str, inbox_prefix: &str) -> Result<()> {
    let service = connect(endpoint, "service", None).await?;
    let mut requests = service.subscribe(request.to_owned()).await?;
    confirm_subscriptions(&service).await?;
    let panel = connect(endpoint, "panel", None).await?;
    let inbox = format!("{inbox_prefix}reply");
    let mut replies = panel.subscribe(inbox.clone()).await?;
    confirm_subscriptions(&panel).await?;

    panel
        .publish_with_reply(request.to_owned(), inbox.clone(), "fetch".into())
        .await?;
    panel.flush().await?;
    let received = receive(&mut requests).await?;
    let reply = received
        .reply
        .context("the request carries the panel inbox")?;
    assert_eq!(reply.as_str(), inbox);

    let count = 2 * WINDOW_FRAMES + 1;
    for index in 0..count {
        let mut headers = async_nats::HeaderMap::new();
        headers.insert(PAYLOAD_HEADER, "payload");
        headers.insert(CHUNK_HEADER, format!("{index}/{count}").as_str());
        service
            .publish_with_headers(reply.clone(), headers, format!("frame {index}").into())
            .await?;
    }
    service.flush().await?;
    for index in 0..count {
        assert_eq!(
            receive(&mut replies).await?.payload,
            format!("frame {index}")
        );
    }
    Ok(())
}

async fn exercise_service_responses(endpoint: &str, limit: u32) -> Result<()> {
    let requester = connect(endpoint, "requester", None).await?;
    let (first_events, mut first_violations) = mpsc::unbounded_channel();
    let first = connect(endpoint, "responder_one", Some(first_events)).await?;
    let (second_events, mut second_violations) = mpsc::unbounded_channel();
    let second = connect(endpoint, "responder_two", Some(second_events)).await?;

    let mut first_requests = first.subscribe(REQUEST_SUBJECT).await?;
    let mut second_requests = second.subscribe(REQUEST_SUBJECT).await?;
    confirm_subscriptions(&first).await?;
    confirm_subscriptions(&second).await?;

    let mut replies = requester.subscribe(FIRST_REPLY).await?;
    requester
        .publish_with_reply(REQUEST_SUBJECT, FIRST_REPLY, "request".into())
        .await?;
    requester.flush().await?;

    let first_request = receive(&mut first_requests).await?;
    let second_request = receive(&mut second_requests).await?;
    assert_eq!(first_request.reply.as_deref(), Some(FIRST_REPLY));
    assert_eq!(second_request.reply.as_deref(), Some(FIRST_REPLY));

    // Each responder may send its reply limit to one requester inbox, and not one message more.
    for frame in 0..limit {
        first
            .publish(FIRST_REPLY, format!("first {frame}").into())
            .await?;
    }
    second.publish(FIRST_REPLY, "second".into()).await?;
    first.flush().await?;
    second.flush().await?;
    let mut bodies = Vec::new();
    for _ in 0..=limit {
        bodies.push(String::from_utf8(
            receive(&mut replies).await?.payload.to_vec(),
        )?);
    }
    bodies.sort();
    let mut expected: Vec<String> = (0..limit)
        .map(|frame| format!("first {frame}"))
        .chain(["second".to_owned()])
        .collect();
    expected.sort();
    assert_eq!(bodies, expected);

    first.publish(FIRST_REPLY, "one too many".into()).await?;
    first.flush().await?;
    assert_publish_violation(&mut first_violations).await?;
    assert_no_message(&mut replies).await?;

    let mut arbitrary_replies = requester.subscribe(ARBITRARY_REPLY).await?;
    let mut arbitrary_valid_replies = requester.subscribe(ARBITRARY_VALID_REPLY).await?;
    requester
        .publish_with_reply(REQUEST_SUBJECT, ARBITRARY_VALID_REPLY, "arbitrary".into())
        .await?;
    requester.flush().await?;
    let _ = receive(&mut first_requests).await?;
    let arbitrary_request = receive(&mut second_requests).await?;
    assert_eq!(
        arbitrary_request.reply.as_deref(),
        Some(ARBITRARY_VALID_REPLY)
    );
    second.publish(ARBITRARY_REPLY, "arbitrary".into()).await?;
    second.flush().await?;
    assert_publish_violation(&mut second_violations).await?;
    assert_no_message(&mut arbitrary_replies).await?;
    second
        .publish(ARBITRARY_VALID_REPLY, "valid".into())
        .await?;
    second.flush().await?;
    assert_eq!(
        receive(&mut arbitrary_valid_replies).await?.payload,
        "valid"
    );

    let mut expired_replies = requester.subscribe(EXPIRED_REPLY).await?;
    requester
        .publish_with_reply(REQUEST_SUBJECT, EXPIRED_REPLY, "expires".into())
        .await?;
    requester.flush().await?;
    let expired_request = receive(&mut first_requests).await?;
    let _ = receive(&mut second_requests).await?;
    assert_eq!(expired_request.reply.as_deref(), Some(EXPIRED_REPLY));
    tokio::time::sleep(Duration::from_millis(1_100)).await;
    first.publish(EXPIRED_REPLY, "late".into()).await?;
    first.flush().await?;
    assert_publish_violation(&mut first_violations).await?;
    assert_no_message(&mut expired_replies).await?;

    Ok(())
}

async fn confirm_subscriptions(client: &Client) -> Result<()> {
    let mut readiness = client.subscribe(READINESS_SUBJECT).await?;
    client.publish(READINESS_SUBJECT, "ready".into()).await?;
    // Delivery proves the broker processed the preceding subscriptions on this connection.
    receive(&mut readiness)
        .await
        .context("confirming responder subscriptions")?;
    Ok(())
}

/// Renders the broker users; every user may also use the readiness subject.
fn server_config(users: &[FixtureUser<'_>]) -> String {
    let users: Vec<String> = users
        .iter()
        .map(|user| {
            let mut publish = user.publish.clone();
            let mut subscribe = user.subscribe.clone();
            publish.insert(READINESS_SUBJECT.to_owned());
            subscribe.insert(READINESS_SUBJECT.to_owned());
            let publish = serde_json::to_string(&publish).unwrap();
            let subscribe = serde_json::to_string(&subscribe).unwrap();
            let responses = user
                .response
                .map(|(max, expires)| {
                    format!(", allow_responses: {{ max: {max}, expires: \"{expires}ms\" }}")
                })
                .unwrap_or_default();
            format!(
                r#"    {{ user: "{}", password: "{PASSWORD}", permissions: {{ publish: {{ allow: {publish} }}, subscribe: {{ allow: {subscribe} }}{responses} }} }}"#,
                user.name
            )
        })
        .collect();
    format!(
        "authorization {{\n  users = [\n{}\n  ]\n}}\n",
        users.join("\n")
    )
}

async fn start_broker(config: &str) -> Result<Broker> {
    let directory = tempfile::tempdir()?;
    let config_path = directory.path().join("nats.conf");
    tokio::fs::write(&config_path, config).await?;
    let binary = std::env::var_os("NATS_SERVER_BIN").unwrap_or_else(|| "nats-server".into());
    let mut child = Command::new(binary)
        .args(["--addr", "127.0.0.1", "--port", "-1", "--config"])
        .arg(&config_path)
        .stderr(Stdio::piped())
        .kill_on_drop(true)
        .spawn()
        .context("starting authenticated NATS fixture")?;
    let mut lines = BufReader::new(child.stderr.take().context("NATS stderr unavailable")?).lines();
    let endpoint = tokio::time::timeout(Duration::from_secs(10), async {
        let mut endpoint = None;
        let mut output = Vec::new();
        while let Some(line) = lines.next_line().await? {
            if let Some((_, address)) = line.split_once("Listening for client connections on ") {
                endpoint = Some(format!("nats://{}", address.trim()));
            }
            if line.contains("Server is ready") {
                return endpoint.context("NATS ready without client address");
            }
            output.push(line);
        }
        bail!("NATS exited before readiness: {}", output.join(" | "))
    })
    .await
    .context("NATS startup timed out")
    .and_then(|result| result);
    let endpoint = match endpoint {
        Ok(endpoint) => endpoint,
        Err(error) => {
            let _ = child.kill().await;
            return Err(error);
        }
    };
    let stderr = tokio::spawn(async move { while let Ok(Some(_)) = lines.next_line().await {} });
    Ok(Broker {
        _directory: directory,
        child,
        stderr,
        endpoint,
    })
}

async fn connect(
    endpoint: &str,
    user: &str,
    events: Option<mpsc::UnboundedSender<String>>,
) -> Result<Client> {
    let mut options = ConnectOptions::new().user_and_password(user.into(), PASSWORD.into());
    if let Some(events) = events {
        options = options.event_callback(move |event| {
            let events = events.clone();
            async move {
                if matches!(event, Event::ServerError(_) | Event::ClientError(_)) {
                    let _ = events.send(event.to_string());
                }
            }
        });
    }
    Ok(options.connect(endpoint).await?)
}

async fn receive(subscriber: &mut Subscriber) -> Result<async_nats::Message> {
    tokio::time::timeout(Duration::from_secs(2), subscriber.next())
        .await
        .context("message timed out")?
        .context("subscription closed")
}

async fn assert_publish_violation(events: &mut mpsc::UnboundedReceiver<String>) -> Result<()> {
    tokio::time::timeout(Duration::from_secs(2), async {
        while let Some(event) = events.recv().await {
            if event.contains("Permissions Violation for Publish") {
                return Ok(());
            }
        }
        bail!("connection closed before permission violation")
    })
    .await
    .context("publish permission violation timed out")?
}

async fn assert_no_message(subscriber: &mut Subscriber) -> Result<()> {
    if tokio::time::timeout(Duration::from_millis(200), subscriber.next())
        .await
        .is_ok()
    {
        bail!("denied reply was delivered")
    }
    Ok(())
}
