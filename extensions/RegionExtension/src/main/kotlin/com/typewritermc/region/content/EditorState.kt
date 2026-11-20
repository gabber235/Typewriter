package com.typewritermc.region.content

/**
 * One value of an editor's working model. Every value stored under the field has type [T],
 * so a read needs no cast and cannot find a value of another type.
 *
 * Fields compare by identity. Two fields sharing a [name] are still two fields, so each mode
 * declares its own fields once, as constants. [default] answers a read of a snapshot that does
 * not hold the field. A non null [readout] names the field in undo and redo feedback.
 */
internal class EditField<T>(val name: String, val default: T, val readout: String? = null) {
    infix fun of(value: T): EditValue<T> = EditValue(this, value)

    override fun toString(): String = name
}

/** A field paired with a value of its type, for building an [EditorState]. */
internal class EditValue<T>(val field: EditField<T>, val value: T)

/**
 * An immutable snapshot of editor values keyed by [EditField].
 *
 * A full snapshot holds the whole working model of a session. The edit history keeps partial
 * ones that hold only the fields a change moved, and applies them on top of the current model
 * with [overriddenBy].
 */
internal class EditorState private constructor(private val values: Map<EditField<*>, Any?>) {
    val fields: Set<EditField<*>> get() = values.keys

    operator fun <T> get(field: EditField<T>): T {
        if (!values.containsKey(field)) return field.default
        @Suppress("UNCHECKED_CAST")
        return values[field] as T
    }

    /** The value [field] reads as, for comparisons that do not know the field's type. */
    fun valueOf(field: EditField<*>): Any? = if (values.containsKey(field)) values[field] else field.default

    fun <T> with(field: EditField<T>, value: T): EditorState = EditorState(values + (field to value))

    /** This snapshot reduced to [fields]; a field it does not hold stays absent. */
    fun only(fields: Collection<EditField<*>>): EditorState = EditorState(values.filterKeys { it in fields })

    /** This snapshot with every field [overrides] holds taking the value it holds there. */
    fun overriddenBy(overrides: EditorState): EditorState = EditorState(values + overrides.values)

    fun isEmpty(): Boolean = values.isEmpty()

    override fun equals(other: Any?): Boolean = other is EditorState && other.values == values

    override fun hashCode(): Int = values.hashCode()

    override fun toString(): String = values.entries.joinToString(prefix = "{", postfix = "}") { "${it.key}=${it.value}" }

    companion object {
        val EMPTY = EditorState(emptyMap())

        fun of(vararg entries: EditValue<*>): EditorState =
            EditorState(entries.associate { it.field to it.value })
    }
}

/**
 * The fields whose value differs between [before] and [after], judged over every field either
 * side holds. A field one side does not hold reads as its default there.
 */
internal fun changedFields(before: EditorState, after: EditorState): Set<EditField<*>> =
    (before.fields + after.fields).filterTo(LinkedHashSet()) { before.valueOf(it) != after.valueOf(it) }
