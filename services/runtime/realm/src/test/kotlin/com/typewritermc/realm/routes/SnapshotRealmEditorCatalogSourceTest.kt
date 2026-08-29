package com.typewritermc.realm.routes

import com.typewritermc.discovery.DeploymentDiscoverySnapshot
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.pages.GraphDirection
import com.typewritermc.pages.PageCatalog
import com.typewritermc.pages.PageCatalogEntry
import com.typewritermc.pages.PageDescriptor
import com.typewritermc.pages.PageDiagnostic
import com.typewritermc.pages.ResolvedPageEditorDefinition
import com.typewritermc.presentation.PresentationDiagnostic
import com.typewritermc.realm.RealmDiscoverySnapshot
import com.typewritermc.types.Color
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeId
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.SubtypeQuery
import skirout.editor.v1.catalog.SubtypeQueryId
import skirout.editor.v1.presentation.PresentationDefinition
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.PresentationId
import com.typewritermc.discovery.CatalogGeneration as DiscoveryGeneration
import skirout.editor.v1.type_catalog.TypeCatalog as WireTypeCatalog

val SnapshotRealmEditorCatalogSourceTest by testSuite {
    test("successful fetch returns the requested atomic type closure") {
        val fixture = catalogFixture()
        val source = SnapshotRealmEditorCatalogSource { fixture.snapshot.editorCatalog() }
        val request =
            emptyRequest(
                requestedTypes = listOf(SkirTypeCodec.encode(fixture.leaf.id).getOrThrow()),
            )

        val response = source.fetch(request) as CatalogFetchResult.SuccessWrapper

        SkirTypeCodec
            .decode(WireTypeCatalog.partial(definitions = response.value.typeDefinitions))
            .getOrThrow()
            .definitions
            .map(TypeDefinition::id)
            .toSet() shouldBe setOf(fixture.leaf.id, fixture.middle.id, fixture.parent.id)
    }

    test("successful fetch keeps page diagnostics in the atomic catalog") {
        val fixture = catalogFixture()
        val diagnostic = PageDiagnostic(code = "invalid_page", message = "Broken page", namespace = "test")
        val source = SnapshotRealmEditorCatalogSource { fixture.snapshot.editorCatalog(pageDiagnostics = listOf(diagnostic)) }

        val response = source.fetch(emptyRequest()) as CatalogFetchResult.SuccessWrapper

        response.value.pageDiagnostics.single().let {
            it.code shouldBe "invalid_page"
            it.message shouldBe "Broken page"
            it.originArtifactId shouldBe "test"
        }
    }

    test("atomic catalog includes types referenced by page definitions") {
        val fixture = catalogFixture()
        val pages =
            PageCatalog(
                entries =
                    listOf(
                        PageCatalogEntry(
                            originArtifactId = "test",
                            sourcePart = "main",
                            descriptor =
                                PageDescriptor(
                                    kind =
                                        PageKindRef(
                                            PageKindId(DeclaredTypeId.parse("019d3a87001070008000000000000010")),
                                            1,
                                        ),
                                    name = "Test",
                                    description = null,
                                    icon = Icon.parse("material-symbols:test-tube"),
                                    color = Color.parseRgb("#000000"),
                                    editor =
                                        ResolvedPageEditorDefinition.Graph(
                                            GraphDirection.LEFT_TO_RIGHT,
                                            listOf(fixture.leaf.id),
                                        ),
                                ),
                        ),
                    ),
                diagnostics = emptyList(),
            )
        val source = SnapshotRealmEditorCatalogSource { fixture.snapshot.editorCatalog(pages = pages) }

        val response = source.fetch(emptyRequest()) as CatalogFetchResult.SuccessWrapper
        val catalog =
            SkirTypeCodec
                .decode(WireTypeCatalog.partial(definitions = response.value.typeDefinitions))
                .getOrThrow()

        catalog.definitions.map(TypeDefinition::id).toSet() shouldBe
            setOf(fixture.leaf.id, fixture.middle.id, fixture.parent.id)
        response.value.pageEntries.size shouldBe 1
    }

    test("subtype queries retain abstract and concrete descendants") {
        val fixture = catalogFixture()
        val source = SnapshotRealmEditorCatalogSource { fixture.snapshot.editorCatalog() }
        val response =
            source.fetch(
                emptyRequest(
                    subtypeQueries =
                        listOf(
                            SubtypeQuery(
                                queryId = SubtypeQueryId(value = "descendants"),
                                target = SkirTypeCodec.encode(fixture.parent.id).getOrThrow(),
                            ),
                        ),
                ),
            ) as CatalogFetchResult.SuccessWrapper

        response.value.subtypeResults
            .single()
            .matchingTypes
            .map { SkirTypeCodec.decode(it).getOrThrow() }
            .toSet() shouldBe setOf(fixture.middle.id, fixture.leaf.id)
    }

    test("successful fetch includes assembled presentation definitions") {
        val fixture = catalogFixture()
        val presentation =
            PresentationDefinition(
                presentationId = PresentationId(namespace = "test", name = "editor"),
                target =
                    SkirTypeCodec
                        .encode(
                            com.typewritermc.types.TypeExpression
                                .Named(fixture.leaf.id),
                        ).getOrThrow(),
                root = PresentationNode.partial(nodeId = "root"),
                dependencies =
                    skirout.editor.v1.presentation.PresentationDependencies
                        .partial(),
            )
        val source = SnapshotRealmEditorCatalogSource { fixture.snapshot.editorCatalog(listOf(presentation)) }

        val response =
            source.fetch(
                emptyRequest(
                    presentationIds = listOf(presentation.presentationId),
                ),
            ) as CatalogFetchResult.SuccessWrapper

        response.value.presentationDefinitions shouldBe listOf(presentation)
        SkirTypeCodec
            .decode(WireTypeCatalog.partial(definitions = response.value.typeDefinitions))
            .getOrThrow()
            .definitions
            .map(TypeDefinition::id)
            .toSet() shouldBe setOf(fixture.leaf.id, fixture.middle.id, fixture.parent.id)
    }

    test("requested type includes its attached presentation") {
        val fixture = catalogFixture()
        val presentationId = com.typewritermc.types.PresentationId("test", "editor")
        val presentation = presentation(presentationId, fixture.leaf.id)
        val types =
            fixture.snapshot.types.copy(
                definitions =
                    fixture.snapshot.types.definitions.map { definition ->
                        if (definition.id == fixture.leaf.id) {
                            definition.copy(defaultPresentationId = presentationId)
                        } else {
                            definition
                        }
                    },
            )
        val source =
            SnapshotRealmEditorCatalogSource {
                fixture.snapshot.copy(types = types).editorCatalog(listOf(presentation))
            }

        val response =
            source.fetch(
                emptyRequest(requestedTypes = listOf(SkirTypeCodec.encode(fixture.leaf.id).getOrThrow())),
            ) as CatalogFetchResult.SuccessWrapper

        response.value.presentationDefinitions shouldBe listOf(presentation)
    }

    test("successful fetch includes attributed presentation diagnostics") {
        val fixture = catalogFixture()
        val source =
            SnapshotRealmEditorCatalogSource {
                fixture.snapshot.editorCatalog(
                    diagnostics =
                        listOf(
                            PresentationDiagnostic(
                                code = "priority_tie",
                                message = "Priority is tied.",
                                namespace = "test",
                                sourcePart = "common",
                                presentationName = "editor",
                            ),
                        ),
                )
            }

        val response = source.fetch(emptyRequest()) as CatalogFetchResult.SuccessWrapper

        response.value.diagnostics
            .single()
            .message
            .contains("Presentation: editor") shouldBe true
    }
}

private data class CatalogFixture(
    val parent: TypeDefinition,
    val middle: TypeDefinition,
    val leaf: TypeDefinition,
    val snapshot: DeploymentDiscoverySnapshot,
)

private fun catalogFixture(): CatalogFixture {
    val parent = definition("Parent", NominalTypeKind.OPEN_ABSTRACT)
    val middle = definition("Middle", NominalTypeKind.OPEN_ABSTRACT, listOf(parent.id))
    val leaf = definition("Leaf", NominalTypeKind.CONCRETE, listOf(middle.id))
    val unrelated = definition("Unrelated", NominalTypeKind.CONCRETE)
    return CatalogFixture(
        parent = parent,
        middle = middle,
        leaf = leaf,
        snapshot =
            DeploymentDiscoverySnapshot(
                generation = DiscoveryGeneration("generation"),
                artifacts = emptyList(),
                sourceParts = emptyList(),
                types = TypeCatalog(listOf(leaf, parent, middle, unrelated)),
                diagnostics = emptyList(),
            ),
    )
}

private fun definition(
    name: String,
    kind: NominalTypeKind,
    parents: List<ResolvedTypeRef> = emptyList(),
): TypeDefinition =
    TypeDefinition(
        id = ResolvedTypeRef(TypeId.Qualified("test", name), revision = 1),
        kind = kind,
        parents = parents,
    )

private fun presentation(
    id: com.typewritermc.types.PresentationId,
    target: ResolvedTypeRef,
) = PresentationDefinition(
    presentationId = PresentationId(namespace = id.namespace, name = id.name),
    target =
        SkirTypeCodec
            .encode(
                com.typewritermc.types.TypeExpression
                    .Named(target),
            ).getOrThrow(),
    root = PresentationNode.partial(nodeId = "root"),
    dependencies =
        skirout.editor.v1.presentation.PresentationDependencies
            .partial(),
)

private fun emptyRequest(
    requestedTypes: List<skirout.editor.v1.type_catalog.ResolvedTypeRef> = emptyList(),
    presentationIds: List<PresentationId> = emptyList(),
    subtypeQueries: List<SubtypeQuery> = emptyList(),
): CatalogFetchRequest =
    CatalogFetchRequest(
        expectedGeneration = null,
        requestedTypes = requestedTypes,
        presentationIds = presentationIds,
        subtypeQueries = subtypeQueries,
    )

private fun DeploymentDiscoverySnapshot.editorCatalog(
    presentations: List<PresentationDefinition> = emptyList(),
    diagnostics: List<PresentationDiagnostic> = emptyList(),
    pageDiagnostics: List<PageDiagnostic> = emptyList(),
    pages: PageCatalog = PageCatalog(emptyList(), pageDiagnostics),
) = RealmDiscoverySnapshot(
    discovery = this,
    elements = ElementCatalog(emptyList()),
    pages = pages,
    presentations = presentations,
    presentationDiagnostics = diagnostics,
)
