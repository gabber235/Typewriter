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
DEFINE FIELD OVERWRITE title ON book TYPE string;
DEFINE FIELD OVERWRITE icon ON book TYPE string;
-- Color stored as ARGB uint32 (default: neutral gray 0xFF9E9E9E = 4288585374)
DEFINE FIELD OVERWRITE color ON book TYPE int DEFAULT 4288585374 ASSERT $value >= 0 && $value <= 4294967295;
DEFINE FIELD OVERWRITE tags ON book VALUE <future> { (SELECT VALUE ->bears->tag FROM ONLY $this FETCH tag) };

-- Tag table
DEFINE TABLE OVERWRITE tag SCHEMAFULL TYPE NORMAL;
DEFINE FIELD OVERWRITE name ON tag TYPE string;
-- Color stored as ARGB uint32 (default: neutral gray 0xFF9E9E9E = 4288585374)
DEFINE FIELD OVERWRITE color ON tag TYPE int DEFAULT 4288585374 ASSERT $value >= 0 && $value <= 4294967295;
DEFINE FIELD OVERWRITE placement ON tag TYPE { x: int, y: int, width: int, height: int } DEFAULT { x: 0, y: 0, width: 3, height: 1 };
DEFINE FIELD OVERWRITE parents ON tag VALUE <future> { (SELECT VALUE ->inherits->tag FROM ONLY $this FETCH tag) };

-- Tag Inherits Table
DEFINE TABLE OVERWRITE inherits SCHEMAFULL TYPE RELATION IN tag OUT tag ENFORCED;

-- Book Tags Table
DEFINE TABLE OVERWRITE bears SCHEMAFULL TYPE RELATION IN book OUT tag ENFORCED;

-- Page table
DEFINE TABLE OVERWRITE page SCHEMAFULL TYPE NORMAL;
DEFINE FIELD OVERWRITE name ON page TYPE string;
DEFINE FIELD OVERWRITE book_id ON page TYPE record<book>;
DEFINE FIELD OVERWRITE type ON page TYPE "sequence" | "scene" | "manifest" | "static" DEFAULT "sequence";
DEFINE FIELD OVERWRITE chapter ON page TYPE string DEFAULT "";
DEFINE FIELD OVERWRITE priority ON page TYPE int DEFAULT 0;
