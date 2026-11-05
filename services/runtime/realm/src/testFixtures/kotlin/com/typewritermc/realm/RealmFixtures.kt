@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm

import build.skir.Serializer
import com.surrealdb.Surreal
import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedPresentationProvider
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderDeployment
import com.typewritermc.discovery.GeneratedProviderInstantiator
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.GeneratedRuntimeRegistrarProvider
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeRegistrarDescriptor
import com.typewritermc.discovery.RuntimeRegistrarId
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.discovery.assemble
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ProducerId
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.BookFields
import com.typewritermc.library.BookPages
import com.typewritermc.library.BookTags
import com.typewritermc.library.LibraryBooks
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.LibraryFields
import com.typewritermc.library.PageDefinition
import com.typewritermc.library.Tag
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TagFields
import com.typewritermc.library.TagParents
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.library.TaxonomyFields
import com.typewritermc.library.TaxonomyTags
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.HostedArtifactPackage
import com.typewritermc.loader.api.HostedExtensionArtifact
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.HostedSourcePart
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactCatalog
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.loader.api.artifact.SharedCatalogRevision
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.of
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.realm.edit.SurrealAuthoringStorage
import com.typewritermc.realm.operation.PreparationEvaluator
import com.typewritermc.realm.publication.StagedEngineImplementationSource
import com.typewritermc.realm.routes.PANEL_REPLY_INBOX
import com.typewritermc.realm.storage.DatabaseAuthentication
import com.typewritermc.realm.storage.DatabaseEndpoint
import com.typewritermc.realm.storage.RealmDatabaseProvider
import com.typewritermc.realm.storage.SchemaMigrator
import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.codes
import com.typewritermc.realm.testing.itemIds
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.linkTargets
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.storeSeed
import com.typewritermc.realm.testing.typesOf
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.FakeDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import com.typewritermc.testing.routes.FixtureTimelinePage
import com.typewritermc.testing.routes.FixtureTimelinePageDefinition
import com.typewritermc.testkit.ready
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.Ref
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.requireValid
import com.typewritermc.types.template
import com.typewritermc.types.toResourceId
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.ints.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.bind
import io.kotest.property.arbitrary.boolean
import io.kotest.property.arbitrary.choose
import io.kotest.property.arbitrary.constant
import io.kotest.property.arbitrary.enum
import io.kotest.property.arbitrary.int
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.map
import io.kotest.property.checkAll
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.InputToken
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import java.io.File
import java.net.URI
import java.nio.file.Files
import java.nio.file.Path
import java.util.Properties
import java.util.jar.JarEntry
import java.util.jar.JarOutputStream
import kotlin.io.path.extension
import kotlin.io.path.name
import kotlin.io.path.nameWithoutExtension
import kotlin.time.Duration.Companion.seconds

internal fun settings(vararg values: Pair<String, String>): RealmSettings = RealmSettings(configuration = mapOf(*values))

internal class FakeManagedRealmRuntime(
    private val failActivation: Boolean = false,
) : ManagedRealmRuntime {
    var released = false
        private set

    override suspend fun activate() {
        if (failActivation) error("catalog activation failed")
    }

    override suspend fun quiesce() = Unit

    override suspend fun resume() = Unit

    override suspend fun stop() {
        released = true
    }
}

/** How many resources a step can tell apart; an index picks among what the model holds, modulo its size. */
internal val index = Arb.int(0..7)

internal enum class Kind { Book, Page, Tag }

/** An author's intent with resources named by index into what the model holds, so most steps mean something. */
internal sealed interface Step {
    data object CreateBook : Step

    data class CreatePage(
        val book: Int,
    ) : Step

    data object CreateTag : Step

    data class TagBook(
        val book: Int,
        val tag: Int,
    ) : Step

    data class UntagBook(
        val book: Int,
        val tag: Int,
    ) : Step

    data class ParentTag(
        val child: Int,
        val parent: Int,
    ) : Step

    data class UnparentTag(
        val child: Int,
        val parent: Int,
    ) : Step

    data class MovePage(
        val page: Int,
        val book: Int,
    ) : Step

    data class UnlistPage(
        val page: Int,
    ) : Step

    data class Delete(
        val kind: Kind,
        val index: Int,
    ) : Step

    data class DeleteSection(
        val library: Boolean,
    ) : Step
}

internal val step: Arb<Step> =
    Arb.choose(
        3 to Arb.constant(Step.CreateBook),
        4 to index.map(Step::CreatePage),
        4 to Arb.constant(Step.CreateTag),
        4 to Arb.bind(index, index, Step::TagBook),
        3 to Arb.bind(index, index, Step::UntagBook),
        5 to Arb.bind(index, index, Step::ParentTag),
        3 to Arb.bind(index, index, Step::UnparentTag),
        3 to Arb.bind(index, index, Step::MovePage),
        1 to index.map(Step::UnlistPage),
        3 to Arb.bind(Arb.enum<Kind>(), index, Step::Delete),
        1 to Arb.boolean().map(Step::DeleteSection),
    )

/** A step with its resources resolved to ids. */
internal sealed interface Action {
    data class CreateBook(
        val book: ResourceId,
    ) : Action

    data class CreatePage(
        val page: ResourceId,
        val book: ResourceId,
    ) : Action

    data class CreateTag(
        val tag: ResourceId,
    ) : Action

    data class TagBook(
        val book: ResourceId,
        val tag: ResourceId,
    ) : Action

    data class UntagBook(
        val book: ResourceId,
        val tag: ResourceId,
    ) : Action

    data class ParentTag(
        val child: ResourceId,
        val parent: ResourceId,
    ) : Action

    data class UnparentTag(
        val child: ResourceId,
        val parent: ResourceId,
    ) : Action

    data class MovePage(
        val page: ResourceId,
        val book: ResourceId,
    ) : Action

    data class UnlistPage(
        val page: ResourceId,
        val book: ResourceId,
    ) : Action

    data class Delete(
        val resource: ResourceId,
    ) : Action

    data class DeleteSection(
        val section: ResourceId,
    ) : Action
}

/**
 * What the realm should hold after the steps it admitted: plain maps, with its own rules for refusals and deletion, and
 * no knowledge of how the planner reaches them.
 */
internal class RealmModel(
    val library: ResourceId,
    val taxonomy: ResourceId,
) {
    val books = linkedMapOf<ResourceId, MutableList<ResourceId>>()
    val pages = linkedMapOf<ResourceId, ResourceId>()
    val tags = linkedMapOf<ResourceId, MutableList<ResourceId>>()
    private var created = 0

    /** The action [step] names on what the model holds now, or null when it names a resource the model lacks. */
    fun resolve(step: Step): Action? =
        when (step) {
            Step.CreateBook -> Action.CreateBook(next("book"))
            is Step.CreatePage -> books.keys.pick(step.book)?.let { Action.CreatePage(next("page"), it) }
            Step.CreateTag -> Action.CreateTag(next("tag"))
            is Step.TagBook, is Step.UntagBook, is Step.ParentTag, is Step.UnparentTag -> resolveLink(step)
            is Step.MovePage, is Step.UnlistPage, is Step.Delete, is Step.DeleteSection -> resolveRemoval(step)
        }

    private fun resolveLink(step: Step): Action? =
        when (step) {
            is Step.TagBook -> {
                both(books.keys.pick(step.book), tags.keys.pick(step.tag), Action::TagBook)
            }

            is Step.UntagBook -> {
                books.linked().pick(step.book)?.let { both(it, books.getValue(it).pick(step.tag), Action::UntagBook) }
            }

            is Step.ParentTag -> {
                both(tags.keys.pick(step.child), tags.keys.pick(step.parent), Action::ParentTag)
            }

            is Step.UnparentTag -> {
                tags
                    .linked()
                    .pick(
                        step.child,
                    )?.let { both(it, tags.getValue(it).pick(step.parent), Action::UnparentTag) }
            }

            else -> {
                error("$step is no link step")
            }
        }

    private fun resolveRemoval(step: Step): Action? =
        when (step) {
            is Step.MovePage -> both(pages.keys.pick(step.page), books.keys.pick(step.book), Action::MovePage)
            is Step.UnlistPage -> pages.keys.pick(step.page)?.let { Action.UnlistPage(it, pages.getValue(it)) }
            is Step.Delete -> idsOf(step.kind).pick(step.index)?.let(Action::Delete)
            is Step.DeleteSection -> Action.DeleteSection(if (step.library) library else taxonomy)
            else -> error("$step is no removal step")
        }

    private fun idsOf(kind: Kind): Collection<ResourceId> =
        when (kind) {
            Kind.Book -> books.keys
            Kind.Page -> pages.keys
            Kind.Tag -> tags.keys
        }

    /**
     * The code the realm must refuse [action] for, or null when it must commit it. A tag named twice on a book or as a
     * parent commits: authoring keeps the duplicate and publication reports it, so the model holds both.
     */
    fun refusal(action: Action): String? =
        when (action) {
            is Action.ParentTag -> "relation_cycle".takeIf { action.child == action.parent || action.child in ancestors(action.parent) }
            is Action.UnlistPage -> "owner_required"
            is Action.DeleteSection -> "singleton_required"
            else -> null
        }

    fun apply(action: Action) {
        when (action) {
            is Action.CreateBook -> books[action.book] = mutableListOf()
            is Action.CreatePage -> pages[action.page] = action.book
            is Action.CreateTag -> tags[action.tag] = mutableListOf()
            is Action.TagBook -> books.getValue(action.book) += action.tag
            is Action.UntagBook -> books.getValue(action.book) -= action.tag
            is Action.ParentTag -> tags.getValue(action.child) += action.parent
            is Action.UnparentTag -> tags.getValue(action.child) -= action.parent
            is Action.MovePage -> pages[action.page] = action.book
            is Action.Delete -> delete(action.resource)
            is Action.UnlistPage, is Action.DeleteSection -> error("$action is always refused")
        }
    }

    /** A book takes its pages with it; a deleted tag disappears from every book and child that named it. */
    private fun delete(resource: ResourceId) {
        if (books.remove(resource) != null) pages.values.removeAll { it == resource }
        pages.remove(resource)
        if (tags.remove(resource) != null) {
            books.values.forEach { tags -> tags.removeAll { it == resource } }
            tags.values.forEach { parents -> parents.removeAll { it == resource } }
        }
    }

    private fun ancestors(tag: ResourceId): Set<ResourceId> {
        val found = linkedSetOf<ResourceId>()
        val pending = ArrayDeque(tags.getValue(tag))
        while (pending.isNotEmpty()) {
            val next = pending.removeFirst()
            if (found.add(next)) pending += tags.getValue(next)
        }
        return found
    }

    private fun next(kind: String) = ResourceId(value = "$kind-${++created}")

    private fun Collection<ResourceId>.pick(index: Int): ResourceId? = if (isEmpty()) null else elementAt(index % size)

    /** The resources that link to at least one other through the collection the map holds. */
    private fun Map<ResourceId, List<ResourceId>>.linked() = filterValues { it.isNotEmpty() }.keys

    private fun <A> both(
        first: ResourceId?,
        second: ResourceId?,
        action: (ResourceId, ResourceId) -> A,
    ): A? = if (first == null || second == null) null else action(first, second)
}

/** Commits [action] as an author's edit through the Realm's edit context. */
internal suspend fun RealmFixture.write(action: Action): CommitPreparedEditResponse {
    val saved = resources
    return commit {
        when (action) {
            is Action.CreateBook -> {
                val record =
                    encoder
                        .record(
                            BookDefinition.id.use(),
                            Book(library = Ref(action.book.author)),
                        ).with("library", DataValue.UNFILLED)
                create(action.book.author, record)
                insert(listAt(saved.libraryOf(), LibraryFields.books.path), null, link(BOOK_IN_LIBRARY, action.book))
            }

            is Action.CreatePage -> {
                val page = FixtureTimelinePage(book = Ref(action.book.author), name = action.page.value)
                create(action.page.author, encoder.record(FixtureTimelinePageDefinition.id.use(), page).with("book", DataValue.UNFILLED))
                insert(listAt(action.book, BookFields.pages.path), null, link(PAGE_IN_BOOK, action.page))
            }

            is Action.CreateTag -> {
                val tag = Tag(taxonomy = Ref(action.tag.author), name = action.tag.value, placement = GraphPlacement())
                create(action.tag.author, encoder.record(TagDefinition.id.use(), tag).with("taxonomy", DataValue.UNFILLED))
                insert(listAt(saved.taxonomyOf(), TaxonomyFields.tags.path), null, link(TAG_IN_TAXONOMY, action.tag))
            }

            is Action.TagBook -> {
                insert(listAt(action.book, BookFields.tags.path), null, link(TAG_ON_BOOK, action.tag))
            }

            is Action.UntagBook -> {
                remove(listAt(action.book, BookFields.tags.path), saved.itemOf(action.book, "tags", action.tag))
            }

            is Action.ParentTag -> {
                insert(listAt(action.child, TagFields.parents.path), null, link(TAG_PARENT, action.parent))
            }

            is Action.UnparentTag -> {
                remove(listAt(action.child, TagFields.parents.path), saved.itemOf(action.child, "parents", action.parent))
            }

            is Action.MovePage -> {
                insert(listAt(action.book, BookFields.pages.path), null, link(PAGE_IN_BOOK, action.page))
            }

            is Action.UnlistPage -> {
                remove(listAt(action.book, BookFields.pages.path), saved.itemOf(action.book, "pages", action.page))
            }

            is Action.Delete -> {
                delete(action.resource.author)
            }

            is Action.DeleteSection -> {
                delete(action.section.author)
            }
        }
    }
}

internal val BOOK_IN_LIBRARY =
    LibraryBooks.Library.Definition.id
        .namedUse(listOf(BookDefinition.id.use()))
        .use

internal val PAGE_IN_BOOK =
    BookPages.Book.Definition.id
        .namedUse(listOf(PageDefinition.id.use()))
        .use

internal val TAG_IN_TAXONOMY =
    TaxonomyTags.Taxonomy.Definition.id
        .namedUse(listOf(TagDefinition.id.use()))
        .use

internal val TAG_ON_BOOK =
    BookTags.Book.Definition.id
        .namedUse(listOf(TagDefinition.id.use()))
        .use

internal val TAG_PARENT =
    TagParents.Child.Definition.id
        .namedUse(listOf(TagDefinition.id.use()))
        .use

internal val ResourceId.author get() = toResourceId()

internal fun listAt(
    resource: ResourceId,
    path: ValuePath,
) = boundCollectionPath(ValueLocation.of(resource, path))

internal fun RealmFixture.link(
    item: skirout.editor.v1.type_catalog.TypeUse,
    target: ResourceId,
): DataValue = encoder.encode(item, Ref<Nothing, Nothing>(target.author))

internal fun Map<ResourceId, AuthoringRecord>.libraryOf() = typesOf(LibraryDefinition.id).single()

internal fun Map<ResourceId, AuthoringRecord>.taxonomyOf() = typesOf(TaxonomyDefinition.id).single()

/** The item of the collection [field] of [holder] that links to [target]. */
internal fun Map<ResourceId, AuthoringRecord>.itemOf(
    holder: ResourceId,
    field: String,
    target: ResourceId,
) = getValue(holder).let { record ->
    record
        .itemIds(field)
        .zip(record.links(field))
        .first { it.second == target }
        .first
}

/** The collections that own what they list, by the type that holds them and the field. */
internal val OWNING_LISTS =
    mapOf(
        RealmRootDefinition.id to "sections",
        LibraryDefinition.id to "books",
        BookDefinition.id to "pages",
        TaxonomyDefinition.id to "tags",
    )

/** The field through which an owned resource names its owner, for types that have one. */
internal val OWNER_FIELDS =
    mapOf(
        BookDefinition.id to "library",
        FixtureTimelinePageDefinition.id to "book",
        TagDefinition.id to "taxonomy",
    )

internal val AuthoringRecord.type: TypeDefinitionId get() = configuration.definition

/**
 * Rules every saved state keeps, whatever was edited: one root; every link names a saved resource; every resource but
 * the root is listed by exactly one owner and names that owner back; a link that names its opposite field is listed
 * there; no tag is its own ancestor.
 */
internal fun Map<ResourceId, AuthoringRecord>.shouldHoldInvariants() {
    val root = typesOf(RealmRootDefinition.id).single()
    forEach { (id, record) ->
        record.fields.forEach { field ->
            field.value.links().forEach { target ->
                withClue("$id ${field.name} links to ${target.resource.value}") {
                    (target.resource in this) shouldBe true
                    target.opposite?.let { opposite ->
                        getValue(target.resource)
                            .valueAt(opposite)
                            ?.links()
                            .orEmpty()
                            .map { it.resource } shouldContainAll listOf(id)
                    }
                }
            }
        }
    }
    val owners =
        entries
            .flatMap { (holder, record) -> OWNING_LISTS[record.type]?.let { field -> record.links(field).map { it to holder } }.orEmpty() }
            .groupBy({ it.first }, { it.second })
    keys.forEach { id ->
        withClue("owners of ${id.value}") {
            if (id == root) {
                owners[id] shouldBe null
            } else {
                val owner = owners[id].orEmpty()
                owner.size shouldBe 1
                OWNER_FIELDS[getValue(id).type]?.let { getValue(id).link(it) shouldBe owner.single() }
            }
        }
    }
    val parents = typesOf(TagDefinition.id).associateWith { getValue(it).links("parents") }
    parents.keys.forEach { tag ->
        val seen = mutableSetOf<ResourceId>()
        val pending = ArrayDeque(parents.getValue(tag))
        while (pending.isNotEmpty()) {
            val next = pending.removeFirst()
            withClue("tag ${tag.value} reaches itself through its parents") { (next == tag) shouldBe false }
            if (seen.add(next)) pending += parents[next].orEmpty()
        }
    }
}

/** The saved state holds exactly the model's books, pages and tags beside the provisioned [structure], linked as it says. */
internal fun Map<ResourceId, AuthoringRecord>.shouldMatch(
    model: RealmModel,
    structure: Set<ResourceId>,
) {
    keys shouldBe structure + model.books.keys + model.pages.keys + model.tags.keys
    typesOf(BookDefinition.id).toSet() shouldBe model.books.keys
    typesOf(FixtureTimelinePageDefinition.id).toSet() shouldBe model.pages.keys
    typesOf(TagDefinition.id).toSet() shouldBe model.tags.keys
    model.pages.forEach { (page, book) -> withClue("book of ${page.value}") { getValue(page).link("book") shouldBe book } }
    model.books.forEach { (book, tags) ->
        withClue("tags of ${book.value}") { getValue(book).links("tags").sortedBy { it.value } shouldBe tags.sortedBy { it.value } }
    }
    model.tags.forEach { (tag, parents) ->
        withClue("parents of ${tag.value}") { getValue(tag).links("parents").sortedBy { it.value } shouldBe parents.sortedBy { it.value } }
    }
}

/** The links a saved field value holds: itself when it is a link, its items when it is a list or set of links. */
internal fun DataValue.links(): List<LinkTarget> =
    when (val value = unwrapNamed()) {
        is DataValue.LinkWrapper -> listOf(value.value.target)
        is DataValue.ListValueWrapper -> value.items.flatMap { it.value.links() }
        is DataValue.SetValueWrapper -> value.items.flatMap { it.value.links() }
        else -> emptyList()
    }

/** Realm request subjects with a subscription that is still open. */
internal fun FakeMessageTransport.activeRealmRoutes(): Set<String> {
    val open = mutableMapOf<String, Int>()
    actions.forEach { action ->
        when (action) {
            is FakeMessageTransport.Action.Subscribe -> open.merge(action.pattern.value, 1, Int::plus)
            is FakeMessageTransport.Action.SubscriptionClose -> open.merge(action.pattern.value, -1, Int::plus)
            else -> Unit
        }
    }
    return open.filter { (subject, count) -> count > 0 && subject.startsWith("service.to.") }.keys
}

internal class RealmLifecycleFixture(
    scope: kotlinx.coroutines.CoroutineScope,
    catalog: RealmCatalogIncarnation? = null,
    initialSeed: AuthoringSeed? = null,
    catalogActivator: RealmCatalogActivator? = null,
) {
    private val telemetry = TelemetryTestHarness.create()
    private val sharedArtifacts = InMemorySharedArtifacts()
    private val catalogs =
        RealmCatalogStore().also { store ->
            if (catalog == null) store.installTestCatalog("lifecycle_catalog") else store.replace(catalog)
        }
    val messaging = MutableStateFlow<HostedMessagingSession?>(null)
    val delayScheduler = FakeDelayScheduler(holdDelays = true)
    var databaseOpen = false
        private set
    val artifactWrites: Int
        get() = sharedArtifacts.completedWrites
    private val host =
        object : HostedRuntimeHost {
            override val publicationRetention =
                com.typewritermc.realm.publication
                    .TestPublicationRetention()
            override val messaging = this@RealmLifecycleFixture.messaging
            override val openTelemetry = telemetry.openTelemetry
            override val sharedArtifacts = this@RealmLifecycleFixture.sharedArtifacts
        }
    private val realm =
        Realm(
            databaseProvider =
                TestDatabaseProvider(
                    onConnect = { databaseOpen = true },
                    onClose = { databaseOpen = false },
                    initialize = { database -> initialSeed?.let { SurrealAuthoringStorage(database).storeSeed(it.resources) } },
                ),
            catalogs = catalogs,
            scope = scope,
            telemetry = telemetry.telemetry,
            retryPolicy = RetryPolicy.fixed(1.seconds),
            delayScheduler = delayScheduler,
            host = host,
            registrars = emptyList(),
            facts = DeploymentFacts(),
            preparationEvaluator = PreparationEvaluator { _, _ -> error("Preparation is not used by lifecycle tests.") },
            engine =
                StagedEngineImplementationSource(
                    EngineImplementationInputs(
                        token =
                            skirout.editor.v1.type_catalog
                                .InputToken(value = "engine"),
                    ),
                ),
            catalogActivator =
                catalogActivator ?: RealmCatalogActivator { repository, catalog ->
                    repository.activateCatalog(catalog, install = {}, publish = {})
                },
        )

    fun session(id: Long): TestSession {
        val transport = FakeMessageTransport()
        val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
        return TestSession(HostedMessagingSession(id, "organization", communicator), transport)
    }

    suspend fun <Request : Any, Response : Any> request(
        session: TestSession,
        suffix: String,
        request: Request,
        requestSerializer: Serializer<Request>,
        responseSerializer: Serializer<Response>,
    ): Response {
        val reply =
            session.transport.exchange(
                to = MessageAddress.of("service.to.realm.organization.organization.realm.$suffix"),
                payload = requestSerializer.toBytes(request).toByteArray(),
                replyTo = MessageAddress.of("$PANEL_REPLY_INBOX.${replySequence++}"),
            )
        return responseSerializer.fromBytes(reply.toByteArray())
    }

    suspend fun start() {
        telemetry.telemetry.mainSpan(
            name = "test.realm.start",
            unhandledFailureSlug = ErrorSlug.of("test-realm-start-failed"),
        ) {
            realm.start("realm")
        }
        databaseOpen shouldBe true
    }

    suspend fun stop() {
        realm.shutdown()
    }

    suspend fun close() {
        try {
            realm.shutdown()
            databaseOpen shouldBe false
        } finally {
            catalogs.close()
            telemetry.close()
        }
    }

    private var replySequence = 0
}

internal class InMemorySharedArtifacts : SharedArtifactAccess {
    private val artifacts = mutableMapOf<ArtifactDigest, ByteArray>()
    var completedWrites = 0
        private set

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        artifacts[digest]
            ?.let { BlobResult.Success(BlobMetadata(digest, it.size.toLong())) }
            ?: BlobResult.NotFound

    override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> =
        artifacts[digest]?.let { BlobResult.Success(it.copyOf()) } ?: BlobResult.NotFound

    override suspend fun store(
        expected: BlobMetadata,
        content: ByteArray,
    ): StoreResult {
        if (content.size.toLong() != expected.size || ArtifactDigest.sha256(content) != expected.digest) {
            return StoreResult.Invalid("Content does not match its metadata.")
        }
        artifacts[expected.digest] = content.copyOf()
        completedWrites++
        return StoreResult.Stored(expected)
    }

    override suspend fun publish(command: PublishSharedArtifact): PublishResult = error("Catalog writes are not used.")

    override suspend fun delete(
        id: SharedArtifactId,
        expectedRevision: SharedArtifactRevision,
        provenance: SharedArtifactProvenance,
    ): PublishResult = error("Catalog deletes are not used.")

    override suspend fun catalog() = SharedArtifactCatalog(SharedCatalogRevision(0), emptyList())
}

internal data class TestSession(
    val session: HostedMessagingSession,
    val transport: FakeMessageTransport,
)

internal class TestDatabaseProvider(
    private val onConnect: () -> Unit,
    private val onClose: () -> Unit,
    private val initialize: (Surreal) -> Unit = {},
) : RealmDatabaseProvider {
    context(_: MainSpanScope)
    override fun connect(): Surreal {
        onConnect()
        return Surreal().apply {
            connect("memory")
            useNs("realm_lifecycle_test").useDb("realm_lifecycle_test")
            SchemaMigrator(this).migrate()
            initialize(this)
        }
    }

    override fun close(database: Surreal) {
        try {
            onClose()
        } finally {
            database.close()
        }
    }
}

/**
 * Each Realm package may reference only the packages listed here, and this test checks that the map is acyclic,
 * so the Realm has no package cycles. References are read from imports and from fully qualified names in code
 * (comments and the package line are ignored), and wildcard imports are rejected, so reading them is exact.
 */
internal val ALLOWED: Map<String, Set<String>> =
    mapOf(
        "storage" to setOf(),
        "catalog" to setOf(),
        "authoring" to setOf("catalog"),
        "search" to setOf("authoring", "catalog", "storage"),
        "checking" to setOf("authoring", "catalog"),
        "edit" to setOf("authoring", "catalog", "search", "storage"),
        "operation" to setOf("edit", "checking", "authoring", "catalog"),
        "publication" to setOf("checking", "authoring", "catalog", "storage"),
        "routes" to setOf("operation", "publication", "edit", "checking", "search", "authoring", "catalog"),
        ROOT to setOf("routes", "operation", "publication", "edit", "checking", "search", "authoring", "catalog", "storage"),
    )

internal val PACKAGE_LINE = Regex("""^package com\.typewritermc\.realm(?:\.(\w+))?""", RegexOption.MULTILINE)

internal val IMPORT_LINE = Regex("""^import com\.typewritermc\.realm\.(\w+)""", RegexOption.MULTILINE)

internal val HEADER_LINE = Regex("""^(?:package|import) .*$""", RegexOption.MULTILINE)

internal val QUALIFIED_REFERENCE = Regex("""(?<![\w.])com\.typewritermc\.realm\.(\w+)""")

/** Strings are matched only so that comment markers inside them are not mistaken for comments. */
internal val COMMENT_OR_STRING = Regex("\"\"\"[\\s\\S]*?\"\"\"|\"(?:\\\\.|[^\"\\\\\\n])*\"|//[^\\n]*|/\\*[\\s\\S]*?\\*/")

internal class RealmSource(
    val file: File,
    val pkg: String,
    val references: Set<String>,
)

/** A first segment naming a declared package refers to that package; any other names a root declaration. */
internal fun realmPackageOf(segment: String): String = if (segment in ALLOWED.keys) segment else ROOT

/** Realm packages that [text] references through imports or fully qualified names in code. */
internal fun realmReferences(text: String): Set<String> {
    val code =
        COMMENT_OR_STRING
            .replace(text) { if (it.value.startsWith("/")) it.value.replace(Regex("[^\\n]"), " ") else it.value }
    val imports = IMPORT_LINE.findAll(code).map { it.groupValues[1] }
    val qualified = QUALIFIED_REFERENCE.findAll(HEADER_LINE.replace(code, "")).map { it.groupValues[1] }
    return (imports + qualified).map(::realmPackageOf).toSet()
}

internal fun realmSources(): List<RealmSource> =
    File("src/main/kotlin/com/typewritermc/realm")
        .walkTopDown()
        .filter { it.extension == "kt" }
        .map { file ->
            val text = file.readText()
            val pkg = PACKAGE_LINE.find(text)!!.groupValues[1].ifEmpty { ROOT }
            RealmSource(file, pkg, realmReferences(text))
        }.toList()

/** One cycle in [graph] as the path that closes it, or null when [graph] is acyclic. */
internal fun cycleIn(graph: Map<String, Set<String>>): List<String>? {
    val finished = mutableSetOf<String>()
    val path = mutableListOf<String>()

    fun visit(node: String): List<String>? {
        if (node in finished) return null
        val start = path.indexOf(node)
        if (start >= 0) return path.subList(start, path.size) + node
        path += node
        for (next in graph[node].orEmpty().sorted()) {
            visit(next)?.let { return it }
        }
        path.removeLast()
        finished += node
        return null
    }

    return graph.keys.sorted().firstNotNullOfOrNull(::visit)
}

internal val EXTENSION = ArtifactId("fixture:extension")

/** A Realm runtime and one extension with a common part of [disposition] and a paper engine part. */
internal class ExtensionPackage(
    val artifacts: List<GeneratedProviderArtifact>,
) {
    fun load(block: (GeneratedProviderDeployment) -> Unit) =
        GeneratedProviderLoader().load(artifacts, DeploymentFacts(), DiscoveryDomains.Realm).use(block)
}

internal fun extensionPackage(
    disposition: SourcePartDisposition = SourcePartDisposition.Ineligible(listOf("No local engine is available.")),
): ExtensionPackage {
    val directory = Files.createTempDirectory("realm-common-providers")
    val runtime = directory.resolve("realm.jar").also { providerJar(it, emptyList()) }
    val extension =
        directory.resolve("extension.jar").also {
            providerJar(
                it,
                listOf(
                    Triple("type", RealmCommonTypeProvider::class.java, "common"),
                    Triple("nativeBinding", RealmCommonBindingProvider::class.java, "common"),
                    Triple("presentation", RealmCommonPresentationProvider::class.java, "common"),
                    Triple("registrar", RealmCommonRegistrarProvider::class.java, "common"),
                    Triple("registrar", RealmExecutionRegistrarProvider::class.java, "common"),
                    Triple("type", RealmTargetedTypeProvider::class.java, "paper"),
                ),
            )
        }
    val manifest =
        ExtensionManifest(
            id = EXTENSION,
            version = ArtifactVersion("1.0.0"),
            sourceParts =
                listOf(
                    CommonExtensionSourcePart,
                    EngineExtensionSourcePart(
                        "paper",
                        ArtifactRequirement(ArtifactId("fixture:paper"), VersionConstraint("^1")),
                        ResolvedArtifact(ArtifactId("fixture:paper"), ArtifactVersion("1.0.0"), ArtifactKind.ENGINE),
                        emptyList(),
                    ),
                ),
            buildProvenance = emptyList(),
            contributions = emptyList(),
        )
    return ExtensionPackage(
        HostedArtifactPackage(
            runtimeArtifact =
                HostedArtifact(
                    runtime,
                    RealmManifest(
                        id = ArtifactId("fixture:realm"),
                        version = ArtifactVersion("1.0.0"),
                        hostApi = VersionConstraint("^1"),
                        runtimeEntrypointClass = "fixture.Runtime",
                        contributions = emptyList(),
                    ),
                ),
            extensions =
                listOf(
                    HostedExtensionArtifact(
                        manifest.id,
                        extension,
                        manifest,
                        listOf(
                            HostedSourcePart("common", disposition),
                            HostedSourcePart("paper", SourcePartDisposition.Eligible(setOf(RuntimePlacement.PRIMARY_ENGINE))),
                        ),
                    ),
                ),
            catalogArtifacts = emptyList(),
        ).realmProviderArtifacts(),
    )
}

object RealmProviderFixture {
    val type = TypeDefinitionId.qualified("fixture", "RealmCommon")
    val registrar =
        object : RuntimeRegistrar {
            context(scope: RuntimeScope)
            override suspend fun register() = Unit
        }
}

class RealmCommonTypeProvider : GeneratedTypeProvider {
    override val definition =
        TypeDefinition.partial(
            id = RealmProviderFixture.type,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
        )
}

class RealmCommonBindingProvider : NativeBindingFactory {
    override val definition = RealmProviderFixture.type
    override val provider = NativeBindingId(value = "fixture.common")

    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ) = GeneratedRecordNativeBinding(actual, provider, "fixture.common", Unit::class, emptyList()) { Unit }
}

class RealmCommonPresentationProvider : GeneratedPresentationProvider {
    override fun descriptor(origin: ProviderOrigin) =
        PresentationDescriptor.of(
            PresentationId(namespace = "fixture", name = "common"),
            origin.owner,
            PresentationTarget.NamedWrapper(RealmProviderFixture.type.namedTemplate()),
            setOf(PresentationRole.INSPECTOR),
            0,
        )

    override fun build(binding: PresentationBuildBinding) = DefaultPresentationRuntime().build(binding) {}
}

class RealmCommonRegistrarProvider : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor(RuntimeRegistrarId("fixture.realm"), setOf(DiscoveryDomains.Realm))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar = RealmProviderFixture.registrar
}

class RealmExecutionRegistrarProvider : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor(RuntimeRegistrarId("fixture.execution"), setOf(DiscoveryDomains.Execution))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar =
        error("Execution registrars must never be bound by Realm.")
}

class RealmTargetedTypeProvider : GeneratedTypeProvider {
    init {
        error("Targeted engine code must never be constructed by Realm.")
    }

    override val definition =
        TypeDefinition.partial(
            id = RealmProviderFixture.type,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
        )
}

internal fun providerJar(
    path: Path,
    providers: List<Triple<String, Class<*>, String>>,
) {
    JarOutputStream(Files.newOutputStream(path)).use { archive ->
        archive.putNextEntry(JarEntry(GENERATED_PROVIDER_INDEX_PATH))
        archive.write(providers.joinToString("") { (kind, type, part) -> "$kind\t${type.name}\t$part\n" }.encodeToByteArray())
        archive.closeEntry()
        providers.forEach { (_, type, _) ->
            val name = type.name.replace('.', '/') + ".class"
            archive.putNextEntry(JarEntry(name))
            archive.write(requireNotNull(type.getResourceAsStream("/$name")).use { it.readBytes() })
            archive.closeEntry()
        }
    }
}

internal fun shippedProfiles(): List<Path> =
    Files
        .list(Path.of("..", "config"))
        .use { files ->
            files.filter { it.extension == "properties" }.sorted().toList()
        }.also { check(it.isNotEmpty()) { "No shipped Realm profiles found" } }

internal const val ROOT = "(root)"
