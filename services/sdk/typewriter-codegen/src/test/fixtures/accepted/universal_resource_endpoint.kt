package fixture

import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.TypewriterTypeImports

@TypewriterType(id = "a0000000000000000000000000000080")
data class UniversalSource(
    val target: Ref<UniversalTarget.Source, Resource>,
) : Resource

@ReferenceContract("a0000000000000000000000000000081")
interface UniversalTargetContract {
    interface Source : One<UniversalSource>

    interface Target : One<Resource>
}

// A universal endpoint names Resource itself, so this module states Resource's definition.
@TypewriterTypeImports(Resource::class)
object UniversalTypeImports
