package com.typewritermc.authoring

import com.typewritermc.configuration.CapturedDefault
import com.typewritermc.configuration.InitializationPreference
import com.typewritermc.configuration.InitializationRequirements
import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import kotlinx.coroutines.CancellationException

data class InitializationCatalogPlan(
    val descriptors: List<InitializationDescriptor>,
    val diagnostics: Map<TypeDefinitionId, List<InitializationDiagnostic>>,
)

class InitializationCatalogPlanner(
    private val catalog: CheckedCatalog,
    private val bindings: NativeBindingRegistry,
    private val modes: DefaultModeResolver = WorklistDefaultModeResolver(),
) {
    fun plan(
        definitions: List<TypeDefinition>,
        preferences: Map<TypeDefinitionId, InitializationPreference>,
    ): InitializationCatalogPlan {
        val index = definitions.associateBy(TypeDefinition::id)
        val requirements =
            definitions.associate { definition ->
                definition.id to
                    InitializationRequirements(
                        forcedCreation = definition.parameters.isNotEmpty() && definition.hasConstructorDefault(),
                        preference = preferences[definition.id],
                        embeddedDependencies = definition.embeddedDependencies(index),
                    )
            }
        val resolution = modes.resolveWithDiagnostics(requirements)
        val descriptors = mutableListOf<InitializationDescriptor>()
        definitions.captureOrder(requirements).forEach { definition ->
            val mode = resolution.modes[definition.id] ?: return@forEach
            val modeDiagnostics = resolution.diagnostics[definition.id].orEmpty()
            if (mode == InitializationMode.Creation || definition.parameters.isNotEmpty()) {
                descriptors += InitializationDescriptor(definition.id, mode, emptyList(), modeDiagnostics)
                return@forEach
            }
            val descriptor =
                try {
                    val use = TypeUse.Named(definition.id, emptyList())
                    val checked =
                        when (val resolved = catalog.resolve(use)) {
                            is Resolution.Invalid -> return@forEach
                            is Resolution.Ready -> resolved.value
                        }
                    val prepared =
                        DefaultInitializationRuntime(catalog, bindings, descriptors).prepareNow(
                            InitializationRequest(
                                InitializationRequestId("catalog:${definition.id}"),
                                catalog.generation,
                                TypeSelection.Complete(use),
                                emptyMap(),
                                "catalog initialization",
                            ),
                        )
                    val captured =
                        checked.schema.fields.mapNotNull { field ->
                            val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
                            val value = prepared.record.fields[field.key] ?: return@mapNotNull null
                            value.takeUnless { it == DataValue.Unfilled }?.let { CapturedDefault(owner, it) }
                        }
                    InitializationDescriptor(
                        definition.id,
                        mode,
                        captured,
                        modeDiagnostics + prepared.findings,
                    )
                } catch (cancellation: CancellationException) {
                    throw cancellation
                } catch (failure: Exception) {
                    InitializationDescriptor(
                        definition.id,
                        mode,
                        emptyList(),
                        modeDiagnostics +
                            InitializationDiagnostic(
                                null,
                                "startup_default_capture_failed",
                                failure.message
                                    ?: "Startup default capture failed for ${definition.id} with ${failure::class.qualifiedName}.",
                            ),
                    )
                }
            descriptors += descriptor
        }
        return InitializationCatalogPlan(descriptors, resolution.diagnostics)
    }
}

private fun List<TypeDefinition>.captureOrder(requirements: Map<TypeDefinitionId, InitializationRequirements>): List<TypeDefinition> {
    val definitions = associateBy(TypeDefinition::id)
    val ordered = mutableListOf<TypeDefinition>()
    val visited = mutableSetOf<TypeDefinitionId>()
    val visiting = mutableSetOf<TypeDefinitionId>()

    fun visit(definition: TypeDefinition) {
        if (definition.id in visited || !visiting.add(definition.id)) return
        requirements[definition.id]?.embeddedDependencies.orEmpty().forEach { dependency ->
            definitions[dependency]?.let(::visit)
        }
        visiting -= definition.id
        visited += definition.id
        ordered += definition
    }

    forEach(::visit)
    return ordered
}

private fun TypeDefinition.hasConstructorDefault(): Boolean =
    (representation as? RepresentationTemplate.Record)?.fields.orEmpty().any(FieldDeclaration::hasConstructorDefault)

private fun TypeDefinition.embeddedDependencies(index: Map<TypeDefinitionId, TypeDefinition>): Set<TypeDefinitionId> =
    buildSet {
        (representation as? RepresentationTemplate.Record)?.fields.orEmpty().forEach { field ->
            addEmbedded(field.type, index)
        }
    }

private fun MutableSet<TypeDefinitionId>.addEmbedded(
    template: TypeTemplate,
    index: Map<TypeDefinitionId, TypeDefinition>,
) {
    when (template) {
        is TypeTemplate.Nullable -> {
            addEmbedded(template.value, index)
        }

        is TypeTemplate.Parameter, is TypeTemplate.Scalar -> {}

        is TypeTemplate.Named -> {
            when (template.definition) {
                StandardTypes.list, StandardTypes.set, StandardTypes.map -> {
                    template.arguments.forEach { addEmbedded(it, index) }
                }

                else -> {
                    val dependency = index[template.definition] ?: return
                    if (dependency.representation !is RepresentationTemplate.Link) add(template.definition)
                }
            }
        }
    }
}
