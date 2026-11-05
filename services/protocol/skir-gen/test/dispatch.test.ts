import { describe, expect, test } from "bun:test";

import { servedSubjects, subscriptionSubject } from "../src/routes/dispatch.js";
import { parseManifest, type Manifest } from "../src/routes/manifest.js";
import { routeChannels } from "../src/routes/subject.js";
import { manifestSource } from "./support.js";

function served(manifest: Manifest) {
  return servedSubjects(
    manifest.routes.map((route) => ({ name: route.name, channels: routeChannels(route, manifest.roles) })),
  );
}

function subscriptions(manifest: Manifest, component: string): string[] {
  return (served(manifest).get(component) ?? []).map((entry) => subscriptionSubject(entry.subject));
}

const unary = (name: string, callers: string, request: string, scope = "user", server = "user-organization") => `  - name: ${name}
    scope: ${scope}
    callers: [${callers}]
    server: { component: ${server} }
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: sample.${name}
      request: ${request}
`;

describe("component dispatch", () => {
  test("every component receives exactly the subjects of the routes it serves", () => {
    const manifest = parseManifest(
      manifestSource(
        unary("create", "{ role: authenticated_user }", "user.{user}.create") +
          unary("members", "{ role: authenticated_user }, { component: auth-callout }", "user.{user}.members", "user", "organization-members"),
        ["user-organization", "organization-members", "auth-callout"],
      ),
      "routes.yaml",
    );
    expect([...served(manifest).keys()]).toEqual(["user-organization", "organization-members"]);
    expect(subscriptions(manifest, "user-organization")).toEqual(["typewriter.from.user.*.create"]);
    expect(subscriptions(manifest, "organization-members")).toEqual([
      "typewriter.from.user.*.members",
      "user.*.members",
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
});
