package com.typewritermc.testing.routes

import com.typewritermc.authoring.GraphLayout
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.HierarchyPath
import com.typewritermc.authoring.TimelineEntryPlacement
import com.typewritermc.capability.RealmCapabilities
import com.typewritermc.capability.RealmCapability
import com.typewritermc.capability.RealmCapabilityPermissionDeniedException
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmCommandOutcome
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.elements.Entry
import com.typewritermc.engine.pages.StaticEntry
import com.typewritermc.engine.pages.StaticPage
import com.typewritermc.library.Book
import com.typewritermc.library.BookPages
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterType
import skirout.editor.v1.capability.NotificationSeverity
import skirout.editor.v1.capability.PanelInstruction

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
