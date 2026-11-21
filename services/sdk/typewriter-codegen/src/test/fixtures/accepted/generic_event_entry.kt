package fixture

import com.typewritermc.formula.Var
import com.typewritermc.formula.VarDefinition
import com.typewritermc.identity.Protagonist
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.functionTemplate
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind

@TypewriterRecordContract
interface SampleEvent

@TypewriterRecordContract
interface SampleCancelable : SampleEvent

/** The formula context of an entry about one event: its formulas read the event's fields as `event`. */
interface SampleEventContext<E : SampleEvent> {
    val event: E
}

// An event is a Typewriter type whose subject is a protagonist.
@TypewriterType(id = "a0000000000000000000000000000921")
data class SampleBreak(
    val player: Protagonist,
) : SampleCancelable

// One entry serves every cancelable event: the event is the entry's type argument, and its Var contexts name it.
@TypewriterType(id = "a0000000000000000000000000000922")
data class SampleGuardEntry<E : SampleCancelable>(
    val condition: Var<Boolean, SampleEventContext<E>>,
    val cancel: Var<Boolean, SampleEventContext<E>>,
) : Resource

fun main(args: Array<String>) {
    val boolean = ScalarKind.BOOLEAN.template
    val event = ParameterKey(owner = SampleGuardEntryDefinition.id, index = 0).template
    val fields =
        (SampleGuardEntryDefinition.declaration.representation as RepresentationTemplate.RecordWrapper)
            .value.fields
            .associate { it.owner.name to it.type }
    val expected = VarDefinition.id.template(listOf(boolean, functionTemplate(context = listOf("event" to event), result = boolean)))
    check(fields["condition"] == expected) { fields["condition"].toString() }
    check(fields["cancel"] == expected) { fields["cancel"].toString() }

    val eventFields =
        (SampleBreakDefinition.declaration.representation as RepresentationTemplate.RecordWrapper)
            .value.fields
            .associate { it.owner.name to it.type }
    check("player" in eventFields) { eventFields.toString() }
}
