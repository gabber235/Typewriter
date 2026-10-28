-- Records the supplied child observations for the current topology revision, derives the host
-- status, and advances the applied revision only when every assigned child reported active.
BEGIN TRANSACTION;

RETURN {
    LET $hosts = SELECT * FROM service_host WHERE service_id = $service_id;
    IF array::is_empty($hosts) {
        RETURN { outcome: 'host-not-found' }
    };
    LET $host = array::first($hosts);
    LET $host_id = $host.id;
    IF $host.topology_revision.desired != $topology_revision {
        RETURN { outcome: 'stale-revision' }
    };
    LET $realm = array::first(SELECT * FROM realm_instance WHERE owner_host_id = $host_id);
    LET $engine = array::first(SELECT * FROM engine_instance WHERE owner_host_id = $host_id);
    IF $realm_state != NONE AND $realm_state != NULL {
        UPDATE realm_instance SET
            state = {
                status: $realm_state.status,
                active_artifact_version: IF $realm_state.active_artifact_version = NULL {
                    NONE
                } ELSE {
                    $realm_state.active_artifact_version
                },
                message: IF $realm_state.message = NULL {
                    NONE
                } ELSE {
                    $realm_state.message
                },
                updated_at: <datetime>$realm_state.updated_at,
            }
        WHERE owner_host_id = $host_id
    };
    IF $engine_state != NONE AND $engine_state != NULL {
        UPDATE engine_instance SET
            state = {
                status: $engine_state.status,
                active_artifact_version: IF $engine_state.active_artifact_version = NULL {
                    NONE
                } ELSE {
                    $engine_state.active_artifact_version
                },
                message: IF $engine_state.message = NULL {
                    NONE
                } ELSE {
                    $engine_state.message
                },
                updated_at: <datetime>$engine_state.updated_at,
            }
        WHERE owner_host_id = $host_id
    };
    LET $complete = (
        $realm = NONE
        OR ($realm_state != NONE AND $realm_state != NULL AND $realm_state.status = 'active')
    ) AND (
        $engine = NONE
        OR ($engine_state != NONE AND $engine_state != NULL AND $engine_state.status = 'active')
    );
    LET $failed = (
        $realm_state != NONE AND $realm_state != NULL AND $realm_state.status = 'failed'
    ) OR (
        $engine_state != NONE AND $engine_state != NULL AND $engine_state.status = 'failed'
    );
    LET $drifted = (
        $realm_state != NONE
        AND $realm_state != NULL
        AND $realm_state.status IN ['rolled_back', 'drifted']
    ) OR (
        $engine_state != NONE
        AND $engine_state != NULL
        AND $engine_state.status IN ['rolled_back', 'drifted']
    );
    LET $host_status = IF $complete {
        'active'
    } ELSE IF $failed {
        'failed'
    } ELSE IF $drifted {
        'drifted'
    } ELSE {
        'reconciling'
    };
    LET $updated_host = UPDATE ONLY $host_id SET
        topology_revision.applied = IF $complete {
            $topology_revision
        } ELSE {
            topology_revision.applied
        },
        state = { status: $host_status, updated_at: time::now() }
    RETURN AFTER;
    RETURN {
        outcome: 'updated',
        organization_id: $host.service_id.organization,
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
    };
};

COMMIT TRANSACTION;
