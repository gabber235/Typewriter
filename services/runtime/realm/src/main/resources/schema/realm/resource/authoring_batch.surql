DEFINE TABLE OVERWRITE authoring_batch SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE intent_digest ON authoring_batch TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE result ON authoring_batch TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE snapshot ON authoring_batch TYPE string
    ASSERT string::trim($value) != "";

DEFINE TABLE OVERWRITE creation_receipt SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE intent_digest ON creation_receipt TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE catalog ON creation_receipt TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE result ON creation_receipt TYPE string
    ASSERT string::trim($value) != "";
