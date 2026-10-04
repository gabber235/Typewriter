DEFINE TABLE OVERWRITE publication_attempt SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE capture ON publication_attempt TYPE string;
DEFINE FIELD OVERWRITE catalog ON publication_attempt TYPE string;
DEFINE FIELD OVERWRITE engine_token ON publication_attempt TYPE string;
DEFINE FIELD OVERWRITE engine_inputs ON publication_attempt TYPE string;
DEFINE FIELD OVERWRITE state ON publication_attempt TYPE "checking" | "compiling" | "activating" | "complete" | "blocked" | "interrupted";
DEFINE FIELD OVERWRITE active ON publication_attempt TYPE bool;
DEFINE FIELD OVERWRITE findings ON publication_attempt TYPE option<string>;
DEFINE FIELD OVERWRITE started_at ON publication_attempt TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE updated_at ON publication_attempt TYPE datetime DEFAULT time::now();

DEFINE TABLE OVERWRITE publication_slot SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE owner ON publication_slot TYPE option<string>;

UPSERT ONLY publication_slot:current SET owner = owner OR NONE;
