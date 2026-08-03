DEFINE TABLE OVERWRITE page SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON page TYPE string
    ASSERT {
        IF !fn::is_id($value) {
            THROW "page-name-invalid-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE book ON page TYPE record<book> REFERENCE
    ASSERT {
        IF !record::exists($value) {
            THROW "book-not-found-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE type ON page
    TYPE "sequence" | "scene" | "manifest" | "static"
    DEFAULT "sequence";

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
