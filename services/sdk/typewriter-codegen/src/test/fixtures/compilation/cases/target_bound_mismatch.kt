package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000020")
data class BoundSource(
    val target: Ref<TargetBounds.Source, WrongTarget>,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000021")
data class ExpectedTarget(
    val name: String,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000022")
data class WrongTarget(
    val name: String,
) : Resource

@ReferenceContract("a0000000000000000000000000000023")
interface TargetBoundsContract {
    interface Source : One<BoundSource>

    interface Target : One<ExpectedTarget>
}

object FixtureResources {
    @TypewriterResourceDefinition("fixture.bound_source", BoundSource::class)
    val SOURCE = ResourceDefinitionId("fixture.bound_source")

    @TypewriterResourceDefinition("fixture.expected_target", ExpectedTarget::class)
    val EXPECTED = ResourceDefinitionId("fixture.expected_target")

    @TypewriterResourceDefinition("fixture.wrong_target", WrongTarget::class)
    val WRONG = ResourceDefinitionId("fixture.wrong_target")
}
