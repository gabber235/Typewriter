package com.typewritermc.realm

import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.elements.Element
import com.typewritermc.elements.Entry
import com.typewritermc.library.Book
import com.typewritermc.library.Page
import com.typewritermc.library.TAG_COLLECTION_SOURCE_ID
import com.typewritermc.library.Tag
import com.typewritermc.presentation.PresentationCatalogAssembler
import com.typewritermc.types.CatalogAbstractTypePrototype
import com.typewritermc.types.CatalogMetadataTypePrototype
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.PresentationId
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototype
import com.typewritermc.types.TypePrototypeProvider
import com.typewritermc.types.TypePrototypeRegistry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.Expression
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.SearchProvider

val CoreLibraryPresentationsTest by testSuite {
    test("core providers assemble defaults and inherited resource roles for entry types") {
        val classLoader = DefaultRealmRuntimeFactory::class.java.classLoader
        val contributions =
            classLoader
                .getResources("META-INF/typewriter/contributions/types/declared.cbor")
                .toList()
                .map { resource -> resource.openStream().use { TypeDiscoveryContributionCodec.decode(it.readAllBytes()) } }
        val definitionsFromContributions = contributions.flatMap { it.definitions }.distinctBy { it.id }
        val bindings = contributions.flatMap { it.prototypeBindings }.distinctBy { it.type }
        val concrete =
            bindings
                .filter { DiscoveryDomains.Realm in it.domains }
                .map { binding ->
                    val provider =
                        Class
                            .forName(binding.prototypeProviderClass, true, classLoader)
                            .getDeclaredConstructor()
                            .newInstance() as TypePrototypeProvider
                    provider.prototype()
                }
        val boundTypes = concrete.mapTo(mutableSetOf()) { it.type }
        val metadata =
            definitionsFromContributions
                .filter { definition ->
                    definition.kind == NominalTypeKind.CONCRETE &&
                        definition.id.id is TypeId.Qualified &&
                        definition.id !in boundTypes
                }.mapNotNull { definition ->
                    val identity = definition.id.id as TypeId.Qualified
                    val runtimeType =
                        runCatching { Class.forName("${identity.namespace}.${identity.name}", false, classLoader).kotlin }
                            .getOrNull() ?: return@mapNotNull null
                    @Suppress("UNCHECKED_CAST")
                    CatalogMetadataTypePrototype(
                        runtimeType as kotlin.reflect.KClass<Any>,
                        definition.id,
                        definition,
                        (definition.representation as? TypeExpression.Record)
                            ?.fields
                            ?.associate { it.name to it.name }
                            .orEmpty(),
                    ) as TypePrototype<*>
                }
        val element = abstractDefinition(Element::class.qualifiedName!!, fields = listOf("id", "name"))
        val entry = abstractDefinition(Entry::class.qualifiedName!!, parents = listOf(element.id))
        val pageType = abstractDefinition(Page::class.qualifiedName!!, fields = listOf("book", "name", "chapter", "priority", "elements"))
        val inheritedEntry = qualified("test", "InheritedEntry")
        val entryDefinitions =
            listOf(
                TypeDefinition(inheritedEntry, NominalTypeKind.CONCRETE, parents = listOf(entry.id)),
            )
        val definitions =
            (definitionsFromContributions + element + entry + pageType + entryDefinitions)
                .associateBy(TypeDefinition::id)
                .values
                .toList()
        val prototypes =
            TypePrototypeRegistry(
                concrete + metadata +
                    listOf(
                        abstractPrototype(Element::class, element, mapOf("id" to "id", "name" to "name")),
                        abstractPrototype(Entry::class, entry, mapOf("id" to "id", "name" to "name")),
                        abstractPrototype(Page::class, pageType, mapOf("book" to "book", "name" to "name", "chapter" to "chapter", "priority" to "priority", "elements" to "elements")),
                    ),
                definitions,
            )

        val catalog =
            PresentationCatalogAssembler.assemble(
                coreLibraryPresentationProviders(),
                prototypes,
                TypeCatalog(definitions),
            )

        catalog.diagnostics shouldBe emptyList()
        val iconify = catalog.definitions.single { it.presentationId.name == "icon.iconify.default" }
        val iconifyChildren = (iconify.root.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
        val iconifyNode = (iconifyChildren.value.children.single() as AxisChild.FixedWrapper).value
        val iconifySearch = (iconifyNode.element as PresentationElement.SearchInputWrapper).value
        val merged = (iconifySearch.provider as SearchProvider.DistinctWrapper).value.child as SearchProvider.MergeWrapper
        val leaves = merged.value.children.map(::searchLeaf)
        val http = (leaves[0] as SearchProvider.HttpJsonWrapper).value
        val suggested = (leaves[1] as SearchProvider.StaticValuesWrapper).value
        http.resultPath shouldBe "$.icons[*]"
        http.parameters.map { it.name } shouldBe listOf("query", "prefix", "limit")
        (http.result.selectedValue.expression is Expression.RecordWrapper) shouldBe true
        (suggested.result.selectedValue.expression is Expression.RecordWrapper) shouldBe true
        (iconifySearch.customValue?.expression is Expression.RecordWrapper) shouldBe true
        (iconifySearch.summary != null) shouldBe true
        (http.result.presentation.nodeId != suggested.result.presentation.nodeId) shouldBe true
        definition(catalog.types, prototypes.require(Book::class).type).defaultPresentationId shouldBe
            PresentationId(CORE_NAMESPACE, "book.default")
        definition(catalog.types, prototypes.require(Tag::class).type).defaultPresentationId shouldBe
            PresentationId(CORE_NAMESPACE, "tag.default")
        definition(catalog.types, prototypes.require(Page::class).type).defaultPresentationId shouldBe
            PresentationId(CORE_NAMESPACE, "page.default")
        definition(catalog.types, element.id).rolePresentations.keys.shouldContainExactlyInAnyOrder(
            PresentationRole.REFERENCE_SUMMARY,
            PresentationRole.REFERENCE_OPTION,
            PresentationRole.CATALOG_OPTION,
            PresentationRole.AUTHORING_RESULT,
            PresentationRole.INSPECTOR_HEADER,
        )
        resolveRole(catalog.types, inheritedEntry, PresentationRole.GRAPH_NODE) shouldBe
            PresentationId(CORE_NAMESPACE, "entry.graph")
        resolveRole(catalog.types, inheritedEntry, PresentationRole.REFERENCE_SUMMARY) shouldBe
            PresentationId(CORE_NAMESPACE, "element.reference")
        catalog.definitions
            .single { it.presentationId.name == "book.default" }
            .dependencies.collections
            .single()
            .sourceId shouldBe TAG_COLLECTION_SOURCE_ID
        catalog.definitions
            .single { it.presentationId.name == "tag.default" }
            .dependencies.collections
            .single()
            .sourceId shouldBe TAG_COLLECTION_SOURCE_ID
    }
}

private fun searchLeaf(provider: SearchProvider): SearchProvider =
    when (provider) {
        is SearchProvider.GateWrapper -> searchLeaf(provider.value.child)
        is SearchProvider.DebounceWrapper -> searchLeaf(provider.value.child)
        is SearchProvider.RankWrapper -> searchLeaf(provider.value.child)
        is SearchProvider.LimitWrapper -> searchLeaf(provider.value.child)
        is SearchProvider.CacheWrapper -> searchLeaf(provider.value.child)
        is SearchProvider.HistoryWrapper -> searchLeaf(provider.value.child)
        is SearchProvider.SectionWrapper -> searchLeaf(provider.value.child)
        else -> provider
    }

private const val CORE_NAMESPACE = "typewriter.core"

private fun qualified(
    namespace: String,
    name: String,
) = ResolvedTypeRef(TypeId.Qualified(namespace, name), 1)

private fun abstractDefinition(
    qualifiedName: String,
    fields: List<String> = emptyList(),
    parents: List<ResolvedTypeRef> = emptyList(),
): TypeDefinition {
    val namespace = qualifiedName.substringBeforeLast('.')
    val name = qualifiedName.substringAfterLast('.')
    return TypeDefinition(
        id = qualified(namespace, name),
        kind = NominalTypeKind.OPEN_ABSTRACT,
        representation =
            TypeExpression.Record(fields.map { field -> TypeField(field, TypeExpression.StringType()) }),
        parents = parents,
    )
}

private fun <T : Any> abstractPrototype(
    runtimeType: kotlin.reflect.KClass<T>,
    definition: TypeDefinition,
    fields: Map<String, String> = emptyMap(),
): TypePrototype<T> = CatalogAbstractTypePrototype(runtimeType, definition.id, definition, fields)

private fun definition(
    catalog: TypeCatalog,
    reference: ResolvedTypeRef,
): TypeDefinition = catalog.definitions.single { it.id == reference }

private fun resolveRole(
    catalog: TypeCatalog,
    type: ResolvedTypeRef,
    role: PresentationRole,
): PresentationId? {
    var frontier = setOf(type)
    val visited = mutableSetOf<ResolvedTypeRef>()
    while (frontier.isNotEmpty()) {
        val current = frontier - visited
        visited += current
        current
            .mapNotNull { reference -> definition(catalog, reference).rolePresentations[role] }
            .distinct()
            .singleOrNull()
            ?.let { return it }
        frontier = current.flatMapTo(linkedSetOf()) { reference -> definition(catalog, reference).parents }
    }
    return null
}
