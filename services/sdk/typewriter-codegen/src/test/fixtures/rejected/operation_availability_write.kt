package fixture

import com.typewritermc.library.TagOperation
import com.typewritermc.library.TagOperationSpec
import com.typewritermc.operations.*
import skirout.editor.v1.operation.OperationAvailability

object InvalidOperation : TagOperation<Unit> {
    override fun TagOperationSpec<Unit>.declare(): PreparedOperation {
        availableWhen {
            drafts.first().setName("cannot mutate availability") // error: No context argument for 'edits: EditContext' found. // error: can only be called from a coroutine or another suspend function.
            OperationAvailability.ENABLED
        }
        return prepare { }
    }
}
