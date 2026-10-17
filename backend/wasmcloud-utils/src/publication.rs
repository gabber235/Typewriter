//! Publication plans returned by committed domain results.
//!
//! Captured facts preserve transaction history and sequence values. Refresh effects read current
//! component state after commit. The executor preserves declared order and stops at first failure.
//! Database commit and broker publication are separate operations. A publication error can leave
//! earlier effects delivered and later effects unattempted, while the database change remains.

use crate::{
    database::RecordId,
    skir::base::{
        organization::v1::{
            join_codes::OrganizationJoinCodesChanged,
            join_request::{OrganizationJoinRequestsChanged, UserJoinRequestsChanged},
            member::OrganizationMembersChanged,
            organization::UserOrganizationsChanged,
        },
        service::v1::{
            organization::OrganizationServicesChanged,
            topology::{OrganizationTopologyChanged, WatchHostExecutionResponse},
        },
    },
    transport_routes::{
        HostExecutionWatchRoute, OrganizationJoinCodesWatchRoute,
        OrganizationJoinRequestsWatchRoute, OrganizationMembersWatchRoute, OrganizationScope,
        OrganizationServicesWatchRoute, OrganizationTopologyWatchRoute, ServiceScope,
        UserJoinRequestsWatchRoute, UserOrganizationsWatchRoute, UserScope,
    },
};

/// Couples a committed domain result to the publications required before returning its response.
///
/// Construction does not execute or verify a database transaction. Handlers create this value
/// only after decoding a committed result, with facts captured by that transaction.
pub struct CommittedChange<Response> {
    response: Response,
    effects: Vec<PublicationEffect>,
}

/// A sequenced membership projection change captured at commit and persisted through JetStream.
pub enum MembershipFact {
    UserOrganizations {
        user: String,
        event: UserOrganizationsChanged,
    },
    UserJoinRequests {
        user: String,
        event: UserJoinRequestsChanged,
    },
    Members {
        organization: String,
        event: OrganizationMembersChanged,
    },
    JoinRequests {
        organization: String,
        event: OrganizationJoinRequestsChanged,
    },
    JoinCodes {
        organization: String,
        event: OrganizationJoinCodesChanged,
    },
}

/// A captured service observation sent through core messaging without stream persistence.
pub enum TransientFact {
    Services {
        organization: String,
        event: OrganizationServicesChanged,
    },
    Topology {
        organization: String,
        event: OrganizationTopologyChanged,
    },
    DesiredExecution {
        service: String,
        event: WatchHostExecutionResponse,
    },
}

/// Requests a fresh read after commit, which may include changes from intervening transactions.
pub enum ProjectionRefresh {
    Services { organization: String },
    Topology { organization: String },
    ServiceBinding { service: RecordId },
}

pub enum PublicationEffect {
    CapturedMembership(MembershipFact),
    CapturedTransient(TransientFact),
    Refresh(ProjectionRefresh),
}

/// Component supplied reader and publisher for projections whose current state must be fetched.
pub trait ProjectionRefresher {
    fn refresh(
        &self,
        refresh: ProjectionRefresh,
    ) -> impl std::future::Future<Output = Result<(), crate::otel_wasi::Error>>;
}

/// Runs publication effects in declaration order, without rollback or automatic replay.
pub struct PublicationExecutor<Refresher> {
    pub refresher: Refresher,
}

impl<Response> CommittedChange<Response> {
    pub fn new(response: Response, effects: impl IntoIterator<Item = PublicationEffect>) -> Self {
        Self {
            response,
            effects: effects.into_iter().collect(),
        }
    }

    /// Returns the response only after every effect succeeds.
    ///
    /// Failure consumes this plan and returns the publication error. It does not undo the
    /// committed domain mutation or any effect already delivered.
    pub async fn publish_with<Refresher: ProjectionRefresher>(
        self,
        publisher: &PublicationExecutor<Refresher>,
    ) -> Result<Response, crate::otel_wasi::Error> {
        publisher.execute(self.effects).await?;
        Ok(self.response)
    }
}

impl<Refresher: ProjectionRefresher> PublicationExecutor<Refresher> {
    pub async fn execute(
        &self,
        effects: Vec<PublicationEffect>,
    ) -> Result<(), crate::otel_wasi::Error> {
        for effect in effects {
            match effect {
                PublicationEffect::CapturedMembership(fact) => fact.persist().await?,
                PublicationEffect::CapturedTransient(fact) => fact.publish().await?,
                PublicationEffect::Refresh(refresh) => self.refresher.refresh(refresh).await?,
            }
        }
        Ok(())
    }
}

impl MembershipFact {
    async fn persist(self) -> Result<(), crate::otel_wasi::Error> {
        match self {
            Self::UserOrganizations { user, event } => {
                UserOrganizationsWatchRoute::delivery(&UserScope::try_from(user.as_str())?)
                    .persist(event)
                    .await
            }
            Self::UserJoinRequests { user, event } => {
                UserJoinRequestsWatchRoute::delivery(&UserScope::try_from(user.as_str())?)
                    .persist(event)
                    .await
            }
            Self::Members {
                organization,
                event,
            } => {
                OrganizationMembersWatchRoute::delivery(&OrganizationScope::try_from(
                    organization.as_str(),
                )?)
                .persist(event)
                .await
            }
            Self::JoinRequests {
                organization,
                event,
            } => {
                OrganizationJoinRequestsWatchRoute::delivery(&OrganizationScope::try_from(
                    organization.as_str(),
                )?)
                .persist(event)
                .await
            }
            Self::JoinCodes {
                organization,
                event,
            } => {
                OrganizationJoinCodesWatchRoute::delivery(&OrganizationScope::try_from(
                    organization.as_str(),
                )?)
                .persist(event)
                .await
            }
        }
    }
}

impl TransientFact {
    async fn publish(self) -> Result<(), crate::otel_wasi::Error> {
        match self {
            Self::Services {
                organization,
                event,
            } => {
                OrganizationServicesWatchRoute::delivery(&OrganizationScope::try_from(
                    organization.as_str(),
                )?)
                .publish(event)
                .await
            }
            Self::Topology {
                organization,
                event,
            } => {
                OrganizationTopologyWatchRoute::delivery(&OrganizationScope::try_from(
                    organization.as_str(),
                )?)
                .publish(event)
                .await
            }
            Self::DesiredExecution { service, event } => {
                HostExecutionWatchRoute::delivery(&ServiceScope::try_from(service.as_str())?)
                    .publish(event)
                    .await
            }
        }
    }
}

/// Rejects refresh effects for components whose publication plans contain captured facts only.
pub struct CapturedOnly;

impl ProjectionRefresher for CapturedOnly {
    async fn refresh(&self, _: ProjectionRefresh) -> Result<(), crate::otel_wasi::Error> {
        Err(crate::otel_wasi::Error::new(
            "publication-unexpected-refresh",
            "captured effect component requested a refresh",
        ))
    }
}
