package com.typewritermc.processors.entry

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.getAnnotationsByType
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.typewritermc.processors.SharedJsonManager
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.moduleplugin.TypewriterExtensionConfiguration
import com.typewritermc.processors.PartProcessor
import com.typewritermc.processors.annotationClassValue
import com.typewritermc.processors.fullName
import com.typewritermc.processors.serializedName
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.encodeToJsonElement

class EntryProcessor(
    private val json: SharedJsonManager,
    private val logger: KSPLogger,
    private val configuration: TypewriterExtensionConfiguration,
) : PartProcessor {
    override fun process(resolver: Resolver): List<KSAnnotated> {
        val symbols = resolver.getSymbolsWithAnnotation(Entry::class.qualifiedName!!)
        val entries = symbols.filterIsInstance<KSClassDeclaration>()
            .map { with(resolver) { generateEntryBlueprint(it) } }
            .toList()

        logger.warn("Generated blueprints for ${entries.size} entries")

        json.updateSection("entries", JsonArray(entries))

        return symbols.toList()
    }

    context(Resolver)
    @OptIn(KspExperimental::class)
    private fun generateEntryBlueprint(clazz: KSClassDeclaration): JsonElement {
        logger.info("Generating entry blueprint for ${clazz.simpleName.asString()}")
        val annotation = clazz.getAnnotationsByType(Entry::class).first()
        val dataBlueprint = clazz.fieldBlueprints()

        val blueprint = EntryBlueprint(
            id = annotation.name,
            name = annotation.name,
            description = annotation.description,
            color = annotation.color,
            icon = annotation.icon,
            className = clazz.qualifiedName?.asString() ?: throw IllegalClassTypeException(clazz.simpleName.asString()),
            extension = configuration.name,
            tags = clazz.tags,
            dataBlueprint = dataBlueprint,
            genericConstraints = clazz.genericConstraints(dataBlueprint),
            variableDataBlueprint = clazz.variableDataBlueprint(),
            contextKeys = clazz.contextKeys(),
            modifiers = clazz.getModifiers(),
        )

        return blueprintJson.encodeToJsonElement(blueprint)
    }

    @OptIn(KspExperimental::class)
    private val KSClassDeclaration.tags: List<String>
        get() {
            val clazzTags = getAnnotationsByType(Tags::class).firstOrNull()?.tags?.toList() ?: emptyList()
            val superTags: List<String> =
                getAllSuperTypes().map { it.declaration }.filterIsInstance<KSClassDeclaration>().flatMap {
                    it.getAnnotationsByType(Tags::class).firstOrNull()?.tags?.toList() ?: emptyList()
                }.toList()

            return clazzTags + superTags
        }

    context(Resolver)
    private fun KSClassDeclaration.fieldBlueprints(): DataBlueprint {
        with(logger) {
            try {
                return DataBlueprint.blueprint(this@fieldBlueprints.asStarProjectedType())
                    ?: throw CouldNotBuildBlueprintException(fullName)
            } catch (e: Throwable) {
                throw FailedToGenerateBlueprintException(this@fieldBlueprints, e)
            }
        }
    }

    context(Resolver)
    @OptIn(KspExperimental::class)
    private fun KSClassDeclaration.genericConstraints(fields: DataBlueprint): List<DataBlueprint>? {
        with(logger) {
            val data = getAnnotationsByType(GenericConstraint::class)
                .map { annotation ->
                    annotation.annotationClassValue { type }
                }
                .toList()

            if (data.isEmpty()) {
                // If any field has a generic value,
                // we want to return an empty list to indicate that the entry is generic.
                // Otherwise, we want to return null to indicate that the entry is not generic.
                val hasGenericField = fields.walkAny {
                    if (it !is DataBlueprint.CustomBlueprint) return@walkAny false
                    return@walkAny it.editor == "generic"
                }
                if (hasGenericField) return emptyList()

                return null
            }

            return data.map {
                DataBlueprint.blueprint(it) ?: throw FailedToGenerateBlueprintException(
                    it.declaration as KSClassDeclaration,
                    CouldNotBuildBlueprintException(it.fullName)
                )
            }
        }
    }


    context(Resolver)
    @OptIn(KspExperimental::class)
    private fun KSClassDeclaration.variableDataBlueprint(): DataBlueprint? {
        with(logger) {
            val data = getAnnotationsByType(VariableData::class)
                .map { it.annotationClassValue { it.type } }
                .firstOrNull() ?: return null

            val blueprint = DataBlueprint.blueprint(data) ?: throw FailedToGenerateBlueprintException(
                this@variableDataBlueprint,
                CouldNotBuildBlueprintException(data.fullName)
            )
            return blueprint
        }
    }

    context(Resolver)
    @OptIn(KspExperimental::class)
    private fun KSClassDeclaration.contextKeys(): List<ContextKey> {
        with(logger) {
            val data = getAnnotationsByType(ContextKeys::class)
                .map { it.annotationClassValue { it.klass } }
                .firstOrNull() ?: return emptyList()

            val declaration = data.declaration as? KSClassDeclaration ?: return emptyList()
            if (declaration.classKind != ClassKind.ENUM_CLASS) throw ExpectedEnumException(declaration.fullName)
            return declaration.declarations
                .filterIsInstance<KSClassDeclaration>()
                .filter { it.classKind == ClassKind.ENUM_ENTRY }
                .map {
                    val annotation = it.getAnnotationsByType(KeyType::class).firstOrNull()
                        ?: throw IllegalArgumentException("Could not find @KeyType annotation for ${it.simpleName} on ${declaration.fullName}")
                    val type = annotation.annotationClassValue { type }
                    ContextKey(
                        it.serializedName,
                        declaration.fullName,
                        DataBlueprint.blueprint(type) ?: throw FailedToGenerateBlueprintException(
                            this@contextKeys,
                            CouldNotBuildBlueprintException(type.fullName)
                        )
                    )
                }
                .toList()
        }
    }

    @OptIn(KspExperimental::class)
    private fun KSClassDeclaration.getModifiers(): List<EntryModifier> {
        val modifiers = mutableListOf<EntryModifier>()
        val annotation = this.getAnnotationsByType(Deprecated::class).firstOrNull()
        if (annotation != null) {
            modifiers.add(EntryModifier.Deprecated(annotation.message))
        }
        return modifiers
    }
}

@Serializable
private data class EntryBlueprint(
    val id: String,
    val name: String,
    val description: String,
    val color: String,
    val icon: String,
    val className: String,
    val extension: String,
    val tags: List<String>,
    val dataBlueprint: DataBlueprint,
    val genericConstraints: List<DataBlueprint>?,
    val variableDataBlueprint: DataBlueprint?,
    val contextKeys: List<ContextKey>,
    val modifiers: List<EntryModifier>,
)

@Serializable
class ContextKey(
    val name: String,
    val klassName: String,
    val blueprint: DataBlueprint,
)

@Serializable
sealed interface EntryModifier {
    @Serializable
    @SerialName("deprecated")
    class Deprecated(val reason: String) : EntryModifier
}


class IllegalClassTypeException(className: String) :
    Exception("Class $className does not have a qualified name. Entry classes must be full classes.")



class ExpectedEnumException(className: String) :
    Exception("Class $className does not have a qualified name. Context keys must be enums.")