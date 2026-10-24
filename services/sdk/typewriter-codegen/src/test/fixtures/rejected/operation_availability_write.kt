package fixture

import com.typewritermc.library.TagOperations
import com.typewritermc.library.TagOperationsScope
import com.typewritermc.operations.*

object InvalidOperations : TagOperations {
    override fun TagOperationsScope.operations() {
        operation("invalid", noInput()) {
            label("Invalid")
            availability {
                subjects.first().setName("cannot mutate availability") // error: No context argument for 'edits: EditContext' found. // error: can only be called from a coroutine or another suspend function.
                OperationAvailability.Enabled
            }
            prepare { }
        }
    }
}
