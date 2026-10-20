package fixture

import com.typewritermc.operations.noInput
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000561")
data class Counter(
    val count: Int = 0,
    val start: Int = 0,
    val end: Int = 0,
) : Resource

object CounterInspector : CounterPresentation {
    override fun CounterPresentationScope.present() {
        count {
            numericInput {
                label("Count") // error: cannot be called in this context with an implicit receiver.
            }
        }
    }
}

object CounterRules : CounterConfiguration {
    override fun CounterConfigurationScope.configure() {
        start {
            end { } // error: cannot be called in this context with an implicit receiver.
        }
    }
}

object ResetOperations : CounterOperations {
    override fun CounterOperationsScope.operations() {
        operation("reset", noInput()) {
            operation("nested", noInput()) { } // error: cannot be called in this context with an implicit receiver.
        }
    }
}
