DEFINE TABLE OVERWRITE member_of TYPE RELATION FROM user TO organization ENFORCED SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE in ON member_of TYPE record<user>;
DEFINE FIELD OVERWRITE out ON member_of TYPE record<organization>;

DEFINE FIELD OVERWRITE roles ON member_of TYPE array<record<organization_role>>
    ASSERT {
        IF array::len($value) < 1 { THROW "At least one role is required" };
        IF !fn::organization::roles::valid_for($value, out) { THROW "All roles must belong to the target organization" };
        RETURN true;
    };

DEFINE FIELD OVERWRITE joined_at ON member_of TYPE datetime
    DEFAULT time::now()
    READONLY
    VALUE $before OR time::now();

DEFINE INDEX OVERWRITE member_of_by_account ON member_of FIELDS in;
DEFINE INDEX OVERWRITE member_of_by_organization ON member_of FIELDS out;
DEFINE INDEX OVERWRITE member_of_unique ON member_of FIELDS in, out UNIQUE;

DEFINE EVENT OVERWRITE guard_founder_role_holder ON member_of WHEN $event IN ["DELETE", "UPDATE"] THEN {
    LET $org = IF $event = "DELETE" { $before.out } ELSE { $after.out };
    IF (SELECT VALUE id FROM ONLY $org) == NONE { RETURN NONE };

    LET $founder_members = (
        SELECT VALUE id FROM member_of
        WHERE out = $org AND fn::organization::roles::has_named_role(roles, "founder")
    );
    IF array::len($founder_members) = 0 { THROW "Organization needs at least one founder role holder" };
};

DEFINE EVENT OVERWRITE guard_founder_removal ON member_of WHEN $event = "DELETE" THEN {
    IF (SELECT VALUE id FROM ONLY $before.out) == NONE { RETURN NONE };
    IF $before.out.founder == $before.in { THROW "Cannot remove the founder while organization exists" };
};
