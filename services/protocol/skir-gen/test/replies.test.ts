import { describe, expect, test } from "bun:test";

import { parseManifest, type Party, type ScopeKind } from "../src/routes/manifest.js";
import { replyInboxes, replyInboxText } from "../src/routes/replies.js";
import { manifestSource } from "./support.js";

const { roles } = parseManifest(manifestSource(""), "routes.yaml");

/** The reply inboxes a server of `scope` answers for these callers, as `_INBOX.{user}.*.*`. */
const answered = (scope: ScopeKind, ...callers: Party[]) =>
  replyInboxes(callers, scope, roles).map(replyInboxText);

describe("reply inboxes a server answers", () => {
  test("a panel caller is answered on its session inbox, bound to the user the scope names", () => {
    expect(answered("user", { role: "authenticated_user" })).toEqual(["_INBOX.{user}.*.*"]);
    expect(answered("organization_actor", { role: "organization_member" })).toEqual(["_INBOX.{user}.*.*"]);
  });

  test("a panel caller the scope does not name is answered on any panel inbox", () => {
    expect(answered("realm", { role: "organization_member" })).toEqual(["_INBOX.*.*.*"]);
  });

  test("a service caller is answered on its inbox, bound to the service the scope names", () => {
    expect(answered("service", { role: "registered_service" })).toEqual(["_INBOX.{service}.*"]);
  });

  test("a service caller the scope does not name is answered on any service inbox", () => {
    expect(answered("realm", { role: "realm_participant" })).toEqual(["_INBOX.*.*"]);
    expect(answered("realm", { role: "realm_coordinator" })).toEqual(["_INBOX.*.*"]);
  });

  test("callers of both sides are each answered on their own side's inbox, once per shape", () => {
    expect(
      answered("realm", { role: "organization_member" }, { role: "realm_participant" }, { role: "realm_coordinator" }),
    ).toEqual(["_INBOX.*.*.*", "_INBOX.*.*"]);
  });

  test("a component caller opens no inbox, since the wasmCloud host owns its reply subjects", () => {
    expect(answered("service", { component: "auth-typewriter-permissions" })).toEqual([]);
    expect(answered("service", { role: "registered_service" }, { component: "auth-typewriter-permissions" })).toEqual([
      "_INBOX.{service}.*",
    ]);
  });
});
