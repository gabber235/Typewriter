macro_rules! with_join_submission_query {
    ($callback:ident $(, $argument:tt)*) => {
        $callback!(
            $($argument,)*
            r#"
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

                    RETURN {
                        kind: 'request_made',
                        single_use: $join_code.single_use,
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

                RETURN {
                    kind: 'auto_accepted',
                    single_use: $join_code.single_use,
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
            "#
        )
    };
}

#[allow(unused_macros)]
macro_rules! build_join_submission_transaction {
    ($outcome:ty, $query:literal) => {
        transaction_query!($outcome, $query)
    };
}

#[allow(unused_macros)]
macro_rules! return_join_submission_query {
    ($query:literal) => {
        $query
    };
}

#[allow(unused_macros)]
macro_rules! return_join_submission_outcome_index {
    ($query:literal) => {
        wasmcloud_utils::transaction_outcome_index!($query)
    };
}

macro_rules! join_submission_transaction {
    (query) => {
        with_join_submission_query!(return_join_submission_query)
    };
    (outcome_index) => {
        with_join_submission_query!(return_join_submission_outcome_index)
    };
    ($outcome:ty) => {
        with_join_submission_query!(build_join_submission_transaction, $outcome)
    };
}
