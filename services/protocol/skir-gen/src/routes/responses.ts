import type { Party, RoleDeclarations } from "./manifest.js";
import { routeChannel, type ResolvedRoute } from "./resolve.js";

/**
 * How many messages a role may send in answer to one received request, or null when it never needs
 * to answer one.
 *
 * NATS limits responses per received request and per connection, not per route. A server answers
 * one request with up to ceil(reply_max_bytes / chunk_bytes) frames, so its role gets the largest
 * such count over the routes it serves. A requester answers each window end of a framed reply with
 * one credit, and each window end is a request of its own, so a role that calls a route whose replies
 * may be framed gets at least 1.
 */
export function responseLimit(role: string, routes: readonly ResolvedRoute[]): number | null {
  const requests = routes.flatMap((route) => {
    const channel = routeChannel(route, "request");
    return channel ? [{ channel, limits: route.limits }] : [];
  });
  const hasRole = (parties: readonly Party[]) => parties.some((party) => "role" in party && party.role === role);
  const frames = requests
    .filter(({ channel }) => hasRole(channel.receivers))
    .map(({ limits }) => Math.ceil(limits.replyMaxBytes / limits.chunkBytes));
  if (frames.length > 0) return Math.max(...frames);
  const framedCalls = requests.some(
    ({ channel, limits }) => hasRole(channel.publishers) && limits.replyMaxBytes > limits.chunkBytes,
  );
  return framedCalls ? 1 : null;
}

/**
 * The response limit of a connection on one side: the largest limit of the side's roles, since one
 * connection may hold several roles and NATS grants it one response permission.
 */
export function sideResponseLimit(
  side: "panel" | "service",
  roles: RoleDeclarations,
  routes: readonly ResolvedRoute[],
): number | null {
  const limits = [...roles.values()]
    .filter((role) => role.side === side)
    .flatMap((role) => {
      const limit = responseLimit(role.name, routes);
      return limit === null ? [] : [limit];
    });
  return limits.length > 0 ? Math.max(...limits) : null;
}
