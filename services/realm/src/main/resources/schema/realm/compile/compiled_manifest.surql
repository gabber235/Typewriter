DEFINE TABLE OVERWRITE compiled_manifest SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE source_revision ON compiled_manifest TYPE string;
DEFINE FIELD OVERWRITE catalog_revision ON compiled_manifest TYPE string;
DEFINE FIELD OVERWRITE pages ON compiled_manifest TYPE array<record<compiled_page_shard>>;
DEFINE FIELD OVERWRITE payload ON compiled_manifest TYPE string;
