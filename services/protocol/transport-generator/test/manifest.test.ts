import { describe, expect, test } from "bun:test";

import { parseManifest, symbolRefText } from "../src/routes/manifest.js";
import { committedManifest, manifestSource } from "./support.js";

const unary = (name: string, party: string, request: string, scope = "user") => `  - name: ${name}
    scope: ${scope}
    callers: [${party}]
    server: { component: user-organization }
    flow:
      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: sample.route
      request: ${request}
`;

const parse = (routes: string, components = ["user-organization"]) =>
  parseManifest(manifestSource(routes, components), "routes.yaml");

describe("manifest admission", () => {
  test("parses the complete route inventory", () => {
    const manifest = committedManifest();
    expect(manifest.routes).toHaveLength(65);
    const methods = new Set<string>();
    const payloads = new Set<string>();
    for (const { flow } of manifest.routes) {
      if (flow.kind === "unary" || flow.kind === "watch") {
        methods.add(symbolRefText(flow.method));
      }
      if (flow.kind === "watch") {
        payloads.add(symbolRefText(flow.updates.payload));
      }
      if (flow.kind === "event" && flow.binding.kind === "skir") {
        payloads.add(symbolRefText(flow.binding.payload));
      }
    }
    expect(methods.size).toBe(55);
    expect(payloads.size).toBe(17);
  });

  test("declares the reply framing limits once", () => {
    expect(committedManifest().limits).toEqual({ chunkBytes: 524288, maxChunks: 64 });
    expect(committedManifest().limits.chunkBytes * committedManifest().limits.maxChunks).toBe(33_554_432);
    const source = manifestSource(unary("sample_route", "{ role: authenticated_user }", "user.{user}.sample"), [
      "user-organization",
    ]);
    expect(() => parseManifest(source.replace("max_chunks: 64", "max_chunks: 0"), "routes.yaml")).toThrow(
      "limits.max_chunks",
    );
    expect(() => parseManifest(source.replace("chunk_bytes: 524288", "chunk_bytes: 1.5"), "routes.yaml")).toThrow(
      "limits.chunk_bytes",
    );
  });

  test("declares every backend component that serves or calls a route", () => {
    const { components } = committedManifest();
    expect(Object.fromEntries(components)).toEqual({
      "auth-callout": "backend/access/auth-callout/deploy/base",
      "auth-typewriter-permissions": "backend/access/auth-typewriter-permissions/deploy/base",
      "organization-members": "backend/organization/organization-members/deploy/base",
      "organization-roles": "backend/organization/organization-roles/deploy/base",
      "service-registration": "backend/service/service-registration/deploy/base",
      "user-organization": "backend/organization/user-organization/deploy/base",
    });
  });

  test("names roles, components and one logical address per channel", () => {
    const manifest = parse(unary("sample_route", "{ role: authenticated_user }", "user.{user}.sample"));
    expect(manifest.roles.get("organization_member")).toEqual({
      name: "organization_member",
      side: "panel",
      tenant: ["organization"],
      personal: "user",
    });
    expect(manifest.roles.get("realm_coordinator")?.personal).toBeUndefined();
    const [route] = manifest.routes;
    expect(route).toMatchObject({
      callers: [{ role: "authenticated_user" }],
      server: { component: "user-organization" },
    });
    expect(route!.flow.kind === "unary" && route!.flow.request.toString()).toBe("user.{user}.sample");
  });

  test("rejects a party naming an undeclared role", () => {
    expect(() => parse(unary("unknown_role", "{ role: native_client }", "user.{user}.sample"))).toThrow(
      'routes.yaml:12:23: routes[0].callers[0].role: unknown role "native_client"',
    );
  });

  test("rejects a party naming an undeclared component", () => {
    expect(() =>
      parse(unary("unknown_component", "{ component: auth-sentinel }", "user.{user}.sample")),
    ).toThrow('routes[0].callers[0].component: unknown component "auth-sentinel"');
  });

  test("rejects an address placeholder the route scope does not bind", () => {
    expect(() =>
      parse(unary("unbound_placeholder", "{ role: authenticated_user }", "user.{user}.organization.{organization}")),
    ).toThrow("routes[0].flow.request: placeholder {organization} is not bound by user scope");
  });

  test("rejects a role that binds neither a scope identifier nor its tenant", () => {
    expect(() =>
      parse(
        unary(
          "cross_tenant",
          "{ role: authenticated_user }",
          "user.{user}.organization.{organization}.watch",
          "organization_actor",
        ),
      ),
    ).toThrow("routes[0].callers[0].role: role authenticated_user does not bind {organization} of organization_actor scope");
  });

  test("rejects a component that takes part in no route", () => {
    expect(() =>
      parse(unary("sample_route", "{ role: authenticated_user }", "user.{user}.sample"), [
        "user-organization",
        "organization-roles",
      ]),
    ).toThrow('components.organization-roles: component "organization-roles" takes part in no route');
  });

  test("rejects addresses that spell a subject family", () => {
    for (const address of ["cloud.to.user.{user}.sample", "typewriter.presence", "service.to.sample"]) {
      expect(() => parse(unary("family_prefix", "{ role: authenticated_user }", address))).toThrow(
        "subject family",
      );
    }
  });

  test("requires the parties of the flow kind", () => {
    expect(() =>
      parse(`  - name: event_with_callers
    scope: user
    callers: [{ role: authenticated_user }]
    server: { component: user-organization }
    flow:
      kind: event
      binding: { kind: skir, payload: "organization/v1/presence.skir:PresenceEvent" }
      operation: event.callers
      address: user.{user}.event
      delivery: { kind: transient }
`),
    ).toThrow("event routes declare publishers");
  });

  test("rejects duplicate keys", () => {
    expect(() =>
      parse(`  - name: duplicate_key
    scope: user
    scope: user
`),
    ).toThrow("routes.yaml: Map keys must be unique");
  });

  test("names the YAML path and line of an invalid address", () => {
    expect(() => parse(unary("invalid_address", "{ role: authenticated_user }", "user.*"))).toThrow(
      'routes.yaml:18:16: routes[0].flow.request: invalid subject token "*"',
    );
  });

  test("rejects the removed bounded watch flow", () => {
    expect(() =>
      parse(`  - name: bounded_fetch
    scope: user
    callers: [{ role: authenticated_user }]
    server: { component: user-organization }
    flow:
      kind: bounded_watch
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: bounded.fetch
      request: user.{user}.fetch
`),
    ).toThrow("routes[0].flow.kind");
    expect(() => parse(unary("transfer_capture", "{ role: authenticated_user }", "user.{user}.fetch.{transfer_id}"))).toThrow(
      'invalid subject token "{transfer_id}"',
    );
  });

  test("rejects the removed per route fields", () => {
    for (const field of ["failure_slug: sample-failed", "requests: { panel: 'user.{user}' }"]) {
      expect(() =>
        parse(`${unary("removed_field", "{ role: authenticated_user }", "user.{user}.sample")}      ${field}\n`),
      ).toThrow("routes[0].flow");
    }
    expect(() =>
      parse(`  - name: removed_grants
    scope: user
    grants: []
${unary("x", "{ role: authenticated_user }", "user.{user}.sample").split("\n").slice(2).join("\n")}`),
    ).toThrow('Unrecognized key: "grants"');
  });

  test("rejects unsupported native targets and malformed Skir references", () => {
    expect(() =>
      parse(`  - name: native_target
    scope: realm
    callers: [{ role: realm_coordinator }]
    server: { role: realm_participant }
    flow:
      kind: scatter
      binding: { kind: native_kotlin, format: kotlin_serialization_cbor, target: panel, request_type: a.B, response_type: a.C, request_codec: a.D.e, response_codec: a.D.f }
      operation: native.target
      request: rollout.probe
`, []),
    ).toThrow('unsupported Kotlin generator target "panel"');
    expect(() =>
      parse(
        unary("bad_reference", "{ role: authenticated_user }", "user.{user}.sample").replace(
          "organization/v1/user.skir",
          "../user.skir",
        ),
      ),
    ).toThrow('invalid canonical module path "../user.skir"');
  });
});
