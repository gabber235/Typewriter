package com.typewritermc.realm.testing

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.engine.pages.StaticPage
import com.typewritermc.engine.pages.StaticPageDefinition
import com.typewritermc.library.PageElements
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.edit.WorkingViewEditContext
import com.typewritermc.realm.formula.FitOf
import com.typewritermc.testing.routes.FixtureBoard
import com.typewritermc.testing.routes.FixtureBoardDefinition
import com.typewritermc.testing.routes.FixtureColumn
import com.typewritermc.testing.routes.FixtureColumnDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.derived
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.ChosenArgument
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
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
 * [chosen] chooses arguments; [rows] gives the board's rows from its row type.
 */
suspend fun RealmFixture.commitBoard(
    name: String,
    vararg columns: FixtureColumn,
    chosen: List<ChosenArgument> = emptyList(),
    rows: (TypeUse) -> List<DataValue> = { emptyList() },
): Creation =
    commitBound(
        FixtureBoardDefinition.id,
        chosen = chosen,
        rows = rows,
    ) { page -> FixtureBoard<Nothing>(page, GraphPlacement(), name, columns.toList()) }

/**
 * Creates the entry [element] makes on the realm's static page, of a type with a computed `V` and a `rows: List<V>`
 * field, and commits it with only the [chosen] arguments. [rows] gives its rows from the row type it computes.
 *
 * The code catalog cannot encode a type a resource computes, so the entry encodes with every one of its [parameters] as
 * a number, then its rows are rewritten as a list of its computed row type. This stays while the encoder only knows code
 * types; once it encodes a derived type argument, the entry can encode as what it is.
 */
suspend fun RealmFixture.commitBound(
    definition: TypeDefinitionId,
    parameters: Int = 1,
    chosen: List<ChosenArgument> = emptyList(),
    rows: (TypeUse) -> List<DataValue> = { emptyList() },
    element: (Ref<PageElements.Element, StaticPage>) -> Any,
): Creation {
    val (id, reply) =
        commitElement { id ->
            val page = resources.typesOf(StaticPageDefinition.id).single()
            val items = rows(rowsOf(id)).mapIndexed { index, value -> ListItem(id = ItemId(value = "row-$index"), value = value) }
            encoder
                .record(definition.namedUse(List(parameters) { intUse }).use, element(Ref(page.toResourceId())))
                .with("rows", DataValue.named(StandardTypes.list.namedUse(listOf(rowsOf(id))), DataValue.listValue(items)))
                .copy(configuration = TypeSelection(definition = definition, arguments = chosen))
        }
    return Creation(id, reply)
}

/** A board, the row type it computes, and a definition whose value is one row of that type. */
data class ScoredRow(
    val board: ResourceId,
    val row: TypeUse,
    val holder: ResourceId,
)

/**
 * Commits a board "scores" with one number column "gold", then a definition "best" whose value is a row of the board's
 * row type with [gold] in that column.
 */
suspend fun RealmFixture.commitScoredRow(gold: Long = 1): ScoredRow {
    val board = commitBoard("scores", column("gold", number = true)).created()
    val row = rowsOf(board)
    val holder = commitDefinition("best", plainType(row)) { plainVar(row, recordValue(row, "gold" to DataValue.integer(gold))) }.created()
    return ScoredRow(board, row, holder)
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

/** How often [resource]'s fit was judged so far. */
internal fun RealmFixture.fitRuns(resource: ResourceId): Long = graphRuns.runsOf(FitOf(resource))

/**
 * An edit an operation prepared after reading what [holder]'s value means, not yet committed: it renames [holder] to
 * [name]. What the operation read stands as its expectations. When [readElsewhereFirst], another reader of the same
 * view read it first, so the operation takes what that reader already computed.
 */
internal suspend fun RealmFixture.renameAfterReadingTypeOf(
    holder: ResourceId,
    name: String,
    readElsewhereFirst: Boolean = false,
): PreparedEdit =
    views.capture().use { lease ->
        WorkingViewEditContext(lease.root, "read-type").run {
            if (readElsewhereFirst) CapturedAuthoringReads(capturedReads.view).resourceBinding(holder)
            capturedReads.resourceBinding(holder)
            checkedSet(ValueLocation.of(holder, ValuePath.root.field("name")), DataValue.StringValueWrapper(name))
            finish()
        }
    }
