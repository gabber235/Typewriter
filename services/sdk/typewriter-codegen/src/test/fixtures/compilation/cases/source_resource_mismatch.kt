package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000010")
data class DeclaredSource(
    val name: String,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000011")
data class DeclaredTarget(
    val name: String,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000012")
data class WrongSource(
    val target: Ref<SourceMismatch.Source, DeclaredTarget>,
) : Resource

@ReferenceContract("a0000000000000000000000000000013")
interface SourceMismatchContract {
    interface Source : One<DeclaredSource>

    interface Target : One<DeclaredTarget>
}

object FixtureResources {
    @TypewriterResourceDefinition("fixture.declared_source", DeclaredSource::class)
    val SOURCE = ResourceDefinitionId("fixture.declared_source")

    @TypewriterResourceDefinition("fixture.declared_target", DeclaredTarget::class)
    val TARGET = ResourceDefinitionId("fixture.declared_target")

    @TypewriterResourceDefinition("fixture.wrong_source", WrongSource::class)
    val WRONG = ResourceDefinitionId("fixture.wrong_source")
}
