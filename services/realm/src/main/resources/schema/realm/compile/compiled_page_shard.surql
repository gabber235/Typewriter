DEFINE TABLE OVERWRITE compiled_page_shard SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE input_fingerprint ON compiled_page_shard TYPE string
    ASSERT string::len($value) = 64;
DEFINE FIELD OVERWRITE page ON compiled_page_shard TYPE record<page>;
DEFINE FIELD OVERWRITE payload ON compiled_page_shard TYPE string;

DEFINE INDEX OVERWRITE compiled_page_shard_input
    ON compiled_page_shard FIELDS input_fingerprint UNIQUE;
