package com.typewritermc.discovery

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression

/**
 * Retains a decoded contribution and the artifacts carrying its identical payload.
 */
data class KeyedTypeContribution(
    val key: ContributionKey,
    val carriers: Set<ArtifactId>,
    val contribution: TypeDiscoveryContribution,
) {
    init {
        require(carriers.isNotEmpty()) { "A type contribution requires a physical carrier." }
    }
}

/**
 * Retains the originating contribution alongside a runtime module binding so module providers receive provenance.
 */
data class KeyedExecutableBinding(
    val key: ContributionKey,
    val binding: ExecutableBinding,
)

/** One exact schema meaning with its metadata and physical binding availability. */
data class ResolvedType(
    val definition: TypeDefinition,
    val metadata: TypeMetadata?,
    val carrierEligibility: Map<ArtifactId, Eligibility>,
    val boundDomains: Set<DiscoveryDomainId>,
) {
    fun canCreate(domain: DiscoveryDomainId): Boolean = domain in boundDomains

    fun creationReasons(domain: DiscoveryDomainId): List<String> =
        if (canCreate(domain)) {
            emptyList()
        } else {
            carrierEligibility.values
                .filterIsInstance<Eligibility.Ineligible>()
                .flatMap { it.reasons }
                .distinct()
                .ifEmpty { listOf("No active prototype for ${definition.id} in ${domain.value}.") }
        }
}

/** One validated deployment resolution used for structural, editor, and runtime projections. */
data class ResolvedDeploymentTypes(
    val typesById: Map<ResolvedTypeRef, ResolvedType>,
    val relations: List<RelationDefinition>,
    val prototypeBindings: List<PrototypeBinding>,
    val executableBindings: List<KeyedExecutableBinding>,
    val resourceDefinitions: List<AuthoringResourceDefinition> = emptyList(),
) {
    init {
        require(typesById.all { (id, type) -> id == type.definition.id })
    }

    val catalog: TypeCatalog = TypeCatalog(typesById.values.map(ResolvedType::definition))

    fun requireType(id: ResolvedTypeRef): ResolvedType = requireNotNull(typesById[id]) { "Unknown exact type $id." }

    fun describe(id: ResolvedTypeRef): ResolvedType? = typesById[id]
}

private class TypeClosureValidator(
    private val definitions: Map<ResolvedTypeRef, TypeDefinition>,
    private val root: ResolvedTypeRef,
) {
    private val visited = hashSetOf<ResolvedTypeRef>()

    fun includeReference(reference: ResolvedTypeRef) {
        reference.arguments.forEach(::includeExpression)
        val exact = reference.copy(arguments = emptyList())
        if (!visited.add(exact)) return
        val definition =
            requireNotNull(definitions[exact]) {
                "Type $root depends on missing exact type $exact."
            }
        includeExpression(definition.representation)
        definition.parents.forEach(::includeReference)
        definition.parameters.flatMap { it.upperBounds }.forEach(::includeExpression)
    }

    private fun includeExpression(expression: TypeExpression) {
        when (expression) {
            is TypeExpression.Named -> {
                includeReference(expression.reference)
            }

            is TypeExpression.Reference -> {
                includeReference(expression.target)
            }

            is TypeExpression.Enumeration -> {
                includeExpression(expression.valueType)
            }

            is TypeExpression.ListType -> {
                includeExpression(expression.element)
            }

            is TypeExpression.MapType -> {
                includeExpression(expression.key)
                includeExpression(expression.value)
            }

            is TypeExpression.Record -> {
                expression.fields.forEach { includeExpression(it.type) }
            }

            else -> {
                Unit
            }
        }
    }
}

/**
 * Resolves generated type contributions in stable logical source order.
 *
 * Identical definitions and bindings may be shared; conflicting identities and duplicate contribution keys are
 * rejected. Ineligible source parts still contribute structural definitions but not executable or prototype
 * bindings. A missing eligibility entry does not exclude a binding.
 */
object TypeContributionAssembler {
    /**
     * Merges contributions into the structural catalog and domain specific executable bindings.
     *
     * Contributions are sorted by provenance before conflicts are checked. A source part marked ineligible loses
     * executable and prototype bindings, but its definitions remain available for diagnostics and catalog display.
     */
    fun assemble(
        contributions: Collection<KeyedTypeContribution>,
        sourceParts: Collection<SourcePartCatalogEntry> = emptyList(),
    ): ResolvedDeploymentTypes {
        val ordered = contributions.sortedBy { it.key.sortKey() }
        require(ordered.map(KeyedTypeContribution::key).distinct().size == ordered.size) {
            "Discovery contribution keys must be unique."
        }

        val definitions = linkedMapOf<ResolvedTypeRef, TypeDefinition>()
        StandardTypes.definitions.forEach { definition -> definitions[definition.id] = definition }
        val carriers = linkedMapOf<ResolvedTypeRef, MutableMap<ArtifactId, Eligibility>>()
        val metadata = linkedMapOf<ResolvedTypeRef, TypeMetadata>()
        val prototypeBindings = linkedMapOf<ResolvedTypeRef, PrototypeBinding>()
        val relations = linkedMapOf<RelationId, RelationDefinition>()
        val resourceDefinitions = linkedMapOf<ResourceDefinitionId, AuthoringResourceDefinition>()
        val executableBindings = linkedMapOf<Pair<DiscoveryDomainId, String>, KeyedExecutableBinding>()
        val extensionEligibility = sourceParts.associateBy { it.artifact to it.sourcePart }
        ordered.forEach { keyed ->
            val localDefinitions =
                (StandardTypes.definitions + keyed.contribution.definitions).associateBy(TypeDefinition::id)
            keyed.contribution.definitions.forEach { definition ->
                TypeClosureValidator(localDefinitions, definition.id).includeReference(definition.id)
            }
            keyed.contribution.resourceDefinitions.forEach { resource ->
                val root = (resource.acceptedRoot as? TypeExpression.Named)?.reference
                requireNotNull(root) { "Resource ${resource.id.value} requires a named root type." }
                TypeClosureValidator(localDefinitions, root).includeReference(root)
            }
            val eligibilityByCarrier =
                keyed.carriers.associateWith { carrier ->
                    extensionEligibility[carrier to keyed.key.sourcePart]?.eligibility ?: Eligibility.Eligible
                }
            keyed.contribution.definitions.forEach { definition ->
                carriers.getOrPut(definition.id) { linkedMapOf() }.putAll(eligibilityByCarrier)
            }
            keyed.contribution.definitions.forEach { definition ->
                val previous = definitions[definition.id]
                require(
                    previous == null ||
                        previous.copy(displayName = definition.displayName, qualifiedName = definition.qualifiedName) == definition,
                ) {
                    "Conflicting type definition ${definition.id} from ${keyed.key}."
                }
                val defaultName = TypeDefinition(id = definition.id, kind = definition.kind).displayName
                require(
                    previous == null || previous.displayName == definition.displayName ||
                        previous.displayName == defaultName || definition.displayName == defaultName,
                ) {
                    "Conflicting type display name ${definition.id} from ${keyed.key}."
                }
                require(
                    previous == null || previous.qualifiedName == null || definition.qualifiedName == null ||
                        previous.qualifiedName == definition.qualifiedName,
                ) {
                    "Conflicting qualified type name ${definition.id} from ${keyed.key}."
                }
                definitions[definition.id] =
                    when {
                        previous == null -> {
                            definition
                        }

                        else -> {
                            previous.copy(
                                displayName = if (previous.displayName == defaultName) definition.displayName else previous.displayName,
                                qualifiedName = previous.qualifiedName ?: definition.qualifiedName,
                            )
                        }
                    }
            }
            keyed.contribution.relations.forEach { definition ->
                val previous = relations[definition.id]
                relations[definition.id] = previous?.merge(definition) ?: definition
            }
            keyed.contribution.resourceDefinitions.forEach { definition ->
                val previous = resourceDefinitions.putIfAbsent(definition.id, definition)
                require(previous == null || previous == definition) {
                    "Conflicting resource definition ${definition.id.value} from ${keyed.key}."
                }
            }
            keyed.contribution.metadata.forEach { declaration ->
                val previous = metadata.putIfAbsent(declaration.type, declaration)
                require(previous == null || previous == declaration) {
                    "Conflicting type metadata ${declaration.type} from ${keyed.key}."
                }
            }
            if (eligibilityByCarrier.values.none { it is Eligibility.Eligible }) return@forEach
            keyed.contribution.prototypeBindings.forEach { binding ->
                val previous = prototypeBindings.putIfAbsent(binding.type, binding)
                require(previous == null || previous == binding) {
                    "Conflicting prototype binding ${binding.type} from ${keyed.key}."
                }
            }
            keyed.contribution.executableBindings.forEach { binding ->
                val identity = binding.domain to binding.localName
                val candidate = KeyedExecutableBinding(keyed.key, binding)
                val previous = executableBindings.putIfAbsent(identity, candidate)
                require(previous == null || previous.binding == binding) {
                    "Conflicting executable binding $identity from ${previous?.key} and ${keyed.key}."
                }
            }
        }

        val catalog = TypeCatalog(definitions.values.sortedBy { it.id.toString() })
        definitions.forEach { (type, definition) ->
            TypeClosureValidator(definitions, type).includeReference(type)
            definition.validateAcyclicParents(definitions)
        }
        resourceDefinitions.values.forEach { resource ->
            val root = (resource.acceptedRoot as? TypeExpression.Named)?.reference
            requireNotNull(root) { "Resource ${resource.id.value} requires a named root type." }
            TypeClosureValidator(definitions, root).includeReference(root)
        }
        relations.values.forEach { relation ->
            TypeClosureValidator(definitions, relation.source).includeReference(relation.source)
            TypeClosureValidator(definitions, relation.target).includeReference(relation.target)
        }
        val concreteTypes = catalog.definitions.filter { it.kind == NominalTypeKind.CONCRETE }.mapTo(mutableSetOf()) { it.id }
        val violations =
            catalog.fieldContractViolations(
                prototypeBindings.values.map { it.type }.filterTo(mutableSetOf()) { it in concreteTypes },
            )
        require(violations.isEmpty()) { violations.joinToString("; ") }
        val resolved =
            definitions.values.sortedBy { it.id.toString() }.associate { definition ->
                definition.id to
                    ResolvedType(
                        definition = definition,
                        metadata = metadata[definition.id],
                        carrierEligibility = carriers[definition.id]?.toMap() ?: emptyMap(),
                        boundDomains = prototypeBindings[definition.id]?.domains ?: emptySet(),
                    )
            }
        return ResolvedDeploymentTypes(
            typesById = resolved,
            relations = relations.values.sortedBy { it.id.value },
            resourceDefinitions = resourceDefinitions.values.sortedBy { it.id.value },
            prototypeBindings = prototypeBindings.values.sortedBy { it.type.toString() },
            executableBindings =
                executableBindings.values.sortedWith(
                    compareBy({ it.binding.domain.value }, { it.binding.localName }, { it.key.sortKey() }),
                ),
        )
    }
}

private fun TypeDefinition.validateAcyclicParents(definitions: Map<ResolvedTypeRef, TypeDefinition>) {
    fun visit(
        type: ResolvedTypeRef,
        path: Set<ResolvedTypeRef>,
    ) {
        val exact = type.copy(arguments = emptyList())
        require(exact !in path) { "Cyclic type inheritance at $exact." }
        definitions.getValue(exact).parents.forEach { visit(it, path + exact) }
    }
    parents.forEach { visit(it, setOf(id)) }
}

private fun RelationDefinition.merge(other: RelationDefinition): RelationDefinition {
    require(source == other.source && target == other.target) { "Conflicting relation endpoints for $id." }
    require(families == other.families) { "Conflicting relation families for $id." }
    require(onSourceDelete == other.onSourceDelete && onTargetDelete == other.onTargetDelete) {
        "Conflicting relation deletion policy for $id."
    }
    require(sourceEndpoint == null || other.sourceEndpoint == null || sourceEndpoint == other.sourceEndpoint) {
        "Conflicting source endpoint for $id."
    }
    require(targetEndpoint == null || other.targetEndpoint == null || targetEndpoint == other.targetEndpoint) {
        "Conflicting target endpoint for $id."
    }
    return copy(
        sourceEndpoint = sourceEndpoint ?: other.sourceEndpoint,
        targetEndpoint = targetEndpoint ?: other.targetEndpoint,
    )
}

private fun ContributionKey.sortKey(): String = "${source.value}/$sourcePart/${producer.value}/${name.value}"
