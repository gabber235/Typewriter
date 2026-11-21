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
import com.typewritermc.events.EnginePartDependencies
import com.typewritermc.events.Event
import com.typewritermc.events.Handler
import com.typewritermc.events.Origin
import com.typewritermc.events.Outcome
import com.typewritermc.events.Param
import com.typewritermc.events.Triggered
import com.typewritermc.events.VarReader
import com.typewritermc.events.Verdict
import com.typewritermc.events.VerdictHandler
import com.typewritermc.events.deny
import com.typewritermc.events.pass
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Var
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypewriterType
import java.nio.file.Path
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
) : Entry

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
    greeting: String,
    shouts: Shouts,
    protagonist: Protagonist,
    origin: Origin?,
    outcome: Outcome<Triggered<VaultEntry>>,
) {
    shouts.shout("$greeting ${protagonist.principal.id}")
}

@Handler
suspend fun Tick<EveryTick>.animate(
    config: EveryTick,
    guard: Candidate<GuardEntry<Smashed>>?,
) {
}

private val page = Ref<PageElements.Element, Page>(ResourceId("page"))
private val steve = Protagonist(PrincipalId(PrincipalId.MINECRAFT, "steve"))

/** Reads a candidate's fields as their written values. */
private val written =
    object : VarReader {
        @Suppress("UNCHECKED_CAST")
        override fun <T> read(
            field: Var<T, *>,
            candidate: Candidate<*>,
        ): T = (field as Var.Value<T, *>).value
    }

private fun <E : Entry> candidate(entry: E) = Candidate(entry, priority = 0, subject = steve, context = Context.EMPTY, reader = written)

private fun <T> runSuspending(block: suspend () -> T) {
    block.startCoroutine(Continuation(EmptyCoroutineContext) { it.getOrThrow() })
}

fun main(args: Array<String>) {
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

        // An after handler on a triggered entry reads the entry's field, the live trait and the identity.
        @Suppress("UNCHECKED_CAST")
        val greet = parts.getValue("Triggered_greetHandler").create(noDependencies) as AfterHandler<Triggered<VaultEntry>>
        check(greet.event == Triggered::class) { greet.event.toString() }
        check(greet.entry == VaultEntry::class) { greet.entry.toString() }
        check(
            greet.params ==
                listOf(
                    Param.Field("greeting", read = { error("equality ignores the reader") }),
                    Param.Trait(Shouts::class),
                    Param.Identity(Protagonist::class),
                    Param.Origin(optional = true),
                    Param.Outcome,
                ),
        ) { greet.params.toString() }
        val vault = VaultEntry(page, greeting = Var.Value("welcome"))
        val field = greet.params.first() as Param.Field
        check(field.read(vault) == vault.greeting) { "the field reads the triggered entry's Var" }
        check(candidate(vault).greeting == "welcome") { "a candidate reads its entry's field" }
        val triggered = Triggered(vault, steve, Context.EMPTY)
        val shouted = mutableListOf<String>()
        val shouts =
            object : Shouts {
                override fun shout(text: String) {
                    shouted += text
                }
            }
        runSuspending { greet.run(triggered, listOf("welcome", shouts, steve, null, Outcome.Allowed(triggered))) }
        check(shouted == listOf("welcome steve")) { shouted.toString() }

        // A configured event hands its configuration to the handler.
        val animate = parts.getValue("Tick_animateHandler").create(noDependencies) as AfterHandler<*>
        check(animate.event == Tick::class) { animate.event.toString() }
        check(
            animate.params == listOf(Param.Config(EveryTick::class), Param.Candidate(GuardEntry::class, ofEvent = false, optional = true)),
        ) { animate.params.toString() }
    }
}
