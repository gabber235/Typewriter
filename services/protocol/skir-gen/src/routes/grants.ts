import type { Direction, Party, RoleDeclaration, RoleDeclarations } from "./manifest.js";
import type { RouteChannel, SubjectTemplate, SubjectToken } from "./subject.js";

/**
 * One token of a granted subject: a literal, an identifier the grantee is bound to, a single token
 * wildcard, or the grantee connection's consumer name for a persistent projection.
 */
export type GrantToken =
  | SubjectToken
  | { readonly kind: "wildcard" }
  | { readonly kind: "consumer"; readonly projection: string };

/** One broker permission a route grants to a role. */
export interface Grant {
  readonly role: string;
  readonly direction: Direction;
  readonly tokens: readonly GrantToken[];
}

/**
 * The identity of a connection's persistent projection consumer: the prefix followed by the
 * unpadded URL safe Base64 of the compact JSON tuple of these values, in order. The organization
 * is null for grantees without an organization tenant. Emitted into Rust and Dart, so the backend
 * grant and the panel consumer always agree.
 */
export const CONSUMER_NAME = {
  prefix: "TW_",
  tuple: ["actor", "organization", "session", "projection"],
} as const;

/**
 * The reply inbox prefix of a requester on each side: the root followed by these identity values,
 * dot separated, such as `_INBOX.{user}.{session}`. A requester's reply inboxes are single tokens
 * below its prefix, and the backend grants each connection the subscription to exactly those.
 * Emitted into Rust, Dart and Kotlin, so the grant and the clients' inboxes always agree.
 */
export const REPLY_INBOX = {
  root: "_INBOX",
  panel: ["user", "session"],
  service: ["service"],
} as const;

/** One identity value a reply inbox prefix holds. */
export type ReplyInboxValue = (typeof REPLY_INBOX)["panel" | "service"][number];

/** Renders a grant as `service.to.*.organization.{organization}.realm.editor.catalog.fetch`. */
export function grantText(tokens: readonly GrantToken[]): string {
  return tokens
    .map((token) => {
      switch (token.kind) {
        case "literal":
          return token.value;
        case "parameter":
          return `{${token.parameter}}`;
        case "wildcard":
          return "*";
        case "consumer":
          return `{consumer:${token.projection}}`;
      }
    })
    .join(".");
}

/**
 * Binds the identifiers a role is admitted for; every other placeholder becomes a single token
 * wildcard. A personal identifier in an event names its publisher, so a role subscribing to other
 * publishers' events receives every publisher in its tenant. Route path tokens always stay
 * literal, so a grant never covers an undeclared route and never ends in `>`.
 */
export function grantSubject(
  subject: SubjectTemplate,
  role: RoleDeclaration,
  receivesOthersEvents: boolean,
): GrantToken[] {
  const bound = new Set<string>(role.tenant);
  if (role.personal && !receivesOthersEvents) {
    bound.add(role.personal);
  }
  return subject.tokens.map((token) =>
    token.kind === "parameter" && !bound.has(token.parameter) ? { kind: "wildcard" } : token,
  );
}

const literals = (value: string): GrantToken[] =>
  value.split(".").map((part) => ({ kind: "literal", value: part }));

/**
 * Grants a role the named JetStream consumer operations of a persistent channel instead of a plain
 * subscription. The consumer filter is the channel subject bound like any other grant.
 */
export function persistentConsumerGrants(
  channel: RouteChannel,
  role: RoleDeclaration,
): Grant[] {
  const { delivery, subjects } = channel;
  if (delivery?.kind !== "persistent" || !subjects.client) {
    throw new Error(`role ${role.name} receives no persistent client channel`);
  }
  if (!role.personal) {
    throw new Error(`persistent consumers of role ${role.name} need a personal identifier`);
  }
  const { stream, projection } = delivery;
  const consumer: GrantToken = { kind: "consumer", projection };
  const filter = grantSubject(subjects.client, role, false);
  return [
    [...literals(`$JS.API.STREAM.INFO.${stream}`)],
    [...literals(`$JS.API.CONSUMER.CREATE.${stream}`), consumer, ...filter],
    [...literals(`$JS.API.CONSUMER.INFO.${stream}`), consumer],
    [...literals(`$JS.API.CONSUMER.MSG.NEXT.${stream}`), consumer],
    [...literals(`$JS.API.CONSUMER.DELETE.${stream}`), consumer],
  ].map((tokens) => ({ role: role.name, direction: "publish", tokens }));
}

const roleOf = (party: Party, roles: RoleDeclarations): RoleDeclaration | undefined =>
  "role" in party ? roles.get(party.role) : undefined;

/**
 * Derives every broker permission of a route's channels, in channel and party order: publishers
 * publish, receivers subscribe, and receivers of a persistent channel get its consumer operations.
 * Components get no grants; their subscriptions belong to their deployment.
 */
export function routeGrants(channels: readonly RouteChannel[], roles: RoleDeclarations): Grant[] {
  const grants: Grant[] = [];
  for (const channel of channels) {
    const subject = channel.subjects.client;
    for (const party of channel.publishers) {
      const role = roleOf(party, roles);
      if (role && subject) {
        const tokens = grantSubject(subject, role, false);
        grants.push({ role: role.name, direction: "publish", tokens });
      }
    }
    for (const party of channel.receivers) {
      const role = roleOf(party, roles);
      if (!role || !subject) {
        continue;
      }
      if (channel.delivery?.kind === "persistent") {
        grants.push(...persistentConsumerGrants(channel, role));
      } else {
        const tokens = grantSubject(subject, role, channel.kind === "event");
        grants.push({ role: role.name, direction: "subscribe", tokens });
      }
    }
  }
  return grants;
}
