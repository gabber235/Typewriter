DEFINE TABLE OVERWRITE tag SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON tag TYPE string
    ASSERT fn::is_id($value);

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
    ASSERT $value > 0;

DEFINE FIELD OVERWRITE placement.height ON tag TYPE int
    DEFAULT ALWAYS 1
    ASSERT $value > 0;

DEFINE FIELD OVERWRITE parentIds ON tag
    COMPUTED ->inherits->tag;
