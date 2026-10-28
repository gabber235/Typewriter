package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LambdaTypeName
import com.squareup.kotlinpoet.ParameterSpec
import com.squareup.kotlinpoet.ParameterizedTypeName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STRING
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.TypeVariableName
import com.squareup.kotlinpoet.UNIT
import com.typewritermc.codegen.completeUseCode
import com.typewritermc.codegen.implements
import com.typewritermc.codegen.isType
import com.typewritermc.types.codegen.FieldShape
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.SdkField
import skirout.editor.v1.type_catalog.TypeTemplate
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * Setup builders. Every owning list field of a concrete owner becomes a `SetupList` typed by the list's element type,
 * and every concrete resource type gets one builder on `SetupList<T>`. `SetupList` is contravariant, so the builder
 * applies to every owning list whose element type the resource implements, wherever that list is declared; cues,
 * which have no link back to their owner, are covered the same way. A concrete realm section gets an accessor on
 * `SetupRoot` instead of a builder, because the realm creates sections. Abstract and generic types get nothing.
 */
internal object SetupEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        if (!declaration.resource || declaration.generic || declaration.abstract) return
        val lists = declaration.fields.filter { it.link?.isOwningListOfChildren == true }
        when {
            declaration.source.implements(Api.RealmSection) -> {
                if (lists.isEmpty()) return
                addType(declaration.sectionClass(lists))
                addFunction(declaration.sectionAccessor())
            }

            declaration.source isType Api.RealmRoot -> {
                Unit
            }

            else -> {
                addType(declaration.fieldsClass(lists))
                addFunction(declaration.builder(hasLists = lists.isNotEmpty()))
            }
        }
    }

    private val SdkDeclaration.builderName: String get() = names.baseName.replaceFirstChar(Char::lowercaseChar)

    /** `class BookSetup(scope) : SetupFields<Book>(scope)` with its owning lists and one property per settable field. */
    private fun SdkDeclaration.fieldsClass(lists: List<SdkField>): TypeSpec {
        val settable = fields.filter { field -> field !in lists && field.link?.isOwnerLinkOfChild != true && !field.placement }
        return TypeSpec
            .classBuilder(names.setup)
            .primaryConstructor(
                FunSpec
                    .constructorBuilder()
                    .addModifiers(KModifier.INTERNAL)
                    .addParameter("scope", Api.PartScope.parameterizedBy(selfType))
                    .build(),
            ).superclass(Api.SetupFields.parameterizedBy(selfType))
            .addSuperclassConstructorParameter("scope")
            .addProperties(lists.map { list -> list(list, "scope") })
            .addProperties(
                settable.map { field ->
                    PropertySpec
                        .builder(field.property, field.shape.setupType())
                        .mutable()
                        .delegate("field()")
                        .build()
                },
            ).build()
    }

    /** `val pages: SetupList<Page> = scope.list(BookFields.pages.path, linkUse)`. */
    private fun SdkDeclaration.list(
        list: SdkField,
        source: String,
    ): PropertySpec {
        val item = (list.template as TypeTemplate.NamedWrapper).value.arguments.single()
        return PropertySpec
            .builder(list.property, Api.SetupList.parameterizedBy(list.link!!.elementType))
            .initializer("%L.list(%T.%N.path,♢%L)", source, names.fields, list.property, context(references) { item.completeUseCode() })
            .build()
    }

    /** `fun <H> SetupList<Book>.book(key, configure: BookSetup.() -> H): H`; a type without owning lists returns its handle. */
    private fun SdkDeclaration.builder(hasLists: Boolean): FunSpec {
        val handle = Api.SetupHandle.parameterizedBy(selfType)
        val result = if (hasLists) TypeVariableName("H") else handle
        val ownerField = fields.singleOrNull { it.link?.isOwnerLinkOfChild == true }
        val placement = fields.singleOrNull { it.placement }
        val arguments =
            CodeBlock.of(
                "key,♢%T::class,♢%T.id,♢%L,♢%L,♢::%T",
                selfType,
                names.definition,
                ownerField?.let { CodeBlock.of("%T(%S,♢%S)", Api.SetupFieldName, it.property, it.name) } ?: "null",
                placement?.let { CodeBlock.of("%S", it.property) } ?: "null",
                names.setup,
            )
        return FunSpec
            .builder(builderName)
            .receiver(Api.SetupList.parameterizedBy(selfType))
            .apply { if (hasLists) addTypeVariable(TypeVariableName("H")) }
            .addParameter("key", STRING)
            .addParameter(
                ParameterSpec
                    .builder("configure", LambdaTypeName.get(receiver = names.setup, returnType = if (hasLists) result else UNIT))
                    .apply { if (!hasLists) defaultValue("{}") }
                    .build(),
            ).returns(result)
            .apply {
                if (hasLists) {
                    addStatement("return add(%L,♢configure)", arguments)
                } else {
                    addStatement("return add(%L)·{ configure();·handle }", arguments)
                }
            }.build()
    }

    /** `class LibrarySection(section)` with the section's owning lists, the receiver of its `SetupRoot` accessor. */
    private fun SdkDeclaration.sectionClass(lists: List<SdkField>): TypeSpec =
        TypeSpec
            .classBuilder(names.setupSection)
            .addAnnotation(Api.SetupDsl)
            .primaryConstructor(
                FunSpec
                    .constructorBuilder()
                    .addModifiers(KModifier.INTERNAL)
                    .addParameter("section", Api.SetupSection)
                    .build(),
            ).addProperties(lists.map { list -> list(list, "section") })
            .build()

    /** `fun <H> SetupRoot.library(configure: LibrarySection.() -> H): H`. */
    private fun SdkDeclaration.sectionAccessor(): FunSpec {
        val result = TypeVariableName("H")
        return FunSpec
            .builder(builderName)
            .receiver(Api.SetupRoot)
            .addTypeVariable(result)
            .addParameter("configure", LambdaTypeName.get(receiver = names.setupSection, returnType = result))
            .returns(result)
            .addStatement(
                "return %T(section(%T::class,♢%T.id,♢%S)).configure()",
                names.setupSection,
                selfType,
                names.definition,
                builderName,
            ).build()
    }
}

/** The type a setup assigns to a field: links become handles to the resources the setup creates. */
private fun FieldShape.setupType(): TypeName =
    when (this) {
        is FieldShape.Link -> {
            Api.SetupHandle.parameterizedBy(target).copy(nullable = native.isNullable)
        }

        is FieldShape.Nullable -> {
            value.setupType().copy(nullable = true)
        }

        is FieldShape.Sequence -> {
            (native as ParameterizedTypeName).rawType.parameterizedBy(item.setupType()).copy(nullable = native.isNullable)
        }

        is FieldShape.Mapping -> {
            (native as ParameterizedTypeName).rawType.parameterizedBy(key.setupType(), value.setupType()).copy(nullable = native.isNullable)
        }

        else -> {
            native
        }
    }
