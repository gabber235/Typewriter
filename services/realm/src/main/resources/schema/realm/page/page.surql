DEFINE TABLE OVERWRITE page SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE revision ON page TYPE int
    DEFAULT 1
    ASSERT $value >= 1;

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
