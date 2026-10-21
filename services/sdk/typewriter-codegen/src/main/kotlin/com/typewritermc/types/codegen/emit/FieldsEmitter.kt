package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.authoring.TypedPath
import com.typewritermc.authoring.ValuePath
import com.typewritermc.codegen.completeUseCode
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.SdkField
import com.typewritermc.types.codegen.containsParameter
import com.typewritermc.types.template
import com.typewritermc.codegen.TypewriterApi as Api

/** `XFields`: one typed path per authoring field, for hand written selections, projections and checks. */
internal object FieldsEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        addType(
            TypeSpec
                .objectBuilder(declaration.names.fields)
                .addProperties(declaration.fields.map { field -> declaration.fieldPath(field) })
                .build(),
        )
    }

    private fun SdkDeclaration.fieldPath(field: SdkField): PropertySpec =
        context(references) {
            val owner = names.definition
            if (field.template.containsParameter) {
                PropertySpec
                    .builder(field.property, Api.GenericField.parameterizedBy(starType))
                    .initializer("%T(%T.id,♢%L,♢%L)", Api.GenericField, owner, field.valuePath(), field.template.kotlinCode())
                    .build()
            } else {
                PropertySpec
                    .builder(field.property, TypedPath::class.asClassName().parameterizedBy(starType, field.shape.native))
                    .initializer("%M(%T.id,♢%L,♢%L)", TYPED_PATH, owner, field.valuePath(), field.template.completeUseCode())
                    .build()
            }
        }
}

/** `ValuePath().field("name")`: the path of one field, built with the same API as hand written code. */
internal fun SdkField.valuePath(): CodeBlock = CodeBlock.of("%T().%M(%S)", ValuePath::class, VALUE_PATH_FIELD, name)

private val TYPED_PATH = MemberName(ValuePath::class.asClassName().packageName, "typedPath")
private val VALUE_PATH_FIELD = MemberName(ValuePath::class.asClassName().packageName, "field", isExtension = true)
