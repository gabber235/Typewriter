DEFINE TABLE OVERWRITE service_host SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE service_id ON service_host TYPE record<service>
    REFERENCE ON DELETE CASCADE;
DEFINE FIELD OVERWRITE revision ON service_host TYPE int
    DEFAULT 1
    ASSERT {
        IF $value <= 0 {
            THROW "service-host-revision-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE entrypoint ON service_host TYPE string
    VALUE string::uppercase($value)
    ASSERT {
        IF string::len(string::trim($value)) == 0 {
            THROW "service-host-entrypoint-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE can_host_realm ON service_host TYPE bool;
DEFINE FIELD OVERWRITE supported_engines ON service_host TYPE array<object>
    ASSERT fn::service::valid_supported_engines($value);
DEFINE FIELD OVERWRITE supported_engines.* ON service_host TYPE object
    ASSERT fn::service::valid_supported_engine($value);
DEFINE FIELD OVERWRITE supported_engines.*.engine_id ON service_host TYPE string;
DEFINE FIELD OVERWRITE supported_engines.*.supported_major_versions ON service_host TYPE array<int>;
DEFINE FIELD OVERWRITE supported_engines.*.supported_major_versions.* ON service_host TYPE int
    ASSERT {
        IF $value < 0 {
            THROW "supported-engine-major-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE topology_revision ON service_host TYPE object DEFAULT {
    desired: 0,
    applied: 0,
};
DEFINE FIELD OVERWRITE topology_revision.desired ON service_host TYPE int DEFAULT 0
    ASSERT {
        IF $value < 0 {
            THROW "service-host-topology-desired-revision-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE topology_revision.applied ON service_host TYPE int DEFAULT 0
    ASSERT {
        IF $value < 0 {
            THROW "service-host-topology-applied-revision-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE state ON service_host TYPE object DEFAULT {
    status: "OFFLINE",
    updated_at: time::now(),
};
DEFINE FIELD OVERWRITE state.status ON service_host
    TYPE "OFFLINE" | "RECONCILING" | "ACTIVE" | "FAILED" | "DRIFTED";
DEFINE FIELD OVERWRITE state.message ON service_host TYPE option<string>;
DEFINE FIELD OVERWRITE state.updated_at ON service_host TYPE datetime;

DEFINE INDEX OVERWRITE service_host_by_service ON service_host FIELDS service_id UNIQUE;

DEFINE TABLE OVERWRITE realm_instance SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE owner_host_id ON realm_instance TYPE record<service_host>
    REFERENCE ON DELETE CASCADE;
DEFINE FIELD OVERWRITE revision ON realm_instance TYPE int
    DEFAULT 1
    ASSERT {
        IF $value < 1 {
            THROW "realm-instance-revision-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE target_engine ON realm_instance TYPE object
    ASSERT fn::service::valid_engine_target($value);
DEFINE FIELD OVERWRITE target_engine.engine_id ON realm_instance TYPE string;
DEFINE FIELD OVERWRITE target_engine.major_version ON realm_instance TYPE int
    ASSERT {
        IF $value < 0 {
            THROW "engine-target-major-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE manifest_revision ON realm_instance TYPE object DEFAULT {
    desired: 1,
    applied: 0,
};
DEFINE FIELD OVERWRITE manifest_revision.desired ON realm_instance TYPE int
    DEFAULT 1
    ASSERT {
        IF $value < 1 {
            THROW "realm-manifest-desired-revision-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE manifest_revision.applied ON realm_instance TYPE int
    DEFAULT 0
    ASSERT {
        IF $value < 0 {
            THROW "realm-manifest-applied-revision-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE state ON realm_instance TYPE object DEFAULT {
    status: "ABSENT",
    updated_at: time::now(),
};
DEFINE FIELD OVERWRITE state.status ON realm_instance
    TYPE "ABSENT" | "STAGING" | "ACTIVE" | "QUIESCING" | "FAILED" | "ROLLED_BACK" | "DRIFTED";
DEFINE FIELD OVERWRITE state.active_artifact_version ON realm_instance TYPE option<string>
    ASSERT {
        IF $value = NONE {
            RETURN TRUE;
        };
        IF !string::is_semver($value) {
            THROW "realm-active-artifact-version-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE state.message ON realm_instance TYPE option<string>;
DEFINE FIELD OVERWRITE state.updated_at ON realm_instance TYPE datetime;

DEFINE INDEX OVERWRITE realm_instance_by_owner ON realm_instance FIELDS owner_host_id UNIQUE;

DEFINE TABLE OVERWRITE engine_instance SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE owner_host_id ON engine_instance TYPE record<service_host>
    REFERENCE ON DELETE CASCADE;
DEFINE FIELD OVERWRITE realm_id ON engine_instance TYPE record<realm_instance>
    REFERENCE ON DELETE REJECT;
DEFINE FIELD OVERWRITE revision ON engine_instance TYPE int
    DEFAULT 1
    ASSERT {
        IF $value < 1 {
            THROW "engine-instance-revision-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE target ON engine_instance TYPE object
    ASSERT fn::service::valid_engine_target($value);
DEFINE FIELD OVERWRITE target.engine_id ON engine_instance TYPE string;
DEFINE FIELD OVERWRITE target.major_version ON engine_instance TYPE int
    ASSERT {
        IF $value < 0 {
            THROW "engine-target-major-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE manifest_revision ON engine_instance TYPE object DEFAULT {
    desired: 1,
    applied: 0,
};
DEFINE FIELD OVERWRITE manifest_revision.desired ON engine_instance TYPE int DEFAULT 1 ASSERT {
    IF $value < 1 {
        THROW "engine-manifest-desired-revision-invalid-error"
    };
    RETURN TRUE;
};
DEFINE FIELD OVERWRITE manifest_revision.applied ON engine_instance TYPE int DEFAULT 0 ASSERT {
    IF $value < 0 {
        THROW "engine-manifest-applied-revision-invalid-error"
    };
    RETURN TRUE;
};
DEFINE FIELD OVERWRITE state ON engine_instance TYPE object DEFAULT {
    status: "ABSENT",
    updated_at: time::now(),
};
DEFINE FIELD OVERWRITE state.status ON engine_instance
    TYPE "ABSENT" | "STAGING" | "ACTIVE" | "QUIESCING" | "FAILED" | "ROLLED_BACK" | "DRIFTED";
DEFINE FIELD OVERWRITE state.active_artifact_version ON engine_instance TYPE option<string>
    ASSERT {
        IF $value = NONE {
            RETURN TRUE;
        };
        IF !string::is_semver($value) {
            THROW "engine-active-artifact-version-invalid-error"
        };
        RETURN TRUE;
    };
DEFINE FIELD OVERWRITE state.message ON engine_instance TYPE option<string>;
DEFINE FIELD OVERWRITE state.updated_at ON engine_instance TYPE datetime;

DEFINE INDEX OVERWRITE engine_instance_by_owner ON engine_instance FIELDS owner_host_id UNIQUE;
DEFINE INDEX OVERWRITE engine_instance_by_realm ON engine_instance FIELDS realm_id;
