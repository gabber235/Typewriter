@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.engine.events.testing

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.TypedPath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.authoring.typedPath
import com.typewritermc.elements.Entry
import com.typewritermc.engine.events.Triggerable
import com.typewritermc.engine.formula.testing.Said
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.CancelableEvent
import com.typewritermc.events.Event
import com.typewritermc.events.EventReason
import com.typewritermc.events.EventShape
import com.typewritermc.events.RecordScope
import com.typewritermc.events.SubscribedEvent
import com.typewritermc.events.readField
import com.typewritermc.formula.Var
import com.typewritermc.identity.Engine
import com.typewritermc.identity.Identity
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.declared
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValuePath

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

/** A test event about one connection, so a subject that is no protagonist can be told apart. */
data class Knock(
    val session: Session = Session(protagonist(), SessionId("tab")),
) : Event

/** A subscribed test event without a subject: a beat a [TestSubscribedSource] emits for one subscription. */
data class Beat<S : Any>(
    override val subscription: S,
) : SubscribedEvent<S>

/** A beat subscription written in code: present while a handler on it can run. */
data object EveryBeat

/** A second code subscription, so a handler on one object subscription can be told apart from another. */
data object Downbeat

/** A beat subscription written as content: one subscription per published entry. */
data class BeatEntry(
    override val name: String,
    val every: Int = 1,
    override val page: Ref<PageElements.Element, Page> = Ref(ResourceId("page")),
    override val placement: GraphPlacement = GraphPlacement(),
) : Entry

/** A test event about one engine, so a subject that is an engine can be told apart. */
data class Ring(
    val engine: Engine,
) : Event

/** A deny reason named [code]. */
fun reason(code: String): EventReason = EventReason(code = code, message = code)

/** The shapes of the test events, as KSP generates them for real events. */
val testShapes: List<EventShape<*>> =
    listOf(shape<Poke> { it.protagonist }, shape<Shove> { it.protagonist }, shape<Knock> { it.session }, shape<Said> { it.protagonist }, shape<Ring> { it.engine })

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

/**
 * The paths of the test entries' `Var` fields, as codegen emits them for a real entry, read by their accessors below. The test entries have no catalog
 * type, so both name one stand in owner.
 */
object TestFields {
    private val owner = TypeDefinitionId.declared("e1f0000000000000000000000000b001")

    val cancel: TypedPath<GuardEntry<*>, Var<Boolean, Any>> = typedPath(owner, ValuePath.root.field("cancel"), ScalarKind.BOOLEAN.use)

    val message: TypedPath<StepEntry, Var<String, Any>> = typedPath(owner, ValuePath.root.field("message"), ScalarKind.TEXT.use)
}

/** The accessor of [GuardEntry.cancel], as codegen emits it for a real entry. */
val RecordScope<GuardEntry<*>>.cancel: Boolean get() = readField(TestFields.cancel)

/** The accessor of [StepEntry.message], as codegen emits it for a real entry. */
val RecordScope<StepEntry>.message: String get() = readField(TestFields.message)

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
