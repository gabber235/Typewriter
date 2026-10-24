package fixture

import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000020")
data class BoundSource(
    val target: Ref<TargetBounds.Source, WrongTarget>, // error: Relation endpoint fixture.TargetBounds.Source does not accept target fixture.WrongTarget.
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

