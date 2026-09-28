DEFINE TABLE OVERWRITE authoring_batch SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE operation ON authoring_batch TYPE string
    ASSERT string::trim($value) != "";

DEFINE FIELD OVERWRITE request_hash ON authoring_batch TYPE string
    ASSERT string::len($value) = 64;

DEFINE FIELD OVERWRITE result ON authoring_batch TYPE string
    ASSERT string::trim($value) != "";
