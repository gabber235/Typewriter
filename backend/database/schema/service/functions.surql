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

DEFINE FUNCTION OVERWRITE fn::service::engine_target_error($target: object) -> option<string> {
    IF !array::all(object::keys($target), |$key| $key IN ["engine_id", "version_constraint"]) {
        RETURN "engine-target-unknown-property-error"
    };
    IF !fn::is_artifact_id($target.engine_id) { RETURN "engine-target-id-invalid-error" };
    IF string::len(string::trim($target.version_constraint)) = 0 {
        RETURN "engine-target-version-constraint-invalid-error"
    };
    RETURN NONE;
};

DEFINE FUNCTION OVERWRITE fn::service::valid_engine_target($target: object) -> bool {
    LET $error = fn::service::engine_target_error($target);
    IF $error != NONE { THROW $error };
    RETURN true;
};

DEFINE FUNCTION OVERWRITE fn::service::valid_supported_engine($engine: object) -> bool {
    IF !array::all(object::keys($engine), |$key| $key IN ["engine_id"]) {
        THROW "supported-engine-unknown-property-error"
    };
    IF !fn::is_artifact_id($engine.engine_id) {
        THROW "supported-engine-id-invalid-error"
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

DEFINE FUNCTION OVERWRITE fn::service::realm_view($realm: object) -> object {
    RETURN {
        id: $realm.id,
        revision: $realm.revision,
        target_engine: $realm.target_engine,
        state: $realm.state,
        owner_host: {
            id: $realm.owner_host_id,
            name: $realm.owner_host_id.service_id.name,
        },
    };
};

DEFINE FUNCTION OVERWRITE fn::service::engine_view($engine: object) -> object {
    RETURN {
        id: $engine.id,
        revision: $engine.revision,
        target: $engine.target,
        state: $engine.state,
        owner_host: {
            id: $engine.owner_host_id,
            name: $engine.owner_host_id.service_id.name,
        },
        realm: {
            realm_id: $engine.realm_id,
            owner_host: {
                id: $engine.realm_id.owner_host_id,
                name: $engine.realm_id.owner_host_id.service_id.name,
            },
        },
    };
};

DEFINE FUNCTION OVERWRITE fn::service::configure_host(
    $host_id: record<service_host>,
    $organization_id: record<organization>,
    $expected_revision: int,
    $desired: object
) -> object {
    LET $has_realm = $desired.realm != NONE AND $desired.realm != NULL;
    LET $has_engine = $desired.primary_engine != NONE AND $desired.primary_engine != NULL;
    LET $realm_target = $desired.realm.primary_engine;
    LET $engine_target = $desired.primary_engine.target;
    LET $uses_hosted_realm = $has_engine AND $desired.primary_engine.realm.kind = 'hosted_realm';
    LET $existing_realm_id = IF $has_engine AND !$uses_hosted_realm {
        $desired.primary_engine.realm.realm_id
    } ELSE { NONE };
    IF $has_realm AND fn::service::engine_target_error($realm_target) != NONE {
        RETURN { outcome: 'invalid-configuration-error', message: 'Realm target is invalid' }
    };
    IF $has_engine AND fn::service::engine_target_error($engine_target) != NONE {
        RETURN { outcome: 'invalid-configuration-error', message: 'Engine target is invalid' }
    };
    IF $uses_hosted_realm AND !$has_realm {
        RETURN {
            outcome: 'invalid-configuration-error',
            message: 'A hosted engine requires a hosted Realm configuration',
        }
    };
    LET $hosts = SELECT * FROM $host_id
        WHERE service_id.organization = $organization_id;
    IF array::is_empty($hosts) {
        RETURN {
            outcome: 'invalid-configuration-error',
            message: 'Host was not found in this organization',
        }
    };
    LET $host = array::first($hosts);
    IF $host.revision != $expected_revision {
        RETURN {
            outcome: 'conflict-error',
            host: $host,
            realm: array::first(
                (SELECT * FROM realm_instance
                    WHERE owner_host_id = $host_id)
                    .map(|$row| fn::service::realm_view($row))
            ),
            engine: array::first(
                (SELECT * FROM engine_instance
                    WHERE owner_host_id = $host_id)
                    .map(|$row| fn::service::engine_view($row))
            ),
        }
    };
    IF $has_realm AND !$host.can_host_realm {
        RETURN {
            outcome: 'invalid-configuration-error',
            message: 'Host cannot run a Realm',
        }
    };
    IF $has_engine AND !array::any(
        $host.supported_engines,
        |$supported| $supported.engine_id = $engine_target.engine_id,
    ) {
        RETURN { outcome: 'incompatible-engine-error', target: $engine_target }
    };

    LET $current_realm = array::first(SELECT * FROM realm_instance WHERE owner_host_id = $host_id);
    LET $current_engine = array::first(SELECT * FROM engine_instance WHERE owner_host_id = $host_id);

    LET $external_realm = IF $has_engine AND !$uses_hosted_realm {
        array::first(
            SELECT * FROM $existing_realm_id
            WHERE owner_host_id.service_id.organization = $organization_id
        )
    } ELSE {
        NONE
    };
    IF $has_engine AND !$uses_hosted_realm AND $external_realm = NONE {
        RETURN { outcome: 'realm-not-found-error', realm_id: $existing_realm_id }
    };
    LET $assigned_target = IF $uses_hosted_realm {
        $realm_target
    } ELSE {
        $external_realm.target_engine
    };
    IF $has_engine AND $assigned_target != $engine_target {
        RETURN { outcome: 'incompatible-engine-error', target: $engine_target }
    };
    IF !$has_realm AND $current_realm != NONE {
        LET $dependents = SELECT id FROM engine_instance
            WHERE realm_id = $current_realm.id
            AND (id != $current_engine.id OR ($has_engine AND $existing_realm_id = $current_realm.id));
        IF !array::is_empty($dependents) {
            RETURN {
                outcome: 'invalid-configuration-error',
                message: 'Realm is still assigned to an execution engine',
            }
        };
    };

    LET $realm = IF $has_realm {
        IF $current_realm = NONE {
            CREATE ONLY realm_instance SET
                owner_host_id = $host_id,
                target_engine = $realm_target
        } ELSE IF $current_realm.target_engine != $realm_target {
            UPDATE ONLY $current_realm.id SET
                target_engine = $realm_target,
                revision += 1,
                state = { status: 'STAGING', updated_at: time::now() }
        } ELSE {
            $current_realm
        }
    } ELSE {
        NONE
    };

    LET $assigned_realm = IF $uses_hosted_realm { $realm } ELSE { $external_realm };

    LET $engine = IF $has_engine {
        IF $current_engine = NONE {
            CREATE ONLY engine_instance SET
                owner_host_id = $host_id,
                realm_id = $assigned_realm.id,
                target = $engine_target
        } ELSE IF $current_engine.target != $engine_target
            OR $current_engine.realm_id != $assigned_realm.id {
            UPDATE ONLY $current_engine.id SET
                realm_id = $assigned_realm.id,
                target = $engine_target,
                revision += 1,
                state = { status: 'STAGING', updated_at: time::now() }
        } ELSE {
            $current_engine
        }
    } ELSE {
        NONE
    };

    LET $removed_engine = IF !$has_engine AND $current_engine != NONE {
        $current_engine.id
    } ELSE {
        NONE
    };
    IF $removed_engine != NONE {
        DELETE $removed_engine
    };

    LET $removed_realm = IF !$has_realm AND $current_realm != NONE {
        $current_realm.id
    } ELSE {
        NONE
    };
    IF $removed_realm != NONE {
        DELETE $removed_realm
    };

    LET $updated_host = UPDATE ONLY $host_id SET
        revision += 1,
        topology_revision.desired += 1,
        state = { status: 'RECONCILING', updated_at: time::now() }
    RETURN AFTER;

    LET $result = {
        outcome: 'configured',
        host: $updated_host,
        realm: array::first(
            (SELECT * FROM realm_instance
                WHERE owner_host_id = $host_id)
                .map(|$row| fn::service::realm_view($row))
        ),
        engine: array::first(
            (SELECT * FROM engine_instance
                WHERE owner_host_id = $host_id)
                .map(|$row| fn::service::engine_view($row))
        ),
        removed_realm: $removed_realm,
        removed_engine: $removed_engine,
    };
    RETURN $result;
} PERMISSIONS NONE;
