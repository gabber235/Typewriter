// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _i1;
import 'package:widgetbook_workspace/stories/components/labeled_divider.stories.dart'
    as _i4;
import 'package:widgetbook_workspace/stories/components/text_scroller.stories.dart'
    as _i6;
import 'package:widgetbook_workspace/stories/routes/route.dart' as _i3;
import 'package:widgetbook_workspace/stories/screens/error_screen.stories.dart'
    as _i7;
import 'package:widgetbook_workspace/stories/widgets/generic/components/input_field.stories.dart'
    as _i2;
import 'package:widgetbook_workspace/stories/widgets/generic/components/organization_icon.stories.dart'
    as _i5;

final directories = <_i1.WidgetbookNode>[
  _i1.WidgetbookFolder(
    name: 'material',
    children: [
      _i1.WidgetbookComponent(
        name: 'TextField',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i2.inputFieldUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'Error',
            builder: _i2.inputFieldErrorUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'With Prefix Icon',
            builder: _i2.inputFieldWithPrefixIconUseCase,
          ),
        ],
      ),
    ],
  ),
  _i1.WidgetbookFolder(
    name: 'routes',
    children: [
      _i1.WidgetbookLeafComponent(
        name: 'IndexPage',
        useCase: _i1.WidgetbookUseCase(
          name: 'IndexPage',
          builder: _i3.indexPageUseCase,
        ),
      ),
    ],
  ),
  _i1.WidgetbookFolder(
    name: 'widgets',
    children: [
      _i1.WidgetbookFolder(
        name: 'generic',
        children: [
          _i1.WidgetbookFolder(
            name: 'components',
            children: [
              _i1.WidgetbookLeafComponent(
                name: 'LabeledDivider',
                useCase: _i1.WidgetbookUseCase(
                  name: 'LabeledDivider',
                  builder: _i4.labeledDividerUseCase,
                ),
              ),
              _i1.WidgetbookComponent(
                name: 'OrganizationIcon',
                useCases: [
                  _i1.WidgetbookUseCase(
                    name: 'Default',
                    builder: _i5.organizationIconUseCase,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Placeholder',
                    builder: _i5.organizationIconPlaceholderUseCase,
                  ),
                ],
              ),
              _i1.WidgetbookLeafComponent(
                name: 'TextScroller',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i6.textScrollerUseCase,
                ),
              ),
            ],
          ),
          _i1.WidgetbookFolder(
            name: 'screens',
            children: [
              _i1.WidgetbookLeafComponent(
                name: 'ErrorScreen',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i7.errorScreenUseCase,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
