package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType

interface Marker

@TypewriterRecordContract
interface AcceptedTarget : Resource {
    val name: String
}

@TypewriterType(id = "a0000000000000000000000000000040")
data class GenericSource<T>(
    val target: Ref<IntersectionBound.Source, T>,
) : Resource where T : AcceptedTarget, T : Marker

@ReferenceContract("a0000000000000000000000000000041")
interface IntersectionBoundContract {
    interface Source : One<GenericSource<*>>

    interface Target : One<AcceptedTarget>
}

object FixtureResources {
    @TypewriterResourceDefinition("fixture.generic_source", GenericSource::class)
    val SOURCE = ResourceDefinitionId("fixture.generic_source")
}
