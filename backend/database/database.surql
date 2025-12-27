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
-- Color stored as ARGB uint32 (default: neutral gray 0xFF9E9E9E = 4288585374)
DEFINE FIELD OVERWRITE color ON role TYPE int DEFAULT 4288585374 ASSERT $value >= 0 && $value <= 4294967295 PERMISSIONS NONE;
-- Can this role be deleted?
DEFINE FIELD OVERWRITE deletable ON role TYPE bool DEFAULT true PERMISSIONS NONE;
-- Can this role be assigned to users?
DEFINE FIELD OVERWRITE assignable ON role TYPE bool DEFAULT true PERMISSIONS NONE;
-- Is this the default role?
DEFINE FIELD OVERWRITE default_role ON role TYPE bool DEFAULT false PERMISSIONS NONE;
DEFINE FIELD OVERWRITE priority ON role TYPE int DEFAULT 1 PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON role TYPE datetime DEFAULT time::now() READONLY VALUE $before OR time::now() PERMISSIONS NONE;

DEFINE INDEX OVERWRITE unique_role_per_org ON role FIELDS name, organization UNIQUE;

-- ------------------------------
-- TABLE: user
-- ------------------------------

-- Service table (authentik_user_id is the record id)
DEFINE TABLE OVERWRITE user TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE avatar ON user TYPE option<string> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE avatar_url ON user TYPE option<string> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE email ON user TYPE option<string> ASSERT string::is::email($value) PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON user TYPE datetime DEFAULT time::now() READONLY VALUE $before OR time::now() PERMISSIONS NONE;
DEFINE FIELD OVERWRITE last_login ON user TYPE datetime DEFAULT time::now() PERMISSIONS NONE;
DEFINE FIELD OVERWRITE name ON user TYPE option<string> PERMISSIONS NONE;

-- ------------------------------
-- TABLE: requests_to_join (graph: user->requests_to_join->organization)
-- ------------------------------

DEFINE TABLE OVERWRITE requests_to_join TYPE RELATION IN user OUT organization ENFORCED SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE in ON requests_to_join TYPE record<user> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE out ON requests_to_join TYPE record<organization> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE requested_at ON requests_to_join TYPE datetime DEFAULT time::now() READONLY VALUE $before OR time::now() PERMISSIONS NONE;
-- Default expiration is 7 days from now
DEFINE FIELD OVERWRITE expires_at ON requests_to_join TYPE datetime DEFAULT time::now() + 7d PERMISSIONS NONE;

-- ------------------------------
-- TABLE: join_code
-- ------------------------------

DEFINE TABLE OVERWRITE join_code TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE organization ON join_code TYPE record<organization> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON join_code TYPE datetime DEFAULT time::now() READONLY VALUE $before OR time::now() PERMISSIONS NONE;
-- Expiration: NONE means never expires
DEFINE FIELD OVERWRITE expires_at ON join_code TYPE option<datetime> DEFAULT time::now() + 7d PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_by ON join_code TYPE record<user> PERMISSIONS NONE;
-- Single-use flag: code is deleted when used
DEFINE FIELD OVERWRITE single_use ON join_code TYPE bool DEFAULT true PERMISSIONS NONE;
-- Auto-accept role IDs: empty array means manual approval required
DEFINE FIELD OVERWRITE auto_accept_roles ON join_code TYPE array<record<role>> DEFAULT [] PERMISSIONS NONE;

-- ------------------------------
-- TABLE: service
-- ------------------------------

-- Service table (authentik_user_id is the record id)
DEFINE TABLE OVERWRITE service TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON service TYPE string
  ASSERT string::matches($value, '^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$')
  PERMISSIONS NONE;

DEFINE FIELD OVERWRITE service_types ON service TYPE array<'engine' | 'realm'>
  PERMISSIONS NONE;

DEFINE FIELD OVERWRITE created_at ON service TYPE datetime
  DEFAULT time::now() READONLY VALUE $before OR time::now()
  PERMISSIONS NONE;

DEFINE FIELD OVERWRITE last_seen ON service TYPE option<datetime>
  PERMISSIONS NONE;

DEFINE FIELD OVERWRITE metadata ON service TYPE option<object>
  PERMISSIONS NONE;

-- Organization the service belongs to (set later during linking)
DEFINE FIELD OVERWRITE organization ON service TYPE option<record<organization>>
  PERMISSIONS NONE;

-- Only engines can have a runs_in reference, and it must point to a realm
DEFINE FIELD OVERWRITE runs_in ON service TYPE option<record<service>>
  ASSERT {
    IF $value IS NONE {
      RETURN true
    };
    IF !('engine' IN $this.service_types) {
      THROW "Only services with 'engine' type can have runs_in set"
    };
    IF !('realm' IN $value.service_types) {
      THROW "runs_in must reference a service with 'realm' type"
    };
    RETURN true
  }
  PERMISSIONS NONE;

