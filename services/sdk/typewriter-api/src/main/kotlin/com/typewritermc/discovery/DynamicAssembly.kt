package com.typewritermc.discovery

import com.typewritermc.authoring.DraftBinding
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.formula.BindBuilder
import com.typewritermc.formula.BindParameter
import com.typewritermc.formula.DynamicBuilder
import com.typewritermc.formula.Dynamics
import com.typewritermc.types.catalog.BindKey
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId

/**
 * One registered hook. It matches like any check subject, so a hook on a parent contract runs for its subtypes in
 * other artifacts, and a hook by definition id runs for every type argument of that definition.
 */
class DynamicHook internal constructor(
    val origin: RuleOrigin,
    val match: ResourceTypeMatch,
    private val dynamic: DynamicBuilder.(DraftBinding) -> Unit,
) {
    /** Runs this hook on the resource [binding] binds; a caller binds through [match] first. */
    fun run(
        builder: DynamicBuilder,
        binding: DraftBinding,
    ) = builder.dynamic(binding)
}

/** One registered bind: what the parameter [key] names is for each resource of exactly its type. */
class BindHook internal constructor(
    val origin: RuleOrigin,
    val key: BindKey,
    val match: ResourceTypeMatch,
    private val bind: BindBuilder.(DraftBinding) -> Unit,
) {
    /** Runs this bind on the resource [binding] binds; a caller binds through [match] first. */
    fun run(
        builder: BindBuilder,
        binding: DraftBinding,
    ) = builder.bind(binding)
}

/** A dynamic provider whose registration failed under [code], or one registration it made that load rejected. */
data class DynamicRegistrationFailure(
    val provider: OwnedDynamic,
    val code: String,
    val cause: Throwable,
)

/**
 * What every dynamic provider registered when the extension loaded: its hooks and binds, and the failures that dropped
 * a provider or one of its binds. The realm and every engine hold the same collection for one catalog generation.
 */
class CollectedDynamics internal constructor(
    val hooks: List<DynamicHook>,
    val binds: List<BindHook>,
    val failures: List<DynamicRegistrationFailure>,
) {
    /** The type parameters some bind computes. */
    internal val bound: Set<BindKey> get() = binds.mapTo(linkedSetOf()) { it.key }

    companion object {
        val NONE = CollectedDynamics(emptyList(), emptyList(), emptyList())
    }
}

/**
 * Runs the registration of every provider in [dynamics]. A bind must name a parameter of a type its own artifact
 * declares among [declarations]; load drops any other bind. A bind matches exactly the type its parameter belongs to.
 */
internal fun collectDynamics(
    dynamics: List<OwnedDynamic>,
    declarations: List<OwnedTypeDeclaration>,
): CollectedDynamics {
    val declared = declarations.groupBy { it.definition.id }
    val hooks = mutableListOf<DynamicHook>()
    val binds = mutableListOf<BindHook>()
    val failures = mutableListOf<DynamicRegistrationFailure>()
    dynamics.forEach { owned ->
        val collector = DynamicCollector(owned)
        runExtension({
            owned.provider.run { collector.register() }
            hooks += collector.hooks
            collector.binds.forEach { bind ->
                when (val rejection = bind.rejection(owned, declared)) {
                    null -> binds += bind
                    else -> failures += DynamicRegistrationFailure(owned, rejection.first, IllegalArgumentException(rejection.second))
                }
            }
        }) { failure -> failures += DynamicRegistrationFailure(owned, "dynamic_registration_failed", failure) }
    }
    return CollectedDynamics(hooks, binds, failures)
}

/** [declaration] with every parameter some bind in [bound] computes marked derived. */
internal fun OwnedTypeDeclaration.withBinds(bound: Set<BindKey>): OwnedTypeDeclaration {
    val definition = definition
    if (definition.parameters.none { BindKey(definition.id, it.name) in bound }) return this
    return copy(definition = definition.withBinds(bound))
}

private fun TypeDefinition.withBinds(bound: Set<BindKey>): TypeDefinition =
    copy(parameters = parameters.map { if (BindKey(id, it.name) in bound) it.copy(derived = true) else it })

/** Why load drops this bind, as a code and a message, or null when it may compute its parameter. */
private fun BindHook.rejection(
    owned: OwnedDynamic,
    declared: Map<TypeDefinitionId, List<OwnedTypeDeclaration>>,
): Pair<String, String>? {
    val owners = declared[key.owner].orEmpty()
    return when {
        owners.none { declaration -> declaration.definition.parameters.any { it.name == key.name } } ->
            "bind_unknown_parameter" to "No declared type ${key.owner} has a type parameter ${key.name}."
        owners.none { it.origin.artifact == owned.origin.artifact } ->
            "bind_foreign_type" to "Only the artifact that declares ${key.owner} may bind its parameter ${key.name}."
        else -> null
    }
}

private class DynamicCollector(
    private val owned: OwnedDynamic,
) : Dynamics {
    val hooks = mutableListOf<DynamicHook>()
    val binds = mutableListOf<BindHook>()

    override fun <D> each(
        type: DraftType<D>,
        dynamic: DynamicBuilder.(D) -> Unit,
    ) {
        hooks += DynamicHook(owned.ruleOrigin, type.match) { binding -> dynamic(type.bind(binding)) }
    }

    override fun each(
        definition: TypeDefinitionId,
        dynamic: DynamicBuilder.(ResourceId) -> Unit,
    ) {
        hooks += DynamicHook(owned.ruleOrigin, ResourceTypeMatch.Definition(definition)) { binding -> dynamic(binding.location.resource) }
    }

    override fun <D> bind(
        parameter: BindParameter<D>,
        bind: BindBuilder.(D) -> Unit,
    ) {
        val key = parameter.key
        binds += BindHook(owned.ruleOrigin, key, ResourceTypeMatch.Definition(key.owner)) { binding -> bind(parameter.draft.bind(binding)) }
    }
}
