import { describe, expect, test } from "bun:test";

import legacy from "./fixtures/legacy-transport-routes.json" with { type: "json" };
import { grantText } from "../src/routes/grants.js";
import { committedRoutes } from "./support.js";

/**
 * One off proof for the logical address rewrite: the fixture holds every subject and grant the
 * previous manifest produced with the previous generator. Applying exactly the intended, named
 * differences to it must yield what the derived subject and grant rules produce now.
 */

interface RouteFacts {
  scope: string;
  operation: string;
  failureSlug: string;
  subjects: Record<string, string[]>;
  grants: string[];
}

/** Bare internal subjects no component requested; only the bridged subjects stay. */
const UNUSED_INTERNAL_SUBJECTS = [
  "service.{service}.registration.ensure",
  "service.{service}.execution.register",
  "service.{service}.execution.watch",
  "service.{service}.execution.report",
  "service.{service}.heartbeat",
  "service.{service}.shutdown",
];

/** The rollout host subjects move onto the realm mesh. */
const HOSTS_SUBJECTS: Record<string, string> = {
  "typewriter.organization.{organization}.realm.{realm}.hosts.probe":
    "service.from.{realm}.organization.{organization}.realm.rollout.probe",
  "typewriter.organization.{organization}.realm.{realm}.hosts.command":
    "service.from.{realm}.organization.{organization}.realm.rollout.command",
  "typewriter.organization.{organization}.realm.{realm}.hosts.status":
    "service.from.{realm}.organization.{organization}.realm.rollout.status",
  "typewriter.organization.{organization}.realm.{realm}.hosts.state":
    "service.to.{realm}.organization.{organization}.realm.rollout.state",
};

/** Failure slugs now derived from the operation name. */
const SLUG_RENAMES: Record<string, string> = {
  "user-organizations-watch-failed": "user-organization-watch-failed",
  "user-join-requests-watch-failed": "user-organization-join-requests-watch-failed",
  "user-join-request-submit-failed": "user-organization-join-requests-request-failed",
  "user-join-request-cancel-failed": "user-organization-join-requests-cancel-failed",
  "organization-member-remove-failed": "organization-members-remove-failed",
  "organization-join-requests-watch-failed": "organization-members-join-requests-watch-failed",
  "organization-join-requests-approve-failed": "organization-members-join-requests-approve-failed",
  "organization-join-request-decline-failed": "organization-members-join-requests-decline-failed",
  "organization-join-codes-watch-failed": "organization-members-join-codes-watch-failed",
  "organization-join-code-generate-failed": "organization-members-join-codes-generate-failed",
  "organization-join-code-revoke-failed": "organization-members-join-codes-revoke-failed",
  "organization-service-bind-failed": "organization-services-bind-failed",
  "organization-service-update-failed": "organization-services-update-failed",
  "organization-service-unbind-failed": "organization-services-unbind-failed",
  "resource-operations-resolve-failed": "editor-resources-operations-resolve-failed",
  "resource-drop-candidates-resolve-failed": "editor-resources-drops-resolve-failed",
  "authoring-action-prepare-failed": "editor-resources-actions-prepare-failed",
  "realm-host-probe-failed": "realm-hosts-probe-failed",
  "realm-host-status-failed": "realm-hosts-status-failed",
  "auth-panel-permissions-failed": "auth-permissions-panel-failed",
  "auth-services-permissions-failed": "auth-permissions-services-failed",
};

/** Persistent projections whose plain subscription becomes named consumer operations. */
const PERSISTENT_PROJECTIONS: Record<string, string> = {
  user_organizations_watch: "user_organizations_changed",
  user_join_requests_watch: "user_join_requests_changed",
  organization_members_watch: "organization_members_changed",
  organization_join_requests_watch: "organization_join_requests_changed",
  organization_join_codes_watch: "organization_join_codes_changed",
};

function consumerGrants(role: string, filter: string, projection: string): string[] {
  const stream = "TYPEWRITER_MEMBERSHIP";
  const consumer = `{consumer:${projection}}`;
  return [
    `$JS.API.STREAM.INFO.${stream}`,
    `$JS.API.CONSUMER.CREATE.${stream}.${consumer}.${filter}`,
    `$JS.API.CONSUMER.INFO.${stream}.${consumer}`,
    `$JS.API.CONSUMER.MSG.NEXT.${stream}.${consumer}`,
    `$JS.API.CONSUMER.DELETE.${stream}.${consumer}`,
  ].map((subject) => `${role} publish ${subject}`);
}

function expected(name: string, facts: RouteFacts): RouteFacts {
  const moved = (subject: string) => HOSTS_SUBJECTS[subject] ?? subject;
  const subjects = Object.fromEntries(
    Object.entries(facts.subjects).map(([channel, values]) => [
      channel,
      values
        .filter((subject) => !UNUSED_INTERNAL_SUBJECTS.includes(subject))
        .map(moved)
        .sort(),
    ]),
  );
  const grants = facts.grants.flatMap((grant) => {
    const [role, direction, subject] = grant.split(" ") as [string, string, string];
    const projection = PERSISTENT_PROJECTIONS[name];
    if (projection && direction === "subscribe") {
      return consumerGrants(role, subject, projection);
    }
    let derived = moved(subject);
    if (facts.scope === "realm" && role === "organization_member") {
      derived = derived.replace(/^service\.(to|from)\.\{realm\}\./u, "service.$1.*.");
    }
    return [`${role} ${direction} ${derived}`];
  });
  return {
    ...facts,
    failureSlug: SLUG_RENAMES[facts.failureSlug] ?? facts.failureSlug,
    subjects,
    grants: grants.sort(),
  };
}

describe("logical address parity", () => {
  test("every route keeps its subjects and grants except the named differences", async () => {
    const { routes } = await committedRoutes();
    const derived = Object.fromEntries(
      routes.map((route): [string, RouteFacts] => [
        route.name,
        {
          scope: route.scope,
          operation: route.operation,
          failureSlug: route.failureSlug,
          subjects: Object.fromEntries(
            route.channels.map((channel) => [
              channel.kind,
              Object.values(channel.subjects)
                .map((subject) => subject.toString())
                .sort(),
            ]),
          ),
          grants: route.grants
            .map((grant) => `${grant.role} ${grant.direction} ${grantText(grant.tokens)}`)
            .sort(),
        },
      ]),
    );
    const previous = legacy as Record<string, RouteFacts>;
    expect(Object.keys(derived)).toEqual(Object.keys(previous));
    for (const [name, facts] of Object.entries(previous)) {
      expect({ name, ...derived[name]! }).toEqual({ name, ...expected(name, facts) });
    }
  });
});
