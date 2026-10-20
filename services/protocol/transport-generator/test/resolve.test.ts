import { describe, expect, test } from "bun:test";

import { parseManifest } from "../src/routes/manifest.js";
import { resolveRoutes, routeChannel } from "../src/routes/resolve.js";
import { committedRoutes, EMPTY_INPUT, loadSkirInput, manifestSource } from "./support.js";

const parse = (routes: string, components: readonly string[] = []) =>
  parseManifest(manifestSource(routes, components), "routes.yaml");

const resolveSource = (routes: string, components: readonly string[] = []) =>
  resolveRoutes(parse(routes, components), EMPTY_INPUT);

const userRoute = (name: string, request: string) => `  - name: ${name}
    scope: organization_actor
    callers: [{ role: organization_member }]
    server: { component: organization-members }
    flow:
      kind: unary
      method: "organization/v1/user.skir:Missing"
      operation: sample.route
      request: ${request}
`;

describe("route resolution", () => {
  test("rejects duplicate routes before Skir resolution", () => {
    const route = userRoute("duplicate_route", "user.{user}.organization.{organization}.watch");
    expect(() => resolveSource(route + route, ["organization-members"])).toThrow(
      "route duplicate_route at routes[1]: duplicate logical route",
    );
  });

  test("reports a request subject missing a scope capture with route context", () => {
    expect(() =>
      resolveSource(userRoute("missing_actor", "organization.{organization}.members.watch"), [
        "organization-members",
      ]),
    ).toThrow(
      "route missing_actor at routes[0].flow.request: request subject cloud.to.organization.{organization}.members.watch does not capture {user} of organization_actor scope",
    );
  });

  test("reports party combinations without a subject family", () => {
    expect(() =>
      resolveSource(`  - name: service_peers
    scope: service
    publishers: [{ role: registered_service }]
    subscribers: [{ role: registered_service }]
    flow:
      kind: event
      binding: { kind: skir, payload: "service/v1/lifecycle.skir:ServiceHeartbeatNotification" }
      operation: service.peers
      address: service.{service}.peers
      delivery: { kind: transient }
`),
    ).toThrow("route service_peers at routes[0]: event channel between service roles outside realm scope");
  });

  test("reports an unresolved Skir method", () => {
    expect(() =>
      resolveSource(userRoute("unresolved_method", "user.{user}.organization.{organization}.watch"), [
        "organization-members",
      ]),
    ).toThrow(
      "route unresolved_method at routes[0].flow.method: unknown Skir method organization/v1/user.skir:Missing",
    );
  });

  test("names the Skir source of a transfer field that is not a string", async () => {
    const input = await loadSkirInput();
    expect(() =>
      resolveRoutes(
        parse(`  - name: bounded_without_string
    scope: realm
    callers: [{ role: organization_member }]
    server: { role: realm_coordinator }
    flow:
      kind: bounded_watch
      method: "editor/v1/catalog.skir:FetchEditorCatalog"
      transfer_field: missing_field
      operation: bounded.missing
      request: fetch
      updates: fetch.{transfer_id}
`),
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
    expect(routeChannel(catalog, "updates")?.subjects.client?.toString()).toBe(
      "service.from.{realm}.organization.{organization}.realm.editor.catalog.fetch.{transfer_id}",
    );
  });

  test("rollout routes use the realm mesh", async () => {
    const { routes } = await committedRoutes();
    const subject = (name: string, channel: "request" | "event") =>
      routeChannel(routes.find((route) => route.name === name)!, channel)?.subjects.client?.toString();
    expect(subject("realm_hosts_probe", "request")).toBe(
      "service.from.{realm}.organization.{organization}.realm.rollout.probe",
    );
    expect(subject("realm_rollout_state", "event")).toBe(
      "service.to.{realm}.organization.{organization}.realm.rollout.state",
    );
  });
});
