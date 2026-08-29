DEFINE TABLE OVERWRITE contains_element SCHEMAFULL
    TYPE RELATION FROM page TO element ENFORCED
    PERMISSIONS NONE;

DEFINE INDEX OVERWRITE contains_element_unique_element
    ON contains_element FIELDS out UNIQUE;
