-- ------------------------------
-- TABLE: member_of
-- ------------------------------

DEFINE TABLE OVERWRITE member_of TYPE RELATION IN user OUT organization ENFORCED SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE in ON member_of TYPE record<user> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE out ON member_of TYPE record<organization> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE joined_at ON member_of TYPE datetime DEFAULT time::now() READONLY VALUE $before OR time::now() PERMISSIONS NONE;
DEFINE FIELD OVERWRITE roles ON member_of TYPE array<record<role>>
  ASSERT {
    IF array::len($value) < 1 {
      THROW "At least one role is required"
    };
    IF !$value.all(|$role| $role.organization = out) {
      THROW "All roles must belong to the target organization"
    };
    RETURN true
  }
  PERMISSIONS NONE;


-- ------------------------------
-- TABLE: organization
-- ------------------------------

DEFINE TABLE OVERWRITE organization TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON organization TYPE string ASSERT string::matches($value, '^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$') PERMISSIONS NONE;
DEFINE FIELD OVERWRITE icon_url ON organization TYPE string ASSERT string::is::url($value) PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON organization TYPE datetime DEFAULT time::now() READONLY VALUE $before OR time::now() PERMISSIONS NONE;
DEFINE FIELD OVERWRITE updated_at ON organization TYPE datetime DEFAULT time::now() PERMISSIONS NONE;

-- ------------------------------
-- TABLE: role
-- ------------------------------

DEFINE TABLE OVERWRITE role TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON role TYPE string ASSERT string::matches($value, '^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$') PERMISSIONS NONE;
DEFINE FIELD OVERWRITE organization ON role TYPE record<organization> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE deletable ON role TYPE bool DEFAULT true PERMISSIONS NONE;
DEFINE FIELD OVERWRITE assignable ON role TYPE bool DEFAULT true PERMISSIONS NONE;
DEFINE FIELD OVERWRITE priority ON role TYPE int DEFAULT 1 PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON role TYPE datetime DEFAULT time::now() READONLY VALUE $before OR time::now() PERMISSIONS NONE;

DEFINE INDEX OVERWRITE unique_role_per_org ON role FIELDS name, organization UNIQUE;

-- ------------------------------
-- TABLE: user
-- ------------------------------

DEFINE TABLE OVERWRITE user TYPE ANY SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE avatar ON user TYPE option<string> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE avatar_url ON user TYPE option<string> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE email ON user TYPE option<string> ASSERT string::is::email($value) PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON user TYPE datetime DEFAULT time::now() READONLY VALUE $before OR time::now() PERMISSIONS NONE;
DEFINE FIELD OVERWRITE last_login ON user TYPE datetime DEFAULT time::now() PERMISSIONS NONE;
DEFINE FIELD OVERWRITE name ON user TYPE option<string> PERMISSIONS NONE;
