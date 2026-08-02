DEFINE TABLE OVERWRITE book SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE title ON book TYPE string
    ASSERT fn::is_id($value);

DEFINE FIELD OVERWRITE icon ON book TYPE string;

DEFINE FIELD OVERWRITE color ON book TYPE int
    DEFAULT $gray
    ASSERT fn::is_color($value);

DEFINE FIELD OVERWRITE tagIds ON book
    COMPUTED ->bears->tag;
