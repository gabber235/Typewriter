import { describe, expect, test } from "bun:test";

import { generatorFor, type Target } from "../src/index.js";
import { emitDart } from "../src/routes/emit/dart.js";
import { emitKotlinLoader } from "../src/routes/emit/kotlin.js";
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
    const { input, routes } = await committedRoutes();
    const [loader, ...otherLoaderFiles] = emitKotlinLoader(routes);
    expect(otherLoaderFiles).toEqual([]);
    expect(loader!.path).toBe("RolloutRoutes.kt");
    expect(loader!.code).toContain("fun RealmRouteScope.realmHostsProbe");
    expect(loader!.code).toContain("RolloutCodecs.probeRequest");
    expect(loader!.code).toContain("val RealmRouteScope.realmRolloutState");
    expect(loader!.code).toContain("RolloutCodecs.participantState");

    const [rust, ...otherRustFiles] = emitRust(routes, symbolProviders(input).rust);
    expect(otherRustFiles).toEqual([]);
    const code = rust!.code;
    expect(code).toContain("impl OutboundRequestRoute for ServiceBindingQueryRoute");
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

  test("watch update bindings only include subject parameters", async () => {
    const { input, routes } = await committedRoutes();
    const [dart] = emitDart(routes, symbolProviders(input).dart);
    const extension = section(dart!.code, "extension OrganizationServicesWatchRouteNats", "\n}\n");
    const operation = section(extension, "operation({", "\n    }\n");
    const watch = section(extension, "Stream<TData> watch<TData>", "\n    }\n");
    expect(operation).toContain("final user = userId._transportIdentity;");
    expect(watch).toContain("final organization = organizationId.id._transportIdentity;");
    expect(watch).not.toContain("final user");
  });

  test("realm admission matches the concrete organization", async () => {
    const { input, routes } = await committedRoutes();
    const [dart] = emitDart(routes, symbolProviders(input).dart);
    expect(dart!.code).toContain('const prefix = "service.to.";');
    expect(dart!.code).toContain(
      'final suffix = ".organization." + organization + ".realm.editor.catalog.fetch";',
    );
  });

  test("references Skir declarations through the provider imports", async () => {
    const { input, routes } = await committedRoutes();
    const [dart] = emitDart(routes, symbolProviders(input).dart);
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
