import { describe, expect, test } from "bun:test";

import { grantSubject, grantText, routeGrants } from "../src/routes/grants.js";
import { parseManifest } from "../src/routes/manifest.js";
import { routeChannels, SubjectTemplate } from "../src/routes/subject.js";
import { manifestSource } from "./support.js";

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
});
