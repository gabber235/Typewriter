package com.typewritermc.types

import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResolvedRecordForm
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId

/*
 * A record is concrete, open or closed. A concrete record has values of its own; an open record accepts any subtype
 * that names it as a parent; a closed record accepts only the cases it lists, in their declared order. An enum is a
 * closed record whose cases are all unit, and its value is the case itself: a named unit value whose actual type is
 * the case's member id.
 */

/** The cases this closed record lists, or null when this is not a closed record. */
fun RepresentationTemplate.closedCases(): List<NamedTypeTemplate>? =
    ((this as? RepresentationTemplate.RecordWrapper)?.value?.form as? RecordForm.ClosedWrapper)?.value?.cases

/** The applied cases this closed record lists, or null when this is not a closed record. */
fun ResolvedRepresentation.closedCases(): List<NamedTypeUse>? =
    ((this as? ResolvedRepresentation.RecordWrapper)?.value?.form as? ResolvedRecordForm.ClosedWrapper)?.value?.cases

/** False for an open or closed record, whose values always carry one of its subtypes. */
fun RepresentationTemplate.isInstantiable(): Boolean =
    (this as? RepresentationTemplate.RecordWrapper)?.value?.form?.let { it == RecordForm.CONCRETE } ?: true

/** False for an open or closed record, whose values always carry one of its subtypes. */
fun ResolvedRepresentation.isInstantiable(): Boolean =
    (this as? ResolvedRepresentation.RecordWrapper)?.value?.form?.let { it == ResolvedRecordForm.CONCRETE } ?: true

/** True for the unit scalar, the representation of an enum case. */
val ResolvedRepresentation.isUnit: Boolean get() = (this as? ResolvedRepresentation.ScalarWrapper)?.value?.kind == ScalarKind.UNIT

/**
 * The case names of this type when it is an enum: a closed record whose cases are all unit members of it. Null for
 * any other type, including a closed record with a case that holds fields.
 */
fun CheckedType.enumCases(): List<String>? {
    val cases = schema.representation.closedCases() ?: return null
    if (cases.isEmpty()) return null
    val owner = use.named?.definition ?: return null
    return cases.map { case ->
        val name = case.definition.memberName?.takeIf { case.definition == owner.member(it) } ?: return null
        val resolved = resolve(case.use) as? Resolution.Ready ?: return null
        if (!resolved.value.schema.representation.isUnit) return null
        name
    }
}

/**
 * Whether this declaration is an enum: a closed record whose cases are all unit members of it, looked up through
 * [definition]. The template counterpart of [enumCases] for code that holds declarations rather than a catalog.
 */
fun TypeDefinition.isEnum(definition: (TypeDefinitionId) -> TypeDefinition?): Boolean {
    val cases = representation.closedCases() ?: return false
    return cases.isNotEmpty() &&
        cases.all { case ->
            case.definition.memberName?.let { case.definition == id.member(it) } == true &&
                definition(case.definition)?.representation?.let {
                    (it as? RepresentationTemplate.ScalarWrapper)?.value?.kind == ScalarKind.UNIT
                } == true
        }
}

/** The case name of this value when it is a unit case of a closed record, such as an enum value; null otherwise. */
fun DataValue.enumCaseName(): String? {
    val named = (this as? DataValue.NamedWrapper)?.value ?: return null
    return if (named.payload == DataValue.UNIT) named.actualType.definition.memberName else null
}
