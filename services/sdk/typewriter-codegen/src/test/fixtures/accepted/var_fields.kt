package fixture

import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Formula
import com.typewritermc.formula.Var
import com.typewritermc.formula.VarDefinition
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.functionTemplate
import com.typewritermc.types.integerScalar
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate

interface SampleContext {
    val chain: Int
}

// A Var's second argument is a scope in Kotlin and a function type in the catalog: its context slots are the scope's
// properties and its result is the Var's value type.
@TypewriterType(id = "a0000000000000000000000000000911")
data class VarSample<T>(
    val amount: Var<Int, DefinitionScope>,
    val generic: Var<T, DefinitionScope>,
    val scorer: Var<(level: Int) -> Int, DefinitionScope>,
    val needsContext: Var<Int, SampleContext>,
) : Resource

fun main(args: Array<String>) {
    val int = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
    val fields = (VarSampleDefinition.declaration.representation as RepresentationTemplate.RecordWrapper).value.fields.associate { it.owner.name to it.type }
    val generic = ParameterKey(owner = VarSampleDefinition.id, index = 0).template
    val scorer = functionTemplate(parameters = listOf("level" to int), result = int)
    check(fields["amount"] == VarDefinition.id.template(listOf(int, functionTemplate(result = int)))) { fields["amount"].toString() }
    check(fields["generic"] == VarDefinition.id.template(listOf(generic, functionTemplate(result = generic)))) { fields["generic"].toString() }
    check(fields["scorer"] == VarDefinition.id.template(listOf(scorer, functionTemplate(result = scorer)))) { fields["scorer"].toString() }
    check(fields["needsContext"] == VarDefinition.id.template(listOf(int, functionTemplate(context = listOf("chain" to int), result = int)))) {
        fields["needsContext"].toString()
    }

    val computed: Var<Int, DefinitionScope> = Var.Computed(Formula("level * 2"))
    val source =
        when (computed) {
            is Var.Computed -> computed.formula.source
            is Var.Value -> computed.value.toString()
        }
    check(source == "level * 2")
}
