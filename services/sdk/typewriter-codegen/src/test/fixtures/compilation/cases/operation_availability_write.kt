package fixture

import com.typewritermc.library.TagOperations
import com.typewritermc.library.TagOperationsScope
import com.typewritermc.operations.*

object InvalidOperations : TagOperations {
    override fun TagOperationsScope.operations() {
        operation("invalid", noInput()) {
            label("Invalid")
            availability {
                subjects.first().setName("cannot mutate availability")
                OperationAvailability.Enabled
            }
            prepare { }
        }
    }
}
