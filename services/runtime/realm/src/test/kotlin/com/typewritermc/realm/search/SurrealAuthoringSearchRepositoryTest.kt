package com.typewritermc.realm.search

import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.of
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.RealmStorage
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.testkit.definitions
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.kernel.v1.resource_id.ResourceId

val SurrealAuthoringSearchRepositoryTest by testSuite {
    test("a search for a supertype pages past incompatible resources to the compatible one") {
        val parent = definition("parent")
        val compatible = definition("compatible")
        val incompatible = definition("incompatible")
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(parent, abstract = true)
                    record(compatible, parents = listOf(parent.namedTemplate()))
                    record(incompatible)
                },
            )
        RealmFixture.surreal(catalog).use { realm ->
            val ahead = (0 until 256).map { create("a_${it.toString().padStart(3, '0')}", incompatible.namedUse()) }
            realm.commit(*(ahead + create("z_compatible", compatible.namedUse())).toTypedArray()).shouldBeCommitted()

            realm.search(roots = setOf(parent), limit = 100) shouldBe listOf(ResourceId(value = "z_compatible"))
        }
    }

    test("a search inside a context finds only the resources the context holds") {
        val type = definition("resource")
        RealmFixture.surreal(DefinitionCatalog(definitions { record(type) })).use { realm ->
            realm.commit(create("inside", type.namedUse()), create("outside", type.namedUse())).shouldBeCommitted()

            realm.search(contexts = setOf(ResourceId(value = "inside"))) shouldBe listOf(ResourceId(value = "inside"))
        }
    }

    test("a search for an applied generic type finds a pending resource only when its chosen argument matches") {
        val box = definition("box")
        val first = definition("first")
        val second = definition("second")
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(box, parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = box, index = 0), name = "T")))
                    record(first)
                    record(second)
                },
            )
        RealmFixture.surreal(catalog).use { realm ->
            val pending = TypeSelection.createPending(definition = box, arguments = listOf(ArgumentSelection.ChosenWrapper(first.use())))
            realm
                .commit(
                    EditIntent.createCreateResource(id = ResourceId(value = "pending"), record = AuthoringRecord.of(pending, emptyMap())),
                ).shouldBeCommitted()

            realm.search(target = box.namedUse(listOf(first.use()))) shouldBe listOf(ResourceId(value = "pending"))
            realm.search(target = box.namedUse(listOf(second.use()))) shouldBe emptyList()
        }
    }

    test("the realm root is left out of search results while its sections stay searchable") {
        RealmFixture.core(RealmStorage.Surreal).use { realm ->
            val root = realm.singleOf(RealmRootDefinition.id)
            val sections = setOf(realm.singleOf(LibraryDefinition.id), realm.singleOf(TaxonomyDefinition.id))

            realm.resources.keys shouldBe sections + root
            realm.search().toSet() shouldBe sections
        }
    }

    test("a multiword query finds a resource whose saved title holds those words") {
        val book = definition("book")
        RealmFixture.surreal(DefinitionCatalog(definitions { record(book) { field("title", ScalarKind.TEXT.template) } })).use { realm ->
            val record =
                AuthoringRecord.of(
                    TypeSelection.CompleteWrapper(book.namedUse()),
                    mapOf("title" to DataValue.StringValueWrapper("Metadata verification 20261004")),
                )
            realm.commit(EditIntent.createCreateResource(id = ResourceId(value = "book"), record = record)).shouldBeCommitted()

            realm.search(query = "Metadata verification") shouldBe listOf(ResourceId(value = "book"))
        }
    }

    test("text inside nested records, lists, sets, maps and enum values is indexed for search") {
        fun text(value: String) = DataValue.StringValueWrapper(value)

        fun items(vararg values: String) = values.map { ListItem(id = ItemId(value = it), value = text(it)) }
        val record =
            AuthoringRecord.of(
                TypeSelection.CompleteWrapper(definition("holder").namedUse()),
                mapOf(
                    "nested" to DataValue.named(definition("nested").namedUse(), DataValue.record("inner" to text("inner"))),
                    "list" to DataValue.listValue(items("listed")),
                    "set" to DataValue.setValue(items("member")),
                    "map" to DataValue.mapValue(listOf(MapRow(id = ItemId(value = "row"), key = text("key"), value = text("mapped")))),
                    "mood" to DataValue.EnumCaseWrapper("cheerful"),
                    "done" to DataValue.BooleanWrapper(true),
                ),
            )

        authoredSearchText(ResourceId(value = "holder"), record).split(" ").toSet() shouldBe
            setOf("holder", "inner", "listed", "member", "key", "mapped", "cheerful")
    }
}

private fun definition(name: String): TypeDefinitionId = TypeDefinitionId.qualified("test", name)

/** Creates [id] as an empty resource of [type]. */
private fun create(
    id: String,
    type: skirout.editor.v1.type_catalog.NamedTypeUse,
) = EditIntent.createCreateResource(
    id = ResourceId(value = id),
    record = AuthoringRecord.of(TypeSelection.CompleteWrapper(type), emptyMap()),
)
