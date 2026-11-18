@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.edit

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmRootFields
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.of
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
import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.RealmStorage
import com.typewritermc.realm.testing.Refusal
import com.typewritermc.realm.testing.expectRefusedUnguarded
import com.typewritermc.realm.testing.itemIds
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.refusals
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.typesOf
import com.typewritermc.realm.testing.unfilledRecord
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.Ref
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val RealmStructureTest by testSuite {
    val questTag = setup("quest-tag") { taxonomy { tags.tag("quest") { name = "Quest" } } }

    val shelf =
        setup("shelf") {
            val (quest, side) = taxonomy { tags.tag("quest") to tags.tag("side") }
            Triple(library { books.book("story") { handle } }, quest, side)
        }

    val extraSection = TypeDefinitionId.qualified("structure", "ExtraSection")

    /** A Tag value whose owner link is not filled in, which no author's create may leave so. */
    val unownedTagValue = Tag(taxonomy = Ref(com.typewritermc.types.ResourceId("unowned")), placement = GraphPlacement())

    test("a fresh realm gets its root and one instance of every section in display name order") {
        RealmFixture.core().use { realm ->
            val resources = realm.resources
            resources.typesOf(RealmRootDefinition.id).size shouldBe 1
            val library = resources.typesOf(LibraryDefinition.id).single()
            val taxonomy = resources.typesOf(TaxonomyDefinition.id).single()
            val root = resources.getValue(resources.typesOf(RealmRootDefinition.id).single())
            root.links("sections") shouldBe listOf(library, taxonomy)
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

            realm.restart(
                RealmCatalog(
                    declarations = { core ->
                        listOf(
                            OwnedTypeDeclaration(
                                core.declarations.first().origin,
                                TypeDefinition.partial(
                                    id = extraSection,
                                    representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                                    parents = listOf(RealmSectionDefinition.id.namedTemplate()),
                                ),
                                searchKey = "extrasection",
                            ),
                        )
                    },
                ),
            )

            val after = realm.resources
            val added = after.typesOf(extraSection).single()
            val root = before.typesOf(RealmRootDefinition.id).single()
            after.getValue(root).links("sections") shouldBe before.getValue(root).links("sections") + added
            after.keys shouldBe before.keys + added
            after.filterKeys { it != root && it != added } shouldBe before - root
        }
    }

    test("a tag created into the taxonomy commits and survives reload") {
        withSetup(questTag, RealmStorage.Surreal) { tag ->
            restart()

            resources.getValue(tag.id.toSkir()).link("taxonomy") shouldBe resources.typesOf(TaxonomyDefinition.id).single()
        }
    }

    test("creating a resource under an id that exists is refused and changes nothing") {
        withSetup(questTag) { tag ->
            expectRefusedUnguarded(
                EditIntent.createCreateResource(
                    id = tag.id.toSkir(),
                    record = unfilledRecord(TagDefinition.id.use(), unownedTagValue, "taxonomy"),
                ),
            ).refusals shouldContain Refusal(tag.id.value, "resource_already_exists")
        }
    }

    test("a resource without an owner is refused") {
        RealmFixture.core().use { realm ->
            realm
                .expectRefusedUnguarded(
                    EditIntent.createCreateResource(
                        id = ResourceId(value = "loose"),
                        record = realm.unfilledRecord(TagDefinition.id.use(), unownedTagValue, "taxonomy"),
                    ),
                ).refusals shouldContain Refusal("loose", "owner_required")
        }
    }

    test("unlinking a section from the root leaves it without an owner and is refused") {
        RealmFixture.core().use { realm ->
            val resources = realm.resources
            val root = resources.typesOf(RealmRootDefinition.id).single()
            val library = resources.typesOf(LibraryDefinition.id).single()
            val sections = resources.getValue(root)
            val item = sections.itemIds("sections")[sections.links("sections").indexOf(library)]

            realm
                .expectRefusedUnguarded(EditIntent.createRemove(at = ValueLocation.of(root, RealmRootFields.sections.path), item = item))
                .refusals shouldContain Refusal(library.value, "owner_required")
        }
    }

    test("a second root or a second instance of a section type is refused") {
        RealmFixture.core().use { realm ->
            val resources = realm.resources
            val root = resources.getValue(resources.typesOf(RealmRootDefinition.id).single())
            val library = resources.getValue(resources.typesOf(LibraryDefinition.id).single())

            realm
                .expectRefusedUnguarded(EditIntent.createCreateResource(id = ResourceId(value = "second_root"), record = root))
                .refusals shouldContain Refusal("second_root", "singleton_exists")
            realm
                .expectRefusedUnguarded(EditIntent.createCreateResource(id = ResourceId(value = "second_library"), record = library))
                .refusals shouldContain Refusal("second_library", "singleton_exists")
        }
    }

    test("removing the root or a section is refused") {
        RealmFixture.core().use { realm ->
            val resources = realm.resources
            val root = resources.typesOf(RealmRootDefinition.id).single()
            val library = resources.typesOf(LibraryDefinition.id).single()

            realm
                .expectRefusedUnguarded(EditIntent.createDeleteResource(id = library))
                .refusals shouldContain Refusal(library.value, "singleton_required")
            realm
                .expectRefusedUnguarded(EditIntent.createDeleteResource(id = root))
                .refusals shouldContain Refusal(root.value, "singleton_required")
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

            first.commit { insert(tags, null, encoder.encode(tagLink, Ref<Nothing, Nothing>(quest.id))) }.shouldBeCommitted()
            val saved = resources

            second
                .commit { insert(tags, null, encoder.encode(tagLink, Ref<Nothing, Nothing>(side.id))) }
                .shouldBeInstanceOf<CommitPreparedEditResponse.ConflictErrorWrapper>()
            resources shouldBe saved
        }
    }
}
