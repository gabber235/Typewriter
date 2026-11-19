//! The stack's engine binder (`typewriter-stack bind --as-engine`) against service registration:
//! each game Paper slot's loader writes its pending token into the slot's folder, and the binder
//! binds that service, names it `game_paper_<slot>` and attaches its host to the Realm as the Paper
//! engine. The cases play the loaders: they write the token, and register the host once bound.

use std::time::Duration;

use typewriter_component_test::{
    binder::{BoundSlot, MemberRoutes, ScratchSlots, expect_slot, paper_engine},
    prelude::*,
    service::{register_once_bound, seed_realm_host, seed_registration_lease},
};
use wasmcloud_utils::skir::base::service::v1::registration::{
    BindServiceRequest, BindServiceResponse,
};

use super::ServiceRegistration;

/// The engine every slot's loader advertises.
const PAPER: &str = "typewritermc:paper";
/// How long a slot's registration lease has left.
const LEASE: Duration = Duration::from_secs(300);
/// How long a case lets its binder and loaders run.
const PATIENCE: Duration = Duration::from_secs(30);

#[component_test(ServiceRegistration)]
async fn every_game_paper_slot_binds_as_an_engine_of_the_realm(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let realm = seed_realm_host(context, &acme(), ada(), "realm", paper_engine()).await?;
    let slots = ScratchSlots::new(3, Duration::from_secs(10))?;
    for (slot, token) in [(0, "SLOTAAAAAA"), (1, "SLOTBBBBBB"), (2, "SLOTCCCCCC")] {
        seed_registration_lease(context, &format!("paper_{slot}"), token, LEASE).await?;
        slots.write_token(slot, token)?;
        expect_slot(context, &acme(), &format!("paper_{slot}"), true)?;
    }
    let loaders = async {
        for slot in 0..3 {
            register_once_bound(context, &format!("paper_{slot}"), &[PAPER], PATIENCE).await?;
        }
        Ok::<_, anyhow::Error>(())
    };

    let (bound, loaders) = tokio::join!(
        tokio::time::timeout(
            PATIENCE,
            slots.0.bind_all(|| async {
                Ok(MemberRoutes {
                    context: &*context,
                    user: ada(),
                    organization: acme(),
                })
            })
        ),
        loaders,
    );

    loaders?;
    let bound = bound??;
    assert_eq!(
        bound.iter().map(|slot| slot.slot).collect::<Vec<_>>(),
        [0, 1, 2]
    );
    for BoundSlot { slot, host, change } in &bound {
        assert_eq!(
            host.service_id,
            skir_record_id("service", format!("paper_{slot}"))
        );
        let engine = change
            .engine
            .as_ref()
            .expect("the slot was attached as an engine");
        assert_eq!(engine.realm.realm_id, realm, "slot {slot}'s engine");
        assert_eq!(engine.target.engine_id, PAPER);
    }
    assert_eq!(
        context
            .database()?
            .query_json("SELECT VALUE name FROM service WHERE id IN [service:`paper_0`, service:`paper_1`, service:`paper_2`] ORDER BY name")
            .await?,
        serde_json::json!(["game_paper_0", "game_paper_1", "game_paper_2"])
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn a_slot_whose_token_is_bound_already_waits_for_its_next_token(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_realm_host(context, &acme(), ada(), "realm", paper_engine()).await?;
    seed_registration_lease(context, "earlier", "EARLIERAAA", LEASE).await?;
    let reply: BindServiceResponse = context
        .arrange(
            from_member(ada(), &acme(), "services.bind"),
            &BindServiceRequest {
                registration_token: "EARLIERAAA".into(),
                ..Default::default()
            },
        )
        .await?;
    assert!(
        matches!(reply, BindServiceResponse::Success(_)),
        "{reply:?}"
    );
    let slots = ScratchSlots::new(1, Duration::from_secs(10))?;
    slots.write_token(0, "EARLIERAAA")?;
    expect_slot(context, &acme(), "paper_0", true)?;
    let loader = async {
        // Long enough for the binder to try the bound token first.
        tokio::time::sleep(Duration::from_secs(2)).await;
        seed_registration_lease(context, "paper_0", "NEXTAAAAAA", LEASE).await?;
        slots.write_token(0, "NEXTAAAAAA")?;
        register_once_bound(context, "paper_0", &[PAPER], PATIENCE).await
    };

    let (bound, loader) = tokio::join!(
        tokio::time::timeout(
            PATIENCE,
            slots.0.bind_all(|| async {
                Ok(MemberRoutes {
                    context: &*context,
                    user: ada(),
                    organization: acme(),
                })
            })
        ),
        loader,
    );

    loader?;
    let bound = bound??;
    assert_eq!(
        bound[0].host.service_id,
        skir_record_id("service", "paper_0")
    );
    assert_eq!(
        context
            .database()?
            .query_json("SELECT VALUE name FROM service WHERE id IN [service:earlier, service:`paper_0`] ORDER BY name")
            .await?,
        serde_json::json!(["earlier", "game_paper_0"])
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn a_bound_slot_whose_host_never_advertises_fails_naming_the_wait(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_realm_host(context, &acme(), ada(), "realm", paper_engine()).await?;
    seed_registration_lease(context, "paper_0", "SLOTAAAAAA", LEASE).await?;
    let slots = ScratchSlots::new(1, Duration::from_secs(1))?;
    slots.write_token(0, "SLOTAAAAAA")?;
    expect_slot(context, &acme(), "paper_0", false)?;

    let failed = tokio::time::timeout(
        PATIENCE,
        slots.0.bind_all(|| async {
            Ok(MemberRoutes {
                context: &*context,
                user: ada(),
                organization: acme(),
            })
        }),
    )
    .await?
    .expect_err("a host that never advertised was attached");

    let message = format!("{failed:#}");
    assert!(message.contains("slot 0"), "{message}");
    assert!(
        message.contains("service paper_0 to advertise its host"),
        "{message}"
    );
    Ok(())
}
