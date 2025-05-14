USE NAMESPACE typewriter;
USE DATABASE develop;
-- ------------------------------
-- OPTION
-- ------------------------------

OPTION IMPORT;

-- ------------------------------
-- TABLE: user
-- ------------------------------

DEFINE TABLE user TYPE ANY SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE avatar ON user TYPE option<string>;
DEFINE FIELD OVERWRITE name ON user TYPE option<string>;
DEFINE FIELD OVERWRITE email ON user TYPE option<string> ASSERT string::is::email($value);
DEFINE FIELD OVERWRITE phone ON user TYPE option<string>;
DEFINE FIELD OVERWRITE created_at ON user TYPE datetime DEFAULT time::now() VALUE $before OR time::now() READONLY;
DEFINE FIELD OVERWRITE last_login ON user TYPE datetime DEFAULT time::now();



-- ------------------------------
-- TABLE DATA: user
-- ------------------------------


