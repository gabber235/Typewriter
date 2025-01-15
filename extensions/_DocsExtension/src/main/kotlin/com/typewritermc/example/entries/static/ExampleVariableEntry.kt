package com.typewritermc.example.entries.static

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.*

//<code-block:variable_entry>
@Entry("example_variable", "An example variable entry.", Colors.GREEN, "mdi:code-tags")
class ExampleVariableEntry(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val klass = context.klass

        TODO("Do something with the player and the klass")
    }
}
//</code-block:variable_entry>

//<code-block:variable_entry_with_data>
@Entry("example_variable_with_data", "An example variable entry with data.", Colors.GREEN, "mdi:code-tags")
// Register the variable data associated with this variable.
@VariableData(ExampleVariableWithData::class)
class ExampleVariableWithDataEntry(
    override val id: String = "",
    override val name: String = "",
    // This data will be the same for all uses of this variable.
    val someString: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val klass = context.klass
        this.someString
        val data = context.getData<ExampleVariableWithData>() ?: throw IllegalStateException("Could not find data for ${context.klass}, data: ${context.data}")

        TODO("Do something with the player, the klass, and the data")
    }
}

class ExampleVariableWithData(
    // This data can change at the place where the variable is used.
    val otherInfo: Int = 0,
)
//</code-block:variable_entry_with_data>

//<code-block:generic_variable_entry>
@Entry("example_generic_variable", "An example generic variable entry.", Colors.GREEN, "mdi:code-tags")
class ExampleGenericVariableEntry(
    override val id: String = "",
    override val name: String = "",
    // We determine how to parse this during runtime.
    val generic: Generic = Generic.Empty,
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val klass = context.klass

        // Parse the generic data to the correct type.
        val data = generic.get(klass)

        TODO("Do something with the player, the klass, and the generic")
    }
}

class ExampleGenericVariableData(
    // Generic data will always be the same as the generic type in the variable.
    val otherGeneric: Generic,
)
//</code-block:generic_variable_entry>

//<code-block:constraint_variable_entry>
@Entry("example_constraint_variable", "An example constraint variable entry.", Colors.GREEN, "mdi:code-tags")
@GenericConstraint(String::class)
@GenericConstraint(Int::class)
class ExampleConstraintVariableEntry(
    override val id: String = "",
    override val name: String = "",
    // We determine how to parse this during runtime.
    val generic: Generic = Generic.Empty,
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        // This can only be a String or an Int.
        val klass = context.klass

        // Parse the generic data to the correct type.
        val data = generic.get(klass)

        TODO("Do something with the player, the klass, and the generic")
    }
}
//</code-block:constraint_variable_entry>

//<code-block:variable_usage>
@Entry("example_action_using_variable", "An example action that uses a variable.", Colors.RED, "material-symbols:touch-app-rounded")
class ExampleActionUsingVariableEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    val someString: Var<String> = ConstVar(""),
    val someInt: Var<Int> = ConstVar(0),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val someString = someString.get(player)
        val someInt = someInt.get(player)

        // Do something with the variables
    }
}
//</code-block:variable_usage>