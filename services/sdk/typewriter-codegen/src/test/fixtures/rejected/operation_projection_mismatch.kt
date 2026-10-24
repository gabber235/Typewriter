package fixture

import com.typewritermc.operations.PreparedOperation
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000304")
data class Box<T>(
    val value: T,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000305")
data class Value(
    val name: String,
)

object InvalidProjection : BoxOperation<Value, String, Unit> { // error: Resource operation projection arguments must match their native arguments: expected fixture.ValueDraft.
    override fun BoxOperationSpec<Value, String, Unit>.declare(): PreparedOperation = prepare { }
}
