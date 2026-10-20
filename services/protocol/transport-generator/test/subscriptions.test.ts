import { describe, expect, test } from "bun:test";

import {
  componentSubscriptions,
  deploymentSubscriptions,
  validateComponentSubscriptions,
} from "../src/routes/subscriptions.js";
import { committedManifest } from "./support.js";

function deployment(hostInterfaces: string): string {
  return `metadata:\n  name: auth-sample\nspec:\n  template:\n    spec:\n      hostInterfaces:\n${hostInterfaces}`;
}

const NATS = (subscriptions: string) =>
  `        - namespace: wasmcloud\n          package: nats\n          config:\n            core-subscriptions: ${subscriptions}\n`;

const GROUP = "typewriter.auth-auth-typewriter-permissions";

describe("component subscriptions", () => {
  test("reads one typed NATS subscription value and the workload group", () => {
    expect(deploymentSubscriptions(deployment(NATS("one:group,two:group")))).toEqual({
      group: "typewriter.auth-sample",
      subscriptions: "one:group,two:group",
    });
  });

  test("rejects malformed, missing and duplicate subscription values", () => {
    expect(() => deploymentSubscriptions("spec: [invalid]")).toThrow("invalid deployment YAML");
    expect(() =>
      deploymentSubscriptions(deployment("        - namespace: wasi\n          package: otel\n")),
    ).toThrow("deployment has no NATS core-subscriptions value");
    expect(() => deploymentSubscriptions(deployment(NATS("one:group") + NATS("two:group")))).toThrow(
      "deployment has duplicate NATS core-subscriptions values",
    );
  });

  test("the manifest owns the subjects a component serves to other components", () => {
    const manifest = committedManifest();
    expect(componentSubscriptions(manifest)).toEqual(
      new Map([
        [
          "auth-typewriter-permissions",
          new Set(["auth.permissions.typewriter-panel", "auth.permissions.typewriter-services"]),
        ],
      ]),
    );
    validateComponentSubscriptions(manifest, "auth-typewriter-permissions", {
      group: GROUP,
      subscriptions: `auth.permissions.typewriter-panel:${GROUP},auth.permissions.typewriter-services:${GROUP}`,
    });
    for (const subscriptions of [
      `auth.permissions.*:${GROUP}`,
      `auth.permissions.typewriter-panel:other,auth.permissions.typewriter-services:other`,
    ]) {
      expect(() =>
        validateComponentSubscriptions(manifest, "auth-typewriter-permissions", { group: GROUP, subscriptions }),
      ).toThrow("component subscription drift");
    }
    expect(() =>
      validateComponentSubscriptions(manifest, "unknown-component", { group: GROUP, subscriptions: "" }),
    ).toThrow("has no canonical subscriptions");
  });
});
