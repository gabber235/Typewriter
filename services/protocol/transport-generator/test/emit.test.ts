import { describe, expect, test } from "bun:test";

import { generatorFor, type Target } from "../src/index.js";
import { emitDart } from "../src/routes/emit/dart.js";
import { emitKotlin } from "../src/routes/emit/kotlin.js";
import { emitRust } from "../src/routes/emit/rust.js";
import { symbolProviders } from "../src/symbols.js";
import { committedRoutes, loadSkirInput, MANIFEST_PATH } from "./support.js";

function section(code: string, start: string, end: string): string {
  const from = code.indexOf(start);
  expect(from).toBeGreaterThanOrEqual(0);
  return code.slice(from, code.indexOf(end, from + start.length));
}

describe("route emission", () => {
  test("the complete inventory emits backend routes", async () => {
    const { input, resolved } = await committedRoutes();
    const [rust, ...otherRustFiles] = emitRust(resolved, symbolProviders(input).rust, input);
    expect(otherRustFiles.map(({ path }) => path)).toEqual(["skir_types.rs"]);
    expect(rust!.code).toContain("\nmod skir_types;\n");
    const code = rust!.code;
    const impl = (contract: string, route: string) => `impl crate::transport::${contract} for ${route}`;
    expect(code).toContain(impl("OutboundRequestRoute", "ServiceBindingQueryRoute"));
    expect(code).toContain(impl("OutboundRequestRoute", "PanelPermissionResolveRoute"));
    expect(code).not.toContain(impl("OutboundRequestRoute", "UserOrganizationCreateRoute"));
    expect(code).not.toContain("EditorCatalogFetchRoute");
    expect(code).toContain(impl("OutboundEventRoute", "UserOrganizationsWatchRoute"));
    expect(code).toContain(impl("PersistentEventRoute", "UserOrganizationsWatchRoute"));
    expect(code).not.toContain(impl("TransientEventRoute", "UserOrganizationsWatchRoute"));
    expect(code).toContain(impl("OutboundEventRoute", "OrganizationTopologyWatchRoute"));
    expect(code).toContain(impl("TransientEventRoute", "OrganizationTopologyWatchRoute"));
    expect(code).not.toContain(impl("PersistentEventRoute", "OrganizationTopologyWatchRoute"));
    expect(code).toContain("type Scope = crate::transport::OrganizationScope;");
    expect(code).toContain(
      "crate::skirout::base::organization::v1::organization::create_organization_method()",
    );
  });

  test("role grants bind the grantee's identifiers and wildcard the rest", async () => {
    const { input, resolved } = await committedRoutes();
    const [rust] = emitRust(resolved, symbolProviders(input).rust, input);
    const member = section(rust!.code, "impl crate::transport::OrganizationActorScope {", "\n}\n");
    expect(member).toContain("session: &crate::transport::ConnectionSession,");
    expect(member).toContain('"service.to.*.organization.{organization}.realm.editor.catalog.fetch"');
    expect(member).toContain('"typewriter.presence.organization.{organization}.user.*"');
    expect(member).toContain(
      'let organization_members_changed = consumer_name(user, Some(organization), session, "organization_members_changed");',
    );
    expect(member).not.toContain('"cloud.from.organization.{organization}.members.changed"');
    const realm = section(rust!.code, "pub enum RealmRole {", "\n}\n");
    expect(realm).toBe("pub enum RealmRole {\n    RealmCoordinator,\n    RealmParticipant,");
    const service = section(rust!.code, "impl crate::transport::ServiceScope {", "\n}\n");
    expect(service).not.toContain("session");
    expect(rust!.code).not.toContain("USER.INFO");
  });

  test("both languages name persistent consumers from one template", async () => {
    const { input, resolved } = await committedRoutes();
    const [rust] = emitRust(resolved, symbolProviders(input).rust, input);
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    expect(rust!.code).toContain(
      "let identity = serde_json::json!([actor.as_str(), organization.map(crate::transport::SubjectToken::as_str), session.as_str(), projection]);",
    );
    expect(rust!.code).toContain('"TW_{}",');
    expect(dart!.code).toContain("final identity = jsonEncode([actor, organization, session, projection]);");
    expect(dart!.code).toContain('return "TW_$encoded";');
    expect(dart!.code).toContain('id: "organization_members_changed",\n    organizationScoped: true,');
    expect(dart!.code).toContain('id: "user_organizations_changed",\n    organizationScoped: false,');
  });

  test("Kotlin route scopes are hand written once, not emitted", async () => {
    const { input, resolved } = await committedRoutes();
    const [realm, service] = emitKotlin(resolved, symbolProviders(input).kotlin);
    expect(realm!.code).toContain("import com.typewritermc.protocol.transport.RealmRouteScope\n");
    expect(realm!.code).toContain("import com.typewritermc.protocol.transport.realmTemplate\n");
    expect(realm!.code).not.toContain("data class RealmRouteScope");
    expect(realm!.code).not.toContain("addressTemplate(");
    expect(service!.code).toContain("import com.typewritermc.protocol.transport.serviceTemplate\n");
    expect(service!.code).not.toContain("data class ServiceRouteScope");
  });

  test("rollout scatter routes take Skir methods with generated policies", async () => {
    const { input, resolved } = await committedRoutes();
    const [realm, service] = emitKotlin(resolved, symbolProviders(input).kotlin);
    const command = section(realm!.code, "val RealmRouteScope.rolloutCommand get() =", "\n)\n");
    expect(command).toContain("skirScatterContract(");
    expect(command).toContain("method = ApplyRolloutCommand, name = OperationName.of(\"realm.rollout.command\"),");
    expect(command).toContain("responsePolicy = applyRolloutCommandResponsePolicy,");
    expect(realm!.code).toContain("import skirout.service.v1.rollout.ApplyRolloutCommand\n");
    const policy = section(realm!.code, "private val applyRolloutCommandResponsePolicy =", "\n}\n");
    expect(policy).toContain(
      'ApplyRolloutCommandResponse.Kind.COMMAND_FAILED_ERROR_WRAPPER -> ResponseClassification.domainError("command-failed-error")',
    );
    expect(policy).toContain("ApplyRolloutCommandResponse.InternalErrorWrapper(");
    for (const route of ["rolloutProbe", "rolloutStatus"]) {
      expect(realm!.code).toContain(`val RealmRouteScope.${route} get() = skirScatterContract(`);
    }
    expect(realm!.code).not.toContain("rollout.state");
    expect(service!.code).not.toContain("skirScatterContract");
  });

  test("Dart subjects interpolate tokens the hand written segment checks validated", async () => {
    const { input, resolved } = await committedRoutes();
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    expect(dart!.code).not.toContain("extension _TransportSegment");
    expect(dart!.code).not.toContain('+ "." +');
    expect(dart!.code).toContain('subject: "cloud.to.user.$user.organization.create",');
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
    expect(operation).toContain("final user = userId.transportIdentity;");
    expect(watch).toContain("final organization = organizationId.id.transportIdentity;");
    expect(watch).not.toContain("final user");
  });

  test("presence subscribers read every member of the organization", async () => {
    const { input, resolved } = await committedRoutes();
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    const presence = section(dart!.code, "final class OrganizationPresenceRouteEvent", "\n}\n");
    expect(presence).toContain('return "typewriter.presence.organization.$organization.user.*";');
    expect(presence).toContain("static String? userIdFromSubject(");
  });

  test("references Skir declarations through the provider imports", async () => {
    const { input, resolved } = await committedRoutes();
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    expect(dart!.code).toContain(
      'import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/organization.dart" as _lib_organization_v1_organization;',
    );
    expect(dart!.code).toContain("final method = _lib_organization_v1_organization.createOrganizationMethod;");
  });
});

describe("reply framing limits", () => {
  test("every language receives the manifest limits", async () => {
    const { input, resolved } = await committedRoutes();
    const providers = symbolProviders(input);
    const kotlin = emitKotlin(resolved, providers.kotlin).find((file) => file.path === "TransportLimits.kt");
    expect(kotlin!.code).toContain("import com.typewritermc.services.libs.communicator.transfer.TransportLimits");
    expect(kotlin!.code).toContain("val TRANSPORT_LIMITS = TransportLimits(chunkBytes = 524288, maxChunks = 64)");
    const [dart] = emitDart(resolved, providers.dart);
    expect(dart!.code).toContain("const transportLimits = TransportLimits(chunkBytes: 524288, maxChunks: 64);");
    const [rust] = emitRust(resolved, providers.rust, input);
    expect(rust!.code).toContain("pub const RESPONSE_CHUNK_BYTES: usize = 524288;");
    expect(rust!.code).toContain("pub const MAX_RESPONSE_CHUNKS: usize = 64;");
  });

  test("bulk reads are plain unary routes without an update channel", async () => {
    const { input, resolved } = await committedRoutes();
    const [realm] = emitKotlin(resolved, symbolProviders(input).kotlin);
    const catalog = section(realm!.code, "val RealmRouteScope.editorCatalogFetch get() =", "\n)\n");
    expect(catalog).toContain("skirUnaryContract(");
    expect(realm!.code).not.toContain("updateAddressResolver");
    const [dart] = emitDart(resolved, symbolProviders(input).dart);
    expect(dart!.code).not.toContain("watchRequest");
    expect(dart!.code).toContain("extension EditorCatalogFetchRouteNats on");
  });
});

describe("generator entry points", () => {
  const targets: Array<[Target, string[]]> = [
    ["kotlin", ["RealmRoutes.kt", "ServiceRegistrationRoutes.kt", "TransportLimits.kt"]],
    ["dart", ["transport_routes.dart"]],
    ["rust", ["mod.rs", "skir_types.rs"]],
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
    expect(generatorFor("kotlin").generateCode(input).files).toHaveLength(3);
  });
});
