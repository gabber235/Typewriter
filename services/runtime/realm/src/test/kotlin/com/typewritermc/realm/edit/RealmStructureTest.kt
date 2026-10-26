@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.edit

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmRootFields
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.library.BookFields
import com.typewritermc.library.BookTags
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.Tag
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.library.tag
import com.typewritermc.library.taxonomy
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.RealmStorage
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.Ref
import com.typewritermc.types.items
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

private val questTag = setup("quest-tag") { taxonomy { tags.tag("quest") { name = "Quest" } } }

private val shelf =
    setup("shelf") {
        val (quest, side) = taxonomy { tags.tag("quest") to tags.tag("side") }
        Shelf(library { books.book("story") { handle } }, quest, side)
    }

val RealmStructureTest by testSuite {
    test("a fresh realm gets its root and one instance of every section in display name order") {
        RealmFixture.core().use { realm ->
            val resources = realm.resources
            resources.typesOf(RealmRootDefinition.id).size shouldBe 1
            val library = resources.typesOf(LibraryDefinition.id).single()
            val taxonomy = resources.typesOf(TaxonomyDefinition.id).single()
            resources.sectionsOfRoot() shouldBe listOf(library, taxonomy)
        }
    }

    test("provisioning an already structured realm changes nothing") {
        RealmFixture.core().use { realm ->
            val before = realm.views.read { it.observationId to it.resources }

            realm.provision()

            realm.views.read { it.observationId to it.resources } shouldBe before
        }
    }

    test("a section type added by a new extension is created on the next start") {
        RealmFixture.core(RealmStorage.Surreal).use { realm ->
            val before = realm.resources

            realm.restart(RealmCatalog(declarations = { core -> listOf(extraSection(core)) }))

            val after = realm.resources
            val added = after.typesOf(EXTRA_SECTION).single()
            after.sectionsOfRoot() shouldBe before.sectionsOfRoot() + added
            val root = before.typesOf(RealmRootDefinition.id).single()
            after.keys shouldBe before.keys + added
            after.filterKeys { it != root && it != added } shouldBe before - root
        }
    }

    test("a tag created into the taxonomy commits and survives reload") {
        withSetup(questTag, RealmStorage.Surreal) { tag ->
            restart()

            resources.getValue(tag.id.toSkir()).owner() shouldBe resources.typesOf(TaxonomyDefinition.id).single()
        }
    }

    test("creating a resource under an id that exists is refused and changes nothing") {
        withSetup(questTag) { tag ->
            rejected(EditIntent.createCreateResource(id = tag.id.toSkir(), record = unownedTag())) shouldContain
                (tag.id.value to "resource_already_exists")
        }
    }

    test("a resource without an owner is refused") {
        RealmFixture.core().use { realm ->
            realm.rejected(EditIntent.createCreateResource(id = ResourceId(value = "loose"), record = realm.unownedTag())) shouldContain
                ("loose" to "owner_required")
        }
    }

    test("unlinking a section from the root leaves it without an owner and is refused") {
        RealmFixture.core().use { realm ->
            val resources = realm.resources
            val root = resources.typesOf(RealmRootDefinition.id).single()
            val library = resources.typesOf(LibraryDefinition.id).single()
            val sections = resources.getValue(root).valueAt(RealmRootFields.sections.path)?.unwrapNamed() as DataValue.ListValueWrapper
            val item = sections.items.single { it.value.linkTarget() == library }.id

            realm.rejected(EditIntent.createRemove(at = ValueLocation.of(root, RealmRootFields.sections.path), item = item)) shouldContain
                (library.value to "owner_required")
        }
    }

    test("a second root or a second instance of a section type is refused") {
        RealmFixture.core().use { realm ->
            val resources = realm.resources
            val root = resources.getValue(resources.typesOf(RealmRootDefinition.id).single())
            val library = resources.getValue(resources.typesOf(LibraryDefinition.id).single())

            realm.rejected(EditIntent.createCreateResource(id = ResourceId(value = "second_root"), record = root)) shouldContain
                ("second_root" to "singleton_exists")
            realm.rejected(EditIntent.createCreateResource(id = ResourceId(value = "second_library"), record = library)) shouldContain
                ("second_library" to "singleton_exists")
        }
    }

    test("removing the root or a section is refused") {
        RealmFixture.core().use { realm ->
            val resources = realm.resources
            val root = resources.typesOf(RealmRootDefinition.id).single()
            val library = resources.typesOf(LibraryDefinition.id).single()

            realm.rejected(EditIntent.createDeleteResource(id = library)) shouldContain (library.value to "singleton_required")
            realm.rejected(EditIntent.createDeleteResource(id = root)) shouldContain (root.value to "singleton_required")
        }
    }

    test("an edit prepared before another author changed the same list is refused as a conflict") {
        withSetup(shelf) { (book, quest, side) ->
            val first = asUser("first")
            val second = asUser("second")
            val tags = boundCollectionPath(ValueLocation.of(book.id.toSkir(), BookFields.tags.path))
            val tagLink =
                BookTags.Book.Definition.id
                    .namedUse(listOf(TagDefinition.id.use()))
                    .use

            first.commit { insert(tags, null, encoder.encode(tagLink, Ref<Nothing, Nothing>(quest.id))) } shouldBe
                CommitPreparedEditResponse.COMMITTED
            val saved = resources

            second
                .commit { insert(tags, null, encoder.encode(tagLink, Ref<Nothing, Nothing>(side.id))) }
                .shouldBeInstanceOf<CommitPreparedEditResponse.ConflictErrorWrapper>()
            resources shouldBe saved
        }
    }
}

private data class Shelf(
    val book: com.typewritermc.setup.SetupHandle<com.typewritermc.library.Book>,
    val quest: com.typewritermc.setup.SetupHandle<Tag>,
    val side: com.typewritermc.setup.SetupHandle<Tag>,
)

private val EXTRA_SECTION = TypeDefinitionId.qualified("structure", "ExtraSection")

private fun extraSection(core: CatalogContributions) =
    OwnedTypeDeclaration(
        core.declarations.first().origin,
        TypeDefinition.partial(
            id = EXTRA_SECTION,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            parents = listOf(RealmSectionDefinition.id.namedTemplate()),
        ),
        searchKey = "extrasection",
    )

/** A Tag record whose owner link is not filled in, which no author's create may leave so. */
private fun RealmFixture.unownedTag(): AuthoringRecord =
    encoder
        .record(TagDefinition.id.use(), Tag(taxonomy = Ref(com.typewritermc.types.ResourceId("unowned")), placement = GraphPlacement()))
        .with("taxonomy", DataValue.UNFILLED)

/** Commits [intent] alone, expects the refusal, checks nothing changed, and returns its problems as resource and code pairs. */
private suspend fun RealmFixture.rejected(intent: EditIntent): List<Pair<String, String>> {
    val before = resources
    val generation = views.read { it.catalog.generation }
    val response = commit(PreparedEdit(catalog = generation, expectations = emptyList(), intents = listOf(intent)))
    resources shouldBe before
    return response.shouldBeInstanceOf<CommitPreparedEditResponse.RejectedErrorWrapper>().value.map {
        it.location.resource.value to it.code
    }
}

private fun Map<ResourceId, AuthoringRecord>.typesOf(type: TypeDefinitionId): List<ResourceId> =
    filterValues { it.configuration.definition == type }.keys.toList()

private fun Map<ResourceId, AuthoringRecord>.sectionsOfRoot(): List<ResourceId> {
    val root = getValue(typesOf(RealmRootDefinition.id).single())
    val sections = root.valueAt(RealmRootFields.sections.path)?.unwrapNamed() as DataValue.ListValueWrapper
    return sections.items.map { it.value.linkTarget() }
}

/** The resource a tag's owner link points at. */
private fun AuthoringRecord.owner(): ResourceId = valueAt(ValuePath.root.field("taxonomy"))!!.linkTarget()

private fun DataValue.linkTarget(): ResourceId = (unwrapNamed() as DataValue.LinkWrapper).value.target.resource
