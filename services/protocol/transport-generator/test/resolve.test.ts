import { describe, expect, test } from "bun:test";

import { parseManifest } from "../src/routes/manifest.js";
import { resolveRoutes } from "../src/routes/resolve.js";
import { committedRoutes, EMPTY_INPUT, loadSkirInput } from "./support.js";

const resolveSource = (source: string) => resolveRoutes(parseManifest(source, "routes.yaml"), EMPTY_INPUT);

describe("route resolution", () => {
  test("rejects duplicate routes before Skir resolution", () => {
    expect(() =>
      resolveSource(`
routes:
  - &route
    name: duplicate_route
    scope: user
    grants: []
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: duplicate.route
      failure_slug: duplicate-route-failed
      requests:
        panel: "cloud.to.user.{user}.watch"
  - *route
`),
    ).toThrow("route duplicate_route at routes[1]: duplicate logical route");
  });

  test("rejects duplicate and incompatible grants", () => {
    expect(() =>
      resolveSource(`
routes:
  - name: duplicate_grant
    scope: user
    grants:
      - &grant { role: authenticated_user, side: panel, direction: publish, channel: request }
      - *grant
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: duplicate.grant
      failure_slug: duplicate-grant-failed
      requests:
        panel: "cloud.to.user.{user}.watch"
`),
    ).toThrow("route duplicate_grant at routes[0].grants[1]: duplicate grant");
    expect(() =>
      resolveSource(`
routes:
  - name: incompatible_grant
    scope: user
    grants:
      - { role: authenticated_user, side: panel, direction: subscribe, channel: updates }
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: incompatible.grant
      failure_slug: incompatible-grant-failed
      requests:
        panel: "cloud.to.user.{user}.watch"
`),
    ).toThrow("invalid grant channel updates");
  });

  test("reports a missing required capture with route context", () => {
    expect(() =>
      resolveSource(`
routes:
  - name: missing_actor
    scope: organization_actor
    grants: []
    flow:
      kind: unary
      method: "organization/v1/member.skir:WatchOrganizationMembers"
      operation: missing.actor
      failure_slug: missing-actor-failed
      requests:
        panel: "cloud.to.organization.{organization}.members.watch"
`),
    ).toThrow(
      "route missing_actor at routes[0].flow.requests.panel: request endpoint panel is invalid: request subject is missing required user parameter",
    );
  });

  test("reports an unresolved Skir method", () => {
    expect(() =>
      resolveSource(`
routes:
  - name: unresolved_method
    scope: user
    grants: []
    flow:
      kind: unary
      method: "organization/v1/user.skir:Missing"
      operation: unresolved.method
      failure_slug: unresolved-method-failed
      requests:
        panel: "cloud.to.user.{user}.watch"
`),
    ).toThrow(
      "route unresolved_method at routes[0].flow.method: unknown Skir method organization/v1/user.skir:Missing",
    );
  });

  test("rejects presence projections of authoritative or absent identities", () => {
    for (const [parameter, expected] of [
      ["organization", "authoritative scope identity"],
      ["realm", "absent parameter"],
    ] as const) {
      expect(() =>
        resolveSource(`
routes:
  - name: invalid_presence
    scope: organization_actor
    grants: []
    flow:
      kind: event
      binding: { kind: native_kotlin, format: kotlin_serialization_cbor, target: loader_core, event_type: com.example.Event, event_codec: com.example.Codecs.event }
      operation: invalid.presence
      failure_slug: invalid-presence-failed
      addresses:
        panel:
          subject: "typewriter.presence.organization.{organization}.user.{user}"
          subscription: { wildcard: [${parameter}] }
      delivery: { kind: transient }
`),
      ).toThrow(expected);
    }
  });

  test("rejects grants on internal component routes", () => {
    expect(() =>
      resolveSource(`
routes:
  - name: invalid_internal
    scope: internal_component
    grants:
      - { role: native_client, side: backend_internal, direction: publish, channel: request }
    subscription: { component: auth-typewriter-permissions, group: typewriter.auth-auth-typewriter-permissions }
    flow:
      kind: unary
      method: "access/v1/permission.skir:GetEntityPermission"
      operation: invalid.internal
      failure_slug: invalid-internal-failed
      requests: { backend_internal: "auth.permissions.typewriter-panel" }
`),
    ).toThrow("requires a subscription and no grants");
  });

  test("names the Skir source of a transfer field that is not a string", async () => {
    const input = await loadSkirInput();
    expect(() =>
      resolveRoutes(
        parseManifest(
          `
routes:
  - name: bounded_without_string
    scope: realm
    grants: []
    flow:
      kind: bounded_watch
      method: "editor/v1/catalog.skir:FetchEditorCatalog"
      transfer_field: missing_field
      operation: bounded.missing
      failure_slug: bounded-missing-failed
      requests: { service: "service.to.{realm}.organization.{organization}.fetch" }
      updates: { service: "service.from.{realm}.organization.{organization}.fetch.{transfer_id}" }
`,
          "routes.yaml",
        ),
        input,
      ),
    ).toThrow(/expected string field missing_field on .* \(Skir editor\/v1\/catalog\.skir:\d+:\d+\)/u);
  });

  test("resolves every committed route against the Skir sources", async () => {
    const { routes } = await committedRoutes();
    expect(routes).toHaveLength(65);
    const catalog = routes.find((route) => route.name === "editor_catalog_fetch")!;
    expect(catalog.flow.kind).toBe("bounded_watch");
    if (catalog.flow.kind === "bounded_watch") {
      expect(catalog.flow.method.method.name.text).toBe("FetchEditorCatalog");
      expect(catalog.flow.transferField.name.text).toBe("transfer_id");
    }
  });
});
