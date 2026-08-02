DEFINE TABLE OVERWRITE _patch SCHEMAFULL TYPE NORMAL;
DEFINE FIELD OVERWRITE checksum ON _patch TYPE string
    ASSERT string::matches($value, '^[a-f0-9]{64}$');
DEFINE FIELD OVERWRITE applied_at ON _patch TYPE datetime DEFAULT time::now();
