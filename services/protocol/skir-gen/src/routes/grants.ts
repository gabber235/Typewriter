import type { BucketDeclaration, Direction, Party, RoleDeclaration, RoleDeclarations } from "./manifest.js";
import type { RouteChannel, SubjectTemplate, SubjectToken } from "./subject.js";

/**
 * One token of a granted subject: a literal, an identifier the grantee is bound to, a single token
 * wildcard, or the grantee connection's consumer name for a persistent projection.
 */
export type GrantToken =
  | SubjectToken
  | { readonly kind: "wildcard" }
  | { readonly kind: "consumer"; readonly projection: string }
  | { readonly kind: "bucket"; readonly name: string; readonly stream: boolean };

/**
 * The name of a realm's key value bucket, `<name>_<realm id>`, and of the JetStream stream that
 * holds it, `KV_<name>_<realm id>`. Emitted into Rust and Kotlin, so the grant and the bucket the
 * realm creates always agree.
 */
export const bucketName = (name: string, realm: string) => `${name}_${realm}`;

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
 * Emitted into Rust, Dart and Kotlin, so the grant and the clients' inboxes always agree, and the
 * Kotlin servers answer exactly these inboxes (see replies.ts).
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
        case "free":
          return `{${token.name}}`;
        case "wildcard":
          return "*";
        case "consumer":
          return `{consumer:${token.projection}}`;
        case "bucket":
          return `${token.stream ? "KV_" : ""}${bucketName(token.name, "{realm}")}`;
      }
    })
    .join(".");
}

/**
 * Binds the identifiers a role is admitted for; every other placeholder, free values included,
 * becomes a single token wildcard. A personal identifier in an event names its publisher, so a role subscribing to other
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
    token.kind === "free" || (token.kind === "parameter" && !bound.has(token.parameter)) ? { kind: "wildcard" } : token,
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

/**
 * The key filter that selects every key of [bucket]: one `*` per declared key token, the exact
 * shape its writers' grants allow, so a watch or listing of the whole bucket stays inside them.
 */
export function everyKeyFilter(bucket: BucketDeclaration): string {
  return bucket.key.map(() => "*").join(".");
}

/**
 * Derives the broker permissions of a realm key value bucket. Its writers open it, read and write
 * keys of exactly the declared tokens and list them through consumers on its stream; its owner also
 * creates it. Every subject but the owner's account info binds the realm, so a role reaches only its
 * own realm's bucket.
 */
export function bucketGrants(bucket: BucketDeclaration, roles: RoleDeclarations): Grant[] {
  const stream: GrantToken = { kind: "bucket", stream: true, name: bucket.name };
  const subjectRoot: GrantToken = { kind: "bucket", stream: false, name: bucket.name };
  const keys: GrantToken[] = bucket.key.map(() => ({ kind: "wildcard" }));
  const key: GrantToken[] = [...literals("$KV"), subjectRoot, ...keys];
  const consumer: GrantToken = { kind: "wildcard" };
  // The subjects the natskt key value client uses: stream info to open, direct get of a key's last
  // message (or the message get fallback), a filtered ephemeral consumer to list keys with its flow
  // control replies, and a publish per key write.
  const read: GrantToken[][] = [
    [...literals("$JS.API.STREAM.INFO"), stream],
    [...literals("$JS.API.DIRECT.GET"), stream, ...key],
    [...literals("$JS.API.STREAM.MSG.GET"), stream],
    [...literals("$JS.API.CONSUMER.CREATE"), stream, consumer, ...key],
    [...literals("$JS.API.CONSUMER.DELETE"), stream, consumer],
    [...literals("$JS.FC"), stream, { kind: "wildcard" }, { kind: "wildcard" }],
    key,
  ];
  // natskt reads the account's JetStream info before it creates a key value stream; the account
  // info subject carries no stream, so it is the one owner grant not bound to the realm.
  const own: GrantToken[][] = [[...literals("$JS.API.STREAM.CREATE"), stream], [...literals("$JS.API.INFO")]];
  const grant = (role: string, subjects: GrantToken[][]): Grant[] =>
    subjects.map((tokens) => ({ role, direction: "publish", tokens }));
  for (const name of [bucket.owner, ...bucket.writers]) {
    if (!roles.get(name)?.tenant.includes("realm")) {
      throw new Error(`bucket ${bucket.name} role ${name} is not bound to one realm`);
    }
  }
  return [
    ...grant(bucket.owner, [...own, ...read]),
    ...bucket.writers.flatMap((writer) => grant(writer, read)),
  ];
}
