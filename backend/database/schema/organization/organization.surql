DEFINE TABLE OVERWRITE organization SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON organization TYPE string
    ASSERT fn::is_id($value);

DEFINE FIELD OVERWRITE logo_url ON organization TYPE option<string>
    ASSERT $value == NONE OR fn::is_http_url($value);

DEFINE FIELD OVERWRITE founder ON organization TYPE record<user>
    REFERENCE ON DELETE REJECT
    DEFAULT $auth;

DEFINE FIELD OVERWRITE created_at ON organization TYPE datetime
    DEFAULT time::now()
    READONLY
    VALUE $before OR time::now();

DEFINE FIELD OVERWRITE updated_at ON organization TYPE datetime
    DEFAULT time::now()
    VALUE time::now();

DEFINE INDEX OVERWRITE organization_name_unique ON organization FIELDS name UNIQUE;

DEFINE EVENT OVERWRITE setup_organization ON organization WHEN $event = "CREATE" THEN {
    LET $founder_role = CREATE ONLY organization_role SET
        name = "founder",
        organization = $after.id,
        color = fn::color("#53AAD0"),
        deletable = false,
        assignable = false,
        default_role = false,
        priority = 9223372036854775807;

    LET $writer_role = CREATE ONLY organization_role SET
        name = "writer",
        organization = $after.id,
        color = $gray,
        deletable = false,
        assignable = true,
        default_role = true,
        priority = 0;

    LET $founder = $after.founder;
    LET $organization = $after.id;
    RELATE $founder->member_of->$organization SET
        roles = [$founder_role.id];
};
