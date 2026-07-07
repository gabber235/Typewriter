use crate::{
    define_skir_subjects,
    skirout::base::organization::v1::{
        join_codes::WatchOrganizationJoinCodesResponse,
        join_request::WatchOrganizationJoinRequestsResponse,
        member::WatchOrganizationMembersResponse,
        user::{WatchUserJoinRequestsResponse, WatchUserOrganizationsResponse},
    },
};

define_skir_subjects! {
    user_organizations(user_id) -> WatchUserOrganizationsResponse =
        "typewriter.out.user.{user_id}.organization.watch";

    user_join_requests(user_id) -> WatchUserJoinRequestsResponse =
        "typewriter.out.user.{user_id}.organization.join_requests.watch";

    organization_members(organization_id) -> WatchOrganizationMembersResponse =
        "typewriter.out.organization.{organization_id}.members.watch";

    organization_join_requests(organization_id) -> WatchOrganizationJoinRequestsResponse =
        "typewriter.out.organization.{organization_id}.members.join_requests.watch";

    organization_join_codes(organization_id) -> WatchOrganizationJoinCodesResponse =
        "typewriter.out.organization.{organization_id}.members.join_codes.watch";
}

#[cfg(test)]
mod tests {
    #[test]
    fn user_organizations_subject_formats_user_id() {
        let subject = super::user_organizations("user_123");

        assert_eq!(
            subject.subject(),
            "typewriter.out.user.user_123.organization.watch"
        );
    }

    #[test]
    fn user_join_requests_subject_formats_user_id() {
        let subject = super::user_join_requests("user_123");

        assert_eq!(
            subject.subject(),
            "typewriter.out.user.user_123.organization.join_requests.watch"
        );
    }

    #[test]
    fn organization_members_subject_formats_organization_id() {
        let subject = super::organization_members("org_123");

        assert_eq!(
            subject.subject(),
            "typewriter.out.organization.org_123.members.watch"
        );
    }

    #[test]
    fn organization_join_requests_subject_formats_organization_id() {
        let subject = super::organization_join_requests("org_123");

        assert_eq!(
            subject.subject(),
            "typewriter.out.organization.org_123.members.join_requests.watch"
        );
    }

    #[test]
    fn organization_join_codes_subject_formats_organization_id() {
        let subject = super::organization_join_codes("org_123");

        assert_eq!(
            subject.subject(),
            "typewriter.out.organization.org_123.members.join_codes.watch"
        );
    }
}
