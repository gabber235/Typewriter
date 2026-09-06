DEFINE TABLE OVERWRITE authoring_head SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE revision ON authoring_head TYPE int DEFAULT 0
    ASSERT $value >= 0;

UPSERT ONLY authoring_head:current SET revision = revision OR 0;
