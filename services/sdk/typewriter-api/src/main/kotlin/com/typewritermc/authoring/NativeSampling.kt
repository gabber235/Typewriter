package com.typewritermc.authoring

import com.typewritermc.configuration.InitializationRequirements
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse

data class AppliedNativeArguments(
    val portable: List<TypeUse>,
    val bindings: List<NativeBinding<*>>,
    val resolver: com.typewritermc.types.NativeBindingResolver,
)

fun AppliedNativeArguments.requireOpaqueCompatibility(allowed: Set<Int>) {
    bindings.forEachIndexed { index, binding ->
        if (binding.opaque && index !in allowed) {
            throw com.typewritermc.types.NativeBindingException(
                "opaque_native_argument_violates_bound",
                "Portable argument $index cannot satisfy the compiled Kotlin bound.",
            )
        }
    }
}

data class SamplingInputs(
    val required: Map<com.typewritermc.types.FieldOwner, CompleteValue>,
)

interface DefaultModeResolver {
    fun resolve(requirements: Map<TypeDefinitionId, InitializationRequirements>): Map<TypeDefinitionId, InitializationMode>

    fun resolveWithDiagnostics(requirements: Map<TypeDefinitionId, InitializationRequirements>): DefaultModeResolution =
        DefaultModeResolution(resolve(requirements), emptyMap())
}

data class DefaultModeResolution(
    val modes: Map<TypeDefinitionId, InitializationMode>,
    val diagnostics: Map<TypeDefinitionId, List<InitializationDiagnostic>>,
)

class WorklistDefaultModeResolver : DefaultModeResolver {
    override fun resolve(requirements: Map<TypeDefinitionId, InitializationRequirements>): Map<TypeDefinitionId, InitializationMode> =
        resolveWithDiagnostics(requirements).modes

    override fun resolveWithDiagnostics(requirements: Map<TypeDefinitionId, InitializationRequirements>): DefaultModeResolution {
        val dependents = linkedMapOf<TypeDefinitionId, MutableSet<TypeDefinitionId>>()
        requirements.forEach { (owner, requirement) ->
            requirement.embeddedDependencies.forEach { dependency ->
                dependents.getOrPut(dependency) { linkedSetOf() } += owner
            }
        }
        val forced = requirements.filterValues(InitializationRequirements::forcedCreation).keys.toMutableSet()
        val pendingForced = ArrayDeque(forced)
        while (pendingForced.isNotEmpty()) {
            dependents[pendingForced.removeFirst()].orEmpty().filter(forced::add).forEach(pendingForced::addLast)
        }
        val invalid =
            forced.filterTo(linkedSetOf()) { definition ->
                requirements.getValue(definition).preference?.name == InitializationMode.Startup.name
            }
        val pendingInvalid = ArrayDeque(invalid)
        while (pendingInvalid.isNotEmpty()) {
            dependents[pendingInvalid.removeFirst()].orEmpty().filter(invalid::add).forEach(pendingInvalid::addLast)
        }
        val modes =
            requirements.filterKeys { it !in invalid }.mapValuesTo(linkedMapOf()) { (definition, requirement) ->
                val preference = requirement.preference
                when {
                    definition in forced -> InitializationMode.Creation
                    preference != null -> InitializationMode.valueOf(preference.name)
                    else -> InitializationMode.Startup
                }
            }
        val pending =
            ArrayDeque(
                requirements
                    .filter { (definition, requirement) ->
                        definition !in forced && requirement.preference?.name == InitializationMode.Creation.name
                    }.keys,
            )
        while (pending.isNotEmpty()) {
            val dynamic = pending.removeFirst()
            dependents[dynamic].orEmpty().forEach { owner ->
                val requirement = requirements.getValue(owner)
                if (owner !in forced && requirement.preference == null && modes[owner] != InitializationMode.Creation) {
                    modes[owner] = InitializationMode.Creation
                    pending += owner
                }
            }
        }
        val diagnostics =
            invalid.associateWith { definition ->
                listOf(
                    InitializationDiagnostic(
                        field = null,
                        code = "forced_creation_conflicts_with_startup",
                        message = "Forced creation conflicts with an explicit startup preference for $definition.",
                    ),
                )
            }
        return DefaultModeResolution(modes, diagnostics)
    }
}

interface InitializationRuntime {
    suspend fun prepare(request: InitializationRequest): PreparedCreation
}

suspend fun InitializationRequest.prepareWith(runtime: InitializationRuntime): PreparedCreation = runtime.prepare(this)
