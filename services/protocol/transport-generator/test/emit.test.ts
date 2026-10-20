import { describe, expect, test } from "bun:test";

import { generatorFor, type Target } from "../src/index.js";
import { emitDart } from "../src/routes/emit/dart.js";
import { emitKotlin, emitKotlinLoader } from "../src/routes/emit/kotlin.js";
import { emitRust } from "../src/routes/emit/rust.js";
import { symbolProviders } from "../src/symbols.js";
import { committedRoutes, loadSkirInput, MANIFEST_PATH } from "./support.js";

function section(code: string, start: string, end: string): string {
  const from = code.indexOf(start);
  expect(from).toBeGreaterThanOrEqual(0);
  return code.slice(from, code.indexOf(end, from + start.length));
}

describe("route emission", () => {
  test("the complete inventory emits loader and backend routes", async () => {
    const { input, resolved } = await committedRoutes();
    const [loader, ...otherLoaderFiles] = emitKotlinLoader(resolved);
    expect(otherLoaderFiles).toEqual([]);
    expect(loader!.path).toBe("RolloutRoutes.kt");
    expect(loader!.code).toContain("fun RealmRouteScope.realmHostsProbe");
    expect(loader!.code).toContain("RolloutCodecs.probeRequest");
    expect(loader!.code).toContain("val RealmRouteScope.realmRolloutState");
    expect(loader!.code).toContain("RolloutCodecs.participantState");

    const [rust, ...otherRustFiles] = emitRust(resolved, symbolProviders(input).rust);
    expect(otherRustFiles).toEqual([]);
    const code = rust!.code;
    expect(code).toContain("impl OutboundRequestRoute for ServiceBindingQueryRoute");
    expect(code).toContain("impl OutboundRequestRoute for PanelPermissionResolveRoute");
    expect(code).not.toContain("impl OutboundRequestRoute for UserOrganizationCreateRoute");
    expect(code).not.toContain("impl OutboundRequestRoute for EditorCatalogFetchRoute");
    expect(code).toContain("impl OutboundEventRoute for UserOrganizationsWatchRoute");
    expect(code).toContain("impl PersistentEventRoute for UserOrganizationsWatchRoute");
    expect(code).not.toContain("impl TransientEventRoute for UserOrganizationsWatchRoute");
    expect(code).toContain("impl OutboundEventRoute for OrganizationTopologyWatchRoute");
    expect(code).toContain("impl TransientEventRoute for OrganizationTopologyWatchRoute");
    expect(code).not.toContain("impl PersistentEventRoute for OrganizationTopologyWatchRoute");
    expect(code).toContain("type Scope = OrganizationScope;");
    expect(code).toContain(
      "crate::skirout::base::organization::v1::organization::create_organization_method()",
    );
  });

  test("role grants bind the grantee's identifiers and wildcard the rest", async () => {
    const { input, resolved } = await committedRoutes();
    const [rust] = emitRust(resolved, symbolProviders(input).rust);
    const member = section(rust!.code, "impl OrganizationActorScope {", "\n}\n");
    expect(member).toContain("session: &crate::transport::ConnectionSession,");
    expect(member).toContain('"service.to.*.organization.{organization}.realm.editor.catalog.fetch"');
    expect(member).toContain('"typewriter.presence.organization.{organization}.user.*"');
    expect(member).toContain(
      'let organization_members_changed = consumer_name(user, Some(organization), session, "organization_members_changed");',
    );
    expect(member).not.toContain('"cloud.from.organization.{organization}.members.changed"');
    const realm = section(rust!.code, "pub enum RealmRole {", "\n}\n");
    expect(realm).toBe("pub enum RealmRole {\n    RealmCoordinator,\n    RealmParticipant,");
    const service = section(rust!.code, "impl ServiceScope {", "\n}\n");
    expect(service).not.toContain("session");
    expect(rust!.code).not.toContain("USER.INFO");
  });

  test("both languages name persistent consumers from one template", async () => {
    const { input, resolved } = await committedRoutes();
    const [rust] = emitRust(resolved, symbolProviders(input).rust);
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    expect(rust!.code).toContain(
      "let identity = serde_json::json!([actor.as_str(), organization.map(SubjectToken::as_str), session.as_str(), projection]);",
    );
    expect(rust!.code).toContain('"TW_{}",');
    expect(dart!.code).toContain("final identity = jsonEncode([actor, organization, session, projection]);");
    expect(dart!.code).toContain('return "TW_" + encoded;');
    expect(dart!.code).toContain('id: "organization_members_changed",\n    organizationScoped: true,');
    expect(dart!.code).toContain('id: "user_organizations_changed",\n    organizationScoped: false,');
  });

  test("Kotlin route scopes are hand written once, not emitted", async () => {
    const { input, resolved } = await committedRoutes();
    const [realm, service] = emitKotlin(resolved, symbolProviders(input).kotlin);
    const [loader] = emitKotlinLoader(resolved);
    for (const file of [realm!, loader!]) {
      expect(file.code).toContain("import com.typewritermc.protocol.transport.RealmRouteScope\n");
      expect(file.code).toContain("import com.typewritermc.protocol.transport.realmTemplate\n");
      expect(file.code).not.toContain("data class RealmRouteScope");
      expect(file.code).not.toContain("addressTemplate(");
    }
    expect(service!.code).toContain("import com.typewritermc.protocol.transport.serviceTemplate\n");
    expect(service!.code).not.toContain("data class ServiceRouteScope");
  });

  test("the panel derives no permissions of its own", async () => {
    const { input, resolved } = await committedRoutes();
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    for (const removed of ["panelTransportPermissions", "admittedRealms", "ServerPermissionSnapshot", "USER.INFO"]) {
      expect(dart!.code).not.toContain(removed);
    }
  });

  test("watch update bindings only include subject parameters", async () => {
    const { input, resolved } = await committedRoutes();
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    const extension = section(dart!.code, "extension OrganizationServicesWatchRouteNats", "\n}\n");
    const operation = section(extension, "operation({", "\n    }\n");
    const watch = section(extension, "Stream<TData> watch<TData>", "\n    }\n");
    expect(operation).toContain("final user = userId._transportIdentity;");
    expect(watch).toContain("final organization = organizationId.id._transportIdentity;");
    expect(watch).not.toContain("final user");
  });

  test("presence subscribers read every member of the organization", async () => {
    const { input, resolved } = await committedRoutes();
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    const presence = section(dart!.code, "final class OrganizationPresenceRouteEvent", "\n}\n");
    expect(presence).toContain('return "typewriter"+ "." +"presence"+ "." +"organization"+ "." +organization+ "." +"user"+ "." +"*";');
    expect(presence).toContain("static String? userIdFromSubject(");
  });

  test("references Skir declarations through the provider imports", async () => {
    const { input, resolved } = await committedRoutes();
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    expect(dart!.code).toContain(
      'import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/organization.dart" as _lib_organization_v1_organization;',
    );
    expect(dart!.code).toContain("final method = _lib_organization_v1_organization.createOrganizationMethod;");
    expect(dart!.code).toContain("this.transferId._transportTransfer");
  });
});

describe("generator entry points", () => {
  const targets: Array<[Target, string[]]> = [
    ["kotlin", ["RealmRoutes.kt", "ServiceRegistrationRoutes.kt"]],
    ["kotlin-loader", ["RolloutRoutes.kt"]],
    ["dart", ["transport_routes.dart"]],
    ["rust", ["mod.rs"]],
  ];

  test.each(targets)("%s writes its files relative to the output directory", async (target, paths) => {
    const input = await loadSkirInput();
    const generator = generatorFor(target);
    expect(generator.id).toBe(`typewriter-transport-${target}`);
    expect(generator.generateCode(input).files.map((file) => file.path)).toEqual(paths);
  });

  test("the config takes only the manifest and the Dart import prefix", () => {
    const { configType } = generatorFor("rust");
    expect(configType.safeParse({ manifest: MANIFEST_PATH }).success).toBe(true);
    expect(configType.safeParse({ manifest: MANIFEST_PATH, target: "rust" }).success).toBe(false);
    expect(configType.safeParse({ manifest: MANIFEST_PATH, executable: "generator" }).success).toBe(false);
  });

  test("the Dart target requires the import prefix", async () => {
    const input = await loadSkirInput({ dartImportUriPrefix: undefined });
    expect(() => generatorFor("dart").generateCode(input)).toThrow("importUriPrefix");
    expect(generatorFor("kotlin").generateCode(input).files).toHaveLength(2);
  });
});
