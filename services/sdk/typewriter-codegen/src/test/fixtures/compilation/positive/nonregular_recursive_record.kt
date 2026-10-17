package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000050")
data class RecursiveSource(
    val nested: Nest<String> = Nest(),
) : Resource

@TypewriterType(id = "a0000000000000000000000000000051")
data class Nest<T>(
    val value: T? = null,
    val next: Nest<List<T>>? = null,
)

object FixtureResources {
    @TypewriterResourceDefinition("fixture.recursive_source", RecursiveSource::class)
    val SOURCE = ResourceDefinitionId("fixture.recursive_source")
}
