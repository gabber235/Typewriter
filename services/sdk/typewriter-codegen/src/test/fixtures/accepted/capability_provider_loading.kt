package fixture

import com.typewritermc.capability.RealmCapabilities
import com.typewritermc.capability.RealmCapability
import com.typewritermc.capability.RealmCommandCapabilityProvider
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmCommandOutcome
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.imprint.ArtifactId
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.types.shouldBeInstanceOf
import java.nio.file.Path

@RealmCapabilities
class Announcements {
    @RealmCapability.Command
    context(_: RealmCommandContext)
    suspend fun announce(request: String): RealmCommandOutcome = RealmCommandOutcome()
}

/**
 * The host that runs this main sees the fixture's classes too, as a host does when an extension sits on its classpath.
 * The bound capability provider must still load with the generated provider that creates it, or the provider could
 * not construct it.
 */
fun main(args: Array<String>) {
    val host = Announcements::class.java.classLoader
    GeneratedProviderLoader()
        .load(
            listOf(GeneratedProviderArtifact(ArtifactId("fixture"), Path.of(args.single()))),
            DeploymentFacts(emptyMap()),
            DiscoveryDomains.Realm,
            parentClassLoader = host,
        ).use { deployment ->
            val capabilities = deployment.providers.capabilities
            capabilities shouldHaveSize 1
            val provider = capabilities.single().provider.shouldBeInstanceOf<RealmCommandCapabilityProvider>()
            provider.javaClass.classLoader shouldNotBe host
        }
}
