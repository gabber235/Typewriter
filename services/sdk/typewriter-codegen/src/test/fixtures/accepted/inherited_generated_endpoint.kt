package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.TypewriterTypeImports

@TypewriterRecordContract
interface Parent : Resource {
    val target: Ref<InheritedTargets.Source, Target>
}

interface Child : Parent

@TypewriterType(id = "a0000000000000000000000000000088")
data class Target(val name: String) : Resource

object FixtureResources {
    @TypewriterResourceDefinition("fixture.target", Target::class)
    val TARGET = ResourceDefinitionId("fixture.target")
}

@ReferenceContract("fixture.inherited.targets")
interface InheritedTargetsContract {
    interface Source : Many<Parent>
    interface Target : One<fixture.Target>
}

@TypewriterTypeImports(Child::class)
object ImportedTypes
