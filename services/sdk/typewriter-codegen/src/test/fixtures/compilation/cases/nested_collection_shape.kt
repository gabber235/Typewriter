package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000030")
data class NestedSource(
    val targets: List<List<Ref<NestedShape.Source, NestedTarget>>>,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000031")
data class NestedTarget(
    val name: String,
) : Resource

@ReferenceContract("a0000000000000000000000000000032")
interface NestedShapeContract {
    interface Source : One<NestedSource>

    interface Target : One<NestedTarget>
}

object FixtureResources {
    @TypewriterResourceDefinition("fixture.nested_source", NestedSource::class)
    val SOURCE = ResourceDefinitionId("fixture.nested_source")

    @TypewriterResourceDefinition("fixture.nested_target", NestedTarget::class)
    val TARGET = ResourceDefinitionId("fixture.nested_target")
}
