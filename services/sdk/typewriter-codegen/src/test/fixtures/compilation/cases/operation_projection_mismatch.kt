package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000304")
data class Box<T>(
    val value: T,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000305")
data class Value(
    val name: String,
)

object Resources {
    @TypewriterResourceDefinition("fixture.box", Box::class)
    val BOX = ResourceDefinitionId("fixture.box")
}

object InvalidProjection : BoxOperations<Value, String> {
    override fun BoxOperationsScope<Value, String>.operations() { }
}
