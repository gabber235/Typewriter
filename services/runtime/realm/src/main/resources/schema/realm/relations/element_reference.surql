DEFINE TABLE OVERWRITE element_reference SCHEMAFULL
    TYPE RELATION FROM element TO element | page | book | tag
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE slot ON element_reference TYPE string
    ASSERT string::trim($value) != "";

DEFINE FIELD OVERWRITE expected_type ON element_reference TYPE string
    ASSERT string::trim($value) != "";

DEFINE INDEX OVERWRITE element_reference_slot
    ON element_reference FIELDS in, slot UNIQUE;

DEFINE INDEX OVERWRITE element_reference_target
    ON element_reference FIELDS out;
