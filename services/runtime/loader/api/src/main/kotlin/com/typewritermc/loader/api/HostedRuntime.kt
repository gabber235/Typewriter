package com.typewritermc.loader.api

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.Serializable
import java.nio.file.Path

@Serializable
enum class RuntimePlacement {
    REALM,
    PANEL_ENGINE,
    PRIMARY_ENGINE,
}

data class RealmServiceAddress(
    val realmId: String,
    val organizationId: String,
) {
    fun request(suffix: String): String = "service.to.$realmId.organization.$organizationId.realm.${validRealmOperation(suffix)}"

    fun event(suffix: String): String = "service.from.$realmId.organization.$organizationId.realm.${validRealmOperation(suffix)}"
}

fun realmRequestAddress(suffix: String): AddressTemplate<RealmServiceAddress> =
    realmAddress("service.to.{realm}.organization.{organization}.realm.${validRealmOperation(suffix)}")

fun realmEventAddress(suffix: String): AddressTemplate<RealmServiceAddress> =
    realmAddress("service.from.{realm}.organization.{organization}.realm.${validRealmOperation(suffix)}")

private fun realmAddress(pattern: String): AddressTemplate<RealmServiceAddress> =
    addressTemplate(
        pattern,
        { address ->
            addressValuesOf(
                "realm" to address.realmId,
                "organization" to address.organizationId,
            )
        },
        { values -> RealmServiceAddress(values.require("realm"), values.require("organization")) },
    )

private fun validRealmOperation(value: String): String =
    value.also {
        require(it.matches(Regex("[a-z0-9]+(?:[._][a-z0-9]+)*"))) {
            "Realm operation suffix must contain only lowercase names separated by dots or underscores."
        }
    }

data class HostedDeploymentContext(
    val identity: HostedRuntimeIdentity,
    val directories: HostedRuntimeDirectories,
    val artifacts: HostedArtifactPackage,
    val facts: Map<String, String>,
    val host: HostedRuntimeHost,
)

data class HostedRuntimeIdentity(
    val hostId: String,
    val realmId: String,
    val placement: RuntimePlacement,
)

data class HostedRuntimeDirectories(
    val state: Path,
    val deployment: Path,
)

data class HostedArtifactPackage(
    val runtimeArtifact: Path,
    val extensions: List<HostedExtensionArtifact>,
    val catalogArtifacts: List<Path>,
) {
    val executableArtifacts: List<Path>
        get() = listOf(runtimeArtifact) + extensions.filter(HostedExtensionArtifact::hasEligibleSourcePart).map { it.path }
}

data class HostedExtensionArtifact(
    val id: ArtifactId,
    val path: Path,
    val sourceParts: List<HostedSourcePart>,
) {
    val hasEligibleSourcePart: Boolean
        get() = sourceParts.any { it.disposition is SourcePartDisposition.Eligible }
}

data class HostedSourcePart(
    val name: String,
    val disposition: SourcePartDisposition,
)

@Serializable
sealed interface SourcePartDisposition {
    @Serializable
    data class Eligible(
        val placements: Set<RuntimePlacement>,
    ) : SourcePartDisposition {
        init {
            require(placements.isNotEmpty()) { "An eligible source part requires at least one runtime placement." }
        }
    }

    @Serializable
    data class Ineligible(
        val reasons: List<String>,
    ) : SourcePartDisposition {
        init {
            require(reasons.isNotEmpty()) { "An ineligible source part must explain why it is unavailable." }
        }
    }
}

data class HostedMessagingSession(
    val id: Long,
    val organizationId: String,
    val communicator: Communicator,
)

interface HostedRuntimeHost {
    val messaging: StateFlow<HostedMessagingSession?>
    val openTelemetry: OpenTelemetry
    val sharedArtifacts: SharedArtifactAccess
}

interface HostedRuntimeProvider {
    suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime
}

interface StagedHostedRuntime {
    val health: StateFlow<RuntimeHealth>

    suspend fun activate()

    suspend fun quiesce()

    suspend fun resume()

    suspend fun close()
}

sealed interface RuntimeHealth {
    data object Staged : RuntimeHealth

    data object Healthy : RuntimeHealth

    data class Unhealthy(
        val reason: String,
    ) : RuntimeHealth
}
