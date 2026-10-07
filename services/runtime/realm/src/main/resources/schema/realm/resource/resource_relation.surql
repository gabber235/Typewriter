DEFINE TABLE OVERWRITE resource_relation SCHEMAFULL
    TYPE RELATION FROM resource TO resource ENFORCED
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE contract ON resource_relation TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE first_location ON resource_relation TYPE option<object> FLEXIBLE;
DEFINE FIELD OVERWRITE second_location ON resource_relation TYPE option<object> FLEXIBLE;
DEFINE INDEX OVERWRITE resource_relation_first
    ON resource_relation FIELDS in, contract;
DEFINE INDEX OVERWRITE resource_relation_second
    ON resource_relation FIELDS out, contract;
