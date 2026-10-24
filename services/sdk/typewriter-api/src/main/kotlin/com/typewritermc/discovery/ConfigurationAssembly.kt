@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.discovery

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.capability.id
import com.typewritermc.configuration.DefaultConfigurationCollectionScope
import com.typewritermc.configuration.DefaultPortableRuleCompiler
import com.typewritermc.configuration.DefaultPredicateReasoner
import com.typewritermc.configuration.PortableConstantEncoder
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.catalog.of
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integerScalar
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.diagnostic.DeclarationOrigin
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

internal data class CollectedOwnedConfiguration(
    val owned: OwnedConfiguration,
    val configuration: com.typewritermc.configuration.CollectedConfiguration,
)

internal sealed interface ConfigurationCollectionResult {
    data class Collected(
        val value: CollectedOwnedConfiguration,
    ) : ConfigurationCollectionResult

    data class Failed(
        val diagnostic: DeclarationDiagnostic,
        val evidence: CatalogCallbackFailure,
    ) : ConfigurationCollectionResult
}

internal fun collectConfiguration(
    owned: OwnedConfiguration,
    constants: PortableConstantEncoder,
): ConfigurationCollectionResult =
    try {
        ConfigurationCollectionResult.Collected(
            CollectedOwnedConfiguration(
                owned,
                owned.callback.collect(DefaultConfigurationCollectionScope(owned.target, constants)),
            ),
        )
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (cause: Exception) {
        ConfigurationCollectionResult.Failed(
            DeclarationDiagnostic.of(owned.target, "configuration_callback_failed", listOf(DeclarationOrigin(owner = owned.origin.owner))),
            CatalogCallbackFailure(owned.origin, CatalogCallback.Configuration(owned.target), cause),
        )
    }

internal fun configurationRuleDiagnostics(
    results: List<CollectedOwnedConfiguration>,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
): List<DeclarationDiagnostic> {
    val compiler = DefaultPortableRuleCompiler()
    val reasoner = DefaultPredicateReasoner()
    val recipes =
        results.flatMap { collected ->
            collected.configuration.recipes.map { recipe ->
                CollectedConfigurationRecipe(collected.owned.target, collected.owned.origin, recipe)
            }
        }
    return definitions.values.flatMap { definition ->
        val applicableOwners =
            (listOf(definition.id) + definition.transitiveAncestors(definitions).map(NamedTypeTemplate::definition)).toSet()
        recipes
            .filter { it.target in applicableOwners }
            .groupBy { it.recipe.relativePath to it.recipe.representationCondition }
            .values
            .flatMap { matching ->
                val origins = matching.map { DeclarationOrigin(owner = it.origin.owner) }.distinct()
                val structural =
                    matching.flatMap { owned ->
                        owned.recipe.rules.flatMap(compiler::validateStructure).map { diagnostic ->
                            diagnostic.copy(affected = definition.id, origins = listOf(DeclarationOrigin(owner = owned.origin.owner)))
                        }
                    }
                val subject =
                    checkedRuleSubject(
                        definition,
                        matching.first().recipe,
                        definitions,
                        catalog,
                    )
                if (subject == null) {
                    structural
                } else {
                    val compiled =
                        matching.flatMap { owned ->
                            owned.recipe.rules.map { rule -> owned to compiler.compile(rule, subject) }
                        }
                    val invalid =
                        compiled.flatMap { (owned, resolution) ->
                            (resolution as? Resolution.Invalid)?.diagnostics.orEmpty().map { diagnostic ->
                                diagnostic.copy(
                                    affected = definition.id,
                                    origins = listOf(DeclarationOrigin(owner = owned.origin.owner)),
                                )
                            }
                        }
                    val checked = compiled.mapNotNull { (_, resolution) -> (resolution as? Resolution.Ready)?.value }
                    invalid +
                        reasoner.contradictions(checked).map { diagnostic ->
                            diagnostic.copy(affected = definition.id, origins = origins)
                        }
                }
            }
    }
}

private fun checkedRuleSubject(
    definition: TypeDefinition,
    recipe: ConfigurationRecipe,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
): com.typewritermc.types.catalog.CheckedType? {
    val concrete =
        definition
            .templateAt(recipe.relativePath, definitions)
            ?.apply(emptyMap())
            ?.let { it as? Resolution.Ready }
            ?.value
            ?.let(catalog::resolve)
            ?.let { it as? Resolution.Ready }
            ?.value
    if (concrete != null) return concrete
    val representative = recipe.representationCondition?.representativeUse() ?: return null
    return (catalog.resolve(representative) as? Resolution.Ready)?.value
}

private fun RepresentationKind.representativeUse(): TypeUse? =
    when (this) {
        RepresentationKind.UNIT -> {
            ScalarKind.UNIT.use
        }

        RepresentationKind.BOOLEAN -> {
            ScalarKind.BOOLEAN.use
        }

        RepresentationKind.TEXT -> {
            ScalarKind.TEXT.use
        }

        RepresentationKind.BYTES -> {
            ScalarKind.BYTES.use
        }

        RepresentationKind.INTEGER -> {
            integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).use
        }

        RepresentationKind.FLOAT -> {
            floatScalar(FloatWidth.SIXTY_FOUR).use
        }

        RepresentationKind.DECIMAL -> {
            ScalarKind.DECIMAL.use
        }

        RepresentationKind.TIMESTAMP -> {
            ScalarKind.TIMESTAMP.use
        }

        RepresentationKind.DURATION -> {
            ScalarKind.DURATION.use
        }

        RepresentationKind.LIST -> {
            StandardTypes.list.use(listOf(ScalarKind.TEXT.use))
        }

        RepresentationKind.SET -> {
            StandardTypes.set.use(listOf(ScalarKind.TEXT.use))
        }

        RepresentationKind.MAP -> {
            StandardTypes.map.use(
                listOf(
                    ScalarKind.TEXT.use,
                    ScalarKind.TEXT.use,
                ),
            )
        }

        RepresentationKind.RECORD,
        RepresentationKind.ENUMERATION,
        RepresentationKind.LINK,
        -> {
            null
        }

        else -> {
            unknownVariant(this)
        }
    }

private data class CollectedConfigurationRecipe(
    val target: TypeDefinitionId,
    val origin: ProviderOrigin,
    val recipe: ConfigurationRecipe,
)

internal fun encodeConstant(
    expected: TypeTemplate,
    value: Any?,
    catalog: CheckedCatalog,
    bindings: com.typewritermc.types.NativeBindingRegistry,
): skirout.editor.v1.type_catalog.DataValue {
    val use =
        when (val applied = expected.apply(emptyMap())) {
            is Resolution.Ready -> applied.value
            is Resolution.Invalid -> throw IllegalArgumentException("A portable constant cannot target a free type parameter.")
        }
    val checked =
        when (val resolved = catalog.resolve(use)) {
            is Resolution.Ready -> resolved.value
            is Resolution.Invalid -> throw IllegalArgumentException("A portable constant requires a valid concrete type.")
        }
    return bindings.bind(checked).encodeGeneratedDefault(value)
}
