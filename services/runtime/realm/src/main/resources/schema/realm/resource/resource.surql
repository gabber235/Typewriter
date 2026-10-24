DEFINE TABLE OVERWRITE resource SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE content ON resource TYPE object FLEXIBLE;

DEFINE FIELD OVERWRITE search ON resource TYPE option<object> FLEXIBLE;
DEFINE FIELD OVERWRITE search.text ON resource TYPE string;

DEFINE INDEX OVERWRITE resource_text ON resource FIELDS search.text FULLTEXT ANALYZER authoring_text BM25;
DEFINE INDEX OVERWRITE resource_approximate ON resource FIELDS search.text FULLTEXT ANALYZER authoring_approximate BM25;
