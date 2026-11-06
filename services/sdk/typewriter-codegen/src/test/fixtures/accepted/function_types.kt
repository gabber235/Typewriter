package fixture

import com.typewritermc.types.TypewriterType
import com.typewritermc.types.functionTemplate
import com.typewritermc.types.integerScalar
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind

// A function type keeps its parameter names; a single unnamed parameter is named it.
@TypewriterType(id = "a0000000000000000000000000000921")
data class Scoring(
    val scorer: (level: Int) -> Int,
    val single: (Int) -> Int,
    val constant: () -> String,
)

fun main(args: Array<String>) {
    val int = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
    val fields = (ScoringDefinition.declaration.representation as RepresentationTemplate.RecordWrapper).value.fields.associate { it.owner.name to it.type }
    check(fields["scorer"] == functionTemplate(parameters = listOf("level" to int), result = int)) { fields["scorer"].toString() }
    check(fields["single"] == functionTemplate(parameters = listOf("it" to int), result = int)) { fields["single"].toString() }
    check(fields["constant"] == functionTemplate(result = ScalarKind.TEXT.template)) { fields["constant"].toString() }
}
