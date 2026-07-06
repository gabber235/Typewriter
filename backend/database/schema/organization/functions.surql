DEFINE FUNCTION OVERWRITE fn::organization::roles::valid_for($roles: array<record<organization_role>>, $organization: record<organization>) -> bool {
    RETURN array::len($roles) > 0 AND $roles.all(|$role| $role.organization = $organization);
};

DEFINE FUNCTION OVERWRITE fn::organization::roles::assignable_for($roles: array<record<organization_role>>, $organization: record<organization>) -> bool {
    RETURN $roles.all(|$role| $role.organization = $organization AND $role.assignable = true);
};

DEFINE FUNCTION OVERWRITE fn::organization::roles::has_named_role($roles: array<record<organization_role>>, $name: string) -> bool {
    RETURN $roles.any(|$role| $role.name = $name);
};

DEFINE FUNCTION OVERWRITE fn::organization::member($account: option<record<user>>, $organization: option<record<organization>>) -> bool {
    IF $account == NONE OR $organization == NONE { RETURN false };
    RETURN (SELECT VALUE id FROM member_of WHERE in = $account AND out = $organization LIMIT 1) != [];
};

DEFINE FUNCTION OVERWRITE fn::organization::founder_member($account: option<record<user>>, $organization: option<record<organization>>) -> bool {
    IF $account == NONE OR $organization == NONE { RETURN false };

    LET $role_sets = (SELECT VALUE roles FROM member_of WHERE out = $organization AND in = $account);
    LET $roles = array::flatten($role_sets);

    RETURN fn::organization::roles::has_named_role($roles, "founder");
};

DEFINE FUNCTION OVERWRITE fn::account::organization::unit($account: record<user>, $organization: record<organization>) -> option<record> {
    RETURN NONE;
};

DEFINE FUNCTION OVERWRITE fn::account::organization::teams($account: record<user>, $organization: record<organization>) -> array<any> {
    RETURN [];
};
