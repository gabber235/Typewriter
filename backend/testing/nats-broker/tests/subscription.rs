//! What a caller may rely on once the server has registered a subscription.

use std::time::Duration;

use futures_util::StreamExt;
use nats_broker::Broker;

/// The race needs the server to read two sockets out of order, so one round rarely shows it.
const ROUNDS: usize = 300;

#[tokio::test(flavor = "multi_thread")]
async fn a_registered_subscription_receives_what_another_connection_publishes_next()
-> anyhow::Result<()> {
    let broker = Broker::start().await?;
    let account = broker.account().await?;
    let credentials = account.admin()?;
    let subscriber = credentials.connect(account.endpoint()).await?;
    let publisher = credentials.connect(account.endpoint()).await?;

    for round in 0..ROUNDS {
        let subject = format!("round.{round}");
        let mut messages = subscriber.subscribe(subject.clone()).await?;
        account
            .subscription_registered(&subscriber, &subject)
            .await?;

        publisher.publish(subject.clone(), "hello".into()).await?;
        publisher.flush().await?;

        let received = tokio::time::timeout(Duration::from_secs(1), messages.next()).await;
        assert!(
            matches!(received, Ok(Some(_))),
            "round {round} lost its message"
        );
    }
    Ok(())
}
