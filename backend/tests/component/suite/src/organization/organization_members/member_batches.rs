use super::*;

#[component_test(OrganizationMembers)]
async fn invalid_middle_member_rejects_entire_batch_without_partial_write(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    let writer = role_key(&database, "writer").await?;
    let response = update(
        context,
        &UpdateOrganizationMemberRolesRequest {
            user_ids: vec![
                skir_record_id("user", "founder"),
                skir_record_id("user", "missing"),
                skir_record_id("user", "member"),
            ],
            role_ids: vec![skir_record_id("organization_role", &writer)],
            _unrecognized: None,
        },
    )
    .await?;
    assert!(matches!(
        response,
        UpdateOrganizationMemberRolesResponse::UserNotFoundError(_)
    ));
    assert_jm!(database.query_json("RETURN { founder_roles: (SELECT VALUE roles.name FROM ONLY member_of WHERE in = user:founder AND out = organization:alpha FETCH roles) }").await?, { "founder_roles": ["founder"] });
    Ok(())
}

async fn update(
    context: &mut TestContext<OrganizationMembers>,
    request: &UpdateOrganizationMemberRolesRequest,
) -> anyhow::Result<UpdateOrganizationMemberRolesResponse> {
    Ok(context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.update",
            request,
            UpdateOrganizationMemberRolesRequest::serializer(),
            UpdateOrganizationMemberRolesResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?)
}
