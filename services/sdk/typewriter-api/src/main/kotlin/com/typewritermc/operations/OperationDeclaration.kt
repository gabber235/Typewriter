@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.operations

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.ReadProjection
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.TypedPath
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.presentation.PresentationReference
import com.typewritermc.types.ResourceId
import com.typewritermc.types.requireValid
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.operation.OperationAvailability
import skirout.editor.v1.operation.OperationCardinality
import skirout.editor.v1.operation.OperationConfirmation
import skirout.editor.v1.operation.OperationGroup
import skirout.editor.v1.operation.OperationInspector
import skirout.editor.v1.operation.OperationPresentation
import skirout.editor.v1.operation.OperationShortcut
import skirout.editor.v1.operation.ResourceOperationId
import skirout.editor.v1.presentation.ButtonVariant
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

/** The input an operation receives, computed by codegen from its input type argument. */
sealed interface OperationInput {
    /** The operation takes [Unit]. */
    data object None : OperationInput

    /** The operation takes a value of [use], a closed application of a `@TypewriterType`. */
    data class Typed(
        val use: NamedTypeUse,
    ) : OperationInput
}

/** Binds invocation subjects as the drafts an operation reads. */
@GeneratedSdkApi
fun interface OperationSubjects<D : ResourceDraft> {
    fun bind(
        id: ResourceId,
        reads: OperationReads,
    ): D
}

/** Subjects of an operation on every resource, bound as untyped resource drafts. */
@GeneratedSdkApi
object AnyResourceSubjects : OperationSubjects<ResourceDraft> {
    override fun bind(
        id: ResourceId,
        reads: OperationReads,
    ): ResourceDraft = reads.resourceDraft(id)
}

/** Subjects of an operation on one resource type, bound through that type's draft projection. */
@GeneratedSdkApi
fun <D : ResourceDraft> projectedSubjects(projection: ReadProjection<D>): OperationSubjects<D> =
    OperationSubjects { id, reads -> with(reads) { requireAuthored(projection.read(ValueLocation.of(id))) } }

/**
 * One declared input field: the values pickers offer, the check for one value, and whether drops fill it.
 * Values are erased at this boundary; a drop field always holds resource identities.
 */
class OperationInputField internal constructor(
    /** The field, relative to the input root. */
    val path: ValuePath,
    /** The type that declares [path]: the input type or one of its supertypes. */
    val owner: TypeDefinitionId,
    /** The hover hint when drops fill this field, or null when they do not. */
    val drop: String?,
    private val candidates: ((List<ResourceId>, OperationReads) -> Sequence<Any?>)?,
    private val accepts: ((List<ResourceId>, OperationReads, Any?) -> Boolean)?,
) {
    val hasCandidates: Boolean get() = candidates != null

    /** The declared candidates for [subjects]; empty when the field declares none. */
    fun candidates(
        subjects: List<ResourceId>,
        reads: OperationReads,
    ): Sequence<Any?> = candidates?.invoke(subjects, reads).orEmpty()

    /** The declared candidates for [subjects] that also pass the declared check, if the field declares one. */
    fun acceptedCandidates(
        subjects: List<ResourceId>,
        reads: OperationReads,
    ): Sequence<Any?> {
        val check = accepts ?: return candidates(subjects, reads)
        return candidates(subjects, reads).filter { check(subjects, reads, it) }
    }

    /** Whether [value] is acceptable for [subjects], by the declared check or by membership in the candidates. */
    fun accepts(
        subjects: List<ResourceId>,
        reads: OperationReads,
        value: Any?,
    ): Boolean = accepts?.invoke(subjects, reads, value) ?: (value in candidates(subjects, reads))
}

/** What one declaration produced, before catalog assembly binds its input and publishes it. */
class CollectedOperation internal constructor(
    val presentation: OperationPresentation,
    val cardinality: OperationCardinality,
    val form: PresentationReference?,
    val fields: List<OperationInputField>,
    private val available: (List<ResourceId>, OperationReads) -> OperationAvailability,
    private val preparation: suspend (List<ResourceId>, Any?, OperationPreparation) -> Unit,
) {
    fun availability(
        subjects: List<ResourceId>,
        reads: OperationReads,
    ): OperationAvailability = available(subjects, reads)

    suspend fun prepare(
        subjects: List<ResourceId>,
        input: Any?,
        session: OperationPreparation,
    ) = preparation(subjects, input, session)
}

/** One operation object as discovered. A declaration that failed to collect keeps its [failure] for diagnostics. */
class OperationDeclaration internal constructor(
    val origin: ProviderOrigin,
    val id: ResourceOperationId,
    val target: ResourceTarget,
    val input: OperationInput,
    val collected: CollectedOperation?,
    val failure: Throwable?,
)

/**
 * Runs the declaration of one operation object. Generated providers call it with the object's identity, its target and
 * input computed at compile time, and the label derived from its name. A declaration that throws is retained as a
 * failure, which catalog assembly reports without publishing the operation.
 */
@GeneratedSdkApi
fun <D : ResourceDraft, I> collectOperation(
    origin: ProviderOrigin,
    declaration: String,
    target: ResourceTarget,
    subjects: OperationSubjects<D>,
    input: OperationInput,
    defaultLabel: String,
    declare: (OperationSpec<D, I>) -> PreparedOperation,
): OperationDeclaration {
    val id = ResourceOperationId(artifact = origin.artifact.value, sourcePart = origin.sourcePart, declaration = declaration).requireValid()
    return try {
        val spec = OperationSpecBuilder<D, I>(defaultLabel, subjects)
        declare(spec)
        OperationDeclaration(origin, id, target, input, spec.collect(), null)
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (failure: Exception) {
        OperationDeclaration(origin, id, target, input, null, failure)
    }
}

private class OperationSpecBuilder<D : ResourceDraft, I>(
    defaultLabel: String,
    private val subjects: OperationSubjects<D>,
) : OperationSpec<D, I>,
    OperationAppearanceScope,
    OperationInputScope<D, I>,
    OperationGestureScope {
    private var label = defaultLabel
    private var description = ""
    private var icon: String? = null
    private var group: OperationGroup = OperationGroup.EDIT
    private var order = 0
    private var inspector: OperationInspector = OperationInspector.ButtonWrapper(ButtonVariant.OUTLINED)
    private var shortcut: OperationShortcut? = null
    private var confirmation: ConfirmBuilder? = null
    private var cardinality: OperationCardinality = OperationCardinality.SELECTION
    private var form: PresentationReference? = null
    private val fields = mutableListOf<OperationFieldBuilder<D, *>>()
    private var available: OperationReadScope<D>.() -> OperationAvailability = { OperationAvailability.ENABLED }
    private var preparation: (suspend OperationPrepareScope<D, I>.() -> Unit)? = null

    override fun appearance(body: OperationAppearanceScope.() -> Unit) = body()

    override fun confirm(
        message: String,
        body: OperationConfirmScope.() -> Unit,
    ) {
        require(confirmation == null) { "An operation declares at most one confirmation." }
        confirmation = ConfirmBuilder(message).apply(body)
    }

    override fun input(body: OperationInputScope<D, I>.() -> Unit) = body()

    override fun gestures(body: OperationGestureScope.() -> Unit) = body()

    override fun singleSubject() {
        cardinality = OperationCardinality.SINGLE
    }

    override fun availableWhen(body: OperationReadScope<D>.() -> OperationAvailability) {
        available = body
    }

    override fun prepare(body: suspend OperationPrepareScope<D, I>.() -> Unit): PreparedOperation {
        require(preparation == null) { "An operation declares exactly one preparation." }
        preparation = body
        return PreparedOperation()
    }

    override fun label(value: String) {
        require(value.isNotBlank()) { "An operation label cannot be blank." }
        label = value
    }

    override fun description(value: String) {
        description = value
    }

    override fun icon(value: String) {
        require(value.isNotBlank()) { "An operation icon cannot be blank." }
        icon = value
    }

    override fun group(
        value: OperationGroup,
        order: Int,
    ) {
        group = value
        this.order = order
    }

    override fun inspector(value: OperationInspector) {
        inspector = value
    }

    override fun form(presentation: PresentationReference) {
        form = presentation
    }

    override fun <V> TypedPath<in I, V>.invoke(body: OperationFieldScope<D, V>.() -> Unit) {
        require(fields.none { it.path == path }) { "The input field $path is declared twice." }
        fields += OperationFieldBuilder<D, V>(this).apply(body)
    }

    override fun shortcut(value: OperationShortcut) {
        shortcut = value
    }

    private fun bind(
        ids: List<ResourceId>,
        reads: OperationReads,
    ): () -> List<D> = { ids.map { subjects.bind(it, reads) } }

    private fun readScope(
        ids: List<ResourceId>,
        reads: OperationReads,
    ) = OperationReadScope(ids, bind(ids, reads), reads)

    fun collect(): CollectedOperation {
        val prepare = requireNotNull(preparation) { "An operation declares exactly one preparation." }
        val available = available
        val drops = fields.filter { it.drop != null }
        require(drops.size <= 1) { "An operation fills at most one input field on drop." }
        drops.forEach { field -> require(field.candidates != null) { "The drop field ${field.path} must declare candidates." } }
        return CollectedOperation(
            presentation =
                OperationPresentation(
                    label = label,
                    description = description,
                    icon = icon.orEmpty(),
                    group = group,
                    order = order,
                    tone = group.tone,
                    confirmation = confirmation?.build(label),
                    inspector = inspector,
                    shortcut = shortcut,
                ).requireValid(),
            cardinality = cardinality,
            form = form,
            fields = fields.map { it.erase(label, ::readScope) },
            available = { ids, reads -> readScope(ids, reads).available().requireValid() },
            preparation = { ids, input, session ->
                @Suppress("UNCHECKED_CAST")
                OperationPrepareScope(ids, bind(ids, session), input as I, session).prepare()
            },
        )
    }
}

internal class OperationFieldBuilder<D : ResourceDraft, V>(
    private val typed: TypedPath<*, V>,
) : OperationFieldScope<D, V> {
    val path: ValuePath get() = typed.path
    var candidates: (OperationReadScope<D>.() -> Sequence<V>)? = null
        private set
    private var accepts: (OperationReadScope<D>.(V) -> Boolean)? = null

    /** Null when drops do not fill this field; blank until the operation label replaces it. */
    var drop: String? = null
        private set

    override fun candidates(body: OperationReadScope<D>.() -> Sequence<V>) {
        candidates = body
    }

    override fun accepts(body: OperationReadScope<D>.(value: V) -> Boolean) {
        accepts = body
    }

    fun fillOnDrop(hint: String?) {
        require(hint == null || hint.isNotBlank()) { "A drop hint cannot be blank." }
        drop = hint.orEmpty()
    }

    fun erase(
        label: String,
        scope: (List<ResourceId>, OperationReads) -> OperationReadScope<D>,
    ): OperationInputField {
        val candidates = candidates
        val accepts = accepts
        return OperationInputField(
            path = typed.path,
            owner = typed.owner,
            drop = drop?.ifEmpty { label },
            candidates = candidates?.let { body -> { ids, reads -> scope(ids, reads).body() } },
            accepts =
                accepts?.let { body ->
                    { ids, reads, value ->
                        @Suppress("UNCHECKED_CAST")
                        scope(ids, reads).body(value as V)
                    }
                },
        )
    }
}

private class ConfirmBuilder(
    private val message: String,
) : OperationConfirmScope {
    private var title: String? = null
    private var action: String? = null

    override fun title(value: String) {
        title = value
    }

    override fun action(value: String) {
        action = value
    }

    fun build(label: String) =
        OperationConfirmation(title = title ?: label, message = message, confirmationLabel = action ?: label).requireValid()
}
