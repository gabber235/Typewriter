@file:JvmName("EngineParts")

package fixture

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.events.EnginePart
import com.typewritermc.events.EnginePartDependencies
import com.typewritermc.imprint.ArtifactId
import java.nio.file.Path
import kotlin.reflect.KClass

/** Something an engine provides to its parts. */
class Clock(
    val now: Long,
)

interface Greeter : EnginePart {
    fun greet(): String
}

// Implementing EnginePart is the registration: no annotation, no list.
class ClockGreeter(
    private val clock: Clock,
) : Greeter {
    override fun greet(): String = "hello at ${clock.now}"
}

class Standalone : EnginePart

// Not a part an engine can build.
abstract class HalfPart : EnginePart

interface OnlyAMarker : EnginePart

fun main(args: Array<String>) {
    val deployment =
        GeneratedProviderLoader().load(
            artifacts = listOf(GeneratedProviderArtifact(ArtifactId("fixture:engine-parts"), Path.of(args.single()))),
            facts = DeploymentFacts(),
            domain = DiscoveryDomains.Execution,
            acceptedKinds = setOf(GeneratedProviderKind.EnginePart),
            parentClassLoader = requireNotNull(Clock::class.java.classLoader),
        )
    deployment.use {
        val parts = it.providers.engineParts.associateBy { part -> part.type.qualifiedName }
        check(parts.keys == setOf(ClockGreeter::class.qualifiedName, Standalone::class.qualifiedName)) { parts.keys.toString() }

        val greeter = parts.getValue(ClockGreeter::class.qualifiedName)
        check(greeter.binds.toSet() == setOf(ClockGreeter::class, Greeter::class, EnginePart::class)) { greeter.binds.toString() }
        val built =
            greeter.create(
                object : EnginePartDependencies {
                    @Suppress("UNCHECKED_CAST")
                    override fun <T : Any> get(type: KClass<T>): T = if (type == Clock::class) Clock(7) as T else error("no ${type.simpleName}")
                },
            )
        check((built as Greeter).greet() == "hello at 7") { built.toString() }
    }
}
