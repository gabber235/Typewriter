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
import com.typewritermc.elements.EntryExecutionContext
import com.typewritermc.elements.ExecutableEntry
import com.typewritermc.elements.TypewriterElement
import com.typewritermc.elements.TypewriterElementFacet
import com.typewritermc.pages.GraphDirection
import com.typewritermc.pages.PageEditorDefinition
import com.typewritermc.pages.TypewriterPage
import com.typewritermc.pages.page
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.TypewriterPresentation
import com.typewritermc.presentation.presentation
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

@Serializable
@TypewriterType(
    id = "019d1f6c1d2e72499fa386964e89721d",
)
data class LiteralMessage(
    val value: String,
) : SyntheticMessage

@Serializable
@TypewriterType(
    id = "019d1f6d0ac77d3e83304b0be26ed722",
)
data class RepeatedMessage(
    val value: String,
    @SerialName("repeat_count")
    val repetitions: Int,
) : SyntheticMessage

/**
 * Conformance fixture connecting generated element discovery to executable entry dispatch. Execution forwards the
 * message payload to the runtime output, allowing the surrounding engine tests to observe delivery without
 * introducing external resources.
 */
@Serializable
@TypewriterElement(
    id = "019d1c2a8f7b7cc18c2a4a7b2fd1e281",
    name = "Synthetic Entry",
    description = "Verifies Typewriter discovery",
    icon = "material-symbols:science",
    color = "#7C4DFF",
)
data class SyntheticEntry(
    override val id: ElementInstanceId,
    val message: SyntheticMessage,
) : ExecutableEntry {
    context(context: EntryExecutionContext)
    override suspend fun execute() {
        context.output.send(message)
    }
}

@TypewriterPage(
    id = "019d3a87000170008000000000000001",
)
fun syntheticPage() =
    page(
        name = "Synthetic",
        icon = "material-symbols:account-tree",
        color = "#7C4DFF",
        editor = PageEditorDefinition.Graph(GraphDirection.LEFT_TO_RIGHT, listOf(SyntheticEntry::class)),
    )

@RealmCapabilities
class SyntheticRealmCapabilities {
    @RealmCapability.Search
    context(_: RealmSearchContext)
    fun searchMessages(request: RealmSearchRequest<LiteralMessage>): RealmSearch<RepeatedMessage> =
        realmSearch {
            partial(listOf(RepeatedMessage(request.payload.value, 1)))
            complete()
        }

    @RealmCapability.Computation
    context(_: RealmComputationContext)
    suspend fun repeatMessage(request: RepeatedMessage): LiteralMessage = LiteralMessage(request.value.repeat(request.repetitions))

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

@TypewriterElementFacet(SyntheticEntry::class)
class SyntheticEntryFacet : ElementRuntimeFacet<SyntheticEntry> {
    context(context: ElementRuntimeContext)
    override suspend fun attach(element: SyntheticEntry): ElementRuntimeHandle =
        object : ElementRuntimeHandle {
            override fun close() = Unit
        }
}

@TypewriterRegistrar(id = "synthetic")
class SyntheticRuntimeRegistrar : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        scope.own {}
    }
}
