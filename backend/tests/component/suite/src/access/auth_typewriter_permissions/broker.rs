//! The component's own grants, enforced by a real broker. Each case turns a permission reply into
//! a broker user with the auth callout's conversion, so neither the grants nor their conversion is
//! rebuilt here.

use std::time::Duration;

use super::AuthTypewriterPermissions;
use anyhow::Context as _;
use typewriter_component_test::{
    access::{Realm, member_grants, panel_inbox, service_grants},
    broker::{Connection, SILENCE, WAIT, next_within, on_broker, receive},
    prelude::*,
};
use wasmcloud_utils::{
    skir::base::access::v1::permission::Permissions, transport_routes::SERVICE_RESPONSE_LIMIT,
};

/// A route of Acme's realm `quests` that a panel member calls and the realm host serves.
const OWN_REALM: &str = "service.to.quests.organization.acme.realm.editor.catalog.fetch";
/// The same route in another organization.
const FOREIGN_REALM: &str = "service.to.quests.organization.globex.realm.editor.catalog.fetch";

#[component_test(AuthTypewriterPermissions)]
async fn panel_grants_are_enforced_by_the_broker(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;
    let granted = member_grants(context, ada(), &acme()).await?;

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
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;
    let granted = member_grants(context, ada(), &acme()).await?;
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
        panel.answer_own_echo(&presence, secret).await?;
        assert!(panel.publish_was_refused().await);
        assert!(next_within(&mut secrets, SILENCE).await.is_none());

        let escalating = Connection::granted(account, escalating).await?;
        escalating.answer_own_echo(&presence, secret).await?;
        assert_eq!(receive(&mut secrets).await?.payload, "self answer");
        Ok(())
    })
    .await
}

#[component_test(AuthTypewriterPermissions)]
async fn a_service_reply_reaches_the_panel_up_to_its_limit(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;
    let panel_grants = member_grants(context, ada(), &acme()).await?;
    let host_grants = service_grants(context, "realm_host", Realm::Owned("quests")).await?;
    let limit = SERVICE_RESPONSE_LIMIT.context("services answer requests")?;

    on_broker(async |account| {
        let panel = Connection::granted(account, panel_grants).await?;
        let mut host = Connection::granted(account, host_grants.clone()).await?;
        let replica = Connection::granted(account, host_grants).await?;
        let mut requests = host.subscribe(OWN_REALM).await?;
        let mut replica_requests = replica.subscribe(OWN_REALM).await?;
        let reply_to = panel_inbox(ada(), "fetch");
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
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;
    let panel_grants = member_grants(context, ada(), &acme()).await?;
    let host_grants = service_grants(context, "realm_host", Realm::Owned("quests")).await?;

    on_broker(async |account| {
        let panel = Connection::granted(account, panel_grants).await?;
        let mut host = Connection::granted(account, host_grants).await?;
        let mut requests = host.subscribe(OWN_REALM).await?;
        let asked = panel_inbox(ada(), "asked");
        let unasked = panel_inbox(ada(), "unasked");
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
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;
    let panel_grants = member_grants(context, ada(), &acme()).await?;
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
        let reply_to = panel_inbox(ada(), "late");
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
