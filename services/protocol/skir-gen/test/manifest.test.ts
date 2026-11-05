import { describe, expect, test } from "bun:test";

import { readFileSync } from "node:fs";

import { parse as parseYaml } from "yaml";

import { parseManifest, symbolRefText } from "../src/routes/manifest.js";
import { committedManifest, MANIFEST_PATH, manifestSource } from "./support.js";

/** The committed manifest as plain YAML data, the independent view admission must preserve. */
const RAW = parseYaml(readFileSync(MANIFEST_PATH, "utf8")) as {
  routes: Array<{ flow: { kind: string; method?: string; payload?: string; updates?: { payload: string } } }>;
};

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
    expect(manifest.routes).toHaveLength(RAW.routes.length);
    const methods = new Set<string>();
    const payloads = new Set<string>();
    for (const { flow } of manifest.routes) {
      if (flow.kind === "event") {
        payloads.add(symbolRefText(flow.payload));
      } else {
        methods.add(symbolRefText(flow.method));
      }
      if (flow.kind === "watch") {
        payloads.add(symbolRefText(flow.updates.payload));
      }
    }
    const raw = RAW.routes.map(({ flow }) => flow);
    expect([...methods].sort()).toEqual([...new Set(raw.flatMap((flow) => flow.method ?? []))].sort());
    expect([...payloads].sort()).toEqual(
      [...new Set(raw.flatMap((flow) => [flow.payload, flow.updates?.payload].filter((value) => value !== undefined)))].sort(),
    );
  });

  const sampleSource = manifestSource(unary("sample_route", "{ role: authenticated_user }", "user.{user}.sample"), [
    "user-organization",
  ]);

  test.each([
    ["a window of no frames", /window_frames: \d+/u, "window_frames: 0", "limits.window_frames"],
    ["a reply ceiling below one chunk", /reply_max_bytes: \d+/u, "reply_max_bytes: 1024", "reply_max_bytes must hold at least one chunk"],
    ["a fractional chunk size", /chunk_bytes: \d+/u, "chunk_bytes: 1.5", "limits.chunk_bytes"],
    ["a missing reply lifetime", /, reply_ttl_ms: \d+/u, "", "limits.reply_ttl_ms"],
    ["a missing frame inactivity timeout", /, frame_inactivity_ms: \d+/u, "", "limits.frame_inactivity_ms"],
  ])("rejects %s in the payload framing limits", (_, pattern, replacement, error) => {
    expect(() => parseManifest(sampleSource.replace(pattern, replacement), "routes.yaml")).toThrow(error);
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
      payload: "organization/v1/presence.skir:PresenceEvent"
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

  test("rejects a capture the identities do not provide", () => {
    expect(() => parse(unary("transfer_capture", "{ role: authenticated_user }", "user.{user}.fetch.{transfer_id}"))).toThrow(
      'invalid subject token "{transfer_id}"',
    );
  });

  test("rejects unknown fields", () => {
    expect(() =>
      parse(`${unary("unknown_field", "{ role: authenticated_user }", "user.{user}.sample")}      timeout: 5\n`),
    ).toThrow('routes.yaml:15:7: routes[0].flow: Unrecognized key: "timeout"');
  });

  test("rejects malformed Skir references", () => {
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
