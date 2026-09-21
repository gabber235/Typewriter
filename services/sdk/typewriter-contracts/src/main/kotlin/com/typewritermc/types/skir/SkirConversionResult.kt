package com.typewritermc.types.skir

/**
 * Typed outcome of conversion between portable Typewriter models and generated Skir values. Failures describe
 * unsupported representations with a traversal path. Only explicitly reported conversion failures become
 * diagnostics; unrelated exceptions propagate.
 */
sealed interface SkirConversionResult<out Value> {
    /** Contains the converted value when the complete traversal succeeded. */
    data class Success<Value>(
        val value: Value,
    ) : SkirConversionResult<Value>

    /** Contains conversion diagnostics and no partial converted value. */
    data class Failure(
        val diagnostics: List<SkirConversionDiagnostic>,
    ) : SkirConversionResult<Nothing>
}

/** Identifies one unsupported or invalid value at a conversion traversal path. */
data class SkirConversionDiagnostic(
    val path: List<String>,
    val message: String,
) {
    override fun toString(): String = "${path.joinToString(" -> ")}: $message"
}

internal inline fun <Value> captureSkirConversion(block: ConversionScope.() -> Value): SkirConversionResult<Value> =
    try {
        SkirConversionResult.Success(ConversionScope().block())
    } catch (failure: ConversionFailure) {
        SkirConversionResult.Failure(listOf(failure.diagnostic))
    }

internal class ConversionScope {
    private val path = ArrayDeque<String>()

    inline fun <Value> at(
        segment: String,
        block: () -> Value,
    ): Value {
        path.addLast(segment)
        return try {
            block()
        } finally {
            path.removeLast()
        }
    }

    fun fail(message: String): Nothing = throw ConversionFailure(SkirConversionDiagnostic(path.toList(), message))
}

internal class ConversionFailure(
    val diagnostic: SkirConversionDiagnostic,
) : RuntimeException(diagnostic.toString())
