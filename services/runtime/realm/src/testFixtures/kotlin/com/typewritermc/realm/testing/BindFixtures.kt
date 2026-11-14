package com.typewritermc.realm.testing

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.engine.pages.StaticPage
import com.typewritermc.engine.pages.StaticPageDefinition
import com.typewritermc.library.PageElements
import com.typewritermc.testing.routes.FixtureBoard
import com.typewritermc.testing.routes.FixtureBoardDefinition
import com.typewritermc.testing.routes.FixtureColumn
import com.typewritermc.testing.routes.FixtureColumnDefinition
import com.typewritermc.testing.routes.FixtureContested
import com.typewritermc.testing.routes.FixtureContestedDefinition
import com.typewritermc.testing.routes.FixtureLedger
import com.typewritermc.testing.routes.FixtureLedgerDefinition
import com.typewritermc.testing.routes.FixtureMirror
import com.typewritermc.testing.routes.FixtureMirrorDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.derived
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.ChosenArgument
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** A column of a fixture board: a number column when [number] is true, a text column otherwise. */
fun column(
    name: String,
    number: Boolean = false,
) = FixtureColumn(name, number)

/**
 * Creates a board named [name] with [columns] on the realm's static page and commits it. A creator chose nothing, unless
 * [chosen] chooses arguments.
 */
suspend fun RealmFixture.commitBoard(
    name: String,
    vararg columns: FixtureColumn,
    chosen: List<ChosenArgument> = emptyList(),
): Creation =
    commitBound(FixtureBoardDefinition.id, parameters = 1, chosen) { id, page ->
        FixtureBoard<Nothing>(page, GraphPlacement(), name, columns.toList()) to mapOf("rows" to rowsOf(id))
    }

/** Creates a mirror named [name], whose bind selects every mirror, its own resource included. */
suspend fun RealmFixture.commitMirror(name: String): Creation =
    commitBound(FixtureMirrorDefinition.id, parameters = 1) { id, page ->
        FixtureMirror<Nothing>(page, GraphPlacement(), name) to mapOf("rows" to rowsOf(id))
    }

/** Creates a contested entry named [name], whose `V` two providers bind. */
suspend fun RealmFixture.commitContested(name: String): Creation =
    commitBound(FixtureContestedDefinition.id, parameters = 1) { id, page ->
        FixtureContested<Nothing>(page, GraphPlacement(), name) to mapOf("rows" to rowsOf(id))
    }

/** Creates a ledger named [name] whose creator chose [about] for its `T`; its bind fails while [failing]. */
suspend fun RealmFixture.commitLedger(
    name: String,
    about: TypeUse,
    failing: Boolean = false,
): Creation =
    commitBound(FixtureLedgerDefinition.id, parameters = 2, listOf(ChosenArgument(parameter = 0, type = about))) { id, page ->
        FixtureLedger<Nothing, Nothing>(page, GraphPlacement(), name, failing) to mapOf("rows" to rowsOf(id))
    }

/**
 * Creates the element [build] makes on the realm's static page and commits it with only the [chosen] arguments. The code
 * catalog cannot encode a type a resource computes, so the element encodes with every one of its [parameters] as a
 * number, then each list [build] names holds an empty list of its real item type.
 */
private suspend fun RealmFixture.commitBound(
    definition: TypeDefinitionId,
    parameters: Int,
    chosen: List<ChosenArgument> = emptyList(),
    build: (ResourceId, Ref<PageElements.Element, StaticPage>) -> Pair<Any, Map<String, TypeUse>>,
): Creation {
    val (id, reply) =
        commitElement { id ->
            val page = resources.typesOf(StaticPageDefinition.id).single()
            val (element, lists) = build(id, Ref(page.toResourceId()))
            lists.entries
                .fold(encoder.record(definition.namedUse(List(parameters) { intUse }).use, element)) { record, (field, item) ->
                    record.with(field, DataValue.named(StandardTypes.list.namedUse(listOf(item)), DataValue.listValue(emptyList())))
                }.copy(configuration = TypeSelection(definition = definition, arguments = chosen))
        }
    return Creation(id, reply)
}

/** Replaces the columns of [board] with [columns]. */
fun RealmFixture.setColumns(
    board: ResourceId,
    vararg columns: FixtureColumn,
): EditIntent =
    EditIntent.createSetValue(
        at = ValueLocation.of(board, ValuePath.root.field("columns")),
        value = encoder.encode(StandardTypes.list.namedUse(listOf(FixtureColumnDefinition.id.use())).use, columns.toList()),
    )

/** The row type [owner]'s bind computes: its derived `V`. */
fun rowsOf(owner: ResourceId): TypeUse = TypeDefinitionId.derived(owner, "V").use()

/** The fields of [board]'s row type with their types, in the saved view's catalog. */
fun RealmFixture.rowFields(board: ResourceId): List<Pair<String, TypeUse>> =
    resolvedSchema(rowsOf(board)).schema.fields.map { it.key to it.type }

/** What [board] wrote down for its types: the declarations it holds and the arguments its selection chose. */
fun RealmFixture.writtenFor(board: ResourceId): List<Any> = record(board).let { it.types + it.configuration.arguments }
