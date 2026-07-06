DEFINE FUNCTION OVERWRITE fn::service::valid_runs_in($service: object, $realm: option<record<service>>) -> bool {
    IF $realm == NONE { RETURN true };

    IF !("engine" IN $service.service_types) {
        THROW "Only services with engine type can have runs_in set"
    };

    IF !("realm" IN $realm.service_types) {
        THROW "runs_in must reference a service with realm type"
    };

    LET $service_org = $service.organization;
    LET $realm_org = $realm.organization;

    IF $service_org == NONE AND $realm_org == NONE { RETURN true };
    IF $service_org != NONE AND $realm_org != NONE AND $service_org = $realm_org { RETURN true };

    THROW "runs_in requires both services to be unbound or bound to the same organization";
};

DEFINE FUNCTION OVERWRITE fn::service::valid_state($service: object) -> bool {
    IF array::len($service.service_types) < 1 { THROW "Service must have at least one type" };
    IF array::len(array::distinct($service.service_types)) != array::len($service.service_types) {
        THROW "Service types must be unique"
    };
    IF $service.organization != NONE AND $service.registration != NONE {
        THROW "Service cannot have both organization and registration set"
    };
    RETURN fn::service::valid_runs_in($service, $service.runs_in);
};
