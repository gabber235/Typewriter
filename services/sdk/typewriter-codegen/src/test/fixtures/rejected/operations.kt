package fixture

import com.typewritermc.authoring.DraftList
import com.typewritermc.operations.PreparedOperation
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000531")
data class Box<T>(
    val value: T,
) : Resource

object StarOperation : BoxOperation<*, *, Unit> { // error: Resource operations require closed native and projection arguments without stars.
    override fun BoxOperationSpec<*, *, Unit>.declare(): PreparedOperation = prepare { }
}

object OpenListOperation : BoxOperation<List<*>, DraftList<*>, Unit> { // error: Resource operations require a supported closed resource application.
    override fun BoxOperationSpec<List<*>, DraftList<*>, Unit>.declare(): PreparedOperation = prepare { }
}
