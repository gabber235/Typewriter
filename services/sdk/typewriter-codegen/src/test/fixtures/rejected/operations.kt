package fixture

import com.typewritermc.authoring.DraftList
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000531")
data class Box<T>(
    val value: T,
) : Resource

object Resources {
    @TypewriterResourceDefinition("fixture.box", Box::class)
    val BOX = ResourceDefinitionId("fixture.box")
}

object StarOperations : BoxOperations<*, *> { // error: Resource operations require closed native and projection arguments without stars.
    override fun BoxOperationsScope<*, *>.operations() { }
}

object OpenListOperations : BoxOperations<List<*>, DraftList<*>> { // error: Resource operations require a supported closed resource application.
    override fun BoxOperationsScope<List<*>, DraftList<*>>.operations() { }
}
