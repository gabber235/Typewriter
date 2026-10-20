import { parse } from "yaml";
import { z } from "zod";

import type { Manifest } from "./manifest.js";
import { routeChannels } from "./subject.js";

/**
 * Lists the exact NATS core subjects each backend component serves only to other components: the
 * requests of routes whose server is the component and whose callers are all components. Such a
 * request has a bare address without placeholders.
 */
export function componentSubscriptions(manifest: Manifest): Map<string, Set<string>> {
  const subscriptions = new Map<string, Set<string>>();
  for (const route of manifest.routes) {
    if ("publishers" in route || !("component" in route.server)) {
      continue;
    }
    if (!route.callers.every((party) => "component" in party)) {
      continue;
    }
    const [request] = routeChannels(route, manifest.roles);
    const subject = request?.subjects.internal;
    if (!subject || subject.tokens.some((token) => token.kind === "parameter")) {
      throw new Error(`component route ${route.name} must request one exact subject`);
    }
    const values = subscriptions.get(route.server.component) ?? new Set<string>();
    subscriptions.set(route.server.component, values);
    values.add(subject.toString());
  }
  return subscriptions;
}

const WorkloadDeployment = z.object({
  metadata: z.object({ name: z.string().min(1) }),
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

/** The NATS core subscriptions of a component deployment and the queue group they must use. */
export interface DeploymentSubscriptions {
  /** `typewriter.` followed by the workload name. */
  readonly group: string;
  /** The comma separated `subject:group` entries of the NATS host interface. */
  readonly subscriptions: string;
}

/** Reads the single `core-subscriptions` value of the NATS host interface of a deployment. */
export function deploymentSubscriptions(source: string): DeploymentSubscriptions {
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
  return { group: `typewriter.${parsed.data.metadata.name}`, subscriptions: values[0]! };
}

/**
 * Fails unless a component's deployed NATS core subscriptions are exactly the subjects the
 * manifest has it serve to other components, each in the deployment's queue group, without
 * duplicates.
 */
export function validateComponentSubscriptions(
  manifest: Manifest,
  component: string,
  deployed: DeploymentSubscriptions,
): void {
  const subjects = componentSubscriptions(manifest).get(component);
  if (!subjects) {
    throw new Error(`component ${JSON.stringify(component)} has no canonical subscriptions`);
  }
  const expected = new Set([...subjects].map((subject) => `${subject}:${deployed.group}`));
  const values = deployed.subscriptions.split(",").filter((value) => value.length > 0);
  const actual = new Set(values);
  if (actual.size !== values.length) {
    throw new Error(`duplicate component subscription for ${component}`);
  }
  const sorted = (set: Set<string>) => JSON.stringify([...set].sort());
  if (sorted(actual) !== sorted(expected)) {
    throw new Error(
      `component subscription drift for ${component}: ` +
        `expected ${sorted(expected)}, received ${sorted(actual)}`,
    );
  }
}
