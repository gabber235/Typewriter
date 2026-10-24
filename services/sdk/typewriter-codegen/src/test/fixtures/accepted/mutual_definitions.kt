package fixture

import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypewriterType

// Each definition's fields name the other, so loading either definition reads the other's id during initialization.
@TypewriterType(id = "a0000000000000000000000000000551")
data class Left(val right: Right? = null)

@TypewriterType(id = "a0000000000000000000000000000552")
data class Right(val left: Left? = null)

fun main(args: Array<String>) {
    val right = (LeftDefinition.declaration.representation as RepresentationTemplate.Record).fields.single().type
    val left = (RightDefinition.declaration.representation as RepresentationTemplate.Record).fields.single().type
    check(right == TypeTemplate.Nullable(TypeTemplate.Named(RightDefinition.id)))
    check(left == TypeTemplate.Nullable(TypeTemplate.Named(LeftDefinition.id)))
    check(LeftFields.right.owner == LeftDefinition.id)
}
