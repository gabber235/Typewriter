DEFINE TABLE OVERWRITE request_to_join TYPE RELATION FROM user TO organization ENFORCED SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE in ON request_to_join TYPE record<user>;
DEFINE FIELD OVERWRITE out ON request_to_join TYPE record<organization>;

DEFINE FIELD OVERWRITE requested_at ON request_to_join TYPE datetime
    DEFAULT time::now()
    READONLY
    VALUE $before OR time::now();

DEFINE FIELD OVERWRITE expires_at ON request_to_join TYPE datetime
    DEFAULT time::now() + 7d;

DEFINE INDEX OVERWRITE request_to_join_user_expiry ON request_to_join FIELDS in, expires_at;
DEFINE INDEX OVERWRITE request_to_join_unique ON request_to_join FIELDS in, out UNIQUE;
