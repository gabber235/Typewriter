package com.typewritermc.types

/**
 * Canonical portable definitions for optional values, color, date time, and duration. These identities and
 * revision one schemas are shared by compiler conversion and runtime serialization. Reuse these definitions so
 * independently generated graphs agree on standard type identity and representation.
 */
object StandardTypes {
    val option = ResolvedTypeRef(TypeId.Option, revision = 1)
    val some = ResolvedTypeRef(TypeId.Some, revision = 1)
    val none = ResolvedTypeRef(TypeId.None, revision = 1)
    val color = ResolvedTypeRef(TypeId.Qualified("kernel/v1", "Color"), revision = 1)
    val dateTime = ResolvedTypeRef(TypeId.Qualified("kernel/v1", "DateTime"), revision = 1)
    val duration = ResolvedTypeRef(TypeId.Qualified("kernel/v1", "Duration"), revision = 1)

    fun optionOf(type: TypeExpression) = option.withArguments(listOf(type))

    fun someOf(type: TypeExpression) = some.withArguments(listOf(type))

    fun noneOf(type: TypeExpression) = none.withArguments(listOf(type))

    val definitions =
        listOf(
            TypeDefinition(
                id = option,
                kind = NominalTypeKind.SEALED_ABSTRACT,
                parameters = listOf(TypeParameter("T", variance = TypeVariance.COVARIANT)),
            ),
            TypeDefinition(
                id = some,
                kind = NominalTypeKind.CONCRETE,
                parameters = listOf(TypeParameter("T")),
                parents = listOf(optionOf(TypeExpression.Parameter("T"))),
                representation =
                    TypeExpression.Record(
                        fields = listOf(TypeField("value", TypeExpression.Parameter("T"))),
                    ),
            ),
            TypeDefinition(
                id = none,
                kind = NominalTypeKind.CONCRETE,
                parameters = listOf(TypeParameter("T", variance = TypeVariance.COVARIANT)),
                parents = listOf(optionOf(TypeExpression.Parameter("T"))),
                representation = TypeExpression.Unit,
            ),
            TypeDefinition(
                id = color,
                kind = NominalTypeKind.CONCRETE,
                representation = TypeExpression.Integer(IntegerWidth.UNSIGNED_32),
            ),
            TypeDefinition(
                id = dateTime,
                kind = NominalTypeKind.CONCRETE,
                representation = TypeExpression.Timestamp(),
            ),
            TypeDefinition(
                id = duration,
                kind = NominalTypeKind.CONCRETE,
                representation = TypeExpression.Duration(),
            ),
        )
}
