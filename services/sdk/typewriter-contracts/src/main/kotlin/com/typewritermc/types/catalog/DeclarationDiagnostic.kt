package com.typewritermc.types.catalog

import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.diagnostic.DeclarationOrigin
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.TypeDefinitionId

/** A diagnostic of [affected], optionally naming the declarations it comes from and the [field] it concerns. */
fun DeclarationDiagnostic.Companion.of(
    affected: TypeDefinitionId,
    code: String,
    origins: List<DeclarationOrigin> = emptyList(),
    field: RelativeFieldPattern? = null,
): DeclarationDiagnostic = DeclarationDiagnostic(affected = affected, code = code, origins = origins, field = field)

/** The diagnostics that make a declaration unavailable. */
val DeclarationStatus.UnavailableWrapper.reasons: List<DeclarationDiagnostic> get() = value
