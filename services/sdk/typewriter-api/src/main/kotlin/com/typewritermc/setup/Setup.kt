package com.typewritermc.setup

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphLayout
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.Placement
import com.typewritermc.authoring.RealmSection
import com.typewritermc.authoring.text
import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import java.nio.ByteBuffer
import java.security.MessageDigest
import java.util.UUID
import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KClass
import kotlin.reflect.KProperty
import kotlin.reflect.full.isSubclassOf
import kotlin.reflect.full.primaryConstructor

/*
 * Setups author realm content as Kotlin values. The KSP pass that writes `XDraft` for every `@TypewriterType` also
 * writes the setup builders: every owning list field becomes a `SetupList`, every concrete resource type a builder on
 * the lists that accept it, and every realm section an accessor on `SetupRoot`. Nothing here names a concrete type.
 */

@DslMarker
annotation class SetupDsl

/** Authored content as one composable value, with typed [handles] to what it creates. */
class Setup<out H> internal constructor(
    val name: SetupName,
    /** Parents before children, siblings in the order their builders ran. */
    val parts: List<SetupPart>,
    val handles: H,
) {
    /** Every resource this setup creates. */
    val resources: Set<ResourceId> get() = parts.mapTo(linkedSetOf()) { it.id }

    /** Both setups' content; a part both contain is created once, two different parts under one id are an error. */
    operator fun <O> plus(other: Setup<O>): Setup<Pair<H, O>> =
        Setup(name + other.name, merge(parts, other.parts), handles to other.handles)

    /** The key path of [resource] for messages, for example `library / books greeting / pages start`. */
    fun pathOf(resource: ResourceId): String = parts.firstOrNull { it.id == resource }?.path?.joinToString(" / ") ?: resource.value
}

@JvmInline
value class SetupName(
    val value: String,
) {
    init {
        require(value.matches(SETUP_NAME)) { "Setup names are lowercase words joined by '-', found '$value'." }
    }

    operator fun plus(other: SetupName) = SetupName("$value+${other.value}")
}

/** A resource a setup creates. Assigning it to a link field stores a [Ref] to it. */
@JvmInline
value class SetupHandle<out T : Resource>(
    val id: ResourceId,
)

/** The owner a part is inserted under: another part of the setup, or the realm's single instance of a section type. */
sealed interface SetupOwner {
    data class Part(
        val id: ResourceId,
    ) : SetupOwner

    /** Section ids are fresh per realm, so the applier resolves [definition] when the setup is applied. */
    data class Section(
        val type: KClass<out RealmSection>,
        val definition: TypeDefinitionId,
    ) : SetupOwner
}

/** A field named both ways: the constructor parameter [property] and the [serialized] authoring field. */
data class SetupFieldName(
    val property: String,
    val serialized: String,
)

/** One resource the setup authors, not yet constructed. */
data class SetupPart(
    val id: ResourceId,
    /** The key path the [id] derives from; each step below the section is the owning list field and the key. */
    val path: List<String>,
    val type: KClass<out Resource>,
    val definition: TypeDefinitionId,
    val owner: SetupOwner,
    /** The owning list field of [owner] the part is inserted into, for example a book's `pages`. */
    val list: ValuePath,
    /** The type of one item of [list]: the owning contract's link to the part's type. */
    val item: TypeUse,
    /** The part's own link back to its owner, when its type declares one (`Element.page`); the insert fills it. */
    val ownerField: SetupFieldName?,
    /** The constructor parameter that receives [placement], when the type is placed by its owner's layout. */
    val placementField: String?,
    val placement: Placement?,
    /** Only the fields the setup assigned, by constructor parameter; handles become refs at construction. */
    val assigned: Map<String, Any?>,
) {
    /**
     * The real object, constructed with `callBy` so unassigned fields keep their Kotlin defaults. The owner field gets
     * a placeholder link that the applier replaces with an unfilled value.
     */
    fun construct(): Resource {
        val constructor = type.primaryConstructor ?: error("${type.simpleName} has no primary constructor.")
        val values = assigned.mapValuesTo(linkedMapOf()) { (_, value) -> value.toRefs() }
        ownerField?.let { values[it.property] = Ref<Nothing, Resource>(id) }
        if (placementField != null && placement != null) values[placementField] = placement
        val parameters = constructor.parameters.associateBy { it.name }
        values.keys.filterNot(parameters::containsKey).takeIf { it.isNotEmpty() }?.let { unknown ->
            error("${describe()}: ${type.simpleName} has no constructor parameter ${unknown.joinToString()}.")
        }
        val missing = constructor.parameters.filter { !it.isOptional && it.name !in values }
        if (missing.isNotEmpty()) {
            val names = missing.joinToString { it.name.orEmpty() }
            val hint = if (missing.any { it.name == placementField }) "; its owner has no known layout, so set placement" else ""
            error("${describe()}: ${type.simpleName} requires $names$hint.")
        }
        return constructor.callBy(values.mapKeys { (name, _) -> parameters.getValue(name) })
    }

    private fun describe(): String = path.joinToString(" / ")
}

private fun Any?.toRefs(): Any? =
    when (this) {
        is SetupHandle<*> -> Ref<Nothing, Resource>(id)
        is Set<*> -> mapTo(linkedSetOf()) { it.toRefs() }
        is List<*> -> map { it.toRefs() }
        is Map<*, *> -> entries.associate { (key, value) -> key.toRefs() to value.toRefs() }
        else -> this
    }

/** Collects the parts of one setup in builder order. */
internal class SetupBuild(
    val name: SetupName,
) {
    private val slots = mutableListOf<SetupPart?>()

    val parts: List<SetupPart> get() = slots.map { checkNotNull(it) { "A setup builder did not finish." } }

    /** Reserves the next position, so a part precedes the children its block adds. */
    fun reserve(): Int = slots.size.also { slots += null }

    fun fill(
        slot: Int,
        part: SetupPart,
    ) {
        require(slots.none { it?.id == part.id }) { "${part.path.joinToString(" / ")} is defined twice in setup ${name.value}." }
        slots[slot] = part
    }
}

/** One owning list of one owner. Builders for every concrete `T : E` are extensions on `SetupList<T>`. */
@SetupDsl
class SetupList<in E : Resource> internal constructor(
    private val build: SetupBuild,
    private val owner: SetupOwner,
    private val ownerPath: List<String>,
    private val field: ValuePath,
    private val item: TypeUse,
    private val layout: SetupLayout,
) {
    private var placed = 0

    @GeneratedSdkApi
    fun <T : Resource, F : SetupFields<T>, H> add(
        key: String,
        type: KClass<T>,
        definition: TypeDefinitionId,
        ownerField: SetupFieldName?,
        placementField: String?,
        fields: (PartScope<T>) -> F,
        configure: F.() -> H,
    ): H {
        val path = ownerPath + "${field.text} $key"
        val scope = PartScope(build, stableId(path), path, type)
        val slot = build.reserve()
        val handles = fields(scope).configure()
        val placement = placementField?.let { scope.explicitPlacement ?: layout.next(placed++) }
        build.fill(
            slot,
            SetupPart(scope.id, path, type, definition, owner, field, item, ownerField, placementField, placement, scope.assigned.toMap()),
        )
        return handles
    }
}

/** The part a generated `XSetup` class configures. */
class PartScope<T : Resource> internal constructor(
    private val build: SetupBuild,
    internal val id: ResourceId,
    private val path: List<String>,
    private val type: KClass<T>,
) {
    internal val assigned = linkedMapOf<String, Any?>()
    internal var explicitPlacement: Placement? = null

    /** The part's owning list [field] with items of type [item], placed by this part's layout. */
    @GeneratedSdkApi
    fun <E : Resource> list(
        field: ValuePath,
        item: TypeUse,
    ): SetupList<E> = SetupList(build, SetupOwner.Part(id), path, field, item, SetupLayout.of(type))
}

/** The realm root. Generated section accessors are extensions on it. */
@SetupDsl
class SetupRoot internal constructor(
    private val build: SetupBuild,
) {
    @GeneratedSdkApi
    fun section(
        type: KClass<out RealmSection>,
        definition: TypeDefinitionId,
        name: String,
    ): SetupSection = SetupSection(build, SetupOwner.Section(type, definition), name)
}

/** One realm section. Its generated `XSection` class exposes the section's owning lists. */
class SetupSection internal constructor(
    private val build: SetupBuild,
    private val owner: SetupOwner.Section,
    private val name: String,
) {
    @GeneratedSdkApi
    fun <E : Resource> list(
        field: ValuePath,
        item: TypeUse,
    ): SetupList<E> = SetupList(build, owner, listOf(name), field, item, SetupLayout.of(owner.type))
}

/** Authors a setup named [name]; the value of [block] becomes its handles. */
fun <H> setup(
    name: String,
    block: SetupRoot.() -> H,
): Setup<H> {
    val build = SetupBuild(SetupName(name))
    val handles = SetupRoot(build).block()
    return Setup(build.name, build.parts, handles)
}

/** Assigned fields of one part. Generated `XSetup` classes declare one delegated property per settable field. */
@SetupDsl
abstract class SetupFields<T : Resource>
    @GeneratedSdkApi
    constructor(
        private val part: PartScope<T>,
    ) {
        /**
         * The delegate of one settable field, stored under the property name, which is also the constructor parameter.
         * Reading a field the setup did not assign is a mistake in the setup, not a default.
         */
        @GeneratedSdkApi
        protected fun <V> field(): ReadWriteProperty<Any?, V> =
            object : ReadWriteProperty<Any?, V> {
                @Suppress("UNCHECKED_CAST")
                override fun getValue(
                    thisRef: Any?,
                    property: KProperty<*>,
                ): V =
                    if (property.name in
                        part.assigned
                    ) {
                        part.assigned[property.name] as V
                    } else {
                        error("${property.name} was not assigned.")
                    }

                override fun setValue(
                    thisRef: Any?,
                    property: KProperty<*>,
                    value: V,
                ) {
                    part.assigned[property.name] = value
                }
            }

        /** Overrides the placement the owner's layout would give. */
        var placement: Placement?
            get() = part.explicitPlacement
            set(value) {
                part.explicitPlacement = value
            }

        val handle: SetupHandle<T> get() = SetupHandle(part.id)
    }

/** Placement policy from the owner's layout interface. */
sealed interface SetupLayout {
    fun next(index: Int): Placement?

    /** Graph pages and the tag graph: rows of eight, in grid units. */
    data object Grid : SetupLayout {
        override fun next(index: Int) = GraphPlacement(x = index % GRID_COLUMNS * 3, y = index / GRID_COLUMNS * 2, width = 2, height = 1)
    }

    /** No known layout: a placed type must be given an explicit placement. */
    data object None : SetupLayout {
        override fun next(index: Int): Placement? = null
    }

    companion object {
        fun of(owner: KClass<*>): SetupLayout = if (owner.isSubclassOf(GraphLayout::class)) Grid else None
    }
}

/** UUIDv5 over the key path: stable across runs, unique per path. */
internal fun stableId(path: List<String>): ResourceId {
    val digest = MessageDigest.getInstance("SHA-1")
    digest.update(
        ByteBuffer
            .allocate(16)
            .putLong(SETUP_NAMESPACE.mostSignificantBits)
            .putLong(SETUP_NAMESPACE.leastSignificantBits)
            .array(),
    )
    val hash = digest.digest(path.joinToString("/").toByteArray(Charsets.UTF_8)).copyOf(16)
    hash[6] = (hash[6].toInt() and 0x0f or 0x50).toByte()
    hash[8] = (hash[8].toInt() and 0x3f or 0x80).toByte()
    val bits = ByteBuffer.wrap(hash)
    return ResourceId(UUID(bits.long, bits.long).toString())
}

internal fun merge(
    a: List<SetupPart>,
    b: List<SetupPart>,
): List<SetupPart> =
    (a + b).groupBy { it.id }.map { (_, same) ->
        require(same.distinct().size == 1) { "${same.first().path.joinToString(" / ")} is defined differently by two setups." }
        same.first()
    }

private const val GRID_COLUMNS = 8
private val SETUP_NAME = Regex("[a-z0-9-]+(\\+[a-z0-9-]+)*")
private val SETUP_NAMESPACE: UUID = UUID.fromString("5b0c2f8e-6a1d-4c3e-9f27-8d4e1a7b6c05")
