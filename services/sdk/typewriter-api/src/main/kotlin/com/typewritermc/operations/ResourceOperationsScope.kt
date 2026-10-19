package com.typewritermc.operations

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.ReadProjection
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.TypedPath
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.map
import com.typewritermc.authoring.read
import com.typewritermc.authoring.replace
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.presentation.ButtonVariant
import com.typewritermc.presentation.PresentationReference
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import kotlinx.coroutines.CancellationException
import kotlin.reflect.KType
import kotlin.reflect.typeOf

class AppliedInputToken<I>
    @PublishedApi
    internal constructor(
        val type: TypeUse,
        val nativeType: KType,
    )

inline fun <reified I> appliedInputToken(type: TypeUse): AppliedInputToken<I> = AppliedInputToken(type, typeOf<I>())

/** Captures metadata only. Catalog assembly owns native binding resolution. */
class OperationInputDeclaration<I>
    @PublishedApi
    internal constructor(
        val nativeType: KType?,
        val applied: TypeUse? = null,
        val presentation: PresentationReference? = null,
    )

/**
 * Declares the complete native input type and optional portable form for an operation.
 * Catalog assembly checks the form against [I]. Omit input with [noInput], rather than a placeholder value.
 * For an applied generic type, use [appliedInputToken] so both the checked type and native arguments are explicit.
 */
inline fun <reified I> operationInput(using: PresentationReference? = null): OperationInputDeclaration<I> =
    OperationInputDeclaration(typeOf<I>(), presentation = using)

fun <I> operationInput(
    type: AppliedInputToken<I>,
    using: PresentationReference? = null,
): OperationInputDeclaration<I> = OperationInputDeclaration(type.nativeType, type.type, using)

fun noInput(): OperationInputDeclaration<Unit> = OperationInputDeclaration(null)

data class OperationHandle(
    val id: ResourceOperationId,
)

/**
 * Collects one generated resource operations declaration at catalog assembly.
 * Contributions are additive across resource supertypes. Stable operation IDs deduplicate shared declarations;
 * this scope does not replace operations contributed by another provider. Generated providers retain the callbacks.
 */
interface ResourceOperationsScope<D : ResourceDraft> {
    fun <I> operation(
        id: String,
        input: OperationInputDeclaration<I>,
        body: ResourceOperationBuilder<D, I>.() -> Unit,
    ): OperationHandle

    fun include(definition: ResourceOperationDefinition): OperationHandle

    fun builtin(operation: BuiltinResourceOperation): OperationHandle

    fun primary(operation: OperationHandle)

    fun placementFor(
        collection: TypedPath<*, *>,
        policy: DestinationPlacementPolicy,
    )
}

interface ResourceOperationBuilder<D : ResourceDraft, I> {
    fun label(value: String)

    fun description(value: String)

    fun icon(value: String)

    fun group(value: OperationGroup)

    fun order(value: Int)

    fun single()

    fun confirmation(value: OperationConfirmation)

    fun tone(value: ActionTone)

    /** Sets inspector button emphasis without changing context menu appearance. */
    fun variant(value: ButtonVariant)

    /** Controls inspector visibility without removing the operation from menus or shortcuts. */
    fun showInInspector(value: Boolean)

    /**
     * Evaluates against the invocation's captured working graph. Keep this callback stateless and free of effects.
     * It can run again for a later invocation. Generated draft setters require the edit context absent here.
     */
    fun availability(body: OperationReadScope<D>.() -> OperationAvailability)

    /**
     * Builds tentative edits against the captured working graph without committing or performing external effects.
     * A retry after form input or a choice starts a fresh attempt. Use [OperationPreparation.identities] for new IDs.
     * The caller validates the complete batch, then stages the exact preview through its ordinary edit owner.
     */
    fun prepare(body: suspend OperationPrepareScope<D, I>.() -> Unit)
}

class OperationReadScope<D : ResourceDraft>(
    val subjects: List<D>,
    reads: AuthoredReads,
) : AuthoredReads by reads

class OperationPrepareScope<D : ResourceDraft, I>(
    val subjects: List<D>,
    val input: I,
    preparation: OperationPreparation,
) : OperationPreparation by preparation

class UnavailableAuthoredValue(
    val locations: List<ValueLocation>,
) : IllegalStateException("Required authored values are missing")

/** The operation input value is not yet complete at [paths], relative to the input root. */
class UnfinishedOperationInput(
    val paths: List<ValuePath>,
) : IllegalStateException("Operation input is unfinished")

class FailedAuthoredValue(
    val diagnostic: com.typewritermc.expression.EvaluationDiagnostic,
) : IllegalStateException(diagnostic.toString())

fun authored(values: Iterable<Availability<*>>): OperationAvailability {
    val missing = mutableListOf<ValueLocation>()
    values.forEach { value ->
        when (value) {
            is Availability.Available -> Unit
            is Availability.Unavailable -> missing += value.locations
            is Availability.Failed -> throw FailedAuthoredValue(value.diagnostic)
        }
    }
    return if (missing.isEmpty()) {
        OperationAvailability.Enabled
    } else {
        OperationAvailability.Disabled(
            "Required authored values are missing: ${missing.joinToString()}",
        )
    }
}

fun <T> requireAuthored(value: Availability<T>): T =
    when (value) {
        is Availability.Available -> value.value
        is Availability.Unavailable -> throw UnavailableAuthoredValue(value.locations)
        is Availability.Failed -> throw FailedAuthoredValue(value.diagnostic)
    }

data class DestinationPlacementRequest(
    val destination: ResourceId,
    val collection: ValueLocation,
    val subjects: List<ResourceDraft>,
    val anchor: PlacementAnchor?,
    val occupants: List<ResourceDraft>,
)

fun interface DestinationPlacementPolicy {
    context(reads: AuthoredReads)
    fun prepare(request: DestinationPlacementRequest): PlacementPreparation
}

data class DestinationPlacementDeclaration(
    val origin: ProviderOrigin,
    val target: TypeTemplate.Named,
    val collection: TypedPath<*, *>,
    val policy: DestinationPlacementPolicy,
)

class OperationDeclaration internal constructor(
    val origin: ProviderOrigin,
    val declaration: String,
    val target: TypeTemplate.Named,
    val operations: List<CollectedOperation>,
    val included: List<ResourceOperationDefinition>,
    val primary: ResourceOperationId?,
    val placements: List<DestinationPlacementDeclaration>,
    val failure: Throwable? = null,
)

/** The erased boundary always binds subjects through the declaration's checked projection. */
interface CollectedOperation {
    val id: ResourceOperationId
    val targets: OperationTargets
    val presentation: OperationPresentation
    val input: OperationInputDeclaration<*>
    val builtin: BuiltinResourceOperation? get() = null

    fun availability(
        targets: List<ResourceId>,
        reads: AuthoredReads,
    ): OperationAvailability

    suspend fun prepare(
        targets: List<ResourceId>,
        input: Any?,
        session: OperationPreparation,
    )
}

class ResourceOperationsBuildScope<D : ResourceDraft> internal constructor(
    private val origin: ProviderOrigin,
    private val declaration: String,
    private val target: TypeTemplate.Named,
    private val projection: ReadProjection<D>,
) : ResourceOperationsScope<D> {
    internal val collected = mutableListOf<CollectedOperation>()
    internal val included = mutableListOf<ResourceOperationDefinition>()
    internal val placements = mutableListOf<DestinationPlacementDeclaration>()
    internal var primary: ResourceOperationId? = null

    override fun <I> operation(
        id: String,
        input: OperationInputDeclaration<I>,
        body: ResourceOperationBuilder<D, I>.() -> Unit,
    ): OperationHandle {
        require(id.matches(Regex("[A-Za-z0-9][A-Za-z0-9_.]*"))) { "Operation local IDs must be nonempty safe identifiers." }
        val identity = ResourceOperationId(origin.artifact.value, origin.sourcePart, declaration, id)
        require(collected.none { it.id == identity }) { "Duplicate operation local ID $id in $declaration." }
        val builder = OperationBuilder<D, I>()
        builder.body()
        val callback = requireNotNull(builder.preparation) { "Operation $id requires one preparation body." }
        val available = builder.available
        val definitionTargets = if (builder.single) OperationTargets.Single(target) else OperationTargets.Selection(target)
        collected +=
            object : CollectedOperation {
                override val id = identity
                override val targets = definitionTargets
                override val presentation = builder.presentation()
                override val input = input

                private fun bind(
                    ids: List<ResourceId>,
                    reads: AuthoredReads,
                ): List<D> =
                    with(reads) {
                        ids.map { requireAuthored(projection.read(ValueLocation(it, ValuePath()))) }
                    }

                override fun availability(
                    targets: List<ResourceId>,
                    reads: AuthoredReads,
                ): OperationAvailability = available.invoke(OperationReadScope(bind(targets, reads), reads))

                @Suppress("UNCHECKED_CAST")
                override suspend fun prepare(
                    targets: List<ResourceId>,
                    input: Any?,
                    session: OperationPreparation,
                ) {
                    callback.invoke(OperationPrepareScope(bind(targets, session), input as I, session))
                }
            }
        return OperationHandle(identity)
    }

    override fun builtin(operation: BuiltinResourceOperation): OperationHandle {
        require(collected.none { it.id == operation.id }) { "A built in operation can be included only once per contribution." }
        collected +=
            object : CollectedOperation {
                override val builtin = operation
                override val id = operation.id
                override val targets =
                    when (operation) {
                        BuiltinResourceOperation.Open,
                        BuiltinResourceOperation.Edit,
                        BuiltinResourceOperation.LinkWithDuplicate,
                        -> OperationTargets.ContributedSingle

                        else -> OperationTargets.ContributedSelection
                    }
                override val input: OperationInputDeclaration<*> =
                    when (operation) {
                        BuiltinResourceOperation.MoveToPage -> operationInput<MoveToPageInput>(using = MoveToPageForm)
                        BuiltinResourceOperation.MoveToBook -> operationInput<MoveToBookInput>(using = MoveToBookForm)
                        BuiltinResourceOperation.LinkWith -> operationInput<LinkWithInput>(using = LinkWithForm)
                        else -> noInput()
                    }
                override val presentation =
                    OperationPresentation(
                        operation.label,
                        icon = operation.icon,
                        variant = operation.variant,
                        showInInspector = operation.showInInspector,
                        group =
                            when (operation) {
                                BuiltinResourceOperation.Open -> OperationGroup.Navigation
                                BuiltinResourceOperation.Delete -> OperationGroup.Destructive
                                BuiltinResourceOperation.Edit -> OperationGroup.Edit
                                else -> OperationGroup.Organize
                            },
                        order = operation.ordinal,
                        tone = if (operation == BuiltinResourceOperation.Delete) ActionTone.Destructive else ActionTone.Neutral,
                        confirmation =
                            if (operation ==
                                BuiltinResourceOperation.Delete
                            ) {
                                OperationConfirmation(
                                    "Delete resources",
                                    "Delete the selected resources and their owned contents?",
                                    "Delete",
                                )
                            } else {
                                null
                            },
                    )

                override fun availability(
                    targets: List<ResourceId>,
                    reads: AuthoredReads,
                ) = OperationAvailability.Enabled

                override suspend fun prepare(
                    targets: List<ResourceId>,
                    input: Any?,
                    session: OperationPreparation,
                ) {
                    with(session) {
                        operation.prepare(targets, input)
                    }
                }
            }
        return OperationHandle(operation.id)
    }

    override fun include(definition: ResourceOperationDefinition): OperationHandle {
        included += definition
        return OperationHandle(definition.id)
    }

    override fun primary(operation: OperationHandle) {
        require(primary == null || primary == operation.id) { "A contribution can nominate only one primary operation." }
        primary = operation.id
    }

    override fun placementFor(
        collection: TypedPath<*, *>,
        policy: DestinationPlacementPolicy,
    ) {
        placements += DestinationPlacementDeclaration(origin, target, collection, policy)
    }
}

private class OperationBuilder<D : ResourceDraft, I> : ResourceOperationBuilder<D, I> {
    private var label = ""
    private var description = ""
    private var icon: String? = null
    private var group = OperationGroup.Edit
    private var order = 0
    private var confirmation: OperationConfirmation? = null
    private var tone = ActionTone.Neutral
    private var variant = ButtonVariant.Outlined
    private var showInInspector = true
    var single = false
    var available: OperationReadScope<D>.() -> OperationAvailability = { OperationAvailability.Enabled }
    var preparation: (suspend OperationPrepareScope<D, I>.() -> Unit)? = null

    override fun label(value: String) {
        require(value.isNotBlank())
        label = value
    }

    override fun description(value: String) {
        description = value
    }

    override fun icon(value: String) {
        icon = value
    }

    override fun group(value: OperationGroup) {
        group = value
    }

    override fun order(value: Int) {
        order = value
    }

    override fun single() {
        single = true
    }

    override fun confirmation(value: OperationConfirmation) {
        confirmation = value
    }

    override fun tone(value: ActionTone) {
        tone = value
    }

    override fun variant(value: ButtonVariant) {
        variant = value
    }

    override fun showInInspector(value: Boolean) {
        showInInspector = value
    }

    override fun availability(body: OperationReadScope<D>.() -> OperationAvailability) {
        available = body
    }

    override fun prepare(body: suspend OperationPrepareScope<D, I>.() -> Unit) {
        require(preparation == null) { "An operation must have exactly one preparation body." }
        preparation = body
    }

    fun presentation(): OperationPresentation {
        require(label.isNotBlank()) { "An operation requires a label." }
        return OperationPresentation(label, description, icon, group, order, confirmation, tone, variant, showInInspector)
    }
}

fun <D : ResourceDraft> collectOperations(
    origin: ProviderOrigin,
    declaration: String,
    target: TypeTemplate.Named,
    projection: ReadProjection<D>,
    body: (ResourceOperationsBuildScope<D>) -> Unit,
): OperationDeclaration {
    val scope = ResourceOperationsBuildScope(origin, declaration, target, projection)
    return try {
        body(scope)
        require(scope.primary == null || scope.collected.any { it.id == scope.primary } || scope.included.any { it.id == scope.primary }) {
            "A primary operation must belong to its contribution."
        }
        OperationDeclaration(
            origin,
            declaration,
            target,
            scope.collected.toList(),
            scope.included.toList(),
            scope.primary,
            scope.placements.toList(),
        )
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (failure: Exception) {
        OperationDeclaration(origin, declaration, target, emptyList(), emptyList(), null, emptyList(), failure)
    }
}
