DEFINE TABLE OVERWRITE active_compiled_manifest SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE manifest ON active_compiled_manifest TYPE record<compiled_manifest>;
DEFINE FIELD OVERWRITE activation_revision ON active_compiled_manifest TYPE int DEFAULT 1
    ASSERT $value > 0;
DEFINE FIELD OVERWRITE activation_payload ON active_compiled_manifest TYPE string;
DEFINE FIELD OVERWRITE activated_at ON active_compiled_manifest TYPE datetime DEFAULT time::now();
