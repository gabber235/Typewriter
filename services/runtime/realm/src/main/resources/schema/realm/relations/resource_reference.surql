DEFINE TABLE OVERWRITE resource_reference SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE source ON resource_reference
    TYPE record<book | page | tag | element>
    REFERENCE ON DELETE CASCADE;

DEFINE FIELD OVERWRITE target ON resource_reference
    TYPE record<book | page | tag | element>
    REFERENCE ON DELETE IGNORE;

DEFINE FIELD OVERWRITE slot ON resource_reference TYPE string
    ASSERT string::trim($value) != "";

DEFINE FIELD OVERWRITE expected_type ON resource_reference TYPE string
    ASSERT string::trim($value) != "";

DEFINE INDEX OVERWRITE resource_reference_source_slot
    ON resource_reference FIELDS source, slot UNIQUE;

DEFINE INDEX OVERWRITE resource_reference_target
    ON resource_reference FIELDS target;
