BEGIN TRANSACTION;
RETURN {
    LET $codes = SELECT organization.*, single_use, auto_accept_roles
        FROM $code
        WHERE expires_at IS NONE OR expires_at IS NULL OR expires_at > time::now();

    IF array::is_empty($codes) {
        RETURN { kind: 'code_not_found_error' }
    };

    LET $join_code = array::first($codes);
    LET $organization = $join_code.organization;
    LET $org = $organization.id;

    IF array::len(SELECT id FROM member_of WHERE in = $user AND out = $org) > 0 {
        RETURN { kind: 'already_member_error' }
    };

    IF array::is_empty($join_code.auto_accept_roles) {
        LET $existing_requests = SELECT out FROM request_to_join
            WHERE in = $user AND expires_at > time::now();

        IF array::len($existing_requests) >= 5 {
            RETURN { kind: 'max_pending_requests_error' }
        };

        IF array::any($existing_requests, |$request| $request.out = $org) {
            RETURN { kind: 'pending_request_exists_error' }
        };

        IF $join_code.single_use {
            DELETE $code;
        };

        LET $request = RELATE ONLY $user->request_to_join->$org;
        LET $user_sequence = UPDATE ONLY $user SET join_requests_sequence += 1
            RETURN VALUE join_requests_sequence;
        LET $organization_sequence = UPDATE ONLY $org SET join_requests_sequence += 1
            RETURN VALUE join_requests_sequence;
        LET $join_codes_sequence = IF $join_code.single_use {
            UPDATE ONLY $org SET join_codes_sequence += 1 RETURN VALUE join_codes_sequence
        } ELSE { NONE };

        RETURN {
            kind: 'request_made',
            single_use: $join_code.single_use,
            code_id: $code,
            user_sequence: $user_sequence,
            organization_sequence: $organization_sequence,
            join_codes_sequence: $join_codes_sequence,
            request: (SELECT
                id,
                in.* AS user,
                out.* AS organization,
                requested_at,
                expires_at
            FROM ONLY $request)
        }
    };

    LET $requested_roles = array::distinct($join_code.auto_accept_roles);
    LET $roles = SELECT VALUE id FROM $requested_roles
        WHERE organization = $org AND assignable;

    IF array::len($roles) != array::len($requested_roles) OR array::is_empty($roles) {
        RETURN { kind: 'no_assignable_roles_error' }
    };

    IF $join_code.single_use {
        DELETE $code;
    };

    LET $member = RELATE ONLY $user->member_of->$org SET roles = $roles;
    LET $user_sequence = UPDATE ONLY $user SET organizations_sequence += 1
        RETURN VALUE organizations_sequence;
    LET $organization_sequence = UPDATE ONLY $org SET members_sequence += 1
        RETURN VALUE members_sequence;
    LET $join_codes_sequence = IF $join_code.single_use {
        UPDATE ONLY $org SET join_codes_sequence += 1 RETURN VALUE join_codes_sequence
    } ELSE { NONE };

    RETURN {
        kind: 'auto_accepted',
        single_use: $join_code.single_use,
        code_id: $code,
        user_sequence: $user_sequence,
        organization_sequence: $organization_sequence,
        join_codes_sequence: $join_codes_sequence,
        organization: $organization,
        member: (SELECT
            in.id AS user_id,
            in.name AS name,
            in.email AS email,
            in.avatar_url AS avatar_url,
            roles.* AS roles,
            joined_at
        FROM ONLY $member
        FETCH roles)
    }
};
COMMIT TRANSACTION;
