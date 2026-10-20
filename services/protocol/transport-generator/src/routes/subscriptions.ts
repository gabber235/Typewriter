import { parse } from "yaml";
import { z } from "zod";

import type { Manifest } from "./manifest.js";

/**
 * Lists the NATS core subscriptions (`subject:group`) each backend component owns, from the internal
 * component routes of the manifest. Such a route must be unary and request one exact
 * `backend_internal` subject.
 */
export function componentSubscriptions(manifest: Manifest): Map<string, Set<string>> {
  const subscriptions = new Map<string, Set<string>>();
  for (const route of manifest.routes) {
    if (!route.subscription) {
      continue;
    }
    if (route.flow.kind !== "unary") {
      throw new Error(`component subscription ${route.name} must be unary`);
    }
    const subject = route.flow.requests.get("backend_internal");
    if (!subject) {
      throw new Error(`component subscription ${route.name} requires backend_internal`);
    }
    if (subject.tokens.some((token) => token.kind === "parameter")) {
      throw new Error(`component subscription ${route.name} must be exact`);
    }
    const values = subscriptions.get(route.subscription.component) ?? new Set<string>();
    subscriptions.set(route.subscription.component, values);
    const value = `${subject}:${route.subscription.group}`;
    if (values.has(value)) {
      throw new Error(`duplicate component subscription in ${route.name}`);
    }
    values.add(value);
  }
  return subscriptions;
}

const WorkloadDeployment = z.object({
  spec: z.object({
    template: z.object({
      spec: z.object({
        hostInterfaces: z.array(
          z.object({
            namespace: z.string(),
            package: z.string(),
            config: z.record(z.string(), z.string()).default({}),
          }),
        ),
      }),
    }),
  }),
});

/** Reads the single `core-subscriptions` value of the NATS host interface of a deployment. */
export function deploymentSubscriptions(source: string): string {
  const parsed = WorkloadDeployment.safeParse(parse(source));
  if (!parsed.success) {
    throw new Error(`invalid deployment YAML: ${parsed.error.message}`);
  }
  const values = parsed.data.spec.template.spec.hostInterfaces
    .filter((host) => host.namespace === "wasmcloud" && host.package === "nats")
    .flatMap((host) => {
      const value = host.config["core-subscriptions"];
      return value === undefined ? [] : [value];
    });
  if (values.length !== 1) {
    throw new Error(
      values.length === 0
        ? "deployment has no NATS core-subscriptions value"
        : "deployment has duplicate NATS core-subscriptions values",
    );
  }
  return values[0]!;
}

/**
 * Fails unless a component's deployed NATS core subscriptions equal the ones the manifest assigns
 * it, without duplicates.
 */
export function validateComponentSubscriptions(
  manifest: Manifest,
  component: string,
  actual: string,
): void {
  const expected = componentSubscriptions(manifest).get(component);
  if (!expected) {
    throw new Error(`component ${JSON.stringify(component)} has no canonical subscriptions`);
  }
  const values = actual.split(",").filter((value) => value.length > 0);
  const deployed = new Set(values);
  if (deployed.size !== values.length) {
    throw new Error(`duplicate component subscription for ${component}`);
  }
  const sorted = (set: Set<string>) => JSON.stringify([...set].sort());
  if (sorted(deployed) !== sorted(expected)) {
    throw new Error(
      `component subscription drift for ${component}: ` +
        `expected ${sorted(expected)}, received ${sorted(deployed)}`,
    );
  }
}
