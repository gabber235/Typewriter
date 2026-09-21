DEFINE TABLE OVERWRITE resource SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE kind ON resource TYPE string
    ASSERT $value = "book"
        OR $value = "tag"
        OR $value = "page"
        OR $value = "element";

DEFINE FIELD OVERWRITE type_id ON resource TYPE string
    ASSERT string::trim($value) != "";

DEFINE FIELD OVERWRITE type_revision ON resource TYPE int
    ASSERT $value > 0;

DEFINE FIELD OVERWRITE value ON resource TYPE object FLEXIBLE;

DEFINE FIELD OVERWRITE sequence ON resource TYPE int DEFAULT 0;

DEFINE INDEX OVERWRITE resource_kind ON resource FIELDS kind;
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

DEFINE INDEX OVERWRITE resource_relation_source
    ON resource_relation FIELDS in, origin.kind, origin.relation_id;

DEFINE INDEX OVERWRITE resource_relation_target
    ON resource_relation FIELDS out, origin.kind, origin.relation_id;

DEFINE INDEX OVERWRITE resource_reference_slot
    ON resource_relation FIELDS in, origin.reference_slot UNIQUE;
