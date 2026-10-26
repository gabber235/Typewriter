import { describe, expect, test } from "bun:test";

import { parseManifest } from "../src/routes/manifest.js";
import { resolveRoutes } from "../src/routes/resolve.js";
import { responseLimit, serviceResponseLimit } from "../src/routes/responses.js";
import { committedRoutes, EMPTY_INPUT, loadSkirInput, manifestSource } from "./support.js";

const MIB = 1024 * 1024;

const componentRoute = (ceiling: string) => `  - name: sample_route
    scope: user
    callers: [{ role: authenticated_user }]
    server: { component: user-organization }
    flow:
      kind: unary
      method: "organization/v1/user.skir:Missing"
      operation: sample.route
      request: user.{user}.sample
      ${ceiling}
`;

const resolveSource = (routes: string, components: readonly string[] = ["user-organization"]) =>
  resolveRoutes(parseManifest(manifestSource(routes, components), "routes.yaml"), EMPTY_INPUT);

/** Resolves routes between service roles against the repository Skir sources. */
const resolveWithSkir = async (routes: string) =>
  resolveRoutes(parseManifest(manifestSource(routes), "routes.yaml"), await loadSkirInput());

describe("payload ceilings", () => {
  test("a route that raises a ceiling carries its own limit and every other route the manifest's", async () => {
    const resolved = await resolveWithSkir(`  - name: plain
    scope: realm
    callers: [{ role: realm_participant }]
    server: { role: realm_coordinator }
    flow:
      kind: unary
      method: "service/v1/artifact.skir:FetchArtifactBlobMetadata"
      operation: plain
      request: plain
  - name: large_request
    scope: realm
    callers: [{ role: realm_participant }]
    server: { role: realm_coordinator }
    flow:
      kind: unary
      method: "service/v1/artifact.skir:FetchArtifactBlobMetadata"
      operation: large.request
      request: large.request
      request_max_bytes: ${128 * MIB}
`);
    const [plain, large] = resolved.routes;
    expect(plain!.limits.requestMaxBytes).toBe(resolved.limits.requestMaxBytes);
    expect(large!.limits.requestMaxBytes).toBe(128 * MIB);
    expect(large!.limits.replyMaxBytes).toBe(resolved.limits.replyMaxBytes);
  });

  test("a backend component cannot receive framed requests", () => {
    expect(() => resolveSource(componentRoute("request_max_bytes: 1048576"))).toThrow(
      "route sample_route at routes[0].flow.request_max_bytes: a backend component cannot receive framed requests",
    );
  });

  test("a backend component frames replies by the manifest ceiling only", () => {
    expect(() => resolveSource(componentRoute("reply_max_bytes: 67108864"))).toThrow(
      "route sample_route at routes[0].flow.reply_max_bytes: a backend component frames every reply by the manifest reply_max_bytes",
    );
  });

  test("a ceiling below one chunk is rejected", () => {
    expect(() => parseManifest(manifestSource(componentRoute("reply_max_bytes: 1024"), ["user-organization"]), "routes.yaml")).toThrow(
      "reply_max_bytes must hold at least one chunk",
    );
  });
});

describe("NATS response limits", () => {
  test("a server may send every frame of the largest reply it serves", async () => {
    const resolved = await resolveWithSkir(`  - name: small_reply
    scope: realm
    callers: [{ role: realm_participant }]
    server: { role: realm_coordinator }
    flow:
      kind: unary
      method: "service/v1/artifact.skir:FetchArtifactBlobMetadata"
      operation: small.reply
      request: small
  - name: large_reply
    scope: realm
    callers: [{ role: realm_participant }]
    server: { role: realm_coordinator }
    flow:
      kind: unary
      method: "service/v1/artifact.skir:FetchArtifactBlobMetadata"
      operation: large.reply
      request: large
      reply_max_bytes: ${64 * MIB}
`);
    const frames = (64 * MIB) / resolved.limits.chunkBytes;
    expect(responseLimit("realm_coordinator", resolved.routes)).toBe(frames);
    expect(serviceResponseLimit(resolved.roles, resolved.routes)).toBe(frames);
  });

  test("a panel role never needs a response permission", async () => {
    const { resolved } = await committedRoutes();
    for (const role of resolved.roles.values()) {
      if (role.side === "panel") expect(responseLimit(role.name, resolved.routes)).toBeNull();
    }
  });

  test("a service that calls a route with credited framed replies may grant one credit", async () => {
    const resolved = await resolveWithSkir(`  - name: sample_route
    scope: realm
    callers: [{ role: realm_coordinator }]
    server: { role: realm_participant }
    flow:
      kind: unary
      method: "service/v1/artifact.skir:FetchArtifactBlobMetadata"
      operation: sample.route
      request: sample
`);
    expect(responseLimit("realm_coordinator", resolved.routes)).toBe(1);
  });
});

describe("reply credit", () => {
  const route = (callers: string, server = "{ role: realm_coordinator }") => `  - name: sample_route
    scope: realm
    callers: [${callers}]
    server: ${server}
    flow:
      kind: unary
      method: "service/v1/artifact.skir:FetchArtifactBlobMetadata"
      operation: sample.route
      request: sample
`;

  test("replies wait for credit only when no caller runs on the panel", async () => {
    const credit = async (callers: string) => (await resolveWithSkir(route(callers))).routes[0]!.limits.replyCredit;
    expect(await credit("{ role: realm_participant }")).toBe(true);
    expect(await credit("{ role: realm_participant }, { role: organization_member }")).toBe(false);
    expect(await credit("{ role: organization_member }")).toBe(false);
  });

  test("every committed route a panel role calls streams its replies", async () => {
    const { resolved } = await committedRoutes();
    const panelRoles = new Set([...resolved.roles.values()].filter((role) => role.side === "panel").map((role) => role.name));
    const credited = resolved.routes.filter(
      (candidate) =>
        candidate.limits.replyCredit && candidate.parties.some((party) => "role" in party && panelRoles.has(party.role)),
    );
    expect(credited.map((candidate) => candidate.name)).toEqual([]);
  });

  test("a panel role cannot serve requests", () => {
    expect(() => resolveSource(route("{ role: realm_participant }", "{ role: organization_member }"), [])).toThrow(
      "route sample_route at routes[0].server: a panel role cannot serve requests",
    );
  });

  test("scatter and watch routes cannot raise the reply ceiling", () => {
    const scatter = `  - name: sample_route
    scope: realm
    callers: [{ role: realm_coordinator }]
    server: { role: realm_participant }
    flow:
      kind: scatter
      method: "organization/v1/user.skir:Missing"
      operation: sample.route
      request: sample
      reply_max_bytes: 67108864
`;
    expect(() => parseManifest(manifestSource(scatter), "routes.yaml")).toThrow("reply_max_bytes");
  });
});
