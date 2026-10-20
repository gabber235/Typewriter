import { describe, expect, test } from "bun:test";

import { parseManifest, symbolRefText } from "../src/routes/manifest.js";
import { SubjectTemplate } from "../src/routes/subject.js";
import { committedManifest } from "./support.js";

const route = (flow: string) => `
routes:
  - name: sample_route
    scope: user
    grants: []
    flow:
${flow}`;

describe("manifest admission", () => {
  test("parses the complete route inventory", () => {
    const manifest = committedManifest();
    expect(manifest.routes).toHaveLength(65);
    const methods = new Set<string>();
    const payloads = new Set<string>();
    for (const { flow } of manifest.routes) {
      if (flow.kind === "unary" || flow.kind === "watch" || flow.kind === "bounded_watch") {
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

  test("resource operation routes preserve subjects and role grants", () => {
    const manifest = committedManifest();
    for (const [name, method, subject, operation, failure] of [
      [
        "resource_operations_resolve",
        "ResolveResourceOperations",
        "service.to.{realm}.organization.{organization}.realm.editor.resources.operations.resolve",
        "editor.resources.operations.resolve",
        "resource-operations-resolve-failed",
      ],
      [
        "resource_drop_candidates_resolve",
        "ResolveDropCandidates",
        "service.to.{realm}.organization.{organization}.realm.editor.resources.drops.resolve",
        "editor.resources.drops.resolve",
        "resource-drop-candidates-resolve-failed",
      ],
      [
        "authoring_action_prepare",
        "PrepareAuthoringAction",
        "service.to.{realm}.organization.{organization}.realm.editor.resources.actions.prepare",
        "editor.resources.actions.prepare",
        "authoring-action-prepare-failed",
      ],
    ] as const) {
      const route = manifest.routes.find((candidate) => candidate.name === name)!;
      expect(route.scope).toBe("realm");
      expect(route.subscription).toBeUndefined();
      expect(route.flow.kind).toBe("unary");
      if (route.flow.kind !== "unary") {
        continue;
      }
      expect(route.flow.method).toEqual({ module: "editor/v1/resource_operations.skir", path: [method] });
      expect(route.flow.operation).toBe(operation);
      expect(route.flow.failure_slug).toBe(failure);
      expect(new Map([...route.flow.requests].map(([side, value]) => [side, value.toString()]))).toEqual(
        new Map([
          ["panel", SubjectTemplate.parse(subject).toString()],
          ["service", subject],
        ]),
      );
      expect(route.grants).toEqual([
        { role: "organization_member", side: "panel", channel: "request", direction: "publish" },
        { role: "realm_coordinator", side: "service", channel: "request", direction: "subscribe" },
      ]);
    }
  });

  test("rejects duplicate endpoint keys", () => {
    const source = route(`      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: duplicate.endpoint
      failure_slug: duplicate-endpoint-failed
      requests:
        panel: "cloud.to.user.{user}.one"
        panel: "cloud.to.user.{user}.two"
`);
    expect(() => parseManifest(source, "routes.yaml")).toThrow("routes.yaml: Map keys must be unique");
  });

  test("names the YAML path and line of an invalid value", () => {
    const source = route(`      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: invalid.subject
      failure_slug: invalid-subject-failed
      requests:
        panel: "cloud.to.*"
`);
    expect(() => parseManifest(source, "routes.yaml")).toThrow(
      'routes.yaml:12:16: routes[0].flow.requests.panel: invalid subject token "*"',
    );
  });

  test("rejects unknown fields and unsupported native targets", () => {
    expect(() =>
      parseManifest(
        route(`      kind: unary
      method: "organization/v1/user.skir:WatchUserOrganizations"
      operation: unknown.field
      failure_slug: unknown-field-failed
      requests: { panel: "cloud.to.user.{user}" }
      exposure: public
`),
        "routes.yaml",
      ),
    ).toThrow("routes[0].flow");
    expect(() =>
      parseManifest(
        route(`      kind: scatter
      binding: { kind: native_kotlin, format: kotlin_serialization_cbor, target: panel, request_type: a.B, response_type: a.C, request_codec: a.D.e, response_codec: a.D.f }
      operation: native.target
      failure_slug: native-target-failed
      requests: { service: "cloud.to.user.{user}" }
`),
        "routes.yaml",
      ),
    ).toThrow('unsupported Kotlin generator target "panel"');
  });

  test("rejects malformed Skir references", () => {
    expect(() =>
      parseManifest(
        route(`      kind: unary
      method: "../user.skir:WatchUserOrganizations"
      operation: invalid.reference
      failure_slug: invalid-reference-failed
      requests: { panel: "cloud.to.user.{user}" }
`),
        "routes.yaml",
      ),
    ).toThrow('invalid canonical module path "../user.skir"');
  });
});
