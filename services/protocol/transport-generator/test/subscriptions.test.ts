import { describe, expect, test } from "bun:test";

import {
  componentSubscriptions,
  deploymentSubscriptions,
  validateComponentSubscriptions,
} from "../src/routes/subscriptions.js";
import { committedManifest } from "./support.js";

function deployment(hostInterfaces: string): string {
  return `spec:\n  template:\n    spec:\n      hostInterfaces:\n${hostInterfaces}`;
}

const NATS = (subscriptions: string) =>
  `        - namespace: wasmcloud\n          package: nats\n          config:\n            core-subscriptions: ${subscriptions}\n`;

describe("component subscriptions", () => {
  test("reads one typed NATS subscription value", () => {
    expect(deploymentSubscriptions(deployment(NATS("one:group,two:group")))).toBe("one:group,two:group");
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

  test("the manifest owns the permission component subscriptions exactly", () => {
    const manifest = committedManifest();
    expect(componentSubscriptions(manifest)).toEqual(
      new Map([
        [
          "auth-typewriter-permissions",
          new Set([
            "auth.permissions.typewriter-panel:typewriter.auth-auth-typewriter-permissions",
            "auth.permissions.typewriter-services:typewriter.auth-auth-typewriter-permissions",
          ]),
        ],
      ]),
    );
    validateComponentSubscriptions(
      manifest,
      "auth-typewriter-permissions",
      "auth.permissions.typewriter-panel:typewriter.auth-auth-typewriter-permissions,auth.permissions.typewriter-services:typewriter.auth-auth-typewriter-permissions",
    );
    expect(() =>
      validateComponentSubscriptions(
        manifest,
        "auth-typewriter-permissions",
        "auth.permissions.*:typewriter.auth-auth-typewriter-permissions",
      ),
    ).toThrow("component subscription drift");
    expect(() => validateComponentSubscriptions(manifest, "unknown-component", "")).toThrow(
      "has no canonical subscriptions",
    );
  });
});
