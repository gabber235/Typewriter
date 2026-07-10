DEFINE TABLE OVERWRITE organization_role SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON organization_role TYPE string
    ASSERT fn::is_id($value);

DEFINE FIELD OVERWRITE organization ON organization_role TYPE record<organization>
    REFERENCE ON DELETE CASCADE
    READONLY;

DEFINE FIELD OVERWRITE color ON organization_role TYPE int
    DEFAULT $gray
    ASSERT fn::is_color($value);

DEFINE FIELD OVERWRITE deletable ON organization_role TYPE bool
    DEFAULT true;

DEFINE FIELD OVERWRITE assignable ON organization_role TYPE bool
    DEFAULT true;

DEFINE FIELD OVERWRITE default_role ON organization_role TYPE bool
    DEFAULT false;

DEFINE FIELD OVERWRITE priority ON organization_role TYPE number
    DEFAULT 1;

DEFINE INDEX OVERWRITE organization_role_unique ON organization_role FIELDS organization, name UNIQUE;

DEFINE EVENT OVERWRITE guard_default_role_count ON organization_role WHEN $event IN ["CREATE", "UPDATE", "DELETE"] THEN {
    LET $org = IF $event = "DELETE" { $before.organization } ELSE { $after.organization };
    IF (SELECT VALUE id FROM ONLY $org) == NONE { RETURN NONE };

    LET $defaults = (SELECT VALUE id FROM organization_role WHERE organization = $org AND default_role = true);

    IF $event IN ["UPDATE", "DELETE"] AND $before.default_role = true AND array::len($defaults) = 0 {
        THROW "Organization needs at least one default role"
    };
};

DEFINE EVENT OVERWRITE guard_role_delete_or_deactivate ON organization_role WHEN $event IN ["UPDATE", "DELETE"] THEN {
    LET $role = IF $event = "DELETE" { $before.id } ELSE { $after.id };
    LET $org = IF $event = "DELETE" { $before.organization } ELSE { $after.organization };
    IF (SELECT VALUE id FROM ONLY $org) == NONE { RETURN NONE };

    IF $event = "DELETE" {
        LET $members = (SELECT VALUE id FROM member_of WHERE $role IN roles);
        IF array::len($members) > 0 { THROW "Cannot delete a role that is assigned to members" };

        LET $codes = (SELECT VALUE id FROM organization_join_code WHERE $role IN auto_accept_roles);
        IF array::len($codes) > 0 { THROW "Cannot delete a role that is used by join codes" };
    };

    IF $event = "UPDATE" AND $before.assignable = true AND $after.assignable = false {
        LET $codes = (SELECT VALUE id FROM organization_join_code WHERE $role IN auto_accept_roles);
        IF array::len($codes) > 0 { THROW "Cannot make a join-code role unassignable" };
    };
};
