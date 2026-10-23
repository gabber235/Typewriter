import type { RouteChannel, SubjectTemplate } from "./subject.js";

/** A route with its derived channels, as route resolution and `routeChannels` produce them. */
export interface RoutedChannels {
  readonly name: string;
  readonly channels: readonly RouteChannel[];
}

/** One subject a backend component receives, with the route and channel it belongs to. */
export interface ServedSubject {
  readonly route: string;
  readonly channel: "request" | "event";
  readonly subject: SubjectTemplate;
}

/** The subscription a NATS subject template needs: every capture becomes a `*` token. */
export function subscriptionSubject(subject: SubjectTemplate): string {
  return subject.tokens.map((token) => (token.kind === "literal" ? token.value : "*")).join(".");
}

/** Whether one concrete subject could match both templates. */
function overlaps(first: SubjectTemplate, second: SubjectTemplate): boolean {
  return (
    first.tokens.length === second.tokens.length &&
    first.tokens.every((token, index) => {
      const other = second.tokens[index]!;
      return token.kind !== "literal" || other.kind !== "literal" || token.value === other.value;
    })
  );
}

/**
 * Lists the subjects each backend component receives, in manifest order: the requests of the
 * routes it serves and the events it subscribes to, each with its bridged backend subject before
 * its direct internal one. Updates are never received by components. Components that receive
 * nothing are absent.
 *
 * Every received message must match exactly one subject of its component, so the generated
 * dispatcher and subscriptions stay unambiguous. Throws when two subjects of one component
 * overlap, naming both routes.
 */
export function servedSubjects(routes: readonly RoutedChannels[]): Map<string, ServedSubject[]> {
  const served = new Map<string, ServedSubject[]>();
  for (const route of routes) {
    for (const { kind, receivers, subjects } of route.channels) {
      if (kind === "updates") {
        continue;
      }
      for (const receiver of receivers) {
        if (!("component" in receiver)) {
          continue;
        }
        const entries = served.get(receiver.component) ?? [];
        served.set(receiver.component, entries);
        for (const subject of [subjects.backend, subjects.internal]) {
          if (!subject) {
            continue;
          }
          const clash = entries.find((entry) => overlaps(entry.subject, subject));
          if (clash) {
            throw new Error(
              `component ${receiver.component} receives overlapping subjects ${clash.subject} ` +
                `of route ${clash.route} and ${subject} of route ${route.name}`,
            );
          }
          entries.push({ route: route.name, channel: kind, subject });
        }
      }
    }
  }
  return served;
}
