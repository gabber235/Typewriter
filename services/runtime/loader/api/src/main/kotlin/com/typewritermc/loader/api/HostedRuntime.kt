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

/**
 * Identifies a runtime role within a host projection.
 *
 * A Realm host can also run a panel engine, and primary engines may run on other hosts. Placement is independent
 * of artifact identity.
 */
@Serializable
enum class RuntimePlacement {
    REALM,
    PANEL_ENGINE,
    PRIMARY_ENGINE,
}

/**
 * Addresses a logical Realm within an organization, independently of the hosting service id.
 *
 * Request and event subjects use opposite service directions. Operation suffixes are validated as lowercase
 * segments separated by dots or underscores; host migration must not change the Realm identity.
 */
data class RealmServiceAddress(
    val realmId: String,
    val organizationId: String,
) {
    fun request(suffix: String): String = "service.to.$realmId.organization.$organizationId.realm.${validRealmOperation(suffix)}"

    fun event(suffix: String): String = "service.from.$realmId.organization.$organizationId.realm.${validRealmOperation(suffix)}"
}

/**
 * Builds a typed request template using the logical Realm and organization identifiers.
 *
 * The operation suffix is validated immediately. Subscribe or target the template with [RealmServiceAddress].
 */
fun realmRequestAddress(suffix: String): AddressTemplate<RealmServiceAddress> =
    realmAddress("service.to.{realm}.organization.{organization}.realm.${validRealmOperation(suffix)}")

/**
 * Builds the corresponding Realm event template for outbound notifications.
 *
 * The suffix follows the same grammar as request routes; the subject direction identifies events from the Realm.
 */
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

/**
 * Supplies one staged runtime with its identity, storage locations, artifact package, and host capabilities.
 *
 * The loader constructs this context from a resolved host projection. Host services are borrowed and outlive an
 * individual activation; the runtime owns only resources it creates.
 */
data class HostedDeploymentContext(
    val identity: HostedRuntimeIdentity,
    val directories: HostedRuntimeDirectories,
    val artifacts: HostedArtifactPackage,
    val facts: Map<String, String>,
    val host: HostedRuntimeHost,
)

/**
 * Separates the physical host, logical Realm, and placement of one runtime.
 *
 * Use the Realm id for Realm routing and the host id for participant coordination.
 */
data class HostedRuntimeIdentity(
    val hostId: String,
    val realmId: String,
    val placement: RuntimePlacement,
)

/**
 * Provides runtime state and deployment paths chosen by the loader.
 *
 * State is kept separately from the deployment workspace so replacing an artifact need not discard runtime data.
 * The context itself does not create directories or manage their cleanup.
 */
data class HostedRuntimeDirectories(
    val state: Path,
    val deployment: Path,
)

/**
 * Separates runtime and extension artifacts from catalog only artifact paths.
 *
 * [executableArtifacts] includes the runtime plus extensions with at least one eligible source part. Consumers
 * must still apply domain and placement rules when loading generated contributions.
 */
data class HostedArtifactPackage(
    val runtimeArtifact: Path,
    val extensions: List<HostedExtensionArtifact>,
    val catalogArtifacts: List<Path>,
) {
    val executableArtifacts: List<Path>
        get() = listOf(runtimeArtifact) + extensions.filter(HostedExtensionArtifact::hasEligibleSourcePart).map { it.path }
}

/**
 * Carries one extension artifact and the loader resolved source part dispositions.
 *
 * Eligibility belongs to source parts rather than the entire JAR. [hasEligibleSourcePart] only tests whether any
 * source part is eligible.
 */
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

/**
 * Records placement eligibility or explicit exclusion reasons for an extension source part.
 *
 * Eligible placement sets and ineligible reason lists must be nonempty. This metadata allows unavailable parts to
 * remain visible to catalog consumers.
 */
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

/**
 * Borrows the communicator for one organization bound host connection generation.
 *
 * The id distinguishes replacements. Runtime subscriptions must be recreated when the host emits a new session;
 * consumers must not close this shared communicator.
 */
data class HostedMessagingSession(
    val id: Long,
    val organizationId: String,
    val communicator: Communicator,
)

/**
 * Exposes loader owned capabilities across the runtime class loader boundary.
 *
 * A null [messaging] value means no usable session is available. Runtime code must observe replacement sessions
 * rather than retaining a communicator indefinitely. Telemetry and shared artifact access remain host owned.
 */
interface HostedRuntimeHost {
    val messaging: StateFlow<HostedMessagingSession?>
    val openTelemetry: OpenTelemetry
    val sharedArtifacts: SharedArtifactAccess
}

/**
 * ServiceLoader entry point for staging a hosted artifact.
 *
 * The loader requires exactly one provider on the runtime classpath. A successful [stage] transfers the returned
 * runtime to the loader; failure must release resources acquired before returning.
 */
interface HostedRuntimeProvider {
    suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime
}

/**
 * Defines the lifecycle controlled by the loader rollout participant.
 *
 * Staging precedes activation. Quiesce releases active behavior while keeping enough state to resume during
 * rollback; close retires the runtime permanently. Implementations report health separately from command
 * completion. The lifecycle owner serializes calls; concurrency and repeat call guarantees are implementation
 * specific.
 */
interface StagedHostedRuntime {
    val health: StateFlow<RuntimeHealth>

    /**
     * Starts the staged runtime and acquires activation resources.
     *
     * Return only after activation setup has completed; ongoing failures should be reflected in [health].
     * Exceptions fail the rollout command.
     */
    suspend fun activate()

    /**
     * Stops active behavior while retaining deployment resources needed by [resume].
     *
     * The loader uses this boundary before activating a replacement and may resume the prior runtime if
     * replacement fails.
     */
    suspend fun quiesce()

    /**
     * Restores behavior after quiescing during a rollout or rollback.
     *
     * Implementations may build a fresh activation scope; callers must not retain resources from the previous
     * activation.
     */
    suspend fun resume()

    /**
     * Releases resources owned by this runtime before its class loader is closed.
     *
     * Borrowed host services remain owned by the loader.
     */
    suspend fun close()
}

/**
 * Reports staged, healthy, or unhealthy runtime state to rollout supervision.
 *
 * Healthy reflects the implementation health contract; it does not by itself establish end to end content
 * execution.
 */
sealed interface RuntimeHealth {
    data object Staged : RuntimeHealth

    data object Healthy : RuntimeHealth

    data class Unhealthy(
        val reason: String,
    ) : RuntimeHealth
}
