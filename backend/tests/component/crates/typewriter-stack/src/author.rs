//! Mints the game requirements' author: a user in the TYPEWRITER account that writes content into
//! the stack Realm and publishes it, as the stack owner does from the panel. Its grants are the
//! owner's organization member grants of the Realm routes an author's setup needs, taken from the
//! generated transport grants, so they follow the route declarations. The user is signed with the
//! account's key, as `observer` is, so it needs no auth callout.

use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, anyhow, bail};
use nats_broker::{Permission, Permissions};
use nkeys::KeyPair;
use serde::Serialize;
use wasmcloud_utils::transport::{ConnectionSession, GrantSet, OrganizationActorScope};
use wasmcloud_utils::transport_routes::{OrganizationActorRole, panel_reply_inbox_prefix};

use crate::broker::{StackKeys, creds_file, user_jwt, write_private};
use crate::observer::session;
use crate::provision::Provisioned;

/// The subjects the author publishes, as the endings of the owner's organization member grants:
/// the authored state a setup edits over, the commit of that edit, the publication review whose
/// candidate it publishes, the publish, and the read of what the selected publication holds; then,
/// as a panel tab of the owner, its presence heartbeat, which makes the tab a session at the
/// Realm's panel engine, and the events that tab emits. `{organization}` and `{user}` are the
/// owner's.
const AUTHORED_SUBJECTS: &[&str] = &[
    ".realm.editor.authoring.state.query",
    ".realm.editor.authoring.edit.commit",
    ".realm.editor.authoring.publication.query",
    ".realm.editor.authoring.publish",
    ".realm.editor.authoring.compiled.query",
    ".presence.organization.{organization}.user.{user}",
    ".realm.event.emit.user.{user}",
];

#[derive(clap::Args)]
pub struct AuthorArgs {
    /// The stack's state directory.
    #[arg(long)]
    state: PathBuf,
}

/// What `author` minted, written to `author.json` in the stack's state directory.
#[derive(Serialize)]
struct Minted {
    /// The `.creds` file the author connects with.
    creds: String,
    /// The prefix of the author's reply inboxes; a client creates its inboxes below it.
    inbox: String,
    /// The owner's subject token, the user its panel tab's presence and emits name.
    user: String,
}

/// The owner and the connection session an author of the stack acts as.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Author {
    /// The owner's subject token.
    pub owner: String,
    /// The organization's subject token.
    pub organization: String,
    /// The author's connection session, which its reply inbox names.
    pub session: String,
}

impl Author {
    /// The reply inbox prefix the Realm answers a panel connection of the owner on.
    pub fn inbox(&self) -> Result<String> {
        Ok(panel_reply_inbox_prefix(
            &self
                .owner
                .as_str()
                .try_into()
                .map_err(|error| anyhow!("{error}"))?,
            &self.connection_session()?,
        ))
    }

    /// The owner's organization member publish grants that end in one of [`AUTHORED_SUBJECTS`],
    /// and its replies below its own inbox. Fails when the generated grants hold no subject or
    /// several for one of them, which means a route was renamed or no longer admits organization
    /// members.
    pub fn permissions(&self) -> Result<Permissions> {
        let mut member = GrantSet::default();
        OrganizationActorScope::from_tokens(&self.owner, &self.organization)
            .map_err(|error| anyhow!("{error}"))?
            .grant(
                OrganizationActorRole::OrganizationMember,
                &self.connection_session()?,
                &mut member,
            );
        let publish = AUTHORED_SUBJECTS
            .iter()
            .map(|ending| {
                let suffix = ending
                    .replace("{organization}", &self.organization)
                    .replace("{user}", &self.owner);
                let granted: Vec<&String> = member
                    .publish
                    .iter()
                    .filter(|subject| subject.ends_with(&suffix))
                    .collect();
                match granted.as_slice() {
                    [subject] => Ok((*subject).clone()),
                    [] => bail!("organization members are granted no subject ending in `{suffix}`"),
                    _ => bail!(
                        "organization members are granted several subjects ending in `{suffix}`"
                    ),
                }
            })
            .collect::<Result<Vec<_>>>()?;
        Ok(Permissions {
            publish: Permission {
                allow: publish,
                deny: Vec::new(),
            },
            subscribe: Permission {
                allow: vec![format!("{}.>", self.inbox()?)],
                deny: Vec::new(),
            },
            resp: None,
        })
    }

    fn connection_session(&self) -> Result<ConnectionSession> {
        ConnectionSession::try_from(self.session.as_str()).map_err(|error| anyhow!("{error}"))
    }
}

pub async fn run(args: AuthorArgs) -> Result<()> {
    let provisioned = Provisioned::read_from(&args.state)?;
    let author = Author {
        owner: provisioned.owner_token,
        organization: provisioned.organization,
        session: session()?,
    };
    let keys = StackKeys::of_stack(&args.state)?;
    let account = KeyPair::from_seed(&keys.typewriter)?;
    let user = KeyPair::new_user();
    let jwt = user_jwt(&account, &user, "author", author.permissions()?, false)?;
    let creds = args.state.join("author.creds");
    write_private(&creds, &creds_file(&jwt, &user.seed()?))?;
    write_minted(
        &args.state,
        &Minted {
            creds: creds.display().to_string(),
            inbox: author.inbox()?,
            user: author.owner.clone(),
        },
    )
}

fn write_minted(state: &Path, minted: &Minted) -> Result<()> {
    let text = serde_json::to_string_pretty(minted)?;
    std::fs::write(state.join("author.json"), &text).context("cannot write author.json")?;
    println!("{text}");
    Ok(())
}

#[cfg(test)]
mod tests {
    use std::time::Duration;

    use crate::test_support::ObservedBroker;

    #[tokio::test]
    async fn the_author_commits_and_publishes_in_its_organizations_realm() {
        let stack = ObservedBroker::start().await;
        let commit = "service.to.r1.organization.acme.realm.editor.authoring.edit.commit";
        let publish = "service.to.r1.organization.acme.realm.editor.authoring.publish";
        let review = "service.to.r1.organization.acme.realm.editor.authoring.publication.query";
        let published = "service.to.r1.organization.acme.realm.editor.authoring.compiled.query";
        for subject in [commit, review, publish, published] {
            stack.answer(subject).await;
        }
        let author = stack.author().await;

        for subject in [commit, review, publish, published] {
            let reply = author.request(subject, "".into()).await;
            assert_eq!(&reply.unwrap().payload[..], b"answer", "{subject}");
        }
    }

    #[tokio::test]
    async fn the_author_acts_as_a_panel_tab_of_its_owner() {
        let stack = ObservedBroker::start().await;
        let presence = "typewriter.presence.organization.acme.user.user_ada";
        let emit = "service.to.r1.organization.acme.realm.event.emit.user.user_ada";
        for subject in [presence, emit] {
            stack.answer(subject).await;
        }
        let author = stack.author().await;

        for subject in [presence, emit] {
            let reply = author.request(subject, "".into()).await;
            assert_eq!(&reply.unwrap().payload[..], b"answer", "{subject}");
        }
    }

    #[tokio::test]
    async fn the_author_calls_no_other_route_and_no_other_organizations_realm() {
        let stack = ObservedBroker::start().await;
        let forbidden = [
            "service.to.r1.organization.acme.realm.editor.authoring.type.commit",
            "service.to.r1.organization.globex.realm.editor.authoring.edit.commit",
            "cloud.to.user.user_ada.organization.acme.topology.configure",
            "typewriter.presence.organization.acme.user.user_bob",
            "service.to.r1.organization.acme.realm.event.emit.user.user_bob",
            "service.to.r1.organization.acme.realm.engine.panel-r1.event",
        ];
        for subject in forbidden {
            stack.answer(subject).await;
        }
        let author = stack.author().await;

        for subject in forbidden {
            let reply =
                tokio::time::timeout(Duration::from_secs(5), author.request(subject, "".into()))
                    .await;
            assert!(
                !matches!(reply, Ok(Ok(_))),
                "the author requested {subject}"
            );
        }
    }
}
