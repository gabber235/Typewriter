import { REPLY_INBOX, type ReplyInboxValue } from "./grants.js";
import type { Party, RoleDeclarations, ScopeKind } from "./manifest.js";
import { scopeParameters, type Parameter } from "./subject.js";

/**
 * One reply inbox shape a server answers on: the {@link REPLY_INBOX} root, the identity values of the
 * caller side and one reply token. An identity the route scope names for its caller is bound to that
 * scope value, so the server answers only that caller; every other value is any single token.
 */
export interface ReplyInbox {
  readonly side: "panel" | "service";
  /** The scope parameters bound in this shape, by the identity value they bind. */
  readonly bound: readonly Parameter[];
}

/** The scope parameter of an identity value: reply inbox values that name a subject identity. */
export const IDENTITY_PARAMETERS: Partial<Record<ReplyInboxValue, Parameter>> = {
  user: "user",
  service: "service",
};

/**
 * Derives the reply inboxes a route's server may answer on from its callers, in caller order without
 * duplicates. A request names its reply subject, and the server holds a response permission, so a
 * server that answered any subject would publish where the requester may not. A role caller replies
 * on its side's inbox; its personal identity is bound when the route scope names it. Component
 * callers add none: their reply subjects belong to the wasmCloud host, and no service serves them.
 */
export function replyInboxes(
  callers: readonly Party[],
  scope: ScopeKind,
  roles: RoleDeclarations,
): ReplyInbox[] {
  const inScope = new Set<Parameter>(scopeParameters(scope));
  const shapes = new Map<string, ReplyInbox>();
  for (const caller of callers) {
    const role = "role" in caller ? roles.get(caller.role) : undefined;
    if (!role) {
      continue;
    }
    const bound = REPLY_INBOX[role.side].flatMap((value) => {
      const parameter = IDENTITY_PARAMETERS[value];
      return parameter && parameter === role.personal && inScope.has(parameter) ? [parameter] : [];
    });
    const shape: ReplyInbox = { side: role.side, bound };
    shapes.set(replyInboxText(shape), shape);
  }
  return [...shapes.values()];
}

/** Renders a shape as `_INBOX.{user}.*.*`: bound identities in braces, every other token `*`. */
export function replyInboxText({ side, bound }: ReplyInbox): string {
  const values = REPLY_INBOX[side].map((value) => {
    const parameter = IDENTITY_PARAMETERS[value];
    return parameter && bound.includes(parameter) ? `{${parameter}}` : "*";
  });
  return [REPLY_INBOX.root, ...values, "*"].join(".");
}
