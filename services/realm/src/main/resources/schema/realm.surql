-- ==============================================
-- Realm Database Schema
-- This file is the single source of truth.
-- Use DEFINE ... OVERWRITE for idempotency.
-- ==============================================

-- Internal: Patch tracking
DEFINE TABLE OVERWRITE _patch SCHEMAFULL TYPE NORMAL;
DEFINE FIELD OVERWRITE id ON _patch TYPE string;
DEFINE FIELD OVERWRITE applied_at ON _patch TYPE datetime DEFAULT time::now();

-- Book table
DEFINE TABLE OVERWRITE book SCHEMAFULL TYPE NORMAL;
DEFINE FIELD OVERWRITE title ON book TYPE string ASSERT string::matches($value, '^[a-z0-9_]*$');
DEFINE FIELD OVERWRITE icon ON book TYPE string;
-- Color stored as ARGB uint32 (default: neutral gray 0xFF9E9E9E = 4288585374)
DEFINE FIELD OVERWRITE color ON book TYPE int DEFAULT 4288585374 ASSERT $value >= 0 && $value <= 4294967295;
DEFINE FIELD OVERWRITE tagIds ON book VALUE <future> { (SELECT VALUE ->bears->tag FROM ONLY $this) };

-- Tag table
DEFINE TABLE OVERWRITE tag SCHEMAFULL TYPE NORMAL;
DEFINE FIELD OVERWRITE name ON tag TYPE string ASSERT string::matches($value, '^[a-z0-9_]*$');
-- Color stored as ARGB uint32 (default: neutral gray 0xFF9E9E9E = 4288585374)
DEFINE FIELD OVERWRITE color ON tag TYPE int DEFAULT 4288585374 ASSERT $value >= 0 && $value <= 4294967295;
DEFINE FIELD OVERWRITE placement ON tag TYPE { x: option<int>, y: option<int>, width: option<int>, height: option<int> } DEFAULT {};
DEFINE FIELD OVERWRITE placement.x ON tag TYPE int DEFAULT ALWAYS 0;
DEFINE FIELD OVERWRITE placement.y ON tag TYPE int DEFAULT ALWAYS 0;
DEFINE FIELD OVERWRITE placement.width ON tag TYPE int DEFAULT ALWAYS 3 ASSERT $value > 0;
DEFINE FIELD OVERWRITE placement.height ON tag TYPE int DEFAULT ALWAYS 1 ASSERT $value > 0;
DEFINE FIELD OVERWRITE parentIds ON tag VALUE <future> { (SELECT VALUE ->inherits->tag FROM ONLY $this) };

-- Tag Inherits Table
DEFINE TABLE OVERWRITE inherits SCHEMAFULL TYPE RELATION IN tag OUT tag ENFORCED;

-- Book Tags Table
DEFINE TABLE OVERWRITE bears SCHEMAFULL TYPE RELATION IN book OUT tag ENFORCED;

-- Page table
DEFINE TABLE OVERWRITE page SCHEMAFULL TYPE NORMAL;
DEFINE FIELD OVERWRITE name ON page TYPE string ASSERT string::matches($value, '^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$');
DEFINE FIELD OVERWRITE book_id ON page TYPE record<book>;
DEFINE FIELD OVERWRITE type ON page TYPE "sequence" | "scene" | "manifest" | "static" DEFAULT "sequence";
DEFINE FIELD OVERWRITE chapter ON page TYPE string DEFAULT "" ASSERT $value == "" || string::matches($value, '^[a-z0-9]([a-z0-9_.]*[a-z0-9])?$');
DEFINE FIELD OVERWRITE priority ON page TYPE int DEFAULT 0;
