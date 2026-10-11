package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000080")
data class UniversalSource(
    val target: Ref<UniversalTarget.Source, Resource>,
) : Resource

@ReferenceContract("a0000000000000000000000000000081")
interface UniversalTargetContract {
    interface Source : One<UniversalSource>

    interface Target : One<Resource>
}

object FixtureResources {
    @TypewriterResourceDefinition("fixture.universal_source", UniversalSource::class)
    val SOURCE = ResourceDefinitionId("fixture.universal_source")
}
