package com.typewritermc.engine

class EngineLayerResolver(
    descriptors: Collection<EngineLayerDescriptor>,
) {
    private val descriptors = descriptors.associateBy(EngineLayerDescriptor::id)

    fun resolve(engine: EngineDescriptor): EngineLayerResolution {
        val requirements = mutableMapOf<EngineLayerId, VersionRequirement>()
        val resolved = linkedMapOf<EngineLayerId, EngineLayerDescriptor>()
        val visiting = mutableListOf<EngineLayerId>()

        engine.layers.forEach { requirement ->
            val failure = resolve(requirement, requirements, resolved, visiting)
            if (failure != null) return failure
        }

        return EngineLayerResolution.Success(resolved.values.toList())
    }

    private fun resolve(
        requirement: EngineLayerRequirement,
        requirements: MutableMap<EngineLayerId, VersionRequirement>,
        resolved: LinkedHashMap<EngineLayerId, EngineLayerDescriptor>,
        visiting: MutableList<EngineLayerId>,
    ): EngineLayerResolution.Failure? {
        val currentRequirement = requirements[requirement.id]
        val mergedRequirement = currentRequirement?.merge(requirement.version) ?: requirement.version
        if (currentRequirement != null && currentRequirement.minimum.major != requirement.version.minimum.major) {
            return EngineLayerResolution.IncompatibleRequirements(
                requirement.id,
                currentRequirement,
                requirement.version,
            )
        }
        requirements[requirement.id] = mergedRequirement

        val descriptor =
            descriptors[requirement.id]
                ?: return EngineLayerResolution.MissingLayer(requirement.id)
        if (!mergedRequirement.accepts(descriptor.version)) {
            return EngineLayerResolution.UnsupportedVersion(requirement.id, mergedRequirement, descriptor.version)
        }

        val cycleStart = visiting.indexOf(requirement.id)
        if (cycleStart >= 0) {
            return EngineLayerResolution.Cycle((visiting.drop(cycleStart) + requirement.id).toList())
        }
        if (requirement.id in resolved) return null

        visiting += requirement.id
        descriptor.requires.forEach { transitiveRequirement ->
            val failure = resolve(transitiveRequirement, requirements, resolved, visiting)
            if (failure != null) return failure
        }
        visiting.removeLast()
        resolved[descriptor.id] = descriptor
        return null
    }
}

sealed interface EngineLayerResolution {
    data class Success(
        val layers: List<EngineLayerDescriptor>,
    ) : EngineLayerResolution

    sealed interface Failure : EngineLayerResolution

    data class MissingLayer(
        val id: EngineLayerId,
    ) : Failure

    data class UnsupportedVersion(
        val id: EngineLayerId,
        val required: VersionRequirement,
        val available: SemanticVersion,
    ) : Failure

    data class IncompatibleRequirements(
        val id: EngineLayerId,
        val first: VersionRequirement,
        val second: VersionRequirement,
    ) : Failure

    data class Cycle(
        val path: List<EngineLayerId>,
    ) : Failure
}
