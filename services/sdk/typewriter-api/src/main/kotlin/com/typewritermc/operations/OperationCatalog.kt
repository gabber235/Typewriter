package com.typewritermc.operations

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.map
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.matches
import com.typewritermc.types.DataValue
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.PresentationId
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationOrigin
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.catalog.isNominalSubtype
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import kotlin.reflect.KClass

class BoundOperationInput internal constructor(
    val schema: CheckedType?,
    val binding: NativeBinding<*>?,
    val presentation: PresentationId?,
) {
    fun decode(value: DataValue?): Any? {
        if (schema == null) return Unit
        requireNotNull(value) { "Operation input is required." }
        return when (val result = schema.complete(value)) {
            is CompletenessResult.Complete -> requireNotNull(binding).decode(result.value)

            is CompletenessResult.Unfinished -> throw UnavailableAuthoredValue(
                result.locations.map {
                    ValueLocation(ResourceId("operation-input"), it.path)
                },
            )

            is CompletenessResult.Invalid -> throw IllegalArgumentException(result.problems.joinToString())
        }
    }
}

class BoundResourceOperation internal constructor(
    val origin: ProviderOrigin,
    val descriptor: ResourceOperationDefinition,
    val input: BoundOperationInput,
    private val callback: CollectedOperation,
) {
    val builtin: BuiltinResourceOperation? get() = callback.builtin
    val capability: RealmCapabilityDescriptor.Authoring =
        RealmCapabilityDescriptor.Authoring(
            descriptor.id.capability,
            input.schema?.use,
            descriptor.targets,
            input.presentation,
        )

    fun availability(
        targets: List<ResourceId>,
        reads: AuthoredReads,
    ): OperationAvailability = callback.availability(targets, reads)

    suspend fun prepare(
        targets: List<ResourceId>,
        input: DataValue?,
        session: OperationPreparation,
    ) = callback.prepare(targets, this.input.decode(input), session)
}

data class OperationBindingFailure(
    val origin: ProviderOrigin,
    val cause: Throwable,
)

data class OperationCatalog(
    val definitions: List<ResourceOperationDefinition> = emptyList(),
    val contributions: List<ResourceOperationContribution> = emptyList(),
    val authoringProviders: List<BoundResourceOperation> = emptyList(),
    val placements: List<DestinationPlacementDeclaration> = emptyList(),
    val diagnostics: List<DeclarationDiagnostic> = emptyList(),
    val failures: List<OperationBindingFailure> = emptyList(),
) {
    fun requireAuthoring(id: com.typewritermc.capability.CapabilityId): BoundResourceOperation =
        requireNotNull(authoringProviders.singleOrNull { it.capability.id == id }) { "Authoring operation is unavailable: ${id.value}" }
}

/** Binds input tokens only after the catalog's checked types and native bindings exist. */
fun bindOperations(
    declarations: List<OperationDeclaration>,
    catalog: CheckedCatalog,
    bindings: NativeBindingRegistry,
    nativeTypes: List<OwnedTypeDeclaration>,
    presentations: List<OwnedPresentation>,
    existingCapabilities: List<RealmCapabilityDescriptor> = emptyList(),
): OperationCatalog {
    val definitions = linkedMapOf<ResourceOperationId, ResourceOperationDefinition>()
    val contributions = mutableListOf<ResourceOperationContribution>()
    val providers = mutableListOf<BoundResourceOperation>()
    val placements = mutableListOf<DestinationPlacementDeclaration>()
    val diagnostics = mutableListOf<DeclarationDiagnostic>()
    val failures = mutableListOf<OperationBindingFailure>()
    declarations.forEach { declaration ->
        val previousDefinitions = definitions.toMap()
        val previousProviders = providers.size
        val previousPlacements = placements.size
        val previousContributions = contributions.size
        try {
            declaration.failure?.let { throw it }
            require(
                catalog.resolve(declaration.target.asClosedUse()) is Resolution.Ready,
            ) { "Operation target is unavailable: ${declaration.target}." }
            val ids = mutableListOf<ResourceOperationId>()

            fun include(definition: ResourceOperationDefinition) {
                val previous = definitions.putIfAbsent(definition.id, definition)
                require(
                    previous == null || previous == definition,
                ) { "Conflicting operation definition ${definition.id} from ${declaration.origin}." }
                ids += definition.id
            }
            declaration.included.forEach(::include)
            declaration.operations.forEach { collected ->
                val requiredFamily =
                    when (collected.builtin) {
                        BuiltinResourceOperation.MoveToPage -> com.typewritermc.elements.ElementDefinition.id
                        BuiltinResourceOperation.MoveToBook -> com.typewritermc.library.PageDefinition.id
                        else -> null
                    }
                if (requiredFamily != null) {
                    require(
                        declaration.target.definition == requiredFamily ||
                            catalog.isNominalSubtype(declaration.target.definition, requiredFamily),
                    ) {
                        "${collected.builtin} cannot apply to ${declaration.target} from ${declaration.origin}."
                    }
                }
                require(definitions[collected.id] == null || collected.builtin != null) {
                    "Duplicate operation ${collected.id} from ${declaration.origin}."
                }
                val input = collected.input.bind(catalog, bindings, nativeTypes, presentations)
                val action =
                    if (collected.builtin in setOf(BuiltinResourceOperation.Open, BuiltinResourceOperation.Edit)) {
                        skirout.editor.v1.action.EditorAction.createNavigate(
                            resource =
                                SkirTypeCodec
                                    .encode(
                                        ExpressionNode.Read(ExpressionBindingId("context:subject"), ValuePath()),
                                    ).getOrThrow(),
                            mode =
                                if (collected.builtin ==
                                    BuiltinResourceOperation.Open
                                ) {
                                    skirout.editor.v1.action.ResourceNavigationMode.OPEN
                                } else {
                                    skirout.editor.v1.action.ResourceNavigationMode.EDIT
                                },
                        )
                    } else {
                        skirout.editor.v1.action.EditorAction.createAuthoring(
                            capability =
                                skirout.editor.v1.type_catalog
                                    .CapabilityId(value = collected.id.capability.value),
                            targets =
                                SkirTypeCodec
                                    .encode(
                                        ExpressionNode.Read(ExpressionBindingId("context:selection"), ValuePath()),
                                    ).getOrThrow(),
                            initialInput = null,
                        )
                    }
                val definition = ResourceOperationDefinition(collected.id, collected.presentation, collected.targets, action)
                include(definition)
                if (collected.builtin !in setOf(BuiltinResourceOperation.Open, BuiltinResourceOperation.Edit)) {
                    val previous = providers.singleOrNull { it.descriptor.id == definition.id }
                    require(
                        previous == null || previous.builtin == collected.builtin,
                    ) { "Conflicting authoring operation ${definition.id}." }
                    if (previous == null) providers += BoundResourceOperation(declaration.origin, definition, input, collected)
                }
            }
            contributions += ResourceOperationContribution(declaration.target, ids.distinct(), declaration.primary)
            declaration.placements.forEach { placement ->
                val target = placement.target.asClosedUse()
                val checked =
                    (catalog.resolve(target) as? Resolution.Ready)?.value
                        ?: error("Invalid destination placement target $target from ${declaration.origin}.")
                require(
                    placement.collection.path.segments
                        .isNotEmpty(),
                ) { "Destination placement requires an exact collection field." }
                require(
                    placement.collection.owner == checked.use.let { (it as TypeUse.Named).definition } ||
                        catalog.isNominalSubtype((checked.use as TypeUse.Named).definition, placement.collection.owner),
                ) {
                    "Destination collection belongs to another resource type."
                }
                var fieldType = checked
                placement.collection.path.segments.forEach { segment ->
                    val field = segment as? PathSegment.Field ?: error("A placement declaration requires a static collection field path.")
                    val use =
                        fieldType.schema.fields
                            .singleOrNull { it.key == field.name }
                            ?.type
                            ?: error("Destination placement field is not declared: ${field.name}.")
                    fieldType = (catalog.resolve(use) as? Resolution.Ready)?.value
                        ?: error("Destination placement field type is unavailable.")
                }
                val collection =
                    fieldType.schema.representation as? ResolvedRepresentation.Sequence
                        ?: error("Destination placement requires a resource reference collection.")
                val item = (catalog.resolve(collection.item) as? Resolution.Ready)?.value
                require(
                    item?.schema?.representation is ResolvedRepresentation.Link,
                ) { "Destination placement collection must contain references." }
                placements += placement
            }
        } catch (cancelled: java.util.concurrent.CancellationException) {
            throw cancelled
        } catch (failure: Exception) {
            definitions.clear()
            definitions.putAll(previousDefinitions)
            while (providers.size > previousProviders) providers.removeLast()
            while (placements.size > previousPlacements) placements.removeLast()
            while (contributions.size > previousContributions) contributions.removeLast()
            diagnostics +=
                DeclarationDiagnostic(
                    declaration.target.definition,
                    "invalid_resource_operation",
                    listOf(DeclarationOrigin(declaration.origin.owner)),
                )
            failures += OperationBindingFailure(declaration.origin, failure)
        }
    }
    val invalid = linkedSetOf<ResourceOperationId>()
    definitions.values.forEach { definition ->
        try {
            validateResourceActions(listOf(definition), catalog, existingCapabilities + providers.map { it.capability })
        } catch (cancelled: java.util.concurrent.CancellationException) {
            throw cancelled
        } catch (failure: Exception) {
            invalid += definition.id
            declarations
                .filter { declaration ->
                    declaration.operations.any { it.id == definition.id } ||
                        declaration.included.any { it.id == definition.id }
                }.forEach { declaration ->
                    diagnostics +=
                        DeclarationDiagnostic(
                            declaration.target.definition,
                            "invalid_resource_operation_action",
                            listOf(DeclarationOrigin(declaration.origin.owner)),
                        )
                    failures += OperationBindingFailure(declaration.origin, failure)
                }
        }
    }
    return OperationCatalog(
        definitions.values.filterNot { it.id in invalid },
        contributions.map {
            it.copy(
                operations = it.operations.filterNot(invalid::contains),
                primary = it.primary?.takeUnless(invalid::contains),
            )
        },
        providers.filterNot { it.descriptor.id in invalid },
        placements.toList(),
        diagnostics.distinct(),
        failures.toList(),
    )
}

private fun OperationInputDeclaration<*>.bind(
    catalog: CheckedCatalog,
    bindings: NativeBindingRegistry,
    declarations: List<OwnedTypeDeclaration>,
    presentations: List<OwnedPresentation>,
): BoundOperationInput {
    val token = nativeType ?: return BoundOperationInput(null, null, null)
    val native = token.classifier as? KClass<*> ?: error("Operation inputs require a concrete native type.")
    require(applied != null || token.arguments.isEmpty()) { "Generic operation inputs require an AppliedInputToken." }
    val inferred = token.resolveOperationType(declarations)
    require(applied == null || applied == inferred) { "Applied operation input token does not match its native arguments." }
    val type = applied ?: inferred
    val checked = (catalog.resolve(type) as? Resolution.Ready)?.value ?: error("Operation input type is unavailable: $type.")
    val binding = bindings.bind(checked)
    require(binding.nativeClass == null || binding.nativeClass == native) { "Operation input native token does not match its binding." }
    val presentationId =
        presentation?.let { reference ->
            val matches =
                presentations.filter {
                    it.reference === reference &&
                        (it.descriptor.target as? PresentationTarget.Named)?.matches(checked) == true
                }
            require(matches.size == 1) { "Operation input presentation must resolve uniquely for $type." }
            matches.single().descriptor.id
        }
    return BoundOperationInput(checked, binding, presentationId)
}

fun TypeTemplate.Named.asClosedUse(): TypeUse.Named = TypeUse.Named(definition, arguments.map { it.asClosedUse() })

private fun TypeTemplate.asClosedUse(): TypeUse =
    when (this) {
        is TypeTemplate.Named -> asClosedUse()
        is TypeTemplate.Nullable -> TypeUse.Nullable(value.asClosedUse())
        is TypeTemplate.Scalar -> TypeUse.Scalar(kind)
        is TypeTemplate.Parameter -> error("Resource operations require closed type applications.")
    }

private fun validateResourceActions(
    definitions: List<ResourceOperationDefinition>,
    catalog: CheckedCatalog,
    capabilities: List<RealmCapabilityDescriptor>,
) {
    val resource = TypeTemplate.Named(com.typewritermc.types.ResourceIdDefinition.id)
    val selection = TypeTemplate.Named(StandardTypes.list, listOf(resource))
    definitions.forEach { definition ->
        val single = definition.targets is OperationTargets.Single || definition.targets == OperationTargets.ContributedSingle
        val context =
            buildMap {
                put(ExpressionBindingId("context:selection"), selection)
                if (single) put(ExpressionBindingId("context:subject"), resource)
            }

        fun check(
            expression: skirout.editor.v1.expression.ExpressionNode,
            expected: TypeTemplate,
        ) {
            val body =
                com.typewritermc.types.skir.SkirExpressionCodec
                    .decode(expression)
                    .getOrThrow()
            val problems =
                com.typewritermc.presentation.checkPresentationExpression(
                    body,
                    context,
                    expected,
                    context.keys,
                    catalog::resolve,
                )
            require(problems.isEmpty()) { "Invalid action for ${definition.id}: ${problems.joinToString()}" }
        }
        when (val action = definition.action) {
            is skirout.editor.v1.action.EditorAction.NavigateWrapper -> {
                require(single) { "Navigation requires one resource target." }
                check(action.value.resource, resource)
            }

            is skirout.editor.v1.action.EditorAction.AuthoringWrapper -> {
                val capability =
                    capabilities
                        .filterIsInstance<RealmCapabilityDescriptor.Authoring>()
                        .singleOrNull { it.id.value == action.value.capability.value }
                requireNotNull(capability) { "Missing authoring capability for ${definition.id}." }
                check(action.value.targets, selection)
                action.value.initialInput?.let { expression ->
                    val input = requireNotNull(capability.requestType) { "An operation without input cannot provide initial input." }
                    check(expression, input.toOperationTemplate())
                }
            }

            is skirout.editor.v1.action.EditorAction.RealmWrapper -> {
                when (val realm = action.value) {
                    is skirout.editor.v1.action.RealmEditorAction.ReloadWrapper -> {
                        Unit
                    }

                    is skirout.editor.v1.action.RealmEditorAction.CommandWrapper -> {
                        val capability =
                            capabilities
                                .filterIsInstance<RealmCapabilityDescriptor.Command>()
                                .singleOrNull { it.id.value == realm.value.capabilityId.value }
                        requireNotNull(capability) { "Missing command capability for ${definition.id}." }
                        check(realm.value.payload, capability.requestType.toOperationTemplate())
                    }

                    else -> {
                        error("Unrecognized Realm action for ${definition.id}.")
                    }
                }
            }

            else -> {
                error("Resource operations cannot execute local field actions without a field binding.")
            }
        }
    }
}

private fun TypeUse.toOperationTemplate(): TypeTemplate =
    when (this) {
        is TypeUse.Named -> TypeTemplate.Named(definition, arguments.map { it.toOperationTemplate() })
        is TypeUse.Nullable -> TypeTemplate.Nullable(value.toOperationTemplate())
        is TypeUse.Scalar -> TypeTemplate.Scalar(kind)
    }

private fun kotlin.reflect.KType.resolveOperationType(declarations: List<OwnedTypeDeclaration>): TypeUse {
    val native = classifier as? KClass<*> ?: error("Operation input type arguments must be closed.")
    val scalar =
        when (native) {
            Unit::class -> ScalarKind.Unit
            String::class -> ScalarKind.Text
            Boolean::class -> ScalarKind.Boolean
            Byte::class -> ScalarKind.Integer(IntegerWidth.SIGNED_8)
            Short::class -> ScalarKind.Integer(IntegerWidth.SIGNED_16)
            Int::class -> ScalarKind.Integer(IntegerWidth.SIGNED_32)
            Long::class -> ScalarKind.Integer(IntegerWidth.SIGNED_64)
            UByte::class -> ScalarKind.Integer(IntegerWidth.UNSIGNED_8)
            UShort::class -> ScalarKind.Integer(IntegerWidth.UNSIGNED_16)
            UInt::class -> ScalarKind.Integer(IntegerWidth.UNSIGNED_32)
            ULong::class -> ScalarKind.Integer(IntegerWidth.UNSIGNED_64)
            Float::class -> ScalarKind.Float(FloatWidth.FLOAT_32)
            Double::class -> ScalarKind.Float(FloatWidth.FLOAT_64)
            ByteArray::class -> ScalarKind.Bytes
            kotlin.time.Instant::class -> ScalarKind.Timestamp
            kotlin.time.Duration::class -> ScalarKind.Duration
            java.math.BigDecimal::class -> ScalarKind.Decimal
            else -> null
        }
    val use =
        if (scalar != null) {
            TypeUse.Scalar(scalar)
        } else {
            val definition =
                when (native) {
                    List::class -> {
                        StandardTypes.list
                    }

                    Set::class -> {
                        StandardTypes.set
                    }

                    Map::class -> {
                        StandardTypes.map
                    }

                    else -> {
                        declarations
                            .filter { it.nativeClass == native }
                            .map { it.definition.id }
                            .distinct()
                            .singleOrNull()
                            ?: error("No unambiguous native operation input type for $this.")
                    }
                }
            TypeUse.Named(
                definition,
                arguments.map {
                    requireNotNull(it.type) { "Operation input type arguments cannot use stars." }.resolveOperationType(declarations)
                },
            )
        }
    return if (isMarkedNullable) TypeUse.Nullable(use) else use
}
