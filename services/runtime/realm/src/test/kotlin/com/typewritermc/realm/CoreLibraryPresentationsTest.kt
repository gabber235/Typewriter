package com.typewritermc.realm

import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.elements.Element
import com.typewritermc.elements.Entry
import com.typewritermc.library.Book
import com.typewritermc.library.Page
import com.typewritermc.library.TAG_COLLECTION_SOURCE_ID
import com.typewritermc.library.Tag
import com.typewritermc.presentation.PresentationCatalogAssembler
import com.typewritermc.presentation.CollectionProjectionCatalogAssembler
import com.typewritermc.presentation.CollectionProjectionProvider
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.library.CoreResourceDefinitionIds
import com.typewritermc.types.CatalogAbstractTypePrototype
import com.typewritermc.types.CatalogMetadataTypePrototype
import com.typewritermc.types.Icon
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.PresentationId
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.RolePresentationStatus
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
import skirout.editor.v1.presentation.PresentationDefinition
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationTextOverflow
import skirout.editor.v1.presentation.PresentationTextTone
import skirout.editor.v1.presentation.SearchProvider
import skirout.editor.v1.presentation.TextContent

val CoreLibraryPresentationsTest by testSuite {
    test("discovered core declarations assemble editor and contextual roles") {
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

        val presentationBindings = classLoader.getResources("META-INF/typewriter/contributions/types/presentations.cbor")
            .toList().flatMap { resource -> resource.openStream().use { TypeDiscoveryContributionCodec.decode(it.readAllBytes()).executableBindings } }
        val providers = presentationBindings.map { binding ->
            val providerClass = binding.moduleProviderClass.removeSuffix("DiscoveryModule") + "Provider"
            Class.forName(providerClass, true, classLoader).getDeclaredConstructor(String::class.java, String::class.java)
                .newInstance(CORE_NAMESPACE, "core-library") as PresentationProvider
        }
        val projectionBindings = classLoader.getResources("META-INF/typewriter/contributions/types/collection-projections.cbor")
            .toList().flatMap { resource -> resource.openStream().use { TypeDiscoveryContributionCodec.decode(it.readAllBytes()).executableBindings } }
        val projectionProviders = projectionBindings.map { binding ->
            val providerClass = binding.moduleProviderClass.removeSuffix("DiscoveryModule") + "Provider"
            Class.forName(providerClass, true, classLoader).getDeclaredConstructor(String::class.java)
                .newInstance("core-library") as CollectionProjectionProvider
        }
        val projections = CollectionProjectionCatalogAssembler.assemble(
            projectionProviders,
            prototypes,
            listOf(AuthoringResourceDefinition(CoreResourceDefinitionIds.TAG, TypeExpression.Named(prototypes.require(Tag::class).type))),
        )
        projections.diagnostics shouldBe emptyList()
        projections.definitions.map { it.sourceId } shouldBe listOf(TAG_COLLECTION_SOURCE_ID)
        val catalog = PresentationCatalogAssembler.assemble(
            providers, prototypes, TypeCatalog(definitions), collectionProjections = projections.definitions,
        )

        catalog.diagnostics shouldBe emptyList()
        definition(catalog.types, prototypes.require(Icon.Iconify::class).type)
            .rolePresentations[PresentationRole.EDITOR] shouldBe
            RolePresentationStatus.Ready(PresentationId(CORE_NAMESPACE, "icon.iconify.editor"))
        val iconify = catalog.definitions.single { it.presentationId.name == "icon.iconify.editor" }
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
        (iconifySearch.initialQuery != null) shouldBe true
        (iconifySearch.summary != null) shouldBe true
        (http.result.presentation.nodeId != suggested.result.presentation.nodeId) shouldBe true
        val resultText = textContents(http.result.presentation)
        resultText.size shouldBe 2
        resultText.all {
            it.paragraph.overflow == PresentationTextOverflow.CLIP && it.paragraph.tone == PresentationTextTone.PRIMARY
        } shouldBe true
        val summaryText = textContents(iconifySearch.summary!!)
        summaryText.size shouldBe 1
        summaryText.all {
            it.paragraph.overflow == PresentationTextOverflow.CLIP && it.paragraph.tone == PresentationTextTone.PRIMARY
        } shouldBe true
        resolveRole(catalog.types, prototypes.require(Book::class).type, PresentationRole.EDITOR) shouldBe
            PresentationId(CORE_NAMESPACE, "book.editor")
        resolveRole(catalog.types, prototypes.require(Tag::class).type, PresentationRole.EDITOR) shouldBe
            PresentationId(CORE_NAMESPACE, "tag.editor")
        resolveRole(catalog.types, prototypes.require(Page::class).type, PresentationRole.EDITOR) shouldBe
            PresentationId(CORE_NAMESPACE, "page.editor")
        listOf(PresentationRole.REFERENCE_SUMMARY, PresentationRole.REFERENCE_OPTION, PresentationRole.INSPECTOR_HEADER)
            .map { role -> resolveRole(catalog.types, prototypes.require(Book::class).type, role) }
            .distinct() shouldBe listOf(PresentationId(CORE_NAMESPACE, "book.reference"))
        listOf(PresentationRole.REFERENCE_SUMMARY, PresentationRole.REFERENCE_OPTION, PresentationRole.GRAPH_NODE, PresentationRole.INSPECTOR_HEADER)
            .map { role -> resolveRole(catalog.types, prototypes.require(Tag::class).type, role) }
            .distinct() shouldBe listOf(PresentationId(CORE_NAMESPACE, "tag.reference"))
        resolveRole(catalog.types, prototypes.require(Book::class).type, PresentationRole.CREATION) shouldBe
            PresentationId(CORE_NAMESPACE, "book.creation")
        resolveRole(catalog.types, prototypes.require(Page::class).type, PresentationRole.CREATION) shouldBe
            PresentationId(CORE_NAMESPACE, "page.creation")
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
            .single { it.presentationId.name == "book.editor" }
            .dependencies.collections
            .single()
            .sourceId shouldBe TAG_COLLECTION_SOURCE_ID
        catalog.definitions
            .single { it.presentationId.name == "book.creation" }
            .dependencies.collections shouldBe emptyList()
        sectionNames(catalog.definitions.single { it.presentationId.name == "book.editor" }) shouldBe
            listOf("title", "icon", "color", "tags", "effective-tags")
        sectionNames(catalog.definitions.single { it.presentationId.name == "book.creation" }) shouldBe
            listOf("title", "icon", "color", "tags")
        sectionNames(catalog.definitions.single { it.presentationId.name == "page.editor" }) shouldBe
            listOf("book", "name", "chapter", "priority")
        sectionNames(catalog.definitions.single { it.presentationId.name == "page.creation" }) shouldBe
            listOf("name", "chapter", "priority")
        catalog.definitions
            .single { it.presentationId.name == "tag.editor" }
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

private fun textContents(node: PresentationNode): List<TextContent> =
    when (val element = node.element) {
        is PresentationElement.TextWrapper -> listOf(element.value)
        is PresentationElement.ChildrenWrapper -> {
            val children =
                when (val layout = element.value) {
                    is ChildrenElement.RowWrapper -> layout.value.children
                    is ChildrenElement.ColumnWrapper -> layout.value.children
                    else -> emptyList()
                }
            children.flatMap { child ->
                when (child) {
                    is AxisChild.FixedWrapper -> textContents(child.value)
                    is AxisChild.FlexibleWrapper -> textContents(child.value.child)
                    else -> emptyList()
                }
            }
        }
        else -> emptyList()
    }

private const val CORE_NAMESPACE = "typewritermc:realm"

private fun sectionNames(definition: PresentationDefinition): List<String> {
    val children = (definition.root.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
    return children.value.children.map { (it as AxisChild.FixedWrapper).value.nodeId }
}

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
            .mapNotNull { reference -> (definition(catalog, reference).rolePresentations[role] as? RolePresentationStatus.Ready)?.id }
            .distinct()
            .singleOrNull()
            ?.let { return it }
        frontier = current.flatMapTo(linkedSetOf()) { reference -> definition(catalog, reference).parents }
    }
    return null
}
