import { describe, expect, test } from "bun:test";

import { parseManifest } from "../src/routes/manifest.js";
import { resolveRoutes, routeChannel } from "../src/routes/resolve.js";
import { committedManifest, committedRoutes, EMPTY_INPUT, manifestSource } from "./support.js";

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
      payload: "service/v1/lifecycle.skir:ServiceHeartbeatNotification"
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

  test("resolves every committed route against the Skir sources", async () => {
    const { routes } = await committedRoutes();
    expect(routes).toHaveLength(committedManifest().routes.length);
    const catalog = routes.find((route) => route.name === "editor_catalog_fetch")!;
    expect(catalog.flow.kind).toBe("unary");
    if (catalog.flow.kind === "unary") {
      expect(catalog.flow.method.method.name.text).toBe("FetchEditorCatalog");
    }
    expect(routeChannel(catalog, "request")?.subjects.client?.toString()).toBe(
      "service.to.{realm}.organization.{organization}.realm.editor.catalog.fetch",
    );
    expect(routeChannel(catalog, "updates")).toBeUndefined();
  });

  test("rollout routes use the realm mesh", async () => {
    const { routes } = await committedRoutes();
    const rollout = routes.filter((route) => route.name.startsWith("rollout_"));
    expect(rollout.map((route) => route.name)).toEqual(["rollout_probe", "rollout_command", "rollout_status"]);
    for (const route of rollout) {
      expect(route.flow.kind).toBe("scatter");
      expect(routeChannel(route, "request")?.subjects.client?.toString()).toBe(
        `service.from.{realm}.organization.{organization}.realm.rollout.${route.name.slice("rollout_".length)}`,
      );
    }
    expect(routes.some((route) => route.operation === "realm.rollout.state")).toBe(false);
  });

  test("admits a scatter method through its response outcomes", async () => {
    const { routes } = await committedRoutes();
    const command = routes.find((route) => route.name === "rollout_command")!;
    if (command.flow.kind !== "scatter") throw new Error("rollout_command must be a scatter route");
    expect(command.flow.method.method.name.text).toBe("ApplyRolloutCommand");
    expect(command.flow.method.outcomes.variants.map(({ slug, outcome }) => [slug, outcome])).toEqual([
      ["accepted", "success"],
      ["stale-attempt-error", "domain_error"],
      ["attempt-conflict-error", "domain_error"],
      ["command-rejected-error", "domain_error"],
      ["command-failed-error", "domain_error"],
      ["internal-error", "internal_error"],
    ]);
  });
});
