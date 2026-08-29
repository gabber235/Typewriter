DEFINE TABLE OVERWRITE realm_outbox SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE subject ON realm_outbox TYPE string;
DEFINE FIELD OVERWRITE payload ON realm_outbox TYPE array<int>;
DEFINE FIELD OVERWRITE state ON realm_outbox TYPE "pending" | "published";
DEFINE FIELD OVERWRITE attempts ON realm_outbox TYPE int DEFAULT 0
    ASSERT $value >= 0;
DEFINE FIELD OVERWRITE available_at ON realm_outbox TYPE datetime;
DEFINE FIELD OVERWRITE created_at ON realm_outbox TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE published_at ON realm_outbox TYPE option<datetime> DEFAULT NONE;

DEFINE INDEX OVERWRITE realm_outbox_pending ON realm_outbox FIELDS state, available_at, created_at;
