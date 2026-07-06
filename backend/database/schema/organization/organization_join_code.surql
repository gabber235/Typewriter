DEFINE TABLE OVERWRITE organization_join_code SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE organization ON organization_join_code TYPE record<organization>
    REFERENCE ON DELETE CASCADE;

DEFINE FIELD OVERWRITE created_at ON organization_join_code TYPE datetime
    DEFAULT time::now()
    READONLY
    VALUE $before OR time::now();

DEFINE FIELD OVERWRITE created_by ON organization_join_code TYPE option<record<user>>
    REFERENCE ON DELETE UNSET
    DEFAULT $auth
    READONLY;

DEFINE FIELD OVERWRITE expires_at ON organization_join_code TYPE option<datetime>
    DEFAULT time::now() + 7d;

DEFINE FIELD OVERWRITE single_use ON organization_join_code TYPE bool
    DEFAULT true;

DEFINE FIELD OVERWRITE auto_accept_roles ON organization_join_code TYPE array<record<organization_role>>
    DEFAULT []
    ASSERT {
        IF !fn::organization::roles::assignable_for($value, $this.organization) {
            THROW "Auto-accept roles must be assignable roles from the target organization"
        };
        RETURN true;
    };

DEFINE INDEX OVERWRITE organization_join_code_by_organization ON organization_join_code FIELDS organization;
DEFINE INDEX OVERWRITE organization_join_code_by_expiry ON organization_join_code FIELDS expires_at;
