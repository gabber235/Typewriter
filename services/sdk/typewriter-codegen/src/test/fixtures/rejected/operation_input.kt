package fixture

import com.typewritermc.operations.PreparedOperation
import com.typewritermc.operations.ResourceOperation
import com.typewritermc.operations.ResourceOperationSpec

/** Not a `@TypewriterType`, so it has no portable type. */
data class PlainInput(
    val name: String,
)

object TextInputOperation : ResourceOperation<String> { // error: Operation input must be Unit or a closed application of a @TypewriterType.
    override fun ResourceOperationSpec<String>.declare(): PreparedOperation = prepare { }
}

object PlainInputOperation : ResourceOperation<PlainInput> { // error: Operation input must be Unit or a closed application of a @TypewriterType.
    override fun ResourceOperationSpec<PlainInput>.declare(): PreparedOperation = prepare { }
}
