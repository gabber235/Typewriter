package com.typewritermc.engine.events.testing

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.Entry
import com.typewritermc.engine.events.Triggerable
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.CancelableEvent
import com.typewritermc.events.Event
import com.typewritermc.events.EventReason
import com.typewritermc.events.EventShape
import com.typewritermc.formula.Var
import com.typewritermc.identity.Identity
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId

/** A protagonist for event runtime tests. */
fun protagonist(name: String = "alex"): Protagonist = Protagonist(PrincipalId(PrincipalId.MINECRAFT, name))

/** A cancelable test event whose [strength] a change verdict can alter. */
data class Poke(
    val protagonist: Protagonist = protagonist(),
    val strength: Int = 1,
) : CancelableEvent

/** A second cancelable test event, so a rule about one event can be told apart from a rule about another. */
data class Shove(
    val protagonist: Protagonist = protagonist(),
) : CancelableEvent

/** A deny reason named [code]. */
fun reason(code: String): EventReason = EventReason(code = code, message = code)

/** The shapes of the test events, as KSP generates them for real events. */
val testShapes: List<EventShape<*>> = listOf(shape<Poke> { it.protagonist }, shape<Shove> { it.protagonist })

private inline fun <reified E : Event> shape(crossinline subject: (E) -> Identity): EventShape<E> =
    object : EventShape<E> {
        override val event = E::class

        override fun subject(event: E): Identity = subject(event)

        override fun identities(event: E): List<Identity> = listOf(subject(event))
    }

private val testPage = Ref<PageElements.Element, Page>(ResourceId("page"))

/** A rule entry about one cancelable event: it denies the event while [cancel] holds. */
class GuardEntry<E : CancelableEvent>(
    override val name: String = "guard",
    val cancel: Var<Boolean, Any> = Var.Value(true),
    override val page: Ref<PageElements.Element, Page> = testPage,
    override val placement: GraphPlacement = GraphPlacement(),
) : Entry

/** A sequence entry a chain passes through; it links to the entries named in [next]. */
class StepEntry(
    override val name: String,
    next: List<String> = emptyList(),
    val message: Var<String, Any> = Var.Value(name),
    override val page: Ref<PageElements.Element, SequencePage> = Ref(ResourceId("sequence")),
    override val placement: GraphPlacement = GraphPlacement(),
) : Triggerable {
    override val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>> = links(next)
}
