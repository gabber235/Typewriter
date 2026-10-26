@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
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
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.codes
import com.typewritermc.realm.testing.itemIds
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.linkTargets
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.typesOf
import com.typewritermc.testing.routes.FixtureTimelinePage
import com.typewritermc.testing.routes.FixtureTimelinePageDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.items
import com.typewritermc.types.namedUse
import com.typewritermc.types.toResourceId
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
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
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/**
 * Generated authoring sessions over the core types: books in the library, pages in books, tags in the taxonomy, tags on
 * books and tag parents. Each step is committed the way an author's edit arrives, and checked against a small model
 * that keeps its own rules for which steps the Realm must refuse.
 */
val RealmInvariantsTest by testSuite {
    test("no sequence of author edits leaves a broken realm or disagrees with the model") {
        checkAll(SESSIONS, Arb.list(step, STEPS)) { steps ->
            RealmFixture.core(catalog = routeFixtureCatalog).use { realm ->
                val structure = realm.resources.keys
                val model = RealmModel(library = realm.singleOf(LibraryDefinition.id), taxonomy = realm.singleOf(TaxonomyDefinition.id))
                steps.forEachIndexed { index, step ->
                    val action = model.resolve(step) ?: return@forEachIndexed
                    withClue("step ${index + 1} of $steps resolved to $action") {
                        val before = realm.resources
                        val refusal = model.refusal(action)
                        val response = realm.write(action)
                        if (refusal == null) {
                            response shouldBe CommitPreparedEditResponse.COMMITTED
                            model.apply(action)
                        } else {
                            response.shouldBeInstanceOf<CommitPreparedEditResponse.RejectedErrorWrapper>().value.codes shouldContainAll
                                listOf(refusal)
                            realm.resources shouldBe before
                        }
                        realm.resources.shouldHoldInvariants()
                        realm.resources.shouldMatch(model, structure)
                    }
                }
            }
        }
    }
}

/** Fixed seed and count, so every run replays the same sessions; change them only on purpose. */
private val SESSIONS = PropTestConfig(seed = 7_204_613_998L, iterations = 100)

/** Long enough sessions that tags gain parents and books gain pages before they are unlinked or deleted again. */
private val STEPS = 10..40

/** How many resources a step can tell apart; an index picks among what the model holds, modulo its size. */
private val index = Arb.int(0..7)

private enum class Kind { Book, Page, Tag }

/** An author's intent with resources named by index into what the model holds, so most steps mean something. */
private sealed interface Step {
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

private val step: Arb<Step> =
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
private sealed interface Action {
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
private class RealmModel(
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
private suspend fun RealmFixture.write(action: Action): CommitPreparedEditResponse {
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

private val BOOK_IN_LIBRARY =
    LibraryBooks.Library.Definition.id
        .namedUse(listOf(BookDefinition.id.use()))
        .use
private val PAGE_IN_BOOK =
    BookPages.Book.Definition.id
        .namedUse(listOf(PageDefinition.id.use()))
        .use
private val TAG_IN_TAXONOMY =
    TaxonomyTags.Taxonomy.Definition.id
        .namedUse(listOf(TagDefinition.id.use()))
        .use
private val TAG_ON_BOOK =
    BookTags.Book.Definition.id
        .namedUse(listOf(TagDefinition.id.use()))
        .use
private val TAG_PARENT =
    TagParents.Child.Definition.id
        .namedUse(listOf(TagDefinition.id.use()))
        .use

private val ResourceId.author get() = toResourceId()

private fun listAt(
    resource: ResourceId,
    path: ValuePath,
) = boundCollectionPath(ValueLocation.of(resource, path))

private fun RealmFixture.link(
    item: skirout.editor.v1.type_catalog.TypeUse,
    target: ResourceId,
): DataValue = encoder.encode(item, Ref<Nothing, Nothing>(target.author))

private fun Map<ResourceId, AuthoringRecord>.libraryOf() = typesOf(LibraryDefinition.id).single()

private fun Map<ResourceId, AuthoringRecord>.taxonomyOf() = typesOf(TaxonomyDefinition.id).single()

/** The item of the collection [field] of [holder] that links to [target]. */
private fun Map<ResourceId, AuthoringRecord>.itemOf(
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
private val OWNING_LISTS =
    mapOf(
        RealmRootDefinition.id to "sections",
        LibraryDefinition.id to "books",
        BookDefinition.id to "pages",
        TaxonomyDefinition.id to "tags",
    )

/** The field through which an owned resource names its owner, for types that have one. */
private val OWNER_FIELDS =
    mapOf(
        BookDefinition.id to "library",
        FixtureTimelinePageDefinition.id to "book",
        TagDefinition.id to "taxonomy",
    )

private val AuthoringRecord.type: TypeDefinitionId get() = configuration.definition

/**
 * Rules every saved state keeps, whatever was edited: one root; every link names a saved resource; every resource but
 * the root is listed by exactly one owner and names that owner back; a link that names its opposite field is listed
 * there; no tag is its own ancestor.
 */
private fun Map<ResourceId, AuthoringRecord>.shouldHoldInvariants() {
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
private fun Map<ResourceId, AuthoringRecord>.shouldMatch(
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
private fun DataValue.links(): List<LinkTarget> =
    when (val value = unwrapNamed()) {
        is DataValue.LinkWrapper -> listOf(value.value.target)
        is DataValue.ListValueWrapper -> value.items.flatMap { it.value.links() }
        is DataValue.SetValueWrapper -> value.items.flatMap { it.value.links() }
        else -> emptyList()
    }
