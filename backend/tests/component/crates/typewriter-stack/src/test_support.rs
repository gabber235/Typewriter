//! What the crate's tests share: a broker with an observer of the stack Realm `r1` and an author
//! acting as its owner.

use futures_util::StreamExt as _;
use nats_broker::{Account, Broker};

use crate::author::Author;
use crate::observer::Observed;

/// A fresh broker, its account's admin connection, the observer of owner `user_ada`'s
/// organization `acme` and Realm `r1`, and the author acting as that owner.
pub struct ObservedBroker {
    _broker: Broker,
    pub account: Account,
    pub admin: async_nats::Client,
    pub observed: Observed,
    pub author: Author,
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
            author: Author {
                owner: "user_ada".into(),
                organization: "acme".into(),
                session: "fedcba9876543210fedcba9876543210".into(),
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

    /// A connection with the author's permissions, receiving replies below its inbox.
    pub async fn author(&self) -> async_nats::Client {
        self.account
            .user(&self.author.permissions().unwrap())
            .unwrap()
            .connect_with_inbox(self.account.endpoint(), &self.author.inbox().unwrap())
            .await
            .unwrap()
    }

    /// Answers every request on `subject` with `answer` from the admin connection, once the
    /// broker routes the subject.
    pub async fn answer(&self, subject: &str) {
        let mut requests = self.admin.subscribe(subject.to_owned()).await.unwrap();
        self.account
            .subscription_registered(&self.admin, subject)
            .await
            .unwrap();
        let replier = self.admin.clone();
        tokio::spawn(async move {
            while let Some(request) = requests.next().await {
                if let Some(reply) = request.reply {
                    replier.publish(reply, "answer".into()).await.unwrap();
                }
            }
        });
    }
}
