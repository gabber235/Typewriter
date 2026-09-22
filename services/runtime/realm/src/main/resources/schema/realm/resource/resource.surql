DEFINE TABLE OVERWRITE resource SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE definition ON resource TYPE string
    ASSERT string::trim($value) != "";

DEFINE FIELD OVERWRITE type_id ON resource TYPE string
    ASSERT string::trim($value) != "";

DEFINE FIELD OVERWRITE type_revision ON resource TYPE int
    ASSERT $value > 0;

DEFINE FIELD OVERWRITE value ON resource TYPE object FLEXIBLE;

DEFINE FIELD OVERWRITE sequence ON resource TYPE int DEFAULT 0;

DEFINE INDEX OVERWRITE resource_definition ON resource FIELDS definition;
DEFINE INDEX OVERWRITE resource_type ON resource FIELDS type_id, type_revision;

DEFINE TABLE OVERWRITE resource_relation SCHEMAFULL
    TYPE RELATION FROM resource TO resource ENFORCED
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE origin ON resource_relation TYPE
      {
        kind: "reference",
        reference_slot: string,
        source_path: object,
        expected_target: object
      }
    | {
        kind: "declared",
        relation_id: string
      };

DEFINE FIELD OVERWRITE origin_kind ON resource_relation TYPE string
    ASSERT $value = "reference" OR $value = "declared";

DEFINE FIELD OVERWRITE relation_id ON resource_relation TYPE option<string>;
DEFINE FIELD OVERWRITE source_path_key ON resource_relation TYPE option<string>;
DEFINE FIELD OVERWRITE expected_target_key ON resource_relation TYPE option<string>;

DEFINE INDEX OVERWRITE resource_relation_source
    ON resource_relation FIELDS in, origin.kind, origin.relation_id;

DEFINE INDEX OVERWRITE resource_relation_target
    ON resource_relation FIELDS out, origin.kind, origin.relation_id;

DEFINE INDEX OVERWRITE resource_relation_source_kind
    ON resource_relation FIELDS in, origin_kind, relation_id;

DEFINE INDEX OVERWRITE resource_relation_target_kind
    ON resource_relation FIELDS out, origin_kind, relation_id;

DEFINE INDEX OVERWRITE resource_relation_reference_path
    ON resource_relation FIELDS origin_kind, source_path_key;

DEFINE INDEX OVERWRITE resource_reference_slot
    ON resource_relation FIELDS in, origin.reference_slot UNIQUE;
