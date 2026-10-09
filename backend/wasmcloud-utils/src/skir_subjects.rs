//! Canonical typed subjects for backend requests, watch streams, and change events.
//!
//! The templates here are part of the broker contract. Watch subjects are requestable
//! snapshots, while `changed` subjects are persisted membership deltas. Callers should
//! use these constructors instead of assembling subject strings locally.

use crate::{
    define_skir_subjects,
    skirout::base::{
        organization::v1::{
            join_codes::{OrganizationJoinCodesChanged, WatchOrganizationJoinCodesResponse},
            join_request::{
                OrganizationJoinRequestsChanged, UserJoinRequestsChanged,
                WatchOrganizationJoinRequestsResponse,
            },
            member::{OrganizationMembersChanged, WatchOrganizationMembersResponse},
            organization::UserOrganizationsChanged,
            user::{WatchUserJoinRequestsResponse, WatchUserOrganizationsResponse},
        },
        service::v1::{
            organization::OrganizationServicesChanged,
            registration::ServiceBoundNotification,
            topology::{OrganizationTopologyChanged, WatchHostExecutionResponse},
        },
    },
};

define_skir_subjects! {
    user_organizations(user_id) -> WatchUserOrganizationsResponse =
        "typewriter.to.user.{user_id}.organization.watch";

    user_join_requests(user_id) -> WatchUserJoinRequestsResponse =
        "typewriter.to.user.{user_id}.organization.join_requests.watch";

    organization_members(organization_id) -> WatchOrganizationMembersResponse =
        "typewriter.to.organization.{organization_id}.members.watch";

    organization_join_requests(organization_id) -> WatchOrganizationJoinRequestsResponse =
        "typewriter.to.organization.{organization_id}.members.join_requests.watch";

    organization_join_codes(organization_id) -> WatchOrganizationJoinCodesResponse =
        "typewriter.to.organization.{organization_id}.members.join_codes.watch";

    user_organizations_changed(user_id) -> UserOrganizationsChanged =
        "typewriter.to.user.{user_id}.organizations.changed";

    user_join_requests_changed(user_id) -> UserJoinRequestsChanged =
        "typewriter.to.user.{user_id}.join_requests.changed";

    organization_members_changed(organization_id) -> OrganizationMembersChanged =
        "typewriter.to.organization.{organization_id}.members.changed";

    organization_join_requests_changed(organization_id) -> OrganizationJoinRequestsChanged =
        "typewriter.to.organization.{organization_id}.join_requests.changed";

    organization_join_codes_changed(organization_id) -> OrganizationJoinCodesChanged =
        "typewriter.to.organization.{organization_id}.join_codes.changed";

    organization_services_changed(organization_id) -> OrganizationServicesChanged =
        "typewriter.to.organization.{organization_id}.services.watch";

    organization_topology_changed(organization_id) -> OrganizationTopologyChanged =
        "typewriter.to.organization.{organization_id}.topology.watch";

    host_execution(service_id) -> WatchHostExecutionResponse =
        "typewriter.to.service.{service_id}.execution.watch";

    service_bound(service_id) -> ServiceBoundNotification =
        "typewriter.to.service.{service_id}.registration.bound";
}

#[cfg(test)]
mod tests {
    #[test]
    fn user_organizations_subject_formats_user_id() {
        let subject = super::user_organizations("user_123");

        assert_eq!(
            subject.subject(),
            "typewriter.to.user.user_123.organization.watch"
        );
    }

    #[test]
    fn user_join_requests_subject_formats_user_id() {
        let subject = super::user_join_requests("user_123");

        assert_eq!(
            subject.subject(),
            "typewriter.to.user.user_123.organization.join_requests.watch"
        );
    }

    #[test]
    fn organization_members_subject_formats_organization_id() {
        let subject = super::organization_members("org_123");

        assert_eq!(
            subject.subject(),
            "typewriter.to.organization.org_123.members.watch"
        );
    }

    #[test]
    fn organization_join_requests_subject_formats_organization_id() {
        let subject = super::organization_join_requests("org_123");

        assert_eq!(
            subject.subject(),
            "typewriter.to.organization.org_123.members.join_requests.watch"
        );
    }

    #[test]
    fn organization_join_codes_subject_formats_organization_id() {
        let subject = super::organization_join_codes("org_123");

        assert_eq!(
            subject.subject(),
            "typewriter.to.organization.org_123.members.join_codes.watch"
        );
    }

    #[test]
    fn membership_change_subjects_match_jetstream_filters() {
        assert_eq!(
            super::user_organizations_changed("user_123").subject(),
            "typewriter.to.user.user_123.organizations.changed"
        );
        assert_eq!(
            super::user_join_requests_changed("user_123").subject(),
            "typewriter.to.user.user_123.join_requests.changed"
        );
        assert_eq!(
            super::organization_members_changed("org_123").subject(),
            "typewriter.to.organization.org_123.members.changed"
        );
        assert_eq!(
            super::organization_join_requests_changed("org_123").subject(),
            "typewriter.to.organization.org_123.join_requests.changed"
        );
        assert_eq!(
            super::organization_join_codes_changed("org_123").subject(),
            "typewriter.to.organization.org_123.join_codes.changed"
        );
    }

    #[test]
    fn organization_services_changed_subject_formats_organization_id() {
        let subject = super::organization_services_changed("org_123");

        assert_eq!(
            subject.subject(),
            "typewriter.to.organization.org_123.services.watch"
        );
    }

    #[test]
    fn service_bound_subject_formats_service_id() {
        let subject = super::service_bound("service_123");

        assert_eq!(
            subject.subject(),
            "typewriter.to.service.service_123.registration.bound"
        );
    }
}
