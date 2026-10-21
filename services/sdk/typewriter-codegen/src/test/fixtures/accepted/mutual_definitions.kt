package fixture

import skirout.editor.v1.type_catalog.RepresentationTemplate
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.template
import com.typewritermc.types.nullable

// Each definition's fields name the other, so loading either definition reads the other's id during initialization.
@TypewriterType(id = "a0000000000000000000000000000551")
data class Left(val right: Right? = null)

@TypewriterType(id = "a0000000000000000000000000000552")
data class Right(val left: Left? = null)

fun main(args: Array<String>) {
    val right = (LeftDefinition.declaration.representation as RepresentationTemplate.RecordWrapper).value.fields.single().type
    val left = (RightDefinition.declaration.representation as RepresentationTemplate.RecordWrapper).value.fields.single().type
    check(right == RightDefinition.id.template().nullable())
    check(left == LeftDefinition.id.template().nullable())
    check(LeftFields.right.owner == LeftDefinition.id)
}
