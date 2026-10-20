package com.typewritermc.codegen

import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.MemberName

/**
 * typewriter-api declarations referenced by generated code.
 *
 * typewriter-api runs codegen as its KSP processor, so codegen cannot load api classes; their names live here as
 * KotlinPoet constants. Contracts declarations are referenced through their KClass instead. TypewriterApiTest loads
 * every name against the api classpath, so a renamed api declaration fails a test instead of a downstream build.
 */
internal object TypewriterApi {
    private const val AUTHORING = "com.typewritermc.authoring"
    private const val CAPABILITY = "com.typewritermc.capability"
    private const val CHECKING = "com.typewritermc.checking"
    private const val CONFIGURATION = "com.typewritermc.configuration"
    private const val DISCOVERY = "com.typewritermc.discovery"
    private const val EXPRESSION = "com.typewritermc.expression"
    private const val OPERATIONS = "com.typewritermc.operations"
    private const val PRESENTATION = "com.typewritermc.presentation"
    private const val TYPES = "com.typewritermc.types"

    // Authoring
    val AppliedNativeArguments = ClassName(AUTHORING, "AppliedNativeArguments")
    val AuthoredReads = ClassName(AUTHORING, "AuthoredReads")
    val Availability = ClassName(AUTHORING, "Availability")
    val AvailabilityAvailable = Availability.nestedClass("Available")
    val AvailabilityUnavailable = Availability.nestedClass("Unavailable")
    val DraftBinding = ClassName(AUTHORING, "DraftBinding")
    val DraftList = ClassName(AUTHORING, "DraftList")
    val DraftSet = ClassName(AUTHORING, "DraftSet")
    val DraftView = ClassName(AUTHORING, "DraftView")
    val EditContext = ClassName(AUTHORING, "EditContext")
    val GeneratedConstructorField = ClassName(AUTHORING, "GeneratedConstructorField")
    val GenericField = ClassName(AUTHORING, "GenericField")
    val MapDraft = ClassName(AUTHORING, "MapDraft")
    val NativeConstructionPlan = ClassName(AUTHORING, "NativeConstructionPlan")
    val ReadContext = ClassName(AUTHORING, "ReadContext")
    val ReadProjection = ClassName(AUTHORING, "ReadProjection")
    val DisplayFormulas = ClassName(AUTHORING, "DisplayFormulas")
    val ResourceDisplayScope = ClassName(AUTHORING, "ResourceDisplayScope")
    val ResourceDisplaySubject = ClassName(AUTHORING, "ResourceDisplaySubject")
    val ResourceDraft = ClassName(AUTHORING, "ResourceDraft")
    val constructorDefaults = MemberName(AUTHORING, "constructorDefaults", isExtension = true)
    val defaultDisplayAccent = MemberName(AUTHORING, "defaultAccent", isExtension = true)
    val defaultDisplayIcon = MemberName(AUTHORING, "defaultIcon", isExtension = true)
    val defaultDisplayLabel = MemberName(AUTHORING, "defaultLabel", isExtension = true)
    val draftViewProjection = MemberName(AUTHORING, "draftViewProjection")
    val exactEditablePath = MemberName(AUTHORING, "exactEditablePath", isExtension = true)
    val listDraftProjection = MemberName(AUTHORING, "listDraftProjection")
    val mapDraftProjection = MemberName(AUTHORING, "mapDraftProjection")
    val nativeReadProjection = MemberName(AUTHORING, "nativeReadProjection")
    val nullableReadProjection = MemberName(AUTHORING, "nullableReadProjection")
    val read = MemberName(AUTHORING, "read", isExtension = true)
    val representationReadProjection = MemberName(AUTHORING, "representationReadProjection")
    val requireOpaqueCompatibility = MemberName(AUTHORING, "requireOpaqueCompatibility", isExtension = true)
    val setDraftProjection = MemberName(AUTHORING, "setDraftProjection")

    // Capability
    val RealmCapabilityProvider = ClassName(CAPABILITY, "RealmCapabilityProvider")
    val RealmCapabilityRuntime = ClassName(CAPABILITY, "RealmCapabilityRuntime")
    val RealmCommandCapabilityProvider = ClassName(CAPABILITY, "RealmCommandCapabilityProvider")
    val RealmCommandCapabilityRef = ClassName(CAPABILITY, "RealmCommandCapabilityRef")
    val RealmCommandContext = ClassName(CAPABILITY, "RealmCommandContext")
    val RealmCommandOutcome = ClassName(CAPABILITY, "RealmCommandOutcome")
    val RealmComputationCapabilityProvider = ClassName(CAPABILITY, "RealmComputationCapabilityProvider")
    val RealmComputationCapabilityRef = ClassName(CAPABILITY, "RealmComputationCapabilityRef")
    val RealmComputationContext = ClassName(CAPABILITY, "RealmComputationContext")
    val RealmSearch = ClassName(CAPABILITY, "RealmSearch")
    val RealmSearchCapabilityProvider = ClassName(CAPABILITY, "RealmSearchCapabilityProvider")
    val RealmSearchCapabilityRef = ClassName(CAPABILITY, "RealmSearchCapabilityRef")
    val RealmSearchContext = ClassName(CAPABILITY, "RealmSearchContext")
    val RealmSearchQuery = ClassName(CAPABILITY, "RealmSearchQuery")
    val RealmSearchRequest = ClassName(CAPABILITY, "RealmSearchRequest")
    val mapValues = MemberName(CAPABILITY, "mapValues", isExtension = true)

    // Checking
    val DraftType = ClassName(CHECKING, "DraftType")
    val RealmCheckProvider = ClassName(CHECKING, "RealmCheckProvider")
    val RealmChecks = ClassName(CHECKING, "RealmChecks")
    val ResourceTypeMatch = ClassName(CHECKING, "ResourceTypeMatch")
    val ResourceTypeMatchApplication = ResourceTypeMatch.nestedClass("Application")
    val ResourceTypeMatchDefinition = ResourceTypeMatch.nestedClass("Definition")
    val TypedSelection = ClassName(CHECKING, "TypedSelection")
    val compileSelection = MemberName(CHECKING, "compileSelection")

    // Configuration
    val BooleanExpressions = ClassName(CONFIGURATION, "BooleanExpressions")
    val BooleanField = ClassName(CONFIGURATION, "BooleanField")
    val Bytes = ClassName(CONFIGURATION, "Bytes")
    val BytesExpressions = ClassName(CONFIGURATION, "BytesExpressions")
    val CollectedConfiguration = ClassName(CONFIGURATION, "CollectedConfiguration")
    val ColorExpressions = ClassName(CONFIGURATION, "ColorExpressions")
    val ColorField = ClassName(CONFIGURATION, "ColorField")
    val Configuration = ClassName(CONFIGURATION, "Configuration")
    val ConfigurationCollectionScope = ClassName(CONFIGURATION, "ConfigurationCollectionScope")
    val Decimal = ClassName(CONFIGURATION, "Decimal")
    val DurationExpressions = ClassName(CONFIGURATION, "DurationExpressions")
    val DurationField = ClassName(CONFIGURATION, "DurationField")
    val EnumExpressions = ClassName(CONFIGURATION, "EnumExpressions")
    val EnumField = ClassName(CONFIGURATION, "EnumField")
    val GenericValueConfigurationScope = ClassName(CONFIGURATION, "GenericValueConfigurationScope")
    val GenericValueExpressions = ClassName(CONFIGURATION, "GenericValueExpressions")
    val Integer = ClassName(CONFIGURATION, "Integer")
    val LinkExpressions = ClassName(CONFIGURATION, "LinkExpressions")
    val LinkField = ClassName(CONFIGURATION, "LinkField")
    val ListExpressions = ClassName(CONFIGURATION, "ListExpressions")
    val ListField = ClassName(CONFIGURATION, "ListField")
    val MapExpressions = ClassName(CONFIGURATION, "MapExpressions")
    val MapField = ClassName(CONFIGURATION, "MapField")
    val NestedConfigurationScope = ClassName(CONFIGURATION, "NestedConfigurationScope")
    val NullableExpressions = ClassName(CONFIGURATION, "NullableExpressions")
    val NullableField = ClassName(CONFIGURATION, "NullableField")
    val NumberExpressions = ClassName(CONFIGURATION, "NumberExpressions")
    val Real = ClassName(CONFIGURATION, "Real")
    val RecordField = ClassName(CONFIGURATION, "RecordField")
    val SetExpressions = ClassName(CONFIGURATION, "SetExpressions")
    val SetField = ClassName(CONFIGURATION, "SetField")
    val Text = ClassName(CONFIGURATION, "Text")
    val TextExpressions = ClassName(CONFIGURATION, "TextExpressions")
    val TimestampExpressions = ClassName(CONFIGURATION, "TimestampExpressions")
    val TimestampField = ClassName(CONFIGURATION, "TimestampField")

    // Discovery
    val CapabilityOwnerResolver = ClassName(DISCOVERY, "CapabilityOwnerResolver")
    val GeneratedCapabilityProvider = ClassName(DISCOVERY, "GeneratedCapabilityProvider")
    val GeneratedCheckProvider = ClassName(DISCOVERY, "GeneratedCheckProvider")
    val GeneratedCollectionProjectionProvider = ClassName(DISCOVERY, "GeneratedCollectionProjectionProvider")
    val GeneratedConfigurationProvider = ClassName(DISCOVERY, "GeneratedConfigurationProvider")
    val GeneratedEndpointBindingsProvider = ClassName(DISCOVERY, "GeneratedEndpointBindingsProvider")
    val GeneratedPresentationProvider = ClassName(DISCOVERY, "GeneratedPresentationProvider")
    val GeneratedProviderInstantiator = ClassName(DISCOVERY, "GeneratedProviderInstantiator")
    val GeneratedRelationProvider = ClassName(DISCOVERY, "GeneratedRelationProvider")
    val GeneratedResourceDisplayProvider = ClassName(DISCOVERY, "GeneratedResourceDisplayProvider")
    val GeneratedResourceOperationProvider = ClassName(DISCOVERY, "GeneratedResourceOperationProvider")
    val GeneratedRuntimeRegistrarProvider = ClassName(DISCOVERY, "GeneratedRuntimeRegistrarProvider")
    val GeneratedTypeProvider = ClassName(DISCOVERY, "GeneratedTypeProvider")
    val ProviderOrigin = ClassName(DISCOVERY, "ProviderOrigin")
    val RuntimeRegistrar = ClassName(DISCOVERY, "RuntimeRegistrar")
    val RuntimeRegistrarDescriptor = ClassName(DISCOVERY, "RuntimeRegistrarDescriptor")

    // Expression
    val CanonicalReadDescriptor = ClassName(EXPRESSION, "CanonicalReadDescriptor")
    val CanonicalReadModel = ClassName(EXPRESSION, "CanonicalReadModel")
    val CanonicalReadModelRegistry = ClassName(EXPRESSION, "CanonicalReadModelRegistry")
    val Expr = ClassName(EXPRESSION, "Expr")
    val ExpressionFactory = ClassName(EXPRESSION, "ExpressionFactory")
    val Handled = ClassName(EXPRESSION, "Handled")
    val MayBeMissing = ClassName(EXPRESSION, "MayBeMissing")
    val MissingPolicy = ClassName(EXPRESSION, "MissingPolicy")
    val collectionAny = MemberName(EXPRESSION, "collectionAny")
    val collectionFilter = MemberName(EXPRESSION, "collectionFilter")
    val expressionField = MemberName(EXPRESSION, "field", isExtension = true)
    val textRepresentation = MemberName(EXPRESSION, "textRepresentation")

    // Operations
    val OperationDeclaration = ClassName(OPERATIONS, "OperationDeclaration")
    val ResourceOperationsBuildScope = ClassName(OPERATIONS, "ResourceOperationsBuildScope")
    val ResourceOperationsScope = ClassName(OPERATIONS, "ResourceOperationsScope")
    val collectOperations = MemberName(OPERATIONS, "collectOperations")

    // Presentation
    val BooleanControl = ClassName(PRESENTATION, "BooleanControl")
    val BytesControl = ClassName(PRESENTATION, "BytesControl")
    val CollectionProjection = ClassName(PRESENTATION, "CollectionProjection")
    val CollectionProjectionSpec = ClassName(PRESENTATION, "CollectionProjectionSpec")
    val ColorControl = ClassName(PRESENTATION, "ColorControl")
    val Control = ClassName(PRESENTATION, "Control")
    val DateTimeControl = ClassName(PRESENTATION, "DateTimeControl")
    val DurationControl = ClassName(PRESENTATION, "DurationControl")
    val EnumControl = ClassName(PRESENTATION, "EnumControl")
    val Layout = ClassName(PRESENTATION, "Layout")
    val LinkControl = ClassName(PRESENTATION, "LinkControl")
    val ListControl = ClassName(PRESENTATION, "ListControl")
    val MapControl = ClassName(PRESENTATION, "MapControl")
    val NestedPresentationScope = ClassName(PRESENTATION, "NestedPresentationScope")
    val NestedPresentationSlot = ClassName(PRESENTATION, "NestedPresentationSlot")
    val NestedPresentationSlotFields = MemberName(NestedPresentationSlot, "Fields")
    val NestedPresentationSlotItems = MemberName(NestedPresentationSlot, "Items")
    val NestedPresentationSlotKeys = MemberName(NestedPresentationSlot, "Keys")
    val NestedPresentationSlotValues = MemberName(NestedPresentationSlot, "Values")
    val NullableControl = ClassName(PRESENTATION, "NullableControl")
    val NumberControl = ClassName(PRESENTATION, "NumberControl")
    val PolymorphicControl = ClassName(PRESENTATION, "PolymorphicControl")
    val PresentationBuildBinding = ClassName(PRESENTATION, "PresentationBuildBinding")
    val PresentationBuildResult = ClassName(PRESENTATION, "PresentationBuildResult")
    val PresentationBuildScope = ClassName(PRESENTATION, "PresentationBuildScope")
    val PresentationReference = ClassName(PRESENTATION, "PresentationReference")
    val PresentationRuntime = ClassName(PRESENTATION, "PresentationRuntime")
    val PresentedField = ClassName(PRESENTATION, "PresentedField")
    val RecordControl = ClassName(PRESENTATION, "RecordControl")
    val ResourceExpr = ClassName(PRESENTATION, "ResourceExpr")
    val ResourcesControl = ClassName(PRESENTATION, "ResourcesControl")
    val SetControl = ClassName(PRESENTATION, "SetControl")
    val TextControl = ClassName(PRESENTATION, "TextControl")

    // Types
    val GeneratedEnumNativeBinding = ClassName(TYPES, "GeneratedEnumNativeBinding")
    val GeneratedNativeField = ClassName(TYPES, "GeneratedNativeField")
    val GeneratedRecordNativeBinding = ClassName(TYPES, "GeneratedRecordNativeBinding")
    val GeneratedScalarNativeBinding = ClassName(TYPES, "GeneratedScalarNativeBinding")
    val NativeBinding = ClassName(TYPES, "NativeBinding")
    val NativeBindingException = ClassName(TYPES, "NativeBindingException")
    val NativeBindingFactory = ClassName(TYPES, "NativeBindingFactory")
}
