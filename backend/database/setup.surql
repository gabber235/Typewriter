DEFINE TABLE OVERWRITE __entity SCHEMAFULL
	PERMISSIONS NONE;

DEFINE FIELD OVERWRITE ns ON __entity
	TYPE string;

DEFINE FIELD OVERWRITE key ON __entity
	TYPE string;

DEFINE FIELD OVERWRITE val ON __entity
	TYPE any;

DEFINE FIELD OVERWRITE updated_at ON __entity
	TYPE datetime
	DEFAULT time::now();

DEFINE INDEX OVERWRITE by_ns_key ON __entity
	FIELDS ns, key
	UNIQUE;

DEFINE TABLE OVERWRITE __rollout SCHEMAFULL
	PERMISSIONS NONE;

DEFINE FIELD OVERWRITE id ON __rollout
	TYPE string;

DEFINE FIELD OVERWRITE name ON __rollout
	TYPE string;

DEFINE FIELD OVERWRITE manifest_path ON __rollout
	TYPE string;

DEFINE FIELD OVERWRITE manifest_checksum ON __rollout
	TYPE string;

DEFINE FIELD OVERWRITE source_schema_hash ON __rollout
	TYPE string;

DEFINE FIELD OVERWRITE target_schema_hash ON __rollout
	TYPE string;

DEFINE FIELD OVERWRITE status ON __rollout
	TYPE string;

DEFINE FIELD OVERWRITE source_entities ON __rollout
	TYPE any;

DEFINE FIELD OVERWRITE target_entities ON __rollout
	TYPE any;

DEFINE FIELD OVERWRITE steps ON __rollout
	TYPE any
	DEFAULT [];

DEFINE FIELD OVERWRITE started_at ON __rollout
	TYPE datetime
	DEFAULT time::now();

DEFINE FIELD OVERWRITE completed_at ON __rollout
	TYPE option<datetime>;

DEFINE FIELD OVERWRITE updated_at ON __rollout
	TYPE datetime
	DEFAULT time::now();

DEFINE FIELD OVERWRITE last_error ON __rollout
	TYPE option<string>;

DEFINE INDEX OVERWRITE by_rollout_id ON __rollout
	FIELDS id
	UNIQUE;
