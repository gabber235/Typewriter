DEFINE FUNCTION OVERWRITE fn::service::valid_role($role: object) -> bool {
    IF !array::all(object::keys($role), |$key| $key IN ["type", "version", "name"]) {
        THROW "role-unknown-property-error"
    };

    IF $role.type NOT IN ["engine", "realm", "custom"] {
        THROW "role-type-invalid-error"
    };

    IF $role.version = NONE OR string::len(string::trim($role.version)) < 1 {
        THROW "role-version-blank-error"
    };

    IF $role.type = "custom" {
        IF $role.name = NONE {
            THROW "custom-role-name-required-error"
        };
        IF !fn::is_id($role.name) {
            THROW "custom-role-name-invalid-error"
        };
        RETURN true;
    };

    IF $role.name != NONE {
        THROW "builtin-role-name-forbidden-error"
    };

    RETURN true;
};

DEFINE FUNCTION OVERWRITE fn::service::valid_roles($roles: array<object>) -> bool {
    IF array::len($roles) < 1 {
        THROW "roles-required-error"
    };

    IF !array::all($roles, |$role| fn::service::valid_role($role)) {
        THROW "role-invalid-error"
    };

    LET $engines = $roles.filter(|$role| $role.type = "engine");
    LET $realms = $roles.filter(|$role| $role.type = "realm");
    LET $custom = $roles.filter(|$role| $role.type = "custom");

    IF array::len($engines) > 1 {
        THROW "engine-role-duplicate-error"
    };

    IF array::len($realms) > 1 {
        THROW "realm-role-duplicate-error"
    };

    LET $custom_slugs = $custom.map(|$role| $role.name);
    IF array::len(array::distinct($custom_slugs)) != array::len($custom_slugs) {
        THROW "custom-role-duplicate-error"
    };

    RETURN true;
};

DEFINE FUNCTION OVERWRITE fn::service::has_role($service: object, $role_type: string) -> bool {
    RETURN array::any($service.roles, |$role| $role.type = $role_type);
};

DEFINE FUNCTION OVERWRITE fn::service::valid_runs_in($service: object, $realm: option<record<service>>) -> bool {
    IF $realm == NONE { RETURN true };

    LET $can_run_in = fn::service::has_role($service, "engine") OR fn::service::has_role($service, "custom");
    IF !$can_run_in {
        THROW "runs-in-requires-engine-or-custom-role"
    };

    IF !fn::service::has_role({ roles: $realm.roles }, "realm") {
        THROW "runs-in-must-reference-realm-role"
    };

    LET $service_org = $service.organization;
    LET $realm_org = $realm.organization;

    IF $service_org == NONE AND $realm_org == NONE { RETURN true };
    IF $service_org != NONE AND $realm_org != NONE AND $service_org = $realm_org { RETURN true };

    THROW "runs-in-organization-mismatch";
};

DEFINE FUNCTION OVERWRITE fn::service::valid_state($service: object) -> bool {
    fn::service::valid_roles($service.roles);
    IF $service.organization != NONE AND $service.registration != NONE {
        THROW "service-organization-registration-conflict"
    };
    RETURN fn::service::valid_runs_in($service, $service.runs_in);
};
