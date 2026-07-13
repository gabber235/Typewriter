CREATE user:alice SET email = "alice@example.com", name = "Alice", avatar_url = "https://example.com/alice.png";
CREATE user:bob SET email = "bob@example.com", name = "Bob";
CREATE user:carol SET email = "carol@example.com", name = "Carol";
CREATE user:dave SET name = "Dave";

CREATE organization:acme SET name = "acme", logo_url = "https://example.com/acme.png", founder = user:alice;
CREATE organization:beta SET name = "beta", founder = user:carol;

LET $member_role = CREATE ONLY organization_role:acme_member SET
    name = "member",
    organization = organization:acme,
    color = fn::color("#112233");

RELATE user:bob->member_of->organization:acme SET roles = [$member_role.id];

CREATE organization_join_code:manual_acme SET organization = organization:acme, created_by = user:alice;

CREATE service:realm_acme SET name = "realm_acme", roles = [{ type: "realm", version: "1.0.0" }], organization = organization:acme;
CREATE service:engine_acme SET name = "engine_acme", roles = [{ type: "engine", version: "1.0.0" }], organization = organization:acme, runs_in = service:realm_acme;
CREATE service:realm_unbound SET name = "realm_unbound", roles = [{ type: "realm", version: "1.0.0" }];
CREATE service:engine_unbound SET name = "engine_unbound", roles = [{ type: "engine", version: "1.0.0" }], runs_in = service:realm_unbound;
