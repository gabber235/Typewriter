DEFINE TABLE OVERWRITE compile_attempt SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE source_revision ON compile_attempt TYPE string;
DEFINE FIELD OVERWRITE catalog_revision ON compile_attempt TYPE string;
DEFINE FIELD OVERWRITE compiler_format ON compile_attempt TYPE int;
DEFINE FIELD OVERWRITE status ON compile_attempt TYPE "success" | "blocked";
DEFINE FIELD OVERWRITE diagnostics ON compile_attempt TYPE string;
DEFINE FIELD OVERWRITE artifact_manifest ON compile_attempt TYPE option<record<compiled_artifact_manifest>>;
DEFINE FIELD OVERWRITE started_at ON compile_attempt TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE completed_at ON compile_attempt TYPE datetime DEFAULT time::now();
