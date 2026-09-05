DEFINE TABLE OVERWRITE tag SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON tag TYPE string
    ASSERT {
        IF !fn::is_id($value) {
            THROW "tag-name-invalid-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE color ON tag TYPE int
    DEFAULT $gray
    ASSERT fn::is_color($value);

DEFINE FIELD OVERWRITE placement ON tag
    TYPE { x: option<int>, y: option<int>, width: option<int>, height: option<int> }
    DEFAULT {};

DEFINE FIELD OVERWRITE placement.x ON tag TYPE int
    DEFAULT ALWAYS 0;

DEFINE FIELD OVERWRITE placement.y ON tag TYPE int
    DEFAULT ALWAYS 0;

DEFINE FIELD OVERWRITE placement.width ON tag TYPE int
    DEFAULT ALWAYS 3
    ASSERT {
        IF $value <= 0 {
            THROW "tag-width-invalid-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE placement.height ON tag TYPE int
    DEFAULT ALWAYS 1
    ASSERT {
        IF $value <= 0 {
            THROW "tag-height-invalid-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE parent_tags ON tag
    COMPUTED ->inherits->tag;
