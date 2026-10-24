package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000089")
data class NavigationResource(val title: String = "") : Resource

@TypewriterResourceDefinition("fixture.invalid", NavigationResource::class, "typewriter.book")
val INVALID = ResourceDefinitionId("fixture.invalid")
