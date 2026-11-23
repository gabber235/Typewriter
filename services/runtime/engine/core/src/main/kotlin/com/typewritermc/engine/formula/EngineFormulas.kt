package com.typewritermc.engine.formula

import com.typewritermc.discovery.CatalogAssembly
import com.typewritermc.formula.CoreFormulas
import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.check.CatalogType
import com.typewritermc.formula.check.ExtensionName
import com.typewritermc.types.named
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.TypeDefinitionId

/**
 * What formulas on an engine call and name, fixed for one deployment: the formula functions its providers and core
 * give, and its code types by the source name formulas write.
 */
interface EngineFormulas {
    /** Every formula function called [name]. */
    fun functions(name: String): List<FormulaFunction>

    /** The code types with source name [name], each with the extension that declares it. */
    fun catalogTypeNamed(name: String): List<CatalogType>

    /** Every extension that declares a code type. */
    fun extensions(): Set<ExtensionName>

    /** The source name of the code type [id], or null when formulas have no name for it. */
    fun typeName(id: TypeDefinitionId): String?

    companion object {
        /** The formula functions and code type names of [assembly], the catalog a deployment assembled. */
        fun of(assembly: CatalogAssembly): EngineFormulas =
            AssembledFormulas(
                functions = (assembly.providers.formulas().map { it.function } + CoreFormulas.functions).groupBy { it.name },
                typeNames =
                    assembly.editorCatalog.types.groupBy(
                        { it.name },
                        { CatalogType(it.definition.id.use(), ExtensionName.of(it.extension)) },
                    ),
            )
    }
}

private class AssembledFormulas(
    private val functions: Map<String, List<FormulaFunction>>,
    private val typeNames: Map<String, List<CatalogType>>,
) : EngineFormulas {
    private val extensions = typeNames.values.flatMapTo(linkedSetOf()) { types -> types.map { it.extension } }
    private val names: Map<TypeDefinitionId, String> =
        typeNames.entries
            .flatMap { (name, types) -> types.mapNotNull { it.type.named?.definition }.map { it to name } }
            .toMap()

    override fun functions(name: String): List<FormulaFunction> = functions[name].orEmpty()

    override fun catalogTypeNamed(name: String): List<CatalogType> = typeNames[name].orEmpty()

    override fun extensions(): Set<ExtensionName> = extensions

    override fun typeName(id: TypeDefinitionId): String? = names[id]
}
