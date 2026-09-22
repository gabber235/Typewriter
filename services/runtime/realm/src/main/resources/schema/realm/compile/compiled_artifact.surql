DEFINE TABLE OVERWRITE compiled_artifact SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE projection ON compiled_artifact TYPE string;
DEFINE FIELD OVERWRITE root ON compiled_artifact TYPE record<resource>;
DEFINE FIELD OVERWRITE format_revision ON compiled_artifact TYPE int;
DEFINE FIELD OVERWRITE media_type ON compiled_artifact TYPE string;
DEFINE FIELD OVERWRITE input_fingerprint ON compiled_artifact TYPE string
    ASSERT string::len($value) = 64;
DEFINE FIELD OVERWRITE semantic_digest ON compiled_artifact TYPE string
    ASSERT string::len($value) = 64;
DEFINE FIELD OVERWRITE payload ON compiled_artifact TYPE string;

DEFINE INDEX OVERWRITE compiled_artifact_input
    ON compiled_artifact FIELDS projection, root, input_fingerprint UNIQUE;
DEFINE INDEX OVERWRITE compiled_artifact_root
    ON compiled_artifact FIELDS projection, root;

DEFINE TABLE OVERWRITE compiled_artifact_manifest SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE source_revision ON compiled_artifact_manifest TYPE string;
DEFINE FIELD OVERWRITE catalog_revision ON compiled_artifact_manifest TYPE string;
DEFINE FIELD OVERWRITE artifacts ON compiled_artifact_manifest TYPE array<record<compiled_artifact>>;
DEFINE FIELD OVERWRITE payload ON compiled_artifact_manifest TYPE string;
