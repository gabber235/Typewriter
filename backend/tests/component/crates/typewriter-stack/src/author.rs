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

/// The request addresses of the Realm routes the author calls: the authored state and catalog a
/// setup edits over, the commit of that edit, the publish, and the reads of what was published.
const AUTHORED_ROUTES: &[&str] = &[
    "editor.catalog.fetch",
    "editor.authoring.state.query",
    "editor.authoring.edit.commit",
    "editor.authoring.publish",
    "editor.authoring.compiled.query",
    "editor.authoring.compiled.status.query",
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

    /// The owner's organization member publish grants of [`AUTHORED_ROUTES`], and its replies
    /// below its own inbox. Fails when the generated grants hold no request subject for one of
    /// them, which means a route was renamed or no longer admits organization members.
    pub fn permissions(&self) -> Result<Permissions> {
        let mut member = GrantSet::default();
        OrganizationActorScope::from_tokens(&self.owner, &self.organization)
            .map_err(|error| anyhow!("{error}"))?
            .grant(
                OrganizationActorRole::OrganizationMember,
                &self.connection_session()?,
                &mut member,
            );
        let publish = AUTHORED_ROUTES
            .iter()
            .map(|address| {
                let suffix = format!(".realm.{address}");
                let granted: Vec<&String> = member
                    .publish
                    .iter()
                    .filter(|subject| {
                        subject.starts_with("service.to.") && subject.ends_with(&suffix)
                    })
                    .collect();
                match granted.as_slice() {
                    [subject] => Ok((*subject).clone()),
                    [] => bail!("organization members are granted no Realm request `{address}`"),
                    _ => {
                        bail!("organization members are granted several Realm requests `{address}`")
                    }
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
        let published = "service.to.r1.organization.acme.realm.editor.authoring.compiled.query";
        for subject in [commit, publish, published] {
            stack.answer(subject).await;
        }
        let author = stack.author().await;

        for subject in [commit, publish, published] {
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
