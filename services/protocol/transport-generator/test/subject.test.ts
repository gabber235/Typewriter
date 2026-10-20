import { describe, expect, test } from "bun:test";

import { parseManifest, type Party, type RoleDeclarations } from "../src/routes/manifest.js";
import { channelSubjects, failureSlug, SubjectTemplate, type ChannelSubjects } from "../src/routes/subject.js";
import { manifestSource } from "./support.js";

const { roles }: { roles: RoleDeclarations } = parseManifest(manifestSource(""), "roles.yaml");

const role = (name: string): Party => ({ role: name });
const component = (name: string): Party => ({ component: name });

function rendered(subjects: ChannelSubjects): Record<string, string> {
  return Object.fromEntries(Object.entries(subjects).map(([key, value]) => [key, value.toString()]));
}

const derive = (...args: Parameters<typeof channelSubjects>) => rendered(channelSubjects(...args));

describe("subject templates", () => {
  test("rejects all broker wildcards", () => {
    for (const subject of ["user.>", "user.*", "user.{unknown}"]) {
      expect(() => SubjectTemplate.parse(subject)).toThrow("invalid subject token");
    }
  });

  test("rejects empty and embedded parameter tokens", () => {
    for (const subject of ["user..{user}", "user-{user}.watch", "{user}.watch."]) {
      expect(() => SubjectTemplate.parse(subject)).toThrow("invalid subject token");
    }
  });

  test("rejects repeated captures", () => {
    expect(() => SubjectTemplate.parse("{user}.to.{user}")).toThrow("repeated subject parameter {user}");
  });

  test("round trips its manifest spelling", () => {
    const text = "user.{user}.organization.{organization}.watch";
    expect(SubjectTemplate.parse(text).toString()).toBe(text);
    expect(SubjectTemplate.parse(text).parameters()).toEqual(["organization", "user"]);
  });
});

describe("subject rule", () => {
  const address = (value: string) => SubjectTemplate.parse(value);

  test("realm scope flows toward the coordinator on service.to", () => {
    expect(
      derive("realm", "request", address("editor.catalog.fetch"), [role("organization_member")], [role("realm_coordinator")], roles),
    ).toEqual({ client: "service.to.{realm}.organization.{organization}.realm.editor.catalog.fetch" });
  });

  test("realm scope flows from the coordinator on service.from", () => {
    expect(
      derive("realm", "updates", address("editor.catalog.invalidate"), [role("realm_coordinator")], [role("organization_member")], roles),
    ).toEqual({ client: "service.from.{realm}.organization.{organization}.realm.editor.catalog.invalidate" });
    expect(
      derive("realm", "event", address("rollout.state"), [role("realm_participant")], [role("realm_coordinator")], roles),
    ).toEqual({ client: "service.to.{realm}.organization.{organization}.realm.rollout.state" });
  });

  test("a role talking to a component crosses the bridge in both directions", () => {
    const request = address("user.{user}.organization.create");
    expect(derive("user", "request", request, [role("authenticated_user")], [component("user-organization")], roles)).toEqual({
      client: "cloud.to.user.{user}.organization.create",
      backend: "typewriter.from.user.{user}.organization.create",
    });
    const updates = address("organization.{organization}.members.changed");
    expect(
      derive("organization_actor", "updates", updates, [component("organization-members")], [role("organization_member")], roles),
    ).toEqual({
      client: "cloud.from.organization.{organization}.members.changed",
      backend: "typewriter.to.organization.{organization}.members.changed",
    });
  });

  test("component callers of a bridged request also get the bare address", () => {
    const callers = [role("registered_service"), component("auth-typewriter-permissions")];
    const server = [component("service-registration")];
    expect(derive("service", "request", address("service.{service}.binding.query"), callers, server, roles)).toEqual({
      client: "cloud.to.service.{service}.binding.query",
      backend: "typewriter.from.service.{service}.binding.query",
      internal: "service.{service}.binding.query",
    });
    expect(derive("service", "updates", address("service.{service}.registration.bound"), server, callers, roles)).toEqual({
      client: "cloud.from.service.{service}.registration.bound",
      backend: "typewriter.to.service.{service}.registration.bound",
    });
  });

  test("component to component uses the bare address", () => {
    expect(
      derive(
        "internal_component",
        "request",
        address("auth.permissions.typewriter-panel"),
        [component("auth-callout")],
        [component("auth-typewriter-permissions")],
        roles,
      ),
    ).toEqual({ internal: "auth.permissions.typewriter-panel" });
  });

  test("events between panel roles use the typewriter prefix", () => {
    const members = [role("organization_member")];
    expect(
      derive("organization_actor", "event", address("presence.organization.{organization}.user.{user}"), members, members, roles),
    ).toEqual({ client: "typewriter.presence.organization.{organization}.user.{user}" });
  });

  test("rejects party combinations without a subject family", () => {
    expect(() =>
      channelSubjects("realm", "request", address("x"), [component("auth-callout")], [role("realm_coordinator")], roles),
    ).toThrow("realm routes connect roles only");
    expect(() =>
      channelSubjects("service", "event", address("x"), [role("registered_service")], [role("registered_service")], roles),
    ).toThrow("has no subject family");
  });

  test("derives failure slugs from the operation", () => {
    expect(failureSlug("organization.members.join_requests.watch")).toBe(
      "organization-members-join-requests-watch-failed",
    );
  });
});
