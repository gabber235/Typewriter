package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.LIST
import com.squareup.kotlinpoet.MAP
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.SET
import com.squareup.kotlinpoet.TypeName
import com.typewritermc.types.codegen.FieldShape
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.SdkField
import skirout.editor.v1.type_catalog.CollectionKind
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * The accessors of a record type: one extension property per field on `RecordScope<X>`, each reading through the entry
 * reader at the field's path below the scope. A `Var<T, C>` field reads as `T`; a record field gives the record's scope
 * one level deeper; a list, set or map of records gives one scope per item, in stored order; any other field reads as
 * stored. So `spoken.minLines` and `options[0].text` read at any depth.
 */
internal object ScopeEmitter : SdkEmitter {
    /** The members of `RecordScope` and `EntryScope`; a field of one of these names would never reach its accessor. */
    val SCOPE_MEMBERS: Set<String> = setOf("entryScope", "recordPath", "entry", "subject", "context", "reader")

    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        if (!declaration.record) return
        val receiver = Api.RecordScope.parameterizedBy(declaration.selfType)
        declaration.fields.forEach { field ->
            val (type, read) = field.access(declaration)
            addProperty(
                PropertySpec
                    .builder(field.property, type)
                    .addTypeVariables(declaration.typeVariables)
                    .receiver(receiver)
                    .getter(FunSpec.getterBuilder().addStatement("return %L", read).build())
                    .build(),
            )
        }
    }

    /** The accessor's type and the read that gives it. */
    private fun SdkField.access(declaration: SdkDeclaration): Pair<TypeName, CodeBlock> {
        val path = CodeBlock.of("%T.%N", declaration.names.fields, property)
        val (member, type) =
            (shape as? FieldShape.Nullable)?.value?.let(::optionalAccess) ?: requiredAccess(shape)
                ?: (Api.readField to shape.native)
        return type to CodeBlock.of("%M(%L)", member, path)
    }

    /** The read and type of a nullable field holding [held]: a `Var` as its nullable value, a record as an optional scope. */
    private fun optionalAccess(held: FieldShape): Pair<MemberName, TypeName>? =
        when {
            held is FieldShape.Record && held.isVar -> {
                Api.readField to
                    held.arguments
                        .first()
                        .native
                        .copy(nullable = true)
            }

            held is FieldShape.Record -> {
                Api.optionalRecordField to scopeOf(held).copy(nullable = true)
            }

            else -> {
                null
            }
        }

    /** The read and type of a field that always holds [shape]; null for a field that reads as stored. */
    private fun requiredAccess(shape: FieldShape): Pair<MemberName, TypeName>? =
        when {
            shape is FieldShape.Record && shape.isVar -> {
                Api.readField to shape.arguments.first().native
            }

            shape is FieldShape.Record -> {
                Api.recordField to scopeOf(shape)
            }

            shape is FieldShape.Sequence && shape.item.isScoped -> {
                sequenceAccess(shape.kind, scopeOf(shape.item as FieldShape.Record))
            }

            shape is FieldShape.Mapping && shape.value.isScoped -> {
                Api.recordMap to MAP.parameterizedBy(shape.key.native, scopeOf(shape.value as FieldShape.Record))
            }

            else -> {
                null
            }
        }

    private fun sequenceAccess(
        kind: CollectionKind,
        item: TypeName,
    ): Pair<MemberName, TypeName> =
        if (kind == CollectionKind.SET) Api.recordSet to SET.parameterizedBy(item) else Api.recordList to LIST.parameterizedBy(item)

    private val FieldShape.Record.isVar: Boolean get() = names.source == Api.Var

    /** A record item a collection accessor gives a scope for: present, and not a `Var`. */
    private val FieldShape.isScoped: Boolean get() = this is FieldShape.Record && !isVar

    private fun scopeOf(record: FieldShape.Record): TypeName = Api.RecordScope.parameterizedBy(record.native.copy(nullable = false))
}
