DEFINE TABLE OVERWRITE collaboration_head SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE revision ON collaboration_head TYPE int DEFAULT 0
    ASSERT $value >= 0;

UPSERT ONLY collaboration_head:current SET revision = revision OR 0;
