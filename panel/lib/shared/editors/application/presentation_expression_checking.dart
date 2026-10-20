import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Checks an instantiated material under the lexical scopes used by rendering.
/// The traversal checks inactive branches and provider result presentations too,
/// so a currently hidden node cannot bypass binding and expression admission.
/// This validates declared types and fixed layout constraints; expression
/// availability and computed numeric ranges still need runtime checks.
extension PresentationExpressionAdmission on CheckedEditorCatalog {
  List<String> presentationExpressionProblems(
    skir.PresentationMaterial material,
    skir.TypeSelection actual,
  ) {
    final subject =
        applyTemplate(material.subject, actual) ??
        concreteType(material.subject);
    if (subject == null) {
      return const ["unresolved_presentation_expression_subject"];
    }
    final errors = <String>[];
    void alias(skir.ExpressionBindingId id) {
      if (id.value.startsWith("context:")) {
        errors.add("reserved_context_binding");
      }
    }

    final contextInputs = <skir.ExpressionBindingId, skir.TypeUse>{};
    for (final input in material.dependencies.contextInputs) {
      if (!input.bindingId.value.startsWith("context:") ||
          input.bindingId.value.substring(8).trim().isEmpty) {
        errors.add("invalid_context_input_binding");
      }
      if (contextInputs.containsKey(input.bindingId)) {
        errors.add("duplicate_context_input");
      }
      switch (input.source) {
        case skir.PresentationContextSource_hostWrapper(:final value)
            when HostContext.valueType(value) != input.valueType:
          errors.add("invalid_host_context_input");
        case skir.PresentationContextSource_unknown():
          errors.add("invalid_context_input_source");
        case _:
      }
      contextInputs[input.bindingId] = input.valueType;
      final named = namedUse(input.valueType);
      if (named != null && !isReadyApplication(named)) {
        errors.add("invalid_context_input_type");
      }
    }
    for (final collection in material.dependencies.collections) {
      alias(collection.rowBindingId);
      if (collection.projection case final projection?) {
        alias(projection.resourceBindingId);
      }
    }
    final configured = skir.ExpressionBindingId(value: "configured_value");
    final text = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
    final boolean = skir.TypeUse.wrapScalar(skir.ScalarKind.boolean);
    final integer = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedSixtyFour),
    );
    final floating = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
    );
    skir.ExpressionType type(skir.TypeUse value, [bool missing = true]) =>
        nominalType(value, missing);
    skir.TypeUse payload(skir.TypeUse value) {
      if (value case skir.TypeUse_nullableWrapper(:final value)) {
        return payload(value.value);
      }
      final named = namedUse(value);
      if (named == null) return value;
      final representation = published(named.definition)
          ?.definition
          .representation;
      if (representation case skir.RepresentationTemplate_scalarWrapper(
        :final value,
      )) {
        return skir.TypeUse.wrapScalar(value.kind);
      }
      return value;
    }

    skir.ExpressionType? path(skir.ExpressionType source, skir.ValuePath path) {
      if (path.segments.isEmpty) return source;
      final named = namedUse(source.declaredUse());
      if (named == null) return null;
      final value = valueTypeAt(skir.TypeSelection.wrapComplete(named), path);
      return value == null ? null : type(value, source.mayBeMissing);
    }

    skir.ExpressionType? binding(
      skir.BindingRef ref,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      final source = env[ref.bindingId];
      return source == null ? null : path(source, ref.path);
    }

    void check(
      skir.ExpressionNode? body,
      skir.TypeUse expected,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env, {
      bool missing = true,
      bool numericWidth = false,
    }) {
      if (body == null) return;
      errors.addAll(
        checkPortableExpression(
          body,
          catalog: this,
          bindings: env,
          expectedOutput: type(payload(expected), missing),
          allowResultNumericWidth: numericWidth,
        ),
      );
    }

    // An icon is an Iconify name or a typed icon value, such as a type display icon.
    void icon(
      skir.ExpressionNode body,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      List<String> against(skir.TypeUse expected) => checkPortableExpression(
        body,
        catalog: this,
        bindings: env,
        expectedOutput: type(payload(expected), true),
      );
      final asText = against(text);
      if (asText.isEmpty) return;
      if (against(skir.TypeUse.wrapNamed(expressionIconUse)).isEmpty) return;
      errors.addAll(asText);
    }

    void resourceAction(
      skir.EditorAction? action,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      switch (action) {
        case skir.EditorAction_navigateWrapper(:final value):
          check(value.resource, text, env, missing: false);
        case skir.EditorAction_authoringWrapper(:final value):
          final selected =
              env[skir.ExpressionBindingId(value: "context:selection")];
          if (selected == null) {
            errors.add("missing_resource_action_context");
          } else {
            if (selected.declaredUse() case final use?) {
              check(value.targets, use, env, missing: false);
            }
          }
          final capability = snapshot.capabilities
              .whereType<skir.CapabilityDefinition_authoringWrapper>()
              .map((item) => item.value)
              .where((item) => item.capabilityId == value.capability)
              .firstOrNull;
          if (capability == null) {
            errors.add("missing_authoring_capability");
          } else if (value.initialInput != null) {
            if (capability.input == null) {
              errors.add("unexpected_authoring_input");
            } else {
              check(value.initialInput, capability.input!.type, env);
            }
          }
        case skir.EditorAction_createWrapper(:final value):
          if (value.owner case final owner? when binding(owner, env) == null) {
            errors.add("unresolved_create_owner");
          }
          final created = beginSelection(value.type);
          if (created == skir.TypeSelection.unknown) {
            errors.add("unknown_create_type");
            break;
          }
          for (final preset in value.fields) {
            final field = valueTypeAt(created, preset.path);
            if (field == null) {
              errors.add("unresolved_create_preset");
            } else {
              check(preset.value, field, env);
            }
          }
        default:
          break;
      }
    }

    void number(
      skir.ExpressionNode? body,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      if (body == null) return;
      final contracts = [
        integer,
        floating,
        skir.TypeUse.wrapScalar(skir.ScalarKind.decimal),
      ];
      final attempts = [
        for (final contract in contracts)
          checkPortableExpression(
            body,
            catalog: this,
            bindings: env,
            expectedOutput: type(contract),
            allowResultNumericWidth: true,
          ),
      ];
      if (attempts.every((attempt) => attempt.isNotEmpty)) {
        errors.addAll(attempts.first);
      }
    }

    void mapping(
      skir.ValueMappings? mappings,
      skir.TypeUse? candidate,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      if (mappings == null) return;
      if (candidate == null) {
        errors.add("unresolved_mapping_candidate_type");
        return;
      }
      for (final entry in [
        (mappings.completion, payload(candidate)),
        (mappings.display, text),
      ]) {
        final authored = entry.$1;
        if (authored == null) continue;
        alias(authored.inputBinding);
        if (env.containsKey(authored.inputBinding)) {
          errors.add("duplicate_expression_binding");
          continue;
        }
        check(authored.body, entry.$2, {
          ...env,
          authored.inputBinding: type(payload(candidate), false),
        }, missing: false);
      }
    }

    void stateMatch(skir.PresentationStateMatch match) {
      if (match.required_.toSet().intersection(match.excluded.toSet())
          case final overlap when overlap.isNotEmpty) {
        errors.add("contradictory_presentation_state_match");
      }
    }

    late void Function(
      skir.PresentationColor?,
      Map<skir.ExpressionBindingId, skir.ExpressionType>,
    )
    color;
    color = (paint, env) {
      switch (paint) {
        case skir.PresentationColor_valueWrapper(:final value):
          check(value, integer, env, numericWidth: true);
        case skir.PresentationColor_contrastWrapper(:final value):
          color(value.source, env);
        case skir.PresentationColor_alphaWrapper(:final value):
          color(value.source, env);
        case skir.PresentationColor_blendWrapper(:final value):
          color(value.foreground, env);
          color(value.background, env);
        case skir.PresentationColor_statesWrapper(:final value):
          for (final rule in value.rules) {
            stateMatch(rule.match);
            color(rule.color, env);
          }
          color(value.fallback, env);
        case skir.PresentationColor_adjustedWrapper(:final value):
          color(value.source, env);
          if (!value.lightness.isFinite ||
              !value.chroma.isFinite ||
              value.lightness.abs() > 1 ||
              value.chroma.abs() > 1) {
            errors.add("invalid_presentation_color_adjustment");
          }
        case skir.PresentationColor_brightnessWrapper(:final value):
          color(value.light, env);
          color(value.dark, env);
        default:
          break;
      }
    };
    void presentationNumber(
      skir.PresentationNumber? value,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      switch (value) {
        case skir.PresentationNumber_valueWrapper(:final value):
          number(value, env);
        case skir.PresentationNumber_statesWrapper(:final value):
          for (final rule in value.rules) {
            stateMatch(rule.match);
            number(rule.value, env);
          }
          number(value.fallback, env);
        case null:
          break;
        default:
          errors.add("unknown_presentation_number");
      }
    }

    void motion(skir.PresentationTransition value) {
      if (value.milliseconds < 0) {
        errors.add("invalid_presentation_transition");
      }
      if (value.curve
          case skir.PresentationCurve_elasticOutWrapper(:final value)
          when !value.isFinite || value <= 0) {
        errors.add("invalid_presentation_curve");
      }
    }

    void transition(skir.PresentationTransitionPolicy? policy) {
      if (policy == null) return;
      for (final rule in policy.rules) {
        stateMatch(rule.match);
        motion(rule.transition);
      }
      motion(policy.fallback);
    }

    void shadows(
      Iterable<skir.PresentationShadow> values,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      for (final shadow in values) {
        color(shadow.color, env);
        if (!shadow.blur.isFinite ||
            shadow.blur < 0 ||
            !shadow.spread.isFinite ||
            !shadow.offsetX.isFinite ||
            !shadow.offsetY.isFinite) {
          errors.add("invalid_presentation_shadow");
        }
      }
    }

    void insets(skir.PresentationInsets? insets) {
      final values = switch (insets) {
        skir.PresentationInsets_allWrapper(:final value) => [value],
        skir.PresentationInsets_symmetricWrapper(:final value) => [
          value.horizontal,
          value.vertical,
        ],
        skir.PresentationInsets_onlyWrapper(:final value) => [
          value.top,
          value.left,
          value.right,
          value.bottom,
        ],
        _ => <double>[],
      };
      if (values.any((value) => !value.isFinite || value < 0)) {
        errors.add("invalid_presentation_padding");
      }
    }

    void border(
      skir.PresentationBorder? border,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      final sides = switch (border) {
        skir.PresentationBorder_allWrapper(:final value) => [value],
        skir.PresentationBorder_sidesWrapper(:final value) => [
          value.top,
          value.start,
          value.end,
          value.bottom,
        ],
        _ => <skir.PresentationBorderSide?>[],
      };
      for (final side in sides) {
        color(side?.color, env);
        if (side != null && (!side.width.isFinite || side.width < 0)) {
          errors.add("invalid_presentation_border_width");
        }
      }
    }

    void radius(
      skir.PresentationRadius? radius,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      if (radius case skir.PresentationRadius_customWrapper(:final value)) {
        number(value, env);
      }
    }

    void sizing(
      skir.TextSizing? sizing,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      switch (sizing) {
        case skir.TextSizing_exactWrapper(:final value):
          number(value, env);
        case skir.TextSizing_fitWrapper(:final value):
          number(value.minimum, env);
          number(value.maximum, env);
        default:
          break;
      }
    }

    void inputTypography(
      skir.InputTextStyle? textStyle,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      color(textStyle?.color, env);
      sizing(textStyle?.sizing, env);
      if (textStyle?.sizing is skir.TextSizing_fitWrapper) {
        errors.add("unsupported_input_text_fit");
      }
      if (textStyle?.weight case final weight?) {
        if (weight < 1 || weight > 1000) {
          errors.add("invalid_input_font_weight");
        }
      }
    }

    late void Function(
      skir.InputAppearance?,
      Map<skir.ExpressionBindingId, skir.ExpressionType>,
    )
    appearance;
    void actionAppearance(
      skir.ActionAppearance? style,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      if (style == null) return;
      appearance(style.appearance, env);
      check(style.tooltip, text, env);
    }

    appearance = (style, env) {
      if (style == null) return;
      if (style.border case skir.BorderOverride_valueWrapper(:final value)) {
        border(value, env);
      }
      insets(style.padding);
      radius(style.radius, env);
      color(style.iconColor, env);
      color(style.fill, env);
      number(style.iconSize, env);
      for (final textStyle in [
        style.valueStyle,
        style.placeholderStyle,
        style.labelStyle,
        style.descriptionStyle,
      ]) {
        inputTypography(textStyle, env);
      }
    };

    void content(
      skir.InputContent? content,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) => check(content?.placeholder, text, env);
    void popup(
      skir.PopupAppearance? style,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      if (style == null) return;
      insets(style.padding);
      radius(style.radius, env);
      number(style.minimumWidth, env);
      number(style.maximumWidth, env);
      number(style.maximumExtent, env);
      color(style.fill, env);
      border(style.border, env);
    }

    void collectionAppearance(
      skir.CollectionAppearance? style,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      if (style == null) return;
      insets(style.itemPadding);
      radius(style.itemRadius, env);
      color(style.itemBackground, env);
      color(style.itemForeground, env);
      border(style.itemBorder, env);
      if (style.itemSpacing != null &&
          (!style.itemSpacing!.isFinite || style.itemSpacing! < 0)) {
        errors.add("invalid_collection_spacing");
      }
      transition(style.itemTransition);
      shadows(style.itemShadows, env);
    }

    void choices(
      skir.SelectInteractionOptions? options,
      skir.TypeUse? candidate,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      if (options == null) return;
      if (options.customValue != null && options.queryBindingId == null) {
        errors.add("missing_choice_custom_query_binding");
      }
      if (options.customValue != null &&
          (options.presentation == skir.ChoicePresentation.segmented ||
              options.presentation == skir.ChoicePresentation.radio)) {
        errors.add("unsupported_choice_custom_presentation");
      }
      number(options.maximumMenuHeight, env);
      final queryEnv = {
        ...env,
        if (options.queryBindingId != null)
          options.queryBindingId!: type(text, false),
      };
      check(options.customValue, candidate ?? text, queryEnv);
      for (final option in options.optionOverrides) {
        check(option.enabledIf, boolean, env);
        check(option.disabledReason, text, env);
      }
      inputTypography(options.selectedTextStyle, env);
    }

    void collectionContent(
      skir.CollectionContent? content,
      Map<skir.ExpressionBindingId, skir.ExpressionType> env,
    ) {
      if (content == null) return;
      for (final expression in [
        content.emptyText,
        content.addLabel,
        content.removeLabel,
        content.chooseLabel,
        content.unlinkLabel,
        content.operationTooltip,
        content.keyLabel,
        content.valueLabel,
      ]) {
        check(expression, text, env);
      }
    }

    late void Function(
      skir.PresentationNode,
      Map<skir.ExpressionBindingId, skir.ExpressionType>,
    )
    visit;
    void clippedColumn(skir.AxisChildrenLayout layout) {
      if (layout.clipOverflow) errors.add("clipped_column_not_supported");
    }

    void sequenceClipping(skir.SequencePresentation presentation) {
      if (presentation.layout case skir.SequenceLayout_childrenWrapper(
        value: skir.ChildrenLayout_columnWrapper(:final value),
      )) {
        clippedColumn(value);
      }
    }

    visit = (node, env) {
      if (node.element case skir.PresentationElement_childrenWrapper(
        :final value,
      )) {
        switch (value) {
          case skir.ChildrenElement_columnWrapper(:final value):
            clippedColumn(value.layout);
          case skir.ChildrenElement_rowWrapper(:final value):
            if (value.layout.clipOverflow &&
                value.children.any(
                  (child) => child is skir.AxisChild_flexibleWrapper,
                )) {
              errors.add("clipped_row_has_flexible_child");
            }
          default:
            break;
        }
      }
      switch (node.element) {
        case skir.PresentationElement_repeatedWrapper(:final value):
          sequenceClipping(value.presentation);
        case skir.PresentationElement_collectionGraphWrapper(:final value):
          sequenceClipping(value.rootSequence);
          sequenceClipping(value.children);
        default:
          break;
      }
      final aliases = switch (node.element) {
        skir.PresentationElement_scopedBindingWrapper(:final value) => [
          value.scopeBindingId,
        ],
        skir.PresentationElement_repeatedWrapper(:final value) => [
          value.itemBindingId,
        ],
        skir.PresentationElement_polymorphicMatchWrapper(:final value) => [
          value.scopeBindingId,
        ],
        skir.PresentationElement_listInputWrapper(:final value) => [
          value.itemBindingId,
          value.indexBindingId,
        ],
        skir.PresentationElement_setInputWrapper(:final value) => [
          value.itemBindingId,
        ],
        skir.PresentationElement_mapInputWrapper(:final value) => [
          value.keyBindingId,
          value.valueBindingId,
        ],
        skir.PresentationElement_collectionGraphWrapper(:final value) => [
          value.childrenBindingId,
          value.childBindingId,
        ],
        skir.PresentationElement_searchInputWrapper(:final value) => [
          value.queryBindingId,
          value.summaryBindingId,
        ],
        skir.PresentationElement_invocationWrapper(:final value) => [
          for (final argument in value.arguments) argument.input,
        ],
        skir.PresentationElement_resourcesWrapper(:final value) => [
          value.itemBindingId,
        ],
        _ => const <skir.ExpressionBindingId>[],
      };
      for (final id in aliases) {
        alias(id);
      }
      check(node.properties.enabledIf, boolean, env);
      for (final item in node.header?.items ?? const <skir.HeaderItem>[]) {
        switch (item) {
          case skir.HeaderItem_buttonWrapper(:final value):
            resourceAction(value.action, env);
          case skir.HeaderItem_booleanToggleWrapper(:final value):
            resourceAction(value.action, env);
          default:
            break;
        }
      }
      final control = node.boundControl;
      final candidate = control == null
          ? null
          : binding(control.binding, env)?.declaredUse();
      if (control != null) {
        if (candidate == null) errors.add("unresolved_control_binding_type");
        check(control.label, text, env);
        check(control.description, text, env);
        check(control.semanticLabel, text, env);
      }
      final nested =
          <
            skir.PresentationNode,
            Map<skir.ExpressionBindingId, skir.ExpressionType>
          >{};
      void rebound(
        skir.PresentationNode? child,
        skir.TypeUse? value, {
        skir.ExpressionBindingId? alias,
      }) {
        if (child == null) return;
        if (value == null) {
          errors.add("unresolved_presentation_scope_type");
          return;
        }
        nested[child] = {...env, alias ?? configured: type(value)};
      }

      Map<skir.ExpressionBindingId, skir.ExpressionType> collectionEnv(
        String sourceId,
      ) {
        final source = material.dependencies.collections
            .where((item) => item.sourceId == sourceId)
            .firstOrNull;
        if (source == null) return env;
        final row =
            applyTemplate(source.rowType, actual) ??
            concreteType(source.rowType);
        return {
          ...env,
          if (row != null) source.rowBindingId: type(row),
          if (source.projection != null)
            source.projection!.resourceBindingId: type(
              skir.TypeUse.wrapNamed(frameworkResourceIdUse),
              false,
            ),
        };
      }

      late void Function(
        skir.SearchProvider,
        Map<skir.ExpressionBindingId, skir.ExpressionType>,
      )
      searchProvider;
      void searchResult(
        skir.SearchResultMapping result,
        skir.TypeUse? row,
        Map<skir.ExpressionBindingId, skir.ExpressionType> parent,
      ) {
        if (row == null) {
          errors.add("unresolved_search_result_type");
          return;
        }
        alias(result.bindingId);
        final local = {...parent, result.bindingId: type(row)};
        nested[result.presentation] = local;
        check(result.label, text, local);
        if (candidate != null) check(result.selectedValue, candidate, local);
      }

      searchProvider = (provider, parent) {
        switch (provider) {
          case skir.SearchProvider_collectionWrapper(:final value):
            final source = material.dependencies.collections
                .where((item) => item.sourceId == value.sourceId)
                .firstOrNull;
            final row = source == null
                ? null
                : applyTemplate(source.rowType, actual) ??
                      concreteType(source.rowType);
            final local = {...collectionEnv(value.sourceId), ...parent};
            if (row != null) {
              check(value.where, boolean, {
                ...local,
                value.result.bindingId: type(row),
              });
            }
            searchResult(value.result, row, local);
          case skir.SearchProvider_httpJsonWrapper(:final value):
            final local = {...parent};
            for (final context in value.contextBindings) {
              alias(context.bindingId);
              final contextType =
                  applyTemplate(context.valueType, actual) ??
                  concreteType(context.valueType);
              if (contextType != null) {
                local[context.bindingId] = type(contextType);
              }
            }
            check(value.uri, text, local);
            for (final parameter in value.parameters) {
              check(parameter.value, text, local);
            }
            searchResult(
              value.result,
              applyTemplate(value.resultType, actual) ??
                  concreteType(value.resultType),
              local,
            );
          case skir.SearchProvider_realmCallbackWrapper(:final value):
            final result = snapshot.capabilities
                .whereType<skir.CapabilityDefinition_searchWrapper>()
                .where((item) => item.value.capabilityId == value.capabilityId)
                .firstOrNull
                ?.value
                .resultType;
            searchResult(value.result, result, parent);
          case skir.SearchProvider_staticValuesWrapper(:final value):
            skir.ExpressionType? source;
            final sourceProblems = checkPortableExpression(
              value.values,
              catalog: this,
              bindings: parent,
              onInferred: (result) => source = result,
            );
            errors.addAll(sourceProblems);
            searchResult(
              value.result,
              source == null ? null : collectionItem(source!)?.declaredUse(),
              parent,
            );
          case skir.SearchProvider_gateWrapper(:final value):
            check(value.condition, boolean, parent);
            check(value.guidance, text, parent);
            searchProvider(value.child, parent);
          case skir.SearchProvider_debounceWrapper(:final value):
            searchProvider(value.child, parent);
          case skir.SearchProvider_cacheWrapper(:final value):
            searchProvider(value.child, parent);
          case skir.SearchProvider_rankWrapper(:final value):
            searchProvider(value.child, parent);
          case skir.SearchProvider_limitWrapper(:final value):
            check(value.maximum, integer, parent, numericWidth: true);
            searchProvider(value.child, parent);
          case skir.SearchProvider_distinctWrapper(:final value):
            searchProvider(value.child, parent);
          case skir.SearchProvider_historyWrapper(:final value):
            check(value.label, text, parent);
            searchProvider(value.child, parent);
          case skir.SearchProvider_sectionWrapper(:final value):
            check(value.label, text, parent);
            searchProvider(value.child, parent);
          case skir.SearchProvider_mergeWrapper(:final value):
            for (final child in value.children) {
              searchProvider(child, parent);
            }
          default:
            errors.add("unknown_search_provider");
        }
      };
      switch (node.element) {
        case skir.PresentationElement_containerWrapper(:final value):
          color(value.backgroundColor, env);
          color(value.foregroundColor, env);
          border(value.border, env);
          radius(value.radius, env);
          transition(value.transition);
          shadows(value.shadows, env);
        case skir.PresentationElement_childrenWrapper(
          value: skir.ChildrenElement_stackWrapper(:final value),
        ):
          for (final child in value.children) {
            if (child case skir.StackChild_positionedWrapper(:final value)) {
              if ([value.start, value.end, value.width].nonNulls.length > 2 ||
                  [value.top, value.bottom, value.height].nonNulls.length > 2) {
                errors.add("overconstrained_positioned_child");
              }
              for (final inset in [
                value.top,
                value.start,
                value.end,
                value.bottom,
                value.width,
                value.height,
              ]) {
                presentationNumber(inset, env);
              }
              transition(value.transition);
            }
          }
        case skir.PresentationElement_sizeWrapper(:final value):
          for (final bound in [
            value.width,
            value.height,
            value.minimumWidth,
            value.maximumWidth,
            value.minimumHeight,
            value.maximumHeight,
          ]) {
            number(bound, env);
          }
        case skir.PresentationElement_transformWrapper(:final value):
          if (!value.perspective.isFinite) {
            errors.add("invalid_transform_perspective");
          }
          for (final part in [
            value.scale,
            value.rotateX,
            value.rotateY,
            value.rotateZ,
            value.translateX,
            value.translateY,
          ]) {
            presentationNumber(part, env);
          }
          transition(value.transition);
        case skir.PresentationElement_textWrapper(:final value):
        case skir.PresentationElement_markdownWrapper(:final value):
          check(value.value, text, env);
          check(value.semanticLabel, text, env);
          color(value.color, env);
          sizing(value.sizing, env);
          for (final expression in [
            value.fontWeight,
            value.fontOpticalSize,
            value.fontSlant,
            value.fontWidth,
            value.lineHeight,
            value.letterSpacing,
          ]) {
            number(expression, env);
          }
          check(value.fontItalic, boolean, env);
          check(value.textAlignment, text, env);
          check(value.decoration, text, env);
        case skir.PresentationElement_iconWrapper(:final value):
          icon(value.name, env);
          check(value.semanticLabel, text, env);
          color(value.color, env);
          number(value.size, env);
        case skir.PresentationElement_dateTimeWrapper(:final value):
          appearance(value.options?.appearance, env);
        case skir.PresentationElement_relativeTimeWrapper(:final value):
          appearance(value.options?.appearance, env);
        case skir.PresentationElement_collectionLookupWrapper(:final value):
          nested[value.found] = collectionEnv(value.sourceId);
        case skir.PresentationElement_collectionGraphWrapper(:final value):
          final local = collectionEnv(value.sourceId);
          final source = material.dependencies.collections
              .where((item) => item.sourceId == value.sourceId)
              .firstOrNull;
          final row = source == null
              ? null
              : applyTemplate(source.rowType, actual) ??
                    concreteType(source.rowType);
          if (row != null) {
            final list = skir.TypeUse.createNamed(
              definition: skir.TypeDefinitionId(
                typeId: skir.TypeId.createQualified(
                  namespace: "typewriter",
                  name: "List",
                ),
                revision: 1,
              ),
              arguments: [row],
            );
            nested[value.node] = {
              ...local,
              value.childrenBindingId: type(list),
              value.childBindingId: type(row),
            };
            nested[value.children.item] = {
              ...local,
              value.childBindingId: type(row),
            };
            nested[value.rootSequence.item] = local;
          }
        case skir.PresentationElement_imageWrapper(:final value):
          check(value.source, text, env);
          check(value.semanticLabel, text, env);
          number(value.options?.width, env);
          number(value.options?.height, env);
          radius(value.options?.radius, env);
        case skir.PresentationElement_badgeWrapper(:final value):
          check(value.label, text, env);
          appearance(value.options?.appearance, env);
        case skir.PresentationElement_chipWrapper(:final value):
          check(value.label, text, env);
          color(value.color, env);
          appearance(value.options?.appearance, env);
        case skir.PresentationElement_progressWrapper(:final value):
          number(value.value, env);
          number(value.maximum, env);
          check(value.label, text, env);
          number(value.appearance?.minimumHeight, env);
          radius(value.appearance?.radius, env);
          color(value.appearance?.color, env);
          color(value.appearance?.backgroundColor, env);
        case skir.PresentationElement_statusWrapper(:final value):
          for (final style in [
            ...value.cases.map((item) => item.appearance),
            if (value.fallback != null) value.fallback!,
          ]) {
            check(style.label, text, env);
            appearance(style.options?.appearance, env);
          }
        case skir.PresentationElement_tooltipWrapper(:final value):
          check(value.message, text, env);
          appearance(value.appearance?.appearance, env);
          if ((value.appearance?.waitMilliseconds ?? 0) < 0 ||
              (value.appearance?.showMilliseconds ?? 0) < 0) {
            errors.add("invalid_tooltip_duration");
          }
        case skir.PresentationElement_tabsWrapper(:final value):
          appearance(value.appearance, env);
          for (final tab in value.tabs) {
            check(tab.label, text, env);
          }
          for (final gap in [value.spacing, value.contentSpacing]) {
            if (gap != null && (!gap.isFinite || gap < 0)) {
              errors.add("invalid_tabs_spacing");
            }
          }
        case skir.PresentationElement_dividerWrapper(:final value):
          color(value.color, env);
          for (final expression in [
            value.thickness,
            value.space,
            value.indent,
            value.endIndent,
          ]) {
            number(expression, env);
          }
        case skir.PresentationElement_buttonWrapper(:final value):
          resourceAction(value.action, env);
          check(value.label, text, env);
          actionAppearance(value.appearance, env);
        case skir.PresentationElement_iconButtonWrapper(:final value):
          resourceAction(value.action, env);
          check(value.semanticLabel, text, env);
          actionAppearance(value.appearance, env);
        case skir.PresentationElement_menuWrapper(:final value):
          check(value.label, text, env);
          actionAppearance(value.appearance, env);
          popup(value.popup, env);
          for (final item in value.items) {
            if (!item.separator && item.action == null) {
              errors.add("missing_menu_item_action");
            }
            resourceAction(item.action, env);
            check(item.label, text, env);
            check(item.description, text, env);
            check(item.enabledIf, boolean, env);
            check(item.disabledReason, text, env);
          }
        case skir.PresentationElement_numericInputWrapper(:final value):
          appearance(value.appearance, env);
          content(value.content, env);
          mapping(value.mappings, candidate, env);
          for (final expression in [
            value.options.minimum,
            value.options.maximum,
            value.options.step,
          ]) {
            if (candidate != null) check(expression, candidate, env);
          }
          check(value.options.editingLocale, text, env);
        case skir.PresentationElement_textInputWrapper(:final value):
          appearance(value.appearance, env);
          content(value.content, env);
          mapping(value.mappings, candidate, env);
        case skir.PresentationElement_durationInputWrapper(:final value):
          appearance(value.appearance, env);
          content(value.content, env);
          mapping(value.mappings, candidate, env);
          for (final expression in [
            value.options?.minimum,
            value.options?.maximum,
            value.options?.step,
          ]) {
            check(
              expression,
              skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
              env,
            );
          }
        case skir.PresentationElement_dateTimeInputWrapper(:final value):
          appearance(value.appearance, env);
          content(value.content, env);
          popup(value.popup, env);
          mapping(value.mappings, candidate, env);
          check(
            value.options?.minimum,
            skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp),
            env,
          );
          check(
            value.options?.maximum,
            skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp),
            env,
          );
          check(
            value.options?.timeIncrement,
            skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
            env,
          );
        case skir.PresentationElement_colorInputWrapper(:final value):
          appearance(value.appearance, env);
          content(value.content, env);
          popup(value.popup, env);
          mapping(value.mappings, candidate, env);
        case skir.PresentationElement_bytesInputWrapper(:final value):
          appearance(value.appearance, env);
          content(value.content, env);
          mapping(value.mappings, candidate, env);
        case skir.PresentationElement_sliderInputWrapper(:final value):
          appearance(value.appearance, env);
          mapping(value.mappings, candidate, env);
          if (candidate != null) {
            check(value.minimum, candidate, env);
            check(value.maximum, candidate, env);
          }
          check(value.divisions, integer, env, numericWidth: true);
        case skir.PresentationElement_toggleInputWrapper(:final value):
          appearance(value.appearance, env);
          check(value.options?.trueLabel, text, env);
          check(value.options?.falseLabel, text, env);
          color(value.options?.thumbColor, env);
          color(value.options?.trackColor, env);
          color(value.options?.checkColor, env);
        case skir.PresentationElement_selectInputWrapper(:final value):
          if (value.allowCustomValue &&
              (value.optionsConfig?.queryBindingId == null ||
                  value.optionsConfig?.customValue == null)) {
            errors.add("missing_choice_custom_mapping");
          }
          appearance(value.appearance, env);
          content(value.content, env);
          popup(value.popup, env);
          for (final option in value.options) {
            check(option.label, text, env);
            check(option.enabledIf, boolean, env);
            check(option.disabledReason, text, env);
            if (candidate != null) check(option.value, candidate, env);
          }
          choices(value.optionsConfig, candidate, env);
        case skir.PresentationElement_enumInputWrapper(:final value):
          appearance(value.appearance, env);
          content(value.content, env);
          popup(value.popup, env);
          choices(value.options, candidate, env);
        case skir.PresentationElement_linkInputWrapper(:final value):
          collectionContent(value.content, env);
          collectionAppearance(value.appearance, env);
          appearance(value.inputAppearance, env);
          content(value.inputContent, env);
          popup(value.popup, env);
        case skir.PresentationElement_resourcesWrapper(:final value):
          final member = collectionItemType(candidate);
          if (member == null) {
            errors.add("unresolved_resources_member_type");
            break;
          }
          if (value.order case final order?) {
            errors.addAll(
              checkPortableExpression(
                order,
                catalog: this,
                bindings: {...env, value.itemBindingId: type(member, false)},
              ),
            );
          }
          switch (value.layout) {
            case skir.ResourcesLayout_graphWrapper(:final value):
              insets(value.appearance?.cardPadding);
              number(value.appearance?.cellSize, env);
              color(value.appearance?.edgeColor, env);
            case skir.ResourcesLayout_timelineWrapper(:final value):
              final style = value.appearance;
              if (style != null) {
                for (final paint in [
                  style.headerColor,
                  style.rulerColor,
                  style.trackColor,
                  style.alternateTrackColor,
                  style.gridMinorColor,
                  style.gridMajorColor,
                  style.textMutedColor,
                ]) {
                  color(paint, env);
                }
                for (final size in [
                  style.rulerHeight,
                  style.trackPadding,
                  style.laneHeight,
                  style.laneGap,
                  style.headerPadding,
                ]) {
                  if (size != null && (!size.isFinite || size < 0)) {
                    errors.add("invalid_resources_timeline_dimension");
                  }
                }
              }
            case skir.ResourcesLayout_gridWrapper(:final value):
              number(value.itemExtent, env);
              number(value.aspectRatio, env);
              number(value.spacing, env);
            case skir.ResourcesLayout_treeWrapper(:final value):
              final target = switch (namedUse(member)) {
                final link? => _linkTargetSelection(link),
                null => null,
              };
              if (target == null || valueTypeAt(target, value.path) == null) {
                errors.add("unresolved_tree_path");
              }
              if (value.group case final group?) {
                alias(value.groupBindingId);
                nested[group] = {
                  ...env,
                  value.groupBindingId: type(
                    skir.TypeUse.wrapNamed(hierarchyGroupUse),
                    false,
                  ),
                };
              }
            default:
              break;
          }
        case skir.PresentationElement_appearanceDefaultsWrapper(:final value):
          appearance(value.appearance, env);
        case skir.PresentationElement_conditionalWrapper(:final value):
          check(value.condition, boolean, env);
        case skir.PresentationElement_scopedBindingWrapper(:final value):
          rebound(
            value.child,
            binding(value.binding, env)?.declaredUse(),
            alias: value.scopeBindingId,
          );
        case skir.PresentationElement_typedFieldWrapper():
          break;
        case skir.PresentationElement_recordInputWrapper(:final value):
          collectionContent(value.content, env);
          collectionAppearance(value.appearance, env);
        case skir.PresentationElement_namedInputWrapper(:final value):
          collectionContent(value.content, env);
          collectionAppearance(value.appearance, env);
        case skir.PresentationElement_nullableInputWrapper(:final value):
          check(value.emptyText, text, env);
          check(value.clearLabel, text, env);
        case skir.PresentationElement_listInputWrapper(:final value):
          collectionContent(value.content, env);
          collectionAppearance(value.appearance, env);
          rebound(
            value.itemPresentation,
            collectionItemType(candidate),
            alias: value.itemBindingId,
          );
          if (value.itemPresentation != null &&
              nested.containsKey(value.itemPresentation)) {
            nested[value.itemPresentation!] = {
              ...nested[value.itemPresentation]!,
              value.indexBindingId: type(integer, false),
            };
          }
        case skir.PresentationElement_setInputWrapper(:final value):
          collectionContent(value.content, env);
          collectionAppearance(value.appearance, env);
          rebound(
            value.itemPresentation,
            collectionItemType(candidate),
            alias: value.itemBindingId,
          );
        case skir.PresentationElement_mapInputWrapper(:final value):
          collectionContent(value.content, env);
          collectionAppearance(value.appearance, env);
          final named = namedUse(candidate);
          final representation = named == null
              ? null
              : published(named.definition)?.definition.representation;
          if (representation case skir.RepresentationTemplate_mappingWrapper(
            value: final valueType,
          )) {
            final containing = skir.TypeSelection.wrapComplete(named!);
            rebound(
              value.keyPresentation,
              applyTemplate(valueType.key, containing),
              alias: value.keyBindingId,
            );
            rebound(
              value.valuePresentation,
              applyTemplate(valueType.value, containing),
              alias: value.valueBindingId,
            );
          }
        case skir.PresentationElement_polymorphicInputWrapper(:final value):
          collectionContent(value.content, env);
          collectionAppearance(value.appearance, env);
          appearance(value.inputAppearance, env);
          content(value.inputContent, env);
          check(value.searchHint, text, env);
          for (final option in value.concreteTypes) {
            check(option.label, text, env);
            rebound(option.presentation, option.concreteType);
          }
        case skir.PresentationElement_polymorphicMatchWrapper(:final value):
          for (final option in value.cases) {
            rebound(
              option.child,
              option.concreteType,
              alias: value.scopeBindingId,
            );
          }
        case skir.PresentationElement_searchInputWrapper(:final value):
          appearance(value.appearance, env);
          content(value.content, env);
          popup(value.popup, env);
          number(value.maximumExtent, env);
          for (final expression in [
            value.placeholder,
            value.initialQuery,
            value.emptyText,
            value.loadingText,
          ]) {
            check(expression, text, env);
          }
          rebound(value.summary, candidate, alias: value.summaryBindingId);
          searchProvider(value.provider, {
            ...env,
            value.queryBindingId: type(text, false),
          });
          check(value.customValue, candidate ?? text, {
            ...env,
            value.queryBindingId: type(text, false),
          });
        case skir.PresentationElement_repeatedWrapper(:final value):
          skir.ExpressionType? source;
          final sourceProblems = checkPortableExpression(
            value.source,
            catalog: this,
            bindings: env,
            onInferred: (result) => source = result,
          );
          errors.addAll(sourceProblems);
          rebound(
            value.presentation.item,
            source == null ? null : collectionItem(source!)?.declaredUse(),
            alias: value.itemBindingId,
          );
        default:
          break;
      }
      for (final child in node.nestedPresentationNodes) {
        visit(child, nested[child] ?? env);
      }
    };
    final rootEnvironment = <skir.ExpressionBindingId, skir.ExpressionType>{
      configured: type(subject),
      skir.ExpressionBindingId(value: "presentation.subject.identifier"): type(
        skir.TypeUse.wrapNamed(frameworkResourceIdUse),
        false,
      ),
      presentationSubjectAppearanceBindingId: type(
        skir.TypeUse.wrapNamed(canonicalReadModels.resourceAppearanceUse),
        false,
      ),
      for (final input in contextInputs.entries) input.key: type(input.value),
    };
    visit(material.layout, rootEnvironment);
    return List.unmodifiable(errors.toSet());
  }
}

extension on CheckedEditorCatalog {
  /// The resource type a link use points at, such as Page for a link of
  /// Book.pages.
  skir.TypeSelection? _linkTargetSelection(skir.NamedTypeUse link) {
    final representation = published(link.definition)
        ?.definition
        .representation;
    if (representation is! skir.RepresentationTemplate_linkWrapper) return null;
    final target = applyTemplate(
      representation.value.target,
      skir.TypeSelection.wrapComplete(link),
    );
    final named = namedUse(target);
    return named == null ? null : skir.TypeSelection.wrapComplete(named);
  }
}
