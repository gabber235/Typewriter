DEFINE TABLE OVERWRITE book SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE title ON book TYPE string
    ASSERT {
        IF !fn::is_id($value) {
            THROW "book-title-invalid-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE icon ON book TYPE string
    ASSERT {
        IF string::trim($value) == "" {
            THROW "book-icon-required-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE color ON book TYPE int
    DEFAULT $gray
    ASSERT {
        IF !fn::is_color($value) {
            THROW "book-color-invalid-error"
        };
        RETURN true;
    };

DEFINE INDEX OVERWRITE book_title_search ON book
    FIELDS title FULLTEXT ANALYZER authoring_text BM25 HIGHLIGHTS;
DEFINE INDEX OVERWRITE book_title_prefix ON book
    FIELDS title FULLTEXT ANALYZER authoring_prefix BM25 HIGHLIGHTS;
DEFINE INDEX OVERWRITE book_title_approximate ON book
    FIELDS title FULLTEXT ANALYZER authoring_approximate BM25 HIGHLIGHTS;
