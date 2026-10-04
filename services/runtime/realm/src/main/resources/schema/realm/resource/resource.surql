DEFINE TABLE OVERWRITE resource SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE definition ON resource TYPE string
    ASSERT string::trim($value) != "";

DEFINE FIELD OVERWRITE content ON resource TYPE string
    ASSERT string::trim($value) != "";

DEFINE FIELD OVERWRITE snapshot ON resource TYPE int DEFAULT 0;

DEFINE INDEX OVERWRITE resource_definition ON resource FIELDS definition;

DEFINE TABLE OVERWRITE resource_relation SCHEMAFULL
    TYPE RELATION FROM resource TO resource ENFORCED
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE contract ON resource_relation TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE first_location ON resource_relation TYPE option<string>;
DEFINE FIELD OVERWRITE second_location ON resource_relation TYPE option<string>;
DEFINE FIELD OVERWRITE first_occurrence ON resource_relation TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE second_occurrence ON resource_relation TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE snapshot ON resource_relation TYPE int;

DEFINE INDEX OVERWRITE resource_relation_first
    ON resource_relation FIELDS in, contract;
DEFINE INDEX OVERWRITE resource_relation_second
    ON resource_relation FIELDS out, contract;
DEFINE INDEX OVERWRITE resource_relation_first_occurrence
    ON resource_relation FIELDS in, contract, first_occurrence UNIQUE;
DEFINE INDEX OVERWRITE resource_relation_second_occurrence
    ON resource_relation FIELDS out, contract, second_occurrence UNIQUE;

DEFINE TABLE OVERWRITE authoring_input SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE identity ON authoring_input TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE token ON authoring_input TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE snapshot ON authoring_input TYPE int;

DEFINE INDEX OVERWRITE authoring_input_identity ON authoring_input FIELDS identity UNIQUE;

DEFINE TABLE OVERWRITE authoring_acceptance_fence SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;
DEFINE FIELD OVERWRITE revision ON authoring_acceptance_fence TYPE int DEFAULT 0;
DEFINE FIELD OVERWRITE gate ON authoring_acceptance_fence TYPE int DEFAULT 0;
DEFINE FIELD OVERWRITE catalog_generation ON authoring_acceptance_fence TYPE string DEFAULT "";
DEFINE FIELD OVERWRITE pending_catalog_generation ON authoring_acceptance_fence TYPE option<string>;

UPSERT ONLY authoring_acceptance_fence:current
    SET revision = revision OR 0, gate = gate OR 0, catalog_generation = catalog_generation OR "";

DEFINE TABLE OVERWRITE authoring_event_outbox SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;
DEFINE FIELD OVERWRITE batch ON authoring_event_outbox TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE snapshot ON authoring_event_outbox TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE sequence ON authoring_event_outbox TYPE int;
DEFINE FIELD OVERWRITE payload ON authoring_event_outbox TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE acknowledged ON authoring_event_outbox TYPE bool DEFAULT false;

DEFINE INDEX OVERWRITE authoring_outbox_batch ON authoring_event_outbox FIELDS batch UNIQUE;
