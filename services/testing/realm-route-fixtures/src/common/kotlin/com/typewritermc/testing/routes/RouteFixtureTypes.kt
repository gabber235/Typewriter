package com.typewritermc.testing.routes

import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.GraphLayout
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.HierarchyPath
import com.typewritermc.authoring.TimelineEntryPlacement
import com.typewritermc.authoring.orNull
import com.typewritermc.capability.RealmCapabilities
import com.typewritermc.capability.RealmCapability
import com.typewritermc.capability.RealmCapabilityPermissionDeniedException
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmCommandOutcome
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.elements.Entry
import com.typewritermc.engine.pages.StaticEntry
import com.typewritermc.engine.pages.StaticPage
import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.DynamicProvider
import com.typewritermc.formula.Dynamics
import com.typewritermc.formula.TypewriterDynamicProvider
import com.typewritermc.formula.TypewriterFormulaProvider
import com.typewritermc.formula.Var
import com.typewritermc.library.Book
import com.typewritermc.library.BookPages
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.TypewriterTypeImports
import com.typewritermc.types.integerScalar
import com.typewritermc.types.use
import skirout.editor.v1.capability.NotificationSeverity
import skirout.editor.v1.capability.PanelInstruction
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ScalarKind

/*
 * Pages and entries for Realm route tests that the core catalog lacks, because core declares no concrete page. They
 * are declared like any extension's types, so the catalog holds exactly the contracts these declarations make.
 */

/** A page that lays out its graph entries as a graph. */
@TypewriterType(id = "2c3d4f709f214da1a406249567f016af")
data class FixtureGraphPage(
    override val book: Ref<BookPages.Page, Book>,
    override val name: String = "",
    override val chapter: HierarchyPath = HierarchyPath.Root,
    override val priority: Int = 0,
    override val elements: List<Ref<PageElements.Page, FixtureGraphEntry>> = emptyList(),
) : Page,
    GraphLayout

/** A page without a graph layout that accepts every entry, so placements of other layouts can live in it. */
@TypewriterType(id = "f77db3810ac945298e24af541eda0c5e")
data class FixtureTimelinePage(
    override val book: Ref<BookPages.Page, Book>,
    override val name: String = "",
    override val chapter: HierarchyPath = HierarchyPath.Root,
    override val priority: Int = 0,
    override val elements: List<Ref<PageElements.Page, Entry>> = emptyList(),
) : Page

/** An entry placed on a graph; it can live in either fixture page. */
@TypewriterType(id = "675473ca14714c8eada6b69ca72837c5")
data class FixtureGraphEntry(
    override val page: Ref<PageElements.Element, Page>,
    override val name: String = "",
    override val placement: GraphPlacement,
) : Entry

/** An entry placed on a timeline track; only the timeline page accepts it. */
@TypewriterType(id = "de1e9a978c1447e180e89fba2f1d946f")
data class FixtureTimelineEntry(
    override val page: Ref<PageElements.Element, FixtureTimelinePage>,
    override val name: String = "",
    override val placement: TimelineEntryPlacement,
) : Entry

/** A real entry of the core static page, so content can sit next to it on the same page. */
@TypewriterType(id = "d3f0562dba934f4290da338f21302315")
data class FixtureStaticEntry(
    override val page: Ref<PageElements.Element, StaticPage>,
    override val placement: GraphPlacement,
    override val name: String = "",
) : StaticEntry

/** What a formula of a [FixtureContextEntry] reads from where it runs: a number only the engine can give. */
interface FixtureChainContext {
    val chain: Int
}

/** An entry of the core static page whose value may be computed from a context the realm cannot fill. */
@TypewriterType(id = "8e41c2d07a5b4f39b1c6e2a49d0f7b35")
data class FixtureContextEntry(
    override val page: Ref<PageElements.Element, StaticPage>,
    override val placement: GraphPlacement,
    override val name: String = "",
    val chained: Var<Int, FixtureChainContext> = Var.Value(0),
) : StaticEntry

/**
 * A code record holding Vars, references and a list of Vars, as an extension's record would. A content reference
 * in a resource needs a collection on its path, so the references are a list. Its display name differs from its class
 * name, which is the name formulas write.
 */
@TypewriterType(id = "4061a95fbcca42ab8e7dd4824049faaf")
@TypewriterDisplay(name = "Loot")
data class FixtureLoot(
    val gold: Var<Int, DefinitionScope> = Var.Value(0),
    val bonus: Var<Int, DefinitionScope> = Var.Value(0),
    val givers: List<Ref<ContentReferences.Source, FixtureStockEntry>> = emptyList(),
    val extras: List<Var<Int, DefinitionScope>> = emptyList(),
)

/** A code union whose other case holds a Var. */
@TypewriterType(id = "c25dd9f1c4a3403cb94b110e85d77abd")
sealed interface FixtureSignal {
    data object Quiet : FixtureSignal

    data class Tuned(
        val level: Var<Int, DefinitionScope>,
    ) : FixtureSignal
}

/** A code generic, which may hold a content type. */
@TypewriterType(id = "dc79aeb4b5f8449d8fe2df2f04a53983")
data class FixtureBox<T>(
    val x: T,
)

/** An open type, which another extension may give more subtypes. */
interface FixturePrize

/** Gives the open [FixturePrize] its catalog type. */
@TypewriterTypeImports(FixturePrize::class)
internal object FixtureTypeImports

/** The open type's one subtype in this extension. */
@TypewriterType(id = "3720f680942d42d2a304e54d11f7f539")
data class FixtureCoinPrize(
    val coins: Int,
) : FixturePrize

/** An entry of the core static page that exports its stock, so a formula naming it reads that field. */
@TypewriterType(id = "bc6081e04a5a40cf8ae9fe98216c33b1")
data class FixtureStockEntry(
    override val page: Ref<PageElements.Element, StaticPage>,
    override val placement: GraphPlacement,
    override val name: String = "",
    val stock: Var<Int, DefinitionScope> = Var.Value(0),
    val loot: FixtureLoot = FixtureLoot(),
) : StaticEntry

/** A stock entry's export: its stock. */
@TypewriterDynamicProvider
object FixtureStockExports : DynamicProvider {
    override fun Dynamics.register() {
        each(FixtureStockEntryDefinition.id) { exports { value(FixtureStockEntryFields.stock) } }
    }
}

/** One column of a [FixtureBoard]: a row field named [name] that holds a number, or a text when [number] is false. */
@TypewriterType(id = "9a1d4c7e2b5f4e08a3c6d9f1b2e4a7c0")
data class FixtureColumn(
    val name: String = "",
    val number: Boolean = false,
)

/** An entry whose row type its own columns compute through a bind, so a creator never chooses it. */
@TypewriterType(id = "4b8e2f6a1c3d4e5f9a0b7c2d4e6f8a1b")
data class FixtureBoard<V>(
    override val page: Ref<PageElements.Element, StaticPage>,
    override val placement: GraphPlacement,
    override val name: String = "",
    val columns: List<FixtureColumn> = emptyList(),
    val rows: List<V> = emptyList(),
) : StaticEntry

/** The column name that makes [FixtureBoardRows] fail, as an extension's own bug would. */
const val FAILING_COLUMN = "fail"

/**
 * A board's row type: one field per named column. A column without a name adds nothing; [FAILING_COLUMN] throws. A board
 * also exports its columns, so a formula naming it reads them through a hook on the board itself.
 */
@TypewriterDynamicProvider
object FixtureBoardRows : DynamicProvider {
    override fun Dynamics.register() {
        each(FixtureBoardDefinition.id) { exports { value(FixtureBoardFields.columns) } }
        bind(FixtureBoardBind.V) { board ->
            val columns = board.columns.orNull() ?: return@bind
            columns.items().orNull().orEmpty().forEach { item ->
                val column = columns.item(item).orNull() ?: return@forEach
                val name = column.name.orNull()?.takeIf { it.isNotBlank() } ?: return@forEach
                check(name != FAILING_COLUMN) { "The fixture bind fails on this column." }
                field(name, if (column.number.orNull() == true) integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use else ScalarKind.TEXT.use)
            }
        }
    }
}

/** An entry whose bind selects every mirror, its own resource included, so computing its type needs that type. */
@TypewriterType(id = "0fe5ad25b675426f940020b90b336303")
data class FixtureMirror<V>(
    override val page: Ref<PageElements.Element, StaticPage>,
    override val placement: GraphPlacement,
    override val name: String = "",
    val rows: List<V> = emptyList(),
) : StaticEntry

/** A mirror's row type: one count field, computed after binding every mirror, which reads each mirror's own type. */
@TypewriterDynamicProvider
object FixtureMirrorRows : DynamicProvider {
    override fun Dynamics.register() {
        bind(FixtureMirrorBind.V) {
            val mirrors = select(TypedSelection(BareDraft(ResourceTypeMatch.Definition(FixtureMirrorDefinition.id)))).knownMatches
            field("mirrors", integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use, hasDefault = mirrors.isNotEmpty())
        }
    }
}

/** An entry whose `V` two providers bind, so neither decides it. */
@TypewriterType(id = "329cd2749bf347ffbed6f98fe80e0b69")
data class FixtureContested<V>(
    override val page: Ref<PageElements.Element, StaticPage>,
    override val placement: GraphPlacement,
    override val name: String = "",
    val rows: List<V> = emptyList(),
) : StaticEntry

/** One of the two binds of [FixtureContested]'s `V`. */
@TypewriterDynamicProvider
object FixtureContestedFirst : DynamicProvider {
    override fun Dynamics.register() {
        bind(FixtureContestedBind.V) { field("first", ScalarKind.TEXT.use) }
    }
}

/** The other bind of [FixtureContested]'s `V`. */
@TypewriterDynamicProvider
object FixtureContestedSecond : DynamicProvider {
    override fun Dynamics.register() {
        bind(FixtureContestedBind.V) { field("second", ScalarKind.TEXT.use) }
    }
}

/** An entry whose `T` a creator chooses, held by no field, and whose row type `V` its bind computes. */
@TypewriterType(id = "6d2f9b4a8e1c4f37b05a3c9e7d1f2b84")
data class FixtureLedger<T, V>(
    override val page: Ref<PageElements.Element, StaticPage>,
    override val placement: GraphPlacement,
    override val name: String = "",
    val failing: Boolean = false,
    val rows: List<V> = emptyList(),
) : StaticEntry

/** A ledger's row type: one text field, or a failure while the ledger is [FixtureLedger.failing]. */
@TypewriterDynamicProvider
object FixtureLedgerRows : DynamicProvider {
    override fun Dynamics.register() {
        bind(FixtureLedgerBind.V) { ledger ->
            check(ledger.failing.orNull() != true) { "The fixture ledger fails." }
            field("note", ScalarKind.TEXT.use)
        }
    }
}

/** A draft type that reads a matched resource as its bare binding. */
private class BareDraft(
    override val match: ResourceTypeMatch,
) : DraftType<DraftBinding> {
    override fun bind(binding: DraftBinding): DraftBinding = binding
}

/** Providers formula tests pass the route fixtures' code types to. */
@TypewriterFormulaProvider
object FixtureFormulas {
    /** The worth of a prize; a coin prize is worth its coins. */
    fun FixturePrize.worth(): Int = (this as? FixtureCoinPrize)?.coins ?: 0
}

/** The payload and result of the fixture capabilities: a text the capability echoes or reacts to. */
@TypewriterType(id = "5b0f7e2a9c3d4e1f8a6b2c4d6e8f0a12")
data class FixtureMessage(
    val value: String,
)

/**
 * A computation and a command for Realm invocation tests. Each echoes its payload, refuses [DENIED] with a permission
 * denial and fails on [BROKEN], so a test picks the outcome through the payload it sends.
 */
@RealmCapabilities
class FixtureCapabilities {
    /** Returns the payload unchanged. */
    @RealmCapability.Computation
    context(_: RealmComputationContext)
    suspend fun echo(request: FixtureMessage): FixtureMessage = request.also { it.react() }

    /** Notifies the panel with the payload. */
    @RealmCapability.Command
    context(_: RealmCommandContext)
    suspend fun announce(request: FixtureMessage): RealmCommandOutcome {
        request.react()
        return RealmCommandOutcome(listOf(PanelInstruction.createNotify(severity = NotificationSeverity.SUCCESS, message = request.value)))
    }

    companion object {
        const val DENIED = "denied"
        const val BROKEN = "broken"
    }
}

private fun FixtureMessage.react() {
    if (value == FixtureCapabilities.DENIED) throw RealmCapabilityPermissionDeniedException("Fixture capability denied")
    check(value != FixtureCapabilities.BROKEN) { "Fixture capability broke" }
}
