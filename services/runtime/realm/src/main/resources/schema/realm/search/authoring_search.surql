DEFINE TABLE OVERWRITE authoring_search SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE resource ON authoring_search TYPE record<resource>;
DEFINE FIELD OVERWRITE definition ON authoring_search TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE root ON authoring_search TYPE object FLEXIBLE;
DEFINE FIELD OVERWRITE text ON authoring_search TYPE string;
DEFINE FIELD OVERWRITE owner_path ON authoring_search TYPE array<string>;

DEFINE INDEX OVERWRITE authoring_search_resource
    ON authoring_search FIELDS resource UNIQUE;
DEFINE INDEX OVERWRITE authoring_search_definition
    ON authoring_search FIELDS definition;
DEFINE INDEX OVERWRITE authoring_search_text
    ON authoring_search FIELDS text FULLTEXT ANALYZER authoring_text BM25;
DEFINE INDEX OVERWRITE authoring_search_approximate
    ON authoring_search FIELDS text FULLTEXT ANALYZER authoring_approximate BM25;

DEFINE TABLE OVERWRITE authoring_search_selector SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE resource ON authoring_search_selector TYPE record<resource>;
DEFINE FIELD OVERWRITE facet ON authoring_search_selector TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE normalized ON authoring_search_selector TYPE string
    ASSERT string::trim($value) != "";
DEFINE FIELD OVERWRITE display ON authoring_search_selector TYPE string;

DEFINE INDEX OVERWRITE authoring_selector_resource
    ON authoring_search_selector FIELDS resource;
DEFINE INDEX OVERWRITE authoring_selector_value
    ON authoring_search_selector FIELDS facet, normalized;
