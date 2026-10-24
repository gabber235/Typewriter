import { describe, expect, test } from "bun:test";

import { emitKotlin } from "../src/routes/emit/kotlin.js";
import { parseManifest, type Party, type ScopeKind } from "../src/routes/manifest.js";
import { replyInboxes, replyInboxText } from "../src/routes/replies.js";
import { symbolProviders } from "../src/symbols.js";
import { committedRoutes, manifestSource } from "./support.js";

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

describe("Kotlin reply address rules", () => {
  test("each request contract answers only its callers' inboxes through the generated matchers", async () => {
    const { input, resolved } = await committedRoutes();
    const files = emitKotlin(resolved, symbolProviders(input).kotlin);
    const file = (path: string) => files.find((candidate) => candidate.path === path)!.code;
    const contract = (code: string, name: string) => code.slice(code.indexOf(`val RealmRouteScope.${name} get()`));
    const realm = file("RealmRoutes.kt");
    expect(contract(realm, "sharedBlobStore")).toContain(
      "replyAddresses = ReplyAddressRule { _, reply -> isPanelReplyInbox(reply) || isServiceReplyInbox(reply) },",
    );
    expect(contract(realm, "rolloutProbe")).toContain(
      "replyAddresses = ReplyAddressRule { _, reply -> isServiceReplyInbox(reply) },",
    );
    expect(contract(realm, "editorCatalogWatch")).toContain(
      "replyAddresses = ReplyAddressRule { _, reply -> isPanelReplyInbox(reply) },",
    );
    const service = file("ServiceRegistrationRoutes.kt");
    expect(service.slice(service.indexOf("val ServiceRouteScope.registrationLeaseEnsure get()"))).toContain(
      "replyAddresses = ReplyAddressRule { scope, reply -> isServiceReplyInbox(reply, service = scope.serviceId) },",
    );
    const inboxes = file("ReplyInboxes.kt");
    expect(inboxes).toContain(
      "fun isPanelReplyInbox(reply: MessageAddress, user: String? = null): Boolean {\n" +
        "    val tokens = reply.value.split('.')\n" +
        "    return tokens.size == 4 &&\n" +
        '        tokens[0] == "_INBOX" &&\n' +
        "        (user == null || tokens[1] == user)\n}",
    );
    expect(inboxes).toContain(
      "fun isServiceReplyInbox(reply: MessageAddress, service: String? = null): Boolean {\n" +
        "    val tokens = reply.value.split('.')\n" +
        "    return tokens.size == 3 &&\n" +
        '        tokens[0] == "_INBOX" &&\n' +
        "        (service == null || tokens[1] == service)\n}",
    );
  });
});
