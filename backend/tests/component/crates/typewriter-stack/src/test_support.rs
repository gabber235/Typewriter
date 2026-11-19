//! What the crate's tests share: a broker with an observer of the stack Realm `r1`.

use nats_broker::{Account, Broker};

use crate::observer::Observed;

/// A fresh broker, its account's admin connection, and the observer of owner `user_ada`'s
/// organization `acme` and Realm `r1`.
pub struct ObservedBroker {
    _broker: Broker,
    pub account: Account,
    pub admin: async_nats::Client,
    pub observed: Observed,
}

impl ObservedBroker {
    pub async fn start() -> Self {
        let broker = Broker::start().await.unwrap();
        let account = broker.account().await.unwrap();
        let admin = account
            .admin()
            .unwrap()
            .connect(account.endpoint())
            .await
            .unwrap();
        Self {
            _broker: broker,
            account,
            admin,
            observed: Observed {
                owner: "user_ada".into(),
                organization: "acme".into(),
                realm: "r1".into(),
                session: "0123456789abcdef0123456789abcdef".into(),
            },
        }
    }

    /// A connection with the observer's permissions, receiving replies below its inbox.
    pub async fn observer(&self) -> async_nats::Client {
        self.account
            .user(&self.observed.permissions())
            .unwrap()
            .connect_with_inbox(self.account.endpoint(), &self.observed.inbox())
            .await
            .unwrap()
    }
}
