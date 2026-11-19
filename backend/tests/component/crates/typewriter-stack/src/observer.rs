//! Mints the game requirements' observer: a user in the TYPEWRITER account that may only read.
//! It requests the owner's organization topology snapshot, the way the panel's topology view does,
//! and reads the stack Realm's `sessions_<realm>` key value bucket, which the Realm creates. The
//! user is signed with the account's key, as `broker` signs its stream manager, so it needs no
//! auth callout.

use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, anyhow};
use nats_broker::{Permission, Permissions};
use nkeys::KeyPair;
use serde::Serialize;

use crate::broker::{StackKeys, creds_file, user_jwt, write_private};
use crate::provision::Provisioned;

#[derive(clap::Args)]
pub struct ObserverArgs {
    /// The stack's state directory.
    #[arg(long)]
    state: PathBuf,
}

/// What `observer` minted, written to `observer.json` in the stack's state directory.
#[derive(Serialize)]
struct Minted {
    /// The `.creds` file the observer connects with.
    creds: String,
    /// The prefix of the observer's reply inboxes; a client creates its inboxes below it.
    inbox: String,
    /// The subject the observer requests the organization topology snapshot on.
    topology: String,
}

/// What an observer of the stack may read.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Observed {
    /// The owner's subject token.
    pub owner: String,
    /// The organization's subject token.
    pub organization: String,
    /// The stack Realm's record key.
    pub realm: String,
    /// The observer's connection session, which its reply inbox names.
    pub session: String,
}

impl Observed {
    /// The reply inbox prefix the backend answers a panel connection of the owner on.
    pub fn inbox(&self) -> String {
        format!("_INBOX.{}.{}", self.owner, self.session)
    }

    /// The owner's topology snapshot request (route `organization_topology_watch`).
    pub fn topology(&self) -> String {
        format!(
            "cloud.to.user.{}.organization.{}.topology.watch",
            self.owner, self.organization
        )
    }

    /// Exactly the reads: the topology snapshot request, and the bucket's stream info and key
    /// reads (`minecraft.<uuid>.<uuid>` keys). Its replies arrive below its own inbox only.
    pub fn permissions(&self) -> Permissions {
        let stream = format!("KV_sessions_{}", self.realm);
        Permissions {
            publish: Permission {
                allow: vec![
                    self.topology(),
                    format!("$JS.API.STREAM.INFO.{stream}"),
                    format!("$JS.API.STREAM.MSG.GET.{stream}"),
                    format!(
                        "$JS.API.DIRECT.GET.{stream}.$KV.sessions_{}.*.*.*",
                        self.realm
                    ),
                ],
                deny: Vec::new(),
            },
            subscribe: Permission {
                allow: vec![format!("{}.>", self.inbox())],
                deny: Vec::new(),
            },
            resp: None,
        }
    }
}

pub async fn run(args: ObserverArgs) -> Result<()> {
    let provisioned = Provisioned::read_from(&args.state)?;
    let bound: serde_json::Value = serde_json::from_str(
        &std::fs::read_to_string(args.state.join("bound.json"))
            .context("cannot read bound.json; did `bind` run?")?,
    )?;
    let observed = Observed {
        owner: provisioned.owner_token,
        organization: provisioned.organization,
        realm: bound["realm"]
            .as_str()
            .context("bound.json names no realm")?
            .to_owned(),
        session: session()?,
    };
    let keys = StackKeys::of_stack(&args.state)?;
    let account = KeyPair::from_seed(&keys.typewriter)?;
    let user = KeyPair::new_user();
    let jwt = user_jwt(&account, &user, "observer", observed.permissions(), false)?;
    let creds = args.state.join("observer.creds");
    write_private(&creds, &creds_file(&jwt, &user.seed()?))?;
    write_minted(
        &args.state,
        &Minted {
            creds: creds.display().to_string(),
            inbox: observed.inbox(),
            topology: observed.topology(),
        },
    )
}

fn write_minted(state: &Path, minted: &Minted) -> Result<()> {
    let text = serde_json::to_string_pretty(minted)?;
    std::fs::write(state.join("observer.json"), &text).context("cannot write observer.json")?;
    println!("{text}");
    Ok(())
}

/// A connection session as the backend accepts one: 32 lowercase hex digits.
fn session() -> Result<String> {
    let mut bytes = [0; 16];
    getrandom::getrandom(&mut bytes).map_err(|error| anyhow!("{error}"))?;
    Ok(bytes.iter().map(|byte| format!("{byte:02x}")).collect())
}

#[cfg(test)]
mod tests {
    use std::time::Duration;

    use crate::test_support::ObservedBroker;
    use async_nats::jetstream;

    #[tokio::test]
    async fn the_observer_reads_session_keys_of_its_realm_and_writes_nothing() {
        let stack = ObservedBroker::start().await;
        let owned = jetstream::new(stack.admin.clone())
            .create_key_value(jetstream::kv::Config {
                bucket: "sessions_r1".into(),
                ..Default::default()
            })
            .await
            .unwrap();
        let key =
            "minecraft.11111111-1111-1111-1111-111111111111.22222222-2222-2222-2222-222222222222";
        owned.put(key, "entry".into()).await.unwrap();
        let observed = &stack.observed;
        let observer = stack.observer().await;

        let sessions = jetstream::new(observer.clone())
            .get_key_value("sessions_r1")
            .await
            .unwrap();
        let read = sessions.get(key).await.unwrap();
        let written =
            tokio::time::timeout(Duration::from_secs(5), sessions.put(key, "forged".into())).await;

        assert_eq!(read.as_deref(), Some(&b"entry"[..]));
        assert!(
            !matches!(written, Ok(Ok(_))),
            "the observer wrote a session key"
        );
        assert_eq!(
            owned.get(key).await.unwrap().as_deref(),
            Some(&b"entry"[..])
        );
    }

    #[tokio::test]
    async fn the_observer_requests_the_owners_topology_snapshot_and_no_other_route() {
        let stack = ObservedBroker::start().await;
        let observed = &stack.observed;
        let configure = format!(
            "cloud.to.user.{}.organization.{}.topology.configure",
            observed.owner, observed.organization
        );
        for subject in [observed.topology(), configure.clone()] {
            let mut requests = stack.admin.subscribe(subject.clone()).await.unwrap();
            stack
                .account
                .subscription_registered(&stack.admin, &subject)
                .await
                .unwrap();
            let replier = stack.admin.clone();
            tokio::spawn(async move {
                use futures_util::StreamExt as _;
                while let Some(request) = requests.next().await {
                    if let Some(reply) = request.reply {
                        replier.publish(reply, "answer".into()).await.unwrap();
                    }
                }
            });
        }
        let observer = stack.observer().await;

        let snapshot = observer.request(observed.topology(), "".into()).await;
        let configured = tokio::time::timeout(
            Duration::from_secs(5),
            observer.request(configure, "".into()),
        )
        .await;

        assert_eq!(&snapshot.unwrap().payload[..], b"answer");
        assert!(
            !matches!(configured, Ok(Ok(_))),
            "the observer configured a host"
        );
    }
}
