@file:OptIn(com.typewritermc.authoring.GeneratedSdkApi::class)

package com.typewritermc.realm

import com.typewritermc.authoring.RealmRoot
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.assemble
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.Library
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.Tag
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.Taxonomy
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.Ref
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.endpoint
import com.typewritermc.types.fieldMap
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValuePath
import java.nio.file.Path

/** Resource ids of the realm root and the core sections in test resource graphs. */
internal object TestRealmStructure {
    val root = ResourceId(value = "realm-root")
    val library = ResourceId(value = "realm-library")
    val taxonomy = ResourceId(value = "realm-taxonomy")

    /** A placeholder owner link for a Book; [withRealmStructure] rewrites it with its inverse location. */
    val libraryLink = Ref<com.typewritermc.library.LibraryBooks.Book, Library>(library.toResourceId())

    /** A placeholder owner link for a Tag; [withRealmStructure] rewrites it with its inverse location. */
    val taxonomyLink = Ref<com.typewritermc.library.TaxonomyTags.Tag, Taxonomy>(taxonomy.toResourceId())
}

/**
 * Adds the realm root, the Library and the Taxonomy to a test resource graph built on the core catalog, so every Book
 * and Tag has its section as owner, as the realm guarantees. Books and Tags keep their order; their owner links are
 * rewritten to point at the matching item of the section's link field.
 */
internal fun Map<ResourceId, AuthoringRecord>.withRealmStructure(catalog: AuthoringCatalogLease): Map<ResourceId, AuthoringRecord> {
    val books = filterValues { it.configuration.definition == BookDefinition.id }.keys.toList()
    val tags = filterValues { it.configuration.definition == TagDefinition.id }.keys.toList()

    /** The member's owner link, pointing at its item in the section's link field. */
    fun owned(
        id: ResourceId,
        record: AuthoringRecord,
    ): AuthoringRecord {
        val owner =
            when (record.configuration.definition) {
                BookDefinition.id -> SectionMembership("library", TestRealmStructure.library, "books", books)
                TagDefinition.id -> SectionMembership("taxonomy", TestRealmStructure.taxonomy, "tags", tags)
                else -> return record
            }
        val opposite =
            ValuePath(
                segments =
                    listOf(
                        PathSegment.createField(name = owner.collection),
                        PathSegment.createItem(id = ItemId(value = "native:${owner.members.indexOf(id)}")),
                    ),
            )
        val link = record.fieldMap.getValue(owner.field) as DataValue.NamedWrapper
        val endpoint = (link.payload as DataValue.LinkWrapper).endpoint
        val rewritten =
            DataValue.named(
                link.actualType,
                DataValue.createLink(endpoint = endpoint, target = LinkTarget(resource = owner.section, opposite = opposite)),
            )
        return record.with(owner.field, rewritten)
    }

    fun back(field: String) = ValuePath.root.field(field)
    val structure =
        mapOf(
            TestRealmStructure.root to
                catalog.record(
                    RealmRoot(
                        sections = listOf(Ref(TestRealmStructure.library.toResourceId()), Ref(TestRealmStructure.taxonomy.toResourceId())),
                    ),
                    RealmRootDefinition.id,
                ),
            TestRealmStructure.library to
                catalog.record(Library(books = books.map { Ref(it.toResourceId(), back("library")) }), LibraryDefinition.id),
            TestRealmStructure.taxonomy to
                catalog.record(Taxonomy(tags = tags.map { Ref(it.toResourceId(), back("taxonomy")) }), TaxonomyDefinition.id),
        )
    return mapValues { (id, record) -> owned(id, record) } + structure
}

/** Encodes a native value of [type] as an authored record through the catalog's native bindings. */
internal fun <T : Any> AuthoringCatalogLease.record(
    value: T,
    type: TypeDefinitionId,
): AuthoringRecord {
    val checked = (checked.resolve(type.use()) as Resolution.Ready).value

    @Suppress("UNCHECKED_CAST")
    val binding = nativeBindings.bind(checked) as NativeBinding<T>
    val encoded = binding.encodeGeneratedDefault(value) as DataValue.NamedWrapper
    return AuthoringRecord.of(
        TypeSelection.CompleteWrapper(encoded.actualType),
        (encoded.payload as DataValue.RecordWrapper).value.fieldMap,
    )
}

private data class SectionMembership(
    val field: String,
    val section: ResourceId,
    val collection: String,
    val members: List<ResourceId>,
)

/** A Book whose owner is the test Library. */
internal fun testBook(
    title: String = "",
    pages: List<Ref<com.typewritermc.library.BookPages.Book, com.typewritermc.library.Page>> = emptyList(),
): Book = Book(library = TestRealmStructure.libraryLink, title = title, pages = pages)

/** A Tag whose owner is the test Taxonomy. */
internal fun testTag(
    name: String = "",
    parents: Set<Ref<com.typewritermc.library.TagParents.Child, Tag>> = emptySet(),
    placement: com.typewritermc.authoring.GraphPlacement = com.typewritermc.authoring.GraphPlacement(),
): Tag = Tag(taxonomy = TestRealmStructure.taxonomyLink, name = name, parents = parents, placement = placement)

/**
 * The core catalog as discovery assembles it from the typewriter artifact, with [extraDeclarations] added before
 * assembly. Its realm root and sections are what Realm start provisions.
 */
internal fun coreRealmCatalog(
    generation: String,
    extraDeclarations: (CatalogContributions) -> List<OwnedTypeDeclaration> = { emptyList() },
): RealmCatalogIncarnation {
    val artifact =
        Path.of(
            Book::class.java.protectionDomain.codeSource.location
                .toURI(),
        )
    val deployment =
        GeneratedProviderLoader().load(
            listOf(GeneratedProviderArtifact(ArtifactId("typewriter"), artifact)),
            DeploymentFacts(),
            DiscoveryDomains.Realm,
            runtimeServices = mapOf(PresentationRuntime::class.java to DefaultPresentationRuntime()),
        )
    val core = deployment.providers.contributions
    val assembly =
        core
            .copy(declarations = core.declarations + extraDeclarations(core))
            .assemble(CatalogAssemblyContext(CatalogGeneration(value = generation)))
    return RealmCatalogIncarnation(assembly, deployment)
}
