package com.typewritermc.types.skir

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.InitializationDiagnostic
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.SelectionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.InputToken
import com.typewritermc.types.EndpointId
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import skirout.editor.v1.authoring.LinkOccurrence as SkirLinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId as SkirLinkOccurrenceId
import skirout.editor.v1.checking.InputIdentity as SkirInputIdentity
import skirout.editor.v1.checking.InputObservation as SkirInputObservation
import skirout.editor.v1.diagnostic.InitializationDiagnostic as SkirInitializationDiagnostic
import skirout.editor.v1.diagnostic.ValueProblem as SkirValueProblem
import skirout.editor.v1.type_catalog.ArgumentSelection as SkirArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord as SkirAuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.EndpointId as SkirEndpointId
import skirout.editor.v1.type_catalog.FieldOwner as SkirFieldOwner
import skirout.editor.v1.type_catalog.FieldValue as SkirFieldValue
import skirout.editor.v1.type_catalog.InputToken as SkirInputToken
import skirout.editor.v1.type_catalog.LinkTarget as SkirLinkTarget
import skirout.editor.v1.type_catalog.RelationId as SkirRelationId
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.SelectionId as SkirSelectionId
import skirout.editor.v1.type_catalog.TypeSelection as SkirTypeSelection
import skirout.editor.v1.type_catalog.ValueLocation as SkirValueLocation
import skirout.editor.v1.type_catalog.ValuePath as SkirValuePath

object SkirAuthoringValueCodec {
    fun encode(value: AuthoringRecord): SkirConversionResult<SkirAuthoringRecord> = captureSkirConversion { encodeAuthoringRecord(value) }

    fun decode(value: SkirAuthoringRecord): SkirConversionResult<AuthoringRecord> = captureSkirConversion { decodeAuthoringRecord(value) }

    fun encode(value: TypeSelection): SkirConversionResult<SkirTypeSelection> = captureSkirConversion { encodeTypeSelection(value) }

    fun decode(value: SkirTypeSelection): SkirConversionResult<TypeSelection> = captureSkirConversion { decodeTypeSelection(value) }

    fun encode(value: ValuePath): SkirConversionResult<SkirValuePath> = captureSkirConversion { encodeValuePath(value) }

    fun decode(value: SkirValuePath): SkirConversionResult<ValuePath> = captureSkirConversion { decodeValuePath(value) }

    fun encode(value: ValueLocation): SkirConversionResult<SkirValueLocation> = captureSkirConversion { encodeValueLocation(value) }

    fun decode(value: SkirValueLocation): SkirConversionResult<ValueLocation> = captureSkirConversion { decodeValueLocation(value) }

    fun encode(value: LinkOccurrence): SkirConversionResult<SkirLinkOccurrence> = captureSkirConversion { encodeLinkOccurrence(value) }

    fun decode(value: SkirLinkOccurrence): SkirConversionResult<LinkOccurrence> = captureSkirConversion { decodeLinkOccurrence(value) }

    fun encode(value: LinkOccurrenceId): SkirConversionResult<SkirLinkOccurrenceId> =
        captureSkirConversion { encodeLinkOccurrenceId(value) }

    fun decode(value: SkirLinkOccurrenceId): SkirConversionResult<LinkOccurrenceId> =
        captureSkirConversion { decodeLinkOccurrenceId(value) }

    fun encode(value: InputIdentity): SkirConversionResult<SkirInputIdentity> = captureSkirConversion { encodeInputIdentity(value) }

    fun decode(value: SkirInputIdentity): SkirConversionResult<InputIdentity> = captureSkirConversion { decodeInputIdentity(value) }

    fun encode(value: InputObservation): SkirConversionResult<SkirInputObservation> =
        captureSkirConversion { encodeInputObservation(value) }

    fun decode(value: SkirInputObservation): SkirConversionResult<InputObservation> =
        captureSkirConversion { decodeInputObservation(value) }

    fun encode(value: InitializationDiagnostic): SkirConversionResult<SkirInitializationDiagnostic> =
        captureSkirConversion { encodeInitializationDiagnostic(value) }

    fun decode(value: SkirInitializationDiagnostic): SkirConversionResult<InitializationDiagnostic> =
        captureSkirConversion { decodeInitializationDiagnostic(value) }

    fun encode(value: ValueProblem): SkirConversionResult<SkirValueProblem> = captureSkirConversion { encodeValueProblem(value) }

    fun decode(value: SkirValueProblem): SkirConversionResult<ValueProblem> = captureSkirConversion { decodeValueProblem(value) }
}

internal fun ConversionScope.encodeAuthoringRecord(value: AuthoringRecord): SkirAuthoringRecord =
    SkirAuthoringRecord(
        configuration = encodeTypeSelection(value.configuration),
        fields =
            value.fields.toSortedMap().map { (name, field) ->
                SkirFieldValue(name = name, value = at(name) { encodeDataValue(field) })
            },
    )

internal fun ConversionScope.decodeAuthoringRecord(value: SkirAuthoringRecord): AuthoringRecord =
    AuthoringRecord(
        configuration = decodeTypeSelection(value.configuration),
        fields = decodeRecordFields(value.fields),
    )

internal fun ConversionScope.encodeTypeSelection(value: TypeSelection): SkirTypeSelection =
    when (value) {
        is TypeSelection.Complete -> {
            SkirTypeSelection.CompleteWrapper(encodeNamedTypeUse(value.use))
        }

        is TypeSelection.Pending -> {
            SkirTypeSelection.createPending(
                definition = encodeDefinitionId(value.definition),
                arguments =
                    value.arguments.mapIndexed { index, argument ->
                        at("argument $index") {
                            when (argument) {
                                is ArgumentSelection.Chosen -> SkirArgumentSelection.ChosenWrapper(encodeTypeUse(argument.type))
                                ArgumentSelection.Unfilled -> SkirArgumentSelection.UNFILLED
                            }
                        }
                    },
            )
        }
    }

internal fun ConversionScope.decodeTypeSelection(value: SkirTypeSelection): TypeSelection =
    when (value) {
        is SkirTypeSelection.CompleteWrapper -> {
            TypeSelection.Complete(decodeNamedTypeUse(value.value))
        }

        is SkirTypeSelection.PendingWrapper -> {
            TypeSelection.Pending(
                definition = decodeDefinitionId(value.value.definition),
                arguments =
                    value.value.arguments.mapIndexed { index, argument ->
                        at("argument $index") {
                            when (argument) {
                                is SkirArgumentSelection.ChosenWrapper -> ArgumentSelection.Chosen(decodeTypeUse(argument.value))
                                SkirArgumentSelection.UNFILLED -> ArgumentSelection.Unfilled
                                else -> fail("Unknown Skir argument selection variant.")
                            }
                        }
                    },
            )
        }

        else -> {
            fail("Unknown Skir type selection variant.")
        }
    }

internal fun ConversionScope.encodeValueLocation(value: ValueLocation): SkirValueLocation =
    SkirValueLocation(resource = encodeResourceId(value.resource), path = encodeValuePath(value.path))

internal fun ConversionScope.decodeValueLocation(value: SkirValueLocation): ValueLocation =
    ValueLocation(resource = decodeResourceId(value.resource), path = decodeValuePath(value.path))

internal fun ConversionScope.encodeLinkOccurrenceId(value: LinkOccurrenceId): SkirLinkOccurrenceId =
    SkirLinkOccurrenceId(
        endpoint = SkirEndpointId(value = value.endpoint.value),
        location = encodeValueLocation(value.location),
    )

internal fun ConversionScope.decodeLinkOccurrenceId(value: SkirLinkOccurrenceId): LinkOccurrenceId =
    LinkOccurrenceId(
        endpoint = EndpointId(requireText(value.endpoint.value, "Endpoint identity")),
        location = decodeValueLocation(value.location),
    )

internal fun ConversionScope.encodeLinkOccurrence(value: LinkOccurrence): SkirLinkOccurrence =
    SkirLinkOccurrence(
        id = encodeLinkOccurrenceId(value.id),
        source = encodeResourceId(value.source),
        target = encodeLinkTarget(value.target),
    )

internal fun ConversionScope.decodeLinkOccurrence(value: SkirLinkOccurrence): LinkOccurrence =
    LinkOccurrence(
        id = decodeLinkOccurrenceId(value.id),
        source = decodeResourceId(value.source),
        target = decodeLinkTarget(value.target),
    )

internal fun ConversionScope.encodeInputObservation(value: InputObservation): SkirInputObservation =
    SkirInputObservation(
        identity = encodeInputIdentity(value.identity),
        token = SkirInputToken(value = value.token.value),
    )

internal fun ConversionScope.decodeInputObservation(value: SkirInputObservation): InputObservation =
    InputObservation(
        identity = decodeInputIdentity(value.identity),
        token = InputToken(requireText(value.token.value, "Input token")),
    )

internal fun ConversionScope.encodeInputIdentity(value: InputIdentity): SkirInputIdentity =
    when (value) {
        is InputIdentity.Value -> {
            SkirInputIdentity.createValue(at = encodeValueLocation(value.at))
        }

        is InputIdentity.Existence -> {
            SkirInputIdentity.createExistence(resource = encodeResourceId(value.resource))
        }

        is InputIdentity.Form -> {
            SkirInputIdentity.createForm(at = encodeValueLocation(value.at))
        }

        is InputIdentity.Membership -> {
            SkirInputIdentity.createMembership(at = encodeValueLocation(value.at))
        }

        is InputIdentity.Order -> {
            SkirInputIdentity.createOrder(at = encodeValueLocation(value.at))
        }

        is InputIdentity.Selection -> {
            SkirInputIdentity.SelectionWrapper(SkirSelectionId(value = value.query.value))
        }

        is InputIdentity.Incoming -> {
            SkirInputIdentity.createIncoming(
                resource = encodeResourceId(value.resource),
                relation = value.relation?.let { SkirRelationId(value = it.value) },
            )
        }

        is InputIdentity.Catalog -> {
            SkirInputIdentity.CatalogWrapper(SkirCatalogGeneration(value = value.generation.value))
        }
    }

internal fun ConversionScope.decodeInputIdentity(value: SkirInputIdentity): InputIdentity =
    when (value) {
        is SkirInputIdentity.ValueWrapper -> {
            InputIdentity.Value(decodeValueLocation(value.value.at))
        }

        is SkirInputIdentity.ExistenceWrapper -> {
            InputIdentity.Existence(decodeResourceId(value.value.resource))
        }

        is SkirInputIdentity.FormWrapper -> {
            InputIdentity.Form(decodeValueLocation(value.value.at))
        }

        is SkirInputIdentity.MembershipWrapper -> {
            InputIdentity.Membership(decodeValueLocation(value.value.at))
        }

        is SkirInputIdentity.OrderWrapper -> {
            InputIdentity.Order(decodeValueLocation(value.value.at))
        }

        is SkirInputIdentity.SelectionWrapper -> {
            InputIdentity.Selection(SelectionId(requireText(value.value.value, "Selection identity")))
        }

        is SkirInputIdentity.IncomingWrapper -> {
            InputIdentity.Incoming(
                resource = decodeResourceId(value.value.resource),
                relation = value.value.relation?.let { RelationId(requireText(it.value, "Relation identity")) },
            )
        }

        is SkirInputIdentity.CatalogWrapper -> {
            InputIdentity.Catalog(CatalogGeneration(requireText(value.value.value, "Catalog generation")))
        }

        else -> {
            fail("Unknown Skir input identity variant.")
        }
    }

internal fun ConversionScope.encodeInitializationDiagnostic(value: InitializationDiagnostic): SkirInitializationDiagnostic =
    SkirInitializationDiagnostic(
        field = value.field?.let(::encodeFieldOwner),
        code = value.code,
        message = value.message,
        relativePath = value.relativePath?.let(::encodeValuePath),
    )

internal fun ConversionScope.decodeInitializationDiagnostic(value: SkirInitializationDiagnostic): InitializationDiagnostic =
    InitializationDiagnostic(
        field = value.field?.let(::decodeFieldOwner),
        code = value.code,
        message = value.message,
        relativePath = value.relativePath?.let(::decodeValuePath),
    )

internal fun ConversionScope.encodeValueProblem(value: ValueProblem): SkirValueProblem =
    SkirValueProblem(
        location = encodeValueLocation(value.location),
        code = value.code,
    )

internal fun ConversionScope.decodeValueProblem(value: SkirValueProblem): ValueProblem =
    ValueProblem(
        location = decodeValueLocation(value.location),
        code = value.code,
    )

private fun ConversionScope.encodeResourceId(value: ResourceId) = SkirResourceId(value = value.value)

private fun ConversionScope.decodeResourceId(value: SkirResourceId) = ResourceId(requireText(value.value, "Resource identity"))

private fun ConversionScope.encodeLinkTarget(value: LinkTarget) =
    SkirLinkTarget(resource = encodeResourceId(value.resource), opposite = value.opposite?.let(::encodeValuePath))

private fun ConversionScope.decodeLinkTarget(value: SkirLinkTarget) =
    LinkTarget(resource = decodeResourceId(value.resource), opposite = value.opposite?.let(::decodeValuePath))

private fun ConversionScope.encodeFieldOwner(value: FieldOwner) =
    SkirFieldOwner(definition = encodeDefinitionId(value.definition), name = value.name)

private fun ConversionScope.decodeFieldOwner(value: SkirFieldOwner) =
    FieldOwner(definition = decodeDefinitionId(value.definition), name = requireText(value.name, "Field name"))

private fun ConversionScope.requireText(
    value: String,
    label: String,
): String {
    if (value.isBlank()) fail("$label must not be blank.")
    return value
}
