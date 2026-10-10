use std::{collections::BTreeSet, process::Stdio, time::Duration};

use anyhow::{Context, Result, bail};
use async_nats::{Client, ConnectOptions, Event, Subscriber};
use futures_util::StreamExt;
use tokio::{
    io::{AsyncBufReadExt, BufReader},
    process::{Child, Command},
    sync::mpsc,
};
use wasmcloud_utils::transport_routes::{
    GrantScope, GrantSet, RealmRole, RealmScope, SubjectToken,
};

use crate::services::service_response_permission;

const REQUEST_SUBJECT: &str = "typewriter.organization.writers.realm.quests.hosts.probe";
const PASSWORD: &str = "fixture-secret";
const FIRST_REPLY: &str = "_INBOX.requester.first";
const ARBITRARY_REPLY: &str = "_INBOX.requester.arbitrary";
const ARBITRARY_VALID_REPLY: &str = "_INBOX.requester.arbitrary_valid";
const EXPIRED_REPLY: &str = "_INBOX.requester.expired";

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

#[tokio::test]
async fn response_permissions_admit_one_reply_per_responder() -> Result<()> {
    let mut grants = GrantSet::default();
    RealmScope {
        organization: SubjectToken::try_from("writers")
            .map_err(|error| anyhow::anyhow!(error.to_string()))?,
        realm: SubjectToken::try_from("quests")
            .map_err(|error| anyhow::anyhow!(error.to_string()))?,
    }
    .grant(RealmRole::Participant, &mut grants);
    assert!(grants.subscribe.contains(REQUEST_SUBJECT));

    let mut response = service_response_permission();
    assert_eq!(response.max_messages, Some(1));
    assert_eq!(
        response.ttl.as_ref().map(|duration| duration.milliseconds),
        Some(300_000)
    );
    response
        .ttl
        .as_mut()
        .context("response expiration missing")?
        .milliseconds = 1_000;

    let config = server_config(
        &grants.publish,
        &grants.subscribe,
        response.max_messages.context("response maximum missing")?,
        response
            .ttl
            .as_ref()
            .context("response expiration missing")?
            .milliseconds,
    );
    let broker = start_broker(&config).await?;
    let result = exercise_response_permissions(&broker.endpoint).await;
    let cleanup = broker.close().await;
    result?;
    cleanup
}

async fn exercise_response_permissions(endpoint: &str) -> Result<()> {
    let requester = connect(endpoint, "requester", None).await?;
    let (first_events, mut first_violations) = mpsc::unbounded_channel();
    let first = connect(endpoint, "responder_one", Some(first_events)).await?;
    let (second_events, mut second_violations) = mpsc::unbounded_channel();
    let second = connect(endpoint, "responder_two", Some(second_events)).await?;

    let mut first_requests = first.subscribe(REQUEST_SUBJECT).await?;
    let mut second_requests = second.subscribe(REQUEST_SUBJECT).await?;
    first.flush().await?;
    second.flush().await?;

    let mut replies = requester.subscribe(FIRST_REPLY).await?;
    requester
        .publish_with_reply(REQUEST_SUBJECT, FIRST_REPLY, "request".into())
        .await?;
    requester.flush().await?;

    let first_request = receive(&mut first_requests).await?;
    let second_request = receive(&mut second_requests).await?;
    assert_eq!(first_request.reply.as_deref(), Some(FIRST_REPLY));
    assert_eq!(second_request.reply.as_deref(), Some(FIRST_REPLY));

    first.publish(FIRST_REPLY, "first".into()).await?;
    second.publish(FIRST_REPLY, "second".into()).await?;
    first.flush().await?;
    second.flush().await?;
    let mut bodies = [
        receive(&mut replies).await?.payload.to_vec(),
        receive(&mut replies).await?.payload.to_vec(),
    ];
    bodies.sort();
    assert_eq!(bodies, [b"first".to_vec(), b"second".to_vec()]);

    first.publish(FIRST_REPLY, "duplicate".into()).await?;
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

fn server_config(
    publish: &BTreeSet<String>,
    subscribe: &BTreeSet<String>,
    max_messages: i32,
    expires_milliseconds: i64,
) -> String {
    let publish = serde_json::to_string(&publish.iter().collect::<Vec<_>>()).unwrap();
    let subscribe = serde_json::to_string(&subscribe.iter().collect::<Vec<_>>()).unwrap();
    format!(
        r#"
authorization {{
  users = [
    {{ user: "requester", password: "{PASSWORD}", permissions: {{ publish: {{ allow: ["{REQUEST_SUBJECT}"] }}, subscribe: {{ allow: ["_INBOX.requester.*"] }} }} }}
    {{ user: "responder_one", password: "{PASSWORD}", permissions: {{ publish: {{ allow: {publish} }}, subscribe: {{ allow: {subscribe} }}, allow_responses: {{ max: {max_messages}, expires: "{expires_milliseconds}ms" }} }} }}
    {{ user: "responder_two", password: "{PASSWORD}", permissions: {{ publish: {{ allow: {publish} }}, subscribe: {{ allow: {subscribe} }}, allow_responses: {{ max: {max_messages}, expires: "{expires_milliseconds}ms" }} }} }}
  ]
}}
"#
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
