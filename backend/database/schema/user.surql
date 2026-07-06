-- Authentik user id is the record id.
DEFINE TABLE OVERWRITE user SCHEMAFULL
    PERMISSIONS
        FOR select WHERE id = $auth.id
        FOR create, update, delete NONE;

DEFINE FIELD OVERWRITE email ON user TYPE option<string>
    ASSERT $value == NONE OR string::is_email($value);

DEFINE FIELD OVERWRITE name ON user TYPE option<string>;

DEFINE FIELD OVERWRITE avatar ON user TYPE option<string>;

DEFINE FIELD OVERWRITE avatar_url ON user TYPE option<string>
    ASSERT $value == NONE OR fn::is_http_url($value);

DEFINE FIELD OVERWRITE created_at ON user TYPE datetime
    DEFAULT time::now()
    READONLY
    VALUE $before OR time::now();

DEFINE FIELD OVERWRITE last_login ON user TYPE datetime
    DEFAULT time::now();

DEFINE INDEX OVERWRITE user_email_unique ON user FIELDS email UNIQUE;
