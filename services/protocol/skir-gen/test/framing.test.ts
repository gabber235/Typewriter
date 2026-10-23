import { describe, expect, test } from "bun:test";

import { parseManifest } from "../src/routes/manifest.js";
import { resolveRoutes } from "../src/routes/resolve.js";
import { responseLimit, sideResponseLimit } from "../src/routes/responses.js";
import { committedRoutes, EMPTY_INPUT, manifestSource } from "./support.js";

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

const resolveSource = (routes: string) =>
  resolveRoutes(parseManifest(manifestSource(routes, ["user-organization"]), "routes.yaml"), EMPTY_INPUT);

describe("payload ceilings", () => {
  test("only the blob routes raise a ceiling, each in its own direction", async () => {
    const { resolved } = await committedRoutes();
    const raised = resolved.routes
      .filter(
        (route) =>
          route.limits.requestMaxBytes !== resolved.limits.requestMaxBytes ||
          route.limits.replyMaxBytes !== resolved.limits.replyMaxBytes,
      )
      .map((route) => [route.name, route.limits.requestMaxBytes / MIB, route.limits.replyMaxBytes / MIB]);
    expect(raised).toEqual([
      ["shared_blob_fetch", 0.5, 128],
      ["shared_blob_store", 128, 32],
    ]);
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
  test("the Realm coordinator may send every frame of the largest blob it serves", async () => {
    const { resolved } = await committedRoutes();
    expect(responseLimit("realm_coordinator", resolved.routes)).toBe((128 * MIB) / (512 * 1024));
    expect(sideResponseLimit("service", resolved.roles, resolved.routes)).toBe(256);
  });

  test("a panel connection may grant one credit per window end of a framed reply", async () => {
    const { resolved } = await committedRoutes();
    expect(responseLimit("organization_member", resolved.routes)).toBe(1);
    expect(sideResponseLimit("panel", resolved.roles, resolved.routes)).toBe(1);
  });
});
