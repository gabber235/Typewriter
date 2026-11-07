package com.typewritermc.realm.formula

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.FieldPath
import com.typewritermc.authoring.append
import com.typewritermc.authoring.of
import com.typewritermc.checking.InputIdentity
import com.typewritermc.formula.DynamicBuilder
import com.typewritermc.formula.ExportBuilder
import com.typewritermc.formula.ScopeBuilder
import com.typewritermc.formula.check.CheckedFormula
import com.typewritermc.formula.check.check
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.Fact
import com.typewritermc.realm.authoring.OwnLinks
import com.typewritermc.realm.authoring.RealmQuery
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.realm.authoring.extensions
import com.typewritermc.realm.authoring.ownershipRelations
import com.typewritermc.realm.authoring.tracked
import com.typewritermc.realm.catalog.DynamicHook
import com.typewritermc.services.libs.utils.runExtension
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/** One level of names. Two resources under one name are an ambiguity where a formula uses it. */
data class ScopeLevel(
    val names: Map<String, List<ResourceId>>,
) {
    companion object {
        val EMPTY = ScopeLevel(emptyMap())
    }
}

/** The levels a formula's names are looked up in, nearest first. */
data class ScopeChain(
    val levels: List<ScopeLevel>,
)

/** A hook that failed by itself on one resource. */
data class HookFailure(
    val origin: RuleOrigin,
    val message: String,
)

/** What every hook said about one resource: its own fields' scopes, its contents' scope, its export and its failures. */
data class DynamicOutput(
    val fieldScopes: Map<String, ScopeLevel>,
    val contents: ScopeLevel,
    val exports: ValueLocation?,
    val failures: List<HookFailure>,
)

/**
 * What the hooks say about [resource]. A hook that fails by itself, through its own exception, a LinkageError or a
 * stack overflow, adds a failure and nothing else, so a broken extension costs one finding and the other hooks keep
 * working. Only cancellation, graph control and fatal JVM errors pass through.
 */
internal data class DynamicOf(
    val resource: ResourceId,
) : RealmQuery<DynamicOutput> {
    context(reads: RealmReads)
    override fun compute(): DynamicOutput {
        val authored = tracked()
        val output = DynamicOutputBuilder()
        extensions.hooks.forEach { hook -> output.run(hook, authored, resource) }
        return output.build()
    }
}

private class DynamicOutputBuilder {
    private val fieldScopes = linkedMapOf<String, LevelBuilder>()
    private val contents = LevelBuilder()
    private var exports: ValueLocation? = null
    private val failures = mutableListOf<HookFailure>()

    fun run(
        hook: DynamicHook,
        authored: CapturedAuthoringReads,
        resource: ResourceId,
    ) {
        val binding = authored.bindResource(ValueLocation.of(resource), hook.match) ?: return
        val said = HookOutput(authored, resource)
        runExtension({
            hook.run(said, binding)
            said.fieldScopes.forEach { (field, level) -> fieldScopes.getOrPut(field) { LevelBuilder() }.addAll(level) }
            contents.addAll(said.contents)
            said.exports?.let { exports = it }
        }) { failure -> failures += HookFailure(hook.origin, failure.message ?: failure::class.simpleName.orEmpty()) }
    }

    fun build(): DynamicOutput = DynamicOutput(fieldScopes.mapValues { it.value.build() }, contents.build(), exports, failures)
}

/** What one hook said, kept apart until it finishes, so a hook that fails adds nothing. */
private class HookOutput(
    private val reads: AuthoredReads,
    val resource: ResourceId,
) : DynamicBuilder,
    AuthoredReads by reads {
    val fieldScopes = linkedMapOf<String, LevelBuilder>()
    val contents = LevelBuilder()
    var exports: ValueLocation? = null

    override fun scope(
        field: FieldPath,
        block: ScopeBuilder.() -> Unit,
    ) {
        val key = field.path.rootField() ?: return
        Names(reads, fieldScopes.getOrPut(key) { LevelBuilder() }).block()
    }

    override fun scopeContents(block: ScopeBuilder.() -> Unit) = Names(reads, contents).block()

    override fun exports(block: ExportBuilder.() -> Unit) {
        val output = this
        object : ExportBuilder {
            override fun value(field: FieldPath) {
                output.exports = ValueLocation.of(output.resource).append(field.path)
            }
        }.block()
    }
}

private class Names(
    reads: AuthoredReads,
    private val level: LevelBuilder,
) : ScopeBuilder,
    AuthoredReads by reads {
    override fun resource(
        name: String,
        id: ResourceId,
    ) = level.add(name, id)
}

private class LevelBuilder {
    private val names = linkedMapOf<String, LinkedHashSet<ResourceId>>()

    fun add(
        name: String,
        id: ResourceId,
    ) {
        names.getOrPut(name) { linkedSetOf() } += id
    }

    fun addAll(other: LevelBuilder) = other.names.forEach { (name, ids) -> ids.forEach { add(name, it) } }

    fun build(): ScopeLevel = ScopeLevel(names.mapValues { it.value.toList() })
}

/** The name of the first field of this path: the own field a formula below it belongs to. */
internal fun skirout.editor.v1.type_catalog.ValuePath.rootField(): String? =
    (segments.firstOrNull() as? PathSegment.FieldWrapper)?.value?.name

/** The formulas [resource] stores, read from its whole record along its current schema. */
internal data class FormulasOf(
    val resource: ResourceId,
) : RealmQuery<List<FormulaSite>> {
    context(reads: RealmReads)
    override fun compute(): List<FormulaSite> {
        val authored = tracked()
        val record = authored.record(resource) ?: return emptyList()
        return record.formulaSites(resource, authored.viewCatalog.checked)
    }
}

/**
 * Whether [resource] gets a content subject: it stores a formula, a hook failed on it, its owner chain loops, or it
 * does not fit its schema. Its own query, so discovery reruns per resource and stops on an equal answer.
 */
internal data class HoldsContent(
    val resource: ResourceId,
) : RealmQuery<Boolean> {
    context(reads: RealmReads)
    override fun compute(): Boolean =
        reads.read(FormulasOf(resource)).isNotEmpty() ||
            reads.read(FitOf(resource)).isNotEmpty() ||
            reads.read(DynamicOf(resource)).failures.isNotEmpty() ||
            reads.read(OwnerChain(resource)).loops
}

/**
 * The resource that owns [resource]: the target of its own link at the owned end of an ownership relation. It reads
 * that one stored value, so a change elsewhere in the record or in the owner never reruns it.
 */
internal data class OwnerOf(
    val resource: ResourceId,
) : RealmQuery<ResourceId?> {
    context(reads: RealmReads)
    override fun compute(): ResourceId? {
        val owned = ownershipRelations.mapTo(hashSetOf()) { it.second.id }
        val link = reads.read(OwnLinks(resource)).firstOrNull { it.id.endpoint in owned } ?: return null
        reads.read(Fact(InputIdentity.Value(link.id.location)))
        return link.target.resource
    }
}

/** The owners above a resource, nearest first, and whether the chain returns to a resource it passed. */
data class Owners(
    val chain: List<ResourceId>,
    val loops: Boolean,
)

/**
 * The one climb that scopes and the loop finding share. It reads owners only, so a name changed in some scope never
 * reruns it, and it remembers where it has been, so a hand made ownership loop ends.
 */
internal data class OwnerChain(
    val resource: ResourceId,
) : RealmQuery<Owners> {
    context(reads: RealmReads)
    override fun compute(): Owners {
        val seen = linkedSetOf(resource)
        var owner = reads.read(OwnerOf(resource))
        while (owner != null && seen.add(owner)) owner = reads.read(OwnerOf(owner))
        return Owners(chain = seen.drop(1), loops = owner != null)
    }
}

/** The scope levels at a formula: its own field's scope, then each owner's contents, nearest first. */
internal data class ScopeAt(
    val at: ValueLocation,
) : RealmQuery<ScopeChain> {
    context(reads: RealmReads)
    override fun compute(): ScopeChain {
        val own = at.path.rootField()?.let { reads.read(DynamicOf(at.resource)).fieldScopes[it] }
        val levels = reads.read(OwnerChain(at.resource)).chain.map { reads.read(DynamicOf(it)).contents }
        return ScopeChain(listOfNotNull(own) + levels)
    }
}

/**
 * What [name] means at a formula: the resources at the nearest level that has it. The firewall between a scope and a
 * formula: a changed scope reruns this, and only a changed answer reruns the formula.
 */
internal data class NameAt(
    val at: ValueLocation,
    val name: String,
) : RealmQuery<List<ResourceId>> {
    context(reads: RealmReads)
    override fun compute(): List<ResourceId> =
        reads
            .read(ScopeAt(at))
            .levels
            .firstNotNullOfOrNull { it.names[name] }
            .orEmpty()
}

/** The checked formula at [at], or null when no formula is stored there or it is not checked. */
internal data class CheckFormula(
    val at: ValueLocation,
) : RealmQuery<CheckedFormula?> {
    context(reads: RealmReads)
    override fun compute(): CheckedFormula? {
        val site = reads.read(FormulasOf(at.resource)).firstOrNull { it.at == at } ?: return null
        if (site.computedAtFunction) return null
        return with(RealmFormulaEnvironment(at, reads)) { site.formula.toFormula().check(site.expected) }
    }
}
