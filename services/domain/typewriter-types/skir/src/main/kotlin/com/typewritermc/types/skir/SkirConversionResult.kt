package com.typewritermc.types.skir

sealed interface SkirConversionResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : SkirConversionResult<Value>

    data class Failure(
        val diagnostics: List<SkirConversionDiagnostic>,
    ) : SkirConversionResult<Nothing>
}

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
