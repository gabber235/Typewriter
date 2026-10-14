package com.typewritermc.expression

import com.typewritermc.presentation.OperationDescriptor
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse

/** Typed contracts for the portable scalar formatting operations and reused text operations. */
object SharedOperationSignatures {
    val supportedIds: Set<String> =
        setOf(
            "typewriter.text.trim",
            "typewriter.text.lower",
            "typewriter.text.upper",
            "typewriter.text.title",
            "typewriter.text.replace",
            "typewriter.regex.replace",
            "typewriter.number.round_to",
            "typewriter.number.format",
            "typewriter.duration.format",
            "typewriter.timestamp.format",
        )
    private val text = TypeUse.Scalar(ScalarKind.Text)

    private fun family(type: TypeUse): String? =
        when ((type as? TypeUse.Scalar)?.kind) {
            is ScalarKind.Integer -> "integer"
            is ScalarKind.Float -> "float"
            ScalarKind.Decimal -> "decimal"
            else -> null
        }

    private fun integer(type: TypeUse): Boolean = (type as? TypeUse.Scalar)?.kind is ScalarKind.Integer

    fun resolveOrNull(
        id: OperationId,
        inputs: List<ExpressionType>,
    ): OperationDescriptor? {
        val types = inputs.map(ExpressionType::value)
        val result =
            when (id.value) {
                "typewriter.text.trim", "typewriter.text.lower", "typewriter.text.upper", "typewriter.text.title" -> {
                    text.takeIf {
                        types ==
                            listOf(text)
                    }
                }

                "typewriter.text.replace", "typewriter.regex.replace" -> {
                    text.takeIf { types == listOf(text, text, text) }
                }

                "typewriter.number.round_to" -> {
                    types.firstOrNull()?.takeIf {
                        types.size == 3 && family(it) != null &&
                            family(types[1]) == family(it) &&
                            types[2] == text
                    }
                }

                "typewriter.number.format" -> {
                    text.takeIf { types.size == 3 && family(types[0]) != null && integer(types[1]) && types[2] == text }
                }

                "typewriter.duration.format" -> {
                    text.takeIf {
                        types.size == 3 && types[0] == TypeUse.Scalar(ScalarKind.Duration) &&
                            types[1] == text &&
                            integer(types[2])
                    }
                }

                "typewriter.timestamp.format" -> {
                    text.takeIf { types == listOf(TypeUse.Scalar(ScalarKind.Timestamp), text, text, text) }
                }

                else -> {
                    null
                }
            } ?: return null
        return OperationDescriptor(id, inputs.toList(), ExpressionType(result, inputs.any(ExpressionType::mayBeMissing)))
    }
}
