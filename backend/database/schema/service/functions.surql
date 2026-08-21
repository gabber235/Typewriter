DEFINE FUNCTION OVERWRITE fn::service::valid_role($role: object) -> bool {
    IF !array::all(object::keys($role), |$key| $key IN ["type", "version", "name"]) {
        THROW "role-unknown-property-error"
    };

    IF $role.type NOT IN ["host", "custom"] {
        THROW "role-type-invalid-error"
    };

    IF $role.version = NONE OR !string::is_semver($role.version) {
        THROW "role-version-invalid-error"
    };

    IF $role.type = "custom" {
        IF $role.name = NONE {
            THROW "custom-role-name-required-error"
        };
        IF !fn::is_id($role.name) {
            THROW "custom-role-name-invalid-error"
        };
        IF $role.name IN ["host"] {
            THROW "builtin-role-name-forbidden-error"
        };
        RETURN true;
    };

    IF $role.name != NONE {
        THROW "builtin-role-name-forbidden-error"
    };

    RETURN true;
};

DEFINE FUNCTION OVERWRITE fn::service::valid_state($service: object) -> bool {
    fn::service::valid_role($service.role);
    IF $service.organization != NONE AND $service.registration != NONE {
        THROW "service-organization-registration-conflict"
    };
    RETURN true;
};

DEFINE FUNCTION OVERWRITE fn::service::valid_engine_target($target: object) -> bool {
    IF !array::all(object::keys($target), |$key| $key IN ["engine_id", "major_version"]) {
        THROW "engine-target-unknown-property-error"
    };
    IF !fn::is_id($target.engine_id) {
        THROW "engine-target-id-invalid-error"
    };
    IF $target.major_version < 0 {
        THROW "engine-target-major-invalid-error"
    };
    RETURN true;
};

DEFINE FUNCTION OVERWRITE fn::service::valid_supported_engine($engine: object) -> bool {
    IF !array::all(object::keys($engine), |$key| $key IN ["engine_id", "supported_major_versions"]) {
        THROW "supported-engine-unknown-property-error"
    };
    IF !fn::is_id($engine.engine_id) {
        THROW "supported-engine-id-invalid-error"
    };
    IF array::is_empty($engine.supported_major_versions) {
        THROW "supported-engine-versions-required-error"
    };
    IF array::len(array::distinct($engine.supported_major_versions)) != array::len($engine.supported_major_versions) {
        THROW "supported-engine-version-duplicate-error"
    };
    IF !array::all($engine.supported_major_versions, |$major| $major >= 0) {
        THROW "supported-engine-major-invalid-error"
    };
    RETURN true;
};

DEFINE FUNCTION OVERWRITE fn::service::valid_supported_engines($engines: array<object>) -> bool {
    IF !array::all($engines, |$engine| fn::service::valid_supported_engine($engine)) {
        THROW "supported-engine-invalid-error"
    };
    LET $ids = $engines.map(|$engine| $engine.engine_id);
    IF array::len(array::distinct($ids)) != array::len($ids) {
        THROW "supported-engine-duplicate-error"
    };
    RETURN true;
};
