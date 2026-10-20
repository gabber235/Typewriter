package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000501")
data class DefinedResource(val title: String = "") : Resource

@TypewriterType(id = "a0000000000000000000000000000502")
data class PlainValue(val title: String = "")

object Definitions {
    @TypewriterResourceDefinition("", DefinedResource::class)
    val BLANK = ResourceDefinitionId("") // error: Resource definitions require a stable id.

    @TypewriterResourceDefinition("fixture.plain", PlainValue::class)
    val PLAIN = ResourceDefinitionId("fixture.plain") // error: Resource definition roots must implement Resource.
}
