import type { Direction, Role, Side } from "./manifest.js";
import type { ResolvedRoute } from "./resolve.js";
import type { Parameter, SubjectTemplate } from "./subject.js";

/** One broker permission a route grants to a role. */
export interface GrantSpec {
  readonly role: Role;
  readonly direction: Direction;
  readonly endpoint: SubjectTemplate;
  /** Whether the final transfer capture of a bounded update becomes a wildcard. */
  readonly transferToken: boolean;
  /** Identities a subscriber may wildcard, from the event subscription projection. */
  readonly wildcardParameters: readonly Parameter[];
}

/**
 * Derives the permission of each manifest grant, in manifest order, from the endpoint its channel
 * and side select. Throws when a grant names a channel the flow lacks or an endpoint outside the
 * route scope.
 */
export function routeGrants(route: ResolvedRoute): GrantSpec[] {
  const { flow } = route;
  return route.grants.map((grant): GrantSpec => {
    if (flow.kind === "event" && grant.channel === "event") {
      const endpoint = flow.addresses.get(grant.side);
      if (!endpoint) {
        throw new Error(`missing ${grant.side} endpoint`);
      }
      return {
        role: grant.role,
        direction: grant.direction,
        endpoint: endpoint.subject,
        transferToken: false,
        wildcardParameters: grant.direction === "subscribe" ? endpoint.subscriptionWildcards : [],
      };
    }
    let addresses;
    let transferToken = false;
    if (grant.channel === "request" && flow.kind !== "event") {
      addresses = flow.requests;
    } else if (grant.channel === "updates" && flow.kind === "watch") {
      addresses = flow.updates.addresses;
    } else if (grant.channel === "updates" && flow.kind === "bounded_watch") {
      addresses = flow.updates;
      transferToken = true;
    } else {
      throw new Error(`invalid grant channel ${grant.channel}`);
    }
    const endpoint = addresses.get(grant.side);
    if (!endpoint) {
      throw new Error(`missing ${grant.side} endpoint`);
    }
    endpoint.validateScope(route.scope, transferToken);
    return {
      role: grant.role,
      direction: grant.direction,
      endpoint,
      transferToken,
      wildcardParameters: [],
    };
  });
}

/** Whether a side runs inside a backend component rather than a panel or service. */
export function isRuntimeSide(side: Side): boolean {
  return side === "backend" || side === "backend_internal";
}
