package com.typewritermc.testkit

import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.CheckInput
import com.typewritermc.configuration.ConfigurationCollectionScope
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.configuration.DefaultConfigurationCollectionScope
import com.typewritermc.configuration.DurationField
import com.typewritermc.configuration.Integer
import com.typewritermc.configuration.ListField
import com.typewritermc.configuration.NestedConfigurationScope
import com.typewritermc.configuration.NullableField
import com.typewritermc.configuration.Text
import com.typewritermc.configuration.TimestampField
import com.typewritermc.configuration.field
import com.typewritermc.configuration.root
import com.typewritermc.expression.field
import com.typewritermc.presentation.of
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.of
import com.typewritermc.types.duration
import com.typewritermc.types.field
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.nullable
import com.typewritermc.types.template
import com.typewritermc.types.timestamp
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import kotlin.reflect.KClass

private val INT = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template

/** The inputs of the single check [declare] collects for [owner]. */
fun checkInputs(
    owner: TypeDefinitionId,
    declare: DefaultConfigurationCollectionScope.() -> Unit,
): List<CheckInput> =
    DefaultConfigurationCollectionScope(owner)
        .apply(declare)
        .collected()
        .checks
        .single()
        .inputs

/** A configuration provider that runs [configure] against the collection scope it is given. */
fun configurationProvider(configure: (ConfigurationCollectionScope) -> Unit): ConfigurationProvider =
    object : ConfigurationProvider {
        override fun collect(scope: ConfigurationCollectionScope): com.typewritermc.configuration.CollectedConfiguration {
            configure(scope)
            return scope.collected()
        }
    }

/** The field pattern that names the nested [names] of a configured value, one segment each. */
fun fieldPattern(vararg names: String): RelativeFieldPattern =
    RelativeFieldPattern(
        segments =
            names.map {
                FieldPatternSegment.field(it)
            },
    )

/** A signed 32 bit integer field at [path] of the configured value; the root by default. */
@Suppress("UNCHECKED_CAST")
fun integerField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern = RelativeFieldPattern.root,
): Integer<Int> = scope.field(path, RepresentationKind.INTEGER, INT, Integer::class as KClass<Integer<Int>>)

/** An unsigned 64 bit integer field at [path] of the configured value; the root by default. */
@Suppress("UNCHECKED_CAST")
fun unsignedIntegerField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern = RelativeFieldPattern.root,
): Integer<ULong> =
    scope.field(
        path,
        RepresentationKind.INTEGER,
        integerScalar(IntegerWidth.UNSIGNED_SIXTY_FOUR).template,
        Integer::class as KClass<Integer<ULong>>,
    )

/** A text field at [path] of the configured value, typed as [expected]; the root by default. */
fun textField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern = RelativeFieldPattern.root,
    expected: TypeTemplate = ScalarKind.TEXT.template,
): Text = scope.field(path, RepresentationKind.TEXT, expected, Text::class)

/** A nullable text field at [path] whose value is a text field. */
@Suppress("UNCHECKED_CAST")
fun nullableTextField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern = RelativeFieldPattern.root,
): NullableField<String, Text> =
    scope.field(
        path,
        RepresentationKind.TEXT,
        ScalarKind.TEXT.template.nullable(),
        NullableField::class as KClass<NullableField<String, Text>>,
        mapOf(
            FieldPatternSegment.VALUES to
                NestedConfigurationScope(
                    RepresentationKind.TEXT,
                    ScalarKind.TEXT.template,
                    Text::class,
                    com.typewritermc.configuration.TextExpressionsFactory,
                ) { nested -> textField(nested) },
        ),
    )

/** A nullable signed 32 bit integer field at [path] whose value is an integer field. */
@Suppress("UNCHECKED_CAST")
fun nullableIntegerField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern = RelativeFieldPattern.root,
): NullableField<Int, Integer<Int>> =
    scope.field(
        path,
        RepresentationKind.INTEGER,
        INT.nullable(),
        NullableField::class as KClass<NullableField<Int, Integer<Int>>>,
        mapOf(
            FieldPatternSegment.VALUES to
                NestedConfigurationScope(
                    RepresentationKind.INTEGER,
                    INT,
                    Integer::class,
                    com.typewritermc.configuration.NumberExpressionsFactory,
                ) { nested -> integerField(nested) },
        ),
    )

/** A list field at [path] of signed 32 bit integers; the root by default. */
@Suppress("UNCHECKED_CAST")
fun listField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern = RelativeFieldPattern.root,
): ListField<Int, Any, Any> =
    scope.field(
        path,
        RepresentationKind.LIST,
        StandardTypes.list.template(listOf(INT)),
        ListField::class as KClass<ListField<Int, Any, Any>>,
    )

/** A duration field at [path]; the root by default. */
fun durationField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern = RelativeFieldPattern.root,
): DurationField = scope.field(path, RepresentationKind.DURATION, ScalarKind.DURATION.template, DurationField::class)

/** A timestamp field at [path]; the root by default. */
fun timestampField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern = RelativeFieldPattern.root,
): TimestampField = scope.field(path, RepresentationKind.TIMESTAMP, ScalarKind.TIMESTAMP.template, TimestampField::class)
