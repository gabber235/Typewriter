DEFINE TABLE OVERWRITE page SCHEMAFULL TYPE NORMAL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON page TYPE string
    ASSERT fn::is_id($value);

DEFINE FIELD OVERWRITE book_id ON page TYPE record<book>;

DEFINE FIELD OVERWRITE type ON page
    TYPE "sequence" | "scene" | "manifest" | "static"
    DEFAULT "sequence";

DEFINE FIELD OVERWRITE chapter ON page TYPE string
    DEFAULT ""
    ASSERT $value == "" OR string::matches($value, '^[a-z0-9]([a-z0-9_.]*[a-z0-9])?$');

DEFINE FIELD OVERWRITE priority ON page TYPE int
    DEFAULT 0;
