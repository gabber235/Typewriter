package fixture

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
    val target: Ref<SourceMismatch.Source, DeclaredTarget>, // error: Relation endpoint fixture.SourceMismatch.Source does not accept source fixture.WrongSource.
) : Resource

@ReferenceContract("a0000000000000000000000000000013")
interface SourceMismatchContract {
    interface Source : One<DeclaredSource>

    interface Target : One<DeclaredTarget>
}

