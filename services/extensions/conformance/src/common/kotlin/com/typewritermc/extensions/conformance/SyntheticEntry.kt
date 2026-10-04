package com.typewritermc.extensions.conformance

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.capability.NotificationSeverity
import com.typewritermc.capability.PanelInstruction
import com.typewritermc.capability.RealmCapabilities
import com.typewritermc.capability.RealmCapability
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmCommandOutcome
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.capability.RealmSearch
import com.typewritermc.capability.RealmSearchContext
import com.typewritermc.capability.RealmSearchRequest
import com.typewritermc.capability.realmSearch
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.discovery.TypewriterRegistrar
import com.typewritermc.elements.ElementRuntimeContext
import com.typewritermc.elements.ElementRuntimeFacet
import com.typewritermc.elements.ElementRuntimeHandle
import com.typewritermc.elements.Entry
import com.typewritermc.elements.TypewriterElementFacet
import com.typewritermc.expression.literal
import com.typewritermc.library.Book
import com.typewritermc.library.BookPages
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.presentation.AppliedPresentation
import com.typewritermc.types.Color
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceRecord
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Polymorphic message family exercising generated schema discovery, serialized field aliases, and presentation
 * variant selection. The literal and repeated variants provide distinct concrete payloads for the conformance
 * entry and Realm capability fixtures.
 */
@Serializable
sealed interface SyntheticMessage

@TypewriterType(
    id = "019d1f6c1d2e72499fa386964e89721d",
)
data class LiteralMessage(
    val value: String,
) : SyntheticMessage

@TypewriterType(
    id = "019d1f6d0ac77d3e83304b0be26ed722",
)
data class RepeatedMessage(
    val value: String,
    @SerialName("repeat_count")
    val repetitions: Int,
) : SyntheticMessage

interface ConformanceEntry : Entry {
    override val placement: GraphPlacement
}

/** Conformance fixture connecting generated element discovery to polymorphic authoring metadata. */
@TypewriterType(id = "019d1c2a8f7b7cc18c2a4a7b2fd1e281", revision = 1)
@TypewriterDisplay(
    name = "Synthetic Entry",
    description = "Verifies Typewriter discovery",
    icon = "material-symbols:science",
    color = Color.Hex.PURPLE,
)
data class SyntheticEntry(
    override val name: String,
    override val placement: GraphPlacement,
    val message: SyntheticMessage,
    val cues: List<Ref<SyntheticEntryCues.Entry, SyntheticSegment>> = emptyList(),
) : ConformanceEntry

/** Concrete Page used by the reference and page catalog conformance checks. */
@TypewriterType(id = "019d3a87000170008000000000000001")
@TypewriterDisplay(name = "Synthetic", icon = "material-symbols:account-tree", color = "#7C4DFF")
data class SyntheticPage(
    override val book: Ref<BookPages.Page, Book>,
    override val name: String = "",
    override val chapter: ChapterPath = ChapterPath.Root,
    override val priority: Int = 0,
    override val elements: List<Ref<PageElements.Page, ConformanceEntry>> = emptyList(),
) : Page

object SyntheticPageEditor : SyntheticPagePresentation {
    override val roles = setOf(PresentationRole.EDITOR)

    override fun SyntheticPagePresentationScope.present() {
        elements { graphPage(GraphDirection.LEFT_TO_RIGHT) }
    }
}

/** Exposes search, computation, and command fixtures for generated Realm capability discovery. */
@RealmCapabilities
class SyntheticRealmCapabilities {
    /** Returns one matching repeated message and then completes the search stream. */
    @RealmCapability.Search
    context(_: RealmSearchContext)
    fun searchMessages(request: RealmSearchRequest<LiteralMessage>): RealmSearch<RepeatedMessage> =
        realmSearch {
            partial(listOf(RepeatedMessage(request.payload.value, 1)))
            complete()
        }

    /** Repeats the input value and returns the literal message result. */
    @RealmCapability.Computation
    context(_: RealmComputationContext)
    suspend fun repeatMessage(request: RepeatedMessage): LiteralMessage = LiteralMessage(request.value.repeat(request.repetitions))

    /** Emits a successful panel notification containing the input value. */
    @RealmCapability.Command
    context(_: RealmCommandContext)
    suspend fun publishMessage(request: LiteralMessage): RealmCommandOutcome =
        RealmCommandOutcome(
            instructions =
                listOf(
                    PanelInstruction.Notify(
                        severity = NotificationSeverity.SUCCESS,
                        message = request.value,
                    ),
                ),
        )
}

object LiteralMessageEditorPresentation : LiteralMessagePresentation {
    override val priority: Int = 100

    override fun LiteralMessagePresentationScope.present() {
        value { textInput(multiline = true) }
    }
}

object RepeatedMessageEditorPresentation : RepeatedMessagePresentation {
    override val priority: Int = 100

    override fun RepeatedMessagePresentationScope.present() {
        value { textInput() }
        repetitions { numericInput() }
    }
}

object LiteralMessageCompactPresentation : LiteralMessagePresentation {
    override val priority: Int = 10

    override fun LiteralMessagePresentationScope.present() {
        value { textInput() }
    }
}

object RepeatedMessageCompactPresentation : RepeatedMessagePresentation {
    override val priority: Int = 10

    override fun RepeatedMessagePresentationScope.present() {
        value { textInput() }
    }
}

object SyntheticEntryEditorPresentation : SyntheticEntryPresentation {
    override val priority: Int = 100

    override fun SyntheticEntryPresentationScope.present() {
        message {
            label("Message")
            polymorphicInput {
                form(
                    AppliedPresentation(LiteralMessageDefinition.use, LiteralMessageEditorPresentation),
                    literal("Literal"),
                )
                form(
                    AppliedPresentation(RepeatedMessageDefinition.use, RepeatedMessageEditorPresentation),
                    literal("Repeated"),
                )
            }
        }
        remainingFields { exclude(message) }
    }
}

object SyntheticEntryCompactPresentation : SyntheticEntryPresentation {
    override val priority: Int = 10

    override fun SyntheticEntryPresentationScope.present() {
        message {
            polymorphicInput {
                form(
                    AppliedPresentation(LiteralMessageDefinition.use, LiteralMessageCompactPresentation),
                    literal("Literal"),
                )
                form(
                    AppliedPresentation(RepeatedMessageDefinition.use, RepeatedMessageCompactPresentation),
                    literal("Repeated"),
                )
            }
        }
        remainingFields { exclude(message) }
    }
}

/** Supplies the runtime facet discovered for [SyntheticEntry]. */
@TypewriterElementFacet(SyntheticEntry::class)
class SyntheticEntryFacet : ElementRuntimeFacet<SyntheticEntry> {
    context(context: ElementRuntimeContext)
    override suspend fun attach(element: ResourceRecord<ResourceId, SyntheticEntry>): ElementRuntimeHandle =
        object : ElementRuntimeHandle {
            override fun close() = Unit
        }
}

/** Registers the conformance runtime scope and owns no external resources. */
@TypewriterRegistrar(id = "synthetic")
class SyntheticRuntimeRegistrar : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        scope.own {}
    }
}
