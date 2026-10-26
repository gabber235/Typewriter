import { describe, expect, test } from "bun:test";
import { parse } from "yaml";

import {
  orphanedSubscriptionFiles,
  subscriptionConfigMaps,
  SUBSCRIPTIONS_FILE,
} from "../src/routes/subscriptions.js";
import { parseManifest } from "../src/routes/manifest.js";
import { resolveRoutes } from "../src/routes/resolve.js";
import { committedRoutes, loadSkirInput, manifestSource } from "./support.js";

const { resolved } = await committedRoutes();

/** A manifest where one component serves a route another component calls. */
async function permissionRoute() {
  const source = manifestSource(
    `  - name: permission_resolve
    scope: internal_component
    callers: [{ component: auth-callout }]
    server: { component: auth-typewriter-permissions }
    flow:
      kind: unary
      method: "access/v1/permission.skir:GetEntityPermission"
      operation: auth.permissions.panel
      request: auth.permissions.typewriter-panel
`,
    ["auth-callout", "auth-typewriter-permissions"],
  );
  return resolveRoutes(parseManifest(source, "routes.yaml"), await loadSkirInput());
}

/** The component whose deploy/base directory holds `path`. */
const componentOf = (path: string) => path.split("/").at(-4)!;

/** A WorkloadDeployment named after its component whose NATS host interface loads `configFrom`. */
function deployment(component: string, configFrom = `${component}-nats-subscriptions`): string {
  return `apiVersion: runtime.wasmcloud.dev/v1alpha1
kind: WorkloadDeployment
metadata:
  name: ${component}
  namespace: typewriter
spec:
  template:
    spec:
      hostInterfaces:
        - namespace: wasmcloud
          package: nats
          configFrom:
            - name: ${configFrom}
`;
}

const kustomization = (resources: readonly string[]) =>
  `resources:\n${resources.map((resource) => `  - ${resource}\n`).join("")}`;

/** Reads a well formed deploy/base directory of every component. */
function repository(path: string): string {
  return path.endsWith("/kustomization.yaml")
    ? kustomization(["workloaddeployment.yaml", SUBSCRIPTIONS_FILE])
    : deployment(componentOf(path));
}

describe("subscription ConfigMaps", () => {
  test("only a component that receives messages gets a ConfigMap in its deploy/base directory", async () => {
    const read: string[] = [];
    const files = subscriptionConfigMaps(await permissionRoute(), (path) => {
      read.push(path);
      return repository(path);
    });
    expect(files.map((file) => file.path)).toEqual([
      `backend/auth-typewriter-permissions/deploy/base/${SUBSCRIPTIONS_FILE}`,
    ]);
    expect(read.some((path) => path.includes("/auth-callout/"))).toBe(false);
  });

  test("lists each dispatched subject in the workload's queue group", async () => {
    const [permissions] = subscriptionConfigMaps(await permissionRoute(), repository);
    const configMap = parse(permissions!.code);
    expect(configMap.metadata.name).toBe("auth-typewriter-permissions-nats-subscriptions");
    expect(configMap.data).toEqual({
      "core-subscriptions": "auth.permissions.typewriter-panel:typewriter.auth-typewriter-permissions",
    });
  });

  test("rejects a deployment without valid workload metadata", () => {
    expect(() => subscriptionConfigMaps(resolved, () => "metadata: {}\n")).toThrow(
      "backend/organization/user-organization/deploy/base/workloaddeployment.yaml: invalid WorkloadDeployment",
    );
  });

  test("rejects a deployment whose NATS host interface does not load the ConfigMap", () => {
    const read = (path: string) =>
      path.endsWith("workloaddeployment.yaml") ? deployment(componentOf(path), "other") : repository(path);
    expect(() => subscriptionConfigMaps(resolved, read)).toThrow(
      "user-organization/deploy/base/workloaddeployment.yaml: the wasmcloud:nats host interface does not load configFrom user-organization-nats-subscriptions",
    );
  });

  test("rejects a kustomization that does not list the generated file", () => {
    const read = (path: string) =>
      path.endsWith("kustomization.yaml") ? kustomization(["workloaddeployment.yaml"]) : repository(path);
    expect(() => subscriptionConfigMaps(resolved, read)).toThrow(
      `user-organization/deploy/base/kustomization.yaml: resources do not list ${SUBSCRIPTIONS_FILE}`,
    );
  });

  test("finds the files of components that no longer receive messages", () => {
    const files = subscriptionConfigMaps(resolved, repository);
    const stale = `backend/access/auth-callout/deploy/base/${SUBSCRIPTIONS_FILE}`;
    expect(orphanedSubscriptionFiles(files, [...files.map((file) => file.path), stale])).toEqual([stale]);
  });
});
