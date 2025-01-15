package com.typewritermc.processors.entry

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.getAnnotationsByType
import com.google.devtools.ksp.getDeclaredProperties
import com.google.devtools.ksp.isAnnotationPresent
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.*
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.format
import com.typewritermc.processors.fullName
import com.typewritermc.processors.serializedName
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.Transient
import kotlinx.serialization.json.*

val blueprintJson = Json {
    classDiscriminator = "kind"
    explicitNulls = false
}

@Serializable
sealed class DataBlueprint {
    companion object {
        context(KSPLogger, Resolver)
        fun blueprint(type: KSType): DataBlueprint? {
            CustomBlueprint.blueprint(type)?.let { return it }
            PrimitiveBlueprint.blueprint(type)?.let { return it }
            EnumBlueprint.blueprint(type)?.let { return it }
            ListBlueprint.blueprint(type)?.let { return it }
            MapBlueprint.blueprint(type)?.let { return it }

            ObjectBlueprint.blueprint(type)?.let { return it }
            AlgebraicBlueprint.blueprint(type)?.let { return it }
            return null
        }
    }

    val modifiers: MutableList<DataModifier.Modifier> = mutableListOf()
    protected var default: JsonElement = JsonNull
    abstract fun validateDefault(default: JsonElement): Result<Unit>

    abstract fun default(): JsonElement

    @Serializable
    @SerialName("primitive")
    data class PrimitiveBlueprint(val type: PrimitiveType) : DataBlueprint() {
        companion object {
            context(KSPLogger)
            fun blueprint(type: KSType): DataBlueprint? {
                return when (type.declaration.qualifiedName?.asString()) {
                    "kotlin.Boolean" -> PrimitiveBlueprint(PrimitiveType.BOOLEAN)
                    "java.lang.Boolean" -> PrimitiveBlueprint(PrimitiveType.BOOLEAN)
                    "kotlin.Double" -> PrimitiveBlueprint(PrimitiveType.DOUBLE)
                    "java.lang.Double" -> PrimitiveBlueprint(PrimitiveType.DOUBLE)
                    "kotlin.Float" -> PrimitiveBlueprint(PrimitiveType.DOUBLE)
                    "java.lang.Float" -> PrimitiveBlueprint(PrimitiveType.DOUBLE)
                    "kotlin.Int" -> PrimitiveBlueprint(PrimitiveType.INTEGER)
                    "java.lang.Integer" -> PrimitiveBlueprint(PrimitiveType.INTEGER)
                    "kotlin.Long" -> PrimitiveBlueprint(PrimitiveType.INTEGER)
                    "java.lang.Long" -> PrimitiveBlueprint(PrimitiveType.INTEGER)
                    "kotlin.String" -> PrimitiveBlueprint(PrimitiveType.STRING)
                    "java.lang.String" -> PrimitiveBlueprint(PrimitiveType.STRING)
                    else -> null
                }
            }
        }

        override fun validateDefault(default: JsonElement): Result<Unit> {
            if (default !is JsonPrimitive) return failure("Default value for %s needs to be a ${type.name.lowercase()} but is a ${default::class.simpleName}")
            if (type == PrimitiveType.BOOLEAN && default.booleanOrNull == null) return failure("Default value for %s is not a boolean")
            if (type == PrimitiveType.DOUBLE && default.doubleOrNull == null) return failure("Default value for %s is not a double")
            if (type == PrimitiveType.INTEGER && default.intOrNull == null) return failure("Default value for %s is not an integer")
            if (type == PrimitiveType.STRING && !default.isString) return failure("Default value for %s is not a string")
            return ok(Unit)
        }

        override fun default(): JsonElement {
            if (default != JsonNull) return default
            return type.default
        }
    }

    @Serializable
    @SerialName("enum")
    data class EnumBlueprint(val values: List<String>) : DataBlueprint() {
        companion object {
            context(KSPLogger)
            fun blueprint(type: KSType): DataBlueprint? {
                // Check if it is an enum. And if so, get the values.
                val clazz = type.declaration as? KSClassDeclaration ?: return null
                if (clazz.classKind != ClassKind.ENUM_CLASS) return null

                val values = clazz.declarations
                    .filterIsInstance<KSClassDeclaration>()
                    .filter { it.classKind == ClassKind.ENUM_ENTRY }
                    .map { it.serializedName }
                    .toList()

                return EnumBlueprint(values)
            }
        }

        override fun validateDefault(default: JsonElement): Result<Unit> {
            if (default !is JsonPrimitive) return failure("Default value for %s needs to be a string but is a ${default::class.simpleName}")
            if (!values.contains(default.content)) return failure(
                "Default value for %s is not one of the enum values, possible values are ${
                    values.joinToString(
                        ", "
                    )
                }"
            )
            return ok(Unit)
        }

        override fun default(): JsonElement {
            if (default != JsonNull) return default
            return JsonPrimitive(values.first())
        }
    }

    @Serializable
    @SerialName("list")
    data class ListBlueprint(val type: DataBlueprint) : DataBlueprint() {
        companion object {
            context(KSPLogger, Resolver)
            fun blueprint(type: KSType): ListBlueprint? {
                when (type.declaration.qualifiedName?.asString()) {
                    "kotlin.collections.List" -> {}
                    "java.util.List" -> {}
                    else -> return null
                }
                if (type.arguments.size != 1) return null
                val subType = type.arguments.firstOrNull()?.type?.resolve() ?: return null
                return ListBlueprint(DataBlueprint.blueprint(subType) ?: return null)
            }
        }

        override fun validateDefault(default: JsonElement): Result<Unit> {
            if (default !is JsonArray) return failure("Default value for %s needs to be a list but is a ${default::class.simpleName}")
            default.forEach {
                val result = type.validateDefault(it)
                if (result.isFailure) return failure("Sub element of %s is not valid, error: ${result.exceptionOrNull()}")
            }
            return ok(Unit)
        }

        override fun default(): JsonElement {
            if (default != JsonNull) return default
            return JsonArray(emptyList())
        }
    }

    @Serializable
    @SerialName("map")
    data class MapBlueprint(val key: DataBlueprint, val value: DataBlueprint) : DataBlueprint() {
        companion object {
            context(KSPLogger, Resolver)
            fun blueprint(type: KSType): MapBlueprint? {
                when (type.declaration.qualifiedName?.asString()) {
                    "kotlin.collections.Map" -> {}
                    "java.util.Map" -> {}
                    else -> return null
                }
                if (type.arguments.size != 2) return null
                val key = type.arguments.firstOrNull()?.type?.resolve() ?: return null
                val keyBlueprint = DataBlueprint.blueprint(key) ?: return null

                // Since not all key types are supported, we check if the key type is a supported type.
                // TODO: Remove in favor if linter
                when {
                    keyBlueprint is PrimitiveBlueprint && keyBlueprint.type == PrimitiveType.STRING -> {}
                    keyBlueprint is EnumBlueprint -> {}
                    keyBlueprint is CustomBlueprint && keyBlueprint.editor == "ref" -> {}
                    else -> throw InvalidKeyTypeException(type, keyBlueprint, "Strings, enums, and entry references are supported")
                }

                val value = type.arguments.lastOrNull()?.type?.resolve() ?: return null
                val valueBlueprint = DataBlueprint.blueprint(value) ?: return null
                return MapBlueprint(
                    keyBlueprint,
                    valueBlueprint
                )
            }
        }

        override fun validateDefault(default: JsonElement): Result<Unit> {
            if (default !is JsonObject) return failure("Default value for %s needs to be a map but is a ${default::class.simpleName}")
            default.forEach { (k, v) ->
                val resultKey = key.validateDefault(JsonPrimitive(k))
                if (resultKey.isFailure) return failure("Key of %s is not valid, error: ${resultKey.exceptionOrNull()}")
                val resultValue = value.validateDefault(v)
                if (resultValue.isFailure) return failure("Value of %s is not valid, error: ${resultValue.exceptionOrNull()}")
            }
            return ok(Unit)
        }

        override fun default(): JsonElement {
            if (default != JsonNull) return default
            return JsonObject(emptyMap())
        }
    }

    @Serializable
    @SerialName("object")
    data class ObjectBlueprint(val fields: Map<String, DataBlueprint>) : DataBlueprint() {
        companion object {
            context(KSPLogger, Resolver)
            @OptIn(KspExperimental::class)
            fun blueprint(type: KSType): ObjectBlueprint? {
                val clazz = type.declaration as? KSClassDeclaration ?: return null
                if (clazz.classKind != ClassKind.CLASS) return null
                val order = clazz.primaryConstructor?.parameters?.mapNotNull { it.name?.asString() } ?: emptyList()
                val fields = clazz.getDeclaredProperties()
                    .filter { it.hasBackingField && !it.isAnnotationPresent(kotlin.jvm.Transient::class) }
                    .sortedBy {
                        val index = order.indexOf(it.serializedName)
                        if (index == -1) Int.MAX_VALUE else index
                    }
                    .associateBy { it.serializedName }
                    .mapValues { (_, property) ->
                        val parameterType = property.type.resolve()
                        val blueprint = DataBlueprint.blueprint(parameterType) ?: throw CouldNotFindBlueprintException(
                            property.fullName,
                            parameterType,
                            property.location
                        )

                        applyModifiers(blueprint, property)

                        val default = property.defaultValue()
                        if (default != null) {
                            val result = blueprint.validateDefault(default)
                            if (result.isFailure) {
                                val annotation = property.annotations.first { it.shortName.asString() == "Default" }
                                throw InvalidDefaultValueException("${result.exceptionOrNull()?.message?.format(property.simpleName.asString())} at ${annotation.location.format}")
                            }
                            blueprint.default = default
                        }


                        blueprint
                    }

                return ObjectBlueprint(fields)
            }
        }

        override fun validateDefault(default: JsonElement): Result<Unit> {
            if (default !is JsonObject) return failure("Default value for %s needs to be an object but is a ${default::class.simpleName}")
            fields.forEach { (k, v) ->
                val result = v.validateDefault(default.getOrDefault(k, JsonNull))
                if (result.isFailure) return failure("Field $k of %s is not valid, error: ${result.exceptionOrNull()}")
            }
            return ok(Unit)
        }

        override fun default(): JsonElement {
            if (default != JsonNull) return default
            return JsonObject(emptyMap())
        }
    }

    @Serializable
    @SerialName("algebraic")
    data class AlgebraicBlueprint(val cases: Map<String, DataBlueprint>) : DataBlueprint() {
        companion object {
            context(KSPLogger, Resolver)
            @OptIn(KspExperimental::class)
            fun blueprint(type: KSType): DataBlueprint? {
                val clazz = type.declaration as? KSClassDeclaration ?: return null
                if (clazz.classKind != ClassKind.INTERFACE) return null
                val possibilities = clazz.getSealedSubclasses()
                    .associate {
                        val annotation = it.getAnnotationsByType(AlgebraicTypeInfo::class).firstOrNull() ?: throw IllegalArgumentException("Could not find `@AlgebraicTypeInfo` annotation for ${it.fullName}")
                        val name = annotation.name
                        val color = annotation.color
                        val icon = annotation.icon
                        val blueprint = DataBlueprint.blueprint(it.asStarProjectedType()) ?: throw IllegalArgumentException("Could not find blueprint for $name")

                        blueprint.modifiers.add(DataModifier.Modifier("color", color))
                        blueprint.modifiers.add(DataModifier.Modifier("icon", icon))

                        name to blueprint
                    }

                return AlgebraicBlueprint(possibilities)
            }
        }

        override fun validateDefault(default: JsonElement): Result<Unit> {
            val json = default as? JsonObject ?: return failure("Default value for ${this::class.simpleName} should be an object!")
            val case = json["case"] as? JsonPrimitive ?: return failure("Default value for ${this::class.simpleName} should have a case field!")
            val blueprint = cases[case.content] ?: return failure("Default value for ${this::class.simpleName} has an invalid case '$case', possible values are ${cases.keys}")
            return blueprint.validateDefault(json["value"] ?: JsonNull)
        }

        override fun default(): JsonElement {
            if (default != JsonNull) return default
            val case = cases.keys.first()
            val blueprint = cases[case] ?: throw IllegalStateException("Could not find blueprint for case '$case'")
            return JsonObject(mapOf("case" to JsonPrimitive(case), "value" to blueprint.default()))
        }
    }

    @Serializable
    @SerialName("custom")
    data class CustomBlueprint(
        val editor: String,
        val shape: DataBlueprint,
        @Transient
        val validator: (JsonElement) -> Result<Unit> = { ok(Unit) }
    ) : DataBlueprint() {
        companion object {
            context(KSPLogger, Resolver)
            fun blueprint(type: KSType): CustomBlueprint? {
                val editor = customEditors.firstOrNull { it.accept(type) } ?: return null
                return CustomBlueprint(editor.id, editor.shape(type)) {
                    editor.validateDefault(type, it)
                }.also { blueprint ->
                    blueprint.default = editor.default(type)
                    editor.modifiers(type).forEach { it.appendModifier(blueprint) }
                }
            }
        }

        override fun validateDefault(default: JsonElement): Result<Unit> = validator(default)

        override fun default(): JsonElement = default
    }
}


context(KSPLogger)
@OptIn(KspExperimental::class)
private fun KSPropertyDeclaration.defaultValue(): JsonElement? {
    val default = getAnnotationsByType(Default::class).firstOrNull() ?: return null
    try {
        return Json.parseToJsonElement(default.json)
    } catch (e: SerializationException) {
        error("The default value for ${this.fullName} is not a valid JSON value, JSON: `$default`", this)
        throw e
    }
}

fun DataBlueprint.walkAny(visitor: (DataBlueprint) -> Boolean): Boolean {
    if (visitor(this)) return true
    return when (this) {
        is DataBlueprint.PrimitiveBlueprint -> false
        is DataBlueprint.EnumBlueprint -> false
        is DataBlueprint.ListBlueprint -> type.walkAny(visitor)
        is DataBlueprint.MapBlueprint -> key.walkAny(visitor) || value.walkAny(visitor)
        is DataBlueprint.ObjectBlueprint -> fields.values.any { it.walkAny(visitor) }
        is DataBlueprint.AlgebraicBlueprint -> cases.values.any { it.walkAny(visitor) }
        is DataBlueprint.CustomBlueprint -> shape.walkAny(visitor)
    }
}

enum class PrimitiveType {
    @SerialName("boolean")
    BOOLEAN,

    @SerialName("double")
    DOUBLE,

    @SerialName("integer")
    INTEGER,

    @SerialName("string")
    STRING,
    ;

    val default: JsonPrimitive
        get() = when (this) {
            BOOLEAN -> JsonPrimitive(false)
            DOUBLE -> JsonPrimitive(0.0)
            INTEGER -> JsonPrimitive(0)
            STRING -> JsonPrimitive("")
        }
}

class CouldNotFindBlueprintException(property: String, parameter: KSType, location: Location) :
    Exception("Could not find blueprint for $property with type ${parameter.fullName} at ${location.format}")

class InvalidDefaultValueException(message: String) : Exception(message)

class InvalidKeyTypeException(type: KSType, blueprint: DataBlueprint, supported: String) :
        Exception("Invalid key type for map ${type.fullName}, supported types are $supported, but found $blueprint")

class CouldNotBuildBlueprintException(className: String) :
    Exception("Could not build blueprint for class $className")

class FailedToGenerateBlueprintException(
    klass: KSClassDeclaration,
    cause: Throwable,
) : Exception(
    """Failed Generating Blueprint for ${klass.fullName}
    |
    |Failed to generate blueprint for ${klass.fullName}:
    |${cause.message}
    |
    |Not all types are possible to be serialized to JSON.
    |Most platform specific types are not supported. Some examples are:
    | - org.bukkit.Location
    |
    |If you think this is a mistake, or don't know how to fix it, please open an issue on the Typewriter Discord.
|""".trimMargin()
)
