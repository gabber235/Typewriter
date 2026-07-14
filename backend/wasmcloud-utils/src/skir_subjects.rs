use crate::{
    define_skir_subjects,
    skirout::base::{
        organization::v1::{
            join_codes::WatchOrganizationJoinCodesResponse,
            join_request::WatchOrganizationJoinRequestsResponse,
            member::WatchOrganizationMembersResponse,
            user::{WatchUserJoinRequestsResponse, WatchUserOrganizationsResponse},
        },
        service::v1::{
            organization::WatchOrganizationServicesResponse, registration::ServiceBoundNotification,
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

    organization_services(organization_id) -> WatchOrganizationServicesResponse =
        "typewriter.to.organization.{organization_id}.services.watch";

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
    fn organization_services_subject_formats_organization_id() {
        let subject = super::organization_services("org_123");

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
