-- ==============================================
-- Realm Database Schema
-- This file is the single source of truth.
-- Use DEFINE ... OVERWRITE for idempotency.
-- ==============================================

-- Internal: Patch tracking
DEFINE TABLE OVERWRITE _patches TYPE NORMAL SCHEMAFULL;
DEFINE FIELD OVERWRITE id ON _patches TYPE string;
DEFINE FIELD OVERWRITE applied_at ON _patches TYPE datetime DEFAULT time::now();
DEFINE INDEX OVERWRITE _patches_id ON _patches FIELDS id UNIQUE;

-- Add your tables below...
