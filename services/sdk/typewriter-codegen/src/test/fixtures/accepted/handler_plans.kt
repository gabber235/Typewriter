@file:JvmName("HandlerPlans")

package fixture

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.elements.Entry
import com.typewritermc.events.AfterHandler
import com.typewritermc.events.CancelableEvent
import com.typewritermc.events.Candidate
import com.typewritermc.events.ConfiguredEvent
import com.typewritermc.events.Context
import com.typewritermc.events.EntryReader
import com.typewritermc.events.EntryScope
import com.typewritermc.events.EnginePartDependencies
import com.typewritermc.events.Event
import com.typewritermc.events.Handler
import com.typewritermc.events.HandlerConfig
import com.typewritermc.events.Origin
import com.typewritermc.events.Outcome
import com.typewritermc.events.Param
import com.typewritermc.events.Triggered
import com.typewritermc.events.TriggeredEvent
import com.typewritermc.events.Verdict
import com.typewritermc.events.VerdictHandler
import com.typewritermc.events.deny
import com.typewritermc.events.pass
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Var
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.EntryTypeId
import com.typewritermc.imprint.HandledEntriesMetadataCodec
import com.typewritermc.imprint.IMPRINT_HANDLED_ENTRIES_PATH
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.canonicalText
import com.typewritermc.types.declared
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValuePath
import java.nio.file.Path
import kotlin.io.path.readBytes
import kotlin.coroutines.Continuation
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.startCoroutine
import kotlin.reflect.KClass

@TypewriterType(id = "a0000000000000000000000000000939")
data class Smashed(
    val player: Protagonist,
) : CancelableEvent

/** The formula context of an entry about one event. */
interface AboutEvent<E : Event> {
    val event: E
}

// One guard serves every cancelable event: its type argument is the event.
@TypewriterType(id = "a0000000000000000000000000000932")
data class GuardEntry<E : CancelableEvent>(
    override val page: Ref<PageElements.Element, Page>,
    override val name: String = "",
    override val placement: GraphPlacement = GraphPlacement(),
    val cancel: Var<Boolean, AboutEvent<E>>,
) : Entry

@TypewriterType(id = "a0000000000000000000000000000933")
data class VaultEntry(
    override val page: Ref<PageElements.Element, Page>,
    override val name: String = "",
    override val placement: GraphPlacement = GraphPlacement(),
    val greeting: Var<String, DefinitionScope>,
    val spoken: Spoken = Spoken(Var.Value(1)),
    val choices: List<Choice> = emptyList(),
    val prices: Map<String, Choice> = emptyMap(),
) : Entry

// Records inside an entry: accessors reach their fields at any depth, through lists and maps too.
@TypewriterType(id = "a0000000000000000000000000000934")
data class Spoken(
    val minLines: Var<Int, DefinitionScope>,
    val voice: String = "calm",
)

@TypewriterType(id = "a0000000000000000000000000000935")
data class Choice(
    val text: Var<String, DefinitionScope>,
)

object EveryTick

data class Tick<C : Any>(
    override val config: C,
) : ConfiguredEvent<C>

/** A live capability a handler may ask for. */
interface Shouts {
    fun shout(text: String)
}

@Handler
fun <E : CancelableEvent> E.rule(guard: Candidate<GuardEntry<E>>): Verdict = if (guard.cancel) deny() else pass()

@Handler
fun Triggered<VaultEntry>.greet(
    shouts: Shouts,
    protagonist: Protagonist,
    origin: Origin?,
    outcome: Outcome<TriggeredEvent<VaultEntry>>,
) {
    val lines = List(spoken.minLines) { greeting }
    val options = choices.indices.joinToString("/") { choices[it].text }
    shouts.shout("${lines.joinToString(" ")} ${protagonist.principal.id} ${spoken.voice} $options ${prices.getValue("gold").text}")
}

@Handler
suspend fun Tick<EveryTick>.animate(
    config: EveryTick,
    guard: Candidate<GuardEntry<Smashed>>?,
) {
}

// An entry configuration: one configuration per published vault, and the candidate is the vault the tick is for.
@Handler
suspend fun Tick<VaultEntry>.ring(vault: Candidate<VaultEntry>) {
}

private val page = Ref<PageElements.Element, Page>(ResourceId("page"))
private val steve = Protagonist(PrincipalId(PrincipalId.MINECRAFT, "steve"))

/**
 * Reads an entry as written, following each path through its Kotlin properties: a list item's id is its index, a map
 * row's id is its key. A `Var` reads as its written value.
 */
private val written =
    object : EntryReader {
        override fun read(
            scope: EntryScope<*>,
            path: ValuePath,
        ): Any? =
            when (val held = valueAt(scope.entry, path)) {
                is Var.Value<*, *> -> held.value
                else -> held
            }

        override fun has(
            scope: EntryScope<*>,
            path: ValuePath,
        ): Boolean = valueAt(scope.entry, path) != null

        override fun items(
            scope: EntryScope<*>,
            path: ValuePath,
        ): List<ItemId> =
            when (val held = valueAt(scope.entry, path)) {
                is List<*> -> held.indices.map { ItemId(value = "$it") }
                is Map<*, *> -> held.keys.map { ItemId(value = "$it") }
                else -> error("$path holds no items")
            }

        private fun valueAt(
            root: Any?,
            path: ValuePath,
        ): Any? =
            path.segments.fold(root to null as Map.Entry<*, *>?) { (value, row), segment ->
                when (segment) {
                    is PathSegment.FieldWrapper -> {
                        val name = segment.value.name
                        value!!.javaClass.getMethod("get${name.replaceFirstChar(Char::uppercaseChar)}").invoke(value) to null
                    }

                    is PathSegment.ItemWrapper -> {
                        when (value) {
                            is List<*> -> value[segment.value.id.value.toInt()] to null
                            is Map<*, *> -> value.entries.single { "${it.key}" == segment.value.id.value }.let { it to it }
                            else -> error("$path is no collection")
                        }
                    }

                    PathSegment.MAP_KEY -> row!!.key to null
                    PathSegment.MAP_VALUE -> row!!.value to null
                    else -> error("$path has an unknown segment")
                }
            }.first
    }

private fun <E : Entry> candidate(entry: E) = Candidate(entry, priority = 0, subject = steve, context = Context.EMPTY, reader = written)

private fun <T> runSuspending(block: suspend () -> T) {
    block.startCoroutine(Continuation(EmptyCoroutineContext) { it.getOrThrow() })
}

fun main(args: Array<String>) {
    // The part records the entries its handlers give behaviour: the triggered vault entry and the guards they read.
    val handled = HandledEntriesMetadataCodec.decode(Path.of(args.single()).resolve(IMPRINT_HANDLED_ENTRIES_PATH).readBytes()).entries
    val expected =
        listOf("a0000000000000000000000000000932", "a0000000000000000000000000000933")
            .map { EntryTypeId(TypeDefinitionId.declared(it).canonicalText) }
    check(handled.toSet() == expected.toSet() && handled.size == expected.size) { handled.toString() }

    val deployment =
        GeneratedProviderLoader().load(
            artifacts = listOf(GeneratedProviderArtifact(ArtifactId("fixture:handler-plans"), Path.of(args.single()))),
            facts = DeploymentFacts(),
            domain = DiscoveryDomains.Execution,
            acceptedKinds = setOf(GeneratedProviderKind.EnginePart),
            parentClassLoader = requireNotNull(Smashed::class.java.classLoader),
        )
    deployment.use {
        val parts = it.providers.engineParts.associateBy { part -> part.type.simpleName }
        val noDependencies =
            object : EnginePartDependencies {
                override fun <T : Any> get(type: KClass<T>): T = error("no ${type.simpleName}")
            }

        // A generic rule takes every cancelable event and finds only guards about the occurring event.
        @Suppress("UNCHECKED_CAST")
        val rule = parts.getValue("CancelableEvent_ruleHandler").create(noDependencies) as VerdictHandler<CancelableEvent>
        check(rule.event == CancelableEvent::class) { rule.event.toString() }
        check(rule.entry == null) { rule.entry.toString() }
        check(rule.params == listOf(Param.Candidate(GuardEntry::class, ofEvent = true))) { rule.params.toString() }
        val smashed = Smashed(steve)
        val cancelling = candidate(GuardEntry<Smashed>(page, cancel = Var.Value(true)))
        val allowing = candidate(GuardEntry<Smashed>(page, cancel = Var.Value(false)))
        check(rule.run(smashed, listOf(cancelling)) is Verdict.Deny) { "a cancelling guard denies" }
        check(rule.run(smashed, listOf(allowing)) is Verdict.Pass) { "an allowing guard passes" }

        // An after handler on a triggered step is called on the step the runtime built, and reads the entry's fields
        // through accessors at any depth, through lists and maps too.
        @Suppress("UNCHECKED_CAST")
        val greet = parts.getValue("Triggered_greetHandler").create(noDependencies) as AfterHandler<TriggeredEvent<VaultEntry>>
        check(greet.event == TriggeredEvent::class) { greet.event.toString() }
        check(greet.entry == VaultEntry::class) { greet.entry.toString() }
        check(
            greet.params ==
                listOf(
                    Param.Triggered(VaultEntry::class),
                    Param.Trait(Shouts::class),
                    Param.Identity(Protagonist::class),
                    Param.Origin(optional = true),
                    Param.Outcome,
                ),
        ) { greet.params.toString() }
        val vault =
            VaultEntry(
                page,
                greeting = Var.Value("welcome"),
                spoken = Spoken(Var.Value(2), voice = "warm"),
                choices = listOf(Choice(Var.Value("stay")), Choice(Var.Value("leave"))),
                prices = mapOf("gold" to Choice(Var.Value("ten"))),
            )
        check(candidate(vault).greeting == "welcome") { "a candidate reads its entry's field" }
        check(candidate(vault).spoken.minLines == 2) { "a candidate reads a field of a nested record" }
        val event = TriggeredEvent(vault, steve, Context.EMPTY)
        val triggered = Triggered(event, written)
        val shouted = mutableListOf<String>()
        val shouts =
            object : Shouts {
                override fun shout(text: String) {
                    shouted += text
                }
            }
        runSuspending { greet.run(event, listOf(triggered, shouts, steve, null, Outcome.Allowed(event))) }
        check(shouted == listOf("welcome welcome steve warm stay/leave ten")) { shouted.toString() }

        // A configured event hands its configuration to the handler.
        val animate = parts.getValue("Tick_animateHandler").create(noDependencies) as AfterHandler<*>
        check(animate.event == Tick::class) { animate.event.toString() }
        check(
            animate.params == listOf(Param.Config(EveryTick::class), Param.Candidate(GuardEntry::class, ofEvent = false, optional = true)),
        ) { animate.params.toString() }
        check(animate.config == HandlerConfig.Object(EveryTick)) { animate.config.toString() }

        // An entry configuration names its entry type, and a candidate of that type is the configuration's own entry.
        val ring = parts.getValue("Tick_ringHandler").create(noDependencies) as AfterHandler<*>
        check(ring.config == HandlerConfig.Entries(VaultEntry::class)) { ring.config.toString() }
        check(ring.params == listOf(Param.Candidate(VaultEntry::class, ofConfig = true))) { ring.params.toString() }

        // A handler on an event that is not configured has no configuration.
        check(greet.config == null) { greet.config.toString() }
    }
}
