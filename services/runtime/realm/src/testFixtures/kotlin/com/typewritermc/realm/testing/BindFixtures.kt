package com.typewritermc.realm.testing

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.engine.pages.StaticPageDefinition
import com.typewritermc.testing.routes.FixtureBoard
import com.typewritermc.testing.routes.FixtureBoardDefinition
import com.typewritermc.testing.routes.FixtureColumn
import com.typewritermc.testing.routes.FixtureColumnDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.derived
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import skirout.editor.v1.authoring.EditIntent
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

/** Creates a board named [name] with [columns] on the realm's static page and commits it; a creator chose nothing. */
suspend fun RealmFixture.commitBoard(
    name: String,
    vararg columns: FixtureColumn,
): Creation {
    val (id, reply) =
        commitElement { id ->
            val page = resources.typesOf(StaticPageDefinition.id).single()
            val board = FixtureBoard<Nothing>(Ref(page.toResourceId()), GraphPlacement(), name, columns.toList())
            // The code catalog cannot encode the row type the board computes, so the board encodes with any row type,
            // then holds an empty list of its computed row type and a selection that chose nothing for it.
            encoder
                .record(FixtureBoardDefinition.id.namedUse(listOf(intUse)).use, board)
                .with("rows", DataValue.named(StandardTypes.list.namedUse(listOf(rowsOf(id))), DataValue.listValue(emptyList())))
                .copy(configuration = TypeSelection(definition = FixtureBoardDefinition.id, arguments = emptyList()))
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

/** The row type [board]'s columns compute: its derived `V`. */
fun rowsOf(board: ResourceId): TypeUse = TypeDefinitionId.derived(board, "V").use()
