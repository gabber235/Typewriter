package com.typewritermc.extensions.conformance

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
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.discovery.TypewriterRegistrar
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementRuntimeContext
import com.typewritermc.elements.ElementRuntimeFacet
import com.typewritermc.elements.ElementRuntimeHandle
import com.typewritermc.elements.Entry
import com.typewritermc.elements.TypewriterElement
import com.typewritermc.elements.TypewriterElementFacet
import com.typewritermc.pages.GraphDirection
import com.typewritermc.pages.PageEditorDefinition
import com.typewritermc.pages.TypewriterPage
import com.typewritermc.pages.page
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.TypewriterPresentation
import com.typewritermc.presentation.presentation
import com.typewritermc.types.Color
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

interface ConformanceEntry : Entry

/** Conformance fixture connecting generated element discovery to polymorphic authoring metadata. */
@TypewriterElement(
    id = "019d1c2a8f7b7cc18c2a4a7b2fd1e281",
    revision = 2,
    name = "Synthetic Entry",
    description = "Verifies Typewriter discovery",
    icon = "material-symbols:science",
    color = Color.Hex.PURPLE,
)
data class SyntheticEntry(
    override val id: ElementInstanceId,
    override val name: String,
    val message: SyntheticMessage,
) : ConformanceEntry

/** Provides the generated page declaration used by page reference conformance checks. */
@TypewriterPage(
    id = "019d3a87000170008000000000000001",
)
fun syntheticPage() =
    page(
        name = "Synthetic",
        icon = "material-symbols:account-tree",
        color = "#7C4DFF",
        editor = PageEditorDefinition.Graph(GraphDirection.LEFT_TO_RIGHT, listOf(ConformanceEntry::class)),
    )

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

/** Builds the default editor presentation with controls for both message variants. */
@TypewriterPresentation(
    default = true,
    priority = 100,
)
context(_: PresentationBuildContext)
fun syntheticEntryEditor() =
    presentation<SyntheticEntry>(name = "editor") {
        section(
            key = "message",
            title = "Message",
            initiallyExpanded = true,
        ) {
            polymorphicInput(SyntheticEntry::message) {
                type<LiteralMessage>("Literal") {
                    textInput(LiteralMessage::value, multiline = true)
                }
                type<RepeatedMessage>("Repeated") {
                    textInput(RepeatedMessage::value)
                    numericInput(RepeatedMessage::repetitions)
                }
            }
        }
    }

/** Builds a compact named presentation for the same entry. */
@TypewriterPresentation(priority = 10)
context(_: PresentationBuildContext)
fun syntheticEntryCompactEditor() =
    presentation<SyntheticEntry>(name = "compact") {
        polymorphicInput(SyntheticEntry::message) {
            type<LiteralMessage>("Literal") {
                textInput(LiteralMessage::value)
            }
            type<RepeatedMessage>("Repeated") {
                textInput(RepeatedMessage::value)
            }
        }
    }

/** Supplies the runtime facet discovered for [SyntheticEntry]. */
@TypewriterElementFacet(SyntheticEntry::class)
class SyntheticEntryFacet : ElementRuntimeFacet<SyntheticEntry> {
    context(context: ElementRuntimeContext)
    override suspend fun attach(element: SyntheticEntry): ElementRuntimeHandle =
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
