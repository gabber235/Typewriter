-- ------------------------------
-- OPTION
-- ------------------------------
USE NAMESPACE typewriter;
USE DATABASE develop;

OPTION IMPORT;

-- ------------------------------
-- TABLE: member_of
-- ------------------------------

DEFINE TABLE OVERWRITE member_of TYPE RELATION IN user OUT organization ENFORCED SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE in ON member_of TYPE record<user> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE out ON member_of TYPE record<organization> PERMISSIONS NONE;



-- ------------------------------
-- TABLE DATA: member_of
-- ------------------------------


-- ------------------------------
-- TABLE: organization
-- ------------------------------

DEFINE TABLE OVERWRITE organization TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON organization TYPE string ASSERT string::matches($value, '^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$') PERMISSIONS NONE;



-- ------------------------------
-- TABLE DATA: organization
-- ------------------------------


-- ------------------------------
-- TABLE: user
-- ------------------------------

DEFINE TABLE OVERWRITE user TYPE ANY SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD OVERWRITE avatar ON user TYPE option<string> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON user TYPE datetime DEFAULT time::now() READONLY VALUE $before OR time::now() PERMISSIONS NONE;
DEFINE FIELD OVERWRITE email ON user TYPE option<string> ASSERT string::is::email($value) PERMISSIONS NONE;
DEFINE FIELD OVERWRITE last_login ON user TYPE datetime DEFAULT time::now() PERMISSIONS NONE;
DEFINE FIELD OVERWRITE name ON user TYPE option<string> PERMISSIONS NONE;
DEFINE FIELD OVERWRITE phone ON user TYPE option<string> PERMISSIONS NONE;



-- ------------------------------
-- TABLE DATA: user
-- ------------------------------

INSERT [ { avatar: 'https://cdn.discordapp.com/avatars/153829638676676608/120ddf4ebb360c0c9dba5c9c266ad9af', created_at: d'2025-05-13T05:35:47.408778668Z', email: 'gabber200@icloud.com', id: user:54svy3xum2ia, last_login: d'2025-05-13T05:37:43.583079014Z', name: 'gabber235' } ];

