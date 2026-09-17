DEFINE TABLE OVERWRITE page SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON page TYPE string
    ASSERT {
        IF !fn::is_id($value) {
            THROW "page-name-invalid-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE book ON page
    COMPUTED array::first(<-contains_page<-book);

DEFINE FIELD OVERWRITE kind ON page
    TYPE { id: string, revision: int };

DEFINE FIELD OVERWRITE kind.id ON page TYPE string;

DEFINE FIELD OVERWRITE kind.revision ON page TYPE int
    ASSERT $value > 0;

DEFINE FIELD OVERWRITE chapter ON page TYPE string
    DEFAULT ""
    ASSERT {
        IF $value == "" {
            RETURN true;
        };

        IF !string::matches($value, '^[a-z0-9]([a-z0-9_.]*[a-z0-9])?$') {
            THROW "page-chapter-invalid-error"
        };

        RETURN true;
    };

DEFINE FIELD OVERWRITE priority ON page TYPE int
    DEFAULT 0;

DEFINE INDEX OVERWRITE page_name_search ON page
    FIELDS name FULLTEXT ANALYZER authoring_text BM25 HIGHLIGHTS;
DEFINE INDEX OVERWRITE page_name_prefix ON page
    FIELDS name FULLTEXT ANALYZER authoring_prefix BM25 HIGHLIGHTS;
DEFINE INDEX OVERWRITE page_name_approximate ON page
    FIELDS name FULLTEXT ANALYZER authoring_approximate BM25 HIGHLIGHTS;
