import { describe, expect, test } from "bun:test";

import { servedSubjects, subscriptionSubject } from "../src/routes/dispatch.js";
import { emitRust } from "../src/routes/emit/rust.js";
import { parseManifest, type Manifest } from "../src/routes/manifest.js";
import { routeChannels } from "../src/routes/subject.js";
import { symbolProviders } from "../src/symbols.js";
import { committedManifest, committedRoutes, manifestSource } from "./support.js";

function served(manifest: Manifest) {
  return servedSubjects(
    manifest.routes.map((route) => ({ name: route.name, channels: routeChannels(route, manifest.roles) })),
  );
}

function subscriptions(manifest: Manifest, component: string): string[] {
  return (served(manifest).get(component) ?? []).map((entry) => subscriptionSubject(entry.subject));
}

const unary = (name: string, callers: string, request: string, scope = "user") => `  - name: ${name}
    scope: ${scope}
    callers: [${callers}]
    server: { component: user-organization }
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: sample.${name}
      request: ${request}
`;

function section(code: string, start: string, end: string): string {
  const from = code.indexOf(start);
  expect(from).toBeGreaterThanOrEqual(0);
  return code.slice(from, code.indexOf(end, from + start.length));
}

describe("component dispatch", () => {
  test("every component receives exactly the subjects of the routes it serves or subscribes to", () => {
    const manifest = committedManifest();
    expect([...served(manifest).keys()]).toEqual([
      "user-organization",
      "organization-members",
      "organization-roles",
      "service-registration",
      "auth-typewriter-permissions",
    ]);
    expect(subscriptions(manifest, "organization-members")).toEqual([
      "typewriter.from.user.*.organization.*.members.watch",
      "typewriter.from.user.*.organization.*.members.update",
      "typewriter.from.user.*.organization.*.members.remove",
      "typewriter.from.user.*.organization.*.members.join_requests.watch",
      "typewriter.from.user.*.organization.*.members.join_requests.approve",
      "typewriter.from.user.*.organization.*.members.join_requests.decline",
      "typewriter.from.user.*.organization.*.members.join_codes.watch",
      "typewriter.from.user.*.organization.*.members.join_codes.generate",
      "typewriter.from.user.*.organization.*.members.join_codes.revoke",
    ]);
    const registration = subscriptions(manifest, "service-registration");
    expect(registration).toHaveLength(16);
    expect(registration.slice(0, 2)).toEqual([
      "typewriter.from.service.*.binding.query",
      "service.*.binding.query",
    ]);
    expect(registration).toContain("typewriter.from.service.*.heartbeat");
    expect(registration).not.toContain("service.*.registration.ensure");
    expect(registration).not.toContain("typewriter.to.service.*.registration.bound");
    expect(subscriptions(manifest, "auth-typewriter-permissions")).toEqual([
      "auth.permissions.typewriter-panel",
      "auth.permissions.typewriter-services",
    ]);
  });

  test("subjects that one message could match fail generation with both route names", () => {
    const parse = (routes: string, components = ["user-organization"]) =>
      parseManifest(manifestSource(routes, components), "routes.yaml");
    const identical = parse(
      unary("first", "{ role: authenticated_user }", "user.{user}.thing") +
        unary("second", "{ role: authenticated_user }", "user.{user}.thing"),
    );
    expect(() => served(identical)).toThrow(
      "component user-organization receives overlapping subjects typewriter.from.user.{user}.thing " +
        "of route first and typewriter.from.user.{user}.thing of route second",
    );
    const captured = parse(
      unary("captured", "{ role: authenticated_user }, { component: auth-callout }", "user.{user}.thing") +
        unary("literal", "{ component: auth-callout }", "user.admin.thing", "internal_component"),
      ["user-organization", "auth-callout"],
    );
    expect(() => served(captured)).toThrow("of route captured and user.admin.thing of route literal");
    const distinct = parse(
      unary("create", "{ role: authenticated_user }", "user.{user}.create") +
        unary("watch", "{ role: authenticated_user }", "user.{user}.watch") +
        unary("nested", "{ role: authenticated_user }", "user.{user}.watch.all"),
    );
    expect(subscriptions(distinct, "user-organization")).toEqual([
      "typewriter.from.user.*.create",
      "typewriter.from.user.*.watch",
      "typewriter.from.user.*.watch.all",
    ]);
  });

  test("the Rust target emits one typed dispatcher per receiving component", async () => {
    const { input, resolved } = await committedRoutes();
    const [rust] = emitRust(resolved, symbolProviders(input).rust, input);
    const code = rust!.code;
    expect(code).not.toContain("pub mod auth_callout");
    expect(code).not.toContain("fn scope(");

    const members = section(code, "pub mod organization_members {", "\n}\n");
    expect(members).toContain('"typewriter.from.user.*.organization.*.members.join_codes.revoke",');
    expect(members).toContain("pub organization_join_code_revoke: OrganizationJoinCodeRevoke,");
    expect(members).toContain(
      "OrganizationMembersWatch: AsyncFnOnce(OrganizationActorScope, WatchOrganizationMembersRequest) -> Result<WatchOrganizationMembersResponse, Error>,",
    );
    expect(members).toContain(
      '["typewriter", "from", "user", user, "organization", organization, "members", "watch"] => {',
    );
    expect(members).toContain("let scope = OrganizationActorScope::from_tokens(user, organization);");
    expect(members).toContain(
      "serve_request::<super::OrganizationMembersWatchRoute>(msg, scope, handlers.organization_members_watch).await",
    );
    expect(members).toContain("_ => Err(unmatched(&msg)),");
    expect(members).toContain("use crate::transport::OrganizationActorScope;");

    const registration = section(code, "pub mod service_registration {", "\n}\n");
    expect(registration).toContain('["typewriter", "from", "service", service, "heartbeat"] => {');
    expect(registration).toContain(
      "serve_event::<super::ServiceHeartbeatRoute>(msg, scope, handlers.service_heartbeat).await",
    );
    expect(registration).toContain(
      "ServiceHeartbeat: AsyncFnOnce(ServiceScope, ServiceHeartbeatNotification) -> Result<(), Error>,",
    );
    // A route received on its bridged and its direct subject has one handler for both arms.
    expect(registration.match(/handlers\.service_binding_query\)/gu)).toHaveLength(2);
    expect(registration.match(/pub service_binding_query:/gu)).toHaveLength(1);

    const permissions = section(code, "pub mod auth_typewriter_permissions {", "\n}\n");
    expect(permissions).toContain("let scope = InternalComponentScope::from_tokens();");
  });

  test("route types name their Skir types and leave scope parsing to the dispatcher", async () => {
    const { input, resolved } = await committedRoutes();
    const [rust] = emitRust(resolved, symbolProviders(input).rust, input);
    const create = section(rust!.code, "impl crate::transport::RequestRoute for UserOrganizationCreateRoute {", "\n}\n");
    expect(create).toContain(
      "type Response = crate::skirout::base::organization::v1::organization::CreateOrganizationResponse;",
    );
    expect(create).not.toContain("type Delivery");
    const panel = section(rust!.code, "impl crate::transport::RequestRoute for PanelPermissionResolveRoute {", "\n}\n");
    expect(panel).toContain("type Response = crate::skirout::base::access::v1::permission::GetEntityPermissionResponse;");
    const outbound = section(
      rust!.code,
      "impl crate::transport::OutboundRequestRoute for PanelPermissionResolveRoute {",
      "\n}\n",
    );
    expect(outbound).toContain("fn subject(_scope: &Self::Scope) -> String {");
    for (const runtime of ["pub struct SubjectToken", "pub struct GrantSet", "pub trait RequestRoute", "macro_rules!"]) {
      expect(rust!.code).not.toContain(runtime);
    }
  });
});
