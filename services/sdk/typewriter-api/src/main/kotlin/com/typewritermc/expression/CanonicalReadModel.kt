package com.typewritermc.expression

import build.skir.Serializer
import build.skir.reflection.ArrayDescriptor
import build.skir.reflection.EnumConstantVariant
import build.skir.reflection.EnumDescriptor
import build.skir.reflection.EnumVariant
import build.skir.reflection.EnumWrapperVariant
import build.skir.reflection.OptionalDescriptor
import build.skir.reflection.PrimitiveDescriptor
import build.skir.reflection.PrimitiveType
import build.skir.reflection.RecordDescriptorBase
import build.skir.reflection.StructDescriptor
import build.skir.reflection.StructField
import build.skir.reflection.TypeDescriptor
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.COLOR_TYPE_ID
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.ICONIFY_TYPE_ID
import com.typewritermc.types.ICON_TYPE_ID
import com.typewritermc.types.IconDefinition
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.SVG_ICON_TYPE_ID
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.payload
import com.typewritermc.types.unknownVariant
import okio.ByteString
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.NullableTypeTemplate
import skirout.editor.v1.type_catalog.QualifiedTypeId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import java.time.Instant
import java.util.Base64
import skirout.editor.v1.type_catalog.DataValue as SkirDataValue
import skirout.editor.v1.type_catalog.EnumVariant as SkirEnumVariant
import skirout.editor.v1.type_catalog.EnumerationRepresentationTemplate as SkirEnumeration
import skirout.editor.v1.type_catalog.RecordRepresentationTemplate as SkirRecord
import skirout.kernel.v1.icon.Icon as SkirIcon

/**
 * The namespace of every read model identity. A read model is a Skir value that portable expressions read but never
 * author, such as a resource's type selection or its published type; authored declarations cannot use this namespace.
 */
const val CANONICAL_READ_NAMESPACE: String = "skir"

/**
 * One read model root: a Skir type whose values expressions read through [encode] and literals carry back through
 * [decode].
 */
class CanonicalReadModel<T> internal constructor(
    val serializer: Serializer<T>,
    private val registry: CanonicalReadModelRegistry,
) {
    /** The read type of this root. */
    val use: NamedTypeUse = registry.useOf(serializer.typeDescriptor)

    fun encode(value: T): SkirDataValue = registry.encode(value, serializer.typeDescriptor)

    fun decode(value: SkirDataValue): T = registry.decode(value, serializer)
}

/**
 * The finite expression read schema reachable from [roots], derived from Skir reflection. The panel derives the same
 * schema in `canonical_read_models.dart`, and `skir-src/editor/v1/fixtures/canonical_read_models.json` pins it for
 * both. The rule:
 *
 * - A Skir struct is a record. Its fields are the Skir fields in field number order, keyed by their Skir names.
 * - A Skir enum whose variants are all constants is an enumeration whose cases are the variant names.
 * - Any other Skir enum is an abstract record without fields. Each variant is a concrete record with the enum as its
 *   parent; a wrapper variant has one field, `value`, holding the wrapped value, and a constant variant has none.
 * - A record is identified by `TypeId.Qualified(`[CANONICAL_READ_NAMESPACE]`, <record id>)` at revision 1, where the
 *   record id is Skir's own `<module path>:<qualified name>`, for example `editor/v1/type_catalog.skir:TypeUse`. A
 *   variant appends `.<variant name>`, for example `editor/v1/type_catalog.skir:TypeUse.named`.
 * - bool is a boolean, int32 and int64 are signed integers of that width, hash64 is an unsigned 64 bit integer, float32
 *   and float64 are floats of that width, string is text, and bytes and timestamp keep their kind. An optional is
 *   nullable and an array is the framework List.
 * - The kernel Color and Icon are the framework declared Color and Icon types, so a read color equals an authored one.
 *
 * Values follow the schema: a record is a named record payload, an enumeration a named enum case, a list a list value
 * whose items are identified `canonical:<index>`.
 */
open class CanonicalReadModelRegistry(
    roots: List<Serializer<*>>,
) {
    private val records = linkedMapOf<String, ReadRecord>()

    init {
        roots.forEach { declare(it.typeDescriptor) }
    }

    /** The derived definitions, ordered by identity. [frameworkDefinitions] holds the framework ones they reference. */
    val definitions: List<TypeDefinition> = records.values.flatMap(ReadRecord::definitions).sortedBy { it.id.name() }

    private val declaredDefinitions =
        listOf(ColorDefinition.declaration, IconDefinition.declaration, IconIconifyDefinition.declaration, IconSvgDefinition.declaration)

    /**
     * The framework definitions the read definitions reference: the List and the declared Color and Icon types.
     * The panel publishes the same definitions with its read models.
     */
    val frameworkDefinitions: List<TypeDefinition> =
        (StandardTypes.definitions.filter { it.id == StandardTypes.list } + declaredDefinitions).sortedBy { it.id.name() }

    /** Read types and the declared Color and Icon types they read, which resolve here even without the framework. */
    private val ownedIds: Set<TypeDefinitionId> =
        definitions.mapTo(mutableSetOf()) { it.id } + declaredDefinitions.map { it.id }

    /** The read and framework definitions as the checked catalog the checker resolves read types in. */
    val catalog = DefaultCheckedCatalog(CatalogGeneration("canonical.read.v1"), definitions + frameworkDefinitions)

    fun owns(id: TypeDefinitionId): Boolean = id in ownedIds

    fun supports(use: TypeUse): Boolean =
        when (use) {
            is TypeUse.NamedWrapper -> owns(use.value.definition) || use.value.arguments.any(::supports)
            is TypeUse.NullableWrapper -> supports(use.value.value)
            is TypeUse.ScalarWrapper -> false
            else -> unknownVariant(use)
        }

    fun <T> model(serializer: Serializer<T>): CanonicalReadModel<T> = CanonicalReadModel(serializer, this)

    internal fun useOf(descriptor: TypeDescriptor.Reflective<*>): NamedTypeUse =
        NamedTypeUse(definition = declare(descriptor), arguments = emptyList())

    /**
     * Projects [value], described by [descriptor], to its read value, or to the read value at the field [path] below
     * it. Reading a field of a null value is unfilled. Every visited value charges [consumeStep]; a list charges its
     * items and a whole record its fields to [consumeItems].
     */
    fun encode(
        value: Any?,
        descriptor: TypeDescriptor.Reflective<*>,
        path: List<String> = emptyList(),
        consumeStep: () -> Unit = {},
        consumeItems: (Int) -> Unit = {},
    ): SkirDataValue = Projection(consumeStep, consumeItems).project(value, descriptor, path, 0)

    /** Reads [value] back as the Skir value [serializer] describes; rejects a value of any other read type. */
    fun <T> decode(
        value: SkirDataValue,
        serializer: Serializer<T>,
    ): T = serializer.fromJsonCode(json(value, serializer.typeDescriptor, 0))

    private fun declare(descriptor: TypeDescriptor.Reflective<*>): TypeDefinitionId {
        val record = descriptor as? RecordDescriptorBase ?: error("A read model root must be a Skir struct or enum.")
        val name = record.recordId
        DECLARED[name]?.let { return it.id }
        records[name]?.let { return it.id }
        val id = readId(name)
        when (descriptor) {
            is StructDescriptor.Reflective<*, *> -> {
                val placeholder = ReadRecord.Struct(id)
                records[name] = placeholder
                placeholder.fields = descriptor.orderedFields().map { field -> field.name to template(field.type) }
            }

            is EnumDescriptor.Reflective<*> -> {
                val variants = descriptor.orderedVariants()
                if (variants.all { it is EnumConstantVariant.Reflective<*> }) {
                    records[name] = ReadRecord.Enumeration(id, variants.map { it.name })
                } else {
                    val union = ReadRecord.Union(id)
                    records[name] = union
                    union.variants =
                        variants.map { variant ->
                            ReadVariant(
                                readId("$name.${variant.name}"),
                                variant.name,
                                (variant as? EnumWrapperVariant.Reflective<*, *>)?.let { template(it.type) },
                            )
                        }
                }
            }

            else -> {
                error("Unsupported Skir record ${record.qualifiedName}.")
            }
        }
        return id
    }

    private fun template(descriptor: TypeDescriptor.Reflective<*>): TypeTemplate =
        when (descriptor) {
            is OptionalDescriptor.Reflective<*> -> {
                TypeTemplate.NullableWrapper(NullableTypeTemplate(value = template(descriptor.otherType)))
            }

            is ArrayDescriptor.Reflective<*, *> -> {
                TypeTemplate.NamedWrapper(NamedTypeTemplate(definition = LIST_ID, arguments = listOf(template(descriptor.itemType))))
            }

            is PrimitiveDescriptor.Reflective<*> -> {
                TypeTemplate.ScalarWrapper(scalar(descriptor.primitiveType))
            }

            else -> {
                TypeTemplate.NamedWrapper(NamedTypeTemplate(definition = declare(descriptor), arguments = emptyList()))
            }
        }

    private inner class Projection(
        private val consumeStep: () -> Unit,
        private val consumeItems: (Int) -> Unit,
    ) {
        fun project(
            value: Any?,
            descriptor: TypeDescriptor.Reflective<*>,
            path: List<String>,
            depth: Int,
        ): SkirDataValue {
            require(depth <= PortableExpressionLimits.MAX_DEPTH) { "The canonical projection exceeded its depth limit." }
            consumeStep()
            if (value == null) return if (path.isEmpty()) SkirDataValue.NULL else SkirDataValue.UNFILLED
            return when (descriptor) {
                is OptionalDescriptor.Reflective<*> -> {
                    project(value, descriptor.otherType, path, depth + 1)
                }

                is PrimitiveDescriptor.Reflective<*> -> {
                    require(path.isEmpty()) { "A canonical scalar has no fields." }
                    primitive(value, descriptor.primitiveType)
                }

                is ArrayDescriptor.Reflective<*, *> -> {
                    require(path.isEmpty()) { "A canonical collection needs an item binding before field access." }
                    val items = (value as List<*>)
                    consumeItems(items.size)
                    SkirDataValue.createListValue(
                        items =
                            items.mapIndexed { index, item ->
                                ListItem(
                                    id = ItemId(value = "canonical:$index"),
                                    value =
                                        project(
                                            item,
                                            descriptor.itemType,
                                            emptyList(),
                                            depth + 1,
                                        ),
                                )
                            },
                    )
                }

                else -> {
                    record(value, descriptor as RecordDescriptorBase, path, depth)
                }
            }
        }

        private fun record(
            value: Any,
            descriptor: RecordDescriptorBase,
            path: List<String>,
            depth: Int,
        ): SkirDataValue {
            DECLARED[descriptor.recordId]?.let { declared -> return select(declared.encode(value), path) }
            return when (val record = records.getValue(descriptor.recordId)) {
                is ReadRecord.Struct -> {
                    val fields =
                        (descriptor as StructDescriptor.Reflective<*, *>).orderedFields().associate { field ->
                            field.name to { remaining: List<String> -> project(field.read(value), field.type, remaining, depth + 1) }
                        }
                    named(record.id, fields, path)
                }

                is ReadRecord.Enumeration -> {
                    require(path.isEmpty()) { "A canonical enum has no fields." }
                    val variant = (descriptor as EnumDescriptor.Reflective<*>).variantOf(value)
                    SkirDataValue.createNamed(
                        actualType = NamedTypeUse(definition = record.id, arguments = emptyList()),
                        payload = SkirDataValue.EnumCaseWrapper(variant.name),
                    )
                }

                is ReadRecord.Union -> {
                    val variant = (descriptor as EnumDescriptor.Reflective<*>).variantOf(value)
                    val read = record.variants.single { it.name == variant.name }
                    val fields =
                        if (variant is EnumWrapperVariant.Reflective<*, *>) {
                            mapOf(
                                VALUE_FIELD to
                                    { remaining: List<String> -> project(variant.read(value), variant.type, remaining, depth + 1) },
                            )
                        } else {
                            emptyMap()
                        }
                    named(read.id, fields, path)
                }
            }
        }

        private fun named(
            id: TypeDefinitionId,
            fields: Map<String, (List<String>) -> SkirDataValue>,
            path: List<String>,
        ): SkirDataValue {
            if (path.isNotEmpty()) {
                val field = requireNotNull(fields[path.first()]) { "Unknown canonical field ${path.first()}." }
                return field(path.drop(1))
            }
            consumeItems(fields.size)
            return SkirDataValue.createNamed(
                actualType = NamedTypeUse(definition = id, arguments = emptyList()),
                payload =
                    SkirDataValue.createRecord(
                        fields =
                            fields.map { (name, read) ->
                                FieldValue(name = name, value = read(emptyList()))
                            },
                    ),
            )
        }
    }

    private fun json(
        value: SkirDataValue,
        descriptor: TypeDescriptor.Reflective<*>,
        depth: Int,
    ): String {
        require(depth <= PortableExpressionLimits.MAX_DEPTH) { "The canonical value exceeded its depth limit." }
        return when (descriptor) {
            is OptionalDescriptor.Reflective<*> -> {
                if (value == SkirDataValue.NULL) "null" else json(value, descriptor.otherType, depth + 1)
            }

            is PrimitiveDescriptor.Reflective<*> -> {
                primitiveJson(value, descriptor.primitiveType)
            }

            is ArrayDescriptor.Reflective<*, *> -> {
                val items =
                    when (value) {
                        is SkirDataValue.ListValueWrapper -> value.value.items
                        is SkirDataValue.SetValueWrapper -> value.value.items
                        else -> throw IllegalArgumentException("Expected a canonical list.")
                    }
                items.joinToString(",", "[", "]") { json(it.value, descriptor.itemType, depth + 1) }
            }

            else -> {
                recordJson(value, descriptor as RecordDescriptorBase, depth)
            }
        }
    }

    private fun recordJson(
        value: SkirDataValue,
        descriptor: RecordDescriptorBase,
        depth: Int,
    ): String {
        val named =
            (value as? SkirDataValue.NamedWrapper)?.value ?: throw IllegalArgumentException("Expected a canonical named value.")
        require(named.actualType.arguments.isEmpty()) { "Canonical read types take no arguments." }
        val actual = named.actualType.definition
        DECLARED[descriptor.recordId]?.let { declared -> return declared.json(actual, named.payload) }
        return when (val record = records.getValue(descriptor.recordId)) {
            is ReadRecord.Struct -> {
                require(actual == record.id) { "Expected the canonical type ${record.id.name()}." }
                val fields = recordFields(named.payload)
                jsonObject(
                    (descriptor as StructDescriptor.Reflective<*, *>).orderedFields().map { field ->
                        field.name to json(fields.field(field.name), field.type, depth + 1)
                    },
                )
            }

            is ReadRecord.Enumeration -> {
                require(actual == record.id) { "Expected the canonical type ${record.id.name()}." }
                val case = (named.payload as? SkirDataValue.EnumCaseWrapper)?.value
                require(case in record.cases) { "Unknown canonical enum case." }
                jsonString(case!!)
            }

            is ReadRecord.Union -> {
                val read =
                    requireNotNull(record.variants.firstOrNull { it.id == actual }) { "Expected a variant of ${record.id.name()}." }
                val variant = (descriptor as EnumDescriptor.Reflective<*>).orderedVariants().single { it.name == read.name }
                if (variant is EnumWrapperVariant.Reflective<*, *>) {
                    jsonObject(
                        listOf(
                            "kind" to jsonString(read.name),
                            "value" to json(recordFields(named.payload).field(VALUE_FIELD), variant.type, depth + 1),
                        ),
                    )
                } else {
                    jsonString(read.name)
                }
            }
        }
    }

    private sealed class ReadRecord(
        val id: TypeDefinitionId,
    ) {
        abstract val definitions: List<TypeDefinition>

        class Struct(
            id: TypeDefinitionId,
        ) : ReadRecord(id) {
            lateinit var fields: List<Pair<String, TypeTemplate>>

            override val definitions get() = listOf(recordDefinition(id, fields, parent = null, abstract = false))
        }

        class Enumeration(
            id: TypeDefinitionId,
            val cases: List<String>,
        ) : ReadRecord(id) {
            override val definitions
                get() =
                    listOf(
                        TypeDefinition(
                            id = id,
                            parameters = emptyList(),
                            representation =
                                RepresentationTemplate.EnumerationWrapper(
                                    SkirEnumeration(cases = cases.map { SkirEnumVariant(key = it) }),
                                ),
                            parents = emptyList(),
                        ),
                    )
        }

        class Union(
            id: TypeDefinitionId,
        ) : ReadRecord(id) {
            lateinit var variants: List<ReadVariant>

            override val definitions
                get() =
                    listOf(recordDefinition(id, emptyList(), parent = null, abstract = true)) +
                        variants.map { variant ->
                            recordDefinition(
                                variant.id,
                                listOfNotNull(variant.value?.let { VALUE_FIELD to it }),
                                parent = id,
                                abstract = false,
                            )
                        }
        }
    }

    private class ReadVariant(
        val id: TypeDefinitionId,
        val name: String,
        val value: TypeTemplate?,
    )

    /** A Skir record that is the wire form of a framework declared type rather than a read model of its own. */
    private class DeclaredRead(
        val id: TypeDefinitionId,
        val encode: (Any) -> SkirDataValue,
        val json: (TypeDefinitionId, SkirDataValue) -> String,
    )

    private companion object {
        const val VALUE_FIELD = "value"
        val LIST_ID: TypeDefinitionId = StandardTypes.list

        val COLOR: NamedTypeUse = declaredUse(COLOR_TYPE_ID)
        val ICON: NamedTypeUse = declaredUse(ICON_TYPE_ID)
        val ICONIFY: NamedTypeUse = declaredUse(ICONIFY_TYPE_ID)
        val SVG: NamedTypeUse = declaredUse(SVG_ICON_TYPE_ID)

        val DECLARED: Map<String, DeclaredRead> =
            mapOf(
                "kernel/v1/color.skir:Color" to
                    DeclaredRead(
                        COLOR.definition,
                        encode = { value ->
                            val argb = (value as skirout.kernel.v1.color.Color).argb.toUInt()
                            SkirDataValue.createNamed(actualType = COLOR, payload = SkirDataValue.IntegerWrapper(argb.toString()))
                        },
                        json = { actual, payload ->
                            require(actual == COLOR.definition) { "Expected a canonical color." }
                            val argb =
                                (payload as? SkirDataValue.IntegerWrapper)?.value
                                    ?: throw IllegalArgumentException("Expected an ARGB color.")
                            jsonObject(listOf("argb" to argb.toUInt().toInt().toString()))
                        },
                    ),
                "kernel/v1/icon.skir:Icon" to
                    DeclaredRead(
                        ICON.definition,
                        encode = { value ->
                            when (value) {
                                is SkirIcon.IconifyWrapper -> iconValue(ICONIFY, "value", value.value)
                                is SkirIcon.SvgWrapper -> iconValue(SVG, "source", value.value)
                                else -> throw IllegalArgumentException("Unknown icon variant.")
                            }
                        },
                        json = { actual, payload ->
                            val (kind, field) =
                                when (actual) {
                                    ICONIFY.definition -> "iconify" to "value"
                                    SVG.definition -> "svg" to "source"
                                    else -> throw IllegalArgumentException("Expected a canonical icon.")
                                }
                            val text = (recordFields(payload).field(field) as? SkirDataValue.StringValueWrapper)?.value
                            jsonObject(
                                listOf(
                                    "kind" to jsonString(kind),
                                    "value" to jsonString(requireNotNull(text) { "Expected icon text." }),
                                ),
                            )
                        },
                    ),
            )

        fun declaredUse(id: String) =
            NamedTypeUse(
                definition = TypeDefinitionId(typeId = TypeId.DeclaredWrapper(DeclaredTypeId(value = id)), revision = 1),
                arguments = emptyList(),
            )

        fun iconValue(
            use: NamedTypeUse,
            field: String,
            text: String,
        ) = SkirDataValue.createNamed(
            actualType = use,
            payload = SkirDataValue.createRecord(fields = listOf(FieldValue(name = field, value = SkirDataValue.StringValueWrapper(text)))),
        )

        fun readId(record: String) =
            TypeDefinitionId(
                typeId = TypeId.QualifiedWrapper(QualifiedTypeId(namespace = CANONICAL_READ_NAMESPACE, name = record)),
                revision = 1,
            )

        fun recordDefinition(
            id: TypeDefinitionId,
            fields: List<Pair<String, TypeTemplate>>,
            parent: TypeDefinitionId?,
            abstract: Boolean,
        ) = TypeDefinition(
            id = id,
            parameters = emptyList(),
            representation =
                RepresentationTemplate.RecordWrapper(
                    SkirRecord(
                        fields =
                            fields.map { (name, type) ->
                                FieldDeclaration(
                                    owner = FieldOwner(definition = id, name = name),
                                    type = type,
                                    overrides = emptyList(),
                                    hasConstructorDefault = false,
                                )
                            },
                        abstract_ = abstract,
                    ),
                ),
            parents = listOfNotNull(parent?.let { NamedTypeTemplate(definition = it, arguments = emptyList()) }),
        )

        fun scalar(type: PrimitiveType): ScalarKind =
            when (type) {
                PrimitiveType.BOOL -> ScalarKind.BOOLEAN
                PrimitiveType.INT_32 -> ScalarKind.createInteger(width = IntegerWidth.SIGNED_THIRTY_TWO)
                PrimitiveType.INT_64 -> ScalarKind.createInteger(width = IntegerWidth.SIGNED_SIXTY_FOUR)
                PrimitiveType.UINT_64 -> ScalarKind.createInteger(width = IntegerWidth.UNSIGNED_SIXTY_FOUR)
                PrimitiveType.FLOAT_32 -> ScalarKind.createFloat(width = FloatWidth.THIRTY_TWO)
                PrimitiveType.FLOAT_64 -> ScalarKind.createFloat(width = FloatWidth.SIXTY_FOUR)
                PrimitiveType.TIMESTAMP -> ScalarKind.TIMESTAMP
                PrimitiveType.STRING -> ScalarKind.TEXT
                PrimitiveType.BYTES -> ScalarKind.BYTES
            }

        fun primitive(
            value: Any,
            type: PrimitiveType,
        ): SkirDataValue =
            when (type) {
                PrimitiveType.BOOL -> SkirDataValue.BooleanWrapper(value as Boolean)
                PrimitiveType.INT_32, PrimitiveType.INT_64, PrimitiveType.UINT_64 -> SkirDataValue.IntegerWrapper(value.toString())
                PrimitiveType.FLOAT_32 -> SkirDataValue.FloatWrapper((value as Float).toDouble())
                PrimitiveType.FLOAT_64 -> SkirDataValue.FloatWrapper(value as Double)
                PrimitiveType.TIMESTAMP -> SkirDataValue.TimestampWrapper(value as Instant)
                PrimitiveType.STRING -> SkirDataValue.StringValueWrapper(value as String)
                PrimitiveType.BYTES -> SkirDataValue.BytesWrapper(value as ByteString)
            }

        fun primitiveJson(
            value: SkirDataValue,
            type: PrimitiveType,
        ): String =
            when {
                type == PrimitiveType.BOOL && value is SkirDataValue.BooleanWrapper -> {
                    value.value.toString()
                }

                type == PrimitiveType.INT_32 && value is SkirDataValue.IntegerWrapper -> {
                    value.value.toInt().toString()
                }

                type == PrimitiveType.INT_64 && value is SkirDataValue.IntegerWrapper -> {
                    jsonString(value.value.toLong().toString())
                }

                type == PrimitiveType.UINT_64 && value is SkirDataValue.IntegerWrapper -> {
                    jsonString(value.value.toULong().toString())
                }

                type == PrimitiveType.FLOAT_32 && value is SkirDataValue.FloatWrapper -> {
                    value.value.toFloat().toString()
                }

                type == PrimitiveType.FLOAT_64 && value is SkirDataValue.FloatWrapper -> {
                    value.value.toString()
                }

                type == PrimitiveType.TIMESTAMP && value is SkirDataValue.TimestampWrapper -> {
                    value.value.toEpochMilli().toString()
                }

                type == PrimitiveType.STRING && value is SkirDataValue.StringValueWrapper -> {
                    jsonString(value.value)
                }

                type == PrimitiveType.BYTES && value is SkirDataValue.BytesWrapper -> {
                    jsonString(Base64.getEncoder().encodeToString(value.value.toByteArray()))
                }

                else -> {
                    throw IllegalArgumentException("The canonical value does not match its $type field.")
                }
            }

        fun jsonObject(fields: List<Pair<String, String>>): String =
            fields.joinToString(",", "{", "}") { (name, value) -> "${jsonString(name)}:$value" }

        fun jsonString(text: String): String =
            buildString {
                append('"')
                text.forEach { character ->
                    when {
                        character == '"' -> append("\\\"")
                        character == '\\' -> append("\\\\")
                        character < ' ' -> append("\\u%04x".format(character.code))
                        else -> append(character)
                    }
                }
                append('"')
            }

        fun recordFields(payload: SkirDataValue): Map<String, SkirDataValue> =
            (payload as? SkirDataValue.RecordWrapper)?.value?.fields?.associate { it.name to it.value }
                ?: throw IllegalArgumentException("Expected a canonical record.")

        fun Map<String, SkirDataValue>.field(name: String): SkirDataValue =
            this[name] ?: throw IllegalArgumentException("The canonical field $name is absent.")

        /** The value at the field [path] below a projected declared value. */
        fun select(
            value: SkirDataValue,
            path: List<String>,
        ): SkirDataValue =
            path.fold(value) { current, name ->
                val named = (current as? SkirDataValue.NamedWrapper)?.value?.payload ?: current
                recordFields(named).field(name)
            }
    }
}

private val RecordDescriptorBase.recordId: String get() = "$modulePath:$qualifiedName"

private fun TypeDefinitionId.name(): String =
    when (val type = typeId) {
        is TypeId.QualifiedWrapper -> type.value.name
        is TypeId.DeclaredWrapper -> type.value.value
        else -> ""
    }

private fun StructDescriptor.Reflective<*, *>.orderedFields(): List<StructField.Reflective<*, *, *>> = fields.sortedBy { it.number }

private fun EnumDescriptor.Reflective<*>.orderedVariants(): List<EnumVariant.Reflective<*>> =
    variants.filter { it.number != 0 }.sortedBy { it.number }

@Suppress("UNCHECKED_CAST")
private fun EnumDescriptor.Reflective<*>.variantOf(value: Any): EnumVariant.Reflective<*> {
    val variant = (this as EnumDescriptor.Reflective<Any>).getVariant(value)
    require(variant.number != 0) { "Unknown canonical enum variant." }
    return variant
}

@Suppress("UNCHECKED_CAST")
private fun StructField.Reflective<*, *, *>.read(value: Any): Any? = (this as StructField.Reflective<Any, *, *>).get(value)

@Suppress("UNCHECKED_CAST")
private fun EnumWrapperVariant.Reflective<*, *>.read(value: Any): Any? = (this as EnumWrapperVariant.Reflective<Any, *>).get(value)
