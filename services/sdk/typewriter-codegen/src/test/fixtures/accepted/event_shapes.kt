@file:JvmName("EventShapes")

package fixture

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.events.EnginePartDependencies
import com.typewritermc.events.Event
import com.typewritermc.events.EventShape
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.TypewriterType
import java.nio.file.Path
import kotlin.reflect.KClass

@TypewriterType(id = "a0000000000000000000000000000941")
data class Waved(
    val player: Protagonist,
    val times: Int,
) : Event

@TypewriterType(id = "a0000000000000000000000000000942")
data class Reconnected(
    val player: Protagonist,
    val session: Session,
) : Event

@TypewriterType(id = "a0000000000000000000000000000943")
data class Ticked(
    val count: Int,
) : Event

fun main(args: Array<String>) {
    val deployment =
        GeneratedProviderLoader().load(
            artifacts = listOf(GeneratedProviderArtifact(ArtifactId("fixture:event-shapes"), Path.of(args.single()))),
            facts = DeploymentFacts(),
            domain = DiscoveryDomains.Execution,
            acceptedKinds = setOf(GeneratedProviderKind.EnginePart),
            parentClassLoader = requireNotNull(Waved::class.java.classLoader),
        )
    deployment.use {
        val noDependencies =
            object : EnginePartDependencies {
                override fun <T : Any> get(type: KClass<T>): T = error("no ${type.simpleName}")
            }
        val shapes =
            it.providers.engineParts
                .filter { part -> EventShape::class in part.binds }
                .map { part -> part.create(noDependencies) as EventShape<*> }
                .associateBy { shape -> shape.event }
        check(shapes.keys == setOf(Waved::class, Reconnected::class, Ticked::class)) { shapes.keys.toString() }

        val steve = Protagonist(PrincipalId(PrincipalId.MINECRAFT, "steve"))
        val session = Session(steve, SessionId("first"))

        // The only identity field is the subject.
        @Suppress("UNCHECKED_CAST")
        val waved = shapes.getValue(Waved::class) as EventShape<Waved>
        check(waved.subject(Waved(steve, 3)) == steve) { "the protagonist is the subject" }
        check(waved.identities(Waved(steve, 3)) == listOf(steve)) { "one identity field" }

        // Two identity fields of different kinds: both are identities, neither is the only one.
        @Suppress("UNCHECKED_CAST")
        val reconnected = shapes.getValue(Reconnected::class) as EventShape<Reconnected>
        check(reconnected.identities(Reconnected(steve, session)) == listOf(steve, session)) { "every identity field" }
        check(reconnected.subject(Reconnected(steve, session)) == null) { "no only identity field" }

        // An event without identity fields has no subject.
        @Suppress("UNCHECKED_CAST")
        val ticked = shapes.getValue(Ticked::class) as EventShape<Ticked>
        check(ticked.subject(Ticked(1)) == null) { "a tick has no subject" }
        check(ticked.identities(Ticked(1)).isEmpty()) { "a tick has no identities" }
    }
}
