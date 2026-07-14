DEFINE TABLE OVERWRITE service SCHEMAFULL
    PERMISSIONS NONE;

DEFINE FIELD OVERWRITE name ON service TYPE string
    ASSERT fn::is_id($value);

DEFINE FIELD OVERWRITE roles ON service TYPE array<object>
    ASSERT fn::service::valid_roles($value);

DEFINE FIELD OVERWRITE roles.* ON service TYPE object
    ASSERT fn::service::valid_role($value);

DEFINE FIELD OVERWRITE roles.*.type ON service
    TYPE "engine" | "realm" | "custom";

DEFINE FIELD OVERWRITE roles.*.version ON service TYPE string
    ASSERT {
        IF string::len(string::trim($value)) < 1 {
            THROW "role-version-blank-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE roles.*.name ON service TYPE option<string>;

DEFINE FIELD OVERWRITE created_at ON service TYPE datetime
    DEFAULT time::now()
    READONLY
    VALUE $before OR time::now();

DEFINE FIELD OVERWRITE state ON service TYPE option<object>;
DEFINE FIELD OVERWRITE state.status ON service TYPE "ONLINE" | "OFFLINE";
DEFINE FIELD OVERWRITE state.last_seen ON service TYPE datetime;

DEFINE FIELD OVERWRITE organization ON service TYPE option<record<organization>>
    REFERENCE ON DELETE THEN {
        UPDATE $this SET runs_in = NONE, organization = NONE;
    }
    ASSERT {
        IF $value != NONE AND $this.registration != NONE {
            THROW "service-organization-registration-conflict-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE registration ON service TYPE option<object>
    ASSERT {
        IF $value != NONE AND $this.organization != NONE {
            THROW "service-organization-registration-conflict-error"
        };
        RETURN true;
    };

DEFINE FIELD OVERWRITE registration.token ON service TYPE string
    ASSERT {
        IF string::matches($value, '^[A-Z0-9]{10}$') {
            RETURN true
        };
        THROW "registration-token-invalid-error"
    };

DEFINE FIELD OVERWRITE registration.expires_at ON service TYPE datetime;

DEFINE FIELD OVERWRITE runs_in ON service TYPE option<record<service>>
    REFERENCE ON DELETE UNSET
    ASSERT fn::service::valid_runs_in($this, $value);

DEFINE INDEX OVERWRITE service_by_organization ON service FIELDS organization;
DEFINE INDEX OVERWRITE service_registration_token ON service FIELDS registration.token UNIQUE;

DEFINE EVENT OVERWRITE guard_service_state ON service WHEN $event IN ["CREATE", "UPDATE"] THEN {
    RETURN fn::service::valid_state($after);
};
