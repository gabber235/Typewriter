import { describe, expect, test } from "bun:test";

import { bucketGrants, everyKeyFilter, grantSubject, grantText, routeGrants } from "../src/routes/grants.js";
import { parseManifest } from "../src/routes/manifest.js";
import { routeChannels, SubjectTemplate } from "../src/routes/subject.js";
import { committedManifest, manifestSource, permits } from "./support.js";

const manifest = (routes: string, components: readonly string[]) =>
  parseManifest(manifestSource(routes, components), "routes.yaml");

const { roles } = manifest("", []);
const role = (name: string) => roles.get(name)!;
const granted = (subject: string, name: string, receivesOthersEvents = false) =>
  grantText(grantSubject(SubjectTemplate.parse(subject), role(name), receivesOthersEvents));

/** Every grant of each route of an inline manifest, as `role direction subject`. */
function grants(routes: string, components: readonly string[] = []): string[] {
  const parsed = manifest(routes, components);
  return parsed.routes.flatMap((route) =>
    routeGrants(routeChannels(route, parsed.roles), parsed.roles).map(
      (grant) => `${grant.role} ${grant.direction} ${grantText(grant.tokens)}`,
    ),
  );
}

describe("grant rule", () => {
  test("an organization member reaches every realm of its organization", () => {
    expect(granted("service.to.{realm}.organization.{organization}.realm.editor.catalog.fetch", "organization_member")).toBe(
      "service.to.*.organization.{organization}.realm.editor.catalog.fetch",
    );
  });

  test("a subscriber to other publishers' events receives every publisher in its tenant", () => {
    expect(granted("typewriter.presence.organization.{organization}.user.{user}", "organization_member", true)).toBe(
      "typewriter.presence.organization.{organization}.user.*",
    );
    expect(granted("typewriter.presence.organization.{organization}.user.{user}", "organization_member")).toBe(
      "typewriter.presence.organization.{organization}.user.{user}",
    );
  });

  test("a personal identifier stays bound on its own updates", () => {
    expect(granted("cloud.from.user.{user}.organizations.changed", "authenticated_user")).toBe(
      "cloud.from.user.{user}.organizations.changed",
    );
  });

  test("service roles keep exact realm grants because realm is in their tenant", () => {
    expect(granted("service.from.{realm}.organization.{organization}.realm.rollout.command", "realm_participant")).toBe(
      "service.from.{realm}.organization.{organization}.realm.rollout.command",
    );
  });

  test("publishers publish, receivers subscribe and components get no grants", () => {
    expect(
      grants(
        `  - name: catalog_watch
    scope: realm
    callers: [{ role: organization_member }]
    server: { role: realm_coordinator }
    flow:
      kind: watch
      method: "editor/v1/catalog.skir:WatchEditorCatalog"
      operation: editor.catalog.invalidate
      request: editor.catalog.invalidate
      updates:
        payload: "editor/v1/catalog.skir:CatalogInvalidated"
        address: editor.catalog.invalidate
        delivery: { kind: transient }
  - name: permission_resolve
    scope: internal_component
    callers: [{ component: auth-callout }]
    server: { component: auth-typewriter-permissions }
    flow:
      kind: unary
      method: "access/v1/permission.skir:GetEntityPermission"
      operation: auth.permissions.panel
      request: auth.permissions.typewriter-panel
`,
        ["auth-callout", "auth-typewriter-permissions"],
      ),
    ).toEqual([
      "organization_member publish service.to.*.organization.{organization}.realm.editor.catalog.invalidate",
      "realm_coordinator subscribe service.to.{realm}.organization.{organization}.realm.editor.catalog.invalidate",
      "realm_coordinator publish service.from.{realm}.organization.{organization}.realm.editor.catalog.invalidate",
      "organization_member subscribe service.from.*.organization.{organization}.realm.editor.catalog.invalidate",
    ]);
  });

  test("a realm participant receives the panel events of every member of its organization", () => {
    expect(
      grants(`  - name: organization_presence
    scope: organization_actor
    publishers: [{ role: organization_member }]
    subscribers: [{ role: organization_member }, { role: realm_participant }]
    flow:
      kind: event
      payload: "organization/v1/presence.skir:PresenceEvent"
      operation: organization.presence
      address: presence.organization.{organization}.user.{user}
      delivery: { kind: transient }
`),
    ).toEqual([
      "organization_member publish typewriter.presence.organization.{organization}.user.{user}",
      "organization_member subscribe typewriter.presence.organization.{organization}.user.*",
      "realm_participant subscribe typewriter.presence.organization.{organization}.user.*",
    ]);
  });

  test("a free parameter stays open for every party, so any engine of a realm reaches every engine's inbox", () => {
    const parsed = parseManifest(
      manifestSource(
        `  - name: engine_event
    scope: realm
    callers: [{ role: realm_participant }]
    server: { role: realm_participant }
    flow:
      kind: unary
      method: "editor/v1/catalog.skir:FetchEditorCatalog"
      operation: engine.event
      request: engine.{engine}.event
`,
        [],
        "",
        ["engine"],
      ),
      "routes.yaml",
    );
    const granted = parsed.routes.flatMap((route) =>
      routeGrants(routeChannels(route, parsed.roles), parsed.roles).map(
        (grant) => `${grant.role} ${grant.direction} ${grantText(grant.tokens)}`,
      ),
    );
    expect(granted).toEqual([
      "realm_participant publish service.to.{realm}.organization.{organization}.realm.engine.*.event",
      "realm_participant subscribe service.to.{realm}.organization.{organization}.realm.engine.*.event",
    ]);
  });

  test("a realm actor route names its caller, and its server hears every member's requests", () => {
    expect(
      grants(`  - name: event_emit
    scope: realm_actor
    callers: [{ role: organization_member }]
    server: { role: realm_participant }
    flow:
      kind: unary
      method: "editor/v1/catalog.skir:FetchEditorCatalog"
      operation: event.emit
      request: event.emit.user.{user}
`),
    ).toEqual([
      "organization_member publish service.to.*.organization.{organization}.realm.event.emit.user.{user}",
      "realm_participant subscribe service.to.{realm}.organization.{organization}.realm.event.emit.user.*",
    ]);
  });

  test("a realm bucket's writers reach their own realm's keys and only its owner creates it", () => {
    const parsed = parseManifest(
      manifestSource(
        "",
        [],
        `  - name: sessions
    scope: realm
    key: [principal_kind, principal_id, session]
    owner: { role: realm_coordinator }
    writers: [{ role: realm_participant }]
    marker_ttl_seconds: 60
`,
      ),
      "routes.yaml",
    );
    const granted = bucketGrants(parsed.buckets[0]!, parsed.roles).map(
      (grant) => `${grant.role} ${grant.direction} ${grantText(grant.tokens)}`,
    );
    expect(granted.filter((grant) => grant.startsWith("realm_participant "))).not.toContainEqual(
      expect.stringContaining("STREAM.CREATE"),
    );
    expect(granted).toContain("realm_coordinator publish $JS.API.STREAM.CREATE.KV_sessions_{realm}");
    expect(granted).toContain("realm_coordinator publish $JS.API.INFO");
    expect(granted.filter((grant) => grant.startsWith("realm_participant "))).not.toContain(
      "realm_participant publish $JS.API.INFO",
    );
    expect(granted).toContain("realm_participant publish $KV.sessions_{realm}.*.*.*");
    expect(granted).toContain("realm_participant publish $JS.API.DIRECT.GET.KV_sessions_{realm}.$KV.sessions_{realm}.*.*.*");
    expect(granted).toContain(
      "realm_participant publish $JS.API.CONSUMER.CREATE.KV_sessions_{realm}.*.$KV.sessions_{realm}.*.*.*",
    );
    expect(granted.filter((grant) => !grant.endsWith(" $JS.API.INFO")).every((grant) => grant.includes("sessions_{realm}"))).toBe(
      true,
    );
  });

  test("persistent updates grant named consumer operations instead of a subscription", () => {
    expect(
      grants(
        `  - name: members_watch
    scope: organization_actor
    callers: [{ role: organization_member }]
    server: { component: organization-members }
    flow:
      kind: watch
      method: "organization/v1/member.skir:WatchOrganizationMembers"
      operation: organization.members.watch
      request: user.{user}.organization.{organization}.members.watch
      updates:
        payload: "organization/v1/member.skir:OrganizationMembersChanged"
        address: organization.{organization}.members.changed
        delivery: { kind: persistent, stream: TYPEWRITER_MEMBERSHIP, projection: organization_members_changed }
`,
        ["organization-members"],
      ),
    ).toEqual([
      "organization_member publish cloud.to.user.{user}.organization.{organization}.members.watch",
      "organization_member publish $JS.API.STREAM.INFO.TYPEWRITER_MEMBERSHIP",
      "organization_member publish $JS.API.CONSUMER.CREATE.TYPEWRITER_MEMBERSHIP.{consumer:organization_members_changed}.cloud.from.organization.{organization}.members.changed",
      "organization_member publish $JS.API.CONSUMER.INFO.TYPEWRITER_MEMBERSHIP.{consumer:organization_members_changed}",
      "organization_member publish $JS.API.CONSUMER.MSG.NEXT.TYPEWRITER_MEMBERSHIP.{consumer:organization_members_changed}",
      "organization_member publish $JS.API.CONSUMER.DELETE.TYPEWRITER_MEMBERSHIP.{consumer:organization_members_changed}",
    ]);
  });

  test("a persistent watch for a role without a personal identifier is refused", () => {
    expect(() =>
      grants(
        `  - name: realm_watch
    scope: realm
    callers: [{ role: realm_participant }]
    server: { role: realm_coordinator }
    flow:
      kind: watch
      method: "editor/v1/catalog.skir:WatchEditorCatalog"
      operation: realm.watch
      request: realm.watch
      updates:
        payload: "editor/v1/catalog.skir:CatalogInvalidated"
        address: realm.changed
        delivery: { kind: persistent, stream: TYPEWRITER_REALM, projection: realm_changed }
`,
      ),
    ).toThrow("persistent consumers of role realm_participant need a personal identifier");
  });

  test("an engine may watch every key of its realm's sessions bucket with the bucket's every key filter", () => {
    const { buckets, roles } = committedManifest();
    const sessions = buckets.find((bucket) => bucket.name === "sessions")!;
    const watch = `$JS.API.CONSUMER.CREATE.KV_sessions_{realm}.watcher.$KV.sessions_{realm}.${everyKeyFilter(sessions)}`;
    const engine = bucketGrants(sessions, roles)
      .filter((grant) => grant.role === "realm_participant" && grant.direction === "publish")
      .map((grant) => grantText(grant.tokens));
    expect(engine.filter((grant) => permits(grant, watch))).not.toEqual([]);
  });
});
