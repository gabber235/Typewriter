DEFINE TABLE OVERWRITE compile_attempt_root SCHEMAFULL TYPE RELATION IN compile_attempt OUT resource
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE projection ON compile_attempt_root TYPE string;

DEFINE INDEX OVERWRITE attempt_root_lookup
    ON compile_attempt_root FIELDS projection, out, in;
