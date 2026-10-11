use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    publication::{
        CapturedOnly, CommittedChange, MembershipFact, PublicationEffect, PublicationExecutor,
    },
    skir::base::organization::v1::organization::*,
    skir_domain_result, skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

use wasmcloud_utils::database::organization::OrganizationRecord;

/// Database result from creating an organization and advancing the user's list sequence.
///
/// Both values come from the same transaction so the emitted user projection change identifies
/// the sequence at which the new organization became visible.
#[derive(Deserialize)]
struct CreatedOrganization {
    organization: OrganizationRecord,
    sequence: i64,
}

impl CreatedOrganization {
    fn into_committed_change(self, user: &str) -> CommittedChange<CreateOrganizationResponse> {
        let organization: Organization = self.organization.into();
        let event = UserOrganizationsChanged {
            sequence: self.sequence,
            changes: vec![UserOrganizationsChange::Add(Box::new(organization.clone()))],
            ..Default::default()
        };
        CommittedChange::new(
            skir_variant!(CreateOrganizationResponse::Success {
                organization,
                event: event.clone(),
            }),
            [PublicationEffect::CapturedMembership(
                MembershipFact::UserOrganizations {
                    user: user.to_owned(),
                    event,
                },
            )],
        )
    }
}

/// Creates an organization for the user in the message subject.
///
/// The transaction records the organization and advances the user's organization list sequence.
/// After the transaction commits, the handler persists the corresponding add change and returns
/// that same event with the created organization. Event persistence remains a separate effect
/// after the database transaction.
#[tracing::instrument(skip_all)]
pub async fn handle_create(
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::UserScope,
    request: CreateOrganizationRequest,
) -> Result<CreateOrganizationResponse, otel_wasi::Error> {
    let user_id = scope.user.as_str();
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let user_key = user_id;
    let user_id = RecordId::new("user", user_id);

    let name = request.name;
    let logo_url = request.logo_url;

    let organization = transaction_query!(
        CreatedOrganization,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            LET $organization = CREATE ONLY organization SET
                name = $name,
                logo_url = $logo_url,
                founder = $user_id
            ;

            LET $sequence = UPDATE ONLY $user_id SET organizations_sequence += 1
                RETURN VALUE organizations_sequence;
            RETURN { organization: $organization, sequence: $sequence };
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("name", &name)
    .bind("logo_url", &logo_url)
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("organization-create-query-failed")?
    .decode()
    .error_with_slug("organization-create-result-parse-failed")?;
    let created = skir_domain_result!(CreateOrganizationResponse, organization);
    otel_wasi::main_attribute!("organization.outcome" = "created");
    created
        .into_committed_change(user_key)
        .publish_with(&PublicationExecutor {
            refresher: CapturedOnly,
        })
        .await
}
