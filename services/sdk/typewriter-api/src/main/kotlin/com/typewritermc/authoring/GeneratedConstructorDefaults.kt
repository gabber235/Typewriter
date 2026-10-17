package com.typewritermc.authoring

import com.typewritermc.types.FieldOwner
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.TypeUse
import com.typewritermc.types.encodeGeneratedDefault
import kotlinx.coroutines.CancellationException
import java.lang.reflect.InvocationTargetException
import kotlin.reflect.KClass
import kotlin.reflect.KParameter
import kotlin.reflect.full.primaryConstructor

/** Generated constructor identity, applied field type, and native accessor, in primary constructor order. */
class GeneratedConstructorField<T : Any>(
    val owner: FieldOwner,
    val sourceName: String,
    val hasDefault: Boolean,
    val type: (AppliedNativeArguments) -> TypeUse,
    val read: (T) -> Any?,
)

/**
 * Retains constructor metadata with its generated provider. Applied codecs are resolved anew from each capture's
 * catalog. Creating the plan validates generated metadata without running a user constructor.
 */
fun <T : Any> KClass<T>.constructorDefaults(
    fields: List<GeneratedConstructorField<T>>,
    allowedOpaqueArguments: Set<Int> = emptySet(),
): NativeConstructionPlan = GeneratedNativeConstructionPlan(this, fields, allowedOpaqueArguments)

/**
 * Evaluates omitted Kotlin defaults with one optional argument invocation per capture. Native codecs can construct
 * nested arguments separately. Complete stored values continue to use generated direct construction.
 */
private class GeneratedNativeConstructionPlan<T : Any>(
    type: KClass<T>,
    fields: List<GeneratedConstructorField<T>>,
    allowedOpaqueArguments: Set<Int>,
) : NativeConstructionPlan {
    private val allowedOpaqueArguments = allowedOpaqueArguments.toSet()
    private val fields = fields.toList()
    private val constructor = type.primaryConstructor ?: metadataFailure(type, "No primary constructor is available.")
    private val parameters =
        this.fields.map { field ->
            constructor.parameters.singleOrNull { it.name == field.sourceName }
                ?: metadataFailure(type, "No primary constructor parameter matches ${field.owner} (${field.sourceName}).")
        }

    override val defaultedFields: Set<FieldOwner> = fields.filter { it.hasDefault }.mapTo(linkedSetOf()) { it.owner }

    init {
        if (fields.map { it.owner }.distinct().size != fields.size ||
            parameters.map { it.index } != parameters.map { it.index }.distinct().sorted()
        ) {
            metadataFailure(type, "Generated constructor fields must have unique identities in primary constructor order.")
        }
        constructor.parameters.filter { it !in parameters }.forEach { parameter ->
            if (!parameter.isOptional) {
                metadataFailure(type, "Unstored constructor parameter ${parameter.name} must have a Kotlin default.")
            }
        }
        fields.zip(parameters).forEach { (field, parameter) ->
            if (parameter.kind != KParameter.Kind.VALUE || parameter.name != field.sourceName ||
                parameter.isOptional != field.hasDefault
            ) {
                metadataFailure(type, "Generated constructor metadata disagrees for ${field.owner} (${field.sourceName}).")
            }
        }
    }

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        val known = fields.mapTo(hashSetOf()) { it.owner }
        val unknown = supplied.keys - known
        val missing = fields.filter { !it.hasDefault && it.owner !in supplied }
        if (unknown.isNotEmpty() || missing.isNotEmpty()) {
            return CaptureResult.Unavailable(
                unknown.map { InitializationDiagnostic(it, "unknown_constructor_input", "The constructor has no matching field.") } +
                    missing.map {
                        InitializationDiagnostic(it.owner, "missing_constructor_input", "A required constructor input is unavailable.")
                    },
            )
        }
        val omitted = defaultedFields - supplied.keys
        if (omitted.isEmpty()) return CaptureResult.Captured(emptyMap())
        var activeField: FieldOwner? = null
        return try {
            arguments.requireOpaqueCompatibility(allowedOpaqueArguments)
            val codecs =
                fields.associate { field ->
                    activeField = field.owner
                    field.owner to arguments.resolver.bind(field.type(arguments))
                }
            val callArguments =
                buildMap<KParameter, Any?> {
                    fields.forEachIndexed { index, field ->
                        supplied[field.owner]?.let { input ->
                            activeField = field.owner
                            put(parameters[index], codecs.getValue(field.owner).decode(input))
                        }
                    }
                }
            activeField = null
            val instance = constructor.callBy(callArguments)
            CaptureResult.Captured(
                fields.filter { it.owner in omitted }.associate { field ->
                    activeField = field.owner
                    field.owner to codecs.getValue(field.owner).encodeGeneratedDefault(field.read(instance))
                },
            )
        } catch (failure: Exception) {
            val cause = failure.invocationCause()
            if (cause is CancellationException || cause is Error) throw cause
            CaptureResult.Unavailable(
                listOf(
                    InitializationDiagnostic(
                        activeField,
                        (cause as? NativeBindingException)?.code ?: "native_default_capture_failed",
                        cause.message ?: "Native constructor preparation failed with ${cause::class.qualifiedName}.",
                    ),
                ),
            )
        }
    }
}

private tailrec fun Throwable.invocationCause(): Throwable =
    if (this is InvocationTargetException && targetException != null) targetException.invocationCause() else this

private fun metadataFailure(
    type: KClass<*>,
    message: String,
): Nothing = throw NativeBindingException("invalid_constructor_metadata", "${type.qualifiedName}: $message")
